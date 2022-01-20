/*******************************************************************************
    * @author		Novera - TLE    
    * @date		    2021-07-26
    * @description  Server-side controller of createCreditNote from Invoice lightning web components
    * @param		
    * @return		
    ********************************************************************************/
public with sharing class createCreditNoteController {    

    public class InvoiceWrapper{
        @AuraEnabled
        public string InvoicingType {get;set;}
        @AuraEnabled
        public Boolean IsExist {get;set;}
        @AuraEnabled
        public string CreditNoteId {get;set;}

        @AuraEnabled
        public string CreditNoteNumber {get;set;}
        
    }

    @AuraEnabled(cacheable=true)
    public static InvoiceWrapper getInvoiceInfo(String invoiceId){        
        try {     

            InvoiceWrapper invinfo = new InvoiceWrapper();
            invinfo.InvoicingType = [SELECT Invoicing_Type__c FROM Invoice__c WHERE Id=:invoiceId].Invoicing_Type__c;

            Boolean isExist = false;       
            Invoice__c[] creditNotes = [SELECT Id, Invoice_Number__c FROM Invoice__c WHERE Initial_Invoice__c = :invoiceId AND Document_Type__c = :InvoiceManager.INVOICE_DOCUMENT_TYPE_40];

            if(creditNotes !=null && creditNotes.size() > 0){
                isExist = true;
                invinfo.CreditNoteId = creditNotes[0].Id;
                invinfo.CreditNoteNumber = creditNotes[0].Invoice_Number__c;
            }

            invinfo.IsExist = isExist;
            return invinfo;
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }        
    }   


    /*******************************************************************************
    * @author		Novera - TLE    
    * @date		    2021-07-26
    * @description  OAPPMEDCHECK-684 Create CN for 1 invoice - Get list Service Appointments by Invoice
    * @param invoiceId - Invoice record Id		
    * @return List of Service Appointments		
    ********************************************************************************/

    @AuraEnabled(cacheable=true)
    public static List<ServiceAppointment> getServiceAppointments(String invoiceId){
        try {
            List<ServiceAppointment> result = new List<ServiceAppointment>();

            result = [SELECT Id, AppointmentNumber, Name_patient__c, Employee__c , Service_date__c  
                        FROM ServiceAppointment 
                        WHERE Absence_Registration__r.Invoice__c = :invoiceId];

            return result;
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }



    /*******************************************************************************
    * @author		Novera - TLE    
    * @date		    2021-07-26
    * @description  OAPPMEDCHECK-684 Create CN for 1 invoice - Get list Invoice Detail Lines by Invoice
    * @param invoiceId - Invoice record Id		
    * @return List of Invoice Detail Line
    ********************************************************************************/

    @AuraEnabled(cacheable=true)
    public static List<Service_Appointment_Line_Item__c> getServiceAppointmentLineItems(String invoiceId){
        try {
            List<Service_Appointment_Line_Item__c> result = new List<Service_Appointment_Line_Item__c>();
            
            result = [SELECT Id, Name, Name_patient__c, Service_Appointment__r.Employee__c, 
                        Service__c, Service__r.Name, Service_date__c,Service_Appointment__c, Service_Appointment__r.AppointmentNumber
                    FROM Service_Appointment_Line_Item__c 
                    WHERE Service_Appointment__r.Absence_Registration__r.Invoice__c =:invoiceId
                    AND Invoicing_type__c = :ServiceAppointmentManager.INVOICE_DETAIL_LINE_CI_TYPE];

            return result;
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }


    /*******************************************************************************
    * @author		Novera - TLE    
    * @date		    2021-07-26
    * @description  OAPPMEDCHECK-684 Create CN for 1 invoice - Create Credit Memo by parameter
    * @param invoiceId - Invoice record Id	
    * @param actionType - Action type (ALL, SA, IDL)
    * @param selectedValues - List of value base On Action type
    * @return New Credit Note record
    ********************************************************************************/
    @AuraEnabled
    public static Invoice__c createCreditNote(String invoiceId, String actionType, List<String> selectedValues){

        // System.debug('invoiceId=>' + invoiceId + 'actionType=>' + actionType+ 'selectedValues=>' + selectedValues);
        try {
            Invoice__c newCreditNote = generateCreditNote(invoiceid);

            List<InvoiceLineItem__c> processILIs = new List<InvoiceLineItem__c>();
            Map<String,List<Service_Appointment_Line_Item__c>> mapProcessIDLs = new Map<String,List<Service_Appointment_Line_Item__c>>();
            Set<String> setSelectedValue = new Set<String>();
            setSelectedValue.addAll(selectedValues);

            if(actionType == 'ALL'){
                processILIs = getInvoiceLineItemByInvoice(invoiceId);                
                mapProcessIDLs = getInvoiceDetailLineByInvoice(invoiceId);                
            }else if(actionType == 'SA'){
                Set<String> setILIIds= new Set<String>();
                mapProcessIDLs = getInvoiceDetailLineBySA(setSelectedValue);

                if(mapProcessIDLs != null && mapProcessIDLs.size() > 0){
                    setILIIDs.addAll(mapProcessIDLs.keySet());                                        
                    processILIs = getInvoiceLineItemByIds(setILIIds);
                }

            }else if(actionType == 'IDL'){    
                Set<String> setILIIds= new Set<String>();            
                mapProcessIDLs = getInvoiceDetailLineByIds(setSelectedValue);

                if(mapProcessIDLs != null && mapProcessIDLs.size() > 0){
                    setILIIds.addAll(mapProcessIDLs.keySet());                 
                    processILIs = getInvoiceLineItemByIds(setILIIds);
                }
            }
            
            return doCreate(newCreditNote, processILIs, mapProcessIDLs);
            
            
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }


    /*******************************************************************************
    * @author		Novera - TLE    
    * @date		    2021-07-26
    * @description  Do Create Credit Note and related Objects helper function
    * @param newCreditNote - Initial Credit Note record	
    * @param processILIs - List of process Invoice Line Item records
    * @param processIDLs - List of process Invoice Detail Line records
    * @return New Credit Note record
    ********************************************************************************/

    public static Invoice__c doCreate(Invoice__c newCreditNote, List<InvoiceLineItem__c> processILIs,Map<String,List<Service_Appointment_Line_Item__c>> mapProcessIDLs){
        Savepoint sp;
        try {            
            Map<String,InvoiceLineItem__c> mapInsertILIs = new Map<String,InvoiceLineItem__c>();
            List<Service_Appointment_Line_Item__c> listInsertIDL = new List<Service_Appointment_Line_Item__c>();   
            
            sp = Database.setSavepoint();   
            
            insert newCreditNote;
            
            //Insert Invoice Line Item            
            if(newCreditNote.Invoicing_Type__c == InvoiceManager.INVOICE_TYPE_CN_YEARLY_CONTRIBUTION_INVOICING 
                || newCreditNote.Invoicing_Type__c == InvoiceManager.INVOICE_TYPE_CN_PACK_INVOICING){

                List<InvoiceLineItem__c> insertILI = new List<InvoiceLineItem__c>();
                insertILI = generateInvoiceLineItemByILI(newCreditNote.Id, processILIs);                
                insert insertILI;

            }else {
                // System.debug('processILIs=>' + processILIs.size());
                // System.debug('mapProcessIDLs=>' + mapProcessIDLs.size());                          

                for(InvoiceLineItem__c oldIlI: processILIs){
                    List<Service_Appointment_Line_Item__c> listIDLById = mapProcessIDLs.get(oldIlI.Id);
                    System.debug('listIDLById=>' + listIDLById);
    
                    if(listIDLById != null && listIDLById.size() > 0 ){
                        InvoiceLineItem__c newIli =  new InvoiceLineItem__c();  
    
                        newIli = generateInvoiceLineItemByIDL(newCreditNote.Id, oldIlI, listIDLById);   
                        insert newIli;
                        mapInsertILIs.put(oldIlI.Id, newIli);
                    }
                }                
                
                //Insert Service Appointment Line Detail
                for(String itlId: mapProcessIDLs.keySet()){
                    List<Service_Appointment_Line_Item__c> listIDLById = mapProcessIDLs.get(itlId);
                    InvoiceLineItem__c newIli = mapInsertILIs.get(itlId);
                
                    if(listIDLById != null && listIDLById.size() > 0 && newIli != null){
                        for(Service_Appointment_Line_Item__c idl : listIDLById){
                            Service_Appointment_Line_Item__c newidl = new Service_Appointment_Line_Item__c();
                            newidl = idl.clone(false,false,false,false); 

                            newidl.InvoiceLineItem__c = newIli.Id;
                            newidl.Invoicing_Type__c =  ServiceAppointmentManager.INVOICE_DETAIL_LINE_CN_TYPE;
                            newidl.Amount__c = (idl.Amount__c == null?0: idl.Amount__c) * -1;

                            listInsertIDL.add(newidl);
                        }
                    }                
                }
                
                insert listInsertIDL;
            }

            return newCreditNote;
        } catch (Exception ex) {
            Database.rollback(sp);
            throw new AuraHandledException(ex.getMessage());           
            
        }       
    }


    /*******************************************************************************
    * @author		Novera - TLE    
    * @date		    2021-07-28
    * @description  Initial Invoice Line Item By Service Appointment Line Items
    * @param newCreditnoteId - new Credit Note Id	   
    * @param oldIli - Old Invoice Line Item
    * @param listProcessIdl List Service Appointment Line Items
    * @return Initial Invoice Line Item
    ********************************************************************************/
    public static InvoiceLineItem__c generateInvoiceLineItemByIDL(String newCreditnoteId, InvoiceLineItem__c oldIli,List<Service_Appointment_Line_Item__c> listProcessIdl){
        try {

            Integer quantity = 0; 
            Double totalAmount = 0;
            Double totalKm = 0;
            Boolean isKm = listProcessIdl[0].TECH_Km__c != null? true:false; 
            Id serviceId = listProcessIdl[0].Service__c;
            Boolean isMisc = serviceId == createInvoiceController.miscFrServiceId;     
            
            InvoiceLineItem__c newIlI = oldIli.clone(false,false,false,false);
            newIlI.Invoice__c = newCreditnoteId;

            for(Service_Appointment_Line_Item__c saLineItem : listProcessIdl)
            {
                if(isKm)
                {
                    if(saLineItem.TECH_Km__c!=null)
                    {
                        totalKm = totalKm + saLineItem.TECH_Km__c; 
                    }
                }
                else //leave quantity empty for kmservices and Misc
                {
                    if(saLineItem.Amount__c!=null&&saLineItem.Amount__c!=0){
                        if(!isMisc){
                            quantity = quantity + 1;
                        }
                    }
                }
                if(saLineItem.Amount__c != null ) 
                {
                    totalAmount = totalAmount + saLineItem.Amount__c;  
                }            
            }
            
            // newIlI.Unit_Price__c = isKm&&totalKm>0?totalAmount/totalKm:quantity>0?totalAmount/quantity:null;
            newIlI.Quantity__c = isKm||isMisc?null:quantity;
            newIlI.Amount_Excluding_VAT_Currency__c = totalAmount * -1;
            newIlI.Unit_Price__c = (newIlI.Unit_Price__c==null?0:newIlI.Unit_Price__c) * -1;
            
            return newIlI;

        } catch (Exception ex) {
            throw new AuraHandledException(ex.getMessage());   
        }        
    }


    /*******************************************************************************
    * @author		Novera - TLE    
    * @date		    2021-07-28
    * @description  Initial Invoice Line Item By Service Appointment Line Items
    * @param newCreditnoteId - new Credit Note Id	   
    * @param oldIli - Old Invoice Line Item
    * @param listProcessIdl List Service Appointment Line Items
    * @return Initial Invoice Line Item
    ********************************************************************************/
    public static List<InvoiceLineItem__c> generateInvoiceLineItemByILI(String newCreditnoteId, List<InvoiceLineItem__c> listOldIlis){
        try {            
            List<InvoiceLineItem__c> listInsert = new List<InvoiceLineItem__c>();

            System.debug('listOldIlis=>' + listOldIlis.size());
            for(InvoiceLineItem__c oldIli : listOldIlis){
                InvoiceLineItem__c newIlI = oldIli.clone(false,false,false,false);
                newIlI.Invoice__c = newCreditnoteId;  

                newIlI.Amount_Excluding_VAT_Currency__c = (newIlI.Amount_Excluding_VAT_Currency__c ==null?0:newIlI.Amount_Excluding_VAT_Currency__c) * -1;
                newIlI.Amount_Including_VAT_Currency__c = (newIlI.Amount_Including_VAT_Currency__c== null?0:newIlI.Amount_Including_VAT_Currency__c) * -1;
                newIlI.Amount_Including_VAT__c = (newIlI.Amount_Including_VAT__c==null?0:newIlI.Amount_Including_VAT__c) * -1;
                newIlI.Amount_Excluding_VAT__c = (newIlI.Amount_Excluding_VAT__c==null?0:newIlI.Amount_Excluding_VAT__c) * -1;
                newIlI.Unit_Price__c = (newIlI.Unit_Price__c==null?0:newIlI.Unit_Price__c) * -1;
                listInsert.add(newIlI);
            }

            return listInsert;

        } catch (Exception ex) {
            throw new AuraHandledException(ex.getMessage());            
        }        
    }


    /*******************************************************************************
    * @author		Novera - TLE    
    * @date		    2021-07-26
    * @description  Initial Credit note record by Inovoice Id - helper function
    * @param invoiceId - Invoice Id	   
    * @return Initial Credit note record
    ********************************************************************************/
    public static Invoice__c generateCreditNote(String invoiceId){
        
        Invoice__c fromInv = [SELECT    Account_Name__c,                                         
                                        Contact_FirstName__c, Contact_LastName__c, Contact_Salutation__c, 
                                        Contract_Country_Picklist__c,  Contract_Home__c, 
                                        Currency__c, Customer_Reference__c, Document_Date__c, 
                                        Document_Type__c, Invoicing_Account__c, Invoicing_Terms__c, Invoicing_Type__c, 
                                        Legal_Entity__c, Name, OwnerId, PO_Number__c, RecordTypeId, 
                                        SIRET_Number__c, Initial_Invoice__c,

                                        Billing_City__c, Billing_Country__c, Billing_Destination__c, Billing_HouseNr__c, 
                                        Billing_Language__c, Billing_Postal_Box__c, Billing_Postal_Code__c, 
                                        Billing_Street_Extension__c, Billing_Street__c, Billing_name_2__c,  Billing_name__c, 
                                         
                                        Shipping_City__c, Shipping_Country__c, Shipping_Destination__c, Shipping_House_Nr_Alpha__c, 
                                        Shipping_House_Nr__c, Shipping_Postal_Code__c, Shipping_Street_Extension__c, 
                                        Shipping_Street__c, Shipping_name_2__c, Shipping_name__c, 

                                        Invoicing_on_hold__c,                                         
                                        Specific_VAT__c, Status__c, Structured_Message__c, 
                                        VAT_Code_Text__c, VAT_Number__c 
                                        FROM Invoice__c WHERE Id = :invoiceId];


        Invoice__c creditNoteInv =  fromInv.clone(false,false,false,false);

        creditNoteInv.Initial_Invoice__c = invoiceId;
        creditNoteInv.Invoicing_on_hold__c = false;
        creditNoteInv.Document_Type__c = InvoiceManager.INVOICE_DOCUMENT_TYPE_40;
        creditNoteInv.Status__c = 'Draft';
        creditNoteInv.Document_Date__c = System.today();
        creditNoteInv.ownerId = UserInfo.getUserId();

        if(creditNoteInv.Invoicing_Type__c == InvoiceManager.INVOICE_TYPE_SERVICE_INVOICING){
            creditNoteInv.Invoicing_Type__c = InvoiceManager.INVOICE_TYPE_CN_SERVICE_INVOICING;
        }else if(creditNoteInv.Invoicing_Type__c == InvoiceManager.INVOICE_TYPE_YEARLY_CONTRIBUTION_INVOICING){
            creditNoteInv.Invoicing_Type__c = InvoiceManager.INVOICE_TYPE_CN_YEARLY_CONTRIBUTION_INVOICING;
        }if(creditNoteInv.Invoicing_Type__c == InvoiceManager.INVOICE_TYPE_PACK_INVOICING){
            creditNoteInv.Invoicing_Type__c = InvoiceManager.INVOICE_TYPE_CN_PACK_INVOICING;
        }

        //String invCountry =  creditNoteInv.Contract_Country_Picklist__c;
        
        // switch on invCountry{
        //     when 'BEL' {  
        //         creditNoteInv.Invoice_Digit__c = InvoiceManager.InvoiceDigitCreditFrMCM;
        //     }
        //     when 'FRA' {    
        //         creditNoteInv.Invoice_Digit__c = InvoiceManager.InvoiceDigitCreditFrMCM;
        //     }
        // }        
        
        return creditNoteInv;
    }

    /*******************************************************************************
    * @author		Novera - TLE    
    * @date		    2021-07-26
    * @description  Get List Invoice Line Item By Invoice Id - helper function
    * @param invoiceId - Invoice Id	   
    * @return List of Invoice Line Items
    ********************************************************************************/
    public static List<InvoiceLineItem__c> getInvoiceLineItemByInvoice(String invoiceId){
        
        try {
            List<InvoiceLineItem__c> listILIs= new List<InvoiceLineItem__c>();
            listILIs = [SELECT Id, Description__c,
                                Employee_name__c, Employee_first_name__c,RecordTypeId,ILI_Order__c,Quantity__c,
                                Amount_Including_VAT__c,Amount_Excluding_VAT__c,
                                Invoice__c,Contractual_Service_Line_Item__c,Unit_Price__c,
                                Amount_Including_VAT_Currency__c, Amount_Excluding_VAT_Currency__c
                        FROM InvoiceLineItem__c WHERE Invoice__c =:invoiceId];

            return listILIs;            
        } catch (Exception ex) {
            throw new AuraHandledException(ex.getMessage());
        }

    }

    /*******************************************************************************
    * @author		Novera - TLE    
    * @date		    2021-07-26
    * @description  Get List Invoice Line Item By set of Record Ids - helper function
    * @param setIds - Set of Record Ids
    * @return List of Invoice Line Items
    ********************************************************************************/
    public static List<InvoiceLineItem__c> getInvoiceLineItemByIds(Set<String> setIds){
        
        try {            
            List<InvoiceLineItem__c> listILIs= new List<InvoiceLineItem__c>();

            listILIs = [SELECT  Description__c,Delivery__c,
                                Employee_name__c,Employee_first_name__c,RecordTypeId,ILI_Order__c,Quantity__c,
                                Amount_Including_VAT__c,Amount_Excluding_VAT__c,
                                Invoice__c,Contractual_Service_Line_Item__c,
                                Unit_Price__c,
                                Amount_Including_VAT_Currency__c, Amount_Excluding_VAT_Currency__c
                        FROM InvoiceLineItem__c WHERE Id IN :setIds];

            return listILIs;            
        } catch (Exception ex) {
            throw new AuraHandledException(ex.getMessage());
        }

    }


    /*******************************************************************************
    * @author		Novera - TLE    
    * @date		    2021-07-26
    * @description  Get List Invoice Detail Line By Invoice Id - helper function
    * @param invoiceId - Invoice Id
    * @return Map of InvoiceLineItem as Key and  List of Invoice Detail Lines as value
    ********************************************************************************/
    public static Map<String,List<Service_Appointment_Line_Item__c>> getInvoiceDetailLineByInvoice(String invoiceId){
        try {
            Map<String,List<Service_Appointment_Line_Item__c>> mapIDLs = new Map<String,List<Service_Appointment_Line_Item__c>>();

            for(Service_Appointment_Line_Item__c idl : [SELECT Id, Name, Amount__c, InvoiceLineItem__c, Name_doctor__c, 
                                                        Service_Appointment__c, Service__c, Unit_Price__c,
                                                        TECH_Km__c, Motivation_IDL_change__c 
                                                        FROM Service_Appointment_Line_Item__c 
                                                        WHERE Service_Appointment__r.Absence_Registration__r.Invoice__c = :invoiceId
                                                        AND Invoicing_type__c = :ServiceAppointmentManager.INVOICE_DETAIL_LINE_CI_TYPE]){

                if(mapIDLs.containsKey(idl.InvoiceLineItem__c)){
                    mapIDLs.get(idl.InvoiceLineItem__c).add(idl);
                }else {
                    mapIDLs.put(idl.InvoiceLineItem__c, new List<Service_Appointment_Line_Item__c>{idl});
                }                                
            }
            return mapIDLs;
        } catch (Exception ex) {
            throw new AuraHandledException(ex.getMessage());
        }
    }


    /*******************************************************************************
    * @author		Novera - TLE    
    * @date		    2021-07-26
    * @description  Get List Invoice Detail Line By set of Record Ids - helper function
    * @param setIds - Set of Record Ids
    * @return Map of InvoiceLineItem as Key and  List of Invoice Detail Lines as value
    ********************************************************************************/
    public static Map<String,List<Service_Appointment_Line_Item__c>> getInvoiceDetailLineByIds(Set<String> setIds){
        try {
            Map<String,List<Service_Appointment_Line_Item__c>> mapIDLs = new Map<String,List<Service_Appointment_Line_Item__c>>();
            for(Service_Appointment_Line_Item__c idl :  [SELECT Id, Name, Amount__c, InvoiceLineItem__c, Name_doctor__c, 
                                                        Service_Appointment__c, Service__c,  
                                                        TECH_Km__c, Motivation_IDL_change__c 
                                                        FROM Service_Appointment_Line_Item__c WHERE Id IN :setIds
                                                        AND Invoicing_type__c = :ServiceAppointmentManager.INVOICE_DETAIL_LINE_CI_TYPE]){

                if(mapIDLs.containsKey(idl.InvoiceLineItem__c)){
                    mapIDLs.get(idl.InvoiceLineItem__c).add(idl);
                }else {
                    mapIDLs.put(idl.InvoiceLineItem__c, new List<Service_Appointment_Line_Item__c>{idl});
                }                                
            }
            return mapIDLs;
        } catch (Exception ex) {
            throw new AuraHandledException(ex.getMessage());
        }
    }


    /*******************************************************************************
    * @author		Novera - TLE    
    * @date		    2021-07-26
    * @description  Get List Invoice Detail Line By set of Service Appointment Record Ids - helper function
    * @param setIds - Set of Service Appointment Record Ids
    * @return Map of InvoiceLineItem as Key and  List of Invoice Detail Lines as value
    ********************************************************************************/
    public static Map<String,List<Service_Appointment_Line_Item__c>> getInvoiceDetailLineBySA(Set<String> setSAIds){
        try {
            Map<String,List<Service_Appointment_Line_Item__c>> mapIDLs = new Map<String,List<Service_Appointment_Line_Item__c>>();
            for(Service_Appointment_Line_Item__c idl : [SELECT Id, Name, Amount__c, InvoiceLineItem__c, Name_doctor__c, 
                                                        Service_Appointment__c, Service__c,  
                                                        TECH_Km__c, Motivation_IDL_change__c 
                                                        FROM Service_Appointment_Line_Item__c WHERE Service_Appointment__c IN :setSAIds
                                                        AND Invoicing_type__c = :ServiceAppointmentManager.INVOICE_DETAIL_LINE_CI_TYPE]){

                if(mapIDLs.containsKey(idl.InvoiceLineItem__c)){
                    mapIDLs.get(idl.InvoiceLineItem__c).add(idl);
                }else {
                    mapIDLs.put(idl.InvoiceLineItem__c, new List<Service_Appointment_Line_Item__c>{idl});
                }                                
            }
            return mapIDLs;
        } catch (Exception ex) {
            throw new AuraHandledException(ex.getMessage());
        }
    }

}