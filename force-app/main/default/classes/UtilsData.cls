public with sharing class UtilsData {
    /*********************************************************************************************************
    * @author        Germain Martinussen
    * @date          2018 Jan 24
    * @description   The method returns a account record. The record can be inserted if needed
    * @param         accountName (String): The name of the account
    * @param         recordTypeId (String): The record type id of the record
    * @param         fieldnameValueMap (Map<String,Object>): Map with the name of the fields and its value
    * @param         executeInsert (Boolean): True if the record must be inserted, otherwise false
    * @return        Account: The account record
    *********************************************************************************************************/
    public static Account generateAccount(String accountName, String recordTypeId, Map<String,Object> fieldnameValueMap, Boolean executeInsert){
        Account acc;
        acc = new Account(Name=accountName, RecordTypeId=recordTypeId);
        
        if(fieldnameValueMap!=null){
            for(String fieldName : fieldnameValueMap.keySet()) {
                acc.put(fieldName,fieldnameValueMap.get(fieldName));
            }
        }

        if(executeInsert) insert acc;
        return acc;
    }
    public static Account generateAccount(String accountName, boolean insertRecord){
        Account acc = new Account(Name=accountName);
        if (insertRecord){
            insert acc;
        }
        return acc;

    }
    public static Contract__c generateContract(String contractName, Account account){
        Product2 prod = new Product2 (Name = 'test prod', ProductCode='625', ExtSysId__c = '123');
        insert prod;
        Id stdPbId = Test.getStandardPricebookId();
        PricebookEntry pbe = new PricebookEntry(Pricebook2Id = stdPbId, Product2Id = prod.Id, UnitPrice = 10.00, isActive = true);
        insert pbe;
        Contract__c contract = new Contract__c (Contract_Holder__c = account.Id, Product__c = prod.Id, In_Place_Date__c = Date.today(), Contract_Number__c=contractName, Contract_Unique_Number__c = contractName);
        insert contract;

        return contract;
    }
    public static Contract__c generateContract(String contractName){
        Product2 prod = new Product2 (Name = 'test prod', ProductCode='625', ExtSysId__c = '123');
        insert prod;
        Id stdPbId = Test.getStandardPricebookId();
        PricebookEntry pbe = new PricebookEntry(Pricebook2Id = stdPbId, Product2Id = prod.Id, UnitPrice = 10.00, isActive = true);
        insert pbe;
        Contract__c contract = new Contract__c ( Product__c = prod.Id, In_Place_Date__c = Date.today(), Contract_Number__c=contractName, Contract_Unique_Number__c = contractName);
        insert contract;

        return contract;
    }
    public static Spoc__c generateSpoc(Account acc,User prefAgent,User backupAgent,String team,boolean insertRecord){
        Spoc__c spoc= new Spoc__c(Account__c=acc.Id,
            Backup_Agent__c=backupAgent.id,
            Preferred_Agent__c=prefAgent.id,
            Team__c=team);
        if (insertRecord){
            insert spoc;
        }
        return spoc;
    }
    public static Contact generateContact(String contactLastName, String recordTypeId, ID accountId, Map<String,Object> fieldnameValueMap, Boolean executeInsert){
        Contact con;
        con = new Contact(LastName=contactLastName, RecordTypeId=recordTypeId,AccountId = accountId);
        
        if(fieldnameValueMap!=null){
            for(String fieldName : fieldnameValueMap.keySet()) {
                con.put(fieldName,fieldnameValueMap.get(fieldName));
            }
        }

        if(executeInsert) insert con;
        return con;
    }
    public static Contact generateContact(String contactLastName, ID accountId, boolean insertRecord){
        Contact con = new Contact(LastName=contactLastName, AccountId=accountId);
        if (insertRecord){
            insert con;
        }
        return con;

    }
    /*********************************************************************************************************
    * @author        Germain Martinussen
    * @date          2018 Jan 24
    * @description   The method generates a user. The record can be inserted if needed
    * @param         profileId (Id): The profile id of the user
    * @param         isActive (Boolean): If the user is actif
    * @param         userUID (String): A unique id
    * @param         executeInsert (Boolean): True if the record must be inserted, otherwise false
    * @return        User: The user record
    *********************************************************************************************************/
    public static User generateUser(Id profileId, boolean isActive, String userUID, Boolean executeInsert){

        User user = new User(
                Email = 'test@email.com.' + userUID,
                Username = 'test@email.com.' + userUID,
                LastName = 'LastName' + userUID,
                Alias = 'A' + userUID,
                TimeZoneSidKey = 'Europe/Paris',
                LocaleSidKey = 'fr_BE',
                EmailEncodingKey = 'ISO-8859-1',
                ProfileId = profileId,
                LanguageLocaleKey = 'en_US',
                IsActive = isActive,
                Is_Outplacement_Agent__c = true
        );

        if(executeInsert){
            insert user;
        }

        return user;

    }

    public static User generateUser(Id profileId, String fedId, Id contId, boolean isActive, String userUID, Boolean executeInsert){
        UserRole r = new UserRole(DeveloperName = 'MyCustomRole', Name = 'My Custom Role');
        insert r;

       User user = new User(   
           Email = 'test@email.com.' + userUID,
           Username = 'test@email.com.' + userUID,
               UserRoleId = r.Id,
           LastName = 'LastName' + userUID,
           Alias = 'A' + userUID,
           TimeZoneSidKey = 'Europe/Paris',
           LocaleSidKey = 'fr_BE',
           EmailEncodingKey = 'ISO-8859-1',
           ProfileId = profileId,
           LanguageLocaleKey = 'en_US',
           IsActive = isActive,
           Is_Outplacement_Agent__c = true,
           FederationIdentifier = fedId,
           ContactId = contId
       );
        
       if(executeInsert){
         insert user;  
       }
        
       return user;
         
    }

    public static User generateUserWithTeams(Id profileId, boolean isActive, String userUID,String teamgroup, String team,String teams, Boolean executeInsert){
        User u=generateUser(profileId,isActive,userUID,executeInsert);
        u.Service_Team_Group__c=teamgroup;
        u.Service_Team__c=team;
        u.Service_Teams__c=teams;
        update u;
        return u;
    }

    public static QueuesObject generateQueue(){
        Group g1 = new Group(Name='Q1', type='Queue');
        insert g1;
        QueuesObject q2 = new QueueSObject(QueueID = g1.id, SobjectType = 'Task');
        insert q2;
        QueuesObject q1 = new QueueSObject(QueueID = g1.id, SobjectType = 'Case');
        insert q1;
        return q1;
    }

    public static Team_Setting__mdt generateTeamSettings(String queueId,String teamGroup, String team, String shareTo){

        Signature_Settings__mdt signatureSettings=new Signature_Settings__mdt(DeveloperName='R1',
                                Email_CSS__c='font-size:8.5pt;font-family:Verdana;color:#36b8c1',
                                Email_WebSite_Separator__c='&nbsp;|&nbsp;',
                                Email_WebSite_Separator_CSS__c='font-size:8.5pt;font-family:Verdana;color:#706f6f',
                                Phone_CSS__c='font-size:8.5pt;font-family:Verdana;color:#706f6f',
                                WebSite_URL__c='https://www.securex.lu',
                                WebSite_CSS__c='font-size:8.5pt;font-family:Verdana;color:#36b8c1',
                                WebSite_Label__c='www.securex.lu');
        System.debug('LOR:signatureSettings'+signatureSettings);

        Team_Setting__mdt teamSetting=new Team_Setting__mdt(DeveloperName='T1',
                                                        BU__c='BU1',
                                                        Team_Group__c=teamgroup,
                                                        Team__c=team,
                                                        Email__c='email@test.be',
                                                        Product_Codes__c = '110;120;625',
                                                        Queue_Id__c=queueId,
                                                        Queue_Name__c='Q1',
                                                        Signature_Settings__r=signatureSettings,
                                                        Share_To_API_Name__c=shareTo);
                                
        return teamSetting;
    }
    public static Team_Setting__mdt generateTeamSettings(String queueId,String teamgroup,String team,String shareTo,String email,String phone){
       Team_Setting__mdt teamSetting=generateTeamSettings(queueId,teamgroup,team,shareTo);

        teamSetting.Email__c=email;
        teamSetting.Phone__c=phone;
        return teamSetting;
        }
    public static Team_Setting__mdt generateTeamSettingsWithSpocRouting(String teamgroup, String team){
        Team_Setting__mdt teamSetting=generateTeamSettings(null,teamgroup,team,null);
            teamSetting.SPOC_Routing__c=true;
            return teamSetting;
            }

    public static Team_Setting__mdt generateTeamSettingsWithSlaSetting(String teamgroup, String team, String slaType)
    {
        Team_Setting__mdt teamSetting=generateTeamSettings(null,teamgroup,team,null);
        teamSetting.SLA_Type__c=slaType;
        return teamSetting;
    }

    public static Team_Setting__mdt generateTeamSettingsWithDefaultEmail(String teamgroup, String team)
    {
        Team_Setting__mdt teamSetting=generateTeamSettings(null,teamgroup,team,null);
        teamSetting.defaultEmailTemplateForCase__c='Securex Default Template';
        return teamSetting;
    }

    public static SLA__c generateSla(Integer firstres, String firstresUnit, Integer closeCase, String closeCaseUnit)
    {
        BusinessHours bhs=[SELECT Id FROM BusinessHours WHERE IsDefault=true LIMIT 1];
        SLA__c s = new SLA__c(First_Response_Duration__c = firstres
                                , First_Response_TimeUnit__c = firstresUnit
                                , Close_Case_Duration__c = closeCase
                                , Close_Case_TimeUnit__c = closeCaseUnit
                                , Business_Hours__c =bhs.Id ); 
        insert s;
        return s;
    }
    
    public static SLA__c generateSlaTypeAccount(Integer firstres, String firstresUnit, Integer closeCase, String closeCaseUnit, String tg,String t, Id AccountId)
    {
        SLA__c s = generateSla(firstres,firstresUnit,closeCase,closeCaseUnit);
        s.SLA_Type__c = 'Account';
        s.Account__c = AccountId; 
        s.Team_Group__c = tg;
        s.Team__c = t;
        update s;
        return s;
    }

    public static SLA__c generateSlaTypePriority(Integer firstres, String firstresUnit, Integer closeCase, String closeCaseUnit, String tg,String t, String prior)
    {
        SLA__c s = generateSla(firstres,firstresUnit,closeCase,closeCaseUnit);
        s.SLA_Type__c = 'Priority';
        s.Priority__c = prior;
        s.Team_Group__c = tg;
        s.Team__c = t;
        update s;
        return s;
    }

    public static SLA__c generateSlaTypeTeam(Integer firstres, String firstresUnit, Integer closeCase, String closeCaseUnit,String tg,String t)
    {
        SLA__c s = generateSla(firstres,firstresUnit,closeCase,closeCaseUnit);
        s.SLA_Type__c = 'Team';
        s.Team_Group__c = tg;
        s.Team__c = t; 
        update s;
        return s;
    }

    public static SLA__c generateSlaTypeCaseType(Integer firstres, String firstresUnit, Integer closeCase, String closeCaseUnit, String tg,String t, Id cT,Id cSt)
    {
        SLA__c s = generateSla(firstres,firstresUnit,closeCase,closeCaseUnit);
        s.SLA_Type__c = 'CaseType';
        s.Team_Group__c = tg;
        s.Team__c = t;
        s.Case_Type__c = cT;
        s.Case_SubType__c = cSt; 
        update s;
        return s;
    }

    public static Case_Type__c generateCaseType(String tg)
    {
        Case_Type__c cT = new Case_Type__c(Name='Test',Active__c=true,Team_Group__c=tg,Team_Group_Text__c=tg); 
        insert cT;
        return cT;
    } 

    public static Case_Subtype__c generateCaseSubtype(Id ctId,String ctText, String tg)
    {
        Case_Subtype__c cSt = new Case_Subtype__c(Name='Test',Case_Type__c=ctId,Case_Type_Text__c=ctText,Team_Group_Text__c=tg); 
        insert cSt;
        return cSt;
    }

    public static ServiceCase__c generateServiceCase(Id accountId, String recordTypeId, Map<String,Object> fieldnameValueMap, Boolean executeInsert){
        ServiceCase__c sc;
        sc = new ServiceCase__c(Account__c=accountId, RecordTypeId=recordTypeId);

        if(fieldnameValueMap!=null){
            for(String fieldName : fieldnameValueMap.keySet()) {
                sc.put(fieldName,fieldnameValueMap.get(fieldName));
            }
        }

        if(executeInsert) insert sc;
        return sc;
    }

    public static ServiceCase__c generateServiceCase(Id accountId, Boolean insertRecord){
        ServiceCase__c sc = new ServiceCase__c(Account__c=accountId);
        if (insertRecord){
            insert sc;
        }
        return sc;

    }

    public static Service__c generateMcmFrService(String nameS, String category, String visitType, String suppType,
                                                Decimal currStandPrice, String glAccWithVAT, String glAccWithoutVAT,
                                                string docGlVAT, string docGlWithoutVAT)
    {
        Service__c serv = new Service__c(Name = nameS
                                        ,Available_for_country__c='FR'
                                        ,Service_category__c=category
                                        ,Visit_type__c = visitType
                                        ,Supplement_Type__c = suppType
                                        ,Current_Standard_Price__c = currStandPrice
                                        ,Gl_Account_with_VAT__c = glAccWithVAT
                                        ,Gl_Account_without_VAT__c = glAccWithoutVAT
                                        ,Start_Date__c = System.today().addYears(-1)
                                        ,Doctor_Gl_Account_with_VAT__c    = docGlVAT
                                        ,Doctor_Gl_Account_without_VAT__c = docGlWithoutVAT
                                        );
        return serv;
    }

    public static List<Service__c> generateFRServices()
    {
        List<Service__c> services = new  List<Service__c>();
        Service__c convocationService = UtilsData.generateMcmFrService('Convocation','Basic fee per service','Convocation',null,110,'70200000','70200000', '00000000000', '00000000000');
        services.add(convocationService);
        Service__c homeVisitservice = UtilsData.generateMcmFrService('Home visit','Basic fee per service','Home visit',null,120,'70200000','70200000', '00000000000', '00000000000');
        services.add(homeVisitservice);
        Service__c suppFlatService = UtilsData.generateMcmFrService('Supplement flat km','Supplement per service',null,'Flat',0.61,'70240020','70240021', '00000000000', '00000000000');
        services.add(suppFlatService);
        Service__c suppMountService = UtilsData.generateMcmFrService('Supplement mountain km','Supplement per service',null,'Mountain',0.91,'70240020','70240021', '00000000000', '00000000000');
        services.add(suppMountService);
        Service__c suppWkService = UtilsData.generateMcmFrService('Supplement weekend','Supplement per service',null,'Weekend',20,'70212090','70212091', '00000000000', '00000000000');
        services.add(suppWkService);
        Service__c miscService = UtilsData.generateMcmFrService('Miscellaneous','Miscellaneous',null,null,null,'70212093','70212094', '00000000000', '00000000000');
        services.add(miscService);
        Service__c yearlyContributionService = UtilsData.generateMcmFrService(StaticConstants.MCM_SERVICE_YEARLY_CONTRIBUTION,'Annual fee'
                                                        ,null,null,500,'70000000','70000001', '00000000000', '00000000000');
        services.add(yearlyContributionService);
        Service__c packService = UtilsData.generateMcmFrService('Pack','Pack', null, null,1000,'70200000','70204000', '00000000000', '00000000000');
        services.add(packService);
        Service__c smsService = UtilsData.generateMcmFrService('Notification employee - SMS','Supplement per service',null,'SMS',2,'70212090','70212091', '00000000000', '00000000000');
        services.add(smsService);
        Service__c letterService = UtilsData.generateMcmFrService('Notification employee - convocation letter','Supplement per service',null,'Letter',4,'70212090','70212091', '00000000000', '00000000000');
        services.add(letterService);
        return services;
    }

}