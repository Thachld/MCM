/********************************************************************************************************
* @author         Novera - Selim Lalaoui
* @description    Trigger manager for the Contract_Home__c object
* @date           2018 DEC 03       
* @group          Trigger Managers
*********************************************************************************************************/

public class ContractHomeManager 
{
	/* Contract Home */
	public static final String CONTRACT_HOME_RT_MCM_FR_CONTRACT = 'MCM_FR_Contract';
	public static final String CONTRACT_HOME_RT_MCM_BE_CONTRACT = 'MCM_BE_Contract';
	public static final String CONTRACT_HOME_RT_MCM_BE_ONESHOT = 'MCM_BE_OneShot';
	public static final String CONTRACT_HOME_RT_MCM_FR_CONVENTION = 'MCM_FR_Convention';
	public static final String CONTRACT_HOME_RT_MCM_BE_CONVENTION = 'MCM_BE_Convention';
	public static final String CONTRACT_HOME_RT_MCM_PRICING = 'Pricing';


	public static Id mcmFrProductId{
        get{
            if(mcmFrProductId==null){
                Id pId = [SELECT Id FROM Product2 WHERE ExtSysId__c='16200' LIMIT 1].Id;
				mcmFrProductId = pId;
            }
            return mcmFrProductId;
        }
        set;
	}

	public static Id mcmBeProductId{
        get{
            if(mcmBeProductId==null){
                Id pId = [SELECT Id FROM Product2 WHERE ExtSysId__c='16000' LIMIT 1].Id;
				mcmBeProductId = pId;
            }
            return mcmBeProductId;
        }
        set;
	}

	public static Id mcmBeOneShotProductId{
        get{
            if(mcmBeOneShotProductId==null){
                Id pId = [SELECT Id FROM Product2 WHERE ExtSysId__c='16002' LIMIT 1].Id;
				mcmBeOneShotProductId = pId;
            }
            return mcmBeOneShotProductId;
        }
        set;
	}
	

	public static Id mcmRtBEId{
        get{
            if(mcmRtBEId==null){
                Id rtId = Schema.SObjectType.Contract_Home__c.getRecordTypeInfosByDeveloperName().get(CONTRACT_HOME_RT_MCM_BE_CONTRACT).getRecordTypeId();
				mcmRtBEId = rtId;
            }
            return mcmRtBEId;
        }
        set;
	}

	public static Id mcmRtOneshotBeId{
		get{
			if(mcmRtOneshotBeId==null){
				Id rtId = Schema.SObjectType.Contract_Home__c.getRecordTypeInfosByDeveloperName().get(CONTRACT_HOME_RT_MCM_BE_ONESHOT).getRecordTypeId();
				mcmRtOneshotBeId = rtId;
			}
			return mcmRtOneshotBeId;
		}
		set;
	}

	public static Id mcmRtFRId{
		get{
			if(mcmRtFRId==null){
				Id rtId = Schema.SObjectType.Contract_Home__c.getRecordTypeInfosByDeveloperName().get(CONTRACT_HOME_RT_MCM_FR_CONTRACT).getRecordTypeId();
				mcmRtFRId = rtId;
			}
			return mcmRtFRId;
		}
		set;
	}

	public static Id mcmRtConventionFRId{
		get{
			if(mcmRtConventionFRId==null){
				Id rtId = Schema.SObjectType.Contract_Home__c.getRecordTypeInfosByDeveloperName().get(CONTRACT_HOME_RT_MCM_FR_CONVENTION).getRecordTypeId();
				mcmRtConventionFRId = rtId;
			}
			return mcmRtConventionFRId;
		}
		set;
	}

	public static Id mcmRtConventionBEId{
		get{
			if(mcmRtConventionBEId==null){
				Id rtId = Schema.SObjectType.Contract_Home__c.getRecordTypeInfosByDeveloperName().get(CONTRACT_HOME_RT_MCM_BE_CONVENTION).getRecordTypeId();
				mcmRtConventionBEId = rtId;
			}
			return mcmRtConventionBEId;
		}
		set;
	}

	public static Id mcmRtPricingId{
		get{
			if(mcmRtPricingId==null){
				Id rtId = Schema.SObjectType.Contract_Home__c.getRecordTypeInfosByDeveloperName().get(CONTRACT_HOME_RT_MCM_PRICING).getRecordTypeId();
				mcmRtPricingId = rtId;
			}
			return mcmRtPricingId;
		}
		set;
	}


	public static Id generalRtId{
        get{
            if(generalRtId==null){
                Id rtId = Schema.SObjectType.Contract_Home__c.getRecordTypeInfosByDeveloperName().get('General').getRecordTypeId();
                generalRtId = rtId;
            }
            return generalRtId;
        }
        set;
	}  

	public static Integer contractNumberFrMCM {
		get {
			if(contractNumberFrMCM == null)
			{
				AggregateResult[] maxNumberContract = [SELECT MAX(Contract_Digit__c) maxNumberContract FROM Contract_Home__c 
											WHERE RecordTypeId =:mcmRtFRId];
				
				if(maxNumberContract[0].get('maxNumberContract') != null) contractNumberFrMCM = Integer.valueOf(maxNumberContract[0].get('maxNumberContract')) + 1;
				
				else contractNumberFrMCM = 100000;
			}
			return contractNumberFrMCM++;
		}
		set;
	}

	public static Integer contractNumberBeMCM {
		get {
			if(contractNumberBeMCM == null)
			{
				AggregateResult[] maxNumberContract = [SELECT MAX(Contract_Digit__c) maxNumberContract FROM Contract_Home__c 
											WHERE RecordTypeId =:mcmRtBEId OR RecordTypeId =:mcmRtOneshotBeId];
				
				if(maxNumberContract[0].get('maxNumberContract') != null) contractNumberBeMCM = Integer.valueOf(maxNumberContract[0].get('maxNumberContract')) + 1;
				
				else contractNumberBeMCM = 100000;
			}
			return contractNumberBeMCM++;
		}
		set;
	}

	public static Integer conventionNumberFrMCM {
		get {
			if(conventionNumberFrMCM == null)
			{
				AggregateResult[] maxNumberContract = [SELECT MAX(Contract_Digit__c) maxNumberConvention FROM Contract_Home__c 
											WHERE RecordTypeId =:mcmRtConventionFRId];
				
				if(maxNumberContract[0].get('maxNumberConvention') != null) conventionNumberFrMCM = Integer.valueOf(maxNumberContract[0].get('maxNumberConvention')) + 1;
				
				else conventionNumberFrMCM = 0;
			}
			return conventionNumberFrMCM++;
		}
		set;
	}

	public static Integer conventionNumberBeMCM {
		get {
			if(conventionNumberBeMCM == null)
			{
				AggregateResult[] maxNumberContract = [SELECT MAX(Contract_Digit__c) maxNumberConvention FROM Contract_Home__c 
											WHERE RecordTypeId =:mcmRtConventionBEId];
				
				if(maxNumberContract[0].get('maxNumberConvention') != null) conventionNumberBeMCM = Integer.valueOf(maxNumberContract[0].get('maxNumberConvention')) + 1;
				
				else conventionNumberBeMCM = 0;
			}
			return conventionNumberBeMCM++;
		}
		set;
	}


	public static void fillContractNumber(List<Contract_Home__c> recordList)
	{
		
		for(Contract_Home__c ct : recordList)
		{
			if(ct.Contract_Digit__c==null)
			{
				if(ct.RecordTypeId==mcmRtConventionFRId){
					ct.Contract_Digit__c = conventionNumberFrMCM;
					ct.Name = 'CONV-' + String.valueOf(ct.Contract_Digit__c).leftPad(5,'0');
				}
				else if(ct.RecordTypeId==mcmRtConventionBEId)
				{
					ct.Contract_Digit__c = conventionNumberBeMCM;
					system.debug('AMU digit' + ct.Contract_Digit__c);
					ct.Name = 'CONV-' + String.valueOf(ct.Contract_Digit__c).leftPad(5,'0');
					system.debug('AMU name '+ ct.Name);
				}
				else{
					String ctCountry =  ct.Contract_Country__c;
					switch on ctCountry{
						when 'BEL' {  
							ct.Contract_Digit__c = contractNumberBeMCM;
						}
						when 'FRA' {    
							ct.Contract_Digit__c = contractNumberFrMCM;
						}
					}
				}
			}
			// else if(ct.External_Id__c!=null)
			// {
			// 	if(ct.Name!=null && ct.Name.contains('-'))
			// 	{
			// 		Pattern MyPattern = Pattern.compile('[^-]*-([0-9]{1,})$');
			// 		Matcher MyMatcher = MyPattern.matcher(ct.Name);
			// 		if(MyMatcher.matches()){
			// 			if(Integer.ValueOf(MyMatcher.group(1)) > 100000){
			// 				ct.addError('A contract from mainframe can not be assigned a number greater than 100000.');
			// 			}
			// 		}
			// 		else{
			// 			ct.addError('Invalid contract name.');
			// 		}
			// 	}
			// 	else {
			// 		ct.addError('A contract from mainframe must have a name.');
			// 	}
			// }
		}
	}



	public static void populateMCMContractInformation(List<Contract_Home__c> recordList)
	{
		for(Contract_Home__c ctr : recordList)
		{
			if(ctr.In_Place_Date__c !=null)
			{
				ctr.Signature_Date__c = ctr.In_Place_Date__c;
				if(ctr.Contract_Home__c==null) //meaning that the contract doesn't come from versionning process
				{
					ctr.Version_start_date__c = ctr.In_Place_Date__c;
				}
			}

			if(ctr.Product__c==null) 
			{
				if(ctr.RecordTypeId==mcmRtBEId){
					ctr.Product__c = mcmBeProductId;
				}
				else if(ctr.RecordTypeId==mcmRtOneshotBeId){
					ctr.Product__c= mcmBeOneShotProductId;
				}
				else{
					ctr.Product__c = mcmFrProductId;
				}
			}

			if(ctr.RecordTypeId==mcmRtOneshotBeId ){
				ctr.Service_Type__c='Medical check illness';
			}
		}
		
	}

	public static void createDefaultPricingLines(List<Contract_Home__c> recordList)
	{
		Set<Id> pbIdSet = new Set<Id>();
		List<Contract_Home__c> ctrToProcess = new List<Contract_Home__c>();
		for(Contract_Home__c ctr: recordList)
		{
			if(ctr.Contract_Country__c=='FRA')
			{
				ctrToProcess.add(ctr);
			}
		}

		if(!ctrToProcess.isEmpty())
		{
			Map<Id,Service__c> servicesMap = new Map<Id,Service__c>([SELECT Id, Current_Standard_Price__c FROM Service__c WHERE Active__c=TRUE 
													AND Available_for_country__c='FR' AND Service_Category__c!='Pack' AND Service_Category__c!='Miscellaneous' AND Service_Category__c!='Annual fee']);
			List<Contractual_Service_Line_Item__c> cslisToInsert = new List<Contractual_Service_Line_Item__c>();
			for(Contract_Home__c ctr : ctrToProcess)
			{
				if(ctr.MCM_External_Id__c==null)
				{
					for(Id sId : servicesMap.keySet())
					{
						Contractual_Service_Line_Item__c csli = new Contractual_Service_Line_Item__c( Contract_Home__c = ctr.Id
																			, Service__c = sId
																			, RecordTypeId = UtilsConstants.RT_ID_CSLI_RT_MCM_Contract_Service);
						if(Test.isRunningTest())
						{ 
							csli.Price_Rate_1__c = servicesMap.get(sId).Current_Standard_Price__c;		
						}										
						cslisToInsert.add(csli);
					}
				}
			}
			if(!cslisToInsert.isEmpty()) insert cslisToInsert;
		}

	}

	
	public static void createDefaultContractLines(List<Contract_Home__c> recordList)
	{
		Set<Id> pbIdSet = new Set<Id>();
		Map<Id,Map<Id,Contractual_Service_Line_Item__c>> pricePerServiceIdPerPbId = new Map<Id,Map<Id,Contractual_Service_Line_Item__c>>();
		Map<Id, Contract_Home__c> ctrHomeperPbId = new Map<Id, Contract_Home__c>();
		for(Contract_Home__c ctr : recordList)
		{
			if(ctr.Pricing__c!=null && ctr.Version__c==1 && ctr.Is_From_Migration__c==false) ctrHomeperPbId.put(ctr.Pricing__c, ctr); // OAPPMEDCHECK-317
		}
		if(!ctrHomeperPbId.isEmpty())
		{
			for(Contract_Home__c pb : [SELECT Id, (SELECT Service__c, Price_Rate_1__c, Supplement__c, Contract_Home__c FROM Contractual_Service_Line_Items__r) FROM Contract_Home__c WHERE Id IN:ctrHomeperPbId.KeySet()])
			{
				Map<Id,Contractual_Service_Line_Item__c> pricePerServiceId = new Map<Id,Contractual_Service_Line_Item__c>();
				for(Contractual_Service_Line_Item__c pbLine : pb.Contractual_Service_Line_Items__r)
				{
					Contract_Home__c currentCtr = ctrHomeperPbId.get(pb.Id);
					if(pbLine.Price_Rate_1__c != null || pbLine.Supplement__c != null)
					{
						pricePerServiceId.put(pbLine.Service__c, pbLine);
					}
					else 
					{
                        if(currentCtr.RecordTypeId==mcmRtFRId && pbLine.Price_Rate_1__c == null)
						{
							currentCtr.addError(Label.Invoicing_Error_Price_Line);
						}
						else if(currentCtr.RecordTypeId==mcmRtBEId && pbLine.Price_Rate_1__c == null && pbLine.Supplement__c == null)
						{
                            currentCtr.addError(Label.Invoicing_Error_Price_Line); 
						}
					}
				}
				pricePerServiceIdPerPbId.put(pb.Id,pricePerServiceId);
			}
	
			List<Contractual_Service_Line_Item__c> cslisToInsert = new List<Contractual_Service_Line_Item__c>();
			for(Contract_Home__c ctr : recordList)
			{
				if(ctr.Pricing__c!=null && ctr.Version__c==1 && ctr.Is_From_Migration__c==false)
				{
					Map<Id,Contractual_Service_Line_Item__c> pricePerServiceId = pricePerServiceIdPerPbId!=null?pricePerServiceIdPerPbId.get(ctr.Pricing__c):null;
					for(Id sId : pricePerServiceId.keySet())
					{
						cslisToInsert.add(new Contractual_Service_Line_Item__c( Contract_Home__c = ctr.Id
						, Service__c = sId
						, Price_Rate_1__c = pricePerServiceId.get(sId).Price_Rate_1__c
						, Supplement__c = pricePerServiceId.get(sId).Supplement__c
						, RecordTypeId = UtilsConstants.RT_ID_CSLI_RT_MCM_Contract_Service));
					}
				}
			}
	
			if(!cslisToInsert.isEmpty()) insert cslisToInsert;
		}
		
	}

	/*******************************************************************************
    * @author		Novera - AMU
    * @date		    2020-09-26
	* @description  OAPPMEDCHECK-760 Block unflagging of Specific contract if at least one of the 
					department(s) linked is still active. If all of them are inactive, block if there is 
					already an active general contract.		
    * @param		
    * @return
	* @ticket		OAPPMEDCHECK-760		
    ********************************************************************************/
	public static void checkIfSpecificContractUnflagged(List<Contract_Home__c> recordList, Map<Id,Contract_Home__c> recordOldValueMap)
	{
		Set<Id> ctrIds = new Set<Id>();
		List<Contract_Home__c> ctrHomeToProc = new List<Contract_Home__c>();
		
		Map<Id,List<Account>> accPerCtrId = new Map<Id,List<Account>>();

		for(Contract_Home__c ctrH : recordList)
		{
			if(recordOldValueMap.get(ctrH.Id).Specific_Contract__c==true && ctrH.Specific_Contract__c==false)
			{
				ctrIds.add(ctrH.Id);
				ctrHomeToProc.add(ctrH);
			}
		}

		if(ctrIds!=null && !ctrIds.isEmpty())
		{	
			for(Account acc : [SELECT Id, Active_Department__c, Specific_Contract__c
								FROM Account WHERE Specific_Contract__c IN:ctrIds])
			{
				if(accPerCtrId.containsKey(acc.Specific_Contract__c))  
        		{
					List<Account> accList = accPerCtrId.get(acc.Specific_contract__c);
					accList.add(acc);
					accPerCtrId.put(acc.Specific_Contract__c, accList);
				}
				else {
					accPerCtrId.put(acc.Specific_contract__c, new List<Account>{acc});
				}
			}


			for(Contract_Home__c ctr: recordList)
			{
				List<Account> accList = accPerCtrId.get(ctr.Id);
				Boolean inactiveOrNoAccount = true; 
				if(accList!=null&& !accList.isEmpty())
				{
					for(Account acc : accList)
					{	
						if(acc!=null && acc.Active_Department__c==true)
						{
							inactiveOrNoAccount=false;
							break;
						}
					}
				}				
				if(inactiveOrNoAccount==false)
				{
					ctr.addError(Label.BlockUnflagSpecificContract);
				}
				else
				{
					checkActiveContractPerServiceType(ctrHomeToProc, 'on update');
				}
			}
			
		}
	}

	
	/*******************************************************************************
    * @author		Novera - QLE
    * @date		    2020-09-26
	* @description  OAPPMEDCHECK-317 Changes to the contract demand new version			
    * @param		
    * @return		
    ********************************************************************************/
	public static void checkActiveContractPerServiceType(List<Contract_Home__c> recordList, String onWhat)
	{
		system.debug('AMU checkActiveContractPerServiceType ');
		Set<Id> accIds = new Set<Id>();
		Set<Id> ctrIds = new Set<Id>();
		Map<Id,List<Contract_Home__c>> mapActiveContractsPerAccountId = new Map<Id,List<Contract_Home__c>>();
		Map<Id,Contract_Home__c> mapContractPerAccountId = new Map<Id,Contract_Home__c>();
		
		for(Contract_Home__c ctr : recordList)
		{
			if(ctr.Specific_Contract__c==FALSE)
			{
				accIds.add(ctr.Account__c);
				ctrIds.add(ctr.Id);
				mapContractPerAccountId.put(ctr.Account__c,ctr);
			}
		}
		for(Contract_Home__c ctr : [SELECT Id, Account__c, Service_type__c
							FROM Contract_Home__c
							WHERE Account__c IN:accIds 
							AND Active__c=TRUE AND Specific_Contract__c=FALSE AND Id NOT IN:ctrIds])
		{
			if(mapActiveContractsPerAccountId.containsKey(ctr.Account__c))  
        	{
				List<Contract_Home__c> ctrList = mapActiveContractsPerAccountId.get(ctr.Account__c); 
				ctrList.add(ctr);
				mapActiveContractsPerAccountId.put(ctr.Account__c,ctrList);
			}
			else {
				mapActiveContractsPerAccountId.put(ctr.Account__c,new List<Contract_Home__c>{ctr});
			}
		}
		for(Id accId : mapActiveContractsPerAccountId.keySet())
		{
			List<Contract_Home__c> ctrList = mapActiveContractsPerAccountId.get(accId); 
			Contract_Home__c currentCtr = mapContractPerAccountId.get(accId);
			if((currentCtr!=null && currentCtr.Specific_Contract__c==FALSE &&currentCtr.Version__c==1&&ctrList.size()>0))
			{
				for(Contract_Home__c ctr : ctrList)
				{
					Set<String> existingServiceTypes = new Set<String>();
					Set<String> currentServiceTypes = new Set<String>();
					if(ctr.Service_Type__c!=null) existingServiceTypes.addAll(ctr.Service_Type__c.split(';'));
					if(currentCtr.Service_Type__c!=null)
					{
						currentServiceTypes.addAll(currentCtr.Service_Type__c.split(';'));
					}
					if(currentServiceTypes.removeAll(existingServiceTypes))
					{
						if(onWhat=='on insert')
						{
							if(currentCtr.RecordTypeId==mcmRtOneshotBeId) currentCtr.addError(Label.ActiveContractOneShot);
							else currentCtr.addError(Label.ActiveContractSameServiceType);
						}
						else if(onWhat=='on update') currentCtr.addError(Label.ActiveContractSameServiceTypeSpecifContract);
					}
					else {
						continue;
					}
				}
			}
		}
	}

	/*******************************************************************************
    * @author		Novera - QLE
    * @date		    2020-09-26
	* @description  OAPPMEDCHECK-374 When Invoicing Term change, must resend the invoicing account 		
    * @param		
    * @return		
    ********************************************************************************/
    public static void sendAccountToSAP(List<Contract_Home__c> recordList, Map<Id,Contract_Home__c> oldMap)
    {
		System.debug('QLE ContractHomeManager sendAccountToSAP ');
		String insertOrUpdate = oldMap==null?'insert':'update'; 
		Set<Id> parentAccountIds = new Set<Id>();
		Set<Id> specificContracts = new Set<Id>();
		for(Contract_Home__c ctr : recordList)
		{
			if(!ctr.SAP_No_Synch__c)
			{
				if(ctr.Specific_Contract__c==FALSE){
					if(oldMap==null || (oldMap!=null && ctr.Invoicing_Terms__c!=null && ctr.Invoicing_Terms__c!=oldMap.get(ctr.Id).Invoicing_Terms__c))
					{
						parentAccountIds.add(ctr.Account__c);
					}
				}
				else {
					if(oldMap!=null && ctr.Invoicing_Terms__c!=null && ctr.Invoicing_Terms__c!=oldMap.get(ctr.Id).Invoicing_Terms__c)
					{
						specificContracts.add(ctr.Id);
					}
				}
			}
		}

        Set<Id> primaryIds = new Set<Id>();
        Set<Id> dunningRecicipentIds = new Set<Id>();
		
		for(Account acc : [SELECT Id,ParentId,Use_Official_Address_for_Correspondence__c
					FROM Account WHERE Invoicing_On_This_Account__c='Yes' AND 
					(( Specific_Contract__c=null AND ParentId IN:parentAccountIds) OR (Specific_Contract__c!=null AND Specific_Contract__c IN: specificContracts))])
        {
			if(acc.Use_Official_Address_for_Correspondence__c==TRUE) //correspondence address same as official
            {
            	primaryIds.add(acc.Id);
            }
            else //correspondence address different than official
            {
            	dunningRecicipentIds.add(acc.Id);
			}
			
        }
        if(!Test.isRunningTest())
        {  
			System.debug('QLE ContractHomeManager sendAccountToSAP primaryIds ' + primaryIds);
			System.debug('QLE ContractHomeManager sendAccountToSAP dunningRecicipentIds ' + dunningRecicipentIds);
            //if correspondence address is not filled:send account as 'primary account's
            if(!primaryIds.isEmpty()) AccountManager.sendAccountToSAP(primaryIds,'primaryAccount',insertOrUpdate,'Department');
            /*if correspondence address is filled:
                    - first send account as a 'dunning recipient', with id 'A||contractnbr||deptnr' to SAP with correspondence address
                    - then, send account as 'primary account' with id 'contractnbr||deptnr' to SAP with official address
                    - add its 'dunning recipient' in the record with id 'A||contractnbr||deptnr'
            */
            if(!dunningRecicipentIds.isEmpty()) AccountManager.sendAccountToSAP(dunningRecicipentIds,'dunningRecipient' ,insertOrUpdate,'Department');
        }
    }

	/*******************************************************************************
    * @author		Novera - AMU
    * @date		    2021-04-21
    * @description  OAPPMEDCHECK-805 For FR, on creation of the contract or on update of specific contracts, check presence of invoice recipient
					on the invoicing account
    * @param		List<Contract_Home__c> list of ctrs 
    * @return		voice
    ********************************************************************************/
    
    public static void checkInvoicingRecipient(List<Contract_Home__c> recordList, Map<Id,Contract_Home__c> oldMap)
    {
        Set<Id> invAccIds = new Set<Id>();
        List<Contract_Home__c> ctrToProcess = new List<Contract_Home__c>();
        Map<Id,Id> recipientIdPerInvAccIdMap = new Map<Id,Id>();
        for(Contract_Home__c ctr : recordList)
        {

            if(ctr.Specific_Contract__c == false && oldMap==null && ctr.Is_From_Migration__c==FALSE|| 
			   (oldMap!=null && ctr.Specific_Contract__c == true && ctr.Invoicing_Account__c != oldMap.get(ctr.id).Invoicing_Account__c && ctr.Is_From_Migration__c==FALSE) )
            {
                ctrToProcess.add(ctr);
            }
			if(ctr.Invoicing_Account__c!=null)
			{
				invAccIds.add(ctr.Invoicing_Account__c);
			}
        }

		if(invAccIds!=null)
		{
			for(AccountContactRelation acr : [SELECT  AccountId, ContactId FROM AccountContactRelation 
				WHERE AccountId IN:invAccIds  AND (Invoicing_recipient_email__c=TRUE OR Invoicing_recipient_post__c=TRUE)])
			{
				recipientIdPerInvAccIdMap.put(acr.AccountId,acr.ContactId);
			}
		}
		for(Contract_Home__c ctr : ctrToProcess)
		{
			if(ctr.Invoicing_Account__c==null)
			{
				ctr.addError(Label.contractNoInvoicingAccount);
			}
			else
			{
				Id contactId = recipientIdPerInvAccIdMap!=null?recipientIdPerInvAccIdMap.get(ctr.Invoicing_Account__c):null;
				if(contactId==null)
				{
					ctr.addError(Label.MissingInvoicingRecipient);
				}
			}
		}
	}



	/*******************************************************************************
    * @author		Novera - QLE
    * @date		    2020-09-26
	* @description  OAPPMEDCHECK-375 Collect doctor info to send to SAP for accounting
    * @param		
    * @return		
    ********************************************************************************/
    public static void sendDoctorToSAP(List<Contract_Home__c> recordList, Map<Id,Contract_Home__c> oldMap)
    {
		System.debug('QLE ContractHomeManager sendDoctorToSAP ');
		Set<Id> doctorAccountIds = new Set<Id>();
		for(Contract_Home__c ctr : recordList)
		{
			if(!ctr.SAP_No_Synch__c && oldMap==null)
			{
				doctorAccountIds.add(ctr.Account__c);
			}
		}
		System.debug('QLE ContractHomeManager doctorAccountIds ' + doctorAccountIds);
		if(!Test.isRunningTest())
        {  
			AccountManager.sendDoctorToSAP(doctorAccountIds,'Doctor','insert');
		}
	}

	/*******************************************************************************
    * @author		Novera - QLE
    * @date		    2020-04-13
    * @description  OAPPMEDCHECK-927 Yearly contribution invoice for Specific Contract
    *               e
    * @param	
    * @return		voice
    ********************************************************************************/
    
    public static void createYearlyContributionInvoicing(List<Contract_Home__c> recordList, Map<Id,Contract_Home__c> oldMap)
    {   
		Set<Id> ctrIds = new Set<Id>();
		List<Contractual_Service_Line_Item__c> csliList = new List<Contractual_Service_Line_Item__c>();
		Map<Id, Contract_Home__c> ctrMap = new Map<Id, Contract_Home__c>();
        List<Task> taskToInsert = new List<Task>();
		for(Contract_Home__c ctr : recordList)
        {
			if(ctr.Specific_Contract__c && ctr.Invoicing_Account__c!=null && oldMap!=null && oldMap.get(ctr.Id).Invoicing_Account__c==null)
			{
				ctrMap.put(ctr.Id,ctr);
			}
		}
		csliList= [SELECT Contract_Home__c, Parent_contract_is_specific__c, Parent_Contract_RT__c, Is_From_Versioning__c, Is_From_Migration__c
						, Service__c, PO_Number__c, Price_Rate_1__c
				FROM Contractual_Service_Line_Item__c WHERE Contract_Home__c IN:ctrMap.keySet() 
					AND Service__c =:ContractualServiceLineItemManager.annualFeeFrService.Id 
					AND Is_From_Versioning__c=FALSE AND Is_From_Migration__c=FALSE
					AND Id NOT IN (SELECT Contractual_Service_Line_Item__c FROM InvoiceLineItem__c WHERE RecordTypeId=:UtilsConstants.RT_ID_INVOICE_LINE_ITEM_MEDICAL_CONTROL
					AND CreatedDate = THIS_YEAR)];
		ContractualServiceLineItemManager.createYearlyContributionInvoicing(csliList,ctrMap);
    }


	/*******************************************************************************
    * @author		SLALA
    * @date		    2018 DEC 05
    * @description  Retrieves account information to copy them on the contract record.
					The function was previously a workflow rule. We had to move it here
					in order to avoid 'Uncommited work pending' error when syncing with EDB during mass insert.
    * @param		List<Contract_Home__c> recordList : list of new records values.
    * @return		void
    ********************************************************************************/
	
/*	public static void fillContractHomeAddress(List<Contract_Home__c> recordList, Map<Id, Contract_Home__c> recordOldValueMap)
	{
		List<Contract_Home__c> chCorrespondenceAdressToUpd = new List<Contract_Home__c>();
		List<Contract_Home__c> chOfficialAdressToUpd = new List<Contract_Home__c>();
		Set<Id> accIdsSet = new Set<Id>();
		for(Contract_Home__c ch : recordList)
		{
			if((Trigger.isInsert) || (Trigger.isUpdate && ch.Address_Choice__c != recordOldValueMap.get(ch.id).Address_Choice__c))
			{
				if(ch.Address_Choice__c == 'Account Correspondence Address') chCorrespondenceAdressToUpd.add(ch);
				else if(ch.Address_Choice__c == 'Account Official Address') chOfficialAdressToUpd.add(ch);
				else break;
				accIdsSet.add(ch.Account__c);
			}
		}

		if((chCorrespondenceAdressToUpd.size() + chOfficialAdressToUpd.size()) > 0)
		{
			Map<Id, Account> accMap = new Map<Id,Account>([SELECT id, Correspondence_City__c, Correspondence_Country__c, Correspondence_HouseNrAlpha__c, Correspondence_HouseNr__c, Correspondence_PostalCode__c, Correspondence_Street__c, Official_City__c, Official_Country__c, Official_HouseNr__c, Official_HouseNrAlpha__c, Official_PostalCode__c, Official_Street__c FROM Account WHERE id IN :accIdsSet]);
			
			for(Contract_Home__c ch : chCorrespondenceAdressToUpd)
			{
				ch.Contract_City__c = accMap.get(ch.Account__c).Correspondence_City__c;
				ch.Contract_Country__c = accMap.get(ch.Account__c).Correspondence_City__c;
				ch.Contract_House_Nr_Alpha__c = accMap.get(ch.Account__c).Correspondence_HouseNrAlpha__c;
				ch.Contract_House_Nr__c = accMap.get(ch.Account__c).Correspondence_HouseNr__c;
				ch.Contract_Postal_Code__c = accMap.get(ch.Account__c).Correspondence_PostalCode__c;
				ch.Contract_Street__c = accMap.get(ch.Account__c).Correspondence_Street__c;
			}
			
			for(Contract_Home__c ch : chOfficialAdressToUpd)
			{
				ch.Contract_City__c = accMap.get(ch.Account__c).Official_City__c;
				ch.Contract_Country__c = accMap.get(ch.Account__c).Official_Country__c;
				ch.Contract_House_Nr_Alpha__c = accMap.get(ch.Account__c).Official_HouseNrAlpha__c;
				ch.Contract_House_Nr__c = accMap.get(ch.Account__c).Official_HouseNr__c;
				ch.Contract_Postal_Code__c = accMap.get(ch.Account__c).Official_PostalCode__c;
				ch.Contract_Street__c = accMap.get(ch.Account__c).Official_Street__c;
			}

		}
	}
	*/
	/*******************************************************************************
    * @author		SLALA
    * @date		    2018 DEC 05
    * @description  Updates general account info if Update_this_Section_with_Account_Data__c is flagged
					The function was previously a workflow rule. We had to move it here
					in order to avoid 'Uncommited work pending' error when syncing with EDB during mass insert.
    * @param		List<Contract_Home__c> recordList : list of new records values.
    * @return		void
    ********************************************************************************/
	/*
	public static void updateGeneralAccountInfo(List<Contract_Home__c> recordList)
	{
		List<Contract_Home__c> chToUpd = new List<Contract_Home__c>();
		Set<Id> accIdsSet = new Set<Id>();
		for(Contract_Home__c ch : recordList)
		{
			if(ch.Update_this_Section_with_Account_Data__c) 
			{
				chToUpd.add(ch);
				accIdsSet.add(ch.Account__c);
				ch.Update_this_Section_with_Account_Data__c = false;
			}
		}

		if(chToUpd.size() > 0)
		{
			Map<Id, Account> accMap = new Map<Id,Account>([SELECT id, Fax, Account_Language__c, Account_Mobile__c, Phone FROM Account WHERE id IN :accIdsSet]);
			for(Contract_Home__c ch : chToUpd)
			{
				ch.Contract_Fax__c	= accMap.get(ch.Account__c).Fax;
				ch.Contract_Language_Txt__c	= accMap.get(ch.Account__c).Account_Language__c;
				ch.Contract_Mobile__c	= accMap.get(ch.Account__c).Account_Mobile__c;
				ch.Contract_Phone__c	= accMap.get(ch.Account__c).Phone;
			}
		}
	}
	*/
	/*******************************************************************************
    * @author		SLALA
    * @date		    2018 DEC 05
    * @description  Fill Contract Home Name as 'ProductCode-ContractNumber'
					The function was previously a workflow rule. We had to move it here
					in order to avoid 'Uncommited work pending' error when syncing with EDB during mass insert.
    * @param		List<Contract_Home__c> recordList : list of new records values.
    * @return		void
    ********************************************************************************/
	/*
	public static void fillContractHomeName(List<Contract_Home__c> recordList, Map<Id, Contract_Home__c> recordOldValueMap)
	{
		for(Contract_Home__c ch : recordList)
		{
			if(ch.Contract_Number__c != null)
			{
				ch.Name = ch.Product_Code__c + '-' + ch.Contract_Number__c;
			}
		}
	}
	*/
	/*******************************************************************************
    * @author		SLALA
    * @date		    2018 DEC 05
    * @description  Fill Contract Home Name as 'ProductCode-ContractNumber'
					The function was previously a workflow rule. We had to move it here
					in order to avoid 'Uncommited work pending' error when syncing with EDB during mass insert.
    * @param		List<Contract_Home__c> recordList : list of new records values.
    * @return		void
    ********************************************************************************/
	public static void fillSpecificVATNumber(List<Contract_Home__c> recordList)
	{
		//Set<Id> chIds = new Set<Id>();

		//Account account = new Account([SELECT Id,  Official_Country__c, Official_PostalCode__c FROM Account WHERE Id IN :chIds]);

		for(Contract_Home__c ch : recordList)
		{
/* 			Account acc = new Account(Id= account.id);
			if(acc.Official_Country__c=='FRA')
			{
				if(LEFT(acc.Official_PostalCode__c,3)=-'973' || LEFT(acc.Official_PostalCode__c,3)=='976' )
				{
					ch.Specific_VAT_Picklist__c ='0.00%';
				}
				else if(LEFT(acc.Official_PostalCode__c,3)=='971' || LEFT(acc.Official_PostalCode__c,3)=='972' || 
						LEFT(acc.Official_PostalCode__c,3)=='975') //???? || LEFT(acc.Official_PostalCode__c,3)='976')
				{
					ch.Specific_VAT_Picklist__c ='8.50%';
					
				}
				else
				{
					ch.Specific_VAT_Picklist__c ='20.00%';

				}
			}
			else if(acc.Official_Country__c=='BEL')
			{
				ch.Specific_VAT_Picklist__c ='0.00%';

			} */

			if(ch.Specific_VAT_Picklist__c !=null)
			{
				Integer result = ch.Specific_VAT_Picklist__c.indexOf('%');
				String s2 =ch.Specific_VAT_Picklist__c.left(result);
				ch.Specific_TVA__c = Decimal.valueof(s2); 
			}
		}
	}
}