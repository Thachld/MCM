/*******************************************************************************
* @author       Novera - QLE
* @date         2020-09-25
* @description  Test class for createInvoiceController  
********************************************************************************/
@isTest
public class CustomerInvoicingTest 
{

    @TestSetup static void setUpTestData()
    {
        FSL.GlobalAPIS.addStatusTransition('None',ServiceAppointmentManager.STATUS_RESULT_TO_CUSTOMER);
        FSL.GlobalAPIS.addStatusTransition('Scheduled',ServiceAppointmentManager.STATUS_RESULT_TO_CUSTOMER);
        
        List<Account> mainAccList = new List<Account>();
        List<Contract_Home__c> ctrHList = new List<Contract_Home__c>();
        List<Contractual_Service_Line_Item__c> csliList = new List<Contractual_Service_Line_Item__c>();
        
        Product2 p = new Product2 (Name = 'myProduct', ExtSysId__c = '16200',ProductCode = '200');
        insert p;
        
        List<Service__c> services = UtilsData.generateFRServices();
        insert services;

        Map<String,Object> accValueMap = new Map<String,Object>();
        accValueMap.put('Invoicing_Terms__c','30');
        accValueMap.put('Invoicing_on_this_account__c','Yes');
        accValueMap.put('Correspondence_HouseNrAlpha__c','1');
        accValueMap.put('Correspondence_street__c','Leonardo da Vincilaan');
        accValueMap.put('Correspondence_PostalCode__c','1930');
        accValueMap.put('Correspondence_city__c','Zaventem');
        accValueMap.put('Correspondence_country__c','BEL');
        accValueMap.put('Official_Street__c', ' Rue de Namur');
        accValueMap.put('Official_PostalCode__c', '1300');
        accValueMap.put('Official_City__c', 'Wavre');
        accValueMap.put('Official_Country__c', 'BEL');
        for(Integer i=0;i<10;i++)
        {
            accValueMap.put('Official_HouseNr__c', '' + i);
            accValueMap.put('Correspondence_HouseNr__c','' + i);
            accValueMap.put('Official_address_name__c', 'name'+ i);
            accValueMap.put('Securex_Number__c', '123'+ i);
            accValueMap.put('Correspondence_name__c','name corr'+ i);
            Account mainAcc = UtilsData.generateAccount('Main Acc ' + i
                                    , AccountTriggerHandler.RT_ACCOUNT_MAIN
                                    , accValueMap
                                    , false);
            Integer n= 7639241 + 97*i;
            mainAcc.Enterprise_Number__c= 0+String.valueOf(n)+91;
            mainAccList.add(mainAcc); 
        }
        insert mainAccList;    

        Contact cont = UtilsData.generateContact('Test',mainAccList[0].Id,false);
        cont.Email = 'test@test.be';
        insert cont;

        List<Account> invDepList = new List<Account>();
        Integer m=0;
        accValueMap.remove('Securex_Number__c');
        for(Account mainAcc : [SELECT Id, Official_HouseNr__c FROM Account WHERE RecordTypeId=:AccountTriggerHandler.RT_ACCOUNT_MAIN])
        {
            m++;
            Account invDep = UtilsData.generateAccount('Invoicing Dep ' +''+ m
                                , AccountTriggerHandler.RT_DEPARTMENT
                                , accValueMap
                                , false);
            invDep.ParentId = mainAcc.Id;
            invDep.Department_Number__c= m;
            invDep.Date_in__c=system.today();
            System.debug('invDep.Department_Number__c: '+invDep.Department_Number__c);
            invDepList.add(invDep);            
            System.debug('accvaluemap'+ accValueMap);
            System.debug('dep name'+ invDep.Name);
        }
        insert invDepList;

        List<AccountContactRelation> acrList = new List<AccountContactRelation>(); 
        for(Account invDep : invDepList)
        {
            AccountContactRelation acr = new AccountContactRelation(Invoicing_recipient_email__c=TRUE,AccountId = invDep.Id,ContactId=cont.Id);
            acrList.add(acr);
        }
        insert acrList;

        List<Account> accListToUpdate = new List<Account>();
        List<Employee__c> emplList = new List<Employee__c>();

        Integer i = 0;
        for(Account invDep : [SELECT Id, Name, ParentId FROM Account WHERE RecordTypeId=:AccountTriggerHandler.RT_DEPARTMENT AND Invoicing_On_This_Account__c='Yes'])
        {
            i++;
            Employee__c emp = UtilsDataTest.generateExternalEmployee('mcm emp' + i,invDep.Id, 'mcm' + i + '@test.com','2209'+i, false);
            emplList.add(emp);
        }

        update accListToUpdate;

        List<Account> depList = new List<Account>();
        Integer j = 0;
        for(Account invAcc : [SELECT ParentId, Name, Invoicing_Account__c, Parent__r.Official_HouseNr__c, Parent__r.Correspondence_HouseNr__c 
                            FROM Account WHERE Name LIKE '%Invoicing Dep%' ORDER BY Name ASC])
        {
            j++;
            accValueMap.put('ParentId',invAcc.ParentId);
            accValueMap.put('Official_HouseNr__c',invAcc.Parent__r.Official_HouseNr__c);
            accValueMap.put('Correspondence_HouseNr__c',invAcc.Parent__r.Correspondence_HouseNr__c);
            accValueMap.put('Invoicing_On_This_Account__c','No');
            accValueMap.put('Invoicing_Account__c',invAcc.Id);
            Account dep = UtilsData.generateAccount('Department ' + j
                                , AccountTriggerHandler.RT_DEPARTMENT
                                , accValueMap
                                , false);
            depList.add(dep);
        }
        insert depList;

        Integer k=0;
        for(Account dep : [SELECT Id, Name FROM Account WHERE RecordTypeId=:AccountTriggerHandler.RT_DEPARTMENT])
        {
            k++;
            Employee__c emp = UtilsDataTest.generateExternalEmployee('mcm emp1 ' + k,dep.Id, 'mcm1' + k + '@test.com','2208' + k, false);
            emplList.add(emp);
        }
        insert emplList;

        
        Integer l=0;
        for(Account invAcc : [SELECT Id, ParentId FROM Account WHERE  Name LIKE '%Invoicing Dep%' ORDER BY Name ASC])
        {
            l++;
            Contract_Home__c ctrH = new Contract_Home__c(Account__c=invAcc.ParentId
                                        ,Invoicing_Account__c = invAcc.Id
                                        ,Yearly_contribution__c=true
                                        ,Next_due_date__c = Date.today().addMonths(-1).toStartOfMonth()
                                        ,In_Place_Date__c=Date.today().addYears(-12)
                                        ,Signature_Date__c=Date.today().addYears(-12)
                                        ,Specific_VAT_Picklist__c = l==2?'20.00%':null
                                        ,Version__c=1
                                        ,RecordTypeId=ContractHomeManager.mcmRtFRId
                                        ,Service_Type__c = StaticConstants.TYPE_REGISTRATION_CERTIFICATES
                                        ,Amount_of_km_in_forfait__c=20);
            ctrHList.add(ctrH);
        }
        insert ctrHList;

        for(Contract_Home__c ctrH : [SELECT Id FROM Contract_Home__c])
        {
            for(Service__c s : [SELECT Id, Current_Standard_Price__c, Service_Category__c FROM Service__c] )
            {
                if(s.Service_Category__c=='Annual fee')
                {
                    csliList.add(new Contractual_Service_Line_Item__c(Price_Rate_1__c=s.Current_Standard_Price__c
                    ,Contract_Home__c=ctrH.Id,Service__c=s.Id,Is_From_Migration__c=TRUE));
                }
                else if(s.Service_Category__c!='Pack' && s.Service_Category__c!='Miscellaneous')
                {
                    csliList.add(new Contractual_Service_Line_Item__c(Price_Rate_1__c=s.Current_Standard_Price__c
                                ,Contract_Home__c=ctrH.Id,Service__c=s.Id));
                }
            }

        }
        insert csliList;
        
        Map<Id,Id> contractIdPerAccIdMap = new Map<Id,Id>();
        for(Contract_Home__c ctr : [SELECT Id, Account__c FROM Contract_Home__c])
        {
            contractIdPerAccIdMap.put(ctr.Account__c,ctr.Id);
        }

        Map<Id,Id> empIdPerAccIdMap = new Map<Id,Id>();
        for(Employee__c emp : [SELECT Id, Account__c FROM Employee__c])
        {
            empIdPerAccIdMap.put(emp.Account__c,emp.Id);
        }

        List<Absence_Registration__c> arList = new  List<Absence_Registration__c>();
        for(Account acc : [SELECT Id, ParentId, Invoicing_Account__c, Invoicing_On_This_Account__c FROM Account WHERE RecordTypeId=:AccountTriggerHandler.RT_DEPARTMENT])
        {
            Absence_Registration__c ar = UtilsDataTest.generateAbsenceRegistrationFR(empIdPerAccIdMap.get(acc.Id), '123', '1050', 'Doctor', false);
            ar.Status__c = 'Result to customer';
            ar.TECH_Close_Date__c = System.today().addMonths(-1);
            ar.Invoicing_Status__c = StaticConstants.AR_INVOICING_STATUS_INVOICE_TO_GENERATE;
            ar.Contract_Home__c=contractIdPerAccIdMap.get(acc.ParentId);
            ar.Account__c = acc.ParentId;
            ar.Type_of_visit_requested__c = 'During the standard hours';
            // ar.Appointment_will_be_made_by__c = 'Securex';
            ar.Notification_channel__c = 'SMS';
            arList.add(ar);
        }
        insert arList;

/*         List<WorkOrder> workOrderList = new List<WorkOrder>();
        for(Absence_Registration__c ar : [SELECT Id, Account__r.Name FROM Absence_Registration__c])
        {
            if(ar.Account__r.Name.contains('1') || ar.Account__r.Name.contains('3')  || ar.Account__r.Name.contains('5')  
                || ar.Account__r.Name.contains('7')  || ar.Account__r.Name.contains('9'))
            {

                WorkOrder woHomeVisit = new WorkOrder(AccountId = ar.Account__c
                                                ,Absence_Registration__c = ar.Id
                                                , WorkTypeId=homeVisitWorkType.Id); 
                workOrderList.add(woHomeVisit);
            }
            else {

                WorkOrder woConvocation = new WorkOrder(AccountId = ar.Account__c
                                                    ,Absence_Registration__c = ar.Id
                                                    , WorkTypeId=convocationWorkType.Id); 
                workOrderList.add(woConvocation);
            }
        }
        insert workOrderList;


        List<ServiceAppointment> saList = new List<ServiceAppointment>();
        for(WorkOrder wo : [SELECT Id, WorkTypeId, Absence_Registration__r.Contract_Home__c FROM WorkOrder])
        {
            if(wo.WorkTypeId==homeVisitWorkType.Id)
            {
                ServiceAppointment saHomeVisit = new serviceAppointment(Status = 'Scheduled'
                                                                        ,ParentRecordId = wo.Id
                                                                        ,Work_Order_tech__c= wo.Id
                                                                        ,Contract_Home__c= wo.Absence_Registration__r.Contract_Home__c
                                                                        ,SchedStartTime= System.now().addDays(-20)
                                                                        ,SchedEndTime= System.now().addDays(20) 
                                                                        ,EarliestStartTime= System.now().addDays(-20)
                                                                        ,Start_Date__c=System.today().addDays(-10)                                                           
                                                                        ,ActualStartTime=System.now().addDays(-10)
                                                                        ,ActualEndTime=System.now().addDays(10)
                                                                        ,Km_mountain__c = 40
                                                                        ,Km_Flat__c = 30
                                                                        ,Date_Time_Home_Visit__c = Date.newinstance(2021,2,6)
                                                                        ,Notify_Doctor__c=false);
                saList.add(saHomeVisit);                                                            
            }
            else
            {
                ServiceAppointment saConvocation = new serviceAppointment(Status = 'Scheduled'
                                                                        ,ParentRecordId = wo.Id
                                                                        ,Work_Order_tech__c= wo.Id
                                                                        ,Contract_Home__c= wo.Absence_Registration__r.Contract_Home__c
                                                                        ,SchedStartTime= System.now().addDays(-15)
                                                                        ,SchedEndTime= System.now().addDays(15)
                                                                        ,EarliestStartTime= System.now().addDays(-20)
                                                                        ,Start_Date__c=System.today().addDays(-10)  
                                                                        ,ActualStartTime=System.now().addDays(-5)
                                                                        ,ActualEndTime=System.now().addDays(5)
                                                                        ,Km_mountain__c = 10
                                                                        ,Km_Flat__c = 30
                                                                        ,Date_Time_convocation__c = Date.newinstance(2021,2,6)
                                                                        ,Notify_Doctor__c=false);
                saList.add(saConvocation); 
            }
        }
        insert saList;
 */
    }

    // @isTest static void findContractsBlockedForInvoicing()
    // {
    //     Account accountToInvoice = [SELECT Id, Name, Invoicing_Account__c, Invoicing_on_this_account__c
    //                                 FROM Account WHERE Name='Test Main' LIMIT 1];
    //     createInvoiceController.findContractsBlockedForInvoicing(accountToInvoice.Id);
    // }

    @isTest static void createInvoiceFromAccountTest()
    {
        test.startTest();
        List<WorkType> workTypeList = new List<WorkType>();
        WorkType homeVisitWorkType = new WorkType(Name='Home Visit with Potential Convocation',EstimatedDuration=30,DurationType='Minutes',Type_of_Service_Appointment__c='Home Visit');
        WorkType convocationWorkType = new WorkType(Name='Direct Convocation',EstimatedDuration=30,DurationType='Minutes',Type_of_Service_Appointment__c='Convocation');
        workTypeList.add(homeVisitWorkType);
        workTypeList.add(convocationWorkType);
        insert workTypeList;

        List<WorkOrder> workOrderList = new List<WorkOrder>();
        for(Absence_Registration__c ar : [SELECT Id, Account__r.Name FROM Absence_Registration__c])
        {
            if(ar.Account__r.Name.contains('1') || ar.Account__r.Name.contains('3')  || ar.Account__r.Name.contains('5')  || ar.Account__r.Name.contains('7')  || ar.Account__r.Name.contains('9'))
            {
                WorkOrder woHomeVisit = new WorkOrder(AccountId = ar.Account__c ,Absence_Registration__c = ar.Id, WorkTypeId=homeVisitWorkType.Id); 
                workOrderList.add(woHomeVisit);
            }
            else 
            {
                WorkOrder woConvocation = new WorkOrder(AccountId = ar.Account__c,Absence_Registration__c = ar.Id, WorkTypeId=convocationWorkType.Id); 
                workOrderList.add(woConvocation);
            }
        }
        insert workOrderList;

        List<ServiceAppointment> saList = new List<ServiceAppointment>();
        for(WorkOrder wo : [SELECT Id, WorkTypeId, Absence_Registration__r.Contract_Home__c FROM WorkOrder])
        {
            if(wo.WorkTypeId==homeVisitWorkType.Id)
            {
                ServiceAppointment saHomeVisit = new serviceAppointment(Status = 'Scheduled' ,ParentRecordId = wo.Id,Work_Order_tech__c= wo.Id
                                                                        ,Contract_Home__c= wo.Absence_Registration__r.Contract_Home__c
                                                                        ,SchedStartTime= System.now().addDays(-20)
                                                                        ,SchedEndTime= System.now().addDays(20) 
                                                                        ,EarliestStartTime= System.now().addDays(-20)
                                                                        ,Start_Date__c=System.today().addDays(-10)                                                           
                                                                        ,ActualStartTime=System.now().addDays(-10)
                                                                        ,ActualEndTime=System.now().addDays(10)
                                                                        ,Km_mountain__c = 40
                                                                        ,Km_Flat__c = 30
                                                                        ,Date_Time_Home_Visit__c = Date.newinstance(2021,2,6)
                                                                        ,Notify_Doctor__c=false);
                saList.add(saHomeVisit);                                                            
            }
            else
            {
                ServiceAppointment saConvocation = new serviceAppointment(Status = 'Scheduled',ParentRecordId = wo.Id,Work_Order_tech__c= wo.Id
                                                                        ,Contract_Home__c= wo.Absence_Registration__r.Contract_Home__c
                                                                        ,SchedStartTime= System.now().addDays(-15)
                                                                        ,SchedEndTime= System.now().addDays(15)
                                                                        ,EarliestStartTime= System.now().addDays(-20)
                                                                        ,Start_Date__c=System.today().addDays(-10)  
                                                                        ,ActualStartTime=System.now().addDays(-5)
                                                                        ,ActualEndTime=System.now().addDays(5)
                                                                        ,Km_mountain__c = 10
                                                                        ,Km_Flat__c = 30
                                                                        ,Date_Time_convocation__c = Date.newinstance(2021,2,6)
                                                                        ,Notify_Doctor__c=false);
                saList.add(saConvocation); 
            }
        }
        insert saList;

        Account accountToInvoice = [SELECT Id, Name, Invoicing_Account__c, Invoicing_on_this_account__c, ParentId, Active_department__c
        FROM Account WHERE RecordTypeId=:AccountTriggerHandler.RT_DEPARTMENT AND Invoicing_On_This_Account__c='Yes' LIMIT 1];
        String typeOfInvoicing = 'Service Invoicing';
        Date startDate = Date.today().addMonths(-1);
        Date endDate  = Date.today().addMonths(1);
        
        System.debug('QLE saList ' + saList);
        List<ServiceAppointment> saListToUpdate = new List<ServiceAppointment>();    
        for(ServiceAppointment sa : saList)
        {
            sa.Status=ServiceAppointmentManager.STATUS_RESULT_TO_CUSTOMER;
            saListToUpdate.add(sa);   
        }
        update saListToUpdate;

        List<ServiceAppointment> sas = [SELECT Absence_Registration__r.Invoicing_Account__r.Name, Invoicing_Status__c FROM  ServiceAppointment];
        System.debug('QLE sas ' + sas);

        List<Task> tasks = [SELECT Description FROM  Task];
        System.debug('QLE tasks ' + tasks);

        List<Service_Appointment_Line_Item__c> salis = [SELECT Invoicing_type__c
            , Service_Appointment__r.Absence_Registration__r.Invoicing_Account__c
            ,Service_Appointment__r.Absence_Registration__r.Invoicing_Status__c
            ,Service_Appointment__r.Absence_Registration__r.TECH_Close_Date__c
            FROM Service_Appointment_Line_Item__c ]; 
        System.debug('QLE salis ' + salis);


        createInvoiceController.createInvoiceFromAccount(accountToInvoice, typeOfInvoicing, startDate, endDate);
        List<Invoice__c> invoiceCreated = [SELECT Id FROM Invoice__c WHERE Invoicing_Account__c = :accountToInvoice.Invoicing_Account__c];
        test.stopTest();

    }

    // @isTest static void noInvoiceToCreateFromAccountTest()
    // {
    //     Account accountToInvoice = [SELECT Id, Name, Invoicing_Account__c, Invoicing_on_this_account__c
    //                             FROM Account  WHERE Name='Test Main' LIMIT 1];
    //     try{
    //         String typeOfInvoicing =  'Service Invoicing';
    //         Date startDate = Date.today().addMonths(2);
    //         Date endDate  = Date.today().addMonths(3);               
    //         createInvoiceController.createInvoiceFromAccount(accountToInvoice, typeOfInvoicing, startDate, endDate);
    //     }
    //     catch(Exception e){

    //     }
    //     List<Invoice__c> invoiceCreated = [SELECT Id FROM Invoice__c WHERE Invoicing_Account__c=:accountToInvoice.Invoicing_Account__c AND Document_Date__c=:System.today()]; 
    //     System.assertEquals(true,invoiceCreated.isEmpty());
    // }

    @isTest static void searchYearlyContributionInvoiceForThisYearTest()
    {
        Contract_Home__c ctrH = [SELECT Id,Account__c,Account__r.Name
                                        , Account__r.Invoicing_on_this_account__c,Name,Blocked_For_Invoicing__c
                                        ,Yearly_contribution__c,Minimum_amount_per_year__c,Fourchette__c
                                        ,In_Place_Date__c,End_Date__c
                                FROM Contract_Home__c LIMIT 1];
        createInvoiceController.searchYearlyContributionInvoiceForThisYear(ctrH);



    }

   /*  @isTest static void createInvoiceFromContractHomeTest()
    {
        Contract_Home__c ctrH = [SELECT Id,Account__c,Account__r.Name, Invoicing_Account__c
                                , Account__r.Invoicing_on_this_account__c,Name,Blocked_For_Invoicing__c
                                ,Yearly_contribution__c,Minimum_amount_per_year__c,Fourchette__c
                                ,In_Place_Date__c,End_Date__c,RecordType.Name,Invoicing_Account__r.Invoicing_Terms__c
                                ,Invoicing_Account__r.PO_Number__c,Invoicing_Terms__c,Specific_VAT_Picklist__c,Contract_Country__c 
                                FROM Contract_Home__c LIMIT 1];
        createInvoiceController.createInvoiceFromContractHome(ctrH,StaticConstants.INVOICE_TYPE_YEARLY_CONTRIBUTION_INVOICING);

        List<Invoice__c> invoiceCreated = [SELECT Id FROM Invoice__c]; 
        System.assertEquals(false,invoiceCreated.isEmpty());

    } */

    @isTest static void launchYearlyInvoicingBatchTest()
    {
        List<Contract_Home__c> ctrList = [SELECT Id, Next_due_date__c FROM Contract_Home__c];
        List<Contractual_Service_Line_Item__c> csliList = [SELECT Id,Service__r.Service_category__c
                                    ,Contract_Home__r.RecordTypeId
                                    ,Contract_Home__r.Next_due_date__c
                                    ,Contract_Home__r.Blocked_For_Invoicing__c
                                FROM Contractual_Service_Line_Item__c];
        List<Invoice__c> invoiceList = [SELECT Id, Invoicing_Account__c, Status__c FROM Invoice__c ];
        delete invoiceList;
        test.startTest();
        createInvoiceController.launchInvoicingBatch(StaticConstants.INVOICE_TYPE_YEARLY_CONTRIBUTION_INVOICING, null, null);
        test.stopTest();      
        List<Invoice__c> invoiceList2 = [SELECT Id, Invoicing_Account__c, Status__c FROM Invoice__c ];
        Test.setMock(HttpCalloutMock.class, new SapServiceHttpMock(200));
        Database.executeBatch(new sendInvoiceToSapBatch());         
        System.assertEquals(ctrList.size(), invoiceList2.size(),'Incorrect number of invoices: ' + invoiceList.size()); 
    }

    @isTest static void launchServiceInvoicingBatchTest()
    {
        test.startTest();
        List<WorkType> workTypeList = new List<WorkType>();
        WorkType homeVisitWorkType = new WorkType(Name='Home Visit with Potential Convocation',EstimatedDuration=30,DurationType='Minutes',Type_of_Service_Appointment__c='Home Visit');
        WorkType convocationWorkType = new WorkType(Name='Direct Convocation',EstimatedDuration=30,DurationType='Minutes',Type_of_Service_Appointment__c='Convocation');
        workTypeList.add(homeVisitWorkType);
        workTypeList.add(convocationWorkType);
        insert workTypeList;

        List<WorkOrder> workOrderList = new List<WorkOrder>();
        for(Absence_Registration__c ar : [SELECT Id, Account__r.Name FROM Absence_Registration__c])
        {
            if(ar.Account__r.Name.contains('1') || ar.Account__r.Name.contains('3')  || ar.Account__r.Name.contains('5')   || ar.Account__r.Name.contains('7')  || ar.Account__r.Name.contains('9'))
            {
                WorkOrder woHomeVisit = new WorkOrder(AccountId = ar.Account__c,Absence_Registration__c = ar.Id, WorkTypeId=homeVisitWorkType.Id); 
                workOrderList.add(woHomeVisit);
            }
            else 
            {
                WorkOrder woConvocation = new WorkOrder(AccountId = ar.Account__c,Absence_Registration__c = ar.Id , WorkTypeId=convocationWorkType.Id); 
                workOrderList.add(woConvocation);
            }
        }
        insert workOrderList;

        List<ServiceAppointment> saList = new List<ServiceAppointment>();
        for(WorkOrder wo : [SELECT Id, WorkTypeId, Absence_Registration__r.Contract_Home__c FROM WorkOrder])
        {
            if(wo.WorkTypeId==homeVisitWorkType.Id)
            {
                ServiceAppointment saHomeVisit = new serviceAppointment(Status = 'Scheduled' ,ParentRecordId = wo.Id ,Work_Order_tech__c= wo.Id
                                                                        ,Contract_Home__c= wo.Absence_Registration__r.Contract_Home__c
                                                                        ,SchedStartTime= System.now().addDays(-20)
                                                                        ,SchedEndTime= System.now().addDays(20) 
                                                                        ,EarliestStartTime= System.now().addDays(-20)
                                                                        ,Start_Date__c=System.today().addDays(-10)                                                           
                                                                        ,ActualStartTime=System.now().addDays(-10)
                                                                        ,ActualEndTime=System.now().addDays(10)
                                                                        ,Km_mountain__c = 40
                                                                        ,Km_Flat__c = 30
                                                                        ,Date_Time_Home_Visit__c = Date.newinstance(2021,2,6)
                                                                        ,Notify_Doctor__c=false);
                saList.add(saHomeVisit);                                                            
            }
            else
            {
                ServiceAppointment saConvocation = new serviceAppointment(Status = 'Scheduled',ParentRecordId = wo.Id,Work_Order_tech__c= wo.Id
                                                                        ,Contract_Home__c= wo.Absence_Registration__r.Contract_Home__c
                                                                        ,SchedStartTime= System.now().addDays(-15)
                                                                        ,SchedEndTime= System.now().addDays(15)
                                                                        ,EarliestStartTime= System.now().addDays(-20)
                                                                        ,Start_Date__c=System.today().addDays(-10)  
                                                                        ,ActualStartTime=System.now().addDays(-5)
                                                                        ,ActualEndTime=System.now().addDays(5)
                                                                        ,Km_mountain__c = 10
                                                                        ,Km_Flat__c = 30
                                                                        ,Date_Time_convocation__c = Date.newinstance(2021,2,6)
                                                                        ,Notify_Doctor__c=false);
                saList.add(saConvocation); 
            }
        }
        insert saList;
        List<ServiceAppointment> saListToUpdate = new List<ServiceAppointment>();    
        for(ServiceAppointment sa : saList)
        {
            sa.Status=ServiceAppointmentManager.STATUS_RESULT_TO_CUSTOMER;
            saListToUpdate.add(sa);   
        }
        update saListToUpdate;
        createInvoiceController.launchInvoicingBatch(StaticConstants.INVOICE_TYPE_SERVICE_INVOICING, Date.today(), Date.today());
        test.stopTest();
        List<Invoice__c> invoiceList = [SELECT Id, Status__c, Document_Date__c FROM Invoice__c ];
        for(Invoice__C inv : invoiceList)
        {
            inv.Status__c=StaticConstants.INVOICE_STATUS_VALIDATED_BY_SAP;
        }
        update invoiceList;  
        Database.executeBatch(new sendInvoiceToScripturaBatch());
        System.assertEquals(10, invoiceList.size(),'Incorrect number of invoices: ' + invoiceList.size());
    }

    @isTest static void InvoicingAccountIsInactiveYearlyInvoicingBatchTest()
    {
        List<Contract_Home__c> ctrList = [SELECT Id, Next_due_date__c,Invoicing_Account__c FROM Contract_Home__c];

        Date startInvoicing = System.today().addMonths(-1).toStartOfMonth();

        List<Account> accListToUpdate = new List<Account>();

        for(Contract_Home__c ctr : ctrList){
            Account acc = new Account(Id=ctr.Invoicing_Account__c);
            acc.Date_out__c = startInvoicing.addMonths(-1);
            accListToUpdate.add(acc);
        }
        update accListToUpdate;

        List<Invoice__c> invoiceList = [SELECT Id, Invoicing_Account__c, Status__c FROM Invoice__c ];
        delete invoiceList;
        test.startTest();
        createInvoiceController.launchInvoicingBatch(StaticConstants.INVOICE_TYPE_YEARLY_CONTRIBUTION_INVOICING, null, null);
        test.stopTest();      
        List<Invoice__c> invoiceList2 = [SELECT Id, Invoicing_Account__c, Status__c FROM Invoice__c ];
        Test.setMock(HttpCalloutMock.class, new SapServiceHttpMock(200));
        Database.executeBatch(new sendInvoiceToSapBatch());         
    }


    @isTest static void InvoicingAccountIsInactiveServicing()
    {
        test.startTest();
        List<WorkType> workTypeList = new List<WorkType>();
        WorkType homeVisitWorkType = new WorkType(Name='Home Visit with Potential Convocation',EstimatedDuration=30,DurationType='Minutes',Type_of_Service_Appointment__c='Home Visit');
        WorkType convocationWorkType = new WorkType(Name='Direct Convocation',EstimatedDuration=30,DurationType='Minutes',Type_of_Service_Appointment__c='Convocation');
        workTypeList.add(homeVisitWorkType);
        workTypeList.add(convocationWorkType);
        insert workTypeList;
        Date startDateInvoicingPeriod = System.today().addMonths(-1).toStartOfMonth();
        List<Account> invAccList = [SELECT Id, Date_out__c, ParentId, Name FROM Account WHERE (Name='Invoicing Dep 1' OR Name='Invoicing Dep 2') ORDER BY Name ASC];
        for(Account acc: invAccList)
        {
            if(acc.Name=='Invoicing Dep 1')
            {
                acc.Date_out__c= System.today().addDays(-15);
                
            }
            if(acc.Name=='Invoicing Dep 2')
            {
                acc.Date_out__c= startDateInvoicingPeriod.addDays(-10);
            }
        }
        update invAccList;
        
        List<WorkOrder> workOrderList = new List<WorkOrder>();
        for(Absence_Registration__c ar : [SELECT Id, Account__r.Name, Account__r.ParentId FROM Absence_Registration__c WHERE (Invoicing_Account__c= :invAccList[0].Id OR Invoicing_Account__c= :invAccList[1].Id)])
        {
            if(ar.Account__r.Name.contains('1') || ar.Account__r.Name.contains('3')  || ar.Account__r.Name.contains('5')  
                || ar.Account__r.Name.contains('7')  || ar.Account__r.Name.contains('9'))
            {

                WorkOrder woHomeVisit = new WorkOrder(AccountId = ar.Account__c
                                                ,Absence_Registration__c = ar.Id
                                                , WorkTypeId=homeVisitWorkType.Id); 
                workOrderList.add(woHomeVisit);
            }
            else {
                
                WorkOrder woConvocation = new WorkOrder(AccountId = ar.Account__c
                ,Absence_Registration__c = ar.Id
                , WorkTypeId=convocationWorkType.Id); 
                workOrderList.add(woConvocation);
            }
        }
        insert workOrderList;

        List<ServiceAppointment> saList = new List<ServiceAppointment>();
        for(WorkOrder wo : [SELECT Id, WorkTypeId, Absence_Registration__r.Contract_Home__c FROM WorkOrder])
        {
            if(wo.WorkTypeId==homeVisitWorkType.Id)
            {
                ServiceAppointment saHomeVisit = new serviceAppointment(Status = 'Scheduled'
                                                                        ,ParentRecordId = wo.Id
                                                                        ,Work_Order_tech__c= wo.Id
                                                                        ,Contract_Home__c= wo.Absence_Registration__r.Contract_Home__c
                                                                        ,SchedStartTime= System.now().addDays(-20)
                                                                        ,SchedEndTime= System.now().addDays(20) 
                                                                        ,EarliestStartTime= System.now().addDays(-20)
                                                                        ,Start_Date__c=System.today().addDays(-10)                                                           
                                                                        ,ActualStartTime=System.now().addDays(-10)
                                                                        ,ActualEndTime=System.now().addDays(10)
                                                                        ,Km_mountain__c = 40
                                                                        ,Km_Flat__c = 30
                                                                        ,Date_Time_Home_Visit__c = Date.newinstance(2021,2,6)
                                                                        ,Notify_Doctor__c=false);
                saList.add(saHomeVisit);                                                            
            }
            else
            {
                ServiceAppointment saConvocation = new serviceAppointment(Status = 'Scheduled'
                                                                        ,ParentRecordId = wo.Id
                                                                        ,Work_Order_tech__c= wo.Id
                                                                        ,Contract_Home__c= wo.Absence_Registration__r.Contract_Home__c
                                                                        ,SchedStartTime= System.now().addDays(-15)
                                                                        ,SchedEndTime= System.now().addDays(15)
                                                                        ,EarliestStartTime= System.now().addDays(-20)
                                                                        ,Start_Date__c=System.today().addDays(-10)  
                                                                        ,ActualStartTime=System.now().addDays(-5)
                                                                        ,ActualEndTime=System.now().addDays(5)
                                                                        ,Km_mountain__c = 10
                                                                        ,Km_Flat__c = 30
                                                                        ,Date_Time_convocation__c = Date.newinstance(2021,2,6)
                                                                        ,Notify_Doctor__c=false);
                saList.add(saConvocation); 
            }
        }
        insert saList;
        List<ServiceAppointment> saListToUpdate = new List<ServiceAppointment>();    
        for(ServiceAppointment sa : saList)
        {
            sa.Status=ServiceAppointmentManager.STATUS_RESULT_TO_CUSTOMER;
            saListToUpdate.add(sa);   
        }
        update saListToUpdate;
        createInvoiceController.launchInvoicingBatch(StaticConstants.INVOICE_TYPE_SERVICE_INVOICING, Date.today().addDays(-30), Date.today());
        test.stopTest();
        List<Invoice__c> invoiceList = [SELECT Id, Status__c, Document_Date__c FROM Invoice__c ];
        for(Invoice__C inv : invoiceList)
        {
            inv.Status__c=StaticConstants.INVOICE_STATUS_VALIDATED_BY_SAP;
        }
        update invoiceList;  
        Database.executeBatch(new sendInvoiceToScripturaBatch());
        
        //Task task = [SELECT Id, Description FROM Task WHERE WhatId= :invAccOut.Id];
        //System.assertEquals(Label.commentTaskInactiveInvoicingDep, task.Description);

    }

    public class SapServiceHttpMock implements HttpCalloutMock 
    {
        Integer statusCode = 200;

        public SapServiceHttpMock(Integer statusCode)
        {
            this.statusCode = statusCode;
        }

        public HttpResponse respond(HTTPRequest req)
        {
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');
            res.setBody('[{"trackingHeader":{"trackingIdentification":"GenDatUniqueRef007","companyCode":"40","customerSap":"2000478456","securexNumber":"0012345680"},"return":[{"type":"W","identification":"T5","number":"194","text":"Telephonenumbercannotcontainacountrycode","variable1":"+3292220000","variable2":"+32"},{"type":"W","identification":"T5","number":"194","text":"Telephonenumbercannotcontainacountrycode","variable1":"+32486000000","variable2":"+32"}]}]');       
            res.setStatusCode(statusCode);
            System.debug('QLE Mock statusCode ' + statusCode);
            return res;
        }
    }
}