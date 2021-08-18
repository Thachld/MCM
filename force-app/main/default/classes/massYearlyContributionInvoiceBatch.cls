/*******************************************************************************
* @author		Novera - QLE
* @date		    2020-10-22
* @description  Batch for mass creation of yearly contribution invoicesToInsert
********************************************************************************/
global class massYearlyContributionInvoiceBatch implements Database.Batchable<sObject>
{

    global Database.QueryLocator start(Database.BatchableContext bc) 
    {
        // collect the batches of contractrual service line item records to be passed to execute
        //we query active contractual service line item linked to service 'Yearly Contribution'
        //that are not already invoiced (meaning that there are invoice line items pointing to it)
        return Database.getQueryLocator('SELECT Id,Price_Rate_1__c,Contract_Home__c, PO_Number__c'
                                    +',Contract_Home__r.In_Place_Date__c ,Contract_Home__r.Next_due_date__c'
                                    +',Contract_Home__r.Invoicing_Terms__c,Contract_Home__r.Specific_VAT_Picklist__c'
                                    +',Contract_Home__r.RecordTypeId'
                                    +',Contract_Home__r.PO_Number__c'
                                    +',Contract_Home__r.Invoicing_Account__r.Invoicing_Terms__c'
                                    +',Contract_Home__r.Invoicing_Account__r.PO_Number__c'
                                    +',Contract_Home__r.Invoicing_Account__r.Active_Department__c'
                                    +',Contract_Home__r.Invoicing_Account__r.Date_out__c'
                                    +',Contract_Home__r.Todos_before_invoicing__c'
                                    +',Contract_Home__r.Todos_after_invoicing__c' 
                                    +',Service__r.Service_Name_FR__c'
                                    +',Service__r.Service_Name_NL__c'
                                    +',Contract_Home__r.Invoicing_Account__c FROM Contractual_Service_Line_Item__c' 
                                    +' WHERE Service__r.Service_category__c= \'' + StaticConstants.SERVICE_CATEGORY_YEARLY_CONTRIBUTION
                                    +'\' AND (Contract_Home__r.RecordTypeId=\'' + ContractHomeManager.mcmRtFRId 
                                    +'\' OR (Contract_Home__r.RecordTypeId=\'' + ContractHomeManager.mcmRtBEId
                                    + '\' AND Contract_Home__r.Yearly_Contribution__c=TRUE)) AND Contract_Home__r.Next_due_date__c = LAST_MONTH'
                                    +' AND Contract_Home__r.Active__c=TRUE'
                                    +' AND Contract_Home__r.Blocked_For_Invoicing__c=FALSE'
                                    +' AND Contract_Home__r.RecordTypeId!=\'' + ContractHomeManager.mcmRtPricingId + '\''
                                    +' AND Id NOT IN (SELECT Contractual_Service_Line_Item__c FROM InvoiceLineItem__c WHERE RecordTypeId=\'' 
                                    + UtilsConstants.RT_ID_INVOICE_LINE_ITEM_MEDICAL_CONTROL + '\' AND CreatedDate = THIS_YEAR)'
                                    );
    }

    // SELECT Id,Price_Rate_1__c,Contract_Home__c, Contract_Home__r.Invoicing_Account__c 
    // FROM Contractual_Service_Line_Item__c WHERE Service__r.Service_category__c='Yearly contribution'
    // AND ( Contract_Home__r.In_Place_Date__c  = LAST_MONTH OR Contract_Home__r.Next_due_date__c = LAST_MONTH )
    // AND Id NOT IN (SELECT Contractual_Service_Line_Item__c FROM InvoiceLineItem__c WHERE RecordTypeId='0121w000000D3ImAAK' AND CreatedDate = THIS_YEAR)

    global void execute(Database.BatchableContext bc, List<Contractual_Service_Line_Item__c> scope)
    {
        List<Invoice_Batch_Result__c> invoiceBatchResult = [SELECT Id FROM Invoice_Batch_Result__c WHERE Batch_Id__c =: bc.getJobId()]; 
        // try{
            Id batchResultId = invoiceBatchResult.size()==1?invoiceBatchResult[0].Id:null;
            List<Contractual_Service_Line_Item__c> csliToProcess = new List<Contractual_Service_Line_Item__c>();//OAPPMEDCHECK-836
            List<Invoice__c> invoicesToInsert = new List<Invoice__c>();
            List<Task> taskToInsert = new List<Task>(); //Initialize tasks to insert            
            List<InvoiceLineItem__c> invLineItemsToInsert = new List<InvoiceLineItem__c>();
            Map<Id,List<Contractual_Service_Line_Item__c>>  csliListPerCtrHomeId = new Map<Id,List<Contractual_Service_Line_Item__c>>(); 
            List<Contract_Home__c> contractHomeToUpdate = new List<Contract_Home__c>();
            Map<Id,String> beforeTodosPerCtr = new Map<Id,String>();
            Map<Id,String> afterTodosPerCtr = new Map<Id,String>();
            Map<Id,String> ctrHCountryPerCtrIdMap = new Map<Id,String>();
            Set<Id> invAccIds = new  Set<Id>();
            Map<Id,String> lgPerInvAccIdMap = new Map<Id,String>();
            DateTime startDateInvoicingPeriod = System.today().addMonths(-1).toStartOfMonth(); 

            //OAPPMEDCHECK-836 Procedure when invoicing account becomes inactive
            for(Contractual_Service_Line_Item__c csli : scope)
            {
                if(csli.Contract_Home__r.Invoicing_Account__r.Active_Department__c==false)
                {
                    system.debug('AMU Date_out__c '+ csli.Contract_Home__r.Invoicing_Account__r.Date_out__c);
                    if(csli.Contract_Home__r.Invoicing_Account__r.Date_out__c <= startDateInvoicingPeriod)
                    {
                       
                        String country = csli.Contract_Home__r.RecordTypeId==ContractHomeManager.mcmRtFRId?AbsenceRegistrationManager.COUNTRY_FR:AbsenceRegistrationManager.COUNTRY_BE;
                        taskToInsert.add(ServiceAppointmentManager.generateTaskMCMQueue(null,country,csli.Contract_Home__r.Invoicing_Account__c,Label.InvoicingNotPossibleOnInactiveDep
                            ,Label.commentTaskInactiveInvoicingDep,1));
                    }
                    else 
                    {
                        csliToProcess.add(csli);
                    }
                }
                else 
                {
                    csliToProcess.add(csli);
                }
            }
           
            //Group CSLI per Contract Home
            for(Contractual_Service_Line_Item__c csli : csliToProcess)
            { 
                if(csli.Contract_Home__r.Todos_before_invoicing__c==null)
                {
                    if(csliListPerCtrHomeId.containsKey(csli.Contract_Home__c))  
                    {
                            List<Contractual_Service_Line_Item__c> contractualServiceLineItemList = csliListPerCtrHomeId.get(csli.Contract_Home__c);
                            contractualServiceLineItemList.add(csli);
                            csliListPerCtrHomeId.put(csli.Contract_Home__c,contractualServiceLineItemList);
                    } 
                    else
                    {
                        csliListPerCtrHomeId.put(csli.Contract_Home__c,new List<Contractual_Service_Line_Item__c>{csli});
                        invAccIds.add(csli.Contract_Home__r.Invoicing_Account__c);
                    }
                    if(csli.Contract_Home__r.Todos_after_invoicing__c!=null)
                    { 
                        afterTodosPerCtr.put(csli.Contract_Home__c,csli.Contract_Home__r.Todos_after_invoicing__c);
                    }
                }
                else 
                {
                        taskToInsert.add(ServiceAppointmentManager.generateTaskMCMQueue(null, csli.Contract_Home__r.RecordTypeId==ContractHomeManager.mcmRtFRId?'FR':'BE'
                             ,csli.Contract_Home__c,Label.TodosBeforeInvoicing,csli.Contract_Home__r.Todos_before_invoicing__c,1));
                }
            }

            for(AccountContactRelation acr : [SELECT AccountId, Contact.Language__c FROM AccountContactRelation 
            WHERE AccountId IN:invAccIds AND (Invoicing_recipient_email__c=TRUE OR Invoicing_recipient_post__c=TRUE)])
            {
                lgPerInvAccIdMap.put(acr.AccountId,acr.Contact.Language__c);
            }

            //Create 1 invoice per contract home
            for(Id ctrHomeId : csliListPerCtrHomeId.keySet())
            {
                List<Contractual_Service_Line_Item__c> csliList  = csliListPerCtrHomeId.get(ctrHomeId);
                Contractual_Service_Line_Item__c csli = csliList[0];
                //Invoicing Term, if invoicing term on account!=null, get it. Else invoicing term on contract.
                String invoicingTerm = csli.Contract_Home__r.Invoicing_Account__r.Invoicing_Terms__c!=null?csli.Contract_Home__r.Invoicing_Account__r.Invoicing_Terms__c:csli.Contract_Home__r.Invoicing_Terms__c;
                Decimal specificVAT = csli.Contract_Home__r.Specific_VAT_Picklist__c!=null?Decimal.valueOf(csli.Contract_Home__r.Specific_VAT_Picklist__c.remove('%')):null;
                String ctrHCountry =  csli.Contract_Home__r.RecordTypeId==ContractHomeManager.mcmRtFRId?'FRA':csli.Contract_Home__r.RecordTypeId==ContractHomeManager.mcmRtBEId?'BEL':'';
                String poNum = ctrHCountry=='FRA'?csli.PO_Number__c:ctrHCountry=='BEL'?csli.Contract_Home__r.Invoicing_Account__r.PO_Number__c:'';
                ctrHCountryPerCtrIdMap.put(csli.Contract_Home__c,ctrHCountry);
                if(csliList.size()==1)
                {
                    Invoice__c invoiceToCreate = InvoiceManager.createMCMInvoice('30',lgPerInvAccIdMap.get(csli.Contract_Home__r.Invoicing_Account__c)
                                                                                ,StaticConstants.INVOICE_TYPE_YEARLY_CONTRIBUTION_INVOICING
                                                                                ,'Draft',ctrHomeId
                                                                                ,ctrHCountry,invoicingTerm
                                                                                ,csli.Contract_Home__r.Invoicing_Account__c
                                                                                ,batchResultId
                                                                                ,null,specificVAT,poNum,InvoiceManager.RT_ID_INVOICE_MEDICAL_CONTROL);  
                                                                                                                
                    Date nextDate =  csli.Contract_Home__r.In_Place_Date__c!=null&&csli.Contract_Home__r.Next_due_date__c==null?csli.Contract_Home__r.In_Place_Date__c.addYears(1):csli.Contract_Home__r.Next_due_date__c.addYears(1);                                                           
                    Contract_Home__c ctr = new Contract_Home__c(Id=ctrHomeId,Next_due_date__c = nextDate);    
                    contractHomeToUpdate.add(ctr);                                                                                       
                    invoicesToInsert.add(invoiceToCreate);
                }
                else if(csliList.size()>1)
                {                 
                    Invoice__c invoiceToCreate = InvoiceManager.createMCMInvoice('30',lgPerInvAccIdMap.get(csli.Contract_Home__r.Invoicing_Account__c)
                                                                                ,StaticConstants.INVOICE_TYPE_YEARLY_CONTRIBUTION_INVOICING
                                                                                ,StaticConstants.INVOICE_STATUS_ERROR
                                                                                ,ctrHomeId,ctrHCountry,null
                                                                                ,csli.Contract_Home__r.Invoicing_Account__c
                                                                                ,batchResultId
                                                                                ,Label.MoreThanOneCSLI
                                                                                ,specificVat,poNum,InvoiceManager.RT_ID_INVOICE_MEDICAL_CONTROL);                                                           
                    invoiceToCreate.Invoicing_On_Hold__c=true;                                    
                    Date nextDate =  csli.Contract_Home__r.In_Place_Date__c!=null&&csli.Contract_Home__r.Next_due_date__c==null?csli.Contract_Home__r.In_Place_Date__c.addYears(1):csli.Contract_Home__r.Next_due_date__c.addYears(1);                                                           
                    Contract_Home__c ctr = new Contract_Home__c(Id=ctrHomeId,Next_due_date__c = nextDate); 
                    contractHomeToUpdate.add(ctr);        
                    invoicesToInsert.add(invoiceToCreate);
                }
            }

            //Insert invoices
            if(!invoicesToInsert.isEmpty())
            {
                Database.SaveResult[] srInvoices = Database.insert(invoicesToInsert, true); // allOrNone = true, if one invoice can not be created, revert all the batch
            }

            //Create detail line for invoice that are not in error
            for(Invoice__c inv : invoicesToInsert)
            {
                if(afterTodosPerCtr.containsKey(inv.Contract_Home__c))
                {
                    taskToInsert.add(ServiceAppointmentManager.generateTaskMCMQueue(null
                        ,ctrHCountryPerCtrIdMap.get(inv.Contract_Home__c)=='FRA'?'FR':'BE'
                        ,inv.Id,Label.TodosAfterInvoicing,afterTodosPerCtr.get(inv.Contract_Home__c),1));                                  
                }
                if(inv.Status__c!=StaticConstants.INVOICE_STATUS_ERROR)
                {
                    List<Contractual_Service_Line_Item__c> csliList  = csliListPerCtrHomeId.get(inv.Contract_Home__c);
                    Contractual_Service_Line_Item__c csli = csliList[0];
                    Double unitPrice = csli.Price_Rate_1__c!=null?csli.Price_Rate_1__c:0; //Price of the Yearly contribution
                    String description = inv.Billing_Language__c=='NL'?csli.Service__r.Service_Name_NL__c:csli.Service__r.Service_Name_FR__c;
                    invLineItemsToInsert.add(InvoiceLineItemManager.createMCMInvoiceLineItem(inv.Id,description,1,unitPrice,csli.Id));
                }
            }

            List<Invoice__c> invoicesWithError = new List<Invoice__c>(); //Flag invoice as in error if error on insert of line item
            //Insert detail lines
            if(!invLineItemsToInsert.isEmpty())
            {
                Database.SaveResult[] srInvLineItems = Database.insert(invLineItemsToInsert, false);
                invoicesWithError.addAll(InvoiceManager.processSaveResult(invLineItemsToInsert,srInvLineItems));
            }
            if(!invoicesWithError.isEmpty()) Database.update(invoicesWithError,false);
            if(!contractHomeToUpdate.isEmpty()) Database.update(contractHomeToUpdate,false);
            if(!taskToInsert.isEmpty()) Database.insert(taskToInsert,false);
        // }
        // catch(Exception e){
        //     if(invoiceBatchResult.size()==1)
        //     {
        //         invoiceBatchResult[0].Status__c='Failed';
        //         update invoiceBatchResult[0]; 
        //     }
        //     else {
        //         System.debug('ERROR massYearlyContributionInvoiceBatch ' + e.getMessage());
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
            Integer draftCount=0;
            Integer errorCount=0;
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