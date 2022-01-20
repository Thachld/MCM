@istest
public with sharing class ContractualServiceLineItemManagerTest {
    @TestSetup static void setUpTestData()
    {
        FSL.GlobalAPIS.addStatusTransition('None',ServiceAppointmentManager.STATUS_RESULT_TO_CUSTOMER);
        FSL.GlobalAPIS.addStatusTransition('Scheduled',ServiceAppointmentManager.STATUS_RESULT_TO_CUSTOMER);
        
        List<Account> mainAccList = new List<Account>();
        List<Contract_Home__c> ctrHList = new List<Contract_Home__c>();
        List<Contractual_Service_Line_Item__c> csliList = new List<Contractual_Service_Line_Item__c>();
        
        UtilsDataTest.generateMCMProduct(true);
        
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

        for(Integer i=0;i<1;i++)
        {
            accValueMap.put('Official_HouseNr__c', '' + i);
            accValueMap.put('Correspondence_HouseNr__c','' + i);
            accValueMap.put('Official_address_name__c', 'name'+ i);
            accValueMap.put('Securex_Number__c', '123'+ i);
            accValueMap.put('Correspondence_name__c','name corr'+ i);
            Account mainAcc = UtilsData.generateAccount('Main Acc ' + i
                                    , AccountTriggerHandler.RT_FRANCE_ACCOUNT_MAIN
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
        for(Account mainAcc : mainAccList)
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
        System.debug('invDepList=>' + invDepList);

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
        for(Account invDep : invDepList)
        {
            i++;
            Employee__c emp = UtilsDataTest.generateExternalEmployee('mcm emp' + i,invDep.Id, 'mcm' + i + '@test.com','2209'+i, false);
            emplList.add(emp);
        }
        update accListToUpdate;

        List<Account> depList = new List<Account>();
        Integer j = 0;
        for(Account invAcc : invDepList)
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
        for(Account dep : depList)
        {
            k++;
            Employee__c emp = UtilsDataTest.generateExternalEmployee('mcm emp1 ' + k,dep.Id, 'mcm1' + k + '@test.com','2208' + k, false);
            emplList.add(emp);
        }
        insert emplList;

        
        Integer l=0;
        for(Account invAcc : invDepList)
        {
            l++;
            Contract_Home__c ctrH = new Contract_Home__c(Account__c=invAcc.ParentId
                                        ,Invoicing_Account__c = invAcc.Id
                                        ,Yearly_contribution__c=true
                                        //,Next_due_date__c = Date.today().addMonths(-1) New VR only filled in Tacitly Renewal
                                        ,In_Place_Date__c=Date.today().addYears(-12)
                                        ,Signature_Date__c=Date.today().addYears(-12)
                                        ,Specific_VAT_Picklist__c = l==2?'20.00%':null
                                        ,Version__c=1
                                        ,Product__c = ContractHomeManager.mcmFrProductId
                                        ,RecordTypeId=ContractHomeManager.mcmRtFRId
                                        ,Service_Type__c = StaticConstants.TYPE_REGISTRATION_CERTIFICATES
                                        ,Amount_of_km_in_forfait__c=20);
            ctrHList.add(ctrH);
        }
        insert ctrHList;

        for(Contract_Home__c ctrH : ctrHList)
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
        for(Contract_Home__c ctr : ctrHList)
        {
            contractIdPerAccIdMap.put(ctr.Account__c,ctr.Id);
        }

        Map<Id,Id> empIdPerAccIdMap = new Map<Id,Id>();
        for(Employee__c emp : emplList)
        {
            empIdPerAccIdMap.put(emp.Account__c,emp.Id);
        }        

        List<Absence_Registration__c> arList = new  List<Absence_Registration__c>();
        for(Account acc : depList)
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

        WorkType homeVisitWorkType = new WorkType(Name='Home Visit with Potential Convocation',EstimatedDuration=30,DurationType='Minutes',Type_of_Service_Appointment__c='Home Visit');
        insert homeVisitWorkType;
        WorkType convocationWorkType = new WorkType(Name='Direct Convocation',EstimatedDuration=30,DurationType='Minutes',Type_of_Service_Appointment__c='Convocation');
        insert convocationWorkType;

        List<WorkOrder> workOrderList = new List<WorkOrder>();
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
                                                                        ,Absence_Registration__c = arList[0].Id
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
                                                                        ,Absence_Registration__c = arList[0].Id
                                                                        ,Date_Time_convocation__c = Date.newinstance(2021,2,6)
                                                                        ,Notify_Doctor__c=false);
                saList.add(saConvocation); 
            }
        }
        insert saList;
        
        List<Service_Appointment_Line_Item__c> listInsertIDL = new List<Service_Appointment_Line_Item__c>();       
        for(ServiceAppointment sa : saList ){

            Service_Appointment_Line_Item__c idl1 = createSALI(sa.Id, services[0].Id , null, 100, 'Test');
            Service_Appointment_Line_Item__c idl2 = createSALI(sa.Id, services[1].Id, null, 100, 'Test');
            listInsertIDL.add(idl1);
            listInsertIDL.add(idl2);
        }

        insert listInsertIDL;

    }


    public testMethod static void TestcheckIfContractServiceInUse1(){
        Test.startTest();
        List<Contractual_Service_Line_Item__c> listcslitest = [SELECT Id, Price_Rate_1__c, Supplement__c FROM Contractual_Service_Line_Item__c];

        try {
            Contractual_Service_Line_Item__c cslitest = listcslitest[0];
            cslitest.Price_Rate_1__c = 1;            

            update cslitest;

        } catch (Exception ex) {
            String updatepriceMsg = Label.NotAllowChangeContractServicePrice;
            Boolean valid = ex.getMessage().contains(updatepriceMsg)?true:false;
            System.assertEquals(true, valid);
        }        

        Test.stopTest();
    }

    // public testMethod static void TestcheckIfContractServiceInUse2(){
    //     Test.startTest();
    //     List<Contractual_Service_Line_Item__c> listcslitest = [SELECT Id, Price_Rate_1__c, Supplement__c FROM Contractual_Service_Line_Item__c];

    //     try {
    //         Contractual_Service_Line_Item__c cslitest = listcslitest[0];
    //         cslitest.Supplement__c = 11;            

    //         update cslitest;

    //     } catch (Exception ex) {
    //         String updateSupplementMsg = Label.NotAllowChangeContractServiceSupplement;
    //         Boolean valid = ex.getMessage().contains(updateSupplementMsg)?true:false;
    //         System.assertEquals(true, valid);
    //     }

    //     Test.stopTest();
    // }



    public testMethod static void TestcheckIfContractServiceInUse_negative(){
        Test.startTest();
            List<Contractual_Service_Line_Item__c> listcslitest = [SELECT Id, Price_Rate_1__c, Supplement__c FROM Contractual_Service_Line_Item__c];

            Contractual_Service_Line_Item__c cslitest = listcslitest[3];
            cslitest.Price_Rate_1__c = 1;   
            update cslitest;


            Contractual_Service_Line_Item__c aftertest = [SELECT Id, Price_Rate_1__c FROM Contractual_Service_Line_Item__c WHERE Id = :cslitest.Id ];

            System.assertEquals(cslitest.Price_Rate_1__c, aftertest.Price_Rate_1__c);

        Test.stopTest();
    }


    
    public testMethod static void TestdeleteContractServiceInUse(){
        Test.startTest();
            List<Contractual_Service_Line_Item__c> listcslitest = [SELECT Id FROM Contractual_Service_Line_Item__c];

            try {
                delete listcslitest[0];
            } catch (Exception ex) {
                String deleteMsg = Label.NotAllowDeleteContractService;
                Boolean valid = ex.getMessage().contains(deleteMsg)?true:false;
                System.assertEquals(true, valid);
            }

        Test.stopTest();
    }

    public testMethod static void TestdeleteContractServiceInUse_Negative(){
        Test.startTest();
            List<Contractual_Service_Line_Item__c> listcslitest = [SELECT Id FROM Contractual_Service_Line_Item__c];

            delete listcslitest[4];
            
            List<Contractual_Service_Line_Item__c> aftertest = [SELECT Id, Price_Rate_1__c FROM Contractual_Service_Line_Item__c WHERE Id = :listcslitest[4].Id ];

            System.assertEquals(0, aftertest.size());
        Test.stopTest();
    }




    public static Service_Appointment_Line_Item__c createSALI(Id saId, Id serviceId, Id iliId, Decimal amt, String nameDoctor)
    {
        Service_Appointment_Line_Item__c sali = new Service_Appointment_Line_Item__c(Service_Appointment__c=saId
                                                                    ,Service__c = serviceId
                                                                    ,Name_doctor__c = nameDoctor
                                                                    ,Amount__c = amt
                                                                    ,InvoiceLineItem__c = iliId
                                                                    ,Invoicing_Type__c = ServiceAppointmentManager.INVOICE_DETAIL_LINE_CI_TYPE );
        return sali;
    }
    
}