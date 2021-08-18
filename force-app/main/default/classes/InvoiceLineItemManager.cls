/********************************************************************************************************
* @author         Novera - QLE
* @description    Trigger manager for the Invoice__c object
* @date           2021 JAN 06
* @group          Trigger Managers
*********************************************************************************************************/
public class InvoiceLineItemManager
{
    /**************************************************************************************
    * @author		Novera - QLE
    * @date		    2020-01-06
    * @description  
    * @param		Parameters to create a MCM invoice line
    * @return		An MCM invoice line
    **************************************************************************************/
	public static InvoiceLineItem__c createMCMInvoiceLineItem(Id invoiceId, String description, Integer quantity, Decimal unitPrice,  Id csliID)
	{
		InvoiceLineItem__c invoiceLine= new InvoiceLineItem__c(Invoice__c = invoiceId
                                                                ,Description__c= description
                                                                ,Amount_Excluding_VAT_Currency__c=quantity*unitPrice
                                                                //,Amount_Including_VAT_Currency__c=quantity*unitPrice
                                                                ,Unit_Price__c=unitPrice
                                                                ,Quantity__c=quantity
                                                                ,Contractual_Service_Line_Item__c=csliID
                                                                ,RecordTypeId = UtilsConstants.RT_ID_INVOICE_LINE_ITEM_MEDICAL_CONTROL);
		return invoiceLine;
	}
}