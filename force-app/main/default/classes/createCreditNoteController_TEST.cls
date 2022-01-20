@istest
public with sharing class createCreditNoteController_TEST {
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

        for(Integer i=0;i<1;i++)
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
                                        ,Next_due_date__c = Date.today().addMonths(-1)
                                        ,In_Place_Date__c=Date.today().addYears(-12)
                                        ,Signature_Date__c=Date.today().addYears(-12)
                                        ,Specific_VAT_Picklist__c = l==2?'20.00%':null
                                        ,Version__c=1
                                        // ,Product__c = p.Id
                                        ,RecordTypeId=ContractHomeManager.mcmRtFRId
                                        ,Service_Type__c = StaticConstants.TYPE_MEDICAL_CHECK_ILLNESS
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


        List<Invoice__c> insertInvs = new List<Invoice__c>();
         Id rtId = Schema.SObjectType.Invoice__c.getRecordTypeInfosByDeveloperName().get(InvoiceManager.RT_INVOICE_MEDICAL_CONTROL).getRecordTypeId();
        Invoice__c serviceINv = createMCMInvoice('30', 'FR', InvoiceManager.INVOICE_TYPE_CN_SERVICE_INVOICING, 'Draft',ctrHList[0].Id,'FRA','60',invDepList[0].Id , '', 10, '',rtId);
        Invoice__c yearlyINv = createMCMInvoice('30', 'FR', InvoiceManager.INVOICE_TYPE_CN_YEARLY_CONTRIBUTION_INVOICING, 'Draft',ctrHList[0].Id,'FRA','60', invDepList[0].Id, '', 5, '',rtId);
        // Invoice__c packINv = createMCMInvoice('30', 'FR', InvoiceManager.INVOICE_TYPE_PACK_INVOICING, 'Draft',ctrHList[0].Id,'FRA','60', invDepList[0].Id, '', 5, '',rtId);
        insertInvs.add(serviceINv);
        insertInvs.add(yearlyINv);
        insert insertInvs;

        List<Absence_Registration__c> arList = new  List<Absence_Registration__c>();
        for(Account acc : depList)
        {
            Absence_Registration__c ar = UtilsDataTest.generateAbsenceRegistrationFR(empIdPerAccIdMap.get(acc.Id), '123', '1050', 'Doctor', false);
            ar.Status__c = 'Result to customer';
            ar.TECH_Close_Date__c = System.today().addMonths(-1);
            ar.Invoicing_Status__c = StaticConstants.AR_INVOICING_STATUS_INVOICE_TO_GENERATE;
            ar.Contract_Home__c=contractIdPerAccIdMap.get(acc.ParentId);
            ar.Account__c = acc.ParentId;
            ar.Invoice__c = insertInvs[0].Id;
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
        System.debug('saList[0]=>' + saList[0]);
        System.debug('arList[0]=>' + arList[0]);
       

        List<InvoiceLineItem__c> listInsertILI = new List<InvoiceLineItem__c>();
        List<InvoiceLineItem__c> listInsertServiceILI = new List<InvoiceLineItem__c>();
        for(Invoice__c inv: insertInvs){   
            if(inv.Invoicing_Type__c == InvoiceManager.INVOICE_TYPE_YEARLY_CONTRIBUTION_INVOICING
                || inv.Invoicing_Type__c == InvoiceManager.INVOICE_TYPE_PACK_INVOICING){
                    InvoiceLineItem__c ili1 = createMCMInvoiceLineItem(inv.Id, 'Frais divers', 1 , 100, csliList[0].Id);
                    InvoiceLineItem__c ili2 = createMCMInvoiceLineItem(inv.Id, 'Contre-visite à domicile', 1 , 200, csliList[0].Id);
                    listInsertILI.add(ili1);
                    listInsertILI.add(ili2);
                }else {
                    InvoiceLineItem__c ili1 = createMCMInvoiceLineItem(inv.Id, 'Frais divers', 1 , 100, csliList[0].Id);
                    InvoiceLineItem__c ili2 = createMCMInvoiceLineItem(inv.Id, 'Contre-visite à domicile', 1 , 200, csliList[0].Id);
                    listInsertServiceILI.add(ili1);
                    listInsertServiceILI.add(ili2);
                }
           
        }

        insert listInsertServiceILI;
        insert listInsertILI;


        List<Service_Appointment_Line_Item__c> listInsertIDL = new List<Service_Appointment_Line_Item__c>();       
        for(InvoiceLineItem__c ili : listInsertServiceILI ){

            Service_Appointment_Line_Item__c idl1 = createSALI(saList[0].Id, services[0].Id ,ili.Id, 100, 'Test');
            Service_Appointment_Line_Item__c idl2 = createSALI(saList[0].Id, services[0].Id, ili.Id, 100, 'Test');
            listInsertIDL.add(idl1);
            listInsertIDL.add(idl2);
        }

        insert listInsertIDL;

    }


    @istest
    public static void testGetInvoiceInfo(){
        Test.startTest();
            Invoice__c inv = [SELECT Id,Invoicing_Type__c FROM Invoice__c LIMIT 1];

            createCreditNoteController.InvoiceWrapper info = createCreditNoteController.getInvoiceInfo(inv.Id);
            System.assertEquals(inv.Invoicing_Type__c, info.InvoicingType);
        Test.stopTest();
    }

    @istest
    public static void testGetServiceAppointment(){
        Test.startTest();
            Invoice__c inv = [SELECT Id FROM Invoice__c WHERE Invoicing_Type__C = :InvoiceManager.INVOICE_TYPE_CN_SERVICE_INVOICING LIMIT 1];

            List<ServiceAppointment> listtestSA = createCreditNoteController.getServiceAppointments(inv.Id);
            System.assertEquals(1, listtestSA.size());
        Test.stopTest();
    }

    @istest
    public static void testServiceAppointmentDetail(){
        Test.startTest();
            Invoice__c inv = [SELECT Id FROM Invoice__c WHERE Invoicing_Type__C = :InvoiceManager.INVOICE_TYPE_CN_SERVICE_INVOICING LIMIT 1];

            List<Service_Appointment_Line_Item__c> listtestSADL = createCreditNoteController.getServiceAppointmentLineItems(inv.Id);
            System.assertEquals(8, listtestSADL.size());
        Test.stopTest();
    }

    @istest
    public static void testgetInvoiceDetailLineBySA(){
        Test.startTest();
            Set<String> setSAIds = new Set<String>();
            for(ServiceAppointment sa : [SELECT Id FROM ServiceAppointment WHERE Absence_Registration__c != null]){
                setSAIds.add(sa.Id);
            }


            Map<String,List<Service_Appointment_Line_Item__c>> mapvalue = createCreditNoteController.getInvoiceDetailLineBySA(setSAIds);
            System.assertEquals(4, mapvalue.values().size());

        Test.stopTest();
    }


    @istest
    public static void testgetInvoiceDetailLineByIds(){
        Test.startTest();
            Set<String> setSADLIds = new Set<String>();
            for(Service_Appointment_Line_Item__c sa : [SELECT Id FROM Service_Appointment_Line_Item__c]){
                setSADLIds.add(sa.Id);
            }

            Map<String,List<Service_Appointment_Line_Item__c>> mapvalue = createCreditNoteController.getInvoiceDetailLineByIds(setSADLIds);
            System.assertEquals(4, mapvalue.values().size());
        Test.stopTest();
    }

    @istest
    public static void testgetInvoiceDetailLineByInvoice(){
        Test.startTest();
            Invoice__c inv = [SELECT Id FROM Invoice__c WHERE Invoicing_Type__C = :InvoiceManager.INVOICE_TYPE_CN_SERVICE_INVOICING LIMIT 1];

            Map<String,List<Service_Appointment_Line_Item__c>> mapvalue = createCreditNoteController.getInvoiceDetailLineByInvoice(inv.Id);
            System.assertEquals(4, mapvalue.values().size());
        Test.stopTest();
    }

    @istest
    public static void testgetInvoiceLineItemByIds(){
        Test.startTest();
            Set<String> setILIIds = new Set<String>();
            for(InvoiceLineItem__c ili : [SELECT Id FROM InvoiceLineItem__c]){
                setILIIds.add(ili.Id);
            }

            List<InvoiceLineItem__c> listtestILI = createCreditNoteController.getInvoiceLineItemByIds(setILIIds);
            System.assertEquals(4, listtestILI.size());
        Test.stopTest();
    }

    @istest
    public static void testgetInvoiceLineItemByInvoice(){
        Test.startTest();
            Invoice__c inv = [SELECT Id FROM Invoice__c WHERE Invoicing_Type__C = :InvoiceManager.INVOICE_TYPE_CN_SERVICE_INVOICING LIMIT 1];
            List<InvoiceLineItem__c> listtestILI = createCreditNoteController.getInvoiceLineItemByInvoice(inv.Id);
            System.assertEquals(2, listtestILI.size());
        Test.stopTest();
    }
 

    @istest
    public static void testCreateCNFromserivceInvoice(){
        Test.startTest();
            Invoice__c inv = [SELECT Id FROM Invoice__c WHERE Invoicing_Type__C = :InvoiceManager.INVOICE_TYPE_CN_SERVICE_INVOICING LIMIT 1];
            List<String> selectionvls = new List<String>();
            Invoice__c creditNotetest = createCreditNoteController.createCreditNote(inv.Id, 'ALL', selectionvls);
            System.assertEquals(inv.Id, creditNotetest.Initial_Invoice__c);

            createCreditNoteController.InvoiceWrapper info = createCreditNoteController.getInvoiceInfo(inv.Id);
            System.assertEquals(true, info.IsExist);
        Test.stopTest();
    }

    @istest
    public static void testCreateCNYeallynvoice(){
        Test.startTest();
            Invoice__c inv = [SELECT Id FROM Invoice__c WHERE Invoicing_Type__C = :InvoiceManager.INVOICE_TYPE_CN_YEARLY_CONTRIBUTION_INVOICING LIMIT 1];
            List<String> selectionvls = new List<String>();
            Invoice__c creditNotetest = createCreditNoteController.createCreditNote(inv.Id, 'ALL', selectionvls);
            System.assertEquals(inv.Id, creditNotetest.Initial_Invoice__c);
        Test.stopTest();
    }


    @istest
    public static void testCreateCNFromServiceAppointment(){
        Test.startTest();
            Invoice__c inv = [SELECT Id FROM Invoice__c WHERE Invoicing_Type__C = :InvoiceManager.INVOICE_TYPE_CN_SERVICE_INVOICING LIMIT 1];
            List<String> selectionvls = new List<String>();
            for(ServiceAppointment sa : [SELECT Id FROM ServiceAppointment WHERE Absence_Registration__r.Invoice__c = : inv.Id]){
                selectionvls.add(sa.Id);
            }
            Invoice__c creditNotetest = createCreditNoteController.createCreditNote(inv.Id, 'SA', selectionvls);

            System.assertEquals(inv.Id, creditNotetest.Initial_Invoice__c);
        Test.stopTest();
    }


    @istest
    public static void testCreateCNFromServiceAppointmentDetail(){
        Test.startTest();
            Invoice__c inv = [SELECT Id FROM Invoice__c WHERE Invoicing_Type__C = :InvoiceManager.INVOICE_TYPE_CN_SERVICE_INVOICING LIMIT 1];
            List<String> selectionvls = new List<String>();
            for(Service_Appointment_Line_Item__c sa : [SELECT Id FROM Service_Appointment_Line_Item__c WHERE Service_Appointment__r.Absence_Registration__r.Invoice__c = :inv.Id]){
                selectionvls.add(sa.Id);
            }
            Invoice__c creditNotetest = createCreditNoteController.createCreditNote(inv.Id, 'IDL', selectionvls);
            System.assertEquals(inv.Id, creditNotetest.Initial_Invoice__c);
        Test.stopTest();
    }





    public static Invoice__c createMCMInvoice(String docType, String lg , String invoicingType, String invoiceStatus, Id contractHomeId, String contractHomeCountry
					, String invoicingTerm, Id invoicingAccId, String errorReason, Decimal specificVAT, String poNum, Id rtId)
	{
		Invoice__c invoice = new Invoice__c(Document_Date__c = System.today()
													,Invoicing_Type__c = invoicingType
													,Status__c=invoiceStatus
													,Contract_Home__c=contractHomeId
													,Contract_Country_Picklist__c = contractHomeCountry
													,Invoicing_Account__c=invoicingAccId
													,Invoicing_Terms__c= invoicingTerm													
													,RecordTypeId = rtId 
													,Error_reason__c=errorReason
													,Document_Type__c = docType
													,Specific_VAT__c = specificVAT
													,PO_Number__c = poNum
													,Billing_Language__c = lg);
		return invoice;
	}

    public static InvoiceLineItem__c createMCMInvoiceLineItem(Id invoiceId, String description, Integer quantity, Decimal Amount,  Id csliID)
	{
		InvoiceLineItem__c invoiceLine= new InvoiceLineItem__c(Invoice__c = invoiceId
                                                                ,Description__c= description
                                                                ,Amount_Excluding_VAT_Currency__c=Amount
                                                                //,Amount_Including_VAT_Currency__c=quantity*unitPrice
                                                                // ,Unit_Price__c=unitPrice
                                                                ,Quantity__c=quantity
                                                                ,Contractual_Service_Line_Item__c=csliID
                                                                ,RecordTypeId = UtilsConstants.RT_ID_INVOICE_LINE_ITEM_MEDICAL_CONTROL);
		return invoiceLine;
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