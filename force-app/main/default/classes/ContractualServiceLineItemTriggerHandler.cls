public with sharing class ContractualServiceLineItemTriggerHandler
{
    // Map containing the old values for the Records 
    Map<Id, Contractual_Service_Line_Item__c> recordOldValueMap;

    // Initial records receives from the Trigger
    List<Contractual_Service_Line_Item__c> initialRecordList;
    

    public ContractualServiceLineItemTriggerHandler(List<Contractual_Service_Line_Item__c> recordList, Map<Id,Contractual_Service_Line_Item__c> recordOldValueMap)
	{
    	// Store a reference to the inital list
    	this.initialRecordList = recordList;

    	// Set the Old Value Map
        this.recordOldValueMap = recordOldValueMap;
        
    }


    public void run()
    {
    	
    	if(this.initialRecordList != null && !this.initialRecordList.isEmpty())
    	{
            if(trigger.isBefore)
    		{      
/*                 if(trigger.isInsert)
                {
                    ContractualServiceLineItemManager.checkInvoicingRecipient(this.initialRecordList);
                } */
                if(trigger.isUpdate)
                {
                    ContractualServiceLineItemManager.checkIfPriceBookLineItemInUse(this.initialRecordList, this.recordOldValueMap);
                    //QLE 17_09_2021 for BE
                    //ContractualServiceLineItemManager.checkIfContractServiceInUse(this.initialRecordList, this.recordOldValueMap);
                }
                    
            }
            if(trigger.isAfter)
            {      
                if(trigger.isInsert)
                {
                    ContractualServiceLineItemManager.createPackInvoicing(this.initialRecordList);
                    //OAPPMEDCHECK-1212 ContractualServiceLineItemManager.createYearlyContributionInvoicing(this.initialRecordList,null);
                    ContractualServiceLineItemManager.checkExistingLinePerService(this.initialRecordList,null);
                }
                if(trigger.isUpdate)
                {
                    ContractualServiceLineItemManager.checkExistingLinePerService(this.initialRecordList,this.recordOldValueMap);
                }

            }
        }

        if(this.recordOldValueMap!=null && !this.recordOldValueMap.isEmpty())
        {
            if(trigger.isBefore)
            {      
    
                if(trigger.isDelete)
                {
                    ContractualServiceLineItemManager.checkContractualLineItemLink(this.recordOldValueMap.values());
                    //QLE 17_09_2021 for BE
                    //ContractualServiceLineItemManager.deleteContractServiceInUse(this.recordOldValueMap.values());
                }
    
            }
        }

    }

}