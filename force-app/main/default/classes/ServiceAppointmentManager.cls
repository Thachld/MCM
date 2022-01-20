/********************************************************************************************************
* @author         Novera - AMU
* @description    Trigger Handler for the ServiceAppointment object
* @date           10 OCT 2020       
* @group          Trigger Managers
*********************************************************************************************************/
public class ServiceAppointmentManager
{

    public static final String REMUNERATION_STATUS_INVOICE_DETAIL_LINE_TO_GENERATE = 'Invoice Detail Lines to generate';
    public static final String REMUNERATION_STATUS_INVOICE_DETAIL_LINE_GENERATED = 'Invoice Detail Lines generated';
    public static final String REMUNERATION_STATUS_INVOICE_DETAIL_LINE_ERROR = 'Error during Invoice Detail Lines';
    public static final String REMUNERATION_STATUS_NO_REMUNERATION = 'No remuneration';
    public static final String REMUNERATION_STATUS_REMUNERATION_NOTE_CREATED = 'Remuneration note created';

    public static final String STATUS_RESULT_TO_CUSTOMER = 'Result to customer';
    public static final String STATUS_CHECK_COMPLETED = 'Completed';
    public static final String STATUS_SCHEDULED = 'Scheduled';
    public static final String STATUS_DISPATCHED = 'Dispatched';
    public static final String STATUS_CANNOT_COMPLETE = 'Cannot Complete';
    public static final String INVOICING_STATUS_INVOICE_DETAIL_LINE_TO_GENERATE = 'Invoice Detail Lines to generate';
    public static final String INVOICING_STATUS_INVOICE_DETAIL_LINE_GENERATED = 'Invoice Detail Lines generated';
    public static final String INVOICING_STATUS_INVOICE_DETAIL_LINE_ERROR = 'Error during Invoice Detail Lines';
    public static final String INVOICING_STATUS_PREPAYMENT = 'Prepayment - no invoicing';
    public static final String INVOICING_STATUS_NO_INVOICING = 'No invoicing';

    public static final String OP_CONCLUSION_OK_TODAY = 'Arrêt de travail médicalement justifié ce jour';
    public static final String OP_CONCLUSION_OK_TODAY_EXT = 'Arrêt de travail médicalement justifié ce jour - Prolongation possible';
    public static final String OP_CONCLUSION_OK_RESTART = 'Arrêt justifié reprise envisageable';
    public static final String OP_CONCLUSION_NO_ANSWER = 'Absence de réponse au lieu de résidence';
    public static final String OP_CONCLUSION_ABSENT = 'Absence du salarie confirmée par un tiers';
    public static final String OP_CONCLUSION_NOT_OK = 'Arrêt de travail plus médicalement justifié ce jour';
    public static final String OP_CONCLUSION_REFUSED = 'Refus de contrôle ou d\'examen';
    public static final String OP_CONCLUSION_WRONG_ADDRESS = 'Adresse incomplète ou problématique';
    public static final String OP_CONCLUSION_WRONG_CODE = 'Problème de code d\'accès';
    public static final String OP_CONCLUSION_NOT_IN_LEAVE = 'Salarié pas en arrêt de travail';
    public static final String OP_CONCLUSION_NO_SHOW = 'Salarié non présenté au cabinet';

    public static final String VISIT_TYPE_DOUBLE_PASSAGE = 'Double Passage';

    public static final String QUEUE_MCM_iNVOICE_FR = 'MCM_INVOICE_FR';    
    public static final String COUNTRY_FR = 'FR';

    public static final String INVOICE_DETAIL_LINE_CN_TYPE = 'Credit Note - Customer Invoicing';
    public static final String INVOICE_DETAIL_LINE_REMUNERATION_TYPE = 'Doctor Remuneration';
    public static final String INVOICE_DETAIL_LINE_CI_TYPE = 'Customer Invoicing';

    public static final String SERVICE_IDENTIFICATOR_HOME_VISIT = 'Home visit';
    public static final String SERVICE_IDENTIFICATOR_CONVOCATION = 'Convocation';
    public static final String SERVICE_IDENTIFICATOR_WEEKEND = 'Weekend';
    public static final String SERVICE_IDENTIFICATOR_FLAT = 'Flat';
    public static final String SERVICE_IDENTIFICATOR_MOUNTAIN = 'Mountain';
    public static final String SERVICE_IDENTIFICATOR_KM = 'Km';
    public static final String SERVICE_IDENTIFICATOR_LETTER = 'Letter';
    public static final String SERVICE_IDENTIFICATOR_SMS = 'SMS';
    public static final String SERVICE_IDENTIFICATOR_MISC = 'Miscellaneous';

    public static final String WORKTYPE_FR_HV = 'Home_Visit_without_Convocation';
    public static final String WORKTYPE_FR_HV_CONV = 'Home_Visit_with_Potential_Convocation';
    public static final String WORKTYPE_FR_CONV_HV = 'Convocation_After_Home_Visit';
    public static final String WORKTYPE_FR_CONV = 'Direct_Convocation';
    public static final String WORKTYPE_FR_ARBITRAGE = 'Arbitrage';
    public static final String WORKTYPE_FR_EXPERTISE = 'Expertise';



    //Novera- QLE Zip Code is a custom object in Salesforce
    public static Map<String,Id> ZipCodeIdPerNameMap{ 
        get{
            if(ZipCodeIdPerNameMap==null)
            {
                Map<String,Id> zipCodeMap = new Map<String,Id>();
                for(Zip_Code__c zc : [SELECT Id, Name FROM Zip_Code__c WHERE Name!=null])
                {
                    zipCodeMap.put(zc.Name,zc.Id);
                }
                ZipCodeIdPerNameMap=ZipCodeMap;
            }
            return ZipCodeIdPerNameMap;
        }
        set;
    }


    public static Map<Id,String> serviceNamePerIdMap
    { 
        get{
            if(serviceNamePerIdMap==null)
            {
                Map<Id,String> servNamePerIdMap = new Map<Id,String>();
                for(Service__c s : [SELECT Id, Service_Name__c FROM Service__c WHERE Available_for_country__c!=null])
                {
                    servNamePerIdMap.put(s.Id,s.Service_Name__c);
                }
                serviceNamePerIdMap = servNamePerIdMap; 
            }
            return serviceNamePerIdMap;
        }
        set;
    }


    public static Map<String,Map<String,Id>> servicePerVisitTypePerCountryMap{ 
        get{
            if(servicePerVisitTypePerCountryMap==null)
            {
                Map<String,Map<String,Id>> serviceMap = new Map<String,Map<String,Id>>();
                Map<String,Id> servicePerVisitTypeMapFR = new Map<String,Id>();
                Map<String,Id> servicePerVisitTypeMapBE = new Map<String,Id>();
                for(Service__c s : [SELECT Id, Visit_Type__c, Supplement_Type__c, Name, Available_for_country__c,Service_category__c  FROM Service__c WHERE Available_for_country__c!=null])
                {
                    switch on s.Available_for_country__c
                    {
                        when 'FR'{
                            if(s.Visit_Type__c!=null){
                                servicePerVisitTypeMapFR.put(s.Visit_Type__c,s.Id);
                            }
                            if(s.Supplement_Type__c!=null) {
                                servicePerVisitTypeMapFR.put(s.Supplement_Type__c,s.Id);
                            }
                            if(s.Service_category__c==SERVICE_IDENTIFICATOR_MISC)
                            {
                                servicePerVisitTypeMapFR.put(s.Service_category__c,s.Id);
                            }
                        }
                        // when 'BE'{
                        //  servicePerVisitTypeMapBE.put(s.Name,s.Id);
                        // }
                    }
                    
                }
                serviceMap.put('FR',servicePerVisitTypeMapFR);
                //serviceMap.put('BE',servicePerVisitTypeMapBE);
                servicePerVisitTypePerCountryMap=serviceMap;
            }
            return servicePerVisitTypePerCountryMap;
        }
        set;
    }

    /*********************************************************************************************************
    * @author        Novera - AMU
    * @date          2021 APRIL 21
    * @description   This method get the ID of Queue for MCM Belgium an France group
    *                It's used to create a task and we need dispatch correctly the issue when an absence is flagged "on hold"
    * @RelatedUS     OAPPMEDCHECK-785
    * @RecordType    FR (and BE later)
    *********************************************************************************************************/
    public static final Map<String,Id> MCMInvoicingQueues{
        public get{
            if(MCMInvoicingQueues == null){

                List<Group> queues = [SELECT Id, DeveloperName FROM Group WHERE Type = :StaticConstants.GROUP_QUEUE AND ( DeveloperName = :QUEUE_MCM_INVOICE_FR)];
                if(queues.size() == 1){
                    MCMInvoicingQueues = new Map<String, Id>();
                    for(Group queue : queues){
                        // BE to do later
                        //if(queue.DeveloperName == QUEUE_MCM_GENERAL_BE){
                            //MCMQueues.put(COUNTRY_BE, queue.Id);
                        //}
                        if(queue.DeveloperName == QUEUE_MCM_INVOICE_FR){
                            MCMInvoicingQueues.put(COUNTRY_FR, queue.Id);
                        }
                    }
                }else{
                    throw new CustomException(System.Label.Error_Message+' Unable to find MCM Queues');
                }
            }
            return MCMInvoicingQueues;
        }
        public set;
    }

    /*********************************************************************************************************
    * @author        Novera - AMU
    * @date          2021 APRIL 21
    * @description   This method create a Task formatted for MCM Queue
    * @RelatedUS     OAPPMEDCHECK-785
    * @RecordType    FR and BE
    * @return Task
    *********************************************************************************************************/
    public static Task generateTaskMCMQueue(Id ownerId, String country, Id relatedToId, String subject, String comment, Integer delay)
    {        
        Id taskOwnerId = ownerId!=null?ownerId:country!=null?MCMInvoicingQueues.get(country):null;
        Task tsk = new Task();
        tsk.OwnerId = taskOwnerId;
        tsk.WhatId = relatedToId;
        tsk.Subject = subject;
        tsk.Description = comment;
        tsk.ActivityDate = Date.today().addDays(delay);
        tsk.Priority = AbsenceRegistrationManager.TASK_PRIORITY_HIGH;
        tsk.Type = AbsenceRegistrationManager.TASK_TYPE_WARNING;
        tsk.RecordTypeId = AbsenceRegistrationManager.TASK_RT_MCM;
        tsk.ReminderDateTime = Datetime.now().addHours(1);
        return tsk;
    }
    /*******************************************************************************
    * @author       Novera - QLE
    * @date         2020-12-03
    * @description  OAPPMEDCHECK-661 Create remuneration note (SF) : Stamp doctor convention
    * @param        
    * @return       
    ********************************************************************************/
    public static void fillDoctorConvention(List<ServiceAppointment> recordList, Map<Id,ServiceAppointment> oldMap)
    {   
        List<ServiceAppointment> saToProcess = new List<ServiceAppointment>();
        Set<Id> srIds = new Set<Id>();
        Map<Id,Id> doctorAccIdPerServResIdMap = new Map<Id,Id>();
        Set<Id> doctorAccIds = new Set<Id>();
        Map<Id,Id> convIdPerDocAccIdMap = new Map<Id,Id>();
        for(ServiceAppointment sa : recordList)
        {
            if(sa.Assigned_Resource__c==null)
            {
                sa.Doctor_Convention__c=null;
            }
            else
            {
                if((sa.Assigned_Resource__c!=oldMap.get(sa.Id).Assigned_Resource__c)
                || (sa.Assigned_Resource__c==oldMap.get(sa.Id).Assigned_Resource__c && sa.Doctor_Convention__c==null))
                {
                    srIds.add(sa.Assigned_Resource__c);
                    saToProcess.add(sa);
                }
            }
        }
        if(!srIds.isEmpty())
        {
            for(ServiceResource sr : [SELECT Id, AccountId FROM ServiceResource WHERE Id IN:srIds])
            {
                doctorAccIdPerServResIdMap.put(sr.Id,sr.AccountId);
                doctorAccIds.add(sr.AccountId);
            }
            if(!doctorAccIds.isEmpty())
            {
                for(Contract_Home__c conv : [SELECT Id, Account__c FROM Contract_Home__c WHERE Account__c IN:doctorAccIds AND Active__c=TRUE AND (RecordTypeId =:ContractHomeManager.mcmRtConventionFRId OR RecordTypeId =:ContractHomeManager.mcmRtConventionBEId)])
                {
                    convIdPerDocAccIdMap.put(conv.Account__c,conv.Id);
                }
            }
        }
        System.debug('QLE convIdPerDocAccIdMap ' + convIdPerDocAccIdMap); 
        for(ServiceAppointment sa : saToProcess)
        {
            if(doctorAccIdPerServResIdMap.containsKey(sa.Assigned_Resource__c))
            {
                System.debug('QLE doctorAccIdPerServResIdMap.containsKey(sa.Assigned_Resource__c) '); 
                if(convIdPerDocAccIdMap.containsKey(doctorAccIdPerServResIdMap.get(sa.Assigned_Resource__c)))
                {
                    System.debug('QLE convIdPerDocAccIdMap.containsKey(doctorAccIdPerServResIdMap.get(sa.Assigned_Resource__c)) '); 
                    sa.Doctor_Convention__c = convIdPerDocAccIdMap.get(doctorAccIdPerServResIdMap.get(sa.Assigned_Resource__c));
                }
            }
            else
            {
                sa.Doctor_Convention__c = null;
            }
        }
    }



    /*******************************************************************************
    * @author       Novera - QLE
    * @date         2020-12-03
    * @description  OAPPMEDCHECK-343 Setup invoice detail lines for completed WO
    * @param        
    * @return       
    ********************************************************************************/
    public static void createInvoiceDetailLine(List<ServiceAppointment> recordList, Map<Id,ServiceAppointment> oldMap)
    {
        System.debug('QLE createInvoiceDetailLine ');
        Map<Id,ServiceAppointment> saToProcessForInvoice = new Map<Id,ServiceAppointment>();
        Map<Id,Id> ctrIdPersaId= new Map<Id,Id>();
        Set<Id> ctrIdSet = new Set<Id>();
        Map<Id,String> saInvoicingStatus =  new Map<Id,String>(); 
        List<Task> errorTaskToInsert = new List<Task>();
        Map<Id,Set<Id>> servIdOfExistingIDLPerSaId = new Map<Id,Set<Id>>();
        Set<Id> saToRecalculateIds = new Set<Id>();
        
        for(ServiceAppointment sa : recordList)
        {
            if((sa.Invoicing_Status__c==INVOICING_STATUS_INVOICE_DETAIL_LINE_TO_GENERATE && oldMap.get(sa.Id).Invoicing_Status__c!=INVOICING_STATUS_INVOICE_DETAIL_LINE_TO_GENERATE)
                        || (sa.Invoicing_On_Hold__c==false && oldMap.get(sa.Id).Invoicing_On_Hold__c==true && sa.Invoicing_Status__c!=null) 
                        || ( (sa.No_Invoice__c==false && oldMap.get(sa.Id).No_Invoice__c==true && sa.Invoicing_Status__c!=null)  )  )                   
            {
                if(sa.Contract_Home__c!=null)
                {
                    saToProcessForInvoice.put(sa.Id,sa);
                    ctrIdSet.add(sa.Contract_Home__c);
                    ctrIdPerSaId.put(sa.Id,sa.Contract_Home__c);
                    if((sa.Invoicing_On_Hold__c==false && oldMap.get(sa.Id).Invoicing_On_Hold__c==true) 
                            || (sa.No_Invoice__c==false && oldMap.get(sa.Id).No_Invoice__c==true) )
                    {
                        saToRecalculateIds.add(sa.Id);
                    }
                }
                else
                {
                    errorTaskToInsert.add(generateTaskMCMQueue(sa.OwnerId,null,sa.Id,Label.ErrorDuringInvoiceDetailLines,Label.noContractFound,1));
                    saInvoicingStatus.put(sa.Id,'E');
                }  
            }
        }

        //OAPPMEDCHECK-660 SA without invoicing or remuneration
        if(saToRecalculateIds!=null&&!saToRecalculateIds.isEmpty())
        {
            List<Service_Appointment_Line_Item__c> saliToDelete =  [SELECT Id FROM Service_Appointment_Line_Item__c
                                    WHERE Service_Appointment__c IN: saToRecalculateIds 
                                    AND Invoicing_type__c = :INVOICE_DETAIL_LINE_CI_TYPE];
            if(!saliToDelete.isEmpty()) delete saliToDelete; 
        }

        if(!saToProcessForInvoice.isEmpty())
        {
            Map<Id,Task> taskPerSaIdMap = checkInvoicingRecipientAndAccount(saToProcessForInvoice.values(),false);
            if(!taskPerSaIdMap.isEmpty())
            {
                for(Id saId : taskPerSaIdMap.keySet())
                {
                    errorTaskToInsert.add(taskPerSaIdMap.get(saId));
                    saInvoicingStatus.put(saId,'E');
                    saToProcessForInvoice.remove(saId);
                }
            }
        }
        if(!saToProcessForInvoice.isEmpty())
        {
            List<Service_Appointment_Line_Item__c> saliListToInsert = new List<Service_Appointment_Line_Item__c>(); //invoice detail lines to insert
            contractInfoForInvoicing info = getcontractInfoForInvoicing(ctrIdSet);
            Map<Id,Map<Id,Decimal>> pricePerServIdPerCtrId = info.pricePerServIdPerCtrId; //Get negotiated price from CSLI 
            Set<Id> csliWithPrivilegedPack = info.csliWithPrivilegedPack;
            System.debug('QLE pricePerServIdPerCtrId ' + pricePerServIdPerCtrId);
            Map<Id,Decimal> kmInForfaitPerCtrId = info.kmInForfaitPerCtrId; 
            
            //Preparation for SMS invoicing
            Map<Id,Integer> numOfSmsToInvoicePerSaIdMap = new Map<Id,Integer>();
            for(AggregateResult ar : [SELECT WhatId, count(Id) numOfSms FROM Task WHERE WhatId IN:saToProcessForInvoice.keySet() AND Event_Type__c='MCM SMS Employee' 
                                        AND RecordTypeId=:UtilsConstants.RT_ID_TASK_MCM_TASK GROUP BY WhatId])
            {
                numOfSmsToInvoicePerSaIdMap.put(String.valueOf(ar.get('WhatId')),Integer.valueOf(ar.get('numOfSms')));
            }
           
            //Preparation for notification letter invoicing
            Map<Id,Integer> numOfLetterToInvoicePerSaIdMap = new Map<Id,Integer>();
            for(AggregateResult ar : [SELECT WhatId, count(Id) numOfLetter FROM Task WHERE WhatId IN:saToProcessForInvoice.keySet() AND Event_Type__c='MCM Letter Employee' 
                                        AND RecordTypeId=:UtilsConstants.RT_ID_TASK_MCM_TASK GROUP BY WhatId])
            {
                numOfLetterToInvoicePerSaIdMap.put(String.valueOf(ar.get('WhatId')),Integer.valueOf(ar.get('numOfLetter')));
            }
    
            // Id of services available for FR
            Map<String,Id> servicePerVisitTypeMapFR = servicePerVisitTypePerCountryMap.get('FR');

            for(ServiceAppointment sa : saToProcessForInvoice.values())
            {       
                try{
                    System.debug('QLE HERE');
                    Map<Id,Decimal> pricePerServId = pricePerServIdPerCtrId.get(sa.Contract_Home__c); 
                    if(pricePerServId==null || pricePerServId.isEmpty())
                    {
                        throw new CustomException(Label.CanNotFindPriceInContract);
                    }
                    if(!csliWithPrivilegedPack.contains(sa.Contractual_Service_Line_Item__c))
                    {
                        //Visit invoicing
                        saliListToInsert.addAll(visitInvoicing(sa,servicePerVisitTypeMapFR,pricePerServId,false));
    
                        //Communication Invoicing
                        //SMS
                        if(numOfSmsToInvoicePerSaIdMap.get(sa.Id) > 0)
                        {
                            Id sSmsEmplId = getServiceIdFromPricing(servicePerVisitTypeMapFR,SERVICE_IDENTIFICATOR_SMS);
                            for(Integer i=0;i<numOfSmsToInvoicePerSaIdMap.get(sa.Id);i++)
                            {
                                if(sa.No_Invoice__c)
                                {
                                    saliListToInsert.add(createSALI(sa.Id,sa.Contract_Home__c,sSmsEmplId,null,0,null,false));
                                }
                                else 
                                {  
                                    saliListToInsert.add(createSALI(sa.Id,sa.Contract_Home__c,sSmsEmplId,null,null,pricePerServId,false));
                                }
                            }
                        }
                        //Convocation Letter
                        if(numOfLetterToInvoicePerSaIdMap.get(sa.Id) > 0)
                        {
                            Id sLetterEmplId = getServiceIdFromPricing(servicePerVisitTypeMapFR,SERVICE_IDENTIFICATOR_LETTER);
                            for(Integer i=0;i<numOfLetterToInvoicePerSaIdMap.get(sa.Id);i++)
                            {
                                if(sa.No_Invoice__c)
                                {
                                    saliListToInsert.add(createSALI(sa.Id,sa.Contract_Home__c,sLetterEmplId,null,0,null,false));
                                }
                                else
                                {
                                    saliListToInsert.add(createSALI(sa.Id,sa.Contract_Home__c,sLetterEmplId,null,null,pricePerServId,false));
                                }
                            }
                        }
                        //Miscellaneous OAPPMEDCHECK-657
                        if(sa.Montant_Frais_divers__c!=null)
                        {
                            saliListToInsert.addAll(miscellaneousInvoicing(sa,servicePerVisitTypeMapFR,false));                                                                  
                        }
                        
                    }

                    //Mileage invoicing
                    if(sa.Km_mountain__c==null && sa.Km_Flat__c==null)
                    {
                        if(csliWithPrivilegedPack.contains(sa.Contractual_Service_Line_Item__c)) saInvoicingStatus.put(sa.Id,INVOICING_STATUS_PREPAYMENT);  
                    }
                    else 
                    {
                        saliListToInsert.addAll(mileageInvoicing(sa,kmInForfaitPerCtrId,servicePerVisitTypeMapFR,pricePerServId,false));
                    }
                }
                catch(Exception e)
                {
                    saliListToInsert = new List<Service_Appointment_Line_Item__c>(); 
                    String message = '';
                    if(e.getMessage().contains(Label.CanNotFindServiceInPricing) || e.getMessage().contains(Label.CanNotFindPriceInContract))
                    {
                           message = e.getMessage();
                    } 
                    else
                    {
                        message = Label.Error_system_Invoicing +' '+ e.getMessage();
                    }
                    errorTaskToInsert.add(generateTaskMCMQueue(sa.OwnerId,null,sa.Id,Label.ErrorDuringInvoiceDetailLines, message,1));
                    saInvoicingStatus.put(sa.Id,'E');  
                }
            }
            System.debug('QLE saliListToInsert' + saliListToInsert);
            if(!saliListToInsert.isEmpty())
            {
                saliSaveResult insertResult = insertSaliList(saToProcessForInvoice.keySet(),saliListToInsert);
                saInvoicingStatus.putAll(insertResult.saInvOrRemStatus); 
                errorTaskToInsert.addAll(insertResult.taskToInsert);
            }
        }
        System.debug('QLE saInvoicingStatus' + saInvoicingStatus);
        if(saInvoicingStatus!=null && !saInvoicingStatus.isEmpty()) setInvoicingStatus(saInvoicingStatus);
        if(!errorTaskToInsert.isEmpty())  Database.insert(errorTaskToInsert,false);

    }

    /*******************************************************************************
    * @author       Novera - QLE
    * @date         2022-03-10
    * @description  OAPPMEDCHECK-659 Setup invoice detail lines (doctor) for completed SA - France
    * @param        
    * @return       
    ********************************************************************************/
    public static void createRemunerationDetailLine(List<ServiceAppointment> recordList, Map<Id,ServiceAppointment> oldMap)
    {
        System.debug('QLE createRemunerationDetailLine');
        Map<Id,ServiceAppointment> saToProcessForRemuneration = new Map<Id,ServiceAppointment>();
        Set<Id> convIdSet = new Set<Id>();
        Map<Id,String> saRemunerationStatus =  new Map<Id,String>(); 
        List<Task> errorTaskToInsert = new List<Task>();
        Set<Id> saToRecalculateIds = new Set<Id>(); 
        contractInfoForInvoicing info = new contractInfoForInvoicing();
        Map<Id,Map<Id,Decimal>> pricePerServIdPerConvId = new Map<Id,Map<Id,Decimal>>();
        Map<Id,Decimal> kmInForfaitPerConvId = new Map<Id,Decimal>(); 

        //fillDoctorConvention(recordList,oldMap); //OAPPMEDCHECK-815

        for(ServiceAppointment sa : recordList)
        {
            if( (sa.Remuneration_Status__c==REMUNERATION_STATUS_INVOICE_DETAIL_LINE_TO_GENERATE && oldMap.get(sa.Id).Remuneration_Status__c!=REMUNERATION_STATUS_INVOICE_DETAIL_LINE_TO_GENERATE)
                || (sa.Remuneration_On_Hold__c==false && oldMap.get(sa.Id).Remuneration_On_Hold__c==true) 
                || (sa.No_Honoraria__c==false && oldMap.get(sa.Id).No_Honoraria__c==true) 
            )                   
            {
                System.debug('QLE sa.Doctor_Convention__c ' + sa.Doctor_Convention__c); 
                if(sa.Doctor_Convention__c!=null)
                {
                    convIdSet.add(sa.Doctor_Convention__c);
                    saToProcessForRemuneration.put(sa.Id,sa);
                    if((sa.Remuneration_On_Hold__c==false && oldMap.get(sa.Id).Remuneration_On_Hold__c==true) 
                        || (sa.No_Honoraria__c==false && oldMap.get(sa.Id).No_Honoraria__c==true))
                    {
                        saToRecalculateIds.add(sa.Id);
                    }
                }
                else {
                    errorTaskToInsert.add(generateTaskMCMQueue(sa.OwnerId,null,sa.Id,Label.ErrorDuringRemunerationDetailLines,Label.NoConventionFound,1));
                    saRemunerationStatus.put(sa.Id,'E');
                }  
            }
        }        

        //OAPPMEDCHECK-660 SA without invoicing or remuneration
        if(saToRecalculateIds!=null&&!saToRecalculateIds.isEmpty())
        {
            List<Service_Appointment_Line_Item__c> saliToDelete =  [SELECT Id FROM Service_Appointment_Line_Item__c
                                    WHERE Service_Appointment__c IN: saToRecalculateIds 
                                    AND Invoicing_type__c = :INVOICE_DETAIL_LINE_REMUNERATION_TYPE];
            if(!saliToDelete.isEmpty()) delete saliToDelete; 
        }

        if(!saToProcessForRemuneration.isEmpty())
        {
            Map<Id,Task> taskPerSaIdMap = checkInvoicingRecipientAndAccount(saToProcessForRemuneration.values(),true);
            if(!taskPerSaIdMap.isEmpty())
            {
                for(Id saId : taskPerSaIdMap.keySet())
                {
                    errorTaskToInsert.add(taskPerSaIdMap.get(saId));
                    saRemunerationStatus.put(saId,'E');
                    saToProcessForRemuneration.remove(saId);
                }
            }
        }

        List<Service_Appointment_Line_Item__c> saliListToInsert = new List<Service_Appointment_Line_Item__c>(); //Remuneration detail lines to insert
        
        if(convIdSet!=null)
        {
            info = getcontractInfoForInvoicing(convIdSet);//Get negotiated price from CSLI 
            pricePerServIdPerConvId = info.pricePerServIdPerCtrId;
            kmInForfaitPerConvId = info.kmInForfaitPerCtrId; 
        }

        // Id of services available for FR
        Map<String,Id> servicePerVisitTypeMapFR = servicePerVisitTypePerCountryMap.get('FR');
        for(ServiceAppointment sa : saToProcessForRemuneration.values())
        {       
            try
            {
                Map<Id,Decimal> pricePerServId = pricePerServIdPerConvId.get(sa.Doctor_Convention__c); 
                if(pricePerServId==null || pricePerServId.isEmpty())
                {
                    throw new CustomException(Label.CanNotFindPriceInConvention);
                }
    
                //Visit invoicing
                saliListToInsert.addAll(visitInvoicing(sa,servicePerVisitTypeMapFR,pricePerServId,true));
                
                //Mileage invoicing
                if(sa.Km_mountain__c!=null || sa.Km_Flat__c!=null)
                {
                    saliListToInsert.addAll(mileageInvoicing(sa,kmInForfaitPerConvId,servicePerVisitTypeMapFR,pricePerServId,true));
                }
                

                //Miscellaneous OAPPMEDCHECK-657
                if(sa.Montant_Frais_divers__c!=null)saliListToInsert.addAll(miscellaneousInvoicing(sa,servicePerVisitTypeMapFR,true));

                //OAPPMEDCHECK-749
                //if(sa.Extra_remuneration__c!=null) saliListToInsert.addAll(extraRemuneration(sa,servicePerVisitTypeMapFR,true));
            }
            catch(Exception e)
            {
                saliListToInsert = new List<Service_Appointment_Line_Item__c>(); 
                String message = '';
                if(e.getMessage().contains(Label.CanNotFindPriceInConvention)){
                       message = e.getMessage();
                   }
                else{
                    message = Label.Error_system_Invoicing +' '+ e.getMessage();
                }

                errorTaskToInsert.add(generateTaskMCMQueue(sa.OwnerId,null,sa.Id,Label.ErrorDuringRemunerationDetailLines, message,1));
                saRemunerationStatus.put(sa.Id,'E');  
            }
        }
        if(!saliListToInsert.isEmpty())
        {
            saliSaveResult insertResult = insertSaliList(saToProcessForRemuneration.keySet(),saliListToInsert);
            saRemunerationStatus.putAll(insertResult.saInvOrRemStatus); 
            errorTaskToInsert.addAll(insertResult.taskToInsert);
        }
        if(saRemunerationStatus!=null && !saRemunerationStatus.isEmpty()) setRemunerationStatus(saRemunerationStatus);
        if(!errorTaskToInsert.isEmpty())  Database.insert(errorTaskToInsert,false);
    }

    public static List<Service_Appointment_Line_Item__c> mileageInvoicing(ServiceAppointment sa, Map<Id,Decimal> kmInForfaitPerCtrId,Map<String,Id> servicePerVisitTypeMapFR,Map<Id,Decimal> pricePerServId,Boolean isForRemuneration)
    {
        List<Service_Appointment_Line_Item__c> saliListToInsert = new List<Service_Appointment_Line_Item__c>();
        
        Decimal kmInForfait;
        Decimal pricePerMoutainKm;
        Decimal pricePerFlatKm;
        Id mountainKmServiceId = getServiceIdFromPricing(servicePerVisitTypeMapFR,SERVICE_IDENTIFICATOR_MOUNTAIN);
        Id flatKmServiceId = getServiceIdFromPricing(servicePerVisitTypeMapFR,SERVICE_IDENTIFICATOR_FLAT);
        Decimal kmMountainToInvoice = 0;
        Decimal kmFlatToInvoice = 0;
        if(isForRemuneration)
        {
            Id convId = sa.Doctor_Convention__c;
            kmInForfait = kmInForfaitPerCtrId.get(convId);
            if(kmInForfait > 0)
            {
                if(sa.Km_mountain__c!=null && sa.Km_mountain__c > kmInForfait)
                {
                    kmMountainToInvoice = sa.Km_mountain__c - kmInForfait;
                    if(sa.Km_flat__c!=null && sa.Km_flat__c > 0){
                        kmFlatToInvoice = sa.Km_flat__c;
                    }                               
                }
                else if(sa.Km_mountain__c!=null && sa.Km_mountain__c <= kmInForfait)
                {
                    if(sa.Km_flat__c!=null && sa.Km_flat__c > 0){
                        Decimal kmTotal = sa.Km_mountain__c + sa.Km_flat__c;
                        if(kmTotal > kmInforfait){
                            kmFlatToInvoice = kmTotal - kmInforfait;
                        }                               
                    }
                }
                else 
                {
                    if(sa.Km_flat__c!=null && sa.Km_flat__c > 0)
                    {
                        if(sa.Km_flat__c > kmInforfait){
                            kmFlatToInvoice = sa.Km_flat__c - kmInforfait;
                        }                               
                    }
                }
            }
            else
            {
                kmMountainToInvoice = sa.Km_mountain__c!=null?sa.Km_mountain__c:0;
                kmFlatToInvoice = sa.Km_flat__c!=null?sa.Km_flat__c:0;
            }
        }
        else 
        {
            kmInForfait = kmInForfaitPerCtrId.get(sa.Contract_Home__c);
            pricePerMoutainKm = getPriceFromContract(pricePerServId,mountainKmServiceId,isForRemuneration);
            pricePerFlatKm = getPriceFromContract(pricePerServId,flatKmServiceId,isForRemuneration);
            if(kmInForfait > 0)
            {
                if(sa.Km_flat__c!=null && sa.Km_flat__c > kmInForfait)
                {               
                    kmFlatToInvoice = sa.Km_flat__c - kmInForfait;
                    if(sa.Km_mountain__c!=null && sa.Km_mountain__c > 0){
                        kmMountainToInvoice = sa.Km_mountain__c;
                    }       
                }
                else if(sa.Km_flat__c!=null && sa.Km_flat__c <= kmInForfait)
                {        
                    if(sa.Km_mountain__c!=null && sa.Km_mountain__c > 0)
                    {
                        Decimal kmTotal = sa.Km_flat__c + sa.Km_mountain__c;
                        if(kmTotal > kmInforfait)
                        {
                            kmMountainToInvoice = kmTotal - kmInforfait;
                        }                               
                    }
                }
                else
                {
                    if(sa.Km_mountain__c!=null && sa.Km_mountain__c > 0)
                    {
                        if(sa.Km_mountain__c > kmInforfait)
                        {
                            kmMountainToInvoice = sa.Km_mountain__c - kmInforfait;
                        }                               
                    }
                }
            }
            else
            {
                kmFlatToInvoice = sa.Km_flat__c!=null?sa.Km_flat__c:0;
                kmMountainToInvoice = sa.Km_mountain__c!=null?sa.Km_mountain__c:0;
            }
        }
        if(kmMountainToInvoice >0)
        {
            Decimal amt;
            pricePerMoutainKm = getPriceFromContract(pricePerServId,mountainKmServiceId,isForRemuneration);
            if( (isForRemuneration && sa.No_Honoraria__c) || (!isForRemuneration && sa.No_Invoice__c)){
                amt=0;
            }
            else {
                amt=kmMountainToInvoice*pricePerMoutainKm;
            }
            Service_Appointment_Line_Item__c saliToCreate = createSALI(sa.Id,sa.Contract_Home__c,mountainKmServiceId,null,amt,pricePerServId,isForRemuneration);
            if(isForRemuneration)
            {
                saliToCreate.TECH_Km__c=sa.No_Honoraria__c?0:kmMountainToInvoice;
            }
            else
            {
                saliToCreate.TECH_Km__c=sa.No_Invoice__c?0:kmMountainToInvoice;
            }
            saliListToInsert.add(saliToCreate);
        }
    
        if(kmFlatToInvoice >0)
        {
            Decimal amt;
            pricePerFlatKm = getPriceFromContract(pricePerServId,flatKmServiceId,isForRemuneration);
            if( (isForRemuneration&& sa.No_Honoraria__c) || (!isForRemuneration && sa.No_Invoice__c)){
                amt=0;
            }
            else {
                amt=kmFlatToInvoice*pricePerFlatKm;
            }
            Service_Appointment_Line_Item__c saliToCreate = createSALI(sa.Id,sa.Contract_Home__c,flatKmServiceId,null,amt,pricePerServId,isForRemuneration);
            if(isForRemuneration)
            {
                saliToCreate.TECH_Km__c=sa.No_Honoraria__c?0:kmFlatToInvoice;
            }
            else
            {
                saliToCreate.TECH_Km__c=sa.No_Invoice__c?0:kmFlatToInvoice;
            }
            saliListToInsert.add(saliToCreate);
        }
        return saliListToInsert; 
    }

    public static List<Service_Appointment_Line_Item__c> visitInvoicing(ServiceAppointment sa,Map<String,Id> servicePerVisitTypeMapFR,Map<Id,Decimal> pricePerServId,Boolean isForRemuneration)
    {
        List<Service_Appointment_Line_Item__c> saliListToInsert = new List<Service_Appointment_Line_Item__c>();
        System.debug('QLE visitInvoicing ' + servicePerVisitTypeMapFR);
        Id sWeekendId = getServiceIdFromPricing(servicePerVisitTypeMapFR,SERVICE_IDENTIFICATOR_WEEKEND);
        Id ctrHomeId = isForRemuneration==true?sa.Doctor_Convention__c:sa.Contract_Home__c;
        String dayOfWeek;
        //Home Visit Invoicing
        if(sa.Home_Visit__c==true)
        {
            Id sHomeVisitId = getServiceIdFromPricing(servicePerVisitTypeMapFR,SERVICE_IDENTIFICATOR_HOME_VISIT);
            if( (isForRemuneration && sa.No_Honoraria__c) || (!isForRemuneration && sa.No_Invoice__c))
            {
                saliListToInsert.add(createSALI(sa.Id,ctrHomeId,sHomeVisitId,null,0,null,isForRemuneration));
            }
            else 
            {
                saliListToInsert.add(createSALI(sa.Id,ctrHomeId,sHomeVisitId,null,null,pricePerServId,isForRemuneration));
            }
 
            if(sa.Weekend_Supplement__c&&sa.Date_Time_Home_Visit__c!=null) dayOfWeek = sa.Date_Time_Home_Visit__c!=null?sa.Date_Time_Home_Visit__c.format('EEEE'):null;
        }
        //Convocation Invoicing
        else if(sa.Convocation__c==true)
        {
            Id sOfficeVisitId = getServiceIdFromPricing(servicePerVisitTypeMapFR,SERVICE_IDENTIFICATOR_CONVOCATION);
            if((isForRemuneration && sa.No_Honoraria__c) || (!isForRemuneration && sa.No_Invoice__c))
            {
                saliListToInsert.add(createSALI(sa.Id,ctrHomeId,sOfficeVisitId,null,0,null,isForRemuneration));
            }
            else 
            {
                saliListToInsert.add(createSALI(sa.Id,ctrHomeId,sOfficeVisitId,null,null,pricePerServId,isForRemuneration));
            }
            if(sa.Weekend_Supplement__c&&sa.Date_Time_convocation__c!=null) dayOfWeek = sa.Date_Time_convocation__c.format('EEEE');
        }
        if(sa.Weekend_Supplement__c && (dayOfWeek=='Saturday'||dayOfWeek=='Sunday')) //OAPPMEDCHECK-941
        {
            if((isForRemuneration && sa.No_Honoraria__c) || (!isForRemuneration && sa.No_Invoice__c))
            {
                saliListToInsert.add(createSALI(sa.Id,ctrHomeId,sWeekendId,null,0,null,isForRemuneration));

            }
            else 
            {
                saliListToInsert.add(createSALI(sa.Id,ctrHomeId,sWeekendId,null,null,pricePerServId,isForRemuneration));
            }
        }
        return saliListToInsert; 
    }

    public static List<Service_Appointment_Line_Item__c> miscellaneousInvoicing(ServiceAppointment sa,Map<String,Id> servicePerVisitTypeMapFR,Boolean isForRemuneration)
    {
        //Miscellaneous OAPPMEDCHECK-657
        List<Service_Appointment_Line_Item__c> saliListToInsert = new List<Service_Appointment_Line_Item__c>();
        Id miscId = getServiceIdFromPricing(servicePerVisitTypeMapFR,SERVICE_IDENTIFICATOR_MISC);
        Id ctrHomeId = isForRemuneration==true?sa.Doctor_Convention__c:sa.Contract_Home__c;
        Decimal amt;
        if((isForRemuneration && sa.No_Honoraria__c) || (!isForRemuneration && sa.No_Invoice__c)){
            amt = 0;
        }
        else {
            amt = sa.Montant_Frais_divers__c;
        }
        saliListToInsert.add(createSALI(sa.Id,ctrHomeId,miscId,null,amt,null,isForRemuneration));                                                                    
        return saliListToInsert; 
    }

    /*
    OAPPMEDCHECK-941
    public static List<Service_Appointment_Line_Item__c> extraRemuneration(ServiceAppointment sa,Map<String,Id> servicePerVisitTypeMapFR,Boolean isForRemuneration)
    {
        //OAPPMEDCHECK-749
        List<Service_Appointment_Line_Item__c> saliListToInsert = new List<Service_Appointment_Line_Item__c>();
        Id sWeekendId = getServiceIdFromPricing(servicePerVisitTypeMapFR,SERVICE_IDENTIFICATOR_WEEKEND);
        Decimal amt;
        if(isForRemuneration && sa.No_Honoraria__c){
            amt = 0;
        }
        else {
            amt = sa.Extra_remuneration__c;
        }
        saliListToInsert.add(createSALI(sa.Id,sa.Doctor_Convention__c,sWeekendId,null,amt,null,isForRemuneration));                                                                    
        return saliListToInsert; 
    }
    */

    public static  saliSaveResult  insertSaliList(Set<Id> saWithoutError,List<Service_Appointment_Line_Item__c> saliListToInsert)
    {
        saliSaveResult saliSR = new saliSaveResult();
        Map<Id,String> saInvOrRemStatus = new  Map<Id,String>();
        List<Task> errorTaskToInsert = new List<Task> ();
        Database.SaveResult[] saveResults = Database.insert(saliListToInsert,false);
        for(Integer idx = 0; idx < saveResults.size(); idx++)
        {   
            Service_Appointment_Line_Item__c sali = saliListToInsert[idx];
            if (!saveResults[idx].isSuccess())
            {
                saWithoutError.remove(sali.Service_Appointment__c);
                String errText;
                for(Database.Error err : saveResults[idx].getErrors()) 
                {
                    errText = err.getMessage() + ' ';
                }        
                errorTaskToInsert.add(generateTaskMCMQueue(null,'FR',sali.Service_Appointment__c
                        ,Label.ErrorDuringInvoiceDetailLines,errText,1));
                saInvOrRemStatus.put(sali.Service_Appointment__c,'E');
            }
            for(Id saId : saWithoutError)
            {
                saInvOrRemStatus.put(saID,'S');
            }
        }
        saliSR.saInvOrRemStatus = saInvOrRemStatus;
        saliSR.taskToInsert = errorTaskToInsert;
        return saliSR;
    }
    

    public static contractInfoForInvoicing getContractInfoForInvoicing(Set<Id> ctrIdSet)
    {
        contractInfoForInvoicing info = new contractInfoForInvoicing();
        Map<Id,Decimal> kmInForfaitPerCtrId = new Map<Id,Decimal>(); 
        Map<Id,Map<Id,Decimal>> pricePerServIdPerCtrId = new Map<Id,Map<Id,Decimal>>();
        //Set<Id> ctrWithPrivilegedPack = new Set<Id>(); 
        Set<Id> csliWithPrivilegedPack = new Set<Id>(); 
        for(Contract_Home__c ctr : [SELECT Id, Amount_of_km_in_forfait__c
                                        ,(SELECT Price_Rate_1__c, Service__c, Service__r.Pack_Type__c FROM Contractual_Service_Line_Items__r)
                                    FROM Contract_Home__c WHERE Id IN:ctrIdSet])
        {
            if(ctr.Amount_of_km_in_forfait__c!=null)
            {
                kmInForfaitPerCtrId.put(ctr.Id,ctr.Amount_of_km_in_forfait__c);
            }
            else
            {
                kmInForfaitPerCtrId.put(ctr.Id,0);
            }
            Map<Id,Decimal> pricePerServiceId = new Map<Id,Decimal>();
            for(Contractual_Service_Line_Item__c csli : ctr.Contractual_Service_Line_Items__r)
            {
                pricePerServiceId.put(csli.Service__c,csli.Price_Rate_1__c);
                if(csli.Service__r.Pack_Type__c=='Privileged') csliWithPrivilegedPack.add(csli.Id);
            }
            pricePerServIdPerCtrId.put(ctr.Id,pricePerServiceId);
        }
        info.kmInForfaitPerCtrId = kmInForfaitPerCtrId;
        info.pricePerServIdPerCtrId = pricePerServIdPerCtrId;
        info.csliWithPrivilegedPack = csliWithPrivilegedPack;
        return info;
    }

    @future
    public static void setInvoicingStatus(Map<Id,String> statusPerSaIds)
    {
        List<ServiceAppointment> saList = new List<ServiceAppointment>();
        Set<Id> saIds = new Set<Id>(); 
        for(ServiceAppointment sa : [SELECT Id, Invoicing_Status__c, No_Invoice__c FROM ServiceAppointment WHERE Id IN:statusPerSaIds.keySet()])
        {
            if(statusPerSaIds.get(sa.Id)=='S')
            {
                if(sa.No_Invoice__c)
                {
                    sa.Invoicing_Status__c=INVOICING_STATUS_NO_INVOICING;
                    saList.add(sa);
                    saIds.add(sa.Id);
                }
                else
                {
                    sa.Invoicing_Status__c=INVOICING_STATUS_INVOICE_DETAIL_LINE_GENERATED;
                    saList.add(sa);
                    saIds.add(sa.Id);
                }
            }
            else if(statusPerSaIds.get(sa.Id)=='E')
            {
                sa.Invoicing_Status__c=INVOICING_STATUS_INVOICE_DETAIL_LINE_ERROR;
                sa.Invoicing_On_Hold__c = true;
                saList.add(sa);
            }
            else
            {
                sa.Invoicing_Status__c = statusPerSaIds.get(sa.Id); 
                saList.add(sa);
                saIds.add(sa.Id);
            }
        }
        if(!saList.isEmpty()) update saList;
        if(saIds!=null && !saIds.isEmpty()) updateARinvoicingStatus(saIds);
    }

    @future
    public static void setRemunerationStatus(Map<Id,String> statusPerSaIds)
    {
        List<ServiceAppointment> saList = new List<ServiceAppointment>();
        for(ServiceAppointment sa : [SELECT Id, Remuneration_Status__c, No_Honoraria__c FROM ServiceAppointment WHERE Id IN:statusPerSaIds.keySet()])
        {
            if(statusPerSaIds.get(sa.Id)=='S')
            {
                if(sa.No_Honoraria__c)
                {
                    sa.Remuneration_Status__c=REMUNERATION_STATUS_NO_REMUNERATION;
                    saList.add(sa);
                }
                else
                {
                    sa.Remuneration_Status__c=REMUNERATION_STATUS_INVOICE_DETAIL_LINE_GENERATED;
                    saList.add(sa);
                }
            }
            else{
                sa.Remuneration_Status__c=REMUNERATION_STATUS_INVOICE_DETAIL_LINE_ERROR;
                sa.Remuneration_On_Hold__c = true;
                saList.add(sa);
            }
        }
        update saList;
    }

    /*******************************************************************************
    * @author       Novera - QLE
    * @date         2020-12-03
    * @description  OAPPMEDCHECK-343 Setup invoice detail lines for completed WO    
    ********************************************************************************/
    public static Service_Appointment_Line_Item__c createSALI(Id saId, Id ctrId, Id serviceId, Map<Id,String> doctorNamePerSaIdMap, Decimal amt, Map<Id,Decimal> pricePerServId,Boolean isDoctorRemuneration)
    {
        System.debug('QLE createSALI serviceId ' + serviceId); 
        Decimal detailLineAmount = amt;
        if(amt==null){
            detailLineAmount = pricePerServId.get(serviceId);
            if(detailLineAmount==null){ 
                String customMess = isDoctorRemuneration?Label.CanNotFindPriceInConvention:Label.CanNotFindPriceInContract;
                throw new CustomException(customMess);
            }
        }

        String invoicingType;
        if(isDoctorRemuneration){
            invoicingType = INVOICE_DETAIL_LINE_REMUNERATION_TYPE;
        }else {
            invoicingType = INVOICE_DETAIL_LINE_CI_TYPE;
        }


        Service_Appointment_Line_Item__c sali = new Service_Appointment_Line_Item__c(Service_Appointment__c=saId
                                                                    ,Service__c = serviceId
                                                                    ,Name_doctor__c = doctorNamePerSaIdMap!=null?doctorNamePerSaIdMap.get(saId):''
                                                                    ,Amount__c = amt==null?detailLineAmount:amt
                                                                    ,Unit_Price__c = pricePerServId!=null?pricePerServId.get(serviceId):null
                                                                    ,Invoicing_Type__c = invoicingType );
        return sali;
    }

    /*******************************************************************************
    * @author       Novera - QLE
    * @date         2020-12-03
    * @description  OAPPMEDCHECK-343 Setup invoice detail lines for completed WO    
    ********************************************************************************/
    public static Id getServiceIdFromPricing(Map<String,Id> servicePerVisitTypeMap , String serviceIdentifier)
    {
        Id sId = servicePerVisitTypeMap!=null?servicePerVisitTypeMap.get(serviceIdentifier):null; 
        if(sId==null){ 
            throw new CustomException(Label.CanNotFindServiceInPricing + ' ' + serviceIdentifier);
        }
        return sId;
    }

    /******************************************************************************
    * @author       Novera - QLE
    * @date         2020-12-03
    * @description  OAPPMEDCHECK-343 Setup invoice detail lines for completed WO    
    ********************************************************************************/
    public static Decimal getPriceFromContract(Map<Id,Decimal> pricePerServIdMap, Id sId, Boolean isForRemuneration)
    {
        System.debug('QLE getPriceFromContract sId ' + sId);
        System.debug('QLE isForRemuneration ' + isForRemuneration);
        Decimal priceFromContract = pricePerServIdMap!=null?pricePerServIdMap.get(sId):null; // Price for the service from the contract
        if(priceFromContract==null){ 
            if(isForRemuneration){
                throw new CustomException(Label.CanNotFindPriceInConvention + ' : ' + serviceNamePerIdMap.get(sId));
            }
            else{
                throw new CustomException(Label.CanNotFindPriceInContract + ' : ' + serviceNamePerIdMap.get(sId));
            }
        }
        return priceFromContract;
    }

    /*******************************************************************************
    * @author       Novera - QLE
    * @date         2020-12-03
    * @description  
    * @param        
    * @return       
    ********************************************************************************/
    public static void updateZipCode(List<ServiceAppointment> recordList, Map<Id, ServiceAppointment> oldMap)
    {
        for(ServiceAppointment sa : recordList)
        {
            if(oldMap!=null)
            {
                if(sa.PostalCode!=null && sa.PostalCode!=oldMap.get(sa.Id).PostalCode)
                {
                    sa.Zip_Code__c = ZipCodeIdPerNameMap.containsKey(sa.PostalCode)?ZipCodeIdPerNameMap.get(sa.PostalCode):null;
                }
            }
            else
            {
                Map<Id,String> saZipCodeMap =  new Map<Id,String>(); 
                if(sa.PostalCode!=null)
                {
                    saZipCodeMap.put(sa.Id,sa.PostalCode);
                }
                if(!saZipCodeMap.isEmpty()) updateZipCode(saZipCodeMap); 
            }
        }
    }

    /*******************************************************************************
    * @author       Novera - QLE
    * @date         2020-12-03
    * @description  
    * @param        
    * @return       
    ********************************************************************************/
    @future
    public static void updateZipCode(Map<Id,String> saZipCodeMap)
    {
        List<ServiceAppointment> saList = new List<ServiceAppointment>();
        for(Id saId : saZipCodeMap.keySet())
        {
            ServiceAppointment sa = new ServiceAppointment(Id=saId,Zip_Code__c= ZipCodeIdPerNameMap.get(saZipCodeMap.get(saId)));
            saList.add(sa);
        }
        update saList;
    }



    /*******************************************************************************
    * @author       Novera - QLE
    * @date         2020-12-03
    * @description  OAPPMEDCHECK-343 An operator, on the error verified, can uncheck Invoicing On Hold, 
    *               this changes the  SA to status ‘Invoice Detail Line generated’ and the related AR to ‘Invoice to generate’ 
    *               (if all related SAs are in status ‘Invoice Detail Line generated’) 
    * @param        
    * @return       
    ********************************************************************************/
    public static void updateInvoicingAndRemunerationStatus(List<ServiceAppointment> recordList, Map<Id, ServiceAppointment> oldMap)
    {
        List<Absence_Registration__c> absRegToUpdate = new List<Absence_Registration__c>();
        for(ServiceAppointment sa : recordList)
        {
            if((sa.Status==STATUS_RESULT_TO_CUSTOMER && oldMap.get(sa.Id).Status!=STATUS_RESULT_TO_CUSTOMER)
            || (sa.Status==STATUS_CANNOT_COMPLETE && oldMap.get(sa.Id).Status!=STATUS_CANNOT_COMPLETE))
            {                
                if(sa.Invoicing_Status__c!=INVOICING_STATUS_INVOICE_DETAIL_LINE_GENERATED)
                {
                    sa.Invoicing_Status__c = INVOICING_STATUS_INVOICE_DETAIL_LINE_TO_GENERATE;
                }
                if(sa.Remuneration_Status__c!=REMUNERATION_STATUS_INVOICE_DETAIL_LINE_GENERATED)
                {
                    sa.Remuneration_Status__c = REMUNERATION_STATUS_INVOICE_DETAIL_LINE_TO_GENERATE;
                }
                sa.TECH_Close_Date__c = System.today();
                fillDoctorConvention(recordList,oldMap); //OAPPMEDCHECK-815
                
            }
        }
    }

    /*********************************************************************************************************
    * @author        Novera - QLE
    * @date          2020 December 12
    * @description   Triggers to start creating invoice detail lines and invoices - FR
    * @RelatedUS     OAPPMEDCHECK-388
    * @return        void
    ********************************************************************************************************/
    public static void updateARinvoicingStatus(Set<Id> saIds)
    {
        Set<Id> absRegIds = new Set<Id>();
        Set<Id> absRegWithPackIds = new Set<Id>();
        Map<Id,Integer> notClosedSaCountPerArIdMap = new Map<Id,Integer>();
        Map<Id,Integer> saToInvoicePerArIdMap = new Map<Id,Integer>();
        List<Absence_Registration__c> absRegToUpdate = new List<Absence_Registration__c>();
        for(ServiceAppointment sa : [SELECT Absence_Registration__c,  Absence_Registration__r.Is_Contract_Pack__c 
                                    FROM ServiceAppointment WHERE Id IN:saIds ])
        {
            absRegIds.add(sa.Absence_Registration__c);
            if(sa.Absence_Registration__r.Is_Contract_Pack__c)
            {
                absRegWithPackIds.add(sa.Absence_Registration__c);
            }
        }
        if(absRegIds!=null&&!absRegIds.isEmpty()) notClosedSaCountPerArIdMap = getNotClosedSaCountPerAbsReg(absRegIds);
        if(absRegWithPackIds!=null&&!absRegWithPackIds.isEmpty()) saToInvoicePerArIdMap = getSaToInvoicePerAbsReg(absRegWithPackIds);

        for(Absence_Registration__c ar : [SELECT Id,Is_Contract_Pack__c,Contract_Home__c,Invoicing_Account__c 
                                                    ,RecordType.DeveloperName, Status__c
                                        FROM Absence_Registration__c WHERE Id IN:absRegIds])
        {
            if(ar.Status__c==AbsenceRegistrationManager.STATUS_RESULT_TO_CUSTOMER)
            {
                if(notClosedSaCountPerArIdMap.get(ar.Id) == null)
                {
                    if(ar.Is_Contract_Pack__c && saToInvoicePerArIdMap.get(ar.Id) == null)
                    {
                        ar.Invoicing_Status__c=StaticConstants.AR_INVOICING_STATUS_PREPAYMENT;
                        absRegToUpdate.add(ar);
                    }
                    else
                    {
                        ar.Invoicing_Status__c=StaticConstants.AR_INVOICING_STATUS_INVOICE_TO_GENERATE;
                        ar.TECH_Close_Date__c = System.today();
                        if(Test.isRunningTest())
                        {
                            ar.TECH_Close_Date__c = System.today().addMonths(-1);
                        }
                        absRegToUpdate.add(ar);
                    }
                }
            }
            
        }
        if(!absRegToUpdate.isEmpty())
        {
            Database.SaveResult[] updateResult =  Database.update(absRegToUpdate,false); 
            for(Integer idx = 0; idx < updateResult.size(); idx++)
            {   
                String message='';
                if (!updateResult[idx].isSuccess()) 
                {
                    String errText='';
                    for(Database.Error err : updateResult[idx].getErrors()) 
                    {
                        errText = errText + ' ' + err.getMessage();
                        System.debug('ServiceAppointmentManger.updateARinvoicingStatus() ' + errText);
                    }  
                }
            }
        }
    }

    /*******************************************************************************
    * @author       Novera - QLE
    * @date         2020-04-19
    * @description  OAPPMEDCHECK-754 Creation invoices - changes due to big accounts
    * @param        List<ServiceAppointment> list of SAs 
    * @return       voice
    ********************************************************************************/
    
    public static Map<Id,Task> checkInvoicingRecipientAndAccount(List<ServiceAppointment> saToProcess, Boolean isDoctorRemuneration )
    {   
        Map<Id,Task> taskPerSaId = new Map<Id,Task>();
        Set<Id> invAccIds = new Set<Id>();
        Map<Id,Id> invAccPerCtrId = new Map<Id,Id>();
        Map<Id,Id> recipientIdPerInvAccIdMap = new Map<Id,Id>();
        Set<Id> assResIds = new Set<Id>();
        Map<Id,Id> docIdPerServRedId = new Map<Id,Id>();
        Map<Id,Id> recipientIdPerDocIdMap = new Map<Id,Id>();
        for(ServiceAppointment sa : saToProcess)
        {
            if(!isDoctorRemuneration) invAccIds.add(sa.TECH_Invoicing_Account__c);
            if(isDoctorRemuneration) assResIds.add(sa.Assigned_Resource__c);
        }
        if(!invAccIds.isEmpty())
        {
            for(AccountContactRelation acr : [SELECT  AccountId, ContactId FROM AccountContactRelation 
                WHERE AccountId IN:invAccIds  AND (Invoicing_recipient_email__c=TRUE OR Invoicing_recipient_post__c=TRUE)])
            {
                recipientIdPerInvAccIdMap.put(acr.AccountId,acr.ContactId);
            }
            for(ServiceAppointment sa : saToProcess)
            {
                if(sa.TECH_Invoicing_Account__c==null)
                {
                    taskPerSaId.put(sa.Id,generateTaskMCMQueue(sa.OwnerId,null,sa.Id,Label.ErrorDuringInvoiceDetailLines,Label.NoInvoicingAccountOnAbsence,1));
                }
                else 
                {
                    if(sa.Absence_Registration_RT__c=='FR') //OAPPMEDCHECK-832
                    {
                        Id contactId = recipientIdPerInvAccIdMap!=null?recipientIdPerInvAccIdMap.get(sa.TECH_Invoicing_Account__c):null;
                        if(contactId==null)
                        {
                            taskPerSaId.put(sa.Id,generateTaskMCMQueue(sa.OwnerId,null,sa.Id,Label.ErrorDuringInvoiceDetailLines,Label.NoInvoicingContactForSA,1));
                        }
                    }
                }
            }
        }
        if(!assResIds.isEmpty())
        {
            for(ServiceResource sr : [SELECT AccountId FROM ServiceResource WHERE Id IN:assResIds])
            {
                if(sr.AccountId!=null) 
                {
                    docIdPerServRedId.put(sr.Id,sr.AccountId);
                }
            }
            for(Contact c : [SELECT Id, AccountId FROM Contact WHERE AccountId IN:docIdPerServRedId.values()])
            {
                recipientIdPerDocIdMap.put(c.AccountId,c.Id);
            }
            for(ServiceAppointment sa : saToProcess)
            {
               
                Id docId =  docIdPerServRedId.get(sa.Assigned_Resource__c);
                if(docId==null)
                {
                    taskPerSaId.put(sa.Id,generateTaskMCMQueue(sa.OwnerId,null,sa.Id,Label.ErrorDuringInvoiceDetailLines,Label.noDoctorOnServiceResource,1));
                }
                else
                {
                    Id contactId = recipientIdPerDocIdMap!=null?recipientIdPerDocIdMap.get(docId):null;
                    if(contactId==null)
                    {
                        taskPerSaId.put(sa.Id,generateTaskMCMQueue(sa.OwnerId,null,sa.Id,Label.ErrorDuringInvoiceDetailLines ,Label.NoContactDoctorRemuneration,1));
                    }   
                }
            }
        }
        return taskPerSaId;
    }

    /*********************************************************************************************************
    * @author        Novera - QLE
    * @date          2020 December 12
    * @description   Triggers to start creating invoice detail lines and invoices - FR
    * @RelatedUS     OAPPMEDCHECK-388
    * @return        void
    ********************************************************************************************************/
    public static Map<Id,Integer> getNotClosedSaCountPerAbsReg(Set<Id> absRegIds)
    {
        Map<Id,Integer> notClosedSaCountPerArIdMap = new Map<Id,Integer>();
        for (AggregateResult agg : [ SELECT count(Id) closedSaCount, Absence_Registration__c FROM ServiceAppointment
                WHERE Invoicing_Status__c !=:INVOICING_STATUS_INVOICE_DETAIL_LINE_GENERATED 
                AND Invoicing_Status__c !=:INVOICING_STATUS_PREPAYMENT  AND Invoicing_Status__c !=:INVOICING_STATUS_NO_INVOICING AND Absence_Registration__c IN:absRegIds
                GROUP BY Absence_Registration__c]) 
        {
            notClosedSaCountPerArIdMap.put(String.valueOf(agg.get('Absence_Registration__c')), Integer.valueOf(agg.get('closedSaCount')));
        }
        return notClosedSaCountPerArIdMap;
    }

    public static Map<Id,Integer> getSaToInvoicePerAbsReg(Set<Id> absRegIds)
    {
        Map<Id,Integer> saToInvoiceCountPerArIdMap = new Map<Id,Integer>();
        for (AggregateResult agg : [
                SELECT count(Id) saCount, Absence_Registration__c
                FROM ServiceAppointment
                WHERE Invoicing_Status__c =:INVOICING_STATUS_INVOICE_DETAIL_LINE_GENERATED  
                    AND Absence_Registration__c IN:absRegIds
                GROUP BY Absence_Registration__c
        ]) {
            saToInvoiceCountPerArIdMap.put(String.valueOf(agg.get('Absence_Registration__c')), Integer.valueOf(agg.get('saCount')));
        }
        return saToInvoiceCountPerArIdMap;
    }
    

    /*******************************************************************************
    * @author       Novera - JFO
    * @date         2021-06-10
    * @description  Display information to doctor in the portal in the SR's native language
    * @param        
    * @return       
    ********************************************************************************/

    public static void fillSAwithInfoToDoctor(List<ServiceAppointment> recordList, Map<Id, ServiceAppointment> recordOldValueMap)
      {
          
        Set<Id> workOrderIds  = new Set<Id>();
        Set<Id> serviceResIds = new Set<Id>();
        
        String account_Info_ToDoctor  = '';
        String employee_Info_ToDoctor = '';
        String absence_Info_ToDoctor  = '';
        String accountAdditionalInfo  = 'Account informatie / Information compte';
        String employeeAdditionalInfo = 'Werknemer informatie / Information salarié';
        String absenceAdditionalInfo  = 'Afwezigheidsinformatie / Information Absence';
        
        for (ServiceAppointment sa : recordList)            
        {
            if(sa.Assigned_Resource__c!=null && sa.Assigned_Resource__c!=recordOldValueMap.get(sa.Id).Assigned_Resource__c)
            {
                workOrderIds.add(sa.Work_Order_tech__c);
                serviceResIds.add(sa.Assigned_Resource__c);
            }
        }
        
        
        if(!serviceResIds.isEmpty() && !workOrderIds.isEmpty())
        {  
            Map<Id, ServiceResource> srByIdMap = new Map<Id, ServiceResource>([SELECT Id
                                                                        , IsActive
                                                                        , Native_Language__c
                                                             FROM ServiceResource
                                                             WHERE Id IN :serviceResIds]);
            
            Map<Id, WorkOrder> woByIdMap = new Map<Id, WorkOrder>([SELECT Id
                                                                        , Absence_Registration__r.Additional_information__c 
                                                                        , Employee__r.Information_to_doctors__c
                                                                        , Account.Information_to_doctors_FR__c
                                                                        , Account.Information_to_doctors_NL__c
                                                                        , Absence_Registration__r.Contract_Home__r.Information_to_doctors_FR__c
                                                                        , Absence_Registration__r.Contract_Home__r.Information_to_doctors_NL__c
                                                                FROM WorkOrder
                                                                WHERE Id IN :workOrderIds]);
        
            for (ServiceAppointment sa : recordList)
            {
                if(woByIdMap.containsKey(sa.ParentRecordId) && srByIdMap.containsKey(sa.Assigned_Resource__c))
                {
                    WorkOrder wo = woByIdMap.get(sa.ParentRecordId);
                    ServiceResource sr = srByIdMap.get(sa.Assigned_Resource__c);
                                      
                    if(sr.Native_Language__c!=null)
                    {
                        if(sr.Native_Language__c == 'French')
                        {                
                            if (!String.isBlank(wo.Account.Information_to_doctors_FR__c))
                            {
                                account_Info_ToDoctor = wo.Account.Information_to_doctors_FR__c;
                            }    
                            else if (!String.isBlank(wo.Absence_Registration__r.Contract_Home__r.Information_to_doctors_FR__c))
                            {  
                                account_Info_ToDoctor = wo.Absence_Registration__r.Contract_Home__r.Information_to_doctors_FR__c;
                            }  
                        }
            
                        else if(sr.Native_Language__c == 'Dutch')
                        {                
                            if (!String.isBlank(wo.Account.Information_to_doctors_NL__c))
                            {
                                account_Info_ToDoctor = wo.Account.Information_to_doctors_NL__c;
                            }    
                            else if (!String.isBlank(wo.Absence_Registration__r.Contract_Home__r.Information_to_doctors_NL__c))
                            {  
                                account_Info_ToDoctor = wo.Absence_Registration__r.Contract_Home__r.Information_to_doctors_NL__c;
                            }  
                        }
                    }
                             
                    absence_Info_ToDoctor =  (String.isBlank(wo.Absence_Registration__r.Additional_information__c)? '' : wo.Absence_Registration__r.Additional_information__c);       
                    employee_Info_ToDoctor = (String.isBlank(wo.Employee__r.Information_to_doctors__c)? '' : wo.Employee__r.Information_to_doctors__c);
                                
                    sa.Additional_information__c = '<p><strong><u>'+absenceAdditionalInfo+'</u></strong></p>'  +
                                                   absence_Info_ToDoctor  +
                                                   '<p></p>'+
                                                   '<p><strong><u>'+employeeAdditionalInfo+'</u></strong></p>' +
                                                   employee_Info_ToDoctor +
                                                   '<p></p>'+
                                                   '<p><strong><u>'+accountAdditionalInfo+'</u></strong></p>' +
                                                   account_Info_ToDoctor 
                                                   ;                      
                            
                }
            }
        }  
    }    

    /*******************************************************************************
    * @author       Novera - QLE
    * @date         2020-12-03
    * @description  
    * @param        
    * @return       
    ********************************************************************************/
      public static void fillServiceAppointmentWithAbsenceData(List<ServiceAppointment> recordList)
      {
        system.debug( 'AMU fillServiceAppointmentWithAbsenceData');
        Set<Id> workOrderIds = new Set<Id>();
        
        for (ServiceAppointment sa : recordList){
            if (sa.ParentRecordId!= null){
                workOrderIds.add(sa.ParentRecordId);
            }
        }
        Map<Id, WorkOrder> woByIdMap = new Map<Id, WorkOrder>([SELECT Id, Absence_Registration__r.Start_date__c
                                                                    , Absence_Registration__r.End_date__c
                                                                    , Absence_Registration__r.Certificate_Start_Date__c
                                                                    , Absence_Registration__r.Certificate_End_Date__c
                                                                    , Absence_Registration__r.Request_Date_and_Time__c
                                                                    , Absence_Registration__r.Exit_home_authorized__c
                                                                    , Absence_Registration__r.Type__c
                                                                    , Absence_Registration__r.Doctor_Firstname__c
                                                                    , Absence_Registration__r.Doctor_Name__c
                                                                    , Employee__c, AccountId
                                                                    , Employee__r.Name
                                                                    , Account.HR_responsible__c, Account.Parent__c
                                                                    , Account.Maximum_Distance_for_Convocation__c
                                                                    , Account.Parent__r.Maximum_Distance_for_Convocation__c
                                                                    , Account.Maximum_distance_for_home_visits__c
                                                                    , Account.Parent__r.Maximum_distance_for_home_visits__c
                                                                    , Account.Parent__r.HR_responsible__c
                                                                    , Absence_Registration__r.Contract_Home__c
                                                                    , Absence_Registration__r.Is_Contract_Pack__c
                                                                    , Absence_Registration__r.Type_of_visit_requested__c
                                                                    , Absence_Registration__r.Notification_channel__c
                                                                    , Absence_Registration__r.Appointment_will_be_made_by__c    
                                                                    , Absence_Registration__r.Visit_Type__c    
                                                                    , Absence_Registration__r.Start_date_disease__c    
                                                                    , Share_to_MCM_FR__c, Share_to_MCM_BE__c, EndDate
                                                                    , Optimal_First_Day__c, Optimal_Last_Day__c
                                                                    , City, Work_Type_FR__c, PostalCode
                                                                    , WorkType.Type_Id__c

                                                            FROM WorkOrder
                                                            WHERE Id IN :workOrderIds]);
      
        
        for (ServiceAppointment sa : recordList)
        {
            if(woByIdMap.containsKey(sa.ParentRecordId))
            {
                WorkOrder wo = woByIdMap.get(sa.ParentRecordId);
                sa.Work_Order_tech__c = sa.ParentRecordId;               
                sa.Account_Tech__c = wo.AccountId;
                sa.Certificate_Start_Date__c = wo.Absence_Registration__r.Certificate_Start_Date__c;
                sa.Certificate_End_Date__c = wo.Absence_Registration__r.Certificate_End_Date__c;
                sa.EarliestStartTime = wo.Optimal_First_Day__c!=null?wo.Optimal_First_Day__c:wo.Absence_Registration__r.Request_Date_and_Time__c;
                sa.DueDate = wo.Optimal_Last_Day__c!=null?wo.Optimal_Last_Day__c:wo.EndDate;
                sa.Exit_home_authorized__c= wo.Absence_Registration__r.Exit_home_authorized__c;              
                sa.Start_Date__c = wo.Absence_Registration__r.Start_date__c;
                sa.Type_of_visit_requested__c = wo.Absence_Registration__r.Type_of_visit_requested__c;
                sa.Notification_channel__c = wo.Absence_Registration__r.Notification_channel__c;
                sa.Appointment_will_be_made_by__c = wo.Absence_Registration__r.Appointment_will_be_made_by__c;
                sa.Presumed_End_Date__c = wo.Absence_Registration__r.End_date__c;
                sa.Type__c = wo.Absence_Registration__r.Type__c;
                sa.Visit_Type__c= wo.Absence_Registration__r.Visit_Type__c;
                sa.Start_date_disease__c= wo.Absence_Registration__r.Start_date_disease__c;
                sa.Share_to_MCM_FR__c = wo.Share_to_MCM_FR__c;
                sa.Share_to_MCM_BE__c = wo.Share_to_MCM_BE__c;
                sa.City_searchable__c= wo.city!=null?wo.city:'';
                sa.Employee_searchable__c= wo.Employee__r.Name!=null?wo.Employee__r.Name:'';
                sa.Zip_Code_searchable__c = wo.PostalCode!=null?wo.PostalCode:'';
                // WAITING ON ANSWER FROM KATRIEN - OAPPMEDCHECK-1181
                if(wo.WorkType.Type_Id__c == WORKTYPE_FR_HV ||wo.WorkType.Type_Id__c ==WORKTYPE_FR_HV_CONV)
                {
                    //sa.Request_type_searchable__c =  Label.home_visit;
                    sa.Request_type_searchable_FR__c = 'Visite à domicile';
                    sa.Request_type_searchable_NL__c = 'Huisbezoek';
                }
                else if(wo.WorkType.Type_Id__c == WORKTYPE_FR_CONV || wo.WorkType.Type_Id__c == WORKTYPE_FR_CONV_HV)
                {
                //    sa.Request_type_searchable__c = Label.convocation;
                    sa.Request_type_searchable_FR__c = 'Convocation';
                    sa.Request_type_searchable_NL__c = 'Convocatie';
                }
                else if(wo.work_Type_FR__c == WORKTYPE_FR_ARBITRAGE) 
                {
                    //sa.Request_type_searchable__c = 'Arbitrage';
                    sa.Request_type_searchable_FR__c = 'Arbitrage';
                    sa.Request_type_searchable_NL__c = 'Arbitrage';
                }
                else if(wo.work_Type_FR__c == WORKTYPE_FR_EXPERTISE) {
                    //sa.Request_type_searchable__c = 'Expertise';
                    sa.Request_type_searchable_FR__c = 'Expertise';
                    sa.Request_type_searchable_NL__c = 'Expertise';
                }
                String docFirstName= wo.Absence_Registration__r.Doctor_Firstname__c==null?'':wo.Absence_Registration__r.Doctor_Firstname__c;
                String docName= wo.Absence_Registration__r.Doctor_Name__c==null?'':wo.Absence_Registration__r.Doctor_Name__c;
                {
                    sa.Doctor_Full_Name__c = docFirstName + ' ' + docName;
                }    
                sa.Absence_Registration__c = wo.Absence_Registration__c;
                sa.Employee__c = wo.Employee__c;
                if( wo.Account.HR_responsible__c != null)
                {
                    sa.HR_responsible__c = wo.Account.HR_responsible__c;
                }
                if( wo.Account.HR_responsible__c == null && Account.Parent__r.HR_responsible__c != null ){
                    sa.HR_responsible__c = wo.Account.Parent__r.HR_responsible__c;
                }
                sa.Contract_Home__c = wo.Absence_Registration__r.Contract_Home__c;
                sa.Is_Contract_Pack__c = wo.Absence_Registration__r.Is_Contract_Pack__c;
                if(wo.Account.Maximum_Distance_for_Convocation__c!=null)
                {
                    switch on wo.Account.Maximum_Distance_for_Convocation__c
                    {
                        when '20'{
                            sa.Max_20_km_Convocation__c = true;
                        }
                        when '30'{
                            sa.Max_30_km_Convocation__c = true;
                        }
                        when '40'{
                            sa.Max_40_km_Convocation__c = true;
                        }
                        when '50'{
                            sa.Max_50_km_Convocation__c = true;             
                        }
                    }
                }
                else
                {
                    switch on wo.Account.Parent__r.Maximum_Distance_for_Convocation__c
                    {
                        when '20'{
                            sa.Max_20_km_Convocation__c = true;
                        }
                        when '30'{
                            sa.Max_30_km_Convocation__c = true;
                        }
                        when '40'{
                            sa.Max_40_km_Convocation__c = true;
                        }
                        when '50'{
                            sa.Max_50_km_Convocation__c = true;             
                        }
                    }
                }

                if(wo.Account.Maximum_distance_for_home_visits__c!=null)
                {
                    switch on wo.Account.Maximum_distance_for_home_visits__c
                    {
                        when '20'{
                            sa.Max_20_km_Home_Visit__c = true;
                        }
                        when '30'{
                            sa.Max_30_km_Home_Visit__c = true;
                        }
                        when '40'{
                            sa.Max_40_km_Home_Visit__c = true;
                        }
                        when '50'{
                            sa.Max_50_km_Home_Visit__c = true;              
                        }
                    }
                }
                else
                {
                    switch on wo.Account.Parent__r.Maximum_distance_for_home_visits__c
                    {
                        when '20'{
                            sa.Max_20_km_Home_Visit__c = true;
                        }
                        when '30'{
                            sa.Max_30_km_Home_Visit__c = true;
                        }
                        when '40'{
                            sa.Max_40_km_Home_Visit__c = true;
                        }
                        when '50'{
                            sa.Max_50_km_Home_Visit__c = true;              
                        }
                    }
                }
            }
        }

    }

  
    /*******************************************************************************
    * @author       Novera - AMU
    * @date         2020-10-19
    * @description  When Exact time of the SA is known therefore the box is ticked, the corresponding technical field 
                    on the workorder needs to be ticked as well to launch the corresponding milestone.
    * @US           OAPPMEDCHECK-276 Maintain generic SLA FR
    ********************************************************************************/
    public static void updateParentWorkOrder(List<ServiceAppointment> recordList ,Map<Id, ServiceAppointment> recordOldValueMap)
    {
    
        Map<Id,ServiceAppointment> ServAppPerWoIdMap = new Map<Id,ServiceAppointment>();
        for(ServiceAppointment sa : recordList)
        {   
            if(sa.Exact_time_SA_known__c==true && recordOldValueMap.get(sa.Id).Exact_time_SA_known__c==false && sa.Work_Order_tech__c !=null
                || sa.Exact_time_SA_known__c==false && recordOldValueMap.get(sa.Id).Exact_time_SA_known__c==true && sa.Work_Order_tech__c !=null )

            {
                ServAppPerWoIdMap.put(sa.Work_Order_tech__c,sa);
            }

        }
        List<WorkOrder> wOListToUpdate = new List<WorkOrder>();
        if(ServAppPerWoIdMap.keySet()!=null && !ServAppPerWoIdMap.keySet().isEmpty())
        {
            for(WorkOrder wo : [SELECT Id, Exact_Time_SA_KnownTechnical__c, SchedStartTime_SA_Technical__c FROM WorkOrder WHERE Id IN : ServAppPerWoIdMap.keySet()]) 
            {
                if(ServAppPerWoIdMap.get(wo.Id)!=null)
                {
                    wo.Exact_Time_SA_KnownTechnical__c = ServAppPerWoIdMap.get(wo.Id).Exact_time_SA_known__c;
                    wo.SchedStartTime_SA_Technical__c =  ServAppPerWoIdMap.get(wo.Id).SchedStartTime;
                    //wo.EndDate = ServAppPerWoIdMap.get(wo.Id).SchedStartTime.addDays(1);
                    wOListToUpdate.add(wo);
                }
            }
        }
        if(!wOListToUpdate.isEmpty()) update wOListToUpdate; 

    }

    /*******************************************************************************
    * @author       Novera - AMU
    * @date         2020-10-19
    * @description  OAPPMEDCHECK-466 Determine default scheduling policy
    * @param        
    * @return       
    ********************************************************************************/
    
    public static void FillSchedulingPolicyLookup(List<ServiceAppointment> recordList){

        Set<Id> workTypeIds = new Set<Id>();
        for(ServiceAppointment sa: recordList){
            if(sa.WorkTypeId != null){
                workTypeIds.add(sa.WorkTypeId);
            }
        }
        if(workTypeIds != null && !workTypeIds.isEmpty()){

            Map<Id, WorkType> workTypesByIdMap = new Map<Id, WorkType>([SELECT Id, Scheduling_Policy_FR__c,Scheduling_Policy_BE__c
                                                                              FROM WorkType
                                                                        WHERE Id IN :workTypeIds]);
            
             for (ServiceAppointment sa : recordList){
                if(workTypesByIdMap.containsKey(sa.WorkTypeId)){
            
                     WorkType wt = workTypesByIdMap.get(sa.WorkTypeId);
                     if(sa.Absence_Registration_RT__c != null && sa.Absence_Registration_RT__c == 'FR'){
                        sa.FSL__Scheduling_Policy_Used__c = wt.Scheduling_Policy_FR__c;
                     }
                     if(sa.Absence_Registration_RT__c != null && sa.Absence_Registration_RT__c == 'BE'){
                        sa.FSL__Scheduling_Policy_Used__c = wt.Scheduling_Policy_BE__c;
                     }
                }
            }
        }
    }

    /*******************************************************************************
    * @author       Novera - QLE
    * @date         2020-11-05
    * @description  OAPPMEDCHECK-369 Link SA and CSLI and update pack quantity on CSLI
    * @param        
    * @return       
    ********************************************************************************/
    public static void assignContractualServiceLineItem(List<ServiceAppointment> recordList, Map<Id, ServiceAppointment> oldMap)
    {
        //Group SA linked to the same contract pack
        Map<Id,Map<Id,ServiceAppointment>> servApptPerContractHomeIdMap = new Map<Id,Map<Id,ServiceAppointment>>();
        for(ServiceAppointment sa: recordList)
        {       
            if(sa.Contract_Home__c!=null && sa.Is_Contract_Pack__c && sa.Invoicing_Status__c==INVOICING_STATUS_INVOICE_DETAIL_LINE_TO_GENERATE 
            && oldMap.get(sa.Id).Invoicing_Status__c!=INVOICING_STATUS_INVOICE_DETAIL_LINE_TO_GENERATE && sa.Contractual_Service_Line_Item__c==null)
            {
                if(servApptPerContractHomeIdMap.containsKey(sa.Contract_Home__c))
                {
                    Map<Id,ServiceAppointment> servAppts = servApptPerContractHomeIdMap.get(sa.Contract_Home__c);
                    servAppts.put(sa.Id,sa);
                    servApptPerContractHomeIdMap.put(sa.Contract_Home__c,servAppts);
                } 
                else
                {
                    servApptPerContractHomeIdMap.put(sa.Contract_Home__c, new Map<Id,ServiceAppointment>{sa.id => sa});
                }
            }
        }
        /*Build custom class 
            contractMCM :
                Id ctrId;
                csliMCM csliBasicFeeHomeVisit;
                csliMCM csliBasicFeeConvocation;
                List<csliMCM> cslisPack;
                Set<Id> notAssignedSA;
        */
        List<contractMCM> ctrMCMList = new List<contractMCM>(); 
        for(Contract_Home__c c : [SELECT Id, (SELECT Id, Service__r.Service_Category__c , Service__r.Visit_Type__c, Service__r.Pack_Type__c, Pack_saldo__c FROM Contractual_Service_Line_Items__r WHERE Service__r.Visit_Type__c=:SERVICE_IDENTIFICATOR_HOME_VISIT OR Service__r.Visit_Type__c=:SERVICE_IDENTIFICATOR_CONVOCATION OR Service__r.Service_Category__c='Pack' ORDER BY Start_Date__c ASC) 
                                FROM Contract_Home__c
                                WHERE Id IN:servApptPerContractHomeIdMap.keySet()])
        { 
            contractMCM ctr = new contractMCM();
            ctr.ctrId = c.Id;
            ctr.notAssignedSA = servApptPerContractHomeIdMap.get(c.Id).keySet();
            List<csliMCM> csliMCMList = new List<csliMCM>(); 
            for(Contractual_Service_Line_Item__c csli : c.Contractual_Service_Line_Items__r)
            {
                csliMCM cslitem = new csliMCM();
                cslitem.cslitemId = csli.Id;
                cslitem.serviceCategory = csli.Service__r.Service_Category__c;
                cslitem.remaningQuantity = Integer.valueOf(csli.Pack_saldo__c);
                cslitem.isPrivilegedPack = csli.Service__r.Pack_Type__c=='Privileged'? true:false;
                switch on csli.Service__r.Service_Category__c {
                    when 'Basic fee per service' {
                        switch on csli.Service__r.Visit_Type__c {
                            when 'Home visit' {
                                ctr.csliBasicFeeHomeVisit = cslitem;
                            }
                            when 'Convocation' {
                                ctr.csliBasicFeeConvocation = cslitem;
                            }
                        }
                    }
                    when else {
                        csliMCMList.add(cslitem);
                    }
                }
            }
            ctr.cslisPack = csliMCMList;
            ctrMCMList.add(ctr);
        }

        //Iterate over the contract and assign csli to sa per contract
        for(contractMCM ctr: ctrMCMList)
        {
            Set<Id> notAssignedSA = ctr.notAssignedSA;
            System.debug('QLE notAssignedSA ' + notAssignedSA);
            for(csliMCM csli : ctr.cslisPack)
            {
                System.debug('QLE csli.remaningQuantity ' + csli.remaningQuantity);
                if(csli.remaningQuantity > 0)
                {
                    for(Id saId : notAssignedSA)
                    {
                        System.debug('QLE notAssignedSA ' + notAssignedSA);
                        ServiceAppointment sa  = servApptPerContractHomeIdMap.get(ctr.ctrId).get(saId);
                        sa.Contractual_Service_Line_Item__c = csli.cslItemId;
                        csli.remaningQuantity = csli.remaningQuantity - 1;
                        System.debug('QLE csli.isPrivilegedPack ' + csli.isPrivilegedPack); 
                        if(csli.isPrivilegedPack==false) sa.Invoicing_Status__c = INVOICING_STATUS_PREPAYMENT;
                        notAssignedSA.remove(sa.Id);
                    }
                    System.debug('QLE sa.Contractual_Service_Line_Item__c ' + notAssignedSA); 
                }
            }
            if(!notAssignedSA.isEmpty())
            {
                System.debug('QLE notAssignedSA ' + notAssignedSA); 
                for(Id saId : notAssignedSA)
                {
                    ServiceAppointment sa = servApptPerContractHomeIdMap.get(ctr.ctrId).get(saId);
                    System.debug('QLE sa ' + sa); 
                    if(sa.Home_Visit__c && ctr.csliBasicFeeHomeVisit!=null) 
                    {
                        sa.Contractual_Service_Line_Item__c = ctr.csliBasicFeeHomeVisit.cslitemId;
                    }
                    else if(sa.Convocation__c && ctr.csliBasicFeeConvocation!=null)
                    {
                        sa.Contractual_Service_Line_Item__c = ctr.csliBasicFeeConvocation.cslitemId;
                    }
                }
            }
        }

        
    }
    

    /*******************************************************************************
    * @author       Novera - QLE
    * @date         2020-11-05
    * @description  OAPPMEDCHECK-369 Link SA and CSLI and update pack quantity on CSLI
    * @param        
    * @return       
    ********************************************************************************/
    public static void remainingQuantityOnContractualServiceLineItem(List<ServiceAppointment> recordList, Map<Id,ServiceAppointment> oldMap)
    {
    
        Set<Id> csliIdSet = new Set<Id>();
        Set<Id> saIds = new  Set<Id>(); //After a SA has been deduced from a pack, update invoicing status on the related AR.
        for(ServiceAppointment sa: recordList)
        {   
            if(oldMap!=null && sa.Contractual_Service_Line_Item__c!=null && sa.Contractual_Service_Line_Item__c != oldMap.get(sa.Id).Contractual_Service_Line_Item__c && sa.Is_Contract_Pack__c)
            {
                csliIdSet.add(sa.Contractual_Service_Line_Item__c);
                saIds.add(sa.Id);
            }
        }       
        List<Contractual_Service_Line_Item__c> csliListToUpdate = new List<Contractual_Service_Line_Item__c>();
        List<AggregateResult> groupedResults = [SELECT Contractual_Service_Line_Item__c, count(Id) consumedAmount 
                                                FROM ServiceAppointment 
                                                WHERE Contractual_Service_Line_Item__c IN:csliIdSet 
                                                GROUP BY Contractual_Service_Line_Item__c];
        for (AggregateResult ar : groupedResults)
        {
            Integer consumedAmount = Integer.valueOf(ar.get('consumedAmount'));
            Contractual_Service_Line_Item__c csli = new Contractual_Service_Line_Item__c(Id=String.valueOf(ar.get('Contractual_Service_Line_Item__c'))
                                                                                ,Consumed_Amount__c = consumedAmount);
            csliListToUpdate.add(csli);
        }
        update csliListToUpdate;
        if(saIds!=null && !saIds.isEmpty())  updateARinvoicingStatus(saIds);                        

    }

    /*******************************************************************************
    * @author       Novera - AMU
    * @date         2020-10-19
    * @description  Prevent status to change from new to scheduled if there is not an assigned resource assigned to the SA
    * @US           OAPPMEDCHECK-
    ********************************************************************************/
    public static void PreventStatusToScheduled(List<ServiceAppointment> recordList, Map<Id, ServiceAppointment> recordOldValueMap)
    {
        Set<Id> servAppIds = new set<Id>();
        Set<Id> saWithAssignedRessource  = new set<Id>();
        List<ServiceAppointment> saToProcess = new List<ServiceAppointment>(); 
        for(ServiceAppointment sa : recordList)
        {   
            if(recordOldValueMap.get(sa.Id)!=null && sa.status == STATUS_SCHEDULED && recordOldValueMap.get(sa.Id).Status != STATUS_SCHEDULED )
            {
                servAppIds.add(sa.Id); 
                saToProcess.add(sa);
            }
        }

        if (!servAppIds.isEmpty())
        {
            for(AssignedResource assRes:[SELECT ServiceAppointmentId FROM AssignedResource WHERE ServiceAppointmentId IN:servAppIds])
            {
                saWithAssignedRessource.add(assRes.ServiceAppointmentId); 
            }
        }

        if(!saToProcess.isEmpty())
        {
            for(serviceAppointment sa: saToProcess)
            {
                if(saWithAssignedRessource==null || ( saWithAssignedRessource!=null&& !saWithAssignedRessource.contains(sa.id))) sa.addError('Status cannot be changed to Scheduled: a service resource needs to be assigned');
            }
        }
    }

/*******************************************************************************
    * @author       Novera - AMU
    * @date         2020-02-15
    * @description  OAPPMEDCHECK 178- Notify customer of a resource assigned by email
    * @param
    * @return
    ********************************************************************************/

    public static void sendIntermediaryChangeAssignedResource(List<ServiceAppointment> recordList, Map<Id, ServiceAppointment> recordOldValueMap)
    {
        Set<Id> setAbsenceIds = new Set<Id>();
        List <Recipients_Absence_Query.flowInputs> lstInputs = new List <Recipients_Absence_Query.flowInputs>();
        List <Task> alertTasks           = new List <Task>();
        Map  <Id, Contact> mapRecipients = new Map <Id, Contact>();

        system.debug('AMU sendIntermeAss ');

        for(ServiceAppointment sa : recordList)
        {
            if(sa.Absence_Registration_RT__c=='BE' && sa.status == 'Scheduled' && recordOldValueMap.get(sa.Id).Status != 'Scheduled' )
            {
                setAbsenceIds.add(sa.Absence_Registration__c);
            }
        }

        if(!setAbsenceIds.isEmpty())
        {
            //Get the list of absences ids in the SA records
            Map<Id, Absence_Registration__c> absencesByIdMap = new Map<Id, Absence_Registration__c>([SELECT Id, Account__c, Main_Account__c, OwnerId, RecordType.DeveloperName
            FROM Absence_Registration__c
            WHERE Id IN :setAbsenceIds]);

            //If the absences list is not empty, send parameters to the apex query recipients class
            if(!absencesByIdMap.isEmpty())
            {
                for (Absence_Registration__c abs : absencesByIdMap.values())
                {
                    Recipients_Absence_Query.flowInputs Inputs = new Recipients_Absence_Query.flowInputs();
                        Inputs.absenceAccountId = abs.Account__c;
                        Inputs.mainAccountId    = abs.Main_Account__c;
                    lstInputs.add(Inputs);
                }

                //Collect the contact recipients lists output
                List <Recipients_Absence_Query.Response> Responses = Recipients_Absence_Query.retrieveInputs(lstInputs);

                for (Absence_Registration__c abs : absencesByIdMap.values())
                {
                    for(Recipients_Absence_Query.Response res: Responses){
                        if(!res.AssignedResource_Recipients.isEmpty())
                        {
                            mapRecipients.putall(res.AssignedResource_Recipients);
                        }
                    }

                    //Update the contact to trigger email alert
                    if(mapRecipients.size() > 0)
                    {
                        for(contact con : mapRecipients.values())
                        {
                            con.TECH_Notify_employer_assignedResource__c = true;
                            con.Tech_Related_To__c = abs.Id;
                        }
                    }

                    else if(mapRecipients.size() == 0)
                    {
                        Task myTask = new Task();
                        myTask.ActivityDate = System.today();
                        myTask.subject     = System.Label.FlowNoRecipientsAssignedResource;
                        myTask.Description = System.Label.FlowNoRecipientsAssignedResource;
                        myTask.OwnerId     = abs.OwnerId!=null?abs.OwnerId:UserInfo.getUserId();
                        myTask.Status      = 'Open';
                        myTask.WhatId      = abs.Id;

                        alertTasks.add(myTask);
                    }
                }

                if(mapRecipients.size() > 0)
            	{
            	    update mapRecipients.values();
            	}

                //Switch back tech checkboxes to false after operation
                if(mapRecipients.size() > 0)
            	{
                    for(contact con : mapRecipients.values())
                    {
                        con.TECH_Notify_employer_assignedResource__c = false;
                        con.Tech_Related_To__c = null;
                    }

                    update mapRecipients.values();
            	}

                if(alertTasks.size() > 0)
                {
                    insert alertTasks;
                }
            }
        }
    }


/*******************************************************************************
* @author       Novera - JFO
* @date         2020-02-15
* @description  OAPPMEDCHECK 180- Notify customer of visit result by email
                Need to work in without sharing mode to allow doctors in the portal 
                to trigger the notification
* @param        List of SA in adequate status and Map of SA old values
* @return       Void
********************************************************************************/    
    
    public static void sendReportVisitRecipients(List<ServiceAppointment> recordList, Map<Id, ServiceAppointment> recordOldValueMap){
   
        Set<Id> setAbsenceIds = new Set<Id>();
        
        for(ServiceAppointment sa : recordList)
        {   
            if(sa.status == STATUS_RESULT_TO_CUSTOMER && recordOldValueMap.get(sa.Id).Status != STATUS_RESULT_TO_CUSTOMER)
            {
                setAbsenceIds.add(sa.Absence_Registration__c);
            }
        }

        if(!setAbsenceIds.IsEmpty())
        {
            MCM_Notify_Customer_ReportVisits.sendResults(setAbsenceIds, null);
        }
    }



/*******************************************************************************
* @author       Novera - JFO
* @date         2020-02-15
* @description  OAPPMEDCHECK-1042: Send extra information from doctor on SA to customer
                Resend additional information to the customer
* @param        List of SA in adequate status and Map of SA old values
* @return       Void
********************************************************************************/

    public static void resendReportVisitToCustomer(List<ServiceAppointment> recordList, Map<Id, ServiceAppointment> recordOldValueMap){
    
        Set<Id> setAbsenceIds = new Set<Id>();
        List <Absence_Registration__c> lstAbsences = new List <Absence_Registration__c>();
        
        for(ServiceAppointment sa : recordList)
        {   
            if(sa.status == STATUS_RESULT_TO_CUSTOMER && sa.Tech_Resend_email_to_customer__c == True && recordOldValueMap.get(sa.Id).Tech_Resend_email_to_customer__c != True )
            {
                setAbsenceIds.add(sa.Absence_Registration__c);
            }
        }
        
        if(!setAbsenceIds.IsEmpty())
        {
            Map<Id, Absence_Registration__c> mapAbs =  new Map<Id, Absence_Registration__c>([select Id, Additional_info_for_customer__c, Account__c, 
                                                                                             Main_Account__c, OwnerId, RecordType.DeveloperName, Result_Code__c
                                                            from Absence_Registration__c where ID IN:setAbsenceIds]);
            
            for (ServiceAppointment sa: recordList) 
            {
               Absence_Registration__c abs =  mapAbs.get(sa.Absence_Registration__c);
               sa.Tech_Resend_email_to_customer__c = false;
               abs.Additional_info_for_customer__c = sa.Additional_info_for_customer__c;
            }
            update mapAbs.values();
            
            lstAbsences.addall(mapAbs.values());
            
            
            MCM_Notify_Customer_ReportVisits.sendResults(setAbsenceIds, lstAbsences);
        }        
    }

    
/*******************************************************************************

********************************************************************************/    
    public class contractMCM
    {
        public Id ctrId;
        public csliMCM csliBasicFeeHomeVisit;
        public csliMCM csliBasicFeeConvocation;
        public List<csliMCM> cslisPack;
        public Set<Id> notAssignedSA;
    }

    public class csliMCM
    {
        public Id cslitemId;
        public String serviceCategory;
        public Integer remaningQuantity;
        public Boolean isPrivilegedPack; //OAPPMEDCHECK-1001
    }

    public class contractInfoForInvoicing
    {
        Map<Id,Decimal> kmInForfaitPerCtrId; 
        Map<Id,Map<Id,Decimal>> pricePerServIdPerCtrId;
        Set<Id> csliWithPrivilegedPack; //OAPPMEDCHECK-1001
    }

    public class saliSaveResult
    {
        Map<Id,String> saInvOrRemStatus;
        List<Task> taskToInsert;
    }

}


    /*
    ---- RELEASE 2 ---
    public static void DoctorDesiredScore(List<ServiceAppointment> 
    
    ) {

      Set<Id> servAppIds = new Set<Id>();
      for(ServiceAppointment servApp : recordList){
        servAppIds.add(servApp.Id);
      }

      //      List<AssignedResource> assResources = [SELECT Id, ServiceResourceId, ServiceAppointment.Resumption_Date__c FROM AssignedResource WHERE ServiceAppointment.Status = 'completed' AND ServiceAppointmentId IN :servAppIds AND ServiceResourceId != NULL];

      List<AssignedResource> allAssignRes =  [SELECT Id, ServiceResourceId  FROM AssignedResource WHERE ServiceAppointmentId IN :servAppIds];
      Set<Id> serResIds = new Set<Id>();
      for(AssignedResource asr : allAssignRes){
        serResIds.add(asr.ServiceResourceId);
      }

      List<AssignedResource> assResources = [SELECT Id, ServiceResourceId, ServiceAppointment.Resumption_Date__c FROM AssignedResource WHERE ServiceAppointment.Status = 'completed' AND ServiceResourceId IN :serResIds];


      Map<Id,Map<String,Integer>> scoreByServiceRessource = new Map<Id,Map<String,Integer>>();

      for(AssignedResource assResource : assResources){    
        Map<String,Integer> score = new Map<String,Integer>{
            'completed' => 0,
            'nbDate' => 0
        };
        if(scoreByServiceRessource.containsKey(assResource.ServiceResourceId)){
            score = scoreByServiceRessource.get(assResource.ServiceResourceId);
        }  

        if(assResource.ServiceAppointment != null && assResource.ServiceAppointment.Resumption_Date__c != null ){
          Integer countNbDate = score.get('nbDate');
            score.put('nbDate', (countNbDate + 1));
        }
        Integer countCompl = score.get('completed');
        score.put('completed', (countCompl + 1));

        scoreByServiceRessource.put(assResource.ServiceResourceId, score);
      }

        List<ServiceResource> servResources = new List<ServiceResource>();
        for (Id servResId : scoreByServiceRessource.keySet()){
            Map<String,Decimal> score = scoreByServiceRessource.get(servResId);
            ServiceResource servRes = new ServiceResource(Id=servResId);
            System.debug('START');
            System.debug('score.get(nbDate)');
            System.debug(score.get('nbDate'));
            System.debug('score.get(completed)');
            System.debug(score.get('completed'));
            System.debug('total');
            System.debug(((1 - score.get('nbDate')) / score.get('completed')));
            servRes.Desired_Result_Score__c =  (1 - (score.get('nbDate') / score.get('completed'))) ;
         

            servRes.Desired_Score_Last_Calculation_Date__c = Datetime.now();
            servResources.add(servRes);
        }

        update servResources;


    }

    --- TO CONTINUE WHEN BUSINESS DECISION MADE ---
     
    public static void DoctorAcceptanceRate(List<ServiceAppointment> recordList) {

      Set<Id> servAppIds = new Set<Id>();
      for(ServiceAppointment servApp : recordList){
        servAppIds.add(servApp.Id);
      }

      List<AssignedResource> assResources = [SELECT Id, ServiceResourceId, ServiceAppointment.Convocation__c, ServiceAppointment.Home_Visit__c FROM AssignedResource WHERE ServiceAppointment.Status = 'accepted' AND ServiceAppointment.Convocation__c = true AND ServiceAppointmentId IN :servAppIds AND ServiceResourceId != NULL];

      Map<Id,Map<String,Decimal>> scoreByServiceRessource = new Map<Id,Map<String,Integer>>();

      for(AssignedResource assResource : assResources){    
        Map<String,Integer> score = new Map<String,Integer>{
            'accepted Home Visits' => 0,
            'accepted Convocations' => 0,
            'Total Proposals' => 0
        };
        if(scoreByServiceRessource.containsKey(assResource.ServiceResourceId)){
            score = scoreByServiceRessource.get(assResource.ServiceResourceId);
        }  

        if(assResource.ServiceAppointment != null && assResource.ServiceAppointment.Convaction__c = true ){
            Integer countNbDate = score.get('Accepted Convocations');
            score.put('Accepted Convocations', (countNbDate + 1));
        }
        if(assResource.ServiceAppointment != null && assResource.ServiceAppointment.Home_Visit__c = true ){
          Integer countNbDate = score.get('Accepted Home Visits');
          score.put('Accepted Home Visits', (countNbDate + 1));
      }
        Integer countCompl = score.get('Total Proposals');
        score.put('Total Proposals', (countCompl + 1)); // calcul!

        scoreByServiceRessource.put(assResource.ServiceResourceId, score);
      }

      List<ServiceResource> servResources = new List<ServiceResource>();
      for (Id servResId : scoreByServiceRessource.keySet()){
          Map<String,Integer> score = scoreByServiceRessource.get(servResId);
          ServiceResource servRes = new ServiceResource(Id=servResId);
          servRes.Convocations_Acceptance_Rate__c =  ((100 - score.get('Accepted Convocations')) / score.get('Total Proposals')) ;
          servRes.Home_Visits_Acceptance_Rate__c = ((100 - score.get('Accepted Home Visits')) / score.get('Total Proposals')) ;
          servRes.Acceptance_Rate_Last_Calculation_Date__c = Datetime.now();
          servResources.add(servRes);
      }

      update servResources;
    
    
  }*/