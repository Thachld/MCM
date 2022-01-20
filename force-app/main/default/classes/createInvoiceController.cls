/*******************************************************************************
* @author		Novera - QLE
* @testClasses: CustomerInvoicingTest, DoctorRemunerationTest
* @date		    2020-09-25
* @description  Server-side controller of createInvoiceFromContractHome/createInvoiceFromAccount lightning components
********************************************************************************/
public without sharing class createInvoiceController
{

    public static Map<String,Id> servicePerVisitTypeFR{
        get{
            if(servicePerVisitTypeFR==null){
                Map<String,Id> serviceMap = ServiceAppointmentManager.servicePerVisitTypePerCountryMap.get('FR');
                servicePerVisitTypeFR =serviceMap;
            }
            return servicePerVisitTypeFR;
        }
        set;
    }
    

    public static Set<Id> basicOrSupplNotKmIds{
        get{
            if(basicOrSupplNotKmIds==null && servicePerVisitTypeFR!=null)
            {
                Set<Id> serviceIds = new Set<Id>();
                for(String key : servicePerVisitTypeFR.keySet())
                {
                   if(key!='Miscellaneous' || key!='Flat' || key!='Mountain' || key!='Km')
                    {
                        serviceIds.add(servicePerVisitTypeFR.get(key));
                    }
                }
                basicOrSupplNotKmIds = serviceIds;
            }
            return basicOrSupplNotKmIds;
        }
        set;
    }

    public static Set<Id> supplKmIds{
        get{
            if(supplKmIds==null && servicePerVisitTypeFR!=null)
            {
                Set<Id> serviceIds = new Set<Id>();
                for(String key : servicePerVisitTypeFR.keySet())
                {
                   if(key=='Flat' || key=='Mountain' || key=='Km')
                    {
                        serviceIds.add(servicePerVisitTypeFR.get(key));
                    }
                }
                supplKmIds = serviceIds;
            }
            return supplKmIds;
        }
        set;
    }

    public static Id miscFrServiceId{
        get{
            if(miscFrServiceId==null && servicePerVisitTypeFR!=null)
            {
                Id miscId;
                for(String key : servicePerVisitTypeFR.keySet())
                {
                   if(key=='Miscellaneous')
                    {
                        miscId = servicePerVisitTypeFR.get(key);
                    }
                }
                miscFrServiceId = miscId;
            }
            return miscFrServiceId;
        }
        set;
    }

    /*******************************************************************************
    * @author		Novera - QLE
    * @date		    2020-10-19
    * @description  OAPPMEDCHECK-323 Launch invoicing creation batch
    * @param		
    * @return		
    ********************************************************************************/
    @AuraEnabled
    public static Id launchInvoicingBatch(String typeOfInvoicing, Date startDate, Date endDate)
    {
        Savepoint sp = Database.setSavepoint();
        try{
            Id batchJobId;
            Integer totalNumberOfRec;
            if(typeOfInvoicing==InvoiceManager.INVOICE_TYPE_YEARLY_CONTRIBUTION_INVOICING)
            {
                System.debug('QLE HERE');
                Set<Id> ctrHomeIdSet = new Set<Id>();
                for(Contractual_Service_Line_Item__c csli : [SELECT Contract_Home__c FROM Contractual_Service_Line_Item__c 
                    WHERE Service__r.Service_category__c=:StaticConstants.SERVICE_CATEGORY_YEARLY_CONTRIBUTION
                        AND (Contract_Home__r.RecordTypeId=:ContractHomeManager.mcmRtFRId OR Contract_Home__r.RecordTypeId=:ContractHomeManager.mcmRtBEId)
                        AND Contract_Home__r.Next_due_date__c = LAST_MONTH 
                        AND Contract_Home__r.Blocked_For_Invoicing__c=FALSE
                        AND Id NOT IN (SELECT Contractual_Service_Line_Item__c FROM InvoiceLineItem__c WHERE RecordTypeId=:UtilsConstants.RT_ID_INVOICE_LINE_ITEM_MEDICAL_CONTROL AND CreatedDate = THIS_YEAR)])
                {
                    ctrHomeIdSet.add(csli.Contract_Home__c);
                }        
                totalNumberOfRec=ctrHomeIdSet.size();        
                System.debug('QLE totalNumberOfRec ' + totalNumberOfRec);
                if(totalNumberOfRec>0)
                {            
                    
                    batchJobId = Database.executeBatch(new massYearlyContributionInvoiceBatch(), 2000);
                }
                else
                {
                    throw new CustomException(Label.MassInvoicingNoCSLI);
                }
            }
            else if(typeOfInvoicing==InvoiceManager.INVOICE_TYPE_SERVICE_INVOICING)
            {
                
                Set<Id> ctrIdSet = new Set<Id>();
                totalNumberOfRec=0;
                for(Absence_Registration__c ar:[ SELECT Contract_Home__c FROM Absence_Registration__c 
                      WHERE Invoicing_Status__c=:AbsenceRegistrationManager.INVOICING_STATUS_INVOICE_TO_GENERATE AND TECH_Close_Date__c = LAST_MONTH  
                      AND Invoicing_on_hold__c=FALSE AND Contract_Home__r.Blocked_For_Invoicing__c=FALSE AND Contract_Home__r.RecordTypeId!=:ContractHomeManager.mcmRtPricingId])
                //     for(Absence_Registration__c ar:[ SELECT Contract_Home__c FROM Absence_Registration__c 
                //       WHERE Invoicing_Status__c=:AbsenceRegistrationManager.INVOICING_STATUS_INVOICE_TO_GENERATE 
                //       AND Invoicing_on_hold__c=FALSE AND Contract_Home__r.Blocked_For_Invoicing__c=FALSE AND Contract_Home__r.RecordTypeId!=:ContractHomeManager.mcmRtPricingId])
                {
                    if(ar.Contract_Home__c!=null)
                    {
                        ctrIdSet.add(ar.Contract_Home__c);
                        totalNumberOfRec++;
                    }
                }
                if(totalNumberOfRec>0)
                {                    
                    batchJobId = Database.executeBatch(new massServicingInvoiceBatch(), 2000);
                }
                else
                {
                    throw new CustomException(Label.MassInvoicingNoSA);
                }
            }
            else if(typeOfInvoicing==InvoiceManager.INVOICE_TYPE_DOCTOR_REMUNERATION)
            {
                Set<Id> doctorIdSet = new Set<Id>();
                totalNumberOfRec=0;
                for(ServiceAppointment sa:[ SELECT Assigned_Resource__r.AccountId FROM ServiceAppointment
                        WHERE Remuneration_Status__c=:ServiceAppointmentManager.REMUNERATION_STATUS_INVOICE_DETAIL_LINE_GENERATED
                        AND TECH_Close_Date__c = LAST_MONTH AND Remuneration_on_hold__c=FALSE])
                // for(ServiceAppointment sa:[ SELECT Assigned_Resource__r.AccountId FROM ServiceAppointment
                //         WHERE Remuneration_Status__c=:ServiceAppointmentManager.REMUNERATION_STATUS_INVOICE_DETAIL_LINE_GENERATED
                //        AND Remuneration_on_hold__c=FALSE AND Doctor_Convention__c!=null])
                {
                    if(sa.Assigned_Resource__r.AccountId!=null)
                    {
                        doctorIdSet.add(sa.Assigned_Resource__r.AccountId);
                        totalNumberOfRec++;
                    }
                }
                if(totalNumberOfRec>0)
                {                    
                    batchJobId = Database.executeBatch(new massDoctorRemunerationBatch(), 2000);
                }
                else
                {
                    throw new CustomException(Label.NoSAForRemuneration);
                }
            }
            else if(typeOfInvoicing==InvoiceManager.INVOICE_TYPE_END_OF_YEAR_INVOICING)
            {
                //TO DO
            }
            // HTR Add branch to handle send invoice to SAP
            else if(typeOfInvoicing==InvoiceManager.SEND_INVOICE_TO_SAP)
            {
                Database.executeBatch(new sendInvoiceToSAPBatch(), 50);
            }
            // HTR Add branch to handle send invoice to Scriptura
            else if(typeOfInvoicing==InvoiceManager.SEND_INVOICE_TO_SCRIPTURA)
            {
                Database.executeBatch(new sendInvoiceToScripturaBatch(), 50);
            }
            if(batchJobId!=null)
            {
                Invoice_Batch_Result__c result = new Invoice_Batch_Result__c(Batch_Id__c = batchJobId
                                                                            ,Status__c='Queued'
                                                                            ,Invoicing_Type__c=typeOfInvoicing); 
                insert result;
                return result.Id;
            } 
            return null;
        } catch(Exception e){
            Database.rollback(sp);
            System.debug('QLE e.getMessage() ' + e.getMessage()); 
            throw new AuraHandledException(e.getMessage());
        }
    }

    @AuraEnabled
    public static List<Invoice_Batch_Result__c> findRecentInvoicingBatches()
    {
        return [SELECT Id, Name , Status__c, Number_of_invoice_created__c, Number_of_errors__c, Invoicing_Type__c, CreatedDate FROM Invoice_Batch_Result__c ORDER BY CreatedDate DESC LIMIT 3];
    }

    /*******************************************************************************
    * @author		Novera - QLE
    * @date		    2020-10-19
    * @description  OAPPMEDCHECK-323 Display a list of all contracts in the system
                    that are blocked for invoicing
    * @param		
    * @return		
    ********************************************************************************/
    @AuraEnabled
    public static List<Contract_Home__c> findAllContractsBlockedForInvoicing()
    {
        return [SELECT Id, Name, Account__c, Account__r.Commercial_Account_Name__c 
                FROM Contract_Home__c WHERE Blocked_For_Invoicing__c=true  AND RecordTypeId!=:ContractHomeManager.mcmRtPricingId];
    }

    /*******************************************************************************
    * @author		Novera - QLE
    * @date		    2020-10-12
    * @description  OAPPMEDCHECK-137 Display a list of contracts, linked to a specific accounts, 
                    that are blocked for invoicing
    * @param		Id accountId  Id of the current account
    * @return		List<Contract_Home__c>
    ********************************************************************************/
    @AuraEnabled
    public static List<Contract_Home__c> findContractsBlockedForInvoicing(Id accountId)
    {
        return [SELECT Id, Name, Account__c, Account__r.Commercial_Account_Name__c 
                    FROM Contract_Home__c 
                    WHERE Account__c=:accountId 
                    AND Blocked_For_Invoicing__c=true]; 
    }

    /*******************************************************************************
    * @author		Novera - QLE
    * @date		    2020-09-26
    * @description  OAPPMEDCHECK-326 Display a warning to user if there's already a yearly contribution invoice
    *               for this year
    * @param		Contract_Home__c ctrH  contract home record (tab Invoices)
    * @return		Invoice__c mostRecentYearlyInv most recent yearly contribution invoice created 
    *               during the current year   
    ********************************************************************************/
    @AuraEnabled
    public static Invoice__c searchYearlyContributionInvoiceForThisYear(Contract_Home__c ctrH)
    {
        //Check if there's already a yearly contribution invoice for the current period
        if(ctrH!=null){
            List<Invoice__c> mostRecentYearlyInvList = [SELECT Id,CreatedDate,Name FROM Invoice__c 
                                                    WHERE Invoicing_Type__c =:InvoiceManager.INVOICE_TYPE_YEARLY_CONTRIBUTION_INVOICING
                                                    AND Contract_Home__c=:ctrH.Id
                                                    ORDER BY CreatedDate DESC];
            if(mostRecentYearlyInvList.size()>0)
            {
                Invoice__c  mostRecentYearlyInv =   mostRecentYearlyInvList[0];                                                              
                if(mostRecentYearlyInv.CreatedDate.year()==Date.today().year()) return mostRecentYearlyInv; 
            }
        }
        return null;
    }

    /*******************************************************************************
    * @author		Novera - QLE
    * @date		    2020-09-26
    * @description  OAPPMEDCHECK-326 Create Invoice from Contract home detail page
    * @param		Contract_Home__c ctrH  contract home record
    * @return		Id of the newly created invoice 
    ********************************************************************************/
    @AuraEnabled
    public static void createInvoiceFromContractHome(Contract_Home__c ctrH, String typeOfInvoicing)
    {
        /*
        Savepoint sp = Database.setSavepoint();
        if(typeOfInvoicing=='End of year invoicing')
        {
            throw new CustomException('This functionnality is not yet implemented.');
        }
        try{
            if(ctrH.Invoicing_Account__c==null)
            {
                throw new CustomException(Label.contractNoInvoicingAccount);
            }
            List<AccountContactRelation> acrList = [SELECT  Contact.Language__c FROM AccountContactRelation 
                                                WHERE AccountId =:ctrH.Invoicing_Account__c  AND (Invoicing_recipient_email__c=TRUE 
                                                OR Invoicing_recipient_post__c=TRUE)];
    
            String invLg = !acrList.isEmpty()?acrList[0].Contact.Language__c:'FR';                            

            String description;
            String queryCSLI = 'SELECT Id, Price_Rate_1__c, PO_Number__c, Service__r.Service_Name_FR__c, Service__r.Service_Name_NL__c FROM Contractual_Service_Line_Item__c'
                               + ' WHERE Contract_Home__c =\'' + ctrH.Id +'\'';
            if(typeOfInvoicing==InvoiceManager.INVOICE_TYPE_YEARLY_CONTRIBUTION_INVOICING)
            {
                queryCSLI = queryCSLI + ' AND Service__r.Service_category__c=\'' + StaticConstants.SERVICE_CATEGORY_YEARLY_CONTRIBUTION +'\'';
            }
            
            List<Contractual_Service_Line_Item__c> csliList = Database.query(queryCSLI);

            if(csliList.isEmpty())
            {
                throw new CustomException(Label.NoCSLI);
            }
            else if (csliList.size() > 1) {
                throw new CustomException(Label.MoreThanOneCSLI);
            }

            description = invLg=='NL'?csliList[0].Service__r.Service_Name_NL__c:csliList[0].Service__r.Service_Name_FR__c;

            //Define the invoicing account to put on the invoice
            Id invoicingAccId = ctrH.Invoicing_Account__c;
            String invoicingTerm = ctrH.Invoicing_Account__r.Invoicing_Terms__c!=null?ctrH.Invoicing_Account__r.Invoicing_Terms__c:ctrH.Invoicing_Terms__c;
            Decimal specificVAT = ctrH.Specific_VAT_Picklist__c!=null?Decimal.valueOf(ctrH.Specific_VAT_Picklist__c.remove('%')):null;
            String ctrHCountry =  ctrH.RecordTypeId==ContractHomeManager.mcmRtFRId?'FRA':ctrH.RecordTypeId==ContractHomeManager.mcmRtBEId?'BEL':'';
            String poNum = ctrHCountry=='FRA'?csliList[0].PO_Number__c:ctrHCountry=='BEL'?ctrH.Invoicing_Account__r.PO_Number__c:'';

            //Insert the invoice record 
            Invoice__c invoiceToCreate = InvoiceManager.createMCMInvoice('30',invLg,typeOfInvoicing,'Draft',ctrH.Id,ctrHCountry,invoicingTerm,invoicingAccId,null,'',specificVAT,poNum);
            insert invoiceToCreate;

            if(typeOfInvoicing==InvoiceManager.INVOICE_TYPE_YEARLY_CONTRIBUTION_INVOICING && csliList.size()==1)
            {
                Double unitPrice = csliList[0].Price_Rate_1__c!=null?csliList[0].Price_Rate_1__c:0; //Price of the Yearly contribution
                Integer quantity = 1;
                InvoiceLineItem__c invLI =  InvoiceLineItemManager.createMCMInvoiceLineItem(invoiceToCreate.Id,description,quantity,unitPrice,csliList[0].Id);
                insert invLI;     
            }
            return invoiceToCreate.Id; 
        } catch(Exception e){
            Database.rollback(sp);
            throw new AuraHandledException(e.getMessage());
        }
        */
    }


    /*******************************************************************************
    * @author		Novera - QLE
    * @date		    2020-09-26
    * @description  OAPPMEDCHECK-137 Create Invoice from Account home detail page(tab Invoices)
    *               The screen is only visible from an invoicing account
    * @param		Account invAcc : invoices must be generated for all accounts using this invoicing account
    * @return		Id of the newly created invoice 
    ********************************************************************************/
    @AuraEnabled
    public static String createInvoiceFromAccount(Account invAcc, String typeOfInvoicing, Date fromDate, Date toDate)
    {
        List<Absence_Registration__c> arListToUpdate = new List<Absence_Registration__c>(); //Invoicing Status must be updated
        List<Task> taskToInsert = new List<Task>();
        if(invAcc.Active_Department__c==false) //OAPPMEDCHECK-836
        {
            if(invAcc.Date_out__c <= fromDate)
            {
                throw new AuraHandledException(Label.commentTaskInactiveInvoicingDep);
            }
        }
        
        //OAPPMEDCHECK-660 totalAmount per Account, if 0, no need to generate Invoice
        List<AggregateResult> aggresult = [SELECT SUM(Amount__c) sumAmount  FROM Service_Appointment_Line_Item__c 
                        WHERE Invoicing_type__c = :ServiceAppointmentManager.INVOICE_DETAIL_LINE_CI_TYPE
                        AND Service_Appointment__r.Absence_Registration__r.Invoicing_Account__c=:invAcc.Id
                        AND Service_Appointment__r.Absence_Registration__r.Invoicing_Status__c=:AbsenceRegistrationManager.INVOICING_STATUS_INVOICE_TO_GENERATE
                        AND Service_Appointment__r.Absence_Registration__r.TECH_Close_Date__c >=:fromDate 
                        AND Service_Appointment__r.Absence_Registration__r.TECH_Close_Date__c <=:toDate
                        GROUP BY Service_Appointment__r.Absence_Registration__r.Invoicing_Account__c];
        if(aggresult.isEmpty())
        {
            throw new AuraHandledException(Label.NoARToInvoice);
        }
        else if(Integer.valueOf(aggresult[0].get('sumAmount'))==0 || Integer.valueOf(aggresult[0].get('sumAmount'))==null)
        {
            for(Absence_Registration__c ar : [SELECT Invoicing_Status__c FROM Absence_Registration__c WHERE Invoicing_Account__c=:invAcc.Id
            AND Invoicing_Status__c=:AbsenceRegistrationManager.INVOICING_STATUS_INVOICE_TO_GENERATE
            AND TECH_Close_Date__c >=:fromDate  AND TECH_Close_Date__c <=:toDate])
            {
                ar.Invoicing_Status__c = AbsenceRegistrationManager.INVOICING_STATUS_NO_INVOICING;
                arListToUpdate.add(ar);
            }
            try
            {
                update arListToUpdate;   
                return Label.TotalAmountZero; 
            }
            catch(Exception e)
            {
                throw new AuraHandledException(e.getMessage());
            }
        }
        else
        {
            Savepoint sp = Database.setSavepoint();
            try
            {
                //OAPPMEDCHECK-728 1 account, multiple contracts => multiple invoices
                Map<Id,Contract_Home__c> ctrPerIdMap = new Map<Id,Contract_Home__c>(); 
                Map<Id,Map<Id,Contractual_Service_Line_Item__c>> csPerServIdPerCtrIdMap = new  Map<Id,Map<Id,Contractual_Service_Line_Item__c>>();  
                Map<Id,Set<Id>> arIdsPerCtrId = new Map<Id,Set<Id>>();
                Map<Id,Map<Id,List<Service_Appointment_Line_Item__c>>> salisPerServIdPerCtrIdMap = new Map<Id,Map<Id,List<Service_Appointment_Line_Item__c>>>();
                List<Invoice__c> invoicesToInsert = new List<Invoice__c>();
                List<InvoiceLineItem__c> invoiceLIsToInsert = new List<InvoiceLineItem__c>();
                Map<Id,List<InvoiceLineItem__c>> ilisPerInvIdMap = new Map<Id,List<InvoiceLineItem__c>>();
                List<Service_Appointment_Line_Item__c> salisToUpdate = new List<Service_Appointment_Line_Item__c>();//SALI represent invoice detail line )- they must point to the parent invoice line
                /*Map<String,Id> servicePerVisitType = ServiceAppointmentManager.servicePerVisitTypePerCountryMap.get('FR');

                /**********************************Preparing the invoice details*******************************************/
                //Retrieve SALI that are part of the invoice between the specified period and group SALI per Service per Contract
                for(Service_Appointment_Line_Item__c saLineItem : [SELECT Id,Service__c,Service_Appointment__r.Absence_Registration__c
                        ,Amount__c,TECH_Km__c,Service_Appointment__r.Absence_Registration__r.Contract_Home__c
                        , Service__r.Service_Name_FR__c, Service__r.Service_Name_NL__c, Service__r.Order__c 
                    FROM Service_Appointment_Line_Item__c 
                    WHERE Invoicing_type__c = :ServiceAppointmentManager.INVOICE_DETAIL_LINE_CI_TYPE
                        AND Service_Appointment__r.Absence_Registration__r.Invoicing_Account__c=:invAcc.Id
                        AND Service_Appointment__r.Absence_Registration__r.Invoicing_Status__c=:AbsenceRegistrationManager.INVOICING_STATUS_INVOICE_TO_GENERATE
                        AND Service_Appointment__r.Absence_Registration__r.TECH_Close_Date__c >=:fromDate 
                        AND Service_Appointment__r.Absence_Registration__r.TECH_Close_Date__c <=:toDate])
                {
                    //Each AR must be linked to the correct invoice (using contract Id as key)
                    if(arIdsPerCtrId.containsKey(saLineItem.Service_Appointment__r.Absence_Registration__r.Contract_Home__c))
                    {
                        Set<Id> arIdSet = arIdsPerCtrId.get(saLineItem.Service_Appointment__r.Absence_Registration__r.Contract_Home__c);
                        arIdSet.add(saLineItem.Service_Appointment__r.Absence_Registration__c);
                        arIdsPerCtrId.put(saLineItem.Service_Appointment__r.Absence_Registration__r.Contract_Home__c,arIdSet); 
                    }
                    else 
                    {
                        arIdsPerCtrId.put(saLineItem.Service_Appointment__r.Absence_Registration__r.Contract_Home__c,new Set<Id>{saLineItem.Service_Appointment__r.Absence_Registration__c});    
                    }

                    //1 invoice per contract for the same invoicing account. 1 invoice line per service. 
                    if(salisPerServIdPerCtrIdMap.containsKey(saLineItem.Service_Appointment__r.Absence_Registration__r.Contract_Home__c))
                    {
                        Map<Id,List<Service_Appointment_Line_Item__c>> salisPerServIdMap = salisPerServIdPerCtrIdMap.get(saLineItem.Service_Appointment__r.Absence_Registration__r.Contract_Home__c);
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
                        salisPerServIdPerCtrIdMap.put(saLineItem.Service_Appointment__r.Absence_Registration__r.Contract_Home__c,salisPerServIdMap);
                    }
                    else 
                    {
                        Map<Id,List<Service_Appointment_Line_Item__c>> salisPerServIdMap = new  Map<Id,List<Service_Appointment_Line_Item__c>>();
                        salisPerServIdMap.put(saLineItem.Service__c, new List<Service_Appointment_Line_Item__c>{saLineItem});
                        salisPerServIdPerCtrIdMap.put(saLineItem.Service_Appointment__r.Absence_Registration__r.Contract_Home__c,salisPerServIdMap);
                    }
                }

                /**********************************Preparing the contract information*******************************************/
                for(Contract_Home__c ctr : [SELECT Id, Invoicing_Terms__c, Account__c, Invoicing_Account__r.Invoicing_Terms__c
                        ,Invoicing_Account__r.PO_Number__c,Specific_VAT_Picklist__c, PO_Number__c, RecordTypeId
                        ,Todos_after_invoicing__c
                        ,(SELECT Id, Service__c, Price_Rate_1__c FROM Contractual_Service_Line_Items__r WHERE Service__r.Service_category__c!='Pack' AND Service__r.Service_category__c!='Annual fee')
                    FROM Contract_Home__c WHERE Id IN:arIdsPerCtrId.keySet() AND RecordTypeId!=:ContractHomeManager.mcmRtPricingId])
                {
                    ctrPerIdMap.put(ctr.Id,ctr);
                    Map<Id,Contractual_Service_Line_Item__c> csPerServIdMap = new Map<Id,Contractual_Service_Line_Item__c>();
                    //Group Contractual Service Line Item per Service
                    for(Contractual_Service_Line_Item__c csli : ctr.Contractual_Service_Line_Items__r)
                    {
                        //There is only one active csli per service per contract (except pack) - check on insert of CSLI
                        csPerServIdMap.put(csli.Service__c,csli);
                        //csPerIdMap.put(csli.Id,csli);
                    } 
                    csPerServIdPerCtrIdMap.put(ctr.Id,csPerServIdMap);
                } 
                
                if(csPerServIdPerCtrIdMap.isEmpty())
                {
                    throw new CustomException(Label.noContractFound); 
                }

                /**********************************Preparing invoicing recipient information*******************************************/
                List<AccountContactRelation> acrList = [SELECT  Contact.Language__c FROM AccountContactRelation 
                                                WHERE AccountId =:invAcc.Id  AND (Invoicing_recipient_email__c=TRUE 
                                                OR Invoicing_recipient_post__c=TRUE)];
              
                /**********************************Preparing the invoices (1 per contract)*******************************************/
                for(Id ctrId : ctrPerIdMap.keySet())
                {
                    Contract_Home__c ctr = ctrPerIdMap.get(ctrId);
                    String invoicingTerm = ctr.Invoicing_Account__r.Invoicing_Terms__c!=null?ctr.Invoicing_Account__r.Invoicing_Terms__c:ctr.Invoicing_Terms__c;
                    Decimal specificVAT = ctr.Specific_VAT_Picklist__c!=null?Decimal.valueOf(ctr.Specific_VAT_Picklist__c.remove('%')):null;
                    String ctrHCountry =  ctr.RecordTypeId==ContractHomeManager.mcmRtFRId?'FRA':ctr.RecordTypeId==ContractHomeManager.mcmRtBEId?'BEL':'';
                    String poNum = ctrHCountry=='FRA'?ctr.PO_Number__c:ctrHCountry=='BEL'?ctr.Invoicing_Account__r.PO_Number__c:'';
                    String invLg = !acrList.isEmpty()?acrList[0].Contact.Language__c:'FR';
        
                    //Define invoice 
                    Invoice__c inv = InvoiceManager.createMCMInvoice('30',invLg,typeOfInvoicing,'Draft',ctr.Id,ctrHCountry,invoicingTerm,invAcc.Id,null,'',specificVAT,poNum,InvoiceManager.RT_ID_INVOICE_MEDICAL_CONTROL);
                    invoicesToInsert.add(inv);
                }
                insert invoicesToInsert;  // Invoice must be inserted to generate Id, so that we can reference it on Invoice Line Item

                //OAPPMEDCHECK-475
                Map<Id,Map<Id,Map<Decimal,List<Service_Appointment_Line_Item__c>>>> salisPerAmountPerServIdPerInvIdMap = new Map<Id,Map<Id,Map<Decimal,List<Service_Appointment_Line_Item__c>>>>();
                                
                /*Insert invoice line (1 per Service) to generate Id. We link SALIs with the same Service to the same invoice line.
                Placeholders, we insert as many lines as the number of services we have from the grouping of SALIs per Contract*/
                for(Invoice__c inv : invoicesToInsert)
                {
                    Contract_Home__c ctr = ctrPerIdMap.get(inv.Contract_Home__c);
                    if(ctr.Todos_after_invoicing__c!=null)
                    {
                        String queueCountry = ctr.RecordTypeId==ContractHomeManager.mcmRtBEId?'BE':'FR';
                        taskToInsert.add(ServiceAppointmentManager.generateTaskMCMQueue(null,queueCountry,inv.Id,Label.TodosAfterInvoicing
                                                                            ,ctr.Todos_after_invoicing__c,1));  
                    }
                    List<InvoiceLineItem__c> ilis = new List<InvoiceLineItem__c>();
                    Map<Id,Map<Decimal,List<Service_Appointment_Line_Item__c>>> salisPerAmountPerServIdMap = new Map<Id,Map<Decimal,List<Service_Appointment_Line_Item__c>>>();
                    for(Id serviceId : salisPerServIdPerCtrIdMap.get(inv.Contract_Home__c).keySet())
                    {
                        Map<Decimal,List<Service_Appointment_Line_Item__c>> salisPerAmountMap = new Map<Decimal,List<Service_Appointment_Line_Item__c>>();
                        if(serviceId==miscFrServiceId || supplKmIds.contains(serviceId))
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
                
                /*Insert invoice line (1 per Service) to generate Id. We link SALIs with the same Service to the same invoice line.*/
                for(Invoice__c inv : invoicesToInsert)
                {
                    Map<Id,List<Service_Appointment_Line_Item__c>> salisPerServIdMap = salisPerServIdPerCtrIdMap.get(inv.Contract_Home__c);
                    Map<Id,Map<Decimal,List<Service_Appointment_Line_Item__c>>> salisPerAmountPerServIdMap = salisPerAmountPerServIdPerInvIdMap.get(inv.Id);
                    Map<Id,Contractual_Service_Line_Item__c> csPerServIdMap = csPerServIdPerCtrIdMap.get(inv.Contract_Home__c);
                    List<InvoiceLineItem__c> ilis = ilisPerInvIdMap.get(inv.Id);
                    Integer i=0;
                    //Compute total quantity and amount per invoice line (thus per service)
                    for(Id serviceId : salisPerServIdMap.keySet())
                    {  
                        Contractual_Service_Line_Item__c csli = csPerServIdMap.get(serviceId); 
        
                        System.debug('QLE serviceId ' + serviceId); 
                        if(serviceId==miscFrServiceId || supplKmIds.contains(serviceId))
                        {
                            Double totalAmount = 0;
                            Double totalKm = 0;
                            InvoiceLineItem__c invLI = ilis.get(i);
                            List<Service_Appointment_Line_Item__c> saliList = salisPerServIdMap.get(serviceId);
                            for(Service_Appointment_Line_Item__c saLineItem : saliList)
                            {
                                if(supplKmIds.contains(serviceId))
                                {
                                    if(saLineItem.TECH_Km__c!=null) totalKm = totalKm + saLineItem.TECH_Km__c; 
                                }
                                if(saLineItem.Amount__c!=null) totalAmount = totalAmount + saLineItem.Amount__c;  
                                saLineItem.InvoiceLineItem__c = invLI.Id; 
                                salisToUpdate.add(saLineItem);
                            }
                            invLI.Description__c= inv.Billing_Language__c=='NL'?saliList[0].Service__r.Service_Name_NL__c:saliList[0].Service__r.Service_Name_FR__c;
                            invLI.Unit_Price__c = csli!=null?csli.Price_Rate_1__c:null;
                            invLI.Quantity__c = supplKmIds.contains(serviceId)?totalKm:null;
                            invLI.Amount_Excluding_VAT_Currency__c = totalAmount;
                            invLI.Contractual_Service_Line_Item__c = csli!=null?csli.Id:null;
                            invLI.ILI_Order__c = saliList[0].Service__r.Order__c;
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

                    for(Id arId : arIdsPerCtrId.get(inv.Contract_Home__c))
                    {
                        arListToUpdate.add(new Absence_Registration__c(Id=arId,Invoice__c=inv.Id
                            ,Invoicing_Status__c=AbsenceRegistrationManager.INVOICING_STATUS_INVOICE_GENERATED));
                    }
                }   
                update invoiceLIsToInsert;
                update salisToUpdate;
                update arListToUpdate;
                if(!taskToInsert.isEmpty()) insert taskToInsert;
                if(invoicesToInsert.size()==1)
                {
                    return invoicesToInsert[0].Id;
                }
                else
                {
                    return Label.multipleInvoices;
                }
            }
            catch(Exception e){
                Database.rollback(sp);
                throw new AuraHandledException(e.getMessage());
            }
        }
    }   

    /*******************************************************************************
    * @author		Novera - QLE
    * @date		    2020-04-09
    * @description  OAPPMEDCHECK-661 Create Remuneration from Doctor (Account) home detail page(tab Remunerations)
    *               The screen is only visible from an invoicing account
    * @param		
    * @return		Id of the newly created Remuneration 
    ********************************************************************************/
    @AuraEnabled
    public static String createRemunerationFromDoctorAccount(Account doc, String typeOfInvoicing, Date fromDate, Date toDate)
    {
        List<ServiceAppointment> saListToUpdate = new List<ServiceAppointment>(); //Invoicing Status must be updated
 
        //OAPPMEDCHECK-660 totalAmount per Account, if 0, no need to generate Remuneration
        List<AggregateResult> aggresult = [SELECT SUM(Amount__c) sumAmount  FROM Service_Appointment_Line_Item__c 
                        WHERE Invoicing_type__c = :ServiceAppointmentManager.INVOICE_DETAIL_LINE_REMUNERATION_TYPE
                        AND Service_Appointment__r.Assigned_Resource__r.AccountId=:doc.Id
                        AND Service_Appointment__r.Remuneration_Status__c=:ServiceAppointmentManager.REMUNERATION_STATUS_INVOICE_DETAIL_LINE_GENERATED
                        AND Service_Appointment__r.TECH_Close_Date__c >=:fromDate 
                        AND Service_Appointment__r.TECH_Close_Date__c <=:toDate
                        AND Service_Appointment__r.Remuneration_on_hold__c=FALSE
                        AND Service_Appointment__r.Doctor_Convention__c!=null
                        GROUP BY Service_Appointment__r.Assigned_Resource__r.AccountId];
        if(aggresult.isEmpty())
        {
            throw new AuraHandledException(Label.NoSAForRemuneration);
        }
        else if(Integer.valueOf(aggresult[0].get('sumAmount'))==0 || Integer.valueOf(aggresult[0].get('sumAmount'))==null)
        {
            for(ServiceAppointment sa : [SELECT Remuneration_Status__c FROM ServiceAppointment WHERE Assigned_Resource__r.AccountId=:doc.Id
            AND Remuneration_Status__c=:ServiceAppointmentManager.REMUNERATION_STATUS_INVOICE_DETAIL_LINE_GENERATED
            AND TECH_Close_Date__c >=:fromDate  AND TECH_Close_Date__c <=:toDate])
            {
                sa.Remuneration_Status__c = ServiceAppointmentManager.REMUNERATION_STATUS_INVOICE_DETAIL_LINE_GENERATED;
                saListToUpdate.add(sa);
            }
            try
            {
                update saListToUpdate;   
                return Label.TotalAmountZero; 
            }
            catch(Exception e)
            {
                throw new AuraHandledException(e.getMessage());
            }
        }
        else
        {
            Savepoint sp = Database.setSavepoint();
            try
            {
                //OAPPMEDCHECK-728 1 account, multiple contracts => multiple Remunerations
                Map<Id,Contract_Home__c> convPerIdMap = new Map<Id,Contract_Home__c>(); 
                Map<Id,Map<Id,Contractual_Service_Line_Item__c>> csPerServIdPerConvIdMap = new  Map<Id,Map<Id,Contractual_Service_Line_Item__c>>();  
                Map<Id,Set<Id>> saIdsPerConvId = new Map<Id,Set<Id>>();
                Map<Id,Map<Id,List<Service_Appointment_Line_Item__c>>> salisPerServIdPerCtrIdMap = new Map<Id,Map<Id,List<Service_Appointment_Line_Item__c>>>();
                Set<Id> serviceKmIdSet = new Set<Id>();
                List<Invoice__c> remunerationsToInsert = new List<Invoice__c>();
                List<InvoiceLineItem__c> RemunerationLIsToInsert = new List<InvoiceLineItem__c>();
                Map<Id,List<InvoiceLineItem__c>> ilisPerInvIdMap = new Map<Id,List<InvoiceLineItem__c>>();
                List<Service_Appointment_Line_Item__c> salisToUpdate = new List<Service_Appointment_Line_Item__c>();//SALI represent Remuneration detail line )- they must point to the parent Remuneration line
        
                /**********************************Preparing the Remuneration details*******************************************/
                //Retrieve SALI that are part of the Remuneration between the specified period and group SALI per Service per Contract
                for(Service_Appointment_Line_Item__c saLineItem : [SELECT Id,Service__c,Service__r.Service_Name_FR__c,Service__r.Service_Name_NL__c, Service__r.Order__c
                        ,Service_Appointment__c, Service_Appointment__r.Doctor_Convention__c,Amount__c,TECH_Km__c 
                    FROM Service_Appointment_Line_Item__c 
                    WHERE Invoicing_type__c = :ServiceAppointmentManager.INVOICE_DETAIL_LINE_REMUNERATION_TYPE
                        AND Service_Appointment__r.Assigned_Resource__r.AccountId=:doc.Id
                        AND Service_Appointment__r.Remuneration_Status__c=:ServiceAppointmentManager.REMUNERATION_STATUS_INVOICE_DETAIL_LINE_GENERATED
                        AND Service_Appointment__r.TECH_Close_Date__c >=:fromDate 
                        AND Service_Appointment__r.TECH_Close_Date__c <=:toDate])
                {
                    //For Remuneration detail line Km Flat or Km Mountain, OAPPMEDCHECK-343 display  Unit Price/Km  + total amount not total Km
                    //Help to identify the price in the contract avoicing query table Service for service Id
                    if(saLineItem.TECH_Km__c!=null)
                    {
                        serviceKmIdSet.add(saLineItem.Service__c);
                    }

                    //Each SA must be linked to the correct Remuneration (using contract Id as key)
                    if(saIdsPerConvId.containsKey(saLineItem.Service_Appointment__r.Doctor_Convention__c))
                    {
                        Set<Id> saIdSet = saIdsPerConvId.get(saLineItem.Service_Appointment__r.Doctor_Convention__c);
                        saIdSet.add(saLineItem.Service_Appointment__c);
                        saIdsPerConvId.put(saLineItem.Service_Appointment__r.Doctor_Convention__c,saIdSet); 
                    }
                    else 
                    {
                        saIdsPerConvId.put(saLineItem.Service_Appointment__r.Doctor_Convention__c,new Set<Id>{saLineItem.Service_Appointment__c});    
                    }

                    //1 Remuneration per contract for the same doctor. 1 Remuneration line per service. 
                    if(salisPerServIdPerCtrIdMap.containsKey(saLineItem.Service_Appointment__r.Doctor_Convention__c))
                    {
                        Map<Id,List<Service_Appointment_Line_Item__c>> salisPerServIdMap = salisPerServIdPerCtrIdMap.get(saLineItem.Service_Appointment__r.Doctor_Convention__c);
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
                        salisPerServIdPerCtrIdMap.put(saLineItem.Service_Appointment__r.Doctor_Convention__c,salisPerServIdMap);
                    }
                    else 
                    {
                        Map<Id,List<Service_Appointment_Line_Item__c>> salisPerServIdMap = new  Map<Id,List<Service_Appointment_Line_Item__c>>();
                        salisPerServIdMap.put(saLineItem.Service__c, new List<Service_Appointment_Line_Item__c>{saLineItem});
                        salisPerServIdPerCtrIdMap.put(saLineItem.Service_Appointment__r.Doctor_Convention__c,salisPerServIdMap);
                    }
                }

                /**********************************Preparing the convention information*******************************************/
                for(Contract_Home__c conv : [SELECT Id, Account__c, RecordTypeId, Specific_VAT_Picklist__c, Invoice_Digit_Doctor__c
                        ,(SELECT Id, Service__c, Price_Rate_1__c FROM Contractual_Service_Line_Items__r WHERE Service__r.Service_category__c!='Pack' AND Service__r.Service_category__c!='Annual fee')
                    FROM Contract_Home__c WHERE Id IN:saIdsPerConvId.keySet() AND RecordTypeId!=:ContractHomeManager.mcmRtPricingId])
                {
                    convPerIdMap.put(conv.Id,conv);
                    Map<Id,Contractual_Service_Line_Item__c> csIdPerServIdMap = new Map<Id,Contractual_Service_Line_Item__c>();   
                    //Group Contractual Service Line Item per Service
                    for(Contractual_Service_Line_Item__c csli : conv.Contractual_Service_Line_Items__r)
                    {
                        //There is only one active csli per service per contract (except pack) - check on insert of CSLI
                        csIdPerServIdMap.put(csli.Service__c,csli);
                    } 
                    csPerServIdPerConvIdMap.put(conv.Id,csIdPerServIdMap);
                } 
                
                if(csPerServIdPerConvIdMap.isEmpty())
                {
                    throw new CustomException(Label.noContractFound); 
                }


                /**********************************Preparing the Remunerations (1 per contract)*******************************************/
                for(Id convId : convPerIdMap.keySet())
                {
                    Contract_Home__c conv = convPerIdMap.get(convId);
                    String convCountry = conv.RecordTypeId==ContractHomeManager.mcmRtConventionFRId?'FRA':'BEL';
                    String invLg = doc.Account_Language__c!=null?doc.Account_Language__c:'FR';
                    Decimal specificVAT = conv.Specific_VAT_Picklist__c!=null?Decimal.valueOf(conv.Specific_VAT_Picklist__c.remove('%')):null;
        
                    //Define Remuneration 
                    Invoice__c inv = InvoiceManager.createMCMInvoice('19',invLg,typeOfInvoicing,'Draft',conv.Id,convCountry,null,conv.Account__c,null,'',specificVAT,null,InvoiceManager.RT_ID_REMUNERATION_MEDICAL_CONTROL);
                    inv.Invoice_Digit_Doctor__c = conv.Invoice_Digit_Doctor__c!=null?conv.Invoice_Digit_Doctor__c + 1:1;
                    remunerationsToInsert.add(inv);
                }
                insert remunerationsToInsert;  // Remuneration must be inserted to generate Id, so that we can reference it on Remuneration Line Item
                
                //OAPPMEDCHECK-959
                Map<Id,Map<Id,Map<Decimal,List<Service_Appointment_Line_Item__c>>>> salisPerAmountPerServIdPerRemIdMap = new Map<Id,Map<Id,Map<Decimal,List<Service_Appointment_Line_Item__c>>>>();
                     
                /*Insert Remuneration line (1 per Service) to generate Id. We link SALIs with the same Service to the same Remuneration line.
                Placeholders, we insert as many lines as the number of services we have from the grouping of SALIs per Contract*/
                for(Invoice__c inv : remunerationsToInsert)
                {
                    List<InvoiceLineItem__c> ilis = new List<InvoiceLineItem__c>();
                    Map<Id,Map<Decimal,List<Service_Appointment_Line_Item__c>>> salisPerAmountPerServIdMap = new Map<Id,Map<Decimal,List<Service_Appointment_Line_Item__c>>>();
                    for(Id serviceId : salisPerServIdPerCtrIdMap.get(inv.Contract_Home__c).keySet())
                    {
                        Map<Decimal,List<Service_Appointment_Line_Item__c>> salisPerAmountMap = new Map<Decimal,List<Service_Appointment_Line_Item__c>>();
                        if(serviceId==miscFrServiceId || supplKmIds.contains(serviceId))
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
                    salisPerAmountPerServIdPerRemIdMap.put(inv.Id,salisPerAmountPerServIdMap);
                    RemunerationLIsToInsert.addAll(ilis);
                    ilisPerInvIdMap.put(inv.Id,ilis);
                    /*
                    for(Id serviceId : salisPerServIdPerCtrIdMap.get(inv.Contract_Home__c).keySet())
                    {
                        ilis.add(new InvoiceLineItem__c(Invoice__c = inv.Id,RecordTypeId = UtilsConstants.RT_ID_INVOICE_LINE_ITEM_MEDICAL_CONTROL));
                    }
                    RemunerationLIsToInsert.addAll(ilis);
                    ilisPerInvIdMap.put(inv.Id,ilis);
                    */
                }
                insert RemunerationLIsToInsert; 

            
                /*Insert Remuneration line (1 per Service) to generate Id. We link SALIs with the same Service to the same Remuneration line.*/
                for(Invoice__c inv : remunerationsToInsert)
                {

                    Map<Id,List<Service_Appointment_Line_Item__c>> salisPerServIdMap = salisPerServIdPerCtrIdMap.get(inv.Contract_Home__c);
                    Map<Id,Map<Decimal,List<Service_Appointment_Line_Item__c>>> salisPerAmountPerServIdMap = salisPerAmountPerServIdPerRemIdMap.get(inv.Id);
                    Map<Id,Contractual_Service_Line_Item__c> csPerServIdMap = csPerServIdPerConvIdMap.get(inv.Contract_Home__c);
                    List<InvoiceLineItem__c> ilis = ilisPerInvIdMap.get(inv.Id);
                    Integer i=0;
                    //Compute total quantity and amount per Remuneration line (thus per service)
                    for(Id serviceId : salisPerServIdMap.keySet())
                    {  
                        Contractual_Service_Line_Item__c csli = csPerServIdMap.get(serviceId); 
        
                        System.debug('QLE serviceId ' + serviceId); 
                        if(serviceId==miscFrServiceId || supplKmIds.contains(serviceId))
                        {
                            Double totalAmount = 0;
                            Double totalKm = 0;
                            InvoiceLineItem__c invLI = ilis.get(i);
                            List<Service_Appointment_Line_Item__c> saliList = salisPerServIdMap.get(serviceId);
                            for(Service_Appointment_Line_Item__c saLineItem : saliList)
                            {
                                if(supplKmIds.contains(serviceId))
                                {
                                    if(saLineItem.TECH_Km__c!=null) totalKm = totalKm + saLineItem.TECH_Km__c; 
                                }
                                if(saLineItem.Amount__c!=null) totalAmount = totalAmount + saLineItem.Amount__c;  
                                saLineItem.InvoiceLineItem__c = invLI.Id; 
                                salisToUpdate.add(saLineItem);
                            }
                            invLI.Description__c= inv.Billing_Language__c=='NL'?saliList[0].Service__r.Service_Name_NL__c:saliList[0].Service__r.Service_Name_FR__c;
                            invLI.Unit_Price__c = csli!=null?csli.Price_Rate_1__c:null;
                            invLI.Quantity__c = supplKmIds.contains(serviceId)?totalKm:null;
                            invLI.Amount_Excluding_VAT_Currency__c = totalAmount;
                            invLI.Contractual_Service_Line_Item__c = csli!=null?csli.Id:null;
                            invLI.ILI_Order__c = saliList[0].Service__r.Order__c;
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
                        /*
                        List<Service_Appointment_Line_Item__c> saLineItems = salisPerServIdMap.get(serviceId);
                        Integer quantity=0; // not simply saLineItems.size() since we shouldn't count line where Amount__c=0
                        Double totalAmount = 0;
                        Double totalKm = 0;
                        Boolean isKm = serviceKmIdSet.contains(serviceId); 
                        Boolean isMisc = serviceId==miscFrServiceId; 
                        InvoiceLineItem__c invLI = ilis.get(i);
                        for(Service_Appointment_Line_Item__c saLineItem : saLineItems)
                        {
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
                        invLI.Description__c= inv.Billing_Language__c=='NL'?saLineItems[0].Service__r.Service_Name_NL__c:saLineItems[0].Service__r.Service_Name_FR__c;
                        invLI.Unit_Price__c = isKm&&totalKm>0?totalAmount/totalKm:quantity>0?totalAmount/quantity:null;
                        invLI.Quantity__c = isKm||isMisc?null:quantity;
                        invLI.Amount_Excluding_VAT_Currency__c = totalAmount;
                        invLI.Contractual_Service_Line_Item__c = csIdPerServIdMap.get(serviceId);
                        invLI.ILI_Order__c = saLineItems[0].Service__r.Order__c;
                        i++;*/
                    }
                    for(Id saId : saIdsPerConvId.get(inv.Contract_Home__c))
                    {
                        saListToUpdate.add(new ServiceAppointment(Id=saId, Remuneration_Note__c=inv.Id
                            ,Remuneration_Status__c=ServiceAppointmentManager.REMUNERATION_STATUS_REMUNERATION_NOTE_CREATED));
                    }
                }   
                update RemunerationLIsToInsert;
                update salisToUpdate;
                update saListToUpdate;
                if(remunerationsToInsert.size()==1)
                {
                    return remunerationsToInsert[0].Id;
                }
                else
                {
                    return Label.multipleInvoices;
                }
            }
            catch(Exception e)
            {
                Database.rollback(sp);
                System.debug('QLE e.getMessage() ' + e.getMessage());
                throw new AuraHandledException(e.getMessage());
            }
        }
    } 
}