@isTest
public class contractHomeManagerTest
{
    @TestSetup static void setUpTestData()
    {
        List<Account> accList = new List<Account>();
        Account mainAcc = UtilsData.generateAccount('Test Main', AccountManager.RT_ACCOUNT_MAIN, null , false);
        Account mainAccGER = UtilsData.generateAccount('Test Main GER', AccountManager.RT_ACCOUNT_MAIN, null , false);
        mainAccGER.VAT_number__c='123';
        mainAccGER.Official_Country__c='DE';

        Account techAcc = UtilsData.generateAccount('MCM Technical Account', UtilsConstants.RT_ID_ACCOUNT_ACCOUNT_MARKET, null, false);
        accList.add(mainAcc); 
        accList.add(mainAccGER); 
        accList.add(techAcc); 
        insert accList;    

        Map<String,Object> invAccValueMap = UtilsDataTest.generateAccValueMap();
        Account invAcc = UtilsData.generateAccount('Invoicing Dep', UtilsConstants.RT_ID_ACCOUNT_DEPARTMENT, invAccValueMap, false);
        invAcc.ParentId = mainAcc.Id; 
        invAcc.Invoicing_on_this_account__c = 'Yes'; 
        insert invAcc;
        Map<String,Object> contValueMap = new Map<String,Object> ();
        contValueMap.put('Email','test@test.be'); 
        Contact cont = UtilsData.generateContact('Test',UtilsConstants.RT_ID_CONTACT_GENERAL_CONTACT,invAcc.Id,contValueMap,true);
        AccountContactRelation acr = [SELECT Id, Invoicing_recipient_email__c FROM  AccountContactRelation WHERE AccountId=:invAcc.Id AND ContactId=:cont.Id];
        acr.Invoicing_recipient_email__c=TRUE;
        update acr;

        Map<String,Product2> pMap = UtilsDataTest.generateMCMProduct(true);
        UtilsDataTest.generateMCMServices(true);
        List<Contract_Home__c> pricingList = new List<Contract_Home__c>();

        Contract_Home__c pricingFR = new Contract_Home__c(Name = 'MCM FR Tarification Standard',Account__c=techAcc.Id,Product__c=pMap.get('frProduct').Id
                                                    ,In_Place_Date__c=Date.today().addYears(-1),Signature_Date__c=Date.today().addYears(-1)
                                                    ,RecordTypeId=ContractHomeManager.mcmRtPricingId);                                            
        pricingList.add(pricingFR); 

        Contract_Home__c pricingBE = new Contract_Home__c(Name = 'MCM BE Tarification Standard',Account__c=techAcc.Id,Product__c=pMap.get('beProduct').Id
                                                    ,In_Place_Date__c=Date.today().addYears(-1),Signature_Date__c=Date.today().addYears(-1)
                                                    ,RecordTypeId=ContractHomeManager.mcmRtPricingId);                                            
        pricingList.add(pricingBE);
        
        insert pricingList;
    }

    @isTest
    public static void createContractVersion1WithPricing()
    {
        Test.startTest();
        Account mainAcc = [SELECT Id FROM Account WHERE Name='Test Main' LIMIT 1];
        //mainAcc.Official_country__c='FRA';
        //update mainAcc;
        Account mainAccGER = [SELECT Id FROM Account WHERE Name='Test Main GER' LIMIT 1];

        Account invAcc = [SELECT Id FROM Account WHERE Name='Invoicing Dep' LIMIT 1];
        Contract_Home__c pricing = [SELECT Id FROM Contract_Home__c WHERE Name='MCM FR Tarification Standard' LIMIT 1];
        Contract_Home__c ctrH = new Contract_Home__c(Account__c=mainAcc.Id
                                                    ,Invoicing_Account__c = invAcc.Id
                                                    ,Yearly_contribution__c=true
                                                    ,In_Place_Date__c=Date.today().addMonths(-1)
                                                    ,Signature_Date__c=Date.today().addMonths(-1)
                                                    ,Pricing__c = pricing.Id
                                                    ,Version__c=1
                                                    ,RecordTypeId=ContractHomeManager.mcmRtFRId
                                                    ,Visit_type__c = AbsenceRegistrationManager.WORKTYPE_DIRECT_CONVOCATION);
        insert ctrH;

        Contract_Home__c specific = new Contract_Home__c(Account__c=mainAccGER.Id
                                                    ,Yearly_contribution__c=true
                                                    ,In_Place_Date__c=Date.today().addMonths(-1)
                                                    ,Signature_Date__c=Date.today().addMonths(-1)
                                                    ,Pricing__c = pricing.Id
                                                    ,Version__c=1
                                                    ,SAP_No_Synch__c=true
                                                    ,RecordTypeId=ContractHomeManager.mcmRtFRId
                                                    ,Service_Type__c = StaticConstants.TYPE_MEDICAL_CHECK_ILLNESS
                                                    ,Visit_type__c = AbsenceRegistrationManager.WORKTYPE_DIRECT_CONVOCATION
                                                    ,Specific_Contract__c = true);
                                                    
        insert specific;


        Test.stopTest(); 
    }


    @isTest
    public static void checkIfSpecificContractUnflagged()
    {
        Test.startTest();
        Account mainAcc = [SELECT Id FROM Account WHERE Name='Test Main' LIMIT 1];
        //mainAcc.Official_country__c='GUF';
        //update mainAcc;
        Account invAcc = [SELECT Id FROM Account WHERE Name='Invoicing Dep' LIMIT 1];
        Contract_Home__c pricing = [SELECT Id FROM Contract_Home__c WHERE Name='MCM FR Tarification Standard' LIMIT 1];
        Contract_Home__c general = new Contract_Home__c(Account__c=mainAcc.Id
                                                    ,Invoicing_Account__c = invAcc.Id
                                                    ,Yearly_contribution__c=true
                                                    ,In_Place_Date__c=Date.today().addMonths(-1)
                                                    ,Signature_Date__c=Date.today().addMonths(-1)
                                                    ,Pricing__c = pricing.Id
                                                    ,Version__c=1
                                                    ,RecordTypeId=ContractHomeManager.mcmRtFRId
                                                    ,Service_Type__c = StaticConstants.TYPE_MEDICAL_CHECK_ILLNESS
                                                    ,Visit_type__c = AbsenceRegistrationManager.WORKTYPE_DIRECT_CONVOCATION);
        insert general;

        Contract_Home__c specific = new Contract_Home__c(Account__c=mainAcc.Id
                                                    ,Yearly_contribution__c=true
                                                    ,In_Place_Date__c=Date.today().addMonths(-1)
                                                    ,Signature_Date__c=Date.today().addMonths(-1)
                                                    ,Pricing__c = pricing.Id
                                                    ,Version__c=1
                                                    ,SAP_No_Synch__c=true
                                                    ,RecordTypeId=ContractHomeManager.mcmRtFRId
                                                    ,Service_Type__c = StaticConstants.TYPE_MEDICAL_CHECK_ILLNESS
                                                    ,Visit_type__c = AbsenceRegistrationManager.WORKTYPE_DIRECT_CONVOCATION
                                                    ,Specific_Contract__c = true);
                                                    
        insert specific;

        invAcc.Specific_contract__c= specific.Id;
        update invAcc;

        specific.Invoicing_Account__c = invAcc.Id;
        update specific;

        try{
            
            specific.Specific_Contract__c=false;
            update specific;            
        }
        catch(Exception e)
        {
            System.assertEquals(e.getMessage().contains(Label.BlockUnflagSpecificContract),false);
        }
        Test.stopTest(); 
    }

    @isTest
    public static void ActiveContractsWithTheSameServiceType()
    {
        Test.startTest();
        Account mainAcc = [SELECT Id FROM Account WHERE Name='Test Main' LIMIT 1];
        //mainAcc.Official_country__c='GLP';
        //update mainAcc;
        Account invAcc = [SELECT Id FROM Account WHERE Name='Invoicing Dep' LIMIT 1];
        Contract_Home__c pricing = [SELECT Id FROM Contract_Home__c WHERE Name='MCM FR Tarification Standard' LIMIT 1];
        Contract_Home__c ctrH1 = new Contract_Home__c(Account__c=mainAcc.Id
                                                    ,Invoicing_Account__c = invAcc.Id
                                                    ,Yearly_contribution__c=true
                                                    ,In_Place_Date__c=Date.today().addMonths(-1)
                                                    ,Signature_Date__c=Date.today().addMonths(-1)
                                                    ,Pricing__c = pricing.Id
                                                    ,Version__c=1
                                                    ,RecordTypeId=ContractHomeManager.mcmRtFRId
                                                    ,Service_Type__c = StaticConstants.TYPE_MEDICAL_CHECK_ILLNESS
                                                    ,Visit_type__c = AbsenceRegistrationManager.WORKTYPE_DIRECT_CONVOCATION);
        insert ctrH1;

        try{

            Contract_Home__c ctrH2 = new Contract_Home__c(Account__c=mainAcc.Id
                                                        ,Invoicing_Account__c = invAcc.Id
                                                        ,Yearly_contribution__c=true
                                                        ,In_Place_Date__c=Date.today().addMonths(-1)
                                                        ,Signature_Date__c=Date.today().addMonths(-1)
                                                        ,Pricing__c = pricing.Id
                                                        ,Version__c=1
                                                        ,RecordTypeId=ContractHomeManager.mcmRtFRId
                                                        ,Service_Type__c = StaticConstants.TYPE_MEDICAL_CHECK_ILLNESS
                                                        ,Visit_type__c = AbsenceRegistrationManager.WORKTYPE_DIRECT_CONVOCATION);
            insert ctrH2;

            
        }
        catch(Exception e)
        {
            System.assertEquals(e.getMessage().contains(Label.ActiveContractSameServiceType),true);
        }

        ctrH1.Invoicing_Terms__c = '60';
        update ctrH1;

        Test.stopTest(); 

    }

    @isTest
    public static void createConvention()
    {
        Test.startTest();

        Account docAcc = UtilsData.generateAccount('Test Doctor', UtilsConstants.RT_ID_ACCOUNT_DOCTOR, null, false );
        docAcc.Official_country__c='FRA';
        docAcc.Subject_to_VAT__c=true;
        insert docAcc;
        Contract_Home__c ctrH1 = new Contract_Home__c(Account__c=docAcc.Id
                                                    ,Yearly_contribution__c=true
                                                    ,In_Place_Date__c=Date.today().addMonths(-1)
                                                    ,Signature_Date__c=Date.today().addMonths(-1)
                                                    ,Version__c=1
                                                    ,contract_country__c='FRA'
                                                    ,RecordTypeId=ContractHomeManager.mcmRtConventionFRId
                                                    ,Service_Type__c = StaticConstants.TYPE_MEDICAL_CHECK_ILLNESS
                                                    ,Visit_type__c = AbsenceRegistrationManager.WORKTYPE_DIRECT_CONVOCATION);

        Test.stopTest();                                             
    }


    @isTest
    public static void createBeContract()
    {
        Test.startTest();
        Account mainAcc = [SELECT Id FROM Account WHERE Name='Test Main' LIMIT 1];
        mainAcc.Official_country__c='BEL';
        update mainAcc;
        Account invAcc = [SELECT Id FROM Account WHERE Name='Invoicing Dep' LIMIT 1];
        Contract_Home__c pricing = [SELECT Id FROM Contract_Home__c WHERE Name='MCM BE Tarification Standard' LIMIT 1];
        Contract_Home__c ctrH1 = new Contract_Home__c(Account__c=mainAcc.Id
                                                    ,Invoicing_Account__c = invAcc.Id
                                                    ,Yearly_contribution__c=true
                                                    ,In_Place_Date__c=Date.today().addMonths(-1)
                                                    ,Signature_Date__c=Date.today().addMonths(-1)
                                                    ,Pricing__c = pricing.Id
                                                    ,Version__c=1
                                                    ,Contract_Country__c='BEL'
                                                    ,RecordTypeId=ContractHomeManager.mcmRtBEId
                                                    ,Service_Type__c = StaticConstants.TYPE_MEDICAL_CHECK_ILLNESS
                                                    ,Visit_type__c = AbsenceRegistrationManager.WORKTYPE_DIRECT_CONVOCATION);
        insert ctrH1;

        Test.stopTest(); 
    }



    
}