/*******************************************************************************
* @author		Novera - QLE
* @date		    2020-10-22
* @description  OAPPMEDCHECK-323 Launch invoicing creation batch
* @param		
* @return		
********************************************************************************/

global without sharing class massServicingInvoiceBatch implements Database.Batchable<sObject>, Database.Stateful 
{
        
    global Database.QueryLocator start(Database.BatchableContext bc) 
    {
        //collect AR records to be passed to execute
        return Database.getQueryLocator('SELECT Id, Invoicing_Account__c, Contract_Home__c, Invoicing_Account__r.Invoicing_Terms__c, Invoicing_Account__r.PO_Number__c'
                                        +',Invoicing_Account__r.Active_Department__c,Invoicing_Account__r.Date_out__c, RecordTypeId'
                                        +',Contract_Home__r.Invoicing_Terms__c,Contract_Home__r.PO_Number__c' 
                                        +',Contract_Home__r.Specific_VAT_Picklist__c'
                                        +',Contract_Home__r.Todos_before_invoicing__c'
                                        +',Contract_Home__r.RecordTypeId FROM Absence_Registration__c'
                                        + ' WHERE Invoicing_Status__c=\'' + AbsenceRegistrationManager.INVOICING_STATUS_INVOICE_TO_GENERATE
                                        + '\' AND TECH_Close_Date__c <= LAST_MONTH AND Invoicing_on_hold__c=FALSE'
                                        //+ '\' AND Invoicing_on_hold__c=FALSE AND Invoicing_Account__c!=null AND Contract_Home__c!=null'
                                        + ' AND Contract_Home__r.Blocked_For_Invoicing__c=FALSE AND Contract_Home__r.RecordTypeId!=\'' + ContractHomeManager.mcmRtPricingId + '\'');
    }

    global void execute(Database.BatchableContext bc, List<Absence_Registration__c> scope)
    {
        System.debug('QLE scope ' + scope);
        List<Invoice_Batch_Result__c> invoiceBatchResult = [SELECT Id FROM Invoice_Batch_Result__c WHERE Batch_Id__c =: bc.getJobId()]; 
        List<Absence_Registration__c> arToProcess = new List<Absence_Registration__c>();
        for(Absence_Registration__c ar : scope)
        {
            System.debug('QLE ar.Contract_Home__r.Todos_before_invoicing__c ' + ar.Contract_Home__r.Todos_before_invoicing__c);
            if(ar.Contract_Home__r.Todos_before_invoicing__c==null) //OAPPMEDCHECK-346 
            {
                System.debug('QLE ar.Contract_Home__c ' + ar.Contract_Home__c);
                System.debug('QLE ar.Invoicing_Account__c ' + ar.Invoicing_Account__c);
                if(ar.Contract_Home__c!=null && ar.Invoicing_Account__c!=null)
                {
                    arToProcess.add(ar); //Filter to avoid issue in DEV. ARs can not have Status Invoice To Generate if those 2 informations are missing.
                }
            }
        }
        Savepoint sp = Database.setSavepoint();
        // try{
            Id batchResultId = invoiceBatchResult.size()==1?invoiceBatchResult[0].Id:null;
            Set<Id> accToInvoiceSet = new Set<Id>();
            Set<Id> ctrIdSet = new Set<Id>();
            Set<Id> arToInvoiceSet = new Set<Id>();
            Map<Id,Contract_Home__c> ctrPerIdMap = new Map<Id,Contract_Home__c>();//OAPPMEDCHECK-728 
            Map<Id,Map<Id,Contractual_Service_Line_Item__c>> csPerServIdPerCtrIdMap = new  Map<Id,Map<Id,Contractual_Service_Line_Item__c>>(); //Group CSLIs per Service Id per Contract Home Id 
            Map<Id,Map<Id,List<Absence_Registration__c>>> absRegsPerCtrIdPerAccIdMap = new Map<Id,Map<Id,List<Absence_Registration__c>>>();  
            Map<Id,Map<Id,Map<Id,List<Service_Appointment_Line_Item__c>>>> salisPerServIdPerCtrIdPerAccIdMap = new Map<Id,Map<Id,Map<Id,List<Service_Appointment_Line_Item__c>>>>();
            Set<Id> serviceKmIdSet = new Set<Id>();
            List<Task> taskToInsert = new List<Task>(); //Initialize tasks to insert
            List<Invoice__c> invoicesToInsert = new List<Invoice__c>(); //Initialize invoices to insert
            List<InvoiceLineItem__c> invoiceLIsToInsert = new List<InvoiceLineItem__c>(); //Initialize invoice line items to insert
            Map<Id,List<InvoiceLineItem__c>> ilisPerInvIdMap = new Map<Id,List<InvoiceLineItem__c>>();
            Map<Id,String> lgPerInvAccId =  new Map<Id,String>();
            List<Absence_Registration__c> arListToUpdate = new List<Absence_Registration__c>(); //Invoicing Status must be updated and ARs must be linked to the invoice 
            List<Service_Appointment_Line_Item__c> salisToUpdate = new List<Service_Appointment_Line_Item__c>(); //SALIs must be linked to the invoice line created
            List<Invoice__c> invoicesWithError = new List<Invoice__c>();//Put invoice in error status if any problem
            Set<Id> invoicesWithErrorIds = new Set<Id>();//Put invoice in error status if any problem
            Map<Id,Id> invIdPerArIdMap = new Map<Id,Id>(); //In case of update problem on AR, allow to flag the corresponding Invoice
            DateTime startDateInvoicingPeriod = System.today().addMonths(-1).toStartOfMonth(); //OAPPMEDCHECK-836 Compute Invoicing Period
            Map<Id,String> countryPerInactiveInvAccId = new Map<Id,String>(); //OAPPMEDCHECK-836 Procedure when invoicing account becomes inactive
            Map<String,Id> servicePerVisitType = ServiceAppointmentManager.servicePerVisitTypePerCountryMap.get('FR'); 

            System.debug('QLE arToProcess ' + arToProcess);
            for(Absence_Registration__c ar : arToProcess)
            {
                accToInvoiceSet.add(ar.Invoicing_Account__c);
                ctrIdSet.add(ar.Contract_Home__c);
                arToInvoiceSet.add(ar.Id);

                Map<Id,List<Absence_Registration__c>> absRegsPerCtrIdMap = new Map<Id,List<Absence_Registration__c>>();  
                List<Absence_Registration__c> ars = new List<Absence_Registration__c>();
                if(absRegsPerCtrIdPerAccIdMap.containsKey(ar.Invoicing_Account__c))
                {
                    absRegsPerCtrIdMap = absRegsPerCtrIdPerAccIdMap.get(ar.Invoicing_Account__c);
                    if(absRegsPerCtrIdMap.containsKey(ar.Contract_Home__c))  
                    {
                        ars = absRegsPerCtrIdMap.get(ar.Contract_Home__c);
                        ars.add(ar);
                        absRegsPerCtrIdMap.put(ar.Contract_Home__c,ars);
                    } 
                    else
                    {
                        ars.add(ar);
                        absRegsPerCtrIdMap.put(ar.Contract_Home__c,ars);
                    }
                    absRegsPerCtrIdPerAccIdMap.put(ar.Invoicing_Account__c,absRegsPerCtrIdMap);
                }
                else 
                {
                    ars.add(ar);
                    absRegsPerCtrIdMap.put(ar.Contract_Home__c,ars);
                    absRegsPerCtrIdPerAccIdMap.put(ar.Invoicing_Account__c,absRegsPerCtrIdMap);
                }
            }

            //OAPPMEDCHECK-660 totalAmount per Account, if 0, no need to generate Invoice
            for(AggregateResult ar : [SELECT Service_Appointment__r.Absence_Registration__r.Invoicing_Account__c invoicingDep, SUM(Amount__c) sumAmount
                FROM Service_Appointment_Line_Item__c WHERE Service_Appointment__r.Absence_Registration__c IN:arToInvoiceSet 
                AND Invoicing_type__c = :ServiceAppointmentManager.INVOICE_DETAIL_LINE_CI_TYPE
                GROUP BY Service_Appointment__r.Absence_Registration__r.Invoicing_Account__c])

            {
                if(Integer.valueOf(ar.get('sumAmount'))==0 || Integer.valueOf(ar.get('sumAmount'))==null)
                {
                    accToInvoiceSet.remove(String.valueOf(ar.get('invoicingDep')));//OAPPMEDCHECK-660
                }
            }
            for(Absence_Registration__c ar : arToProcess)
            {
                if(!accToInvoiceSet.contains(ar.Invoicing_Account__c))
                {
                    ar.Invoicing_Status__c = AbsenceRegistrationManager.INVOICING_STATUS_NO_INVOICING;
                    arToInvoiceSet.remove(ar.Id);
                    arListToUpdate.add(ar);
                }
                if(ar.Invoicing_Account__r.Active_Department__c==false) //OAPPMEDCHECK-836
                {
                    if(ar.Invoicing_Account__r.Date_out__c <= startDateInvoicingPeriod)
                    {
                        arToInvoiceSet.remove(ar.Id);
                        String country = ar.recordTypeId==AbsenceRegistrationManager.ABSENCE_REGISTRATION_RT_FR?AbsenceRegistrationManager.COUNTRY_FR:AbsenceRegistrationManager.COUNTRY_BE;
                        countryPerInactiveInvAccId.put(ar.Invoicing_Account__c,country);
                    }
                }
            }
            
            for(Id invAccId : countryPerInactiveInvAccId.keySet())//OAPPMEDCHECK-836
            {
                System.debug('QLE invAccId ' + invAccId); 
                System.debug('QLE countryPerInactiveInvAccId ' + countryPerInactiveInvAccId.get(invAccId)); 
                taskToInsert.add(ServiceAppointmentManager.generateTaskMCMQueue(null,countryPerInactiveInvAccId.get(invAccId), invAccId,Label.InvoicingNotPossibleOnInactiveDep
                ,Label.commentTaskInactiveInvoicingDep,1));
            }
            System.debug('QLE arToInvoiceSet ' + arToInvoiceSet);
            /**********************************Preparing the invoice details*******************************************/
            //Retrieve SALI that are part of the invoice between the specified period and group SALI per Service per Contract
            for(Service_Appointment_Line_Item__c saLineItem : [SELECT Id,Service__c,Service__r.Service_Name_FR__c,Service__r.Service_Name_NL__c, Service__r.Order__c
                    ,Service_Appointment__r.Absence_Registration__c,Amount__c,TECH_Km__c,Service_Appointment__r.Absence_Registration__r.Contract_Home__c 
                    ,Service_Appointment__r.Absence_Registration__r.Invoicing_Account__c
                FROM Service_Appointment_Line_Item__c 
                WHERE Service_Appointment__r.Absence_Registration__c IN:arToInvoiceSet 
                AND Invoicing_type__c = :ServiceAppointmentManager.INVOICE_DETAIL_LINE_CI_TYPE])
            {
                //For invoice detail line Km Flat or Km Mountain, OAPPMEDCHECK-343 display  Unit Price/Km  + total amount not total Km
                //Help to identify the price in the contract avoicing query table Service for service Id
                if(saLineItem.TECH_Km__c!=null)
                {
                    serviceKmIdSet.add(saLineItem.Service__c);
                }
                //System.debug('QLE salineItem ' + salineItem);
                Map<Id,Map<Id,List<Service_Appointment_Line_Item__c>>> salisPerServIdPerCtrIdMap = new Map<Id,Map<Id,List<Service_Appointment_Line_Item__c>>>();
                Map<Id,List<Service_Appointment_Line_Item__c>> salisPerServIdMap = new  Map<Id,List<Service_Appointment_Line_Item__c>>();
                List<Service_Appointment_Line_Item__c> salis = new  List<Service_Appointment_Line_Item__c>();
                if(salisPerServIdPerCtrIdPerAccIdMap.containsKey(saLineItem.Service_Appointment__r.Absence_Registration__r.Invoicing_Account__c))
                {
                    salisPerServIdPerCtrIdMap = salisPerServIdPerCtrIdPerAccIdMap.get(saLineItem.Service_Appointment__r.Absence_Registration__r.Invoicing_Account__c);
                    //1 invoice per contract for the same invoicing account. 1 invoice line per service. 
                    if(salisPerServIdPerCtrIdMap.containsKey(saLineItem.Service_Appointment__r.Absence_Registration__r.Contract_Home__c))
                    {
                        salisPerServIdMap = salisPerServIdPerCtrIdMap.get(saLineItem.Service_Appointment__r.Absence_Registration__r.Contract_Home__c);
                        if(salisPerServIdMap.containsKey(saLineItem.Service__c)) 
                        {
                            salis = salisPerServIdMap.get(saLineItem.Service__c);
                            salis.add(saLineItem);
                            salisPerServIdMap.put(saLineItem.Service__c,salis);
                        } 
                        else
                        {
                            salis.add(saLineItem);
                            salisPerServIdMap.put(saLineItem.Service__c,salis);
                        }
                        salisPerServIdPerCtrIdMap.put(saLineItem.Service_Appointment__r.Absence_Registration__r.Contract_Home__c,salisPerServIdMap);
                    }
                    else 
                    {
                        salis.add(saLineItem);
                        salisPerServIdMap.put(saLineItem.Service__c,salis);
                        salisPerServIdPerCtrIdMap.put(saLineItem.Service_Appointment__r.Absence_Registration__r.Contract_Home__c,salisPerServIdMap);
                    }
                    salisPerServIdPerCtrIdPerAccIdMap.put(saLineItem.Service_Appointment__r.Absence_Registration__r.Invoicing_Account__c,salisPerServIdPerCtrIdMap);
                }
                else
                {
                    salis.add(saLineItem);
                    salisPerServIdMap.put(saLineItem.Service__c, salis);
                    salisPerServIdPerCtrIdMap.put(saLineItem.Service_Appointment__r.Absence_Registration__r.Contract_Home__c,salisPerServIdMap);
                    salisPerServIdPerCtrIdPerAccIdMap.put(saLineItem.Service_Appointment__r.Absence_Registration__r.Invoicing_Account__c,salisPerServIdPerCtrIdMap);
                }
            }

            System.debug('QLE salisPerServIdPerCtrIdPerAccIdMap ' + salisPerServIdPerCtrIdPerAccIdMap);

            /**********************************Preparing the contract information*******************************************/
            for(Contract_Home__c ctr : [SELECT Id, Invoicing_Terms__c, Account__c, Invoicing_Account__r.Invoicing_Terms__c
                    ,Invoicing_Account__r.PO_Number__c,Specific_Contract__c,Specific_VAT_Picklist__c, PO_Number__c, RecordTypeId
                    ,Todos_after_invoicing__c
                    ,(SELECT Id, Service__c, Price_Rate_1__c FROM Contractual_Service_Line_Items__r WHERE Service__r.Service_category__c!='Pack' AND Service__r.Service_category__c!='Annual fee')
                FROM Contract_Home__c WHERE Id IN:ctrIdSet AND Invoicing_Account__c IN:accToInvoiceSet AND RecordTypeId!=:ContractHomeManager.mcmRtPricingId])
            {
                ctrPerIdMap.put(ctr.Id,ctr);
                Map<Id,Contractual_Service_Line_Item__c> csPerServIdMap = new Map<Id,Contractual_Service_Line_Item__c>();   
                //Group Contractual Service Line Item per Service
                for(Contractual_Service_Line_Item__c csli : ctr.Contractual_Service_Line_Items__r)
                {
                    //There is only one active csli per service per contract (except pack) - check on insert of CSLI
                    csPerServIdMap.put(csli.Service__c,csli);
                } 
                csPerServIdPerCtrIdMap.put(ctr.Id,csPerServIdMap);
            } 

            /**********************************Preparing invoicing recipient information*******************************************/
            for(AccountContactRelation acr : [SELECT  AccountId,Contact.Language__c FROM AccountContactRelation 
                    WHERE AccountId IN:accToInvoiceSet AND (Invoicing_recipient_email__c=TRUE OR Invoicing_recipient_post__c=TRUE)])
            {
                lgPerInvAccId.put(acr.AccountId,acr.Contact.Language__c);
            }                

            /**********************************Preparing the invoices (1 per contract)*******************************************/
            for(Id aId : salisPerServIdPerCtrIdPerAccIdMap.keySet())
            {
                Map<Id,Map<Id,List<Service_Appointment_Line_Item__c>>> salisPerServIdPerCtrIdMap = salisPerServIdPerCtrIdPerAccIdMap.get(aId);       
                for(Id cId : salisPerServIdPerCtrIdMap.keySet())
                {
                    Contract_Home__c ctr = ctrPerIdMap.get(cId);
                    if(ctr!=null)
                    {
                        Map<Id,List<Service_Appointment_Line_Item__c>> salisPerServIdMap = salisPerServIdPerCtrIdMap.get(cId);
                        String invoicingTerm = ctr.Invoicing_Account__r.Invoicing_Terms__c!=null?ctr.Invoicing_Account__r.Invoicing_Terms__c:ctr.Invoicing_Terms__c;
                        Decimal specificVAT = ctr.Specific_VAT_Picklist__c!=null?Decimal.valueOf(ctr.Specific_VAT_Picklist__c.remove('%')):null;
                        String ctrHCountry =  ctr.RecordTypeId==ContractHomeManager.mcmRtFRId?'FRA':ctr.RecordTypeId==ContractHomeManager.mcmRtBEId?'BEL':'';
                        String poNum = ctrHCountry=='FRA'?ctr.PO_Number__c:ctrHCountry=='BEL'?ctr.Invoicing_Account__r.PO_Number__c:'';
                        String invLg = lgPerInvAccId.get(aId)!=null?lgPerInvAccId.get(aId):'FR';
                        
                        //Define invoice 
                        Invoice__c inv = InvoiceManager.createMCMInvoice('30',invLg,StaticConstants.INVOICE_TYPE_SERVICE_INVOICING,'Draft'
                                        ,cId,ctrHCountry,invoicingTerm,aId,batchResultId,'',specificVAT,poNum,InvoiceManager.RT_ID_INVOICE_MEDICAL_CONTROL);
                        invoicesToInsert.add(inv);
                    }
                }
            }
            //All draft invoices must be inserted. Otherwise exception thrown.Invoice must be inserted to generate Id, so that we can reference it on Invoice Line Item      
            //if(!invoicesToInsert.isEmpty()) Database.SaveResult[] srInvoiceList = Database.insert(invoicesToInsert, true);
            insert invoicesToInsert;

            //OAPPMEDCHECK-475 Service category = 'basic fee per service' OR service category = 'suppl per service' AND suppl type not in (km, flat, mountain)
            Set<Id> basicOrSupplNotKmIds = new Set<Id>();
            //OAPPMEDCHECK-475 service category =  'suppl per service' AND suppl type in (km, flat, mountain)
            Set<Id> supplKmIds = new Set<Id>();
            //OAPPMEDCHECK-475 For service category = 'miscellaneous'
            Id miscId;
            for(String key : servicePerVisitType.keySet())
            {
                switch on key {
                    when 'Miscellaneous' {
                        miscId = servicePerVisitType.get(key);
                    }
                    when 'Flat','Mountain','Km' {
                        supplKmIds.add(servicePerVisitType.get(key));
                    }
                    when else {
                        basicOrSupplNotKmIds.add(servicePerVisitType.get(key));
                    }
                }
            }
            //OAPPMEDCHECK-475
            Map<Id,Map<Id,Map<Decimal,List<Service_Appointment_Line_Item__c>>>> salisPerAmountPerServIdPerInvIdMap = new Map<Id,Map<Id,Map<Decimal,List<Service_Appointment_Line_Item__c>>>>();
                                
            /*Insert invoice line (1 per Service) to generate Id. We link SALIs with the same Service to the same invoice line.
            Placeholders, we insert as many lines as the number of services we have from the grouping of SALIs per Contract*/
            for(Invoice__c inv : invoicesToInsert)
            {
                List<InvoiceLineItem__c> ilis = new List<InvoiceLineItem__c>();
                Map<Id,Map<Id,List<Service_Appointment_Line_Item__c>>> salisPerServIdPerCtrIdMap = salisPerServIdPerCtrIdPerAccIdMap.get(inv.Invoicing_Account__c);
                Map<Id,Map<Decimal,List<Service_Appointment_Line_Item__c>>> salisPerAmountPerServIdMap = new Map<Id,Map<Decimal,List<Service_Appointment_Line_Item__c>>>();
                for(Id serviceId : salisPerServIdPerCtrIdMap.get(inv.Contract_Home__c).keySet())
                {
                    Map<Decimal,List<Service_Appointment_Line_Item__c>> salisPerAmountMap = new Map<Decimal,List<Service_Appointment_Line_Item__c>>();
                    if(serviceId==miscId || supplKmIds.contains(serviceId))
                    {
                        ilis.add(new InvoiceLineItem__c(Invoice__c = inv.Id,RecordTypeId = UtilsConstants.RT_ID_INVOICE_LINE_ITEM_MEDICAL_CONTROL));
                    }
                    else
                    {
                        for(Service_Appointment_Line_Item__c sali : salisPerServIdPerCtrIdMap.get(inv.Contract_Home__c).get(serviceId))
                        {
                            if(salisPerAmountMap.containsKey(sali.Amount__c))
                            {
                                List<Service_Appointment_Line_Item__c> salis = salisPerAmountMap.get(sali.Amount__c);
                                salis.add(sali);
                                salisPerAmountMap.put(sali.Amount__c,salis);
                            }
                            else 
                            {
                                List<Service_Appointment_Line_Item__c> salis = new List<Service_Appointment_Line_Item__c>();
                                salis.add(sali);
                                salisPerAmountMap.put(sali.Amount__c,salis);
                            }
                        }
                        for(Decimal amt : salisPerAmountMap.keySet())
                        {
                            ilis.add(new InvoiceLineItem__c(Invoice__c = inv.Id,RecordTypeId = UtilsConstants.RT_ID_INVOICE_LINE_ITEM_MEDICAL_CONTROL));
                        }
                    }
                    salisPerAmountPerServIdMap.put(serviceId,salisPerAmountMap);
                }
                salisPerAmountPerServIdPerInvIdMap.put(inv.Id,salisPerAmountPerServIdMap);
                invoiceLIsToInsert.addAll(ilis);
                ilisPerInvIdMap.put(inv.Id,ilis);
            }
            insert invoiceLIsToInsert; 

            System.debug('QLE salisPerAmountPerServIdPerInvIdMap ' + salisPerAmountPerServIdPerInvIdMap);

            /*Insert invoice line (1 per Service) to generate Id. We link SALIs with the same Service to the same invoice line.*/
            for(Invoice__c inv : invoicesToInsert)
            {
                Contract_Home__c ctr = ctrPerIdMap.get(inv.Contract_Home__c);
                if(ctr!=null && ctr.Todos_after_invoicing__c!=null)
                {
                    String queueCountry = ctrPerIdMap.get(inv.Contract_Home__c).RecordTypeId==ContractHomeManager.mcmRtBEId?'BE':'FR';
                    taskToInsert.add(ServiceAppointmentManager.generateTaskMCMQueue(null,queueCountry, inv.Id,Label.TodosAfterInvoicing
                                                                        ,ctr.Todos_after_invoicing__c,1));  
                }  
                Map<Id,Map<Id,List<Service_Appointment_Line_Item__c>>> salisPerServIdPerCtrIdMap = salisPerServIdPerCtrIdPerAccIdMap.get(inv.Invoicing_Account__c);       
                Map<Id,List<Service_Appointment_Line_Item__c>> salisPerServIdMap = salisPerServIdPerCtrIdMap.get(inv.Contract_Home__c);
                Map<Id,Map<Decimal,List<Service_Appointment_Line_Item__c>>> salisPerAmountPerServIdMap = salisPerAmountPerServIdPerInvIdMap.get(inv.Id);
                Map<Id,Contractual_Service_Line_Item__c> csPerServIdMap = csPerServIdPerCtrIdMap.get(inv.Contract_Home__c);
                List<InvoiceLineItem__c> ilis = ilisPerInvIdMap.get(inv.Id);
                Integer i=0;
                System.debug('QLE salisPerServIdMap ' + salisPerServIdMap);
                //Compute total quantity and amount per invoice line (thus per service)
                for(Id serviceId : salisPerServIdMap.keySet())
                {  
                    Contractual_Service_Line_Item__c csli = csPerServIdMap.get(serviceId); 
                    if(serviceId==miscId || supplKmIds.contains(serviceId))
                    {
                        Double totalAmount = 0;
                        Double totalKm = 0;
                        InvoiceLineItem__c invLI = ilis.get(i);
                        List<Service_Appointment_Line_Item__c> saLineItems = salisPerServIdMap.get(serviceId);
                        for(Service_Appointment_Line_Item__c saLineItem : saLineItems)
                        {
                            if(supplKmIds.contains(serviceId))
                            {
                                if(saLineItem.TECH_Km__c!=null) totalKm = totalKm + saLineItem.TECH_Km__c; 
                            }
                            if(saLineItem.Amount__c!=null) totalAmount = totalAmount + saLineItem.Amount__c;  
                            saLineItem.InvoiceLineItem__c = invLI.Id; 
                            salisToUpdate.add(saLineItem);
                        }
                        invLI.Description__c= inv.Billing_Language__c=='NL'?saLineItems[0].Service__r.Service_Name_NL__c:saLineItems[0].Service__r.Service_Name_FR__c;
                        invLI.Unit_Price__c = csli!=null?csli.Price_Rate_1__c:null;
                        invLI.Quantity__c = supplKmIds.contains(serviceId)?totalKm:null;
                        invLI.Amount_Excluding_VAT_Currency__c = totalAmount;
                        invLI.Contractual_Service_Line_Item__c = csli!=null?csli.Id:null;
                        invLI.ILI_Order__c = saLineItems[0].Service__r.Order__c;
                        i++;
                    }
                    else 
                    {  
                        for(Decimal amt : salisPerAmountPerServIdMap.get(serviceId).keySet())
                        {
                            InvoiceLineItem__c invLI = ilis.get(i);
                            Double totalAmount = 0;
                            Integer quantity=0; // not simply saLineItems.size() since we shouldn't count line where Amount__c=
                            List<Service_Appointment_Line_Item__c> saliList = salisPerAmountPerServIdMap.get(serviceId).get(amt);
                            for(Service_Appointment_Line_Item__c saLineItem : saliList)
                            {
                                if(saLineItem.Amount__c!=null&&saLineItem.Amount__c!=0) 
                                {
                                    totalAmount = totalAmount + saLineItem.Amount__c;
                                    quantity = quantity + 1;
                                }
                                saLineItem.InvoiceLineItem__c = invLI.Id; 
                                salisToUpdate.add(saLineItem);
                            }
                            invLI.Description__c= inv.Billing_Language__c=='NL'?saliList[0].Service__r.Service_Name_NL__c:saliList[0].Service__r.Service_Name_FR__c;
                            invLI.Unit_Price__c = amt;
                            invLI.Quantity__c = quantity;
                            invLI.Amount_Excluding_VAT_Currency__c = totalAmount;
                            invLI.Contractual_Service_Line_Item__c = csli!=null?csli.Id:null;
                            invLI.ILI_Order__c = saliList[0].Service__r.Order__c;
                            i++;
                        }
                    }
                }
                for(Absence_Registration__c ar : absRegsPerCtrIdPerAccIdMap.get(inv.Invoicing_Account__c).get(inv.Contract_Home__c))
                {
                    invIdPerArIdMap.put(ar.Id,inv.Id);
                    ar.Invoice__c=inv.Id;
                    ar.Invoicing_Status__c=AbsenceRegistrationManager.INVOICING_STATUS_INVOICE_GENERATED;
                    arListToUpdate.add(ar);
                }
            }  
            if(!invoiceLIsToInsert.isEmpty())
            {
                Database.SaveResult[] srInvLineItems = Database.update(invoiceLIsToInsert,false); //update of total quantity and amount information
                for(Invoice__c invWithErr : InvoiceManager.processSaveResult(invoiceLIsToInsert,srInvLineItems))
                {
                    invoicesWithError.add(invWithErr);
                    invoicesWithErrorIds.add(invWithErr.Id);
                }
            }

            /*Update to link invoice line*/
            if(!salisToUpdate.isEmpty())
            {
                Database.SaveResult[] srSalis = Database.update(salisToUpdate,false);
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
                        if(!invoicesWithErrorIds.contains(invIdPerArIdMap.get(sali.Service_Appointment__r.Absence_Registration__c)))
                        {
                            Invoice__c inv = new Invoice__c(Id=invIdPerArIdMap.get(sali.Service_Appointment__r.Absence_Registration__c),Status__c=StaticConstants.INVOICE_STATUS_ERROR,Error_reason__c=errText,Invoicing_On_Hold__c=true);
                            invoicesWithError.add(inv);
                            invoicesWithErrorIds.add(invIdPerArIdMap.get(sali.Service_Appointment__r.Absence_Registration__c));
                        }
                    }
                }
            }

            /*Update to link invoice*/
            if(!arListToUpdate.isEmpty())
            {
                Database.SaveResult[] srArList = Database.update(arListToUpdate,false); 
                for(Invoice__c invWithErr : InvoiceManager.processSaveResult(arListToUpdate,srArList))
                {
                    if(!invoicesWithErrorIds.contains(invWithErr.Id))
                    {
                        invoicesWithError.add(invWithErr);
                        invoicesWithErrorIds.add(invWithErr.Id);
                    }
                }
            }
            Database.update(invoicesWithError,false); //update to put status in error

            /*After Invoice Todos + Inactive Invoicing Dep Task*/
            if(!taskToInsert.isEmpty()) Database.insert(taskToInsert,false);

        // }
        // catch(Exception e){
        //     if(invoiceBatchResult.size()==1)
        //     {
        //         invoiceBatchResult[0].Status__c='Failed';
        //         update invoiceBatchResult[0]; 
        //     }
        //     else {
        //         System.debug('ERROR massServicingInvoiceBatch ' + e.getMessage());
        //     }

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
            for (AggregateResult ar : aggR)  {
                String status = (String) ar.get('Status__c');
                Integer countRec = (Integer) ar.get('expr0');
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