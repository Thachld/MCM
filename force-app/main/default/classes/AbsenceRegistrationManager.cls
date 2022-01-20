/************************************************************************************
* @author       Novera
* @description  This class manage the logic related to Absence registration from the trigger
* @date         2020-10-20
* @group        MCM
* @RelatedUS    OAPPMEDCHEsCK-417, OAPPMEDCHECK-423
*************************************************************************************/
public without sharing class AbsenceRegistrationManager {

    public enum AbsenceType {BE,FR}


    public static final String STATUS_RECEIVED =  'Received';
    public static final String READY_FOR_EXTRA_CHECKS =  'Ready for extra checks';
    public static final String READY_FOR_FOR_TREATMENT =  'Ready for Treatment';
    public static final String RUN_PROCESS =  'Run process';
    public static final String STATUS_INITIATE_MC = 'Initiate MC';
    public static final String STATUS_MC_INITIATED = 'MC initiated';
    public static final String MC_ONGOING = 'MC ongoing';
    public static final String STATUS_TREATED_NO_MC=  'Treated - no MC';
    public static final String STATUS_CANCELED = 'MC canceled';

    public static final String Execute_MC_YES =  'Yes';
    public static final String Execute_MC_NO =  'No';

    public static final String QUEUE_MCM_GENERAL_BE = 'MCM_General_BE';
    public static final String QUEUE_MCM_GENERAL_FR = 'MCM_General_FR';

    public static final String ABSENCE_REGISTRATION_RT_BE = Schema.SObjectType.Absence_Registration__c.getRecordTypeInfosByDeveloperName().get(StaticConstants.Absence_Registration_RT_BE).getRecordTypeId();
    public static final String ABSENCE_REGISTRATION_RT_FR = Schema.SObjectType.Absence_Registration__c.getRecordTypeInfosByDeveloperName().get(StaticConstants.Absence_Registration_RT_FR).getRecordTypeId();

    public static final String COUNTRY_BE = 'BE';
    public static final String COUNTRY_FR = 'FR';

    public static final String EXITS_AUTHORIZED = 'Authorized';
    public static final String EXITS_FREE = 'Free exits';
    public static final String EXITS_FORBIDDEN = 'Forbidden';
    public static final String EXITS_NOT_MENTIONNED = 'Not mentionned';
    public static final String EXITS_MANDATORY_HOURS = 'Mandatory attendance hours';
    public static final String EXITS_SPECIFIED_HOURS = 'Exits allowed during specified hours';


    public static final String TASK_SUBJECT_BLOCKED_BY_INVOICING = System.Label.Blocked_by_invoicing;
    public static final String TASK_DESCRIPTION_BLOCKED_BY_INVOICING = System.Label.Blocked_by_invoicing_description;
    public static final String TASK_SUBJECT_BLOCKED_BY_SERVICES = System.Label.Blocked_by_services;
    public static final String TASK_SUBJECT_BLOCKED_BY_SERVICES_DESCRIPTION = System.Label.Blocked_by_services_description;
    public static final String TASK_SUBJECT_BLOCKED_BY_PACK_EMPTY = System.Label.Blocked_by_pack_empty;
    public static final String TASK_DESCRIPTION_BLOCKED_BY_PACK_EMPTY = System.Label.Blocked_by_pack_empty_description;
    public static final String TASK_SUBJECT_PROTEST_CERTIFICATE = System.Label.Protest_certificate;
    public static final String TASK_SUBJECT_ADDITIONAL_INFORMATION_CERTIFICATE = System.Label.Additional_information_on_certificate;
    public static final String TASK_SUBJECT_EXECUTE_CONTROL_WITH_ABSENCE_IN_PAST = System.Label.Execute_control_with_absence_in_past;
    public static final String TASK_SUBJECT_EXECUTE_CONTROL_WITH_ABSENCE_IN_PAST_DESCRIPTION = System.Label.Execute_control_with_absence_in_past_description;
    public static final String TASK_SUBJECT_EMPLOYEE_MIGHT_BE_BACK_TO_WORK = System.Label.Employee_might_be_back_to_work;
    public static final String TASK_SUBJECT_UNABLE_EVALUATE_MC = System.Label.Unable_to_evaluate_if_MC;
    public static final String TASK_SUBJECT_PROTEST_CERTIFICATE_OTHER_REASON = System.Label.Protest_certificate_of_longer_duration_or_other_reason;
    public static final String TASK_COMMENT_ABSENCE_IS_A_PROTEST_MANUALLY = System.Label.Absence_is_a_protest_certificate_please_treat_manually;

    public static final String TASK_SUBJECT_HOME_VISIT_NO_PRICE = System.Label.Contract_service_home_visit_missing_or_no_price_for_this_service;
    public static final String TASK_SUBJECT_OFFICE_VISIT_NO_PRICE = System.Label.Contract_service_office_visit_missing_or_no_price_for_this_service;


    public static final String TASK_DESCRIPTION_NO_ACTIVE_CONTRACT_MC_OR_CR = System.Label.No_active_contract_for_MC_or_CR;
    public static final String TASK_DESCRIPTION_NO_ACTIVE_CONTRACT_MC = System.Label.No_active_contract_for_MC;
    public static final String TASK_ABSENCE_HAS_FREE_TEXT_COMMENT = System.Label.Absence_has_free_text_comment_please_check;


    public static final String TASK_SUBJECT_UNABLE_TO_EVALUATE_CRITERIA = System.Label.Unable_to_evaluate_criteria;
    public static final String TASK_DESCRIPTION_UNABLE_TO_EVALUATE_CRITERIA_DESCRIPTION = System.Label.Unable_to_evaluate_criteria_description;

    public static final String TASK_RT_MCM = Schema.SObjectType.Task.getRecordTypeInfosByDeveloperName().get(StaticConstants.TASK_RT_MCM_TASK).getRecordTypeId();
    public static final String TASK_TYPE_WARNING = 'Warning';
    public static final String TASK_PRIORITY_HIGH = 'High';
    public static final Integer TASK_DELAY = 1;

    public static final String TYPE_PROTEST_CERTIFICATE_OF_THE_SAME_DURATION = '8';
    public static final String TYPE_PROTEST_CERTIFICATE_OF_LONGER_DURATION_OR_OTHER_REASON = '9';
    public static final String EXIT_HOME_FORBIDDEN = '1';
    public static final String TYPE_1ST_WORK_INCAPACITY = '0';
    public static final String TYPE_EXTENSION = 'C';

    public static final String AVIS_PASSAGE_DEPOSE = 'Déposé dans la boîte aux lettres';
    public static final String AVIS_PASSAGE_REMIS_TIERS = 'Remis à un tiers';

    public static final String WORKTYPE_HOME_VISIT_WITHOUT_CONVOCATION = 'Home_Visit_without_Convocation';
    public static final String WORKTYPE_HOME_VISIT_WITH_POTENTIAL_CONVOCATION = 'Home_Visit_with_Potential_Convocation';
    public static final String WORKTYPE_DIRECT_CONVOCATION = 'Direct_Convocation';

    public static final String REASON_CLOSURE_ABSENCE_FULLY_IN_PAST = 'No need for MC - absence fully in past';

    public static final String STATUS_SA_CANCELED =  'Canceled';
    public static final String STATUS_RESULTS = 'Result to customer';
    public static final String STATUS_SA_NEW = 'None';
    public static final String STATUS_SA_SCHEDULED = 'Scheduled';

    public static final String INVOICING_STATUS_NO_INVOICING = 'No invoicing';
    public static final String STATUS_RESULT_TO_CUSTOMER = 'Result to customer';
    public static final String INVOICING_STATUS_INVOICE_TO_GENERATE = 'Invoice to generate';
    public static final String INVOICING_STATUS_INVOICE_GENERATED = 'Invoice generated';
    public static final String INVOICING_STATUS_ERROR = 'Error during Invoice generation';
    public static final String INVOICING_STATUS_MANUAL = 'Manual Process';
    public static final String INVOICING_STATUS_PREPAYMENT = 'Prepayment - no invoicing';



    /** MCM EXECUTING MC **/
    /** see more details with lucidchart: https://app.lucidchart.com/lucidchart/invitations/accept/d7f6f824-ad2e-4653-9b3f-984fb53398b1?viewport_loc=-856.7567986747271%2C-465.4170321868133%2C2877.302922057135%2C1381.5895641368093%2C0_0 **/
    /** and the documentation: https://securex.sharepoint.com/:w:/s/MedicalCheck2.0Public/ETarSTEszFVFuTgKh5f9WHsBtyQC7d5DpXNYsI4YPA8y9A?e=AZcT8a **/

    /** TECHNICAL CONTENTS **/

    /*********************************************************************************************************
    * @author        Novera - AMA
    * @date          2020 October 27
    * @description   This method get the ID of Queue for MCM Belgium an France group
    *                It's used to create a task and we need dispatch correctly the issue when an absence is flagged "on hold"
    * @RelatedUS     OAPPMEDCHECK-423
    * @RecordType    FR and BE
    *********************************************************************************************************/
    public static final Map<String,Id> MCMQueues{
        public get{
            if(MCMQueues == null){

                List<Group> queues = [SELECT Id, DeveloperName FROM Group WHERE Type = :StaticConstants.GROUP_QUEUE AND (DeveloperName = :QUEUE_MCM_GENERAL_BE OR DeveloperName = :QUEUE_MCM_GENERAL_FR)];
                if(queues.size() == 2){
                    MCMQueues = new Map<String, Id>();
                    for(Group queue : queues){
                        if(queue.DeveloperName == QUEUE_MCM_GENERAL_BE){
                            MCMQueues.put(COUNTRY_BE, queue.Id);
                        }
                        if(queue.DeveloperName == QUEUE_MCM_GENERAL_FR){
                            MCMQueues.put(COUNTRY_FR, queue.Id);
                        }
                    }
                }else{
                    throw new CustomException(System.Label.Error_Message+' Unable to find MCM Queues');
                }
            }
            return MCMQueues;
        }
        public set;
    }

    /*********************************************************************************************************
    * @author        Novera - AMA
    * @date          2020 October 27
    * @description   This method return FR or BE according to the RT
    * @RelatedUS     OAPPMEDCHECK-423
    * @RecordType    FR and BE
    * @return String (FR/BE)
    *********************************************************************************************************/
    public static String getCountryRelatedToRecordType(Id objId, Id recordTypeId){
        String country;
        if(objId!=null && objId.getSObjectType().getDescribe().getName() == StaticConstants.ABSENCE_REGISTRATION_NAME) {
            if (ABSENCE_REGISTRATION_RT_BE == recordTypeId) {
                country = COUNTRY_BE;
            }
            if (ABSENCE_REGISTRATION_RT_FR == recordTypeId) {
                country = COUNTRY_FR;
            }
        }

        return country;
    }

    /*********************************************************************************************************
    * @author        Novera - AMA
    * @date          2020 October 27
    * @description   This method create a Task formatted for MCM Queue
    * @RelatedUS     OAPPMEDCHECK-423
    * @RecordType    FR and BE
    * @return Task
    *********************************************************************************************************/
    public static Task generateTaskMCMQueue(String country, Id relatedToId, String subject, String comment, Integer delay){

        String MCMQueueId;
        if(country == COUNTRY_BE){
            MCMQueueId = MCMQueues.get(COUNTRY_BE);
        }
        if(country == COUNTRY_FR){
            MCMQueueId = MCMQueues.get(COUNTRY_FR);
        }
        Task tsk = new Task(OwnerId = MCMQueueId);
        tsk.WhatId = relatedToId;
        tsk.Subject = subject;
        tsk.Description = comment;
        tsk.ActivityDate = Date.today().addDays(delay);
        tsk.Priority = TASK_PRIORITY_HIGH;
        tsk.Type = TASK_TYPE_WARNING;
        tsk.RecordTypeId = TASK_RT_MCM;
        tsk.ReminderDateTime = Datetime.now().addHours(1);

        return tsk;
    }

    /*********************************************************************************************************
    * @author        Novera - AMA
    * @date          2020 October 27
    * @description   This method create a Task formatted for MCM Queue
    * @RelatedUS     OAPPMEDCHECK-423
    * @RecordType    FR and BE
    * @return Task
    *********************************************************************************************************/
    public static Task generateTaskMCMOwner(Id ownerId, String country, Id relatedToId, String subject, String comment, Integer delay){

        Task tsk = generateTaskMCMQueue(country, relatedToId, subject, comment, delay);
        tsk.OwnerId = ownerId;

        return tsk;
    }

    /*********************************************************************************************************
    * @author        Novera - AMA
    * @date          2021 March 08
    * @description   This method align the status between the UI status and the technical
    *                because we have a lot step to validate the absence registration
    * @RelatedUS     OAPPMEDCHECK-671
    * @RecordType    FR and BE
    *********************************************************************************************************/
    public static void AlignStatusFieldWithTechnical(List<Absence_Registration__c> recordList, Map<Id,Absence_Registration__c> oldAbsenceRegistrations){
        for(Absence_Registration__c abs : recordList) {

            if(abs.Status__c == STATUS_RECEIVED || abs.Status__c == STATUS_CANCELED){
                abs.Technical_Status__c = null;
            }
            if(abs.Status__c == READY_FOR_FOR_TREATMENT && (oldAbsenceRegistrations != null && oldAbsenceRegistrations.containsKey(abs.Id) && oldAbsenceRegistrations.get(abs.Id).Status__c == STATUS_RECEIVED)){
                abs.Technical_Status__c = READY_FOR_FOR_TREATMENT;
            }

            if(abs.Status__c == READY_FOR_FOR_TREATMENT) {

                if (abs.Technical_Status__c == READY_FOR_FOR_TREATMENT || abs.Technical_Status__c == RUN_PROCESS || abs.Technical_Status__c == STATUS_INITIATE_MC) {
                    abs.Status__c = READY_FOR_FOR_TREATMENT;
                }
                if (abs.Technical_Status__c == STATUS_RECEIVED) {
                    abs.Status__c = STATUS_RECEIVED;
                }
                if (abs.Technical_Status__c == STATUS_MC_INITIATED) {
                    abs.Status__c = STATUS_MC_INITIATED;
                }
                if (abs.Technical_Status__c == STATUS_TREATED_NO_MC) {
                    abs.Status__c = STATUS_TREATED_NO_MC;
                }
            }
            // reset reason when the on hold is unflagd
            if(abs.On_hold__c != true){
                abs.Reason_on_hold__c = null;
            }
        }
    }

    /*********************************************************************************************************
    * @author        Novera - AMA
    * @date          2020 October 27
    * @description   This fill accounts related to employee and others dependency for the calculation
    * @RelatedUS     OAPPMEDCHECK-417
    * @RecordType    FR and BE
    *********************************************************************************************************/
    public static void fillAccountOnAbsenceRegistration(List<Absence_Registration__c> recordList, Map<Id,Absence_Registration__c> oldAbsenceRegistrations)
    {

        Map<Id,Set<Absence_Registration__c>> absenceRegistrationsByEmp = new Map<Id,Set<Absence_Registration__c>>();
        for(Absence_Registration__c abs : recordList){

            if(String.isNotBlank(abs.Employee__c)){
                Set<Absence_Registration__c> absenceRegistrations = new Set<Absence_Registration__c>();
                if(absenceRegistrationsByEmp.containsKey(abs.Employee__c)){
                    absenceRegistrations = absenceRegistrationsByEmp.get(abs.Employee__c);
                }
                if(String.isBlank(abs.Id) && (String.isBlank(abs.Account__c) || String.isBlank(abs.Main_Account__c))) {
                    absenceRegistrations.add(abs);
                    absenceRegistrationsByEmp.put(abs.Employee__c, absenceRegistrations);
                }
            }
            if(abs.Request_Date_and_Time__c == null){
                abs.Request_Date_and_Time__c = Datetime.now();
            }
        }

        if(absenceRegistrationsByEmp.size() > 0){

            Map<Id, Employee__c> empById = new Map<Id, Employee__c>([SELECT Id, Account__r.RecordTypeId, Account__r.Specific_Contract__c, Account__r.Specific_Contract__r.Active__c, Account__r.Specific_Contract__r.Service_type__c, Account__r.Parent__r.RecordTypeId, Account__r.Invoicing_on_this_account__c, Account__r.Invoicing_Account__c, Account__r.Parent__c, Account__r.Parent__r.Invoicing_Account__c, Account__r.Parent__r.Exceptional_SLA__c, Account__c, Account__r.Exceptional_SLA__c, Account__r.Federation__c, Account__r.Federation_Membership__r.Id, Account__r.Federation_Membership__r.Federation__c, Account__r.Federation_Membership__r.Exceptional_SLA__c, Account__r.Federation_Membership__r.Federation_Membership__r.Id, Account__r.Federation_Membership__r.Federation_Membership__r.Federation__c, Account__r.Federation_Membership__r.Federation_Membership__r.Exceptional_SLA__c FROM Employee__c WHERE Id IN :absenceRegistrationsByEmp.keySet() AND Account__c != NULL]);

            for(Id empId : empById.keySet()){
                Employee__c emp = empById.get(empId);

                if(absenceRegistrationsByEmp.containsKey(empId)) {
                    Set<Absence_Registration__c> absenceRegistrations = absenceRegistrationsByEmp.get(empId);
                    for(Absence_Registration__c abs : absenceRegistrations){
                        // fill lookup account/main account
                        abs.Account__c = emp.Account__c;

                        // determine main account
                        if(emp.Account__r.RecordTypeId == AccountTriggerHandler.RT_DEPARTMENT)
                        {
                            if(emp.Account__c != null)
                            {
                                abs.Main_Account__c = emp.Account__r.Parent__c;

                                String[] serviceTypes = new List<String>();
                                if(emp.Account__r.Specific_Contract__r != null && String.isNotBlank(emp.Account__r.Specific_Contract__r.Service_type__c)){
                                    serviceTypes = emp.Account__r.Specific_Contract__r.Service_type__c.split(';');
                                }


                                if(emp.Account__r.Specific_Contract__c != null && (serviceTypes.contains(StaticConstants.TYPE_MEDICAL_CHECK_ILLNESS) || serviceTypes.contains(StaticConstants.TYPE_REGISTRATION_CERTIFICATES))){
                                //QLE leave error as it is in PROD if(emp.Account__r.Specific_Contract__c != null && (serviceTypes.contains(StaticConstants.TYPE_MEDICAL_CHECK_ILLNESS) || serviceTypes.contains(StaticConstants.TYPE_REGISTRATION_CERTIFICATES)) && emp.Account__r.Specific_Contract__r.Active__c == true){
                                    abs.Contract_Home__c = emp.Account__r.Specific_Contract__c;
                                }

                            }else
                            {
                                throw new CustomException(System.Label.Error_Message+' Department without Main Account');
                            }
                        }
                        else
                        {
                            abs.Main_Account__c = emp.Account__c;
                        }

                        // fill exceptional SLA
                        if(abs.Id == null && String.isBlank(abs.Exceptional_SLA_Department__c) && String.isNotBlank(emp.Account__r.Exceptional_SLA__c)){
                            abs.Exceptional_SLA_Department__c = emp.Account__r.Exceptional_SLA__c;
                            abs.Tech_Display_exceptional_SLA_warning__c = true ;
                        }
                        if(abs.Id == null && String.isBlank(abs.Exceptional_SLA_Main_Account__c) && emp.Account__r.Parent__c != null && String.isNotBlank(emp.Account__r.Parent__r.Exceptional_SLA__c)){
                            abs.Exceptional_SLA_Main_Account__c = emp.Account__r.Parent__r.Exceptional_SLA__c;
                            abs.Tech_Display_exceptional_SLA_warning__c = true ;

                        }
                    }
                }

            }
        }
    }

    /*********************************************************************************************************
    * @author        Novera - AMA
    * @date          2020 October 27
    * @description   This method fill the lookup Contract_Home__c on the absence registration with a contract active
    * @RelatedUS     OAPPMEDCHECK-182
    * @RecordType    FR and BE
    * @Step          READY_FOR_EXTRA_CHECKS
    * @return        void
    *********************************************************************************************************/
    public static void fillContract(List<Absence_Registration__c> recordList) {
        Map<Id,Id> contractHomesByAccountIds = new Map<Id,Id>();
        List<Absence_Registration__c> absenceRegistrations = new List<Absence_Registration__c>();
        for(Absence_Registration__c absenceRegistration : recordList){
            if(absenceRegistration.Contract_Home__c == null && absenceRegistration.Main_Account__c != null &&  absenceRegistration.Technical_Status__c == READY_FOR_EXTRA_CHECKS){
                contractHomesByAccountIds.put(absenceRegistration.Main_Account__c, null);
                absenceRegistrations.add(absenceRegistration);
            }
        }

        if(absenceRegistrations.size() > 0){
            Set<String> visitTypes = new Set<String>{
                    WORKTYPE_HOME_VISIT_WITHOUT_CONVOCATION,
                    WORKTYPE_DIRECT_CONVOCATION,
                    WORKTYPE_HOME_VISIT_WITH_POTENTIAL_CONVOCATION
            };

            // contract home
            Map<Id,Contract_Home__c> contracts = new Map<Id,Contract_Home__c>([SELECT Id, Account__c, Specific_Contract__c FROM Contract_Home__c WHERE Visit_type__c IN :visitTypes AND Service_type__c INCLUDES (:StaticConstants.TYPE_MEDICAL_CHECK_ILLNESS) AND Account__c IN :contractHomesByAccountIds.keySet() AND Active__c = TRUE AND RecordTypeId != :ContractHomeManager.mcmRtPricingId]);

            Set<Id> hasMultipleContracts = new Set<Id>();
            for(Contract_Home__c contractHome : contracts.values()){
                if(contractHome.Specific_Contract__c != true) {
                    if (contractHomesByAccountIds.containsKey(contractHome.Account__c) && contractHomesByAccountIds.get(contractHome.Account__c) != null) {
                        hasMultipleContracts.add(contractHome.Account__c);
                    }
                    contractHomesByAccountIds.put(contractHome.Account__c, contractHome.Id);
                }
            }
            for(Absence_Registration__c absenceRegistration : absenceRegistrations){

                Id contractId;
                Boolean multipleContracts = false;
                if(absenceRegistration.Contract_Home__c != null && contracts.containsKey(absenceRegistration.Contract_Home__c) && contracts.get(absenceRegistration.Contract_Home__c).Specific_Contract__c == true){
                    contractId = absenceRegistration.Contract_Home__c;
                }else {
                    if (contractHomesByAccountIds.get(absenceRegistration.Main_Account__c) != null) {
                        contractId = contractHomesByAccountIds.get(absenceRegistration.Main_Account__c);
                        if (hasMultipleContracts.contains(absenceRegistration.Main_Account__c)) {
                            multipleContracts = true;
                        }
                    }
                }
                if(contractId != null && !multipleContracts) {
                    absenceRegistration.Contract_Home__c = contractId;
                }else{
                    absenceRegistration.On_hold__c = true;
                    absenceRegistration.Reason_on_hold__c = 'No_contract_active_or_multiple_contract_active';
                }


            }

        }
    }
    /*********************************************************************************************************
    * @author        Novera - AMA
    * @date          2020 October 27
    * @description   This method fill the Absence extensions should have same 'start date disease' as first absence - xml
    * @RelatedUS     OAPPMEDCHECK-516
    * @RecordType    BE
    *********************************************************************************************************/
    public static void fillStartDateDisease(List<Absence_Registration__c> recordList) 
    {

        Map<Id,List<Absence_Registration__c>> absenceByEmployeeId = new Map<Id,List<Absence_Registration__c>>();
        for(Absence_Registration__c abs : recordList)
        {
            if(abs.Loaded_by_service_xml__c)
            {
                if(abs.Start_date__c != null && abs.Start_date_disease__c == null && abs.Type__c == TYPE_1ST_WORK_INCAPACITY){
                    abs.Start_date_disease__c = abs.Start_date__c;
                }
                if(abs.Type__c == TYPE_EXTENSION && abs.Start_date__c != null && abs.Employee__c != null && abs.Start_date_disease__c == null)
                {
                    if(absenceByEmployeeId.containsKey(abs.Employee__c)) 
                    {
                        List<Absence_Registration__c> test = absenceByEmployeeId.get(abs.Employee__c);
                        test.add(abs);
                        absenceByEmployeeId.put(abs.Employee__c, test);
                    }
                    else
                    {
                        absenceByEmployeeId.put(abs.Employee__c, new List<Absence_Registration__c>{abs});
                    }
                }
            }
        }

        if(absenceByEmployeeId.size() > 0)
        {
            String query = '';
            for(List<Absence_Registration__c> absenceRegistrations : absenceByEmployeeId.values()){
                for(Absence_Registration__c abs : absenceRegistrations)
                {
                    Datetime minDate = abs.Start_date__c.addDays(-2); //weekend
                    Datetime maxDate = abs.Start_date__c;
                    query += ' (Employee__c = \''+abs.Employee__c+'\' AND (End_date__c >= '+  minDate.format('yyyy-MM-dd') +' AND End_date__c <= '+maxDate.format('yyyy-MM-dd') + ')) OR';
                }
            }
            query = query.removeEndIgnoreCase('OR');

            List<Absence_Registration__c> oldAbsences = Database.query('SELECT Id, Start_date_disease__c, Employee__c, End_date__c FROM Absence_Registration__c WHERE '+query+' ORDER BY Start_date_disease__c ASC'); //record are inserted per "batch" in random order
            Map<Id,List<Absence_Registration__c>> oldAbsenceByEmployeeId = new Map<Id,List<Absence_Registration__c>>();
            for(Absence_Registration__c oldAbs: oldAbsences)
            {
                if(oldAbsenceByEmployeeId.containsKey(oldAbs.Employee__c))
                {
                    oldAbsenceByEmployeeId.get(oldAbs.Employee__c).add(oldAbs);
                }
                else
                {
                    oldAbsenceByEmployeeId.put(oldAbs.Employee__c, new List<Absence_Registration__c>{oldAbs});
                }
            }

            if(oldAbsenceByEmployeeId.size() > 0)
            {
                for(Id empId : oldAbsenceByEmployeeId.keySet())
                {
                    if(absenceByEmployeeId.containsKey(empId))
                    {
                        List<Absence_Registration__c> potentialNewOldAbsence = new List<Absence_Registration__c>();
                        List<Absence_Registration__c> potentialNewAbsence = new List<Absence_Registration__c>();
                        for(Absence_Registration__c abs : absenceByEmployeeId.get(empId))
                        {
                            List<Absence_Registration__c> oldRegistrations = oldAbsenceByEmployeeId.get(empId);
                            for(Absence_Registration__c oldAbs : oldRegistrations)
                            {
                                Datetime minDate = abs.Start_date__c.addDays(-2);
                                Datetime maxDate = abs.Start_date__c;
                                if(oldAbs.End_date__c >=  minDate && oldAbs.End_date__c <= maxDate)
                                {
                                    abs.Start_date_disease__c = oldAbs.Start_date_disease__c;
                                    potentialNewOldAbsence.add(abs);
                                }
                                else
                                {
                                    potentialNewAbsence.add(abs);
                                }
                            }
                        }
                        while(potentialNewOldAbsence.size() > 0 && potentialNewAbsence.size() > 0)
                        {
                            List<Absence_Registration__c> oldRegistrations = potentialNewOldAbsence;
                            List<Absence_Registration__c> absRegistrations = potentialNewAbsence;
                            potentialNewOldAbsence = new List<Absence_Registration__c>();
                            potentialNewAbsence = new List<Absence_Registration__c>();
                            for(Absence_Registration__c abs : absRegistrations)
                            {
                                for(Absence_Registration__c oldAbs :oldRegistrations)
                                {
                                    Datetime minDate = abs.Start_date__c.addDays(-2);
                                    Datetime maxDate = abs.Start_date__c;
                                    if(oldAbs.End_date__c >=  minDate && oldAbs.End_date__c <= maxDate)
                                    {
                                        abs.Start_date_disease__c = oldAbs.Start_date_disease__c;
                                        potentialNewOldAbsence.add(abs);
                                    }else
                                    {
                                        potentialNewAbsence.add(abs);
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }




    /** -- END -- TECHNICAL CONTENTS **/

    /** START FLOW EXECUTING MC **/

    /** STEP 1: RECEIVED **/
    /** The flow can start with 2 endpoints :
        * 1- Load by the web service "AbsenceRegistrationWebService" is used only by Belgium
        * 2- Load by the flow "Absence_Registration_FR" for France and  "Absence_Registration_BE" for Belgium
        * the calculation start when the Status__c is set to "Ready for Treatment")
    */

    /** STEP 2: READY_FOR_FOR_TREATMENT **/

    /*********************************************************************************************************
    * @author        Novera - AMA
    * @date          2020 October 27
    * @description   This method check if contract is active for MC
    * @RelatedUS     OAPPMEDCHECK-417
    * @Step          READY_FOR_FOR_TREATMENT
    * @NextStep      READY_FOR_EXTRA_CHECKS OR STATUS_TREATED_NO_MC
    * @RecordType    FR and BE
    *********************************************************************************************************/
    public static void contractIsActiveForMC(List<Absence_Registration__c> recordList){

        Set<Id> accountIds = new Set<Id>();
        List<Absence_Registration__c> absenceRegistrations = new List<Absence_Registration__c>();
        for(Absence_Registration__c absenceRegistration : recordList){
            if(absenceRegistration.On_hold__c != true && absenceRegistration.Technical_Status__c == READY_FOR_FOR_TREATMENT && absenceRegistration.Migrated__c == false) {
                absenceRegistrations.add(absenceRegistration);
                accountIds.add(absenceRegistration.Main_Account__c);
            }
        }

        if(accountIds.size() > 0) {
            Map<Id,Contract_Home__c> contractHomes = new Map<Id,Contract_Home__c>([SELECT Id, Service_type__c, Account__c, Specific_Contract__c FROM Contract_Home__c WHERE Active__c = TRUE AND Account__c IN :accountIds AND Service_type__c INCLUDES (:StaticConstants.TYPE_MEDICAL_CHECK_ILLNESS, :StaticConstants.TYPE_REGISTRATION_CERTIFICATES) AND RecordTypeId != :ContractHomeManager.mcmRtPricingId]);

            Set<Id> hasMCByAccountId = new Set<Id>();
            Set<Id> hasCRByAccountId = new Set<Id>();

            for (Contract_Home__c contract : contractHomes.values()) {
                if(contract.Specific_Contract__c == false) {
                    List<String> serviceTypes = new List<String>();
                    if(String.isNotBlank(contract.Service_type__c)){
                        serviceTypes = contract.Service_type__c.split(';');
                    }
                    Boolean hasMC = serviceTypes.contains(StaticConstants.TYPE_MEDICAL_CHECK_ILLNESS);
                    if (hasMC) {
                        hasMCByAccountId.add(contract.Account__c);
                    }
                    Boolean hasCR = serviceTypes.contains(StaticConstants.TYPE_REGISTRATION_CERTIFICATES);
                    if (hasCR) {
                        hasCRByAccountId.add(contract.Account__c);
                    }
                }
            }


            List<Task> tasks = new List<Task>();
            List<Absence_Registration__c> absenceRegistrationToUpdates = new List<Absence_Registration__c>();
            for (Absence_Registration__c abs : recordList) {


                Absence_Registration__c absenceRegistration = new Absence_Registration__c(Id = abs.Id);

                Boolean accountHasMC = false;
                Boolean accountHasCR = false;


                if(abs.Contract_Home__c != null && contractHomes.containsKey(abs.Contract_Home__c) && contractHomes.get(abs.Contract_Home__c).Specific_Contract__c == true){
                    List<String> serviceTypes = new List<String>();
                    if(String.isNotBlank(contractHomes.get(abs.Contract_Home__c).Service_type__c)){
                        serviceTypes = contractHomes.get(abs.Contract_Home__c).Service_type__c.split(';');
                    }
                    accountHasMC = serviceTypes.contains(StaticConstants.TYPE_MEDICAL_CHECK_ILLNESS);
                    accountHasCR = serviceTypes.contains(StaticConstants.TYPE_REGISTRATION_CERTIFICATES);
                }else{
                    if(hasMCByAccountId.contains(abs.Main_Account__c)){
                        accountHasMC = true;
                    }
                    if(hasCRByAccountId.contains(abs.Main_Account__c) ){
                        accountHasCR = true;
                    }
                }



                String status;
                if (!accountHasMC && !accountHasCR) {
                    // create task
                    String country = getCountryRelatedToRecordType(abs.Id, abs.RecordTypeId);
                    String description = TASK_DESCRIPTION_NO_ACTIVE_CONTRACT_MC;
                    if (country == COUNTRY_BE) {
                        description = TASK_DESCRIPTION_NO_ACTIVE_CONTRACT_MC_OR_CR;
                    }

                    tasks.add(generateTaskMCMQueue(country, abs.Id, TASK_SUBJECT_UNABLE_EVALUATE_MC, description, TASK_DELAY));
                    absenceRegistration.On_hold__c = true;
                    absenceRegistration.Reason_on_hold__c = 'Unable_to_evaluate_if_MC';
                } else {
                    if (accountHasMC || abs.Execute_MC__c == Execute_MC_YES) {
                        status = READY_FOR_EXTRA_CHECKS;
                    } else {
                        status = STATUS_TREATED_NO_MC;
                    }
                    absenceRegistration.Technical_Status__c = status;
                    absenceRegistration.Medical_Check_Illness__c = accountHasMC;
                    absenceRegistration.Certificate_Registration__c = accountHasCR;
                }

                absenceRegistrationToUpdates.add(absenceRegistration);
            }

            if (absenceRegistrationToUpdates.size() > 0) {
                update absenceRegistrationToUpdates;
            }

            if (tasks.size() > 0) {
                insert tasks;
            }
        }
    }


    /** STEP 3: READY_FOR_EXTRA_CHECKS **/

    /*********************************************************************************************************
    * @author        Novera - AMA
    * @date          2020 October 27
    * @description   This method check if absence can be automatically treat by the program
    * @RelatedUS     OAPPMEDCHECK-123
    * @Step          READY_FOR_EXTRA_CHECKS
    * @NextStep      RUN_PROCESS
    * @RecordType    FR and BE
    *********************************************************************************************************/
    public static void checkAbsenceIsValidToTreatment(List<Absence_Registration__c> recordList) {

        Set<Id> accountIds = new Set<Id>();
        Set<Id> invoiceAccountIds = new Set<Id>();
        Map<Id,Absence_Registration__c> absenceRegistrations = new Map<Id,Absence_Registration__c>();
        // filter on READY_FOR_EXTRA_CHECKS
        for(Absence_Registration__c abs : recordList){

            if(abs.Technical_Status__c == READY_FOR_EXTRA_CHECKS && abs.On_hold__c != true && abs.Migrated__c == false){

                accountIds.add(abs.Main_Account__c);
                invoiceAccountIds.add(abs.Invoicing_Account__c);
                absenceRegistrations.put(abs.Id,abs);
            }
        }

        // run checks
        if(accountIds.size() > 0){

            List<Task> tasks = new List<Task>();
            List<Absence_Registration__c> absenceRegistrationToUpdates = new List<Absence_Registration__c>();


            // check if invoicing account blocked on contract or account invoicing
            Map<Id,Contract_Home__c> disabledContractHomes = new Map<Id,Contract_Home__c>([SELECT Id, Account__c, Blocked_For_Invoicing__c, Blocked_for_services__c, Specific_Contract__c FROM Contract_Home__c WHERE Account__c IN :accountIds AND Service_type__c INCLUDES (:StaticConstants.TYPE_MEDICAL_CHECK_ILLNESS, :StaticConstants.TYPE_REGISTRATION_CERTIFICATES) AND (Blocked_For_Invoicing__c = TRUE OR Blocked_for_services__c = TRUE) AND RecordTypeId != :ContractHomeManager.mcmRtPricingId AND Active__c = TRUE]);
            Map<Id,Contract_Home__c> contractHomeDisabledByAccountId = new Map<Id,Contract_Home__c>();
            for(Contract_Home__c disabledContractHome : disabledContractHomes.values()){
                if(disabledContractHome.Specific_Contract__c != true) {
                    contractHomeDisabledByAccountId.put(disabledContractHome.Account__c, disabledContractHome);
                }
            }

            List<Account> disabledAccounts = [SELECT Id, Parent__c FROM Account WHERE Id IN :invoiceAccountIds AND Blocked_for_services__c = TRUE];
            Set<Id> disabledAccountByParentIds = new Set<Id>();
            for(Account acc : disabledAccounts){
                disabledAccountByParentIds.add(acc.Id);
            }


            for(Id absId : absenceRegistrations.keySet()) {
                Absence_Registration__c abs = absenceRegistrations.get(absId);


                Boolean contractHomeIsDisabled = contractHomeDisabledByAccountId.containsKey(abs.Main_Account__c);
                Contract_Home__c contractHomeDisabled;
                if(contractHomeIsDisabled){
                    contractHomeDisabled = contractHomeDisabledByAccountId.get(abs.Main_Account__c);
                }
                if(abs.Contract_Home__c != null && disabledContractHomes.containsKey(abs.Contract_Home__c) && disabledContractHomes.get(abs.Contract_Home__c).Specific_Contract__c == true){
                    contractHomeIsDisabled = disabledContractHomes.containsKey(abs.Contract_Home__c);
                    if(contractHomeIsDisabled) {
                        contractHomeDisabled = disabledContractHomes.get(abs.Contract_Home__c);
                    }
                }

                if(contractHomeIsDisabled || disabledAccountByParentIds.contains(abs.Invoicing_Account__c)) {
                    String country = getCountryRelatedToRecordType(abs.Id, abs.RecordTypeId);
                    String subject = '';
                    String reasonOnHold = '';
                    String comment = '';
                    if(contractHomeIsDisabled) {
                        if (contractHomeDisabled.Blocked_For_Invoicing__c) {
                            subject = TASK_SUBJECT_BLOCKED_BY_INVOICING;
                            reasonOnHold = 'Blocked_by_invoicing';
                            comment = TASK_DESCRIPTION_BLOCKED_BY_INVOICING;
                            tasks.add(generateTaskMCMOwner(abs.OwnerId, country, abs.Id, subject, comment, TASK_DELAY));
                        }
                        if (contractHomeDisabled.Blocked_for_services__c) {
                            subject = TASK_SUBJECT_BLOCKED_BY_SERVICES;
                            reasonOnHold = 'Blocked_by_services';
                            comment = TASK_SUBJECT_BLOCKED_BY_SERVICES_DESCRIPTION;
                            tasks.add(generateTaskMCMOwner(abs.OwnerId, country, abs.Id, subject, comment, TASK_DELAY));
                        }
                    }else{
                        subject = TASK_SUBJECT_BLOCKED_BY_SERVICES;
                        reasonOnHold = 'Blocked_by_services';
                        tasks.add(generateTaskMCMOwner(abs.OwnerId,country, abs.Id, subject, comment, TASK_DELAY));
                    }


                    Absence_Registration__c absenceRegistration = new Absence_Registration__c(Id = abs.Id, On_hold__c = true, Reason_on_hold__c = reasonOnHold);
                    absenceRegistrationToUpdates.add(absenceRegistration);
                    absenceRegistrations.remove(absId); // remove for next eval
                }
            }



            // check if account has contract with pack
            Map<Id,Contract_Home__c> contractPacks = new Map<Id,Contract_Home__c>([SELECT Id, Account__c, Specific_Contract__c, (SELECT Id, Pack_saldo__c, Ignore_Pack_Saldo_is_empty__c FROM Contractual_Service_Line_Items__r WHERE Service__r.Service_Category__c = 'Pack' AND Pack_saldo__c != NULL ORDER BY Ignore_Pack_Saldo_is_empty__c DESC) FROM Contract_Home__c WHERE Account__c IN :accountIds  AND Active__c = TRUE AND RecordTypeId != :ContractHomeManager.mcmRtPricingId]);
            Map<Id,Integer> remainingByAccount = new Map<Id,Integer>();
            Map<Id,Boolean> ignoreSaldoByAccount = new Map<Id,Boolean>();

            Map<Id,List<Contractual_Service_Line_Item__c>> cliByAccount = new Map<Id,List<Contractual_Service_Line_Item__c>>();
            List<Contractual_Service_Line_Item__c> cliToUpdate = new List<Contractual_Service_Line_Item__c>();

            for(Contract_Home__c contractHome: contractPacks.values())
            {
                if(contractHome.Contractual_Service_Line_Items__r != null && contractHome.Contractual_Service_Line_Items__r.size() > 0 && contractHome.Specific_Contract__c != true)
                {
                    for(Contractual_Service_Line_Item__c cli : contractHome.Contractual_Service_Line_Items__r)
                    {

                        ignoreSaldoByAccount.put(contractHome.Account__c, cli.Ignore_Pack_Saldo_is_empty__c);
                        Integer remainings = (Integer) cli.Pack_saldo__c;
                        if (remainingByAccount.containsKey(contractHome.Account__c))
                        {
                            remainings += remainingByAccount.get(contractHome.Account__c);
                        }
                        remainingByAccount.put(contractHome.Account__c, remainings);
                    }

                    if(!cliByAccount.containsKey(contractHome.Account__c))
                    {
                        cliByAccount.put(contractHome.Account__c, contractHome.Contractual_Service_Line_Items__r);
                    }else
                    {
                        List<Contractual_Service_Line_Item__c> clis = cliByAccount.get(contractHome.Account__c);
                        clis.addAll(contractHome.Contractual_Service_Line_Items__r);
                        cliByAccount.put(contractHome.Account__c, clis);
                    }
                }

                /*else{
                    contractPacks.remove(contractHome.Id); // remove when doesn't have contract
                }*/
            }
            // check if the pack is not empty
            Set<Id> isPack = new Set<Id>();
            Set<Id> accountIdToIgnorePack = new Set<Id>();
            Set<Id> specificContractIdToIgnorePack = new Set<Id>();


            for(Id absId : absenceRegistrations.keySet())
            {
                Absence_Registration__c abs = absenceRegistrations.get(absId);
                Boolean contractHasPack;
                Boolean ignoreSaldo;
                Integer remainingPack;
                if(abs.Contract_Home__c != null  && contractPacks.containsKey(abs.Contract_Home__c) && contractPacks.get(abs.Contract_Home__c).Specific_Contract__c == true)
                {
                    Integer remainings;
                    Contract_Home__c contractHome = contractPacks.get(abs.Contract_Home__c);
                    isPack.add(abs.Id);
                    if(contractHome != null && contractHome.Contractual_Service_Line_Items__r != null && contractHome.Contractual_Service_Line_Items__r.size() > 0)
                    {
                        remainings = 0;
                        for(Contractual_Service_Line_Item__c cli : contractHome.Contractual_Service_Line_Items__r){
                            contractHasPack = true;
                            ignoreSaldo = cli.Ignore_Pack_Saldo_is_empty__c;

                            remainings += (Integer) cli.Pack_saldo__c;
                        }
                    }
                    if(contractHasPack == true && (remainings == null || remainings <= 0) && ignoreSaldo == false && specificContractIdToIgnorePack.contains(contractHome.Id) == false)
                    {
                        specificContractIdToIgnorePack.add(contractHome.Id);
                        String country = getCountryRelatedToRecordType(abs.Id, abs.RecordTypeId);
                        tasks.add(generateTaskMCMOwner(abs.OwnerId, country, abs.Id, TASK_SUBJECT_BLOCKED_BY_PACK_EMPTY, TASK_DESCRIPTION_BLOCKED_BY_PACK_EMPTY, TASK_DELAY));
                        Absence_Registration__c absenceRegistration = new Absence_Registration__c(Id = abs.Id, Is_contract_pack__c = true);
                        absenceRegistration.On_hold__c = true;
                        absenceRegistration.Reason_on_hold__c = 'Blocked_by_pack_empty';
                        absenceRegistrations.remove(absId);
                        absenceRegistrationToUpdates.add(absenceRegistration);

                        for (Contractual_Service_Line_Item__c cli : contractHome.Contractual_Service_Line_Items__r) {
                            cli.Ignore_Pack_Saldo_is_empty__c = true;
                            cliToUpdate.add(cli);
                        }
                    }
                }
                else
                {
                    contractHasPack = remainingByAccount.containsKey(abs.Main_Account__c);
                    ignoreSaldo = ignoreSaldoByAccount.get(abs.Main_Account__c);
                    remainingPack = remainingByAccount.get(abs.Main_Account__c);
                    if(contractHasPack)
                    {
                        isPack.add(abs.Id);
                        if((remainingPack == null || remainingByAccount.get(abs.Main_Account__c) <= 0) && ignoreSaldo == false)
                        {
                            if(!accountIdToIgnorePack.contains(abs.Main_Account__c)) {
                                String country = getCountryRelatedToRecordType(abs.Id, abs.RecordTypeId);
                                tasks.add(generateTaskMCMOwner(abs.OwnerId, country, abs.Id, TASK_SUBJECT_BLOCKED_BY_PACK_EMPTY,TASK_DESCRIPTION_BLOCKED_BY_PACK_EMPTY, TASK_DELAY));
                                Absence_Registration__c absenceRegistration = new Absence_Registration__c(Id = abs.Id, Is_contract_pack__c = true);
                                absenceRegistration.On_hold__c = true;
                                absenceRegistration.Reason_on_hold__c = 'Blocked_by_pack_empty';

                                absenceRegistrations.remove(absId);
                                absenceRegistrationToUpdates.add(absenceRegistration);


                                accountIdToIgnorePack.add(abs.Main_Account__c);

                                for(Contractual_Service_Line_Item__c cli : cliByAccount.get(abs.Main_Account__c)){
                                    cli.Ignore_Pack_Saldo_is_empty__c = true;
                                    cliToUpdate.add(cli);
                                }
                            }
                        }
                    }
                }
            }
            // when the validation pack is checked
            if(cliToUpdate.size() > 0){
                update cliToUpdate;
            }

            TimeZone tz = TimeZone.getTimeZone('Europe/Paris');
            Datetime now = Datetime.now();
            now = now.addSeconds((tz.getOffset(now)/1000));
            Datetime midday = Datetime.newInstance(now.year(), now.month(), now.day(), 12, 0, 0);
            midday = midday.addSeconds((tz.getOffset(midday)/1000));
            Boolean halfDay = false;
            if(now > midday){
                halfDay = true;
            }



            // extras checks : prostest, additional info, execute with absence in the past

            for(Id absId : absenceRegistrations.keySet())
            {

                Absence_Registration__c abs = absenceRegistrations.get(absId);

                String country = getCountryRelatedToRecordType(abs.Id, abs.RecordTypeId);
                Absence_Registration__c absenceRegistration = new Absence_Registration__c(Id=abs.Id, On_hold__c=true);
                absenceRegistration.Is_contract_pack__c = isPack.contains(abs.Id);


                Date endDate = abs.Certificate_End_Date__c == null ? abs.End_date__c : abs.Certificate_End_Date__c;

                if((abs.Type__c == TYPE_PROTEST_CERTIFICATE_OF_THE_SAME_DURATION || abs.Type__c == TYPE_PROTEST_CERTIFICATE_OF_LONGER_DURATION_OR_OTHER_REASON)  && abs.Ignore_Protest_Certificate__c == false && abs.Loaded_by_service_xml__c == true)
                {
                    String subject = TASK_SUBJECT_PROTEST_CERTIFICATE;

                    if(abs.Type__c == TYPE_PROTEST_CERTIFICATE_OF_LONGER_DURATION_OR_OTHER_REASON && abs.Loaded_by_service_xml__c == true){
                        subject = TASK_SUBJECT_PROTEST_CERTIFICATE_OTHER_REASON;
                    }

                    tasks.add(generateTaskMCMQueue(country, abs.Id, subject, TASK_COMMENT_ABSENCE_IS_A_PROTEST_MANUALLY, TASK_DELAY));
                    absenceRegistration.Reason_on_hold__c = 'Protest_certificate';
                }
                else if(String.isNotBlank(abs.Additional_information__c) && abs.Ignore_Additional_Information__c == false && abs.Loaded_by_service_xml__c == true){
                    tasks.add(generateTaskMCMQueue(country, abs.Id, TASK_SUBJECT_ADDITIONAL_INFORMATION_CERTIFICATE, TASK_ABSENCE_HAS_FREE_TEXT_COMMENT, TASK_DELAY));
                    absenceRegistration.Reason_on_hold__c = 'Additional_information_on_certificate';
                }
                else if((endDate < Date.today() || (halfDay == true && endDate == Date.today()) && country == COUNTRY_BE))
                {
                    if(abs.Execute_MC__c == Execute_MC_YES){
                        tasks.add(generateTaskMCMOwner(abs.OwnerId, country, abs.Id, TASK_SUBJECT_EXECUTE_CONTROL_WITH_ABSENCE_IN_PAST, TASK_SUBJECT_EXECUTE_CONTROL_WITH_ABSENCE_IN_PAST_DESCRIPTION, TASK_DELAY));
                        /* absenceRegistration.Status__c = STATUS_TREATED_NO_MC;
                         absenceRegistration.Reason_closure__c = REASON_CLOSURE_ABSENCE_FULLY_IN_PAST;
                         absenceRegistration.Reason_on_hold__c = 'Execute_control_with_absence_in_past';*/
                    }else{
                        absenceRegistration.Reason_closure__c = 'No need for MC - absence fully in past';
                        absenceRegistration.On_hold__c = false;
                        absenceRegistration.Status__c = STATUS_TREATED_NO_MC;
                        absenceRegistration.Technical_Status__c = STATUS_TREATED_NO_MC;
                    }

                }
                else
                {
                    // if everything is ok
                    absenceRegistration = new Absence_Registration__c(Id=abs.Id, Technical_Status__c = RUN_PROCESS);
                    System.debug('QLE isPack.contains(abs.Id) ' + isPack.contains(abs.Id));
                    absenceRegistration.Is_contract_pack__c = isPack.contains(abs.Id);
                }
                absenceRegistrations.remove(absId);
                System.debug('QLE absenceRegistration.Is_contract_pack__c ' + absenceRegistration.Is_contract_pack__c); 
                absenceRegistrationToUpdates.add(absenceRegistration);
            }



            if(absenceRegistrationToUpdates.size() > 0){
                update absenceRegistrationToUpdates;
            }

            if(tasks.size() > 0){
                insert tasks;
            }


        }

    }

    /** STEP 4: STATUS_INITIATE_MC ONLY FR **/

    /*********************************************************************************************************
    * @author        Novera - AMA
    * @date          2020 October 27
    * @description   This method check fill the visit type if is empty
    * @RelatedUS     OAPPMEDCHECK-182
    * @Step          RUN_PROCESS
    * @NextStep      STATUS_INITIATE_MC
    * @RecordType    FR
    *********************************************************************************************************/
    public static void checkVisitTypeMCFR(List<Absence_Registration__c> recordList) {

        System.debug('QLE checkVisitTypeMCFR ' + recordList); 
        Set<Id> contractHomesIds = new Set<Id>();
        List<Absence_Registration__c> absenceRegistrations = new List<Absence_Registration__c>();
        List<Absence_Registration__c> absenceRegistrationToUpdates = new List<Absence_Registration__c>();

        for(Absence_Registration__c absenceRegistration : recordList){

            if(String.isBlank(absenceRegistration.Reason_closure__c) && absenceRegistration.On_hold__c != true && absenceRegistration.Technical_Status__c == RUN_PROCESS && absenceRegistration.Migrated__c == false ){
                if(absenceRegistration.Contract_Home__c != null) {
                    absenceRegistrations.add(absenceRegistration);
                    contractHomesIds.add(absenceRegistration.Contract_Home__c);
                }else{
                    throw new CustomException(System.Label.Error_Message+' no contract filled');
                }
            }
        }

        if(absenceRegistrations.size() > 0){

            List<Task> tasks = new List<Task>();
            // contract home
            Map<Id,Contract_Home__c> contracts = new Map<Id,Contract_Home__c>([SELECT Id, Visit_type__c, (SELECT Id, Service__r.Visit_Type__c FROM Contractual_Service_Line_Items__r WHERE Service__r.Service_category__c = 'Basic fee per service' AND Service__r.Visit_Type__c != NULL AND Price_Rate_1__c != NULL AND Price_Rate_1__c > 0) FROM Contract_Home__c WHERE Id IN :contractHomesIds AND Active__c = TRUE AND RecordTypeId != :ContractHomeManager.mcmRtPricingId ]);

            for(Absence_Registration__c absenceRegistration : absenceRegistrations) {
                Contract_Home__c contract = contracts.get(absenceRegistration.Contract_Home__c);

                Absence_Registration__c absToUpdate = new Absence_Registration__c(Id=absenceRegistration.Id, Technical_Status__c = STATUS_INITIATE_MC);

                if(String.isBlank(absenceRegistration.Visit_Type__c)) {
                    absToUpdate.Visit_Type__c = contract.Visit_type__c;
                }

                Boolean hasHomeVisit = false;
                Boolean hasDirectConvocation = false;
                if(contract.Contractual_Service_Line_Items__r != null){
                    for(Contractual_Service_Line_Item__c cli : contract.Contractual_Service_Line_Items__r)
                    {
                        if(cli.Service__r.Visit_Type__c == 'Home visit'){
                            hasHomeVisit = true;
                        }
                        if(cli.Service__r.Visit_Type__c == 'Convocation'){
                            hasDirectConvocation = true;
                        }
                    }
                }

                String subject;
                if(contract.Visit_type__c == WORKTYPE_DIRECT_CONVOCATION && hasDirectConvocation != true){
                    absToUpdate.Reason_on_hold__c = 'Contract_service_office_visit_missing_or_no_price_for_this_service';
                    subject = TASK_SUBJECT_OFFICE_VISIT_NO_PRICE;
                }
                if((contract.Visit_type__c == WORKTYPE_HOME_VISIT_WITH_POTENTIAL_CONVOCATION || contract.Visit_type__c == WORKTYPE_HOME_VISIT_WITHOUT_CONVOCATION) && hasHomeVisit != true){
                    subject = TASK_SUBJECT_HOME_VISIT_NO_PRICE;
                    absToUpdate.Reason_on_hold__c = 'Contract_service_home_visit_missing_or_no_price_for_this_service';
                }
                if(String.isNotBlank(subject)) {
                    absToUpdate.On_hold__c = true;
                    absToUpdate.Technical_Status__c = RUN_PROCESS;
                    String country = getCountryRelatedToRecordType(absenceRegistration.Id, absenceRegistration.RecordTypeId);
                    tasks.add(generateTaskMCMQueue(country, absenceRegistration.Id, subject, null, TASK_DELAY));
                }
                
                absenceRegistrationToUpdates.add(absToUpdate);
            }


            if(tasks.size() > 0){
                insert tasks;
            }

        }

        if(absenceRegistrationToUpdates.size() > 0){
            update absenceRegistrationToUpdates;
        }
    }

    /** STEP 3 bis: SPECIAL BELGIUM **/

    /*********************************************************************************************************
    * @author        Novera - AMA
    * @date          2021 Feb 08
    * @description   This method is used only for BE, it calculate custom criteria provided by account and others rules
    * @RelatedUS     OAPPMEDCHECK-98
    * @Step          RUN_PROCESS
    * @NextStep      STATUS_INITIATE_MC
    * @RecordType    BE
    *********************************************************************************************************/
    public static void checkCustomCriteria(List<Absence_Registration__c> recordList){

        // Set<Id> absenceRegistrationIds = new Set<Id>();
        Map<Id,Absence_Registration__c> absenceRegistrationIds = new Map<Id,Absence_Registration__c>();
        Set<Id> employeeIds = new Set<Id>();

        for(Absence_Registration__c ar : recordList){
            if(ar.Technical_Status__c == RUN_PROCESS && ar.On_hold__c != true && String.isBlank(ar.Reason_closure__c) && ar.Custom_criteria_checked__c != true && ar.Migrated__c == false || (ar.On_hold__c == true && ar.Simulation__c == true && String.isBlank(ar.Reason_closure__c) && ar.Custom_criteria_checked__c != true && ar.Reason_on_hold__c != 'Unable_to_evaluate_custom_criteria')) {
                absenceRegistrationIds.put(ar.Id, ar);
                employeeIds.add(ar.Employee__c);
            }
        }


        if(absenceRegistrationIds.size() > 0){

            // get extra check for employee (if the employee must be always/never check)
            List<Employee_Medical_Check_Criteria__c> employeeExtraChecks = [SELECT Id, Employee__c, Execution__c FROM Employee_Medical_Check_Criteria__c WHERE Employee__c IN: employeeIds AND Start_Date__c <= TODAY AND End_Date__c >= TODAY];
            Map<Id,String> executionByEmployeeId = new Map<Id,String>();
            for(Employee_Medical_Check_Criteria__c empExtraCheck : employeeExtraChecks){
                executionByEmployeeId.put(empExtraCheck.Employee__c, empExtraCheck.Execution__c);
            }

            List<Absence_Registration__c> absenceRegistrations = [SELECT Id, Employee__c, Execute_MC__c, Account__r.Flow_Criteria_Absence__c, Main_Account__r.Flow_Criteria_Absence__c FROM Absence_Registration__c WHERE Id =: absenceRegistrationIds.keySet()];


            List<Absence_Registration__c> absenceRegistrationsToUpdate = new List<Absence_Registration__c>();

            Map<String,List<Absence_Registration__c>> absenceRegistrationsByFlowNames = new Map<String,List<Absence_Registration__c>>();
            Map<Id,String> mainFlowByAccount = new Map<Id,String>();

            for(Absence_Registration__c abs : absenceRegistrations){

                String flowDep;
                String flowMain;

                if(String.isNotBlank(abs.Account__r.Flow_Criteria_Absence__c)){
                    flowDep = abs.Account__r.Flow_Criteria_Absence__c;
                }
                if(String.isNotBlank(abs.Account__r.Flow_Criteria_Absence__c)){
                    flowMain = abs.Main_Account__r.Flow_Criteria_Absence__c;
                }

                String flowName;
                if(flowDep != null){
                    flowName = flowDep;
                }else if (flowMain != null){
                    flowName = flowMain;
                }

                if(flowDep != null && flowMain != null){
                    mainFlowByAccount.put(abs.Account__c, flowMain);
                }


                Absence_Registration__c absToUpdate = new Absence_Registration__c(Id=abs.Id);
                // check if MC is explicitly specified
                if(String.isNotBlank(abs.Execute_MC__c)){
                    if(abs.Execute_MC__c == Execute_MC_YES){
                        absToUpdate.Reason_closure__c = 'MC requested by employer on absence registration';
                        absToUpdate.Technical_Status__c = STATUS_INITIATE_MC; 
                    }else if(abs.Execute_MC__c == Execute_MC_NO){
                        absToUpdate.Reason_closure__c = 'Exempt from MC by employer on absence registration';
                        absToUpdate.Technical_Status__c = STATUS_TREATED_NO_MC; 
                    }
                }

                // check if the employee of the absence has extra check
                if(executionByEmployeeId.containsKey(abs.Employee__c)){

                    String execution = executionByEmployeeId.get(abs.Employee__c);
                    if(execution == 'Never'){
                        absToUpdate.Reason_closure__c = 'Exempt from MC by employer on employee level';
                        absToUpdate.Execute_MC__c = Execute_MC_NO;
                        absToUpdate.Technical_Status__c = STATUS_TREATED_NO_MC; 
                    }else if(execution == 'Always'){
                        absToUpdate.Reason_closure__c = 'MC requested by employer on employee level';
                        absToUpdate.Execute_MC__c = Execute_MC_YES;
                        absToUpdate.Technical_Status__c = STATUS_INITIATE_MC; 
                    }
                }
                System.debug('debugAliTest');
                System.debug(absToUpdate.Reason_closure__c);
                System.debug(flowName);
                System.debug(executionByEmployeeId.containsKey(abs.Employee__c));

                // check if Employer has criteria
                if(String.isBlank(absToUpdate.Reason_closure__c) || (flowName != null && executionByEmployeeId.containsKey(abs.Employee__c)) ){


                    System.debug(flowName != null);
                    if(flowName != null){
                        List<Absence_Registration__c> absenceRegistrationsToProcess = new List<Absence_Registration__c>{absenceRegistrationIds.get(abs.Id)};
                        if(absenceRegistrationsByFlowNames.containsKey(flowName)){
                            absenceRegistrationsToProcess.addAll(absenceRegistrationsByFlowNames.get(flowName));
                        }
                        absenceRegistrationsByFlowNames.put(flowName, absenceRegistrationsToProcess);

                    }else{
                        absToUpdate.Reason_closure__c =  'No criteria fit to execute MC';
                        absToUpdate.Custom_criteria_checked__c = true;
                        absToUpdate.Technical_Status__c = STATUS_TREATED_NO_MC; 
                        absenceRegistrationsToUpdate.add(absToUpdate);
                    }

                }else
                {
                    absToUpdate.Custom_criteria_checked__c = true;
                    absenceRegistrationsToUpdate.add(absToUpdate);
                }



            }

            if(absenceRegistrationsToUpdate.size() > 0){
                update absenceRegistrationsToUpdate;
            }

            System.debug('QLE absenceRegistrationsByFlowNames ' + absenceRegistrationsByFlowNames); 
            System.debug('QLE mainFlowByAccount ' + mainFlowByAccount); 
            if(absenceRegistrationsByFlowNames.size() > 0) {
                System.enqueueJob(new CustomCriteriaMCQueueable(absenceRegistrationsByFlowNames, mainFlowByAccount));
            }

        }
    }

    /** STEP 4: STATUS_INITIATE_MC ONLY BE **/
    /*********************************************************************************************************
    * @author        Novera - AMA
    * @date          2020 October 27
    * @description   This method check if is a home visit or convocation
    * @RelatedUS     OAPPMEDCHECK-182
    * @Step          RUN_PROCESS
    * @NextStep      STATUS_INITIATE_MC OR STATUS_TREATED_NO_MC
    * @RecordType    BE
    *********************************************************************************************************/
    public static void checkVisitTypeMCBE(List<Absence_Registration__c> recordList) {

        Set<Id> contractHomesIds = new Set<Id>();
        Set<Id> accountIds = new Set<Id>();
        List<Absence_Registration__c> absenceRegistrations = new List<Absence_Registration__c>();
        List<Absence_Registration__c> absenceRegistrationToUpdates = new List<Absence_Registration__c>();

        for(Absence_Registration__c absenceRegistration : recordList){
            
            if(String.isBlank(absenceRegistration.Reason_closure__c) && absenceRegistration.On_hold__c != true && absenceRegistration.Technical_Status__c == RUN_PROCESS && absenceRegistration.Custom_criteria_checked__c == true && absenceRegistration.Migrated__c == false){
                if(absenceRegistration.Contract_Home__c != null) {
                    absenceRegistrations.add(absenceRegistration);
                    contractHomesIds.add(absenceRegistration.Contract_Home__c);
                    if (String.isNotBlank(absenceRegistration.Main_Account__c)) {
                        accountIds.add(absenceRegistration.Main_Account__c);
                    }
                }else {
                    throw new CustomException(System.Label.Error_Message+' no contract filled');
                }
            }
        }

        if(absenceRegistrations.size() > 0){

            List<Task> tasks = new List<Task>();

            // contract home
            Map<Id,Contract_Home__c> contracts = new Map<Id,Contract_Home__c>([SELECT Id, Visit_type__c, (SELECT Id FROM Contractual_Service_Line_Items__r WHERE Service__r.Service_category__c = 'Basic fee per service' AND Service__r.Visit_Type__c != NULL AND Price_Rate_1__c != NULL AND Price_Rate_1__c > 0) FROM Contract_Home__c WHERE Id IN :contractHomesIds AND Active__c = TRUE AND RecordTypeId != :ContractHomeManager.mcmRtPricingId]);
            Map<Id, Account> accountsByIds = new Map<Id, Account>([SELECT Id, RecordType.Name, Direct_Convocation__c, No_outside__c FROM Account WHERE Id IN:accountIds]);

            for(Absence_Registration__c absenceRegistration : absenceRegistrations) {

                // check
                Date startDate = absenceRegistration.Certificate_Start_Date__c == null ? absenceRegistration.Start_date__c : absenceRegistration.Certificate_Start_Date__c;
                Date endDate = absenceRegistration.Certificate_End_Date__c == null ? absenceRegistration.End_date__c : absenceRegistration.Certificate_End_Date__c;

                Absence_Registration__c absToUpdate = new Absence_Registration__c(Id=absenceRegistration.Id, Technical_Status__c = STATUS_INITIATE_MC);

                if(
                        absenceRegistration.Loaded_by_service_xml__c == true &&
                                startDate < Date.today() && endDate == null && absenceRegistration.Id != null
                        ){
                    absToUpdate.On_hold__c = true;
                    tasks.add(generateTaskMCMQueue(COUNTRY_BE, absenceRegistration.Id, TASK_SUBJECT_EMPLOYEE_MIGHT_BE_BACK_TO_WORK, null, TASK_DELAY));
                    absToUpdate.Reason_on_hold__c = 'Employee_might_be_back_to_work';
                }else {
                    absToUpdate.Reason_closure__c = 'Criteria decided to execute MC';

                    Contract_Home__c contract = contracts.get(absenceRegistration.Contract_Home__c);


                    if(contract.Contractual_Service_Line_Items__r == null || contract.Contractual_Service_Line_Items__r.size() <= 0){

                        absToUpdate.On_hold__c = true;
                        String subject;
                        if(contract.Visit_type__c == WORKTYPE_DIRECT_CONVOCATION){
                            subject = TASK_SUBJECT_HOME_VISIT_NO_PRICE;
                            absToUpdate.Reason_on_hold__c = 'Contract_service_home_visit_missing_or_no_price_for_this_service';
                        }else{
                            subject = TASK_SUBJECT_OFFICE_VISIT_NO_PRICE;
                            absToUpdate.Reason_on_hold__c = 'Contract_service_office_visit_missing_or_no_price_for_this_service';
                        }

                        String country = getCountryRelatedToRecordType(absenceRegistration.Id, absenceRegistration.RecordTypeId);
                        tasks.add(generateTaskMCMQueue(country, absenceRegistration.Id, subject, null, TASK_DELAY));


                    }else{



                        Boolean directConvocation = false;
                        Boolean outsideAllowed = false;
                        // check if absence is linked with department
                        if(absenceRegistration.Main_Account__c != null){
                            directConvocation = accountsByIds.get(absenceRegistration.Main_Account__c).Direct_Convocation__c;
                            outsideAllowed = accountsByIds.get(absenceRegistration.Main_Account__c).No_outside__c;
                        }else{
                            outsideAllowed = accountsByIds.get(absenceRegistration.Account__c).No_outside__c;
                        }

                        if(String.isBlank(absenceRegistration.Visit_Type__c)) {
                            if (directConvocation || contract.Visit_type__c == WORKTYPE_DIRECT_CONVOCATION) {
                                if (absenceRegistration.Exit_home_authorized__c == EXIT_HOME_FORBIDDEN && outsideAllowed) {
                                    if (contract.Visit_type__c == WORKTYPE_DIRECT_CONVOCATION) {
                                        absToUpdate.Visit_Type__c = WORKTYPE_HOME_VISIT_WITH_POTENTIAL_CONVOCATION;
                                    } else {
                                        absToUpdate.Visit_Type__c = contract.Visit_type__c;
                                    }
                                } else {
                                    absToUpdate.Visit_Type__c = WORKTYPE_DIRECT_CONVOCATION;
                                }
                            } else {
                                absToUpdate.Visit_Type__c = contract.Visit_type__c;
                            }
                        }
                    }

                    absenceRegistrationToUpdates.add(absToUpdate);
                }
            }
            if(tasks.size() > 0){
                insert tasks;
            }
            if(absenceRegistrationToUpdates.size() > 0){
                update absenceRegistrationToUpdates;
            }
        }
    }

    /** STEP 5: STATUS_MC_INITIATED **/

    /*********************************************************************************************************
    * @author        Novera - AMA
    * @date          2020 October 27
    * @description   This method create the work order when is status is initiate mc
    * @RelatedUS     OAPPMEDCHECK-182
    * @Step          STATUS_INITIATE_MC
    * @NextStep      STATUS_MC_INITIATED
    * @RecordType    FR and BE
    *********************************************************************************************************/
    public static void createWorkOrder(List<Absence_Registration__c> recordList) {

        Map<Id,Absence_Registration__c> absenceRegistrationIds = new Map<Id,Absence_Registration__c>();


        for(Absence_Registration__c absenceRegistration : recordList){
            if(absenceRegistration.On_hold__c != true && absenceRegistration.Technical_Status__c == STATUS_INITIATE_MC && absenceRegistration.Migrated__c == false && absenceRegistration.Simulation__c == false){
                absenceRegistrationIds.put(absenceRegistration.Id, absenceRegistration);
            }
        }


        List<Absence_Registration__c> absenceRegistrationToUpdates = new List<Absence_Registration__c>();
        List<WorkOrder> workOrders = new List<WorkOrder>();
        for(Id absenceRegistrationId : absenceRegistrationIds.keySet()){
            Absence_Registration__c absenceRegistration = absenceRegistrationIds.get(absenceRegistrationId);

            Absence_Registration__c abs = new Absence_Registration__c(Id = absenceRegistrationId);
            abs.Technical_Status__c = STATUS_MC_INITIATED;
            abs.Status_MC__c = MC_ONGOING;
            absenceRegistrationToUpdates.add(abs);

            WorkOrder wo = new WorkOrder(Absence_Registration__c = absenceRegistrationId);

            wo.Status = 'New';

            // if(absenceRegistration.Optimal_MC__c == false) {
                System.debug('QLE entitlements ' + [SELECT External_Id__c FROM Entitlement]);
                wo.Entitlement = new Entitlement(External_Id__c = 'MCM_Entitlement');
            // }else{
            //     wo.Entitlement = new Entitlement(External_Id__c = 'MCM_Optimal_Entitlement');
            // }

            if (absenceRegistration.Visit_Type__c == WORKTYPE_HOME_VISIT_WITHOUT_CONVOCATION) {
                wo.WorkType = new WorkType(Type_Id__c = WORKTYPE_HOME_VISIT_WITHOUT_CONVOCATION);
            }
            if (absenceRegistration.Visit_Type__c == WORKTYPE_DIRECT_CONVOCATION) {
                wo.WorkType = new WorkType(Type_Id__c = WORKTYPE_DIRECT_CONVOCATION);
            }
            if (absenceRegistration.Visit_Type__c == WORKTYPE_HOME_VISIT_WITH_POTENTIAL_CONVOCATION) {
                wo.WorkType = new WorkType(Type_Id__c = WORKTYPE_HOME_VISIT_WITH_POTENTIAL_CONVOCATION);
            }

            wo.AccountId = absenceRegistration.Account__c;
            wo.Employee__c = absenceRegistration.Employee__c;
            wo.Share_to_MCM_FR__c = absenceRegistration.Share_to_MCM_FR__c;
            wo.Share_to_MCM_BE__c = absenceRegistration.Share_to_MCM_BE__c;

            wo.Street = absenceRegistration.Street__c;
            wo.PostalCode = absenceRegistration.Postal_code__c;
            wo.City = absenceRegistration.City__c;
            wo.Optimal_MC__c = absenceRegistration.Optimal_MC__c;

            wo.Street = absenceRegistration.Street__c;
            if(String.isNotBlank(absenceRegistration.House_number__c)) {
                wo.Street += ' '+absenceRegistration.House_number__c;
            }
            if(String.isNotBlank(absenceRegistration.House_box_number__c)) {
                wo.Street += '/'+absenceRegistration.House_box_number__c;
            }

            /* QLE 30/11 - Google can't process this for automatic assignment
            if(String.isNotBlank(absenceRegistration.Name_on_bell__c)) {
                wo.Street += '\r\n'+Schema.SObjectType.Absence_Registration__c.fields.Name_on_bell__c.getLabel() + ' : ' + absenceRegistration.Name_on_bell__c;
            }
            */

            wo.Country = absenceRegistration.Country__c;


            if(absenceRegistration.Request_Date_and_Time__c != null && absenceRegistration.Request_Date_and_Time__c.hour() < 16){
                wo.Request_before_16h__c = true;
            }

            wo.StartDate = absenceRegistration.Request_Date_and_Time__c;
            wo.Tech_Certificate_End_Date__c = absenceRegistration.Certificate_End_Date__c;


            workOrders.add(wo);

        }

        if(absenceRegistrationToUpdates.size() > 0){
            update absenceRegistrationToUpdates;
        }

        // todo dirty fix for be rt
        for(WorkOrder wo : workOrders){
            Absence_Registration__c absenceRegistration = absenceRegistrationIds.get(wo.Absence_Registration__c);
            if(absenceRegistration.RecordTypeId == ABSENCE_REGISTRATION_RT_BE) {
                Date endDate = absenceRegistration.Certificate_End_Date__c == null ? absenceRegistration.End_date__c : absenceRegistration.Certificate_End_Date__c;
                wo.EndDate = endDate;
            }
        }


        if(workOrders.size() > 0){
            insert workOrders;
        }


    }

    /** --- END --- FLOW EXECUTING MC **/

    /** --- END --- MCM EXECUTING MC **/

    /********************************************************************************
    * @author        Novera - AMA
    * @description   OAPPMEDCHECK-651  Check Todos_before_invoicing_c on the related Contract_Home_c. If not empty => created task
    * @date          2021 March 16
    * @param         recordList Absence Registration (List<Absence_Registration__c>) : list of Absence Registrations
    * @return        void
    ********************************************************************************/
    public static void alignCancellationAbsenceAndSA(List<Absence_Registration__c> recordList, Map<Id,Absence_Registration__c> oldAbsenceRegistrations)
    {

        Map<Id, Absence_Registration__c> absenceRegistrationIds = new Map<Id, Absence_Registration__c>();
        for(Absence_Registration__c absenceRegistration : recordList){
            if(absenceRegistration.Status__c == STATUS_CANCELED && (oldAbsenceRegistrations.containsKey(absenceRegistration.Id) && oldAbsenceRegistrations.get(absenceRegistration.Id).Status__c != STATUS_CANCELED) && absenceRegistration.Migrated__c == false){
                absenceRegistrationIds.put(absenceRegistration.Id, absenceRegistration);
            }
        }

        if(absenceRegistrationIds.size() > 0){

            List<Absence_Registration__c> absenceRegistrations = new List<Absence_Registration__c>();
            for(Absence_Registration__c absence : absenceRegistrationIds.values()){
                Absence_Registration__c absenceToUpdate = new Absence_Registration__c(Id=absence.Id, Status_MC__c = STATUS_CANCELED, On_hold__c = true, Reason_on_hold__c = 'MC_Cancelled');
                absenceRegistrations.add(absenceToUpdate);
            }

            update absenceRegistrations;

            List<ServiceAppointment> serviceAppointments = [SELECT Id, Absence_Registration__c FROM ServiceAppointment WHERE Absence_Registration__c IN :absenceRegistrationIds.keySet()];

            for(ServiceAppointment sa : serviceAppointments){
                Absence_Registration__c abs = absenceRegistrationIds.get(sa.Absence_Registration__c);

                sa.Status = STATUS_SA_CANCELED;
                sa.Reason_of_cancellation__c = abs.Reason_of_cancellation__c;
            }

            update serviceAppointments;
        }

    }



    /********************************************************************************
    * @author        Novera - QLE
    * @description   OAPPMEDCHECK-346  Check Todos_before_invoicing_c on the related Contract_Home_c. If not empty => created task
    * @date          2021/02/23
    * @param         Absence Registration (List<Absence_Registration__c>) : list of Absence Registrations
    * @return        void
    ********************************************************************************/
    public static void createInvoicingTask(List<Absence_Registration__c> recordList,Map<Id,Absence_Registration__c> oldMap)
    {
        List<Task> taskToInsert = new List<Task>();
        Set<Id> ctrIds = new Set<Id>();
        Map<Id,String> statusPerArIds = new Map<Id,String>();
        List<Absence_Registration__c> arToProcess = new List<Absence_Registration__c>();
        for(Absence_Registration__c ar : recordList)
        {
            if(ar.Invoicing_Status__c==StaticConstants.AR_INVOICING_STATUS_INVOICE_TO_GENERATE && ar.Invoicing_Status__c!=oldMap.get(ar.Id).Invoicing_Status__c)
            {
                ctrIds.add(ar.Contract_Home__c);
                arToProcess.add(ar);
            }
        }
        
        Map<Id,Contract_Home__c> ctrMap = new Map<Id,Contract_Home__c>([SELECT Id, Todos_before_invoicing__c FROM Contract_Home__c WHERE Id IN: ctrIds AND RecordTypeId != :ContractHomeManager.mcmRtPricingId]);
        for(Absence_Registration__c ar : arToProcess)
        {
           
            if(ctrMap.get(ar.Contract_Home__c)!=null && ctrMap.get(ar.Contract_Home__c).Todos_before_invoicing__c!=null)
            {
                taskToInsert.add(AbsenceRegistrationManager.generateTaskMCMQueue(ar.RecordType.DeveloperName=='MCM_FR'?'FR':'BE'
                        ,ar.Id
                        ,Label.TodosBeforeInvoicing
                        ,ctrMap.get(ar.Contract_Home__c).Todos_before_invoicing__c
                        ,1));
                statusPerArIds.put(ar.Id,StaticConstants.AR_INVOICING_STATUS_MANUAL);

            }
        }
        if(!taskToInsert.isEmpty()) insert taskToInsert;
        if(!statusPerArIds.keySet().isEmpty()) setInvoicingStatus(statusPerArIds);
    }

    @future
    public static void setInvoicingStatus(Map<Id,String> statusPerArIds)
    {
        List<Absence_Registration__c> arList = new List<Absence_Registration__c>();
        for(Id arId : statusPerArIds.keySet())
        {
            arList.add(new Absence_Registration__c(Id=arId,Invoicing_Status__c=statusPerArIds.get(arId)));
        }
        update arList;
    }


    /********************************************************************************
    * @author        Novera - QLE
    * @description   OAPPMEDCHECK-455 IAM - Internal users Fr en Be (seperated sharing BE/FR)
    * @date          2021/02/15
    * @param         Absence Registration (List<Absence_Registration__c>) : list of Absence Registrations
    * @return        void
    ********************************************************************************/
    public static void shareMCMAbsence(List<Absence_Registration__c> recordList)
    {
        Set<Id> employeeIds = new Set<Id>();
        for (Absence_Registration__c ar : recordList)
        {
            if (ar.Employee__c  != null)
            {
                employeeIds.add(ar.Employee__c);
            }
        }
        if(employeeIds.size() > 0) {
            Map<Id, Employee__c> mapEmployeePerId = new Map<Id, Employee__c>([SELECT Id, Share_to_MCM_FR__c, Share_to_MCM_BE__c FROM Employee__c WHERE Id IN :employeeIds]);
            for (Absence_Registration__c ar : recordList) {
                if (ar.Employee__c != null) {
                    ar.Share_to_MCM_FR__c = mapEmployeePerId.get(ar.Employee__c).Share_to_MCM_FR__c;
                    ar.Share_to_MCM_BE__c = mapEmployeePerId.get(ar.Employee__c).Share_to_MCM_BE__c;
                }
            }
        }
    }


    /********************************************************************************
    * @author        Novera - QLE
    * @description   OAPPMEDCHECK-455 IAM - Internal users Fr en Be (seperated sharing BE/FR)
    * @date          2021/02/15
    * @param         Absence Registration (List<Absence_Registration__c>) : list of Absence Registrations
    * @return        void
    ********************************************************************************/
    public static void shareMCMAbsence(List<Absence_Registration__c> recordList,Map<Id,Absence_Registration__c> oldMap)
    {
        List<Absence_Registration__c> arToProcess = new List<Absence_Registration__c>();
        for (Absence_Registration__c ar : recordList)
        {
            if (ar.Employee__c!= null && ar.Employee__c!=oldMap.get(ar.Id).Employee__c)
            {
                arToProcess.add(ar);
            }
        }
        shareMCMAbsence(arToProcess);
    }






    public static void fillInvoicingAccountOnAbsenceRegistration(List<Absence_Registration__c> recordList, Map<Id,Absence_Registration__c> oldMap)
    {
        Set<Id> accIds = new Set<Id>();
        List<Task> tasks = new List<Task>();
        for(Absence_Registration__c ar : recordList)
        {
            if( (ar.Account__c!=null && ar.Invoicing_Account__c==null) || ( oldMap!=null && ar.Account__c!=null && ar.Account__c!=oldMap.get(ar.Id).Account__c) )
            {
                accIds.add(ar.Account__c);
            }
        }
        if(!accIds.isEmpty())
        {
            Map<Id,Account> accountMap = new Map<Id,Account>([SELECT Id, Invoicing_on_this_account__c, Invoicing_Account__c FROM Account WHERE Id IN:accIds]);
            for(Absence_Registration__c ar : recordList)
            {
                Account arAcc = accountMap.get(ar.Account__c);
                if(arAcc!=null && arAcc.Invoicing_on_this_account__c == 'Yes')
                {
                    ar.Invoicing_Account__c = ar.Account__c;
                }
                else
                {
                    if(arAcc!=null && arAcc.Invoicing_Account__c!=null)
                    {
                        ar.Invoicing_Account__c = arAcc.Invoicing_Account__c;
                    }
                    else
                    {
                        ar.On_Hold__c = true;
                        ar.Reason_on_hold__c = 'No_Invoicing_Account';
                        String country = getCountryRelatedToRecordType(ar.Id, ar.RecordTypeId)!=null?getCountryRelatedToRecordType(ar.Id, ar.RecordTypeId):COUNTRY_FR;
                        String description = Label.NoInvoicingAccount;
                        tasks.add(generateTaskMCMQueue(country, ar.Id, Label.NoInvoicingAccount, description, TASK_DELAY));
                    }
                }
            }
            if(!tasks.isEmpty()) insert tasks;
        }

    }



    /********************************************************************************
    * @author        Novera - AMU
    * @description   OAPPMEDCHECK-798 Absence registration fields on service appointment : rework
    * @date          2021/07/27
    * @param         Absence Registration (List<Absence_Registration__c>) : list of Absence Registrations
    * @return        void
    ********************************************************************************/
    public static void UpdateSAfields(List<Absence_Registration__c> recordList,Map<Id,Absence_Registration__c> oldMap)
    {
        Set<Id> absIds = new Set<Id>();
        List<ServiceAppointment> servAppToUpdate = new List<serviceAppointment>();
        for (Absence_Registration__c ar : recordList)
        {
            if (ar.Start_date__c!=oldMap.get(ar.Id).Start_date__c || ar.End_date__c!=oldMap.get(ar.Id).End_date__c || ar.Certificate_Start_Date__c!=oldMap.get(ar.Id).Certificate_Start_Date__c
                || ar.Certificate_End_Date__c!=oldMap.get(ar.Id).Certificate_End_Date__c || ar.Doctor_Firstname__c!=oldMap.get(ar.Id).Doctor_Firstname__c
                || ar.Doctor_Name__c!=oldMap.get(ar.Id).Doctor_Name__c || ar.Type__c!=oldMap.get(ar.Id).Type__c 
                || ar.Exit_home_authorized__c!=oldMap.get(ar.Id).Exit_home_authorized__c || ar.Visit_Type__c!=oldMap.get(ar.Id).Visit_Type__c 
                || ar.Type_of_visit_requested__c!=oldMap.get(ar.Id).Type_of_visit_requested__c || ar.Appointment_will_be_made_by__c!=oldMap.get(ar.Id).Appointment_will_be_made_by__c
                || ar.Notification_channel__c!=oldMap.get(ar.Id).Notification_channel__c)
            {
                absIds.add(ar.Id);
            }
        }

        List<ServiceAppointment> servAppList = new List<serviceAppointment>([SELECT Id
                                                                                    , Absence_Registration__r.Start_date__c
                                                                                    , Absence_Registration__r.End_date__c
                                                                                    , Absence_Registration__r.Certificate_Start_Date__c
                                                                                    , Absence_Registration__r.Certificate_End_Date__c
                                                                                    , Absence_Registration__r.Doctor_Firstname__c
                                                                                    , Absence_Registration__r.Doctor_Name__c
                                                                                    , Absence_Registration__r.Type__c
                                                                                    , Absence_Registration__r.Exit_home_authorized__c
                                                                                    , Absence_Registration__r.Visit_Type__c
                                                                                    , Absence_Registration__r.Type_of_visit_requested__c
                                                                                    , Absence_Registration__r.Appointment_will_be_made_by__c
                                                                                    , Absence_Registration__r.Notification_channel__c
                                                                            FROM serviceAppointment 
                                                                            WHERE Absence_Registration__c IN :absIds]);
                                                                            
        for(serviceAppointment sa : servAppList )
        {
            
            sa.Start_date__c = sa.Absence_Registration__r.Start_date__c;
            sa.Presumed_End_date__c = sa.Absence_Registration__r.End_date__c;
            sa.Certificate_Start_Date__c = sa.Absence_Registration__r.Certificate_Start_Date__c;
            sa.Certificate_End_Date__c = sa.Absence_Registration__r.Certificate_End_Date__c;
            String docFirstName= sa.Absence_Registration__r.Doctor_Firstname__c==null?'':sa.Absence_Registration__r.Doctor_Firstname__c;
            String docName= sa.Absence_Registration__r.Doctor_Name__c==null?'':sa.Absence_Registration__r.Doctor_Name__c;
            {
                sa.Doctor_Full_Name__c = docFirstName + ' ' + docName;
            }  
            sa.Type__c = sa.Absence_Registration__r.Type__c;
            sa.Exit_home_authorized__c= sa.Absence_Registration__r.Exit_home_authorized__c;   
            sa.Visit_Type__c= sa.Absence_Registration__r.Visit_Type__c;
            sa.Type_of_visit_requested__c = sa.Absence_Registration__r.Type_of_visit_requested__c;
            sa.Appointment_will_be_made_by__c = sa.Absence_Registration__r.Appointment_will_be_made_by__c;
            sa.Notification_channel__c = sa.Absence_Registration__r.Notification_channel__c;

            servAppToUpdate.add(sa);

        }
        if(servAppToUpdate.size() > 0) update servAppToUpdate;

    }

    /********************************************************************************
    * @author        Novera - AMU
    * @description   OAPPMEDCHECK-798 Absence registration fields on service appointment : rework
    * @date          2021/07/27
    * @param         Absence Registration (List<Absence_Registration__c>) : list of Absence Registrations
    * @return        void
    ********************************************************************************/

    public static void sendIntermediaryChangeAbsence(List<Absence_Registration__c> recordList)
    {
        system.debug('AMU sendIntermediaryChangeAbsence');

        Set<Id> setAbsenceIds = new Set<Id>();
        Id saId;
        Id absenceId;
        ID absenceOwnerId;
        String absenceRT;
        List <Recipients_Absence_Query.flowInputs> lstInputs = new List <Recipients_Absence_Query.flowInputs>();
        
        if(recordList!=null && !recordList.isEmpty())
        {
            for(Absence_Registration__c abs : recordList)
            {   
                //send parameters to the apex query recipients class
                Recipients_Absence_Query.flowInputs Inputs = new Recipients_Absence_Query.flowInputs();
                Inputs.absenceAccountId = abs.Account__c;
                Inputs.mainAccountId    = abs.Main_Account__c;
                absenceId               = abs.id;
                absenceOwnerId          = abs.OwnerId;
                system.debug('AMU abs.ownerID '+abs.OwnerId);
                absenceRT               = abs.RecordTypeId;
                lstInputs.add(Inputs);
            }
            system.debug('AMU lstInputs '+ lstInputs);
            
            List<Task> alertTasks = new List<Task>();
            Map<Id, Contact> mapRecipients = new Map<Id, Contact>();
                
            //Collect the contact recipients lists output
            List <Recipients_Absence_Query.Response> Responses = Recipients_Absence_Query.retrieveInputs(lstInputs);
                    
            for(Recipients_Absence_Query.Response res: Responses){
                if(absenceRT == ABSENCE_REGISTRATION_RT_BE && !res.AbsenceReceived_Recipients.isEmpty())
                {
                    mapRecipients.putall(res.AbsenceReceived_Recipients);
                }          
            }
    
            //Update the contact to trigger email alert
            if(mapRecipients.size() > 0) {
                for(contact con : mapRecipients.values()) {
                    con.TECH_Notify_employer_absence__c = true;
                    con.Tech_Related_To__c = absenceId;
                }
                update mapRecipients.values();
            }
            
            else if(mapRecipients.size() == 0) {
                Task myTask = new Task();
                    myTask.ActivityDate = System.today();
                    myTask.subject     = System.Label.FlowNoRecipientsAbsence;
                    myTask.Description = System.Label.FlowNoRecipientsAbsence;
                    myTask.OwnerId     = absenceOwnerId;
                    myTask.Status      = 'Open';
                    myTask.WhatId      = absenceId;
                
                alertTasks.add(myTask);                
            }
            if(alertTasks.size() > 0) {
                insert alertTasks;             
            }
        }
    }

    /********************************************************************************
    * @author        Novera - AMU
    * @description   OAPPMEDCHECK-1053 Prevent cancellation of absence if there is at least one SA in status
                     other than New/Scheduled/Cancelled
    * @date          2021/11/05
    * @param         Absence Registration (List<Absence_Registration__c>) : list of Absence Registrations
    * @return        void
    ********************************************************************************/
    public static void PreventCancellationOfAbsence(List<Absence_Registration__c> recordList,Map<Id,Absence_Registration__c> oldMap)
    {
        Set<Id> absIds = new set<Id>();
        List<Absence_Registration__c> absToProcess = new List<Absence_Registration__c>();
        Set<Id> absWithErrIds = new Set<Id>();

        for(Absence_registration__c ar : recordList)
        {
            if(ar.Status__c==STATUS_CANCELED && oldmap.get(ar.Id).Status__c!=STATUS_CANCELED)
            {
                absIds.add(ar.Id);
                absToProcess.add(ar);
            }
        }

        if(absIds!=null)
        {
            for (AggregateResult agg :[SELECT count(Id) countSA, Absence_Registration__c FROM ServiceAppointment
                                        WHERE Status!=:STATUS_SA_NEW AND Status!=:STATUS_SA_SCHEDULED AND Status!=:STATUS_SA_CANCELED AND Absence_Registration__c IN :absIds
                                        GROUP BY Absence_Registration__c])
            {
                if(Integer.valueOf(String.valueOf(agg.get('countSA'))) > 0)
                {
                    absWithErrIds.add(String.valueOf(agg.get('Absence_Registration__c')));
                }

            }
            if(!absWithErrIds.isEmpty())
            {
                for(Absence_Registration__c ar: absToProcess)
                {
                    if(absWithErrIds.contains(ar.Id))
                    {
                        ar.addError(Label.BlockAbsenceCancellation);
                    }
                }
            }
        }
    }


}