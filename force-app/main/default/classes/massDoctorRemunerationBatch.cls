/*******************************************************************************
* @author		Novera - QLE
* @date		    2020-10-22
* @description  OAPPMEDCHECK-661 Create remuneration note (SF)
* @param		
* @return		
********************************************************************************/

global without sharing class massDoctorRemunerationBatch implements Database.Batchable<sObject>, Database.Stateful 
{
        
    global Database.QueryLocator start(Database.BatchableContext bc) 
    {
        //collect SA records to be passed to execute
        return Database.getQueryLocator('SELECT Id, Assigned_Resource__r.AccountId, Doctor_Convention__c FROM ServiceAppointment'
                                        + ' WHERE Remuneration_Status__c=\'' + ServiceAppointmentManager.REMUNERATION_STATUS_INVOICE_DETAIL_LINE_GENERATED
                                        + '\' AND TECH_Close_Date__c <= LAST_MONTH AND Remuneration_Note__c=null' 
                                        + ' AND Remuneration_on_hold__c=FALSE AND Doctor_Convention__c!=null');
                                        //+ ' WHERE Id=\'08p1j000000MSVAAA4\'');
    }

    global void execute(Database.BatchableContext bc, List<ServiceAppointment> scope)
    {
        System.debug('QLE scope ' + scope);
        List<Invoice_Batch_Result__c> invoiceBatchResult = [SELECT Id FROM Invoice_Batch_Result__c WHERE Batch_Id__c =: bc.getJobId()]; 
        Savepoint sp = Database.setSavepoint();
        //try{
            Id batchResultId = invoiceBatchResult.size()==1?invoiceBatchResult[0].Id:null;
            Set<Id> saToRemIds = new Set<Id>(); //help to find the SALIs to remunerate
            Map<Id,Set<Id>> convIdsPerDocIdMap = new Map<Id,Set<Id>>();//multiple conventions => multiple invoices 
            Map<Id,Contract_Home__c> convPerIdMap = new Map<Id,Contract_Home__c>();
            Map<Id,Map<Id,Id>> csIdPerServIdPerConvIdMap = new  Map<Id,Map<Id,Id>>(); 
            Map<Id,List<ServiceAppointment>> saPerConvIdMap = new Map<Id,List<ServiceAppointment>>();  
            Map<Id,Map<Id,List<Service_Appointment_Line_Item__c>>> salisPerServIdPerConvIdMap = new Map<Id,Map<Id,List<Service_Appointment_Line_Item__c>>>();
            Set<Id> serviceKmIdSet = new Set<Id>();
            List<Task> taskToInsert = new List<Task>(); //Initialize tasks to insert
            List<Invoice__c> remNotesToInsert = new List<Invoice__c>(); //Initialize remuneration notes to insert
            List<InvoiceLineItem__c> invoiceLIsToInsert = new List<InvoiceLineItem__c>(); //Initialize remuneration line items to insert
            Map<Id,List<InvoiceLineItem__c>> ilisPerInvIdMap = new Map<Id,List<InvoiceLineItem__c>>();
            List<ServiceAppointment> saListToUpdate = new List<ServiceAppointment>(); //Remuneration Status must be updated and ARs must be linked to the remuneration note 
            List<Service_Appointment_Line_Item__c> salisToUpdate = new List<Service_Appointment_Line_Item__c>(); //SALIs must be linked to the remuneration line created
            List<Invoice__c> remunerationsWithError = new List<Invoice__c>();//Put invoice in error status if any problem
            Set<Id> remunerationsWithErrorIds = new Set<Id>();//Put invoice in error status if any problem
            Map<Id,Id> remIdPerSaIdMap = new Map<Id,Id>(); //In case of update problem on SA, allow to flag the corresponding Invoice
            for(ServiceAppointment sa : scope)
            {
                saToRemIds.add(sa.Id);
                if(convIdsPerDocIdMap.containsKey(sa.Assigned_Resource__r.AccountId))
                {
                    Set<Id> convIds =  convIdsPerDocIdMap.get(sa.Assigned_Resource__r.AccountId);
                    convIds.add(sa.Doctor_Convention__c);
                    convIdsPerDocIdMap.put(sa.Assigned_Resource__r.AccountId,convIds);
                }
                else
                {
                    convIdsPerDocIdMap.put(sa.Assigned_Resource__r.AccountId,new Set<Id>{sa.Doctor_Convention__c});
                }

                if(saPerConvIdMap.containsKey(sa.Doctor_Convention__c))  
                {
                        List<ServiceAppointment> sas = saPerConvIdMap.get(sa.Doctor_Convention__c);
                        sas.add(sa);
                        saPerConvIdMap.put(sa.Doctor_Convention__c,sas);
                } 
                else
                {
                    saPerConvIdMap.put(sa.Doctor_Convention__c, new List<ServiceAppointment>{sa});
                }
            }
            //OAPPMEDCHECK-660 totalAmount per Account, if 0, no need to generate Invoice
            for(AggregateResult sa : [SELECT Service_Appointment__r.Assigned_Resource__r.AccountId accId, SUM(Amount__c) sumAmount
                FROM Service_Appointment_Line_Item__c WHERE Service_Appointment__c IN:saToRemIds 
                AND Invoicing_type__c = :ServiceAppointmentManager.INVOICE_DETAIL_LINE_REMUNERATION_TYPE
                GROUP BY Service_Appointment__r.Assigned_Resource__r.AccountId])

            {
                if(Integer.valueOf(sa.get('sumAmount'))==0 || Integer.valueOf(sa.get('sumAmount'))==null)
                {
                    convIdsPerDocIdMap.remove(String.valueOf(sa.get('accId'))); //OAPPMEDCHECK-660
                }
            }
            for(ServiceAppointment sa : scope)
            {
                if(!convIdsPerDocIdMap.keySet().contains(sa.Assigned_Resource__r.AccountId))
                {
                    sa.Remuneration_Status__c = ServiceAppointmentManager.REMUNERATION_STATUS_NO_REMUNERATION;
                    saToRemIds.remove(sa.Id);
                    saListToUpdate.add(sa);
                }   
            }

            System.debug('QLE saListToUpdate 1 ' + saListToUpdate);
            System.debug('QLE convIdsPerDocIdMap ' + convIdsPerDocIdMap);

            /**********************************Preparing the invoice details*******************************************/
            //Retrieve SALI that are part of the invoice between the specified period and group SALI per Service per Contract
            for(Service_Appointment_Line_Item__c saLineItem : [SELECT Id,Service__c,Service__r.Service_Name_FR__c,Service__r.Service_Name_NL__c, Service__r.Order__c
                ,Service_Appointment__c,Service_Appointment__r.Doctor_Convention__c, Amount__c,TECH_Km__c FROM Service_Appointment_Line_Item__c 
                        WHERE Service_Appointment__c IN:saToRemIds  
                        AND Invoicing_type__c = :ServiceAppointmentManager.INVOICE_DETAIL_LINE_REMUNERATION_TYPE])
            {
                //For invoice detail line Km Flat or Km Mountain, OAPPMEDCHECK-343 display  Unit Price/Km  + total amount not total Km
                //Help to identify the price in the contract avoicing query table Service for service Id
                if(saLineItem.TECH_Km__c!=null)
                {
                    serviceKmIdSet.add(saLineItem.Service__c);
                }
                
                //1 remuneration note per convertion for the same doctor account. 1 remuneration line per service. 
                if(salisPerServIdPerConvIdMap.containsKey(saLineItem.Service_Appointment__r.Doctor_Convention__c))
                {
                    Map<Id,List<Service_Appointment_Line_Item__c>> salisPerServIdMap = salisPerServIdPerConvIdMap.get(saLineItem.Service_Appointment__r.Doctor_Convention__c);
                    if(salisPerServIdMap.containsKey(saLineItem.Service__c)) 
                    {
                        List<Service_Appointment_Line_Item__c> saLineItems = salisPerServIdMap.get(saLineItem.Service__c);
                        saLineItems.add(saLineItem);
                        salisPerServIdMap.put(saLineItem.Service__c,saLineItems);
                    } 
                    else
                    {
                        salisPerServIdMap.put(saLineItem.Service__c, new List<Service_Appointment_Line_Item__c>{saLineItem});
                    }
                    salisPerServIdPerConvIdMap.put(saLineItem.Service_Appointment__r.Doctor_Convention__c,salisPerServIdMap);
                }
                else 
                {
                    Map<Id,List<Service_Appointment_Line_Item__c>> salisPerServIdMap = new  Map<Id,List<Service_Appointment_Line_Item__c>>();
                    salisPerServIdMap.put(saLineItem.Service__c, new List<Service_Appointment_Line_Item__c>{saLineItem});
                    salisPerServIdPerConvIdMap.put(saLineItem.Service_Appointment__r.Doctor_Convention__c,salisPerServIdMap);
                }
            }

            /**********************************Preparing the contract information*******************************************/
            for(Contract_Home__c conv : [SELECT Id, Account__c, Account__r.Account_Language__c, RecordTypeId, Specific_VAT_Picklist__c
                                        ,(SELECT Price_Rate_1__c, Service__c FROM Contractual_Service_Line_Items__r)
                                FROM Contract_Home__c WHERE Id IN:salisPerServIdPerConvIdMap.keySet() AND RecordTypeId =:ContractHomeManager.mcmRtConventionFRId])
            {
                convPerIdMap.put(conv.Id,conv);
                Map<Id,Id> csIdPerServIdMap = new Map<Id,Id>();   
                //Group Contractual Service Line Item per Service
                for(Contractual_Service_Line_Item__c csli : conv.Contractual_Service_Line_Items__r)
                {
                    //There is only one active csli per service per contract (except pack) - check on insert of CSLI
                    csIdPerServIdMap.put(csli.Service__c,csli.Id);
                } 
                csIdPerServIdPerConvIdMap.put(conv.Id,csIdPerServIdMap);
            }
            System.debug('QLE massDoctorRemunerationBatch csIdPerServIdPerConvIdMap ' + csIdPerServIdPerConvIdMap);                   

            /**********************************Preparing the remuneration notes (1 per contract)*******************************************/
            for(Id dId : convIdsPerDocIdMap.keySet())
            {
                for(Id cId : convIdsPerDocIdMap.get(dId))
                {
                    Contract_Home__c conv = convPerIdMap.get(cId);
                    System.debug('QLE massDoctorRemunerationBatch conv ' + conv );
                    String convCountry = conv.RecordTypeId==ContractHomeManager.mcmRtConventionFRId?'FRA':'BEL';
                    Decimal specificVAT = conv.Specific_VAT_Picklist__c!=null?Decimal.valueOf(conv.Specific_VAT_Picklist__c.remove('%')):null;

                    
                    //Define invoice 
                    Invoice__c inv = InvoiceManager.createMCMInvoice('19',conv.Account__r.Account_Language__c
                                    ,InvoiceManager.INVOICE_TYPE_DOCTOR_REMUNERATION,'Draft'
                                    ,conv.Id,convCountry,null,dId,batchResultId,'',specificVAT,null,InvoiceManager.RT_ID_REMUNERATION_MEDICAL_CONTROL);
                    remNotesToInsert.add(inv);
                }
            }
            
            //All draft remuneration notes must be inserted. Otherwise exception thrown.Invoice must be inserted to generate Id, so that we can reference it on remuneration line Item      
            if(!remNotesToInsert.isEmpty()) Database.SaveResult[] srInvoiceList = Database.insert(remNotesToInsert, true);

            /*Insert remuneration line (1 per Service) to generate Id. We link SALIs with the same Service to the same remuneration line.
            Placeholders, we insert as many lines as the number of services we have from the grouping of SALIs per Contract*/
            System.debug('QLE salisPerServIdPerConvIdMap ' + salisPerServIdPerConvIdMap);
            for(Invoice__c rem : remNotesToInsert)
            {
                List<InvoiceLineItem__c> ilis = new List<InvoiceLineItem__c>();
                System.debug('QLE rem.Contract_Home__c ' + rem.Contract_Home__c);
                System.debug('QLE salisPerServIdPerConvIdMap ' + salisPerServIdPerConvIdMap.get(rem.Contract_Home__c));
                for(Id serviceId : salisPerServIdPerConvIdMap.get(rem.Contract_Home__c).keySet())
                {
                    ilis.add(new InvoiceLineItem__c(Invoice__c = rem.Id,RecordTypeId = UtilsConstants.RT_ID_INVOICE_LINE_ITEM_MEDICAL_CONTROL));
                }
                invoiceLIsToInsert.addAll(ilis);
                ilisPerInvIdMap.put(rem.Id,ilis);
            }
            insert invoiceLIsToInsert; 

            /*Insert remuneration line (1 per Service) to generate Id. We link SALIs with the same Service to the same remuneration line.*/
            for(Invoice__c rem : remNotesToInsert)
            {     
                Map<Id,List<Service_Appointment_Line_Item__c>> salisPerServIdMap = salisPerServIdPerConvIdMap.get(rem.Contract_Home__c);
                Map<Id,Id> csIdPerServIdMap = csIdPerServIdPerConvIdMap.get(rem.Contract_Home__c);
                List<InvoiceLineItem__c> ilis = ilisPerInvIdMap.get(rem.Id);
                Set<Id> saIds = new Set<Id>();
                Integer i=0;
                //Compute total quantity and amount per remuneration line (thus per service)
                for(Id serviceId : salisPerServIdMap.keySet())
                {  
                    List<Service_Appointment_Line_Item__c> saLineItems = salisPerServIdMap.get(serviceId);
                    saIds.add(saLineItems[0].Service_Appointment__c);
                    Integer quantity=0; // not simply saLineItems.size() since we shouldn't count line where Amount__c=0
                    Double totalAmount = 0;
                    Double totalKm = 0;
                    Boolean isKm = serviceKmIdSet.contains(serviceId); 
                    Boolean isMisc = serviceId==createInvoiceController.miscFrServiceId; 
                    InvoiceLineItem__c invLI = ilis.get(i);
                    for(Service_Appointment_Line_Item__c saLineItem : saLineItems)
                    {
                        System.debug('QLE saLineItem ' + saLineItem);
                        if(isKm)
                        {
                            if(saLineItem.TECH_Km__c!=null) totalKm = totalKm + saLineItem.TECH_Km__c; 
                        }
                        else //leave quantity empty for kmservices and Misc
                        {
                            if(saLineItem.Amount__c!=null&&saLineItem.Amount__c!=0)
                            {
                                if(!isMisc) quantity = quantity + 1;
                            }
                        }
                        if(saLineItem.Amount__c!=null) totalAmount = totalAmount + saLineItem.Amount__c;  
                        saLineItem.InvoiceLineItem__c = invLI.Id; 
                        salisToUpdate.add(saLineItem);
                    }
                    invLI.Description__c= rem.Billing_Language__c=='NL'?saLineItems[0].Service__r.Service_Name_NL__c:saLineItems[0].Service__r.Service_Name_FR__c;
                    invLI.Unit_Price__c = isKm&&totalKm>0?totalAmount/totalKm:quantity>0?totalAmount/quantity:null;
                    invLI.Quantity__c = isKm||isMisc?null:quantity;
                    invLI.Amount_Excluding_VAT_Currency__c = totalAmount;
                    invLI.Contractual_Service_Line_Item__c = csIdPerServIdMap.get(serviceId);
                    invLI.ILI_Order__c = saLineItems[0].Service__r.Order__c;
                    i++;
                }
                for(Id saId : saIds)
                {
                    remIdPerSaIdMap.put(saId,rem.Id);
                    ServiceAppointment sa = new ServiceAppointment(Id=saId,Remuneration_Note__c=rem.Id
                        ,Remuneration_Status__c=ServiceAppointmentManager.REMUNERATION_STATUS_REMUNERATION_NOTE_CREATED);
                    saListToUpdate.add(sa);
                }
            }  
            if(!invoiceLIsToInsert.isEmpty())
            {
                Database.SaveResult[] srInvLineItems = Database.update(invoiceLIsToInsert,false); //update of total quantity and amount information
                for(Invoice__c remWithErr : InvoiceManager.processSaveResult(invoiceLIsToInsert,srInvLineItems))
                {
                    remunerationsWithError.add(remWithErr);
                    remunerationsWithErrorIds.add(remWithErr.Id);
                }
            }

            System.debug('QLE saListToUpdate 2 ' + saListToUpdate);

            /*Update to link remuneration line*/
            if(!salisToUpdate.isEmpty())
            {
                Database.SaveResult[] srSalis = Database.update(salisToUpdate,false);
                Set<Id> alreadyProcessed = new Set<Id>();
                for(Integer idx = 0; idx < srSalis.size(); idx++)
                {   
                    if (!srSalis[idx].isSuccess()) 
                    {
                        String errText;
                        for(Database.Error err : srSalis[idx].getErrors()) 
                        {
                            errText = err.getMessage() + ' ';
                        }        
                        Service_Appointment_Line_Item__c sali = salisToUpdate[idx];
                        if(!remunerationsWithErrorIds.contains(remIdPerSaIdMap.get(sali.Service_Appointment__c)))
                        {
                            Invoice__c rem = new Invoice__c(Id=remIdPerSaIdMap.get(sali.Service_Appointment__c),Status__c=StaticConstants.INVOICE_STATUS_ERROR,Error_reason__c=errText,Invoicing_On_Hold__c=true);
                            remunerationsWithError.add(rem);
                            remunerationsWithErrorIds.add(remIdPerSaIdMap.get(sali.Service_Appointment__c));
                        }
                    }
                }
            }

            /*Update to link remuneration*/
            if(!saListToUpdate.isEmpty())
            {
                Database.SaveResult[] saSAList = Database.update(saListToUpdate,false); 
                for(Invoice__c remWithErr : InvoiceManager.processSaveResult(saListToUpdate,saSAList))
                {
                    if(!remunerationsWithErrorIds.contains(remWithErr.Id))
                    {
                        remunerationsWithError.add(remWithErr);
                        remunerationsWithErrorIds.add(remWithErr.Id);
                    }
                }
            }
            Database.update(remunerationsWithError,false); //update to put status in error

            /*After Invoice Todos*/
            if(!taskToInsert.isEmpty()) Database.insert(taskToInsert,false);

        // }
        // catch(Exception e){
        //     Database.rollback(sp);
        //     invoiceBatchResult[0].Status__c='Failed';
        //     update invoiceBatchResult[0];
        // }   
    
    }    


    global void finish(Database.BatchableContext bc)
    {
        //execute any post-processing operations
        List<Invoice_Batch_Result__c> invoiceBatchResult = [SELECT Id FROM Invoice_Batch_Result__c WHERE Batch_Id__c =: bc.getJobId()]; 
        if(invoiceBatchResult.size()==1)
        {
            List<AggregateResult> aggR = [SELECT Status__c, count(Id) FROM Invoice__c WHERE Generated_by_batch__c=:invoiceBatchResult[0].Id GROUP BY Status__c];
            Integer total;
            Integer draftCount = 0;
            Integer errorCount =0;
            for (AggregateResult sa : aggR)  {
                String status = (String) sa.get('Status__c');
                Integer countRec = (Integer) sa.get('expr0');
                if(status==StaticConstants.INVOICE_STATUS_DRAFT)
                {
                    draftCount = countRec;
                }
                else if(status==StaticConstants.INVOICE_STATUS_ERROR)
                {
                    errorCount = countRec;
                }
            }
            invoiceBatchResult[0].Number_of_invoice_created__c = draftCount + errorCount;
            invoiceBatchResult[0].Number_of_errors__c = errorCount;
            invoiceBatchResult[0].Status__c = 'Completed'; 
            update invoiceBatchResult[0]; 
        }
    }    
}