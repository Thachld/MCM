/********************************************************************************************************
* @author         Novera - Selim Lalaoui
* @description    Trigger manager for the Invoice__c object
* @date           2018 DEC 20
* @group          Trigger Managers
*********************************************************************************************************/

public class InvoiceManager 
{

	public static final String INVOICE_TYPE_YEARLY_CONTRIBUTION_INVOICING = 'Yearly contribution invoicing';
    public static final String INVOICE_TYPE_SERVICE_INVOICING = 'Service Invoicing';
    public static final String INVOICE_TYPE_END_OF_YEAR_INVOICING = 'End of year invoicing';
	public static final String INVOICE_TYPE_DOCTOR_REMUNERATION = 'Doctor Remuneration';
	public static final String INVOICE_TYPE_PACK_INVOICING = 'Pack invoicing';

	public static final String INVOICE_TYPE_CN_YEARLY_CONTRIBUTION_INVOICING = 'CN - Yearly contribution invoicing';
    public static final String INVOICE_TYPE_CN_SERVICE_INVOICING = 'CN - Service invoicing';   
	public static final String INVOICE_TYPE_CN_PACK_INVOICING = 'CN - Pack invoicing';


	public static final String INVOICE_DOCUMENT_TYPE_30 = '30';
	public static final String INVOICE_DOCUMENT_TYPE_19 = '19';
	public static final String INVOICE_DOCUMENT_TYPE_40 = '40';

    public static final String INVOICE_STATUS_DRAFT = 'Draft';
    public static final String INVOICE_STATUS_ERROR = 'Error';
    public static final String INVOICE_STATUS_ERROR_TO_SCRIPTURA = 'Error to Scriptura';
    public static final String INVOICE_STATUS_VALIDATED_BY_SAP = 'Validated by SAP';
    public static final String INVOICE_STATUS_DELIVERED_TO_SCRIPTURA = 'Delivered to Scriptura';
    public static final String INVOICE_STATUS_SENT_TO_SAP = 'Sent to SAP';

    public static final String MCM_SERVICE_YEARLY_CONTRIBUTION ='Yearly contribution';
    public static final String RT_INVOICE_MEDICAL_CONTROL ='Medical_Control';

	public static final String INVOICE_DETAIL_LINE_CN_TYPE = 'Credit Note - Customer Invoicing';
	public static final String INVOICE_DETAIL_LINE_REMUNERATION_TYPE = 'Doctor Remuneration';
	public static final String INVOICE_DETAIL_LINE_CI_TYPE = 'Customer Invoicing';

	public static Id RT_ID_INVOICE_MEDICAL_CONTROL
	{
		get 
		{
			if(RT_ID_INVOICE_MEDICAL_CONTROL==null)
			{	
				RT_ID_INVOICE_MEDICAL_CONTROL= Schema.SObjectType.Invoice__c.getRecordTypeInfosByDeveloperName().get(RT_INVOICE_MEDICAL_CONTROL).getRecordTypeId();
			} 
			return RT_ID_INVOICE_MEDICAL_CONTROL;
		} 
		set;
	}
	public static final String RT_REMUNERATION_MEDICAL_CONTROL ='MCM_Doctor_Remuneration';
	public static Id RT_ID_REMUNERATION_MEDICAL_CONTROL
	{
		get 
		{
			if(RT_ID_REMUNERATION_MEDICAL_CONTROL==null)
			{	
				RT_ID_REMUNERATION_MEDICAL_CONTROL= Schema.SObjectType.Invoice__c.getRecordTypeInfosByDeveloperName().get(RT_REMUNERATION_MEDICAL_CONTROL).getRecordTypeId();
			} 
			return RT_ID_REMUNERATION_MEDICAL_CONTROL;
		} 
		set;
	}


	// RT Id of the FR Medical Expertise Invoice
	public static Id expertiseMedicalRtId{
        get{
            if(expertiseMedicalRtId==null){
                Id rtId = Schema.SObjectType.Invoice__c.getRecordTypeInfosByName().get('Expertise Medical').getRecordTypeId();
                expertiseMedicalRtId = rtId;
            }
            return expertiseMedicalRtId;
        }
        set;
	}  
	
	// RT Id of the MCM Invoice
	public static Id medicalControlRtId{
        get{
            if(medicalControlRtId==null){
                Id rtId = Schema.SObjectType.Invoice__c.getRecordTypeInfosByName().get('Medical Control').getRecordTypeId();
                medicalControlRtId = rtId;
            }
            return medicalControlRtId;
        }
        set;
	}
	
	// public static Integer InvoiceDigitExpMed 
	// {
	// 	get
	// 	{
	// 		if(InvoiceDigitExpMed == null && expertiseMedicalRtId!=null)
	// 		{
	// 			AggregateResult[] maxNumber = [SELECT MAX(Invoice_Digit__c) maxNumber FROM Invoice__c WHERE Document_Date__c = THIS_YEAR 
	// 										AND RecordTypeId =:expertiseMedicalRtId];

	// 			if(maxNumber[0].get('maxNumber') != null) InvoiceDigitExpMed = Integer.valueOf(maxNumber[0].get('maxNumber')) + 1;
				
	// 			else InvoiceDigitExpMed = 0;
	// 		}
	// 		return InvoiceDigitExpMed++;
	// 	}
	// }

	public static Integer InvoiceDigitExpMed 
	{
		get
		{
			if(InvoiceDigitExpMed == null && expertiseMedicalRtId!=null)
			{
				AggregateResult[] maxNumber = [SELECT MAX(Invoice_Digit__c) maxNumber FROM Invoice__c WHERE Document_Date__c = THIS_YEAR 
											AND RecordTypeId =:expertiseMedicalRtId
											AND Document_Type__c='32' ];

				if(maxNumber[0].get('maxNumber') != null) InvoiceDigitExpMed = Integer.valueOf(maxNumber[0].get('maxNumber')) + 1;
				
				else InvoiceDigitExpMed = 0;
			}
			return InvoiceDigitExpMed++;
		}
		set;
	}
	
	public static Integer InvoiceDigitExpMedCredit {
		get {
			if(InvoiceDigitExpMedCredit == null)
			{
				AggregateResult[] maxNumberCredit = [SELECT MAX(Invoice_Digit__c) maxNumberCredit FROM Invoice__c WHERE Document_Date__c = THIS_YEAR
											AND RecordTypeId =:expertiseMedicalRtId
											AND Document_Type__c = '42' ];
				
				if(maxNumberCredit[0].get('maxNumberCredit') != null) InvoiceDigitExpMedCredit = Integer.valueOf(maxNumberCredit[0].get('maxNumberCredit')) + 1;
				
				else InvoiceDigitExpMedCredit = 0;
			}
			return InvoiceDigitExpMedCredit++;
		}
		set;
	}

	public static Integer InvoiceDigitFrMCM
	{
		get
		{
			if(InvoiceDigitFrMCM == null && RT_ID_INVOICE_MEDICAL_CONTROL!=null)
			{
				AggregateResult[] maxNumber = [SELECT MAX(Invoice_Digit__c) maxNumber FROM Invoice__c WHERE Document_Date__c = THIS_YEAR 
											AND RecordTypeId =:RT_ID_INVOICE_MEDICAL_CONTROL
											AND Contract_Country_Picklist__c='FRA'
											AND Document_Type__c = '30'];

				if(System.today().year()!=2021)
				{
					if(maxNumber[0].get('maxNumber') != null) InvoiceDigitFrMCM = Integer.valueOf(maxNumber[0].get('maxNumber')) + 1;
					
					else InvoiceDigitFrMCM = 0;
				}
				else 
				{
					if(maxNumber[0].get('maxNumber') != null && Integer.valueOf(maxNumber[0].get('maxNumber')) >= 4000) InvoiceDigitFrMCM = Integer.valueOf(maxNumber[0].get('maxNumber')) + 1;
					
					else InvoiceDigitFrMCM = 4000;
				}
			}
			return InvoiceDigitFrMCM++;
		}
		set;
	}	
	
	public static Integer InvoiceDigitBeMCM
	{
		get
		{
			if(InvoiceDigitBeMCM == null && RT_ID_INVOICE_MEDICAL_CONTROL!=null)
			{
				AggregateResult[] maxNumber = [SELECT MAX(Invoice_Digit__c) maxNumber FROM Invoice__c WHERE Document_Date__c = THIS_YEAR 
										AND RecordTypeId =:RT_ID_INVOICE_MEDICAL_CONTROL 
										AND Contract_Country_Picklist__c='BEL'
										AND Document_Type__c = '30'];

				if(System.today().year()!=2021)
				{
					if(maxNumber[0].get('maxNumber') != null) InvoiceDigitBeMCM = Integer.valueOf(maxNumber[0].get('maxNumber')) + 1;
				
					else InvoiceDigitBeMCM = 0;
				}
				else 
				{
					if(maxNumber[0].get('maxNumber') != null && Integer.valueOf(maxNumber[0].get('maxNumber')) >= 4000) InvoiceDigitBeMCM = Integer.valueOf(maxNumber[0].get('maxNumber')) + 1;
				
					else InvoiceDigitBeMCM = 4000;
				}
			}
			return InvoiceDigitBeMCM++;
		}
		set;
	}

	//OAPPMEDCHECK-684
	public static Integer InvoiceDigitCreditFrMCM
	{
		get
		{
			if(InvoiceDigitCreditFrMCM == null && RT_ID_INVOICE_MEDICAL_CONTROL!=null)
			{
				AggregateResult[] maxNumber = [SELECT MAX(Invoice_Digit__c) maxNumber FROM Invoice__c WHERE Document_Date__c = THIS_YEAR 
											AND RecordTypeId =:RT_ID_INVOICE_MEDICAL_CONTROL
											AND Contract_Country_Picklist__c='FRA'
											AND Document_Type__c = '40'];

				if(System.today().year()!=2021)
				{
					if(maxNumber[0].get('maxNumber') != null) InvoiceDigitCreditFrMCM = Integer.valueOf(maxNumber[0].get('maxNumber')) + 1;
					
					else InvoiceDigitCreditFrMCM = 0;
				}
				else 
				{
					if(maxNumber[0].get('maxNumber') != null && Integer.valueOf(maxNumber[0].get('maxNumber')) >= 4000) InvoiceDigitCreditFrMCM = Integer.valueOf(maxNumber[0].get('maxNumber')) + 1;
					
					else InvoiceDigitCreditFrMCM = 4000;
				}
			}
			return InvoiceDigitCreditFrMCM++;
		}
		set;
	}


	//OAPPMEDCHECK-684
	public static Integer InvoiceDigitCreditBeMCM
	{
		get
		{
			if(InvoiceDigitCreditBeMCM == null && InvoiceDigitCreditBeMCM!=null)
			{
				AggregateResult[] maxNumber = [SELECT MAX(Invoice_Digit__c) maxNumber FROM Invoice__c WHERE Document_Date__c = THIS_YEAR 
										AND RecordTypeId =:RT_ID_INVOICE_MEDICAL_CONTROL 
										AND Contract_Country_Picklist__c='BEL'
										AND Document_Type__c = '40'];

				if(System.today().year()!=2021)
				{
					if(maxNumber[0].get('maxNumber') != null) InvoiceDigitCreditBeMCM = Integer.valueOf(maxNumber[0].get('maxNumber')) + 1;
				
					else InvoiceDigitCreditBeMCM = 0;
				}
				else 
				{
					if(maxNumber[0].get('maxNumber') != null && Integer.valueOf(maxNumber[0].get('maxNumber')) >= 4000) InvoiceDigitCreditBeMCM = Integer.valueOf(maxNumber[0].get('maxNumber')) + 1;
				
					else InvoiceDigitCreditBeMCM = 4000;
				}
			}
			return InvoiceDigitCreditBeMCM++;
		}
		set;
	}

	//OAPPMEDCHECK-817
	public static Integer InvoiceDigitRemunerationFrMCM 
	{
		get
		{
			if(InvoiceDigitRemunerationFrMCM == null && RT_ID_REMUNERATION_MEDICAL_CONTROL!=null)
			{
				AggregateResult[] maxNumber = [SELECT MAX(Invoice_Digit__c) maxNumber FROM Invoice__c WHERE Document_Date__c = THIS_YEAR 
											AND RecordTypeId =:RT_ID_REMUNERATION_MEDICAL_CONTROL
											AND Contract_Country_Picklist__c='FRA'];

				if(System.today().year()!=2021)
				{
					if(maxNumber[0].get('maxNumber') != null) InvoiceDigitRemunerationFrMCM = Integer.valueOf(maxNumber[0].get('maxNumber')) + 1;
					
					else InvoiceDigitRemunerationFrMCM = 0;
				}
				else 
				{
					if(maxNumber[0].get('maxNumber') != null && Integer.valueOf(maxNumber[0].get('maxNumber')) >= 4000) InvoiceDigitRemunerationFrMCM = Integer.valueOf(maxNumber[0].get('maxNumber')) + 1;
					
					else InvoiceDigitRemunerationFrMCM = 4000;
				}
			}
			return InvoiceDigitRemunerationFrMCM++;
		}
		set;
	}

	//OAPPMEDCHECK-817
	public static Integer InvoiceDigitRemunerationBeMCM 
	{
		get
		{
			if(InvoiceDigitRemunerationBeMCM == null && RT_ID_REMUNERATION_MEDICAL_CONTROL!=null)
			{
				AggregateResult[] maxNumber = [SELECT MAX(Invoice_Digit__c) maxNumber FROM Invoice__c WHERE Document_Date__c = THIS_YEAR 
										AND RecordTypeId =:RT_ID_REMUNERATION_MEDICAL_CONTROL 
										AND Contract_Country_Picklist__c='BEL'];

				if(System.today().year()!=2021)
				{
					if(maxNumber[0].get('maxNumber') != null) InvoiceDigitRemunerationBeMCM = Integer.valueOf(maxNumber[0].get('maxNumber')) + 1;
				
					else InvoiceDigitRemunerationBeMCM = 0;
				}
				else 
				{
					if(maxNumber[0].get('maxNumber') != null && Integer.valueOf(maxNumber[0].get('maxNumber')) >= 4000) InvoiceDigitRemunerationBeMCM = Integer.valueOf(maxNumber[0].get('maxNumber')) + 1;
				
					else InvoiceDigitRemunerationBeMCM = 4000;
				}
			}
			return InvoiceDigitRemunerationBeMCM++;
		}
		set;
	}
	public static Set<String> europeanCountries
	{
		get
		{
			if(europeanCountries == null)
			{
				Set<String> countries = new Set<String>();
				for(Country_NIS__c c : [ SELECT Country_Code__c FROM Country_NIS__c WHERE European_Country__c=TRUE])
				{
					countries.add(c.Country_Code__c);
				}
				europeanCountries = countries;
			}
			return europeanCountries;
		}
		set;
	}


	public static void fillInvoiceDigit(List<Invoice__c> recordList)
	{
		for(Invoice__c iv : recordList)
		{	
			// For the Medical Expertise FR Invoices
			if(iv.RecordTypeId==expertiseMedicalRtId)
			{
				// Comment in order to be able to deploy MCM package
				if (iv.Document_Type__c == '32') {
					iv.Invoice_Digit__c = InvoiceDigitExpMed;
				}
				else if (iv.Document_Type__c == '42') {
					iv.Invoice_Digit__c = InvoiceDigitExpMedCredit;
				}
			}
			
			// For the MCM Invoices 
			else if(iv.RecordTypeId==RT_ID_INVOICE_MEDICAL_CONTROL)
			{
				String invCountry =  iv.Contract_Country_Picklist__c;
				if(iv.Document_Type__c == '30'){
					switch on invCountry{
						when 'BEL' {  
							iv.Invoice_Digit__c = InvoiceDigitBeMCM;
						}
						when 'FRA' {    
							iv.Invoice_Digit__c = InvoiceDigitFrMCM ;
						}
					}
				}
				else if(iv.Document_Type__c == '40'){
					switch on invCountry{
						when 'BEL' {  
							iv.Invoice_Digit__c = InvoiceDigitCreditBeMCM;
						}
						when 'FRA' {    
							iv.Invoice_Digit__c = InvoiceDigitCreditFrMCM;
						}
					}
				}	
			}
			// For the MCM Remuneration
			else if(iv.RecordTypeId==RT_ID_REMUNERATION_MEDICAL_CONTROL)
			{
				String invCountry =  iv.Contract_Country_Picklist__c;
				switch on invCountry{
                    when 'BEL' {  
						iv.Invoice_Digit__c = InvoiceDigitRemunerationBeMCM;
					}
					when 'FRA' {    
						iv.Invoice_Digit__c = InvoiceDigitRemunerationFrMCM ;
					}
				}
			}
		}
	}

	/**************************************************************************************
    * @author		Novera - QLE
    * @date		    2020-02-05
    * @description  OAPPMEDCHECK-373 Error handling
    * @param		
    **************************************************************************************/
	public static void InvoicingOnHoldUnflagged(List<Invoice__c> recordList, Map<Id,Invoice__c> oldMap)
	{
		for(Invoice__c inv : recordList)
		{
			if(inv.Invoicing_On_Hold__c==false && inv.Invoicing_On_Hold__c!=oldMap.get(inv.Id).Invoicing_On_Hold__c)
			{
				if(inv.Status__c == InvoiceManager.INVOICE_STATUS_ERROR)
				{
					inv.Status__c = StaticConstants.INVOICE_STATUS_DRAFT;
					inv.Error_reason__c = '';
				}
				else if(inv.Status__c == InvoiceManager.INVOICE_STATUS_ERROR_TO_SCRIPTURA)
				{
					inv.Status__c = InvoiceManager.INVOICE_STATUS_VALIDATED_BY_SAP;
					inv.Error_reason__c = '';
				}
			}
		}
	}

	/**************************************************************************************
    * @author		Novera - QLE
    * @date		    2020-01-26
    * @description  OAPPMEDCHECK-510 (multiple tickets) fill information on invoice based
					on account information
    * @param		
    **************************************************************************************/
	public static void fillInvoiceInformation(List<Invoice__c> recordList)
	{
		Set<Id> invAccIdSet = new Set<Id>();
		Set<Id> ctrIdSet = new Set<Id>();
		for(Invoice__c inv : recordList)
		{
			if(inv.Document_type__c  != '40'){
				if(inv.Invoicing_Account__c!=null) invAccIdSet.add(inv.Invoicing_Account__c);
				if(inv.Contract_Home__c!=null) ctrIdSet.add(inv.Contract_Home__c); 
			}			
		}
		Map<Id,Account> accountMap = new Map<Id,Account>([SELECT Id,Name,Official_Address_Name__c,Official_address_name_2__c
								,Official_HouseNrAlpha__c,Official_HouseNr__c,Official_street__c,Official_Street_Extension__c
								,Official_city__c,Official_PostalCode__c,Official_country__c,Correspondence_Name__c
								,Correspondence_Name_2__c,Correspondence_HouseNrAlpha__c,Correspondence_HouseNr__c,Correspondence_street__c
								,Correspondence_Street_Extension__c,Correspondence_city__c,Correspondence_PostalCode__c,Correspondence_country__c
								,SIRET_Number__c,VAT_Number__c,Account_Language__c,Use_Official_Address_for_Correspondence__c 
								,(SELECT FirstName, LastName, Salutation FROM Contacts)
								,(SELECT ContactId, Contact.FirstName, Contact.LastName, Contact.Salutation 
									FROM AccountContactRelations WHERE Invoicing_recipient_email__c=TRUE OR Invoicing_recipient_post__c=TRUE)
							FROM Account WHERE Id IN:invAccIdSet]);
		Map<Id,Contract_Home__c> ctrMap = new Map<Id,Contract_Home__c>([SELECT Id,Account__r.Official_PostalCode__c,Account__r.Official_country__c
											FROM Contract_Home__c WHERE Id IN:ctrIdSet]);
		for(Invoice__c inv : recordList)
		{	
			//Exclude Credit note
			if(inv.Document_type__c  != '40'){
				Account invAcc = accountMap.get(inv.Invoicing_Account__c);
				if(invAcc!=null)
				{
					inv.Billing_Name__c = invAcc.Official_Address_Name__c!=null?invAcc.Official_Address_Name__c:invAcc.Name; //OAPPMEDCHECK-142
					inv.Billing_Name_2__c = invAcc.Official_address_name_2__c; //OAPPMEDCHECK-732
					inv.Billing_HouseNr__c = invAcc.Official_HouseNr__c;
					inv.Billing_Street__c = invAcc.Official_street__c;
					inv.Billing_Street_Extension__c = invAcc.Official_Street_Extension__c;
					inv.Billing_Postal_Box__c = invAcc.Official_HouseNrAlpha__c;
					inv.Billing_Postal_Code__c = invAcc.Official_PostalCode__c;
					inv.Billing_city__c = invAcc.Official_city__c;
					inv.Billing_country__c = invAcc.Official_country__c;
					if(inv.Document_Type__c==INVOICE_DOCUMENT_TYPE_30)
					{
						inv.Shipping_Name__c = invAcc.Correspondence_name__c;
						inv.Shipping_House_Nr__c = invAcc.Correspondence_HouseNr__c;
						inv.Shipping_Street__c = invAcc.Correspondence_street__c;
						inv.Shipping_Street_Extension__c = invAcc.Correspondence_Street_Extension__c;
						inv.Shipping_House_Nr_Alpha__c = invAcc.Correspondence_HouseNrAlpha__c;
						inv.Shipping_Postal_Code__c = invAcc.Correspondence_PostalCode__c;
						inv.Shipping_city__c = invAcc.Correspondence_city__c;
						inv.Shipping_country__c = invAcc.Correspondence_country__c;
					}
					inv.SIRET_Number__c = invAcc.SIRET_Number__c;
					inv.VAT_Number__c = invAcc.VAT_Number__c;
					AccountContactRelation accContRel = !invAcc.AccountContactRelations.isEmpty()?invAcc.AccountContactRelations[0]:null;
					if(inv.Document_Type__c==INVOICE_DOCUMENT_TYPE_30)
					{
						if(accContRel!=null)
						{
							inv.Contact_FirstName__c = accContRel.Contact.FirstName;
							inv.Contact_LastName__c =  accContRel.Contact.LastName;
							inv.Contact_Salutation__c =  accContRel.Contact.Salutation;
						}
						else
						{
							inv.Status__c=StaticConstants.INVOICE_STATUS_ERROR;
							inv.Invoicing_On_Hold__c = true;
							inv.Error_reason__c = Label.NoInvoicingContact;
						}
					}
					else if (inv.Document_Type__c==INVOICE_DOCUMENT_TYPE_19)
					{
						inv.Contact_FirstName__c = invAcc.Contacts[0].FirstName;
						inv.Contact_LastName__c =  invAcc.Contacts[0].LastName;
						inv.Contact_Salutation__c = invAcc.Contacts[0].Salutation;
					}
				}
				else {
					inv.Status__c = StaticConstants.INVOICE_STATUS_ERROR;
					inv.Invoicing_On_Hold__c = true;
					inv.Error_reason__c = Label.NoInvoicingAccount;
				}

				//OAPPMEDCHECK-510 - Fill VAT Code for customer invoice
				if(inv.Document_Type__c==INVOICE_DOCUMENT_TYPE_30)
				{
					if(inv.Contract_Country_Picklist__c=='BEL')
					{
						inv.VAT_Code_Text__c='00';
					}
					else if(inv.Contract_Country_Picklist__c=='FRA')
					{
						Contract_Home__c ctr = ctrMap.get(inv.Contract_Home__c); 
						if(inv.Specific_VAT__c==null || inv.Specific_VAT__c==0.00)
						{
							if(ctr.Account__r.Official_Country__c=='FRA')
							{
								if( (ctr.Account__r.Official_PostalCode__c!=null && (ctr.Account__r.Official_PostalCode__c.left(3)=='973'
								|| ctr.Account__r.Official_PostalCode__c.left(3)=='976') )
								|| !europeanCountries.contains(ctr.Account__r.Official_Country__c))
								{
									inv.VAT_Code_Text__c='O0';
								}
								else 
								{
									inv.VAT_Code_Text__c='O5';
								}
							}
							else {
								inv.VAT_Code_Text__c='O5';
							}
						}
						else if(inv.Specific_VAT__c==8.50)
						{
							inv.VAT_Code_Text__c='OA';
						}
						else 
						{
							inv.VAT_Code_Text__c='C1';
						}
					}
				}
				//Fill VAT Code for doctor remuneration - OAPPMEDCHECK-817
				else if(inv.Document_Type__c==INVOICE_DOCUMENT_TYPE_19) 
				{
					if(inv.Contract_Country_Picklist__c=='BEL')
					{
						//TO DO?
					} 
					else if(inv.Contract_Country_Picklist__c=='FRA')
					{
						if(inv.Specific_VAT__c == null || inv.Specific_VAT__c==0.00)
						{
							inv.VAT_Code_Text__c = 'P5';
						}
						else
						{
							inv.VAT_Code_Text__c = 'R1';
						}
						/* if(inv.Invoicing_Account__r.Subject_to_VAT__c == false)
						{
							inv.VAT_Code_Text__c = 'P5';
						}
						else if(inv.Invoicing_Account__r.Subject_to_VAT__c == true) 
						{
							inv.VAT_Code_Text__c = 'R1';
						} */
					}
				}
			}
		}
	}

	/**************************************************************************************
    * @author		Novera - QLE
    * @date		    2020-01-26
    * @description  OAPPMEDCHECK-530 Invoice - structured message (BE)
    * @param		
    **************************************************************************************/
	public static void fillStructuredMessage(List<Invoice__c> recordList)
	{
		for(Invoice__c inv : recordList)
		{
			if(inv.Contract_Country_Picklist__c=='BEL' && inv.Document_Type__c!=null && inv.Document_Year__c!=null && inv.Invoice_Digit__c!=null)
			{
				String invoiceNumber = inv.Document_Type__c + inv.Document_Year__c.right(2) + String.valueOf(inv.Invoice_Digit__c).leftPad(6,'0');
				Long remainder = Math.mod(Long.valueOf(invoiceNumber),97);
				if(remainder==0) remainder = 97;
				inv.Structured_Message__c = invoiceNumber + String.valueOf(remainder).leftPad(2,'0');
			}
		}
	}

	
    /**************************************************************************************
    * @author		Novera - QLE
    * @date		    2020-10-29
    * @description  
    * @param		Parameters to create a MCM invoice
    * @return		An MCM invoice
    **************************************************************************************/
	public static Invoice__c createMCMInvoice(String docType, String lg , String invoicingType, String invoiceStatus, Id contractHomeId, String contractHomeCountry
					, String invoicingTerm, Id invoicingAccId, Id invoiceBatchResultId, String errorReason, Decimal specificVAT, String poNum, Id rtId)
	{
		Invoice__c invoice = new Invoice__c(Document_Date__c = System.today()
													,Invoicing_Type__c = invoicingType
													,Status__c=invoiceStatus
													,Contract_Home__c=contractHomeId
													,Contract_Country_Picklist__c = contractHomeCountry
													,Invoicing_Account__c=invoicingAccId
													,Invoicing_Terms__c= invoicingTerm
													,Generated_by_batch__c=invoiceBatchResultId
													,RecordTypeId = rtId 
													,Error_reason__c=errorReason
													,Document_Type__c = docType
													,Specific_VAT__c = specificVAT
													,PO_Number__c = poNum
													,Billing_Language__c = lg);
		return invoice;
	}

	public static List<Invoice__c> processSaveResult(List<sObject> sObjectList,Database.SaveResult[] saveResults)
	{
		List<Invoice__c> invList = new List<Invoice__c>();
		Set<Id> alreadyProcessed = new Set<Id>();
		for(Integer idx = 0; idx < saveResults.size(); idx++)
		{   
			if (!saveResults[idx].isSuccess()) 
			{
				sObject obj = sObjectList[idx];
				Id invoiceId;
				String errText = '';
				for(Database.Error err : saveResults[idx].getErrors()) 
				{
					errText = errText + ' ' + err.getMessage();
				}        
				if(obj instanceof InvoiceLineItem__c)
				{
					InvoiceLineItem__c invline = (InvoiceLineItem__c) obj;
					invoiceId = invline.Invoice__c;
				} 
				else if(obj instanceof Absence_Registration__c)
				{
					Absence_Registration__c ar = (Absence_Registration__c) obj;
					invoiceId = ar.Invoice__c;
				}
				else if(obj instanceof ServiceAppointment)
				{
					ServiceAppointment ar = (ServiceAppointment) obj;
					invoiceId = ar.Remuneration_Note__c;
				}

				if(!alreadyProcessed.contains(invoiceId))
				{
					Invoice__c inv = new Invoice__c(Id=invoiceId,Status__c=StaticConstants.INVOICE_STATUS_ERROR,Error_reason__c=errText,Invoicing_On_Hold__c=true);
					invList.add(inv);
				}
			}
		}
		return invList;
	}

}