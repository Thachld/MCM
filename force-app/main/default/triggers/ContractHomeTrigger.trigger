/********************************************************************************************************
* @author         Novera - Selim Lalaoui
* @description    Trigger for the Contract_Home__c object
* @date           2018 DEC 03       
* @group          Triggers
*********************************************************************************************************/

trigger ContractHomeTrigger on Contract_Home__c
(before insert,
before update,
before delete,
after insert,
after update,
after delete,
after undelete) 
{
    // Initialize the trigger Handler
    ContractHomeTriggerHandler th = new ContractHomeTriggerHandler(Trigger.New, Trigger.oldMap);

    // Run the TriggerHandler logic
    th.run(); 
}