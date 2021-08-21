public class ContractualServiceLineItemManager
{
    public static Service__c packFrService{
        get{
            if(packFrService==null){
                Service__c service = [SELECT Id, Order__c, Service_Name_FR__c FROM Service__c WHERE Available_for_country__c='FR' AND Service_category__c='Pack' LIMIT 1];
				packFrService = service;
            }
            return packFrService;
        }
        set;
    }

    public static Service__c annualFeeFrService{
        get{
            if(annualFeeFrService==null){
                Service__c service = [SELECT Id, Order__c, Service_Name_FR__c FROM Service__c WHERE Available_for_country__c='FR' AND Service_category__c='Annual Fee' LIMIT 1];
				annualFeeFrService = service;
            }
            return annualFeeFrService;
        }
        set;
    }

    /*******************************************************************************
    * @author		Novera - QLE
    * @date		    2020-01-06
    * @description  OAPPMEDCHECK-522 Update to invoicing process : starting point should be AR instead of SA
    *               Per contract, there must be only 1 contract line per service
    * @param		List<Contractual_Service_Line_Item__c> recordList
    * @return		
    // ********************************************************************************/
    public static void checkExistingLinePerService(List<Contractual_Service_Line_Item__c> recordList, Map<Id,Contractual_Service_Line_Item__c> oldMap)
    {
        Set<Id> parentCtrIdSet = new Set<Id>();
        Set<Id> contractWithError = new Set<Id>();
        for(Contractual_Service_Line_Item__c csli : recordList)
        {
            if( (oldMap ==null && csli.Contract_Home__c!=null) || (oldMap!=null && csli.Service__c!=oldMap.get(csli.Id).Service__c && csli.Contract_Home__c!=null))
            {   
                parentCtrIdSet.add(csli.Contract_Home__c);
            }
        }
        for(Contract_Home__c ctr : [SELECT Id, RecordType.DeveloperName, (SELECT Contract_Home__c, Service__c FROM Contractual_Service_Line_Items__r WHERE Service__r.Service_category__c!='Pack') FROM Contract_Home__c WHERE Id IN:parentCtrIdSet])
        {
            Set<Id> serviceIdSet = new Set<Id>();
            for(Contractual_Service_Line_Item__c csli : ctr.Contractual_Service_Line_Items__r)
            { 
                if(!serviceIdSet.contains(csli.Service__c))
                {
                    serviceIdSet.add(csli.Service__c);
                }
                else{
                    contractWithError.add(csli.Contract_Home__c);
                    break;
                }
            }
        }
        for(Contractual_Service_Line_Item__c csli : recordList)
        {
            if(contractWithError.contains(csli.Contract_Home__c)) csli.addError(Label.ActiveLineForService);
        }

    }

    /*******************************************************************************
    * @author		Novera - QLE
    * @date		    2020-12-03
    * @description  OAPPMEDCHECK-474 Create contract from main account - France
    *               For MCM, a contract home is used to represent a price book, and contract line item to represent price book line item
    *               On update of a pricebook line item, we need to check whether the corresponding price book is in used. If yes=>Error.
    *               To perform a price change, user must create a new price book. 
    * @param		List<Contractual_Service_Line_Item__c> recordList 
    *               Map<Id, Contractual_Service_Line_Item__c> recordOldValueMap
    * @return		void
    ********************************************************************************/
    public static void checkIfPriceBookLineItemInUse(List<Contractual_Service_Line_Item__c> recordList, Map<Id, Contractual_Service_Line_Item__c> recordOldValueMap)
    {
        Set<Id> ctrIdSet = new Set<Id>();
        Map<Id,Contract_Home__c> pbPerCsli = new Map<Id,Contract_Home__c>();

        for(Contractual_Service_Line_Item__c csli: recordList)
        {
            if(csli.Contract_Home__c != null)
            {
                ctrIdSet.add(csli.Contract_Home__c);
            }
        }

        if(ctrIdSet != null && !ctrIdSet.isEmpty())
        {
            for(Contractual_Service_Line_Item__c csli: recordList)
            {
                for(Contract_Home__c ctr : [SELECT Id, Contract_Country__c FROM Contract_Home__c WHERE Id IN:ctrIdSet 
                                    AND RecordTypeId=:ContractHomeManager.mcmRtPricingId AND Contract_Country__c='FRA'])
                {
                    pbPerCsli.put(csli.Id, ctr);
                }
            }
            
            if(!pbPerCsli.isEmpty())
            {
                Set<Id> pbIdSet = new Set<Id>();
                Map<Id,Integer> countContractPerPbId = new Map<Id,Integer>();
                for(Contractual_Service_Line_Item__c csli : recordList){
                    if(pbPerCsli.containsKey(csli.Id) && recordOldValueMap.get(csli.Id).Price_Rate_1__c!=null && csli.Price_Rate_1__c!=recordOldValueMap.get(csli.Id).Price_Rate_1__c){
                        pbIdSet.add(csli.Contract_Home__c);
                    }
                }
                for(AggregateResult ar : [SELECT Pricing__c, count(Id) countCtr FROM Contract_Home__c WHERE Pricing__c IN:pbIdSet GROUP BY Pricing__c])
                {
                    countContractPerPbId.put(String.valueOf(ar.get('Pricing__c')),Integer.valueOf(ar.get('countCtr')));
                }
                for(Contractual_Service_Line_Item__c csli : recordList){
                    if(pbPerCsli.containsKey(csli.Id) && countContractPerPbId.get(csli.Contract_Home__c) > 0){
                        csli.addError(Label.UpdatePriceBookLineItem);
                    }
                }
            }
        }
    }
    
    /*******************************************************************************
    * @author		Novera - QLE
    * @date		    2020-12-03
    * @description  OAPPMEDCHECK-474 On creation of a contract, CSLI are inserted automatically
    * Operators can delete CSLI that are not needed. This method prevent operator from wrongly deleting CSLI in used.
    * @param		List<Contractual_Service_Line_Item__c>  list of CSLIs
    * @return		void
    ********************************************************************************/
    public static void checkContractualLineItemLink(List<Contractual_Service_Line_Item__c> recordList)
    {
        
        Set<Id> csliIdSet = new Set<Id>();
        for(Contractual_Service_Line_Item__c csli : recordList){
            csliIdSet.add(csli.Id);
        }

        Map<Id,Integer> saCountPerCsliIdMap = new Map<Id,Integer>();
        Map<Id,Integer> ilCountPerCsliIdMap = new Map<Id,Integer>();
        for(AggregateResult ar : [SELECT Contractual_Service_Line_Item__c, count(Id) saCount FROM ServiceAppointment WHERE Contractual_Service_Line_Item__c IN: csliIdSet GROUP BY Contractual_Service_Line_Item__c])
        {
            saCountPerCsliIdMap.put(String.valueOf(ar.get('Contractual_Service_Line_Item__c')),Integer.valueOf(ar.get('saCount')));
        }
        for(AggregateResult ar : [SELECT Contractual_Service_Line_Item__c, count(Id) ilCount FROM InvoiceLineItem__c WHERE Contractual_Service_Line_Item__c IN: csliIdSet GROUP BY Contractual_Service_Line_Item__c])
        {
            ilCountPerCsliIdMap.put(String.valueOf(ar.get('Contractual_Service_Line_Item__c')),Integer.valueOf(ar.get('ilCount')));
        }
        
        for(Contractual_Service_Line_Item__c csli : recordList){
            if(saCountPerCsliIdMap.get(csli.Id)>0 || ilCountPerCsliIdMap.get(csli.Id)>0)
            {
                csli.addError(Label.DeleteCSLI);
            }
        }

    }

    /*******************************************************************************
    * @author		Novera - QLE
    * @date		    2020-12-03
    * @description  OAPPMEDCHECK-368 Create invoice lines - Pack prepayment
    *               When CSLIs with pack services are inserted, we automatically create the corresponding invoices
    * @param		List<Contractual_Service_Line_Item__c> list of CSLIs with pack services
    * @return		voice
    ********************************************************************************/
    public static void createPackInvoicing(List<Contractual_Service_Line_Item__c> recordList)
    {  
        List<Contractual_Service_Line_Item__c> csliList= new List<Contractual_Service_Line_Item__c>();
        Set<Id> ctrIds = new Set<Id>();
        List<Invoice__c> invoicesToCreate = new List<Invoice__c>(); 
        Map<Id,Invoice__c> invoiceToCreatePerCsliId = new Map<Id,Invoice__c>();
        List<Task> taskToInsert = new List<Task>();

        for(Contractual_Service_Line_Item__c csli : recordList)
        {
            if(csli.Parent_Contract_RT__c == ContractHomeManager.CONTRACT_HOME_RT_MCM_FR_CONTRACT && csli.Service__c == packFrService.Id  
                && csli.Is_From_Versioning__c==false && csli.Is_From_Migration__c==false)
            {
                csliList.add(csli);
                ctrIds.add(csli.Contract_Home__c);
            }
        }

        Map<Id,Contract_Home__c> ctrMap = new Map<Id,Contract_Home__c>([SELECT Id, Invoicing_Terms__c, Specific_VAT_Picklist__c , Invoicing_Account__c
                , Invoicing_Account__r.Invoicing_Terms__c, RecordTypeId, Todos_after_invoicing__c,Invoicing_Account__r.Active_Department__c
                FROM Contract_Home__c WHERE Id IN:ctrIds]);

        if(ctrIds!=null && !ctrIds.isEmpty())
        {
            for(Contractual_Service_Line_Item__c csli : csliList)
            {
                Contract_Home__c ctr = ctrMap.get(csli.Contract_Home__c);
                System.debug('QLE ctr.Invoicing_Account__r.Active_Department__c ' + ctr.Invoicing_Account__r.Active_Department__c);
                if(ctr.Invoicing_Account__r.Active_Department__c)
                {
                    //Pack invoicing is only for France so Billing Language = FR
                    String invoicingTerm = ctr.Invoicing_Account__r.Invoicing_Terms__c!=null?ctr.Invoicing_Account__r.Invoicing_Terms__c:ctr.Invoicing_Terms__c;
                    Decimal specificVAT = ctr.Specific_VAT_Picklist__c!=null?Decimal.valueOf(ctr.Specific_VAT_Picklist__c.remove('%')):0;
                    String ctrHomeCountry = ctr.RecordTypeId==ContractHomeManager.mcmRtFRId?'FRA':ctr.RecordTypeId==ContractHomeManager.mcmRtBEId?'BEL':'';
                    Invoice__c invoiceToCreate = InvoiceManager.createMCMInvoice(INVOICEMANAGER.INVOICE_DOCUMENT_TYPE_30 ,'FR',InvoiceManager.INVOICE_TYPE_PACK_INVOICING,InvoiceManager.INVOICE_STATUS_DRAFT,csli.Contract_Home__c,ctrHomeCountry,invoicingTerm,ctr.Invoicing_Account__c,null,'',specificVat,null,InvoiceManager.RT_ID_INVOICE_MEDICAL_CONTROL);
                    invoicesToCreate.add(invoiceToCreate); 
                    invoiceToCreatePerCsliId.put(csli.Id,invoiceToCreate);
                }
                else
                {
                    csli.addError(Label.InvoicingNotPossibleOnInactiveDep);
                }
            }
            if(!invoicesToCreate.isEmpty()) insert invoicesToCreate;
            
            List<InvoiceLineItem__c> invLineItemList = new List<InvoiceLineItem__c>(); 
            for(Contractual_Service_Line_Item__c csli : csliList)
            {
                Invoice__c invToCreate = invoiceToCreatePerCsliId.get(csli.Id);
                if(invToCreate!=null)
                {
                    Contract_Home__c ctr = ctrMap.get(csli.Contract_Home__c);
                    if(ctr.Todos_after_invoicing__c!=null)
                    {
                        String queueCountry = ctr.RecordTypeId==ContractHomeManager.mcmRtBEId?'BE':'FR';
                        taskToInsert.add(ServiceAppointmentManager.generateTaskMCMQueue(null, queueCountry,invoiceToCreatePerCsliId.get(csli.Id).Id,Label.TodosAfterInvoicing
                        ,ctr.Todos_after_invoicing__c,1));  
                    } 
                    String description = packFrService.Service_Name_FR__c; 
                    if(csli.Pack_volume__c!=null) description = description + ' ' + csli.Pack_volume__c;
                    Double unitPrice = csli.Price_Rate_1__c!=null?csli.Price_Rate_1__c:null; //Price of the Yearly contribution
                    InvoiceLineItem__c invLineItem = InvoiceLineItemManager.createMCMInvoiceLineItem(invToCreate.Id,description,1,unitPrice,csli.Id);
                    invLineItem.ILI_Order__c = packFrService.Order__c;
                    invLineItemList.add(invLineItem);   
                }
            }
            if(!invLineItemList.isEmpty())  insert invLineItemList;
            if(!taskToInsert.isEmpty()) insert taskToInsert;
        }
    }

    /*******************************************************************************
    * @author		Novera - QLE
    * @date		    2020-04-13
    * @description  OAPPMEDCHECK-763 Yearly contribution FR - optimisations
    *               When CSLI yearly contribution is inserted, we automatically create the corresponding invoice
    * @param		List<Contractual_Service_Line_Item__c> list of CSLIs with yearly contribution
    * @return		voice
    ********************************************************************************/
    
    public static void createYearlyContributionInvoicing(List<Contractual_Service_Line_Item__c> recordList, Map<Id,Contract_Home__c> parentMap)
    {   
       
        List<Contractual_Service_Line_Item__c> csliList= new List<Contractual_Service_Line_Item__c>();
        List<Contract_Home__c> contractHomeToUpdate = new List<Contract_Home__c>();
        Set<Id> ctrIds = new  Set<Id>();
        List<Task> taskToInsert = new List<Task>();
        for(Contractual_Service_Line_Item__c csli : recordList)
        {
            if(!csli.Parent_contract_is_specific__c || parentMap!=null)
            {
                if(csli.Parent_Contract_RT__c == ContractHomeManager.CONTRACT_HOME_RT_MCM_FR_CONTRACT 
                && csli.Service__c == annualFeeFrService.Id && !csli.Is_From_Versioning__c && !csli.Is_From_Migration__c)
                {
                    csliList.add(csli);
                    ctrIds.add(csli.Contract_Home__c);
                }
            }
        }

        if(ctrIds!=null && !ctrIds.isEmpty())
        {
            List<Invoice__c> invoicesToCreate = new List<Invoice__c>(); 
            Map<Id,Invoice__c> invoiceToCreatePerCsliId = new Map<Id,Invoice__c>(); 
            List<InvoiceLineItem__c> invLineItemList = new List<InvoiceLineItem__c>(); 
            Map<Id,Contract_Home__c> ctrMap = new Map<Id,Contract_Home__c>([SELECT Id, Invoicing_Terms__c, Specific_VAT_Picklist__c , Invoicing_Account__c, In_Place_Date__c
                ,Invoicing_Account__r.PO_Number__c, Invoicing_Account__r.Invoicing_Terms__c, RecordTypeId, Todos_after_invoicing__c, Invoicing_Account__r.Active_Department__c
                FROM Contract_Home__c WHERE Id IN:ctrIds]);
    
            for(Contractual_Service_Line_Item__c csli : csliList)
            {
                Contract_Home__c ctr = ctrMap.get(csli.Contract_Home__c);
                if(ctr.Invoicing_Account__r.Active_Department__c)
                {
                    String invoicingTerm = ctr.Invoicing_Account__r.Invoicing_Terms__c!=null?ctr.Invoicing_Account__r.Invoicing_Terms__c:ctr.Invoicing_Terms__c;
                    Decimal specificVAT = ctr.Specific_VAT_Picklist__c!=null?Decimal.valueOf(ctr.Specific_VAT_Picklist__c.remove('%')):0;
                    Invoice__c invoiceToCreate = InvoiceManager.createMCMInvoice(INVOICEMANAGER.INVOICE_DOCUMENT_TYPE_30 ,'FR',InvoiceManager.INVOICE_TYPE_YEARLY_CONTRIBUTION_INVOICING,InvoiceManager.INVOICE_STATUS_DRAFT
                            ,csli.Contract_Home__c,'FRA',invoicingTerm,ctr.Invoicing_Account__c,null,''
                            ,specificVAT,csli.PO_Number__c,InvoiceManager.RT_ID_INVOICE_MEDICAL_CONTROL);
                    invoicesToCreate.add(invoiceToCreate); 
                    invoiceToCreatePerCsliId.put(csli.Id,invoiceToCreate);
                }
                else
                {
                    String country = ctr.RecordTypeId==ContractHomeManager.mcmRtFRId?AbsenceRegistrationManager.COUNTRY_FR:AbsenceRegistrationManager.COUNTRY_BE;
                    if(parentMap!=null)
                    {
                        parentMap.get(csli.Contract_Home__c).addError(Label.InvoicingNotPossibleOnInactiveDep);
                    }
                    else
                    {
                        csli.addError(Label.InvoicingNotPossibleOnInactiveDep);
                    }
                }
            }
            if(!invoicesToCreate.isEmpty()) insert invoicesToCreate;
    
            for(Contractual_Service_Line_Item__c csli : csliList)
            {
                Invoice__c invToCreate = invoiceToCreatePerCsliId.get(csli.Id);
                if(invToCreate!=null)
                {
                    Contract_Home__c ctr = ctrMap.get(csli.Contract_Home__c);
                    if(ctr.Todos_after_invoicing__c!=null)
                    {
                        String queueCountry = ctr.RecordTypeId==ContractHomeManager.mcmRtBEId?'BE':'FR';
                        taskToInsert.add(ServiceAppointmentManager.generateTaskMCMQueue(null,queueCountry,invoiceToCreatePerCsliId.get(csli.Id).Id,Label.TodosAfterInvoicing
                        ,ctr.Todos_after_invoicing__c,1));  
                    } 
                    String description = annualFeeFrService.Service_Name_FR__c; 
                    Double unitPrice = csli.Price_Rate_1__c; //Price of the Yearly contribution
                    InvoiceLineItem__c invLineItem = InvoiceLineItemManager.createMCMInvoiceLineItem(invToCreate.Id,description,1,unitPrice,csli.Id);
                    invLineItem.ILI_Order__c = annualFeeFrService.Order__c;  
                    invLineItemList.add(invLineItem);                                                              
                    ctr.Next_due_date__c = ctr.In_Place_Date__c.addYears(1); 
                    contractHomeToUpdate.add(ctr);   
                }
            }
            if(!invLineItemList.isEmpty()) insert invLineItemList;
            if(!contractHomeToUpdate.isEmpty()) update contractHomeToUpdate;
            if(!taskToInsert.isEmpty()) insert taskToInsert;
        }
    }
   
    /*******************************************************************************
    * @author		Novera - QLE
    * @date		    2020-04-19
    * @description  OAPPMEDCHECK-754 Creation invoices - changes due to big accounts
    * @param		List<Contractual_Service_Line_Item__c> list of CSLIs 
    * @return		voice
    ********************************************************************************/
    
    public static void checkInvoicingRecipient(List<Contractual_Service_Line_Item__c> recordList)
    {   
        Set<Id> ctrIds = new Set<Id>();
        Set<Id> invAccIds = new Set<Id>();
        Map<Id,Id> invAccPerCtrId = new Map<Id,Id>();
        List<Contractual_Service_Line_Item__c> csliToProcess = new List<Contractual_Service_Line_Item__c>();
        Map<Id,Id> recipientIdPerInvAccIdMap = new Map<Id,Id>();
        for(Contractual_Service_Line_Item__c csli : recordList)
        {
            if(!csli.Parent_contract_is_specific__c && csli.Parent_Contract_RT__c == ContractHomeManager.CONTRACT_HOME_RT_MCM_FR_CONTRACT && csli.Is_From_Versioning__c==false
                && (csli.Service__c == packFrService.Id || csli.Service__c == annualFeeFrService.Id))
            {
                ctrIds.add(csli.Contract_Home__c);
                csliToProcess.add(csli);
            }
        }
        if(ctrIds!=null)
        {
            for(Contract_Home__c ctr : [SELECT Invoicing_Account__c FROM Contract_Home__c WHERE Id IN:ctrIds])
            {
                if(ctr.Invoicing_Account__c!=null)
                {
                    invAccIds.add(ctr.Invoicing_Account__c);
                    invAccPerCtrId.put(ctr.Id,ctr.Invoicing_Account__c);
                }
            }
            if(invAccIds!=null)
            {
                for(AccountContactRelation acr : [SELECT  AccountId, ContactId FROM AccountContactRelation 
                    WHERE AccountId IN:invAccIds  AND (Invoicing_recipient_email__c=TRUE OR Invoicing_recipient_post__c=TRUE)])
                {
                    recipientIdPerInvAccIdMap.put(acr.AccountId,acr.ContactId);
                }
            }
            for(Contractual_Service_Line_Item__c csli : csliToProcess)
            {
                Id invAccId = invAccPerCtrId!=null?invAccPerCtrId.get(csli.Contract_Home__c):null;
                if(invAccId==null)
                {
                    csli.addError(Label.contractNoInvoicingAccount);
                }
                else
                {
                    
                    Id contactId = recipientIdPerInvAccIdMap!=null?recipientIdPerInvAccIdMap.get(invAccId):null;
                    if(contactId==null)
                    {
                        csli.addError(Label.MissingInvoicingRecipient);
                    }
                }
            }
        }

    }


    /*******************************************************************************
    * @author		Novera - TLE
    * @date		    2021-08-18
    * @description  OAPPMEDCHECK-957 No changes to CSLI allowed when linked IDL
    * @param		List<Contractual_Service_Line_Item__c> list of CSLIs 
    * @param		Map<Id, Contractual_Service_Line_Item__c> Map of Old CSLIs     
    * @return		voice
    ********************************************************************************/
    public static void checkIfContractServiceInUse(List<Contractual_Service_Line_Item__c> recordList, Map<Id, Contractual_Service_Line_Item__c> recordOldValueMap){
        Set<String> contractIds = new Set<String>();
        Set<String> setCheckIds = new Set<String>();
        Set<String> setBeRecordType = new Set<String>();
        setBeRecordType = beContRecordType;

        //Get CSLIs had changed Price and Supplement
        System.debug('setBeRecordType=>' + setBeRecordType);
        for(Contractual_Service_Line_Item__c newCsli: recordList){            
            Contractual_Service_Line_Item__c oldCsli = recordOldValueMap.get(newCsli.Id);
            if( setBeRecordType.contains(newCsli.Parent_Contract_RT__c)
                && (newCsli.Price_rate_1__c != oldCsli.Price_rate_1__c 
                    || newCsli.Supplement__c != oldCsli.Supplement__c)
                ){
                    contractIds.add(newCsli.Contract_Home__c);
            }
        }

        System.debug('contractIds=>' + contractIds);
        //Find relate IDL
        for(Service_Appointment_Line_Item__c idl: [SELECT Service__c, Service_Appointment__r.Contract_Home__c 
                                                    FROM Service_Appointment_Line_Item__c 
                                                    WHERE Service_Appointment__r.Contract_Home__c IN :contractIds ]){
            if(!String.isBlank(idl.Service_Appointment__r.Contract_Home__c)
                && !String.isBlank(idl.Service__c)){
                    String key =  idl.Service_Appointment__r.Contract_Home__c + '##' + idl.Service__c;
                    setCheckIds.add(key);
            }              
        }

        System.debug('setCheckIds=>' + setCheckIds);
        //Checking is exists IDL
        for(Contractual_Service_Line_Item__c newCsli: recordList){
            Contractual_Service_Line_Item__c oldCsli = recordOldValueMap.get(newCsli.Id);
            if( setBeRecordType.contains(newCsli.Parent_Contract_RT__c) ){
                if( newCsli.Price_rate_1__c != oldCsli.Price_rate_1__c){
                    String keycheck =  newCsli.Contract_Home__c + '##' + newCsli.Service__c;    
                    System.debug('keycheck=>' + keycheck);

                    if(setCheckIds.contains(keycheck)){
                        newCsli.addError(Label.NotAllowChangeContractServicePrice);
                    }
                }else if(newCsli.Supplement__c != oldCsli.Supplement__c){
                    String keycheck =  newCsli.Contract_Home__c + '##' + newCsli.Service__c;    
                    if(setCheckIds.contains(keycheck)){
                        newCsli.addError(Label.NotAllowChangeContractServiceSupplement);
                    }
                }
            }
        }
    
    }


    /*******************************************************************************
    * @author		Novera - TLE
    * @date		    2021-08-18
    * @description  OAPPMEDCHECK-957 No changes to CSLI allowed when linked IDL
    * @param		List<Contractual_Service_Line_Item__c> list of CSLIs 
    * @param		Map<Id, Contractual_Service_Line_Item__c> Map of Old CSLIs     
    * @return		voice
    ********************************************************************************/
    public static void deleteContractServiceInUse(List<Contractual_Service_Line_Item__c> recordList){
        Set<String> contractIds = new Set<String>();
        Set<String> setCheckIds = new Set<String>();
        Set<String> setBeRecordType = new Set<String>();
        setBeRecordType = beContRecordType;

        //Get CSLIs had changed Price and Supplement
        for(Contractual_Service_Line_Item__c oldCsli: recordList){
            if(setBeRecordType.contains(oldCsli.Parent_Contract_RT__c) 
                && !String.isBlank(oldCsli.Contract_Home__c)){
                    contractIds.add(oldCsli.Contract_Home__c);
            }
                        
        }

        //Find relate IDL
        for(Service_Appointment_Line_Item__c idl: [SELECT Service__c, Service_Appointment__r.Contract_Home__c 
                                                    FROM Service_Appointment_Line_Item__c 
                                                    WHERE Service_Appointment__r.Contract_Home__c IN :contractIds ]){
            if(!String.isBlank(idl.Service_Appointment__r.Contract_Home__c)
                && !String.isBlank(idl.Service__c)){
                    String key = idl.Service_Appointment__r.Contract_Home__c + '##' + idl.Service__c;
                    setCheckIds.add(key);
            }              
        }

        //Checking is exists IDL
        for(Contractual_Service_Line_Item__c oldCsli: recordList){
            if( setBeRecordType.contains(oldCsli.Parent_Contract_RT__c) 
                && !String.isBlank(oldCsli.Contract_Home__c)){
                String keycheck =  oldCsli.Contract_Home__c + '##' + oldCsli.Service__c;    
                if(setCheckIds.contains(keycheck)){
                    oldCsli.addError(Label.NotAllowDeleteContractService);
                }
            }
        }
    }


    /*******************************************************************************
    * @author		Novera - TLE
    * @date		    2021-08-18
    * @description  OAPPMEDCHECK-957 Get Set of BE Contract Record Type      
    * @return		voice
    ********************************************************************************/
    public static Set<String> beContRecordType{
        get{
            if(beContRecordType == null){
                beContRecordType = new Set<String>();     
                           
                beContRecordType.add(ContractHomeManager.CONTRACT_HOME_RT_MCM_BE_CONTRACT);
                beContRecordType.add(ContractHomeManager.CONTRACT_HOME_RT_MCM_BE_ONESHOT);
                beContRecordType.add(ContractHomeManager.CONTRACT_HOME_RT_MCM_BE_CONVENTION);

                // beContRecordType.add(ContractHomeManager.CONTRACT_HOME_RT_MCM_FR_CONTRACT);
                // beContRecordType.add(ContractHomeManager.CONTRACT_HOME_RT_MCM_FR_CONVENTION);
                // beContRecordType.add(ContractHomeManager.CONTRACT_HOME_RT_MCM_PRICING);

            }            

            return beContRecordType;
        }

        set;
    }

}