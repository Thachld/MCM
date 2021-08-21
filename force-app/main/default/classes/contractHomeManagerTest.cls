@isTest
public class contractHomeManagerTest
{
    @TestSetup static void setUpTestData()
    {
        
        List<Account> accList = new List<Account>();
      
        Account mainAcc = UtilsData.generateAccount('Test Main'
                                , AccountManager.RT_ACCOUNT_MAIN
                                , null
                                , false);

        Account techAcc = UtilsData.generateAccount('MCM Technical Account', UtilsConstants.RT_ID_ACCOUNT_ACCOUNT_MARKET
                                , null
                                , false);
        accList.add(mainAcc); 
        accList.add(techAcc); 
        insert accList;    

        Map<String,Object> invAccValueMap = new Map<String,Object>();
        invAccValueMap.put('ParentId',mainAcc.Id);
        invAccValueMap.put('Invoicing_Terms__c','30');
        invAccValueMap.put('Invoicing_on_this_account__c','Yes');
        invAccValueMap.put('Correspondence_HouseNrAlpha__c','1');
        invAccValueMap.put('Correspondence_HouseNr__c','9');
        invAccValueMap.put('Correspondence_street__c','Leonardo da Vincilaan');
        invAccValueMap.put('Correspondence_PostalCode__c','1930');
        invAccValueMap.put('Correspondence_city__c','Zaventem');
        invAccValueMap.put('Correspondence_country__c','BEL');
        invAccValueMap.put('Official_HouseNr__c', '76');
        invAccValueMap.put('Official_Street__c', ' Rue de Namur');
        invAccValueMap.put('Official_PostalCode__c', '1300');
        invAccValueMap.put('Official_City__c', 'Wavre');
        invAccValueMap.put('Official_Country__c', 'BEL');
        Account invAcc = UtilsData.generateAccount('Invoicing Dep'
                            , UtilsConstants.RT_ID_ACCOUNT_DEPARTMENT
                            , invAccValueMap
                            , false);
        insert invAcc;

        Map<String,Object> contValueMap = new Map<String,Object> ();
        contValueMap.put('Email','test@test.be'); 
        Contact cont = UtilsData.generateContact('Test',UtilsConstants.RT_ID_CONTACT_GENERAL_CONTACT,invAcc.Id,contValueMap,true);

        //List<AccountContactRelation> acr = [SELECT Id, Invoicing_recipient_email__c FROM  AccountContactRelation WHERE AccountId=:invAcc.Id AND ContactId=:cont.Id];
        AccountContactRelation acr = [SELECT Id, Invoicing_recipient_email__c FROM  AccountContactRelation WHERE AccountId=:invAcc.Id AND ContactId=:cont.Id];
        acr.Invoicing_recipient_email__c=TRUE;
        update acr;

        List<Product2> pList = new  List<Product2>(); 
        Product2 pFR = new Product2 (Name = 'myProduct', ExtSysId__c = '16200',ProductCode = '200');
        Product2 pBE = new Product2 (Name = 'myProduct', ExtSysId__c = '16000',ProductCode = '000');
        pList.add(pFR);
        pList.add(pBE);
        insert pList;

        List<Service__c> services = new List<Service__c>();
        
        Service__c yearlyContributionService = UtilsData.generateMcmFrService(StaticConstants.MCM_SERVICE_YEARLY_CONTRIBUTION,'Annual fee'
                                                        ,null,null,500,'70000000','70000000', '70000001','70000001');
        services.add(yearlyContributionService);

        Service__c packService = UtilsData.generateMcmFrService('Pack','Pack', null, null,1000,'70200000','70200000','70204000', '70204000');
        services.add(packService);

        Service__c convocationService = UtilsData.generateMcmFrService('Convocation','Basic fee per service','Convocation',null,110,'70200000','70200000','70200000','70200000');
        services.add(convocationService);

        Service__c homeVisitservice = UtilsData.generateMcmFrService('Home visit','Basic fee per service','Home visit',null,120,'70200000','70200000','70200000','70200000');

        Service__c smsService = UtilsData.generateMcmFrService('Notification employee - SMS','Supplement per service',null,'SMS',2,'70212090','70212090', '70212091', '70212091');
        services.add(smsService);

        Service__c letterService = UtilsData.generateMcmFrService('Notification employee - convocation letter','Supplement per service',null,'Letter',4,'70212090','70212090','70212091', '70212091');
        services.add(letterService);

        Service__c suppFlatService = UtilsData.generateMcmFrService('Supplement flat km','Supplement per service',null,'Flat',0.61,'70240020','70240020','70240021','70240021');
        services.add(suppFlatService);

        Service__c suppMountService = UtilsData.generateMcmFrService('Supplement mountain km','Supplement per service',null,'Mountain',0.91,'70240020','70240020','70240021', '70240021');
        services.add(suppMountService);

        Service__c suppWkService = UtilsData.generateMcmFrService('Supplement weekend','Supplement per service',null,'Weekend',20,'70212090','70212090', '70212091', '70212091');
        services.add(suppWkService);

        insert services;

        Contract_Home__c pricing = new Contract_Home__c(Name = 'MCM FR Tarification Standard'
                                                    ,Account__c=techAcc.Id
                                                    ,Product__c=pFR.Id
                                                    ,In_Place_Date__c=Date.today().addYears(-1)
                                                    ,Signature_Date__c=Date.today().addYears(-1)
                                                    ,RecordTypeId=ContractHomeManager.mcmRtPricingId);                                            
        insert Pricing; 

    }

    @isTest
    public static void createContractVersion1WithPricing()
    {

        Account mainAcc = [SELECT Id FROM Account WHERE Name='Test Main' LIMIT 1];
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
    }


    @isTest
    public static void checkIfSpecificContractUnflagged()
    {

        Account mainAcc = [SELECT Id FROM Account WHERE Name='Test Main' LIMIT 1];
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

    }

    @isTest
    public static void ActiveContractsWithTheSameServiceType()
    {

        Account mainAcc = [SELECT Id FROM Account WHERE Name='Test Main' LIMIT 1];
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

    }

    @isTest
    public static void createConvention()
    {

        Account docAcc = UtilsData.generateAccount('Test Doctor', UtilsConstants.RT_ID_ACCOUNT_DOCTOR, null, false);
        Contract_Home__c ctrH1 = new Contract_Home__c(Account__c=docAcc.Id
                                                    ,Yearly_contribution__c=true
                                                    ,In_Place_Date__c=Date.today().addMonths(-1)
                                                    ,Signature_Date__c=Date.today().addMonths(-1)
                                                    ,Version__c=1
                                                    ,RecordTypeId=ContractHomeManager.mcmRtConventionFRId
                                                    ,Service_Type__c = StaticConstants.TYPE_MEDICAL_CHECK_ILLNESS
                                                    ,Visit_type__c = AbsenceRegistrationManager.WORKTYPE_DIRECT_CONVOCATION);
    }

    @isTest
    public static void createBeContract()
    {
        Account mainAcc = [SELECT Id FROM Account WHERE Name='Test Main' LIMIT 1];
        Account invAcc = [SELECT Id FROM Account WHERE Name='Invoicing Dep' LIMIT 1];
        Contract_Home__c pricing = [SELECT Id FROM Contract_Home__c WHERE Name='MCM FR Tarification Standard' LIMIT 1];
        Contract_Home__c ctrH1 = new Contract_Home__c(Account__c=mainAcc.Id
                                                    ,Invoicing_Account__c = invAcc.Id
                                                    ,Yearly_contribution__c=true
                                                    ,In_Place_Date__c=Date.today().addMonths(-1)
                                                    ,Signature_Date__c=Date.today().addMonths(-1)
                                                    ,Pricing__c = pricing.Id
                                                    ,Version__c=1
                                                    ,RecordTypeId=ContractHomeManager.mcmRtBEId
                                                    ,Service_Type__c = StaticConstants.TYPE_MEDICAL_CHECK_ILLNESS
                                                    ,Visit_type__c = AbsenceRegistrationManager.WORKTYPE_DIRECT_CONVOCATION);
        insert ctrH1;
    }



    
}