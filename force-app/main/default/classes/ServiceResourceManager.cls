/********************************************************************************************************
* @author         Novera - AMU
* @description    Trigger Handler for the ServiceResource object
* @date           2020 DEC 11       
* @group          Trigger Managers
*********************************************************************************************************/

public with sharing class ServiceResourceManager {

/********************************************************************************************************
* @author         Novera - AMU
* @description    Method that copies the information on the Account (Share_to_FR and Share_to_BE fields)
                  to the service resource to use in doctors sharing rules criteria (update on Account)
* @date           2021 MAR 23       
* @group          Trigger Managers
*********************************************************************************************************/

    public static void populateSharingFieldByAccount(List<ServiceResource> recordList) {

        Set<Id> AccId = new set<Id>();
        Map<Id, Account> AccountByIdMap = new Map<Id, Account>();
        for (ServiceResource servRes : recordList)
        {
            if(servRes.AccountId != null){
                AccId.add(servRes.AccountId);
            }
        }

        if(!AccId.isEmpty())
        {
            AccountByIdMap = new Map<Id, Account>([SELECT Id, Share_to_MCM_FR__c, Share_to_MCM_BE__c 
                                                                    FROM Account
                                                                    WHERE Id IN :AccId]);
        }
        //List<ServiceResource> servResListToUpdate = new List<ServiceResource>();
        for (ServiceResource sr : recordList)
        {
           if(AccountByIdMap.containsKey(sr.AccountId))
            {
                Account acc = AccountByIdMap.get(sr.AccountId);
                sr.Tech_Share_to_MCM_FR__c = acc.Share_to_MCM_FR__c;
                sr.Tech_Share_to_MCM_BE__c = acc.Share_to_MCM_BE__c;
                //servResListToUpdate.add(sr);
            }
        }
        //if(!servResListToUpdate.isEmpty()) update servResListToUpdate; 
    }

    public static void populateURLbyId(List<ServiceResource> recordList) //OAPPMEDCHECK-773
    {
    
        for(ServiceResource sr: recordList)
        {
            sr.Details__c= '/'+sr.Id;
        }
    
    }
}