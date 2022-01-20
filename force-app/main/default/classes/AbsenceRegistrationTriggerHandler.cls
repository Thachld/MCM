/********************************************************************************************************
* @author         Novera - Allison Muschs
* @description    Trigger Handler for the Session custom object
* @date           2020 JUNE 23
* @group          MCM
*********************************************************************************************************/

public class AbsenceRegistrationTriggerHandler {

    public static final String ABSENCE_REGISTRATION_RT_BE = Schema.SObjectType.Absence_Registration__c.getRecordTypeInfosByDeveloperName().get(StaticConstants.Absence_Registration_RT_BE).getRecordTypeId();
    public static final String ABSENCE_REGISTRATION_RT_FR = Schema.SObjectType.Absence_Registration__c.getRecordTypeInfosByDeveloperName().get(StaticConstants.Absence_Registration_RT_FR).getRecordTypeId();


    // Map containing recordtype-RecordList combinations
    Map<Id,List<Absence_Registration__c>> rtRecordListMap;

    // Map containing recordtype-OldRecordList combinations
    Map<Id,Map<Id,Absence_Registration__c>> rtOldRecordListMap; 

    // Map containing the old values for the Records
    Map<Id, Absence_Registration__c> recordOldValueMap;

    // Initial records receives from the Trigger
    List<Absence_Registration__c> initialRecordList;



    //////////////////////////////////////////////////////////////////////////////////////////////////////////
    //                                          PUBLIC METHODS                                              //
    //////////////////////////////////////////////////////////////////////////////////////////////////////////

    /*********************************************************************************************************
    * @author        AM
    * @date          2020 JUNE 23
    * @description   Constructor
    *********************************************************************************************************/
    public AbsenceRegistrationTriggerHandler(List<Absence_Registration__c> recordList, Map<Id,Absence_Registration__c> recordOldValueMap)
    {
        // Store a reference to the initial list
        this.initialRecordList = recordList;

        // Set the Old Value Map
        this.recordOldValueMap = recordOldValueMap;

        // Initiate the New and Old RecordType - Record List Map
        rtRecordListMap = new Map<Id,List<Absence_Registration__c>>();
        rtOldRecordListMap = new Map<Id,Map<Id,Absence_Registration__c>>();

        // Fill the RecordType - Record List Map
         this.fillRecordMaps(recordList,recordOldValueMap);
    }


    /*********************************************************************************************************
    * @author        Novera Solutions - Allison Muschs
    * @date          2019 JUNE 10

    * @description   Method carrying out the logic, seperated by RecordType
    * @return        void
    *********************************************************************************************************/
    public void run()
    {

        List<Absence_Registration__c> allRecordList;
        Map<Id,Absence_Registration__c> allOldRecordMap;
        // No Filter : All AbsenceRegistration
        allRecordList = this.initialRecordList;
        allOldRecordMap = this.recordOldValueMap;



        Set<Id> recordTypeFRIds = new Set<Id>{ABSENCE_REGISTRATION_RT_FR};
        Set<Id> recordTypeBEIds = new Set<Id>{ABSENCE_REGISTRATION_RT_BE};

        List<Absence_Registration__c> absenceRegistrationsFR = filterRecord(recordTypeFRIds);
        List<Absence_Registration__c> absenceRegistrationsBE = filterRecord(recordTypeBEIds);
        Map<Id,Absence_Registration__c> oldRecordMapFR = filterOldRecord(recordTypeFRIds);


        if(allRecordList != null && allRecordList.size() > 0)
        {
            if(Trigger.isBefore)
            {
                if(Trigger.isInsert)
                {
                    //AbsenceRegistrationManager.fillDisease(allRecordList,allOldRecordMap);
                    AbsenceRegistrationManager.shareMCMAbsence(allRecordList);
                    
                }
                if(Trigger.isUpdate)
                {
                    AbsenceRegistrationManager.shareMCMAbsence(allRecordList,allOldRecordMap);
                    AbsenceRegistrationManager.PreventCancellationOfAbsence(allRecordList, allOldRecordMap);
                }
                if(Trigger.isInsert || Trigger.isUpdate)
                {
                    AbsenceRegistrationManager.AlignStatusFieldWithTechnical(allRecordList, allOldRecordMap);
                    AbsenceRegistrationManager.fillAccountOnAbsenceRegistration(allRecordList, allOldRecordMap);
                    AbsenceRegistrationManager.fillContract(allRecordList);
                    AbsenceRegistrationManager.fillInvoicingAccountOnAbsenceRegistration(allRecordList,allOldRecordMap);
                }
            }
            if(Trigger.isAfter)
            {
                if(Trigger.isInsert)
                {
                    AbsenceRegistrationManager.sendIntermediaryChangeAbsence(absenceRegistrationsBE);
                    
                }
                if(Trigger.isUpdate)
                {
                    if(!System.isFuture())AbsenceRegistrationManager.createInvoicingTask(allRecordList,allOldRecordMap);
                    AbsenceRegistrationManager.contractIsActiveForMC(allRecordList);
                    AbsenceRegistrationManager.checkAbsenceIsValidToTreatment(allRecordList);
                    AbsenceRegistrationManager.createWorkOrder(allRecordList);
                    AbsenceRegistrationManager.alignCancellationAbsenceAndSA(allRecordList, allOldRecordMap);
                    AbsenceRegistrationManager.UpdateSAfields(allRecordList, allOldRecordMap);
                    
                }
            }
        }


        // ONLY BE
        if(absenceRegistrationsBE != null && absenceRegistrationsBE.size() > 0) {

            if(Trigger.isBefore){
                if (Trigger.isInsert || Trigger.isUpdate) {
                    AbsenceRegistrationManager.fillStartDateDisease(allRecordList);
                }
            }

            if (Trigger.isAfter) {
                if (Trigger.isInsert || Trigger.isUpdate) {                    
                    AbsenceRegistrationManager.checkCustomCriteria(absenceRegistrationsBE);
                    AbsenceRegistrationManager.checkVisitTypeMCBE(absenceRegistrationsBE);
                    
                }
            }

        }
        // ONLY FR
        if(absenceRegistrationsFR != null && absenceRegistrationsFR.size() > 0) {
            if (Trigger.isAfter) {
                if (Trigger.isInsert || Trigger.isUpdate) {
                    AbsenceRegistrationManager.checkVisitTypeMCFR(absenceRegistrationsFR);
                }
                if(Trigger.isUpdate){
                    //AbsenceRegistrationManager.UpdateSAfields(absenceRegistrationsFR, oldRecordMapFR);
                }
            }
        }

    }


    //////////////////////////////////////////////////////////////////////////////////////////////////////////
    //                                         PRIVATE METHODS                                              //
    //////////////////////////////////////////////////////////////////////////////////////////////////////////

    /*********************************************************************************************************
    * @author        Jérémie Denis
    * @date          2018 APR 05
    * @description   This method filter all the Leads by their Record Type Id
    * @param         recordTypeIds (List<Id>): The list of Record Type Id to use for the filter
    * @return        List<Absence_Registration__c>: Return a Absence registrations of Leads that have the filtered Record Type Id
    *********************************************************************************************************/
    private List<Absence_Registration__c> filterRecord(Set<Id> recordTypeIds){

        List<Absence_Registration__c> records = new List<Absence_Registration__c>();

        for(Id recordTypeId:recordTypeIds){
            if(rtRecordListMap.containsKey(recordTypeId)){
                records.addAll(rtRecordListMap.get(recordTypeId));
            }
        }

        return records;

    }

    /*********************************************************************************************************
    * @author        Aliocha Mazurkiewicz
    * @date          2020 July 22
    * @description   This method filter all the old Contacts by their Record Type Id
    * @param         recordTypeIds (List<Id>): The list of Record Type Id to use for the filter
    * @return        List<Absence_Registration__c>: Return a list of old Absence registrations that have the filtered Record Type Id
    *********************************************************************************************************/
    private Map<Id,Absence_Registration__c> filterOldRecord(Set<Id> recordTypeIds){

        Map<Id,Absence_Registration__c> oldsRecords = new Map<Id,Absence_Registration__c>();

        for(Id recordTypeId:recordTypeIds){
            if(rtOldRecordListMap.containsKey(recordTypeId)){

                oldsRecords.putAll(rtOldRecordListMap.get(recordTypeId));
            }
        }

        return oldsRecords;

    }
    /*********************************************************************************************************
        * @author        Jérémie Denis
        * @date          2018 APR 05
        * @description   Method separating the records based on recordtype
        * @param         recordList (List<Absence_Registration__c>): List of new record values.
        * @param         recordOldValueMap (Map<Id,Absence_Registration__c>) : Map of the old record values
        * @return        void
        *********************************************************************************************************/
    private void fillRecordMaps(List<Absence_Registration__c> recordList, Map<Id,Absence_Registration__c> recordOldValueMap)
    {
        // New records (unless Delete trigger)
        if(recordList != null)
        {
            for(Absence_Registration__c r : recordList)
            {
                if(rtRecordListMap.containsKey(r.RecordTypeId))
                {
                    rtRecordListMap.get(r.RecordTypeId).add(r);
                }
                else
                {
                    rtRecordListMap.put(r.RecordTypeId,new List<Absence_Registration__c>{r});
                }
            }
        }

        // Old records
        if(recordOldValueMap != null)
        {
            for(Absence_Registration__c r : recordOldValueMap.values())
            {
                Map<Id,Absence_Registration__c> oldRecord = new Map<Id,Absence_Registration__c>{r.Id => r};
                if(rtOldRecordListMap.containsKey(r.RecordTypeId))
                {
                    rtOldRecordListMap.get(r.RecordTypeId).putAll(oldRecord);
                }
                else
                {
                    rtOldRecordListMap.put(r.RecordTypeId, oldRecord);
                }
            }
        }

    }
}