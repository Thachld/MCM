/*******************************************************************************
* @author		Novera - QLE
* @date		    2020-11-26
* @description  Batch to send validated invoices to Scriptura for printing
********************************************************************************/

global class sendInvoiceToScripturaBatch implements Database.Batchable<sObject>, Database.AllowsCallouts
{
    
    //Gets the API parameters from custom settings
    public static final Securex_Service_API__mdt configApiSendInvoiceToScripturaService = SecurexServiceAPI.getSecurexServiceByType(StaticConstants.securexServiceAPI_Type_SendInvoiceToScripturaService);

    global Database.QueryLocator start(Database.BatchableContext bc) 
    {
        return Database.getQueryLocator('SELECT Id, Name, Invoicing_Account__c, Invoicing_Account__r.Name'
                                            + ',Contract_Home__r.Contract_Digit__c, Contract_Home__r.Contract_Country__c'
                                            + ',Contract_Home__r.Name, Contract_Home__r.Next_due_date__c'
                                            + ',Document_Type__c, Document_Date__c, Due_Date__c'
                                            + ',Invoice_Number__c, Billing_Language__c'
                                            + ',Billing_Name__c'
                                            + ',Billing_Name_2__c'
                                            + ',Billing_HouseNr__c'
                                            + ',Billing_Street__c'
                                            + ',Billing_Street_Extension__c'
                                            + ',Billing_Postal_Box__c'
                                            + ',Billing_Postal_Code__c'
                                            + ',Billing_city__c'
                                            + ',Billing_country__c'
                                            + ',Shipping_Name__c'
                                            + ',Shipping_House_Nr__c'
                                            + ',Shipping_Street__c'
                                            + ',Shipping_Street_Extension__c'
                                            + ',Shipping_House_Nr_Alpha__c'
                                            + ',Shipping_Postal_Code__c'
                                            + ',Shipping_city__c'
                                            + ',Shipping_country__c'
                                            + ',Total_excluded_VAT_Currency__c, Total_VAT_Currency__c'
                                            + ',Total_including_VAT_Currency__c, Contact_FirstName__c , Contact_LastName__c'
                                            + ',Specific_VAT__c, PO_Number__c,VAT_Code_Text__c'
                                            + ',RecordTypeId, Invoicing_Type__c, Initial_invoice__r.Invoice_Number__c'
                                            + ',Initial_invoice__r.Document_Date__c,Invoice_Digit_Doctor__c'
        + ' FROM Invoice__c WHERE '
        +'Status__c=\'' + InvoiceManager.INVOICE_STATUS_VALIDATED_BY_SAP+'\'' 
        + ' AND (RecordTypeId=\'' + InvoiceManager.medicalControlRtId + '\'OR RecordTypeId=\'' + InvoiceManager.RT_ID_REMUNERATION_MEDICAL_CONTROL +'\')');
        //+ 'Id IN (\'a1d1j000001B813AAC\')' );
    }

    global void execute(Database.BatchableContext bc, List<Invoice__c> scope)
    {
        System.debug('QLE scope ' + scope); 
        //try{
            
            List<Invoice__c> invoiceToUpdate = new  List<Invoice__c>();
            List<Invoice__c> invoiceToTreat = new  List<Invoice__c>();
            List<Task> insertTask = new  List<Task>();
            Set<Id> invoicingAccountIds = new Set<Id>();
            Set<Id> invoiceIds = new Set<Id>();
            Set<Id> invoiceLineIds = new Set<Id>();
            Map<Id,Account> invoicingAccountPerId = new Map<Id,Account> ();
            Map<Id,List<InvoiceLineItem__c>> linesPerInvoiceId = new  Map<Id,List<InvoiceLineItem__c>>();
            Map<Id,Map<Id,List<Service_Appointment_Line_Item__c>>> IDLPerAccIdPerInvId = new Map<Id,Map<Id,List<Service_Appointment_Line_Item__c>>>();
            for(Invoice__c inv : scope)
            {
                invoiceIds.add(inv.Id);
                invoicingAccountIds.add(inv.Invoicing_Account__c);
            }
            //OAPPMEDCHECK-142 If AccountContactRelation.Invoicing_recipient_email__c!=TRUE no Json (not in scope of this ticket)" 
            for(Account acc : [SELECT Id, Concatenate_Off_PostalCode_Off_City__c, Department_Number__c, Enterprise_Number__c
                            , SIRET_Number__c, Parent__r.SIRET_Number__c, VAT_number_MCM__c, Parent__r.VAT_Number__c , Account_Language__c, Parent_Securex_Number__c, Account_Email__c
                            , RecordTypeId, MID_number__c, RIZIV__c, Registration_Medical_Board__c, VAT_Number__c
                            , (SELECT ContactId, Contact.FirstName, Contact.LastName, Contact.Salutation, Contact.Email, Invoicing_recipient_email__c
                            , Invoicing_recipient_internal_mailbox__c FROM AccountContactRelations WHERE Invoicing_recipient_email__c=TRUE OR Invoicing_recipient_internal_mailbox__c=TRUE OR Invoicing_recipient_post__c=TRUE)
                FROM Account WHERE Id IN: invoicingAccountIds])
            {
                if(acc.RecordTypeId != AccountManager.RT_DOCTOR && !acc.AccountContactRelations.isEmpty() || acc.RecordTypeId==AccountManager.RT_DOCTOR)
                {
                    invoicingAccountPerId.put(acc.Id,acc);
                }
            }
    
            //Invoice Lines
            for(InvoiceLineItem__c lineItem : [SELECT Id, Unit_Price__c, Quantity__c, Amount_Excluding_VAT_Currency__c, Description__c, Invoice__c,
                                                        Invoice__r.Invoicing_Account__r.Invoice_no_detail_page__c,
                                                        (SELECT Service__r.Service_Name_FR__c, Service__r.Service_Name_NL__c FROM Service_Appointment_Line_Items__r) 
                                                        FROM InvoiceLineItem__c WHERE Invoice__c IN:invoiceIds ORDER BY ILI_Order__c ASC])
            {
                if(lineItem.Invoice__r.Invoicing_Account__r.Invoice_no_detail_page__c==false) invoiceLineIds.add(lineItem.Id); //only retrieve detail line for accounts that want it
                if(linesPerInvoiceId.containsKey(lineItem.Invoice__c))
                {
                    List<InvoiceLineItem__c> invoiceLines = linesPerInvoiceId.get(lineItem.Invoice__c);
                    invoiceLines.add(lineItem);
                    linesPerInvoiceId.put(lineItem.Invoice__c,invoiceLines);
                }
                else
                {
                    linesPerInvoiceId.put(lineItem.Invoice__c, new List<InvoiceLineItem__c>{lineItem});
                }
            }
    
            // Must be ordered by department number, date, by employee, by order
            for(Service_Appointment_Line_Item__c sali : [SELECT Id, Amount__c, Name_patient__c, Name_doctor__c, Service_Date__c, Service__r.Service_Name_FR__c, Service__r.Service_Name_NL__c, Your_reference__c, Service_Appointment__r.AppointmentNumber,
                InvoiceLineItem__r.Description__c, InvoiceLineItem__r.Invoice__c, Service_Appointment__r.Absence_Registration__r.External_Reference__c
                ,Service_Appointment__r.Employee__r.Employee_Number__c, Service_Appointment__r.AccountId, Service_Appointment__r.Account.Department_Number__c, Service_Appointment__r.Account.departmentCode_Customer__c
                                    FROM Service_Appointment_Line_Item__c  
                                    WHERE InvoiceLineItem__c IN:invoiceLineIds 
                                    ORDER BY Service_Appointment__r.Account.Department_Number__c ASC, Service_Date__c ASC, Service_Appointment__r.Employee__r.Last_Name__c ASC,  Service_Appointment__r.Employee__r.First_Name__c ASC, Service_Appointment__r.AppointmentNumber ASC, InvoiceLineItem__r.ILI_Order__c ASC])
            {
                Map<Id,List<Service_Appointment_Line_Item__c>> IDLPerAccId =  new Map<Id,List<Service_Appointment_Line_Item__c>>();
                if(IDLPerAccIdPerInvId.containsKey(sali.InvoiceLineItem__r.Invoice__c))
                {
                    IDLPerAccId = IDLPerAccIdPerInvId.get(sali.InvoiceLineItem__r.Invoice__c);
                    if(IDLPerAccId.containsKey(sali.Service_Appointment__r.AccountId))
                    {
                        List<Service_Appointment_Line_Item__c> IDLs = IDLPerAccId.get(sali.Service_Appointment__r.AccountId);
                        IDLs.add(sali);
                        IDLPerAccId.put(sali.Service_Appointment__r.AccountId,IDLs);
                    }
                    else 
                    {
                        IDLPerAccId.put(sali.Service_Appointment__r.AccountId,new List<Service_Appointment_Line_Item__c>{sali});
    
                    }
                    IDLPerAccIdPerInvId.put(sali.InvoiceLineItem__r.Invoice__c,IDLPerAccId);
                }
                else
                {
                    IDLPerAccId.put(sali.Service_Appointment__r.AccountId,new List<Service_Appointment_Line_Item__c>{sali});
                    IDLPerAccIdPerInvId.put(sali.InvoiceLineItem__r.Invoice__c,IDLPerAccId);
                }
            }
    
            for(Invoice__c inv : scope)
            {
                if(invoicingAccountPerId.containsKey(inv.Invoicing_Account__c))
                {
                    Account invoicingAccount = invoicingAccountPerId.get(inv.Invoicing_Account__c);
                    String jsonBody='';
    
                    if(inv.RecordTypeId != InvoiceManager.RT_ID_REMUNERATION_MEDICAL_CONTROL)
                    {
                        if(inv.Invoicing_Type__c.contains('CN'))
                        {
                            // CUSTOMER CREDIT NOTES
                            jsonBody = sendInvoiceToScripturaService.requestsendCreditNotesToScripturaService(inv
                                                                                        ,invoicingAccount
                                                                                        ,invoicingAccount.AccountContactRelations[0]
                                                                                        ,linesPerInvoiceId.get(inv.Id)
                                                                                        ,IDLPerAccIdPerInvId.get(inv.Id));

                        }
                        else{
                            // CUSTOMER INVOICES
                            jsonBody = sendInvoiceToScripturaService.requestsendInvoiceToScripturaService(inv
                                                                                        ,invoicingAccount
                                                                                        ,invoicingAccount.AccountContactRelations[0]
                                                                                        ,linesPerInvoiceId.get(inv.Id)
                                                                                        ,IDLPerAccIdPerInvId.get(inv.Id));
                        }
                    }
                    else
                    {
                        //REMUNERATION
                        jsonBody = sendInvoiceToScripturaService.requestsendRemunerationToScripturaService(inv
                                                                                            ,invoicingAccount
                                                                                            ,linesPerInvoiceId.get(inv.Id)
                                                                                            ,IDLPerAccIdPerInvId.get(inv.Id));
                    }
                    System.debug('QLE jsonBody ' + jsonBody);
                    //Set HTTPRequest Method
                    HttpRequest req = new HttpRequest();
                    req.setMethod('POST');
                    req.setHeader('Content-type', configApiSendInvoiceToScripturaService.Content_Type__c);
                    req.setHeader('Ocp-Apim-Subscription-Key', configApiSendInvoiceToScripturaService.Ocp_Apim_Subscription_Key__c); //Default
                    //req.setHeader('Ocp-Apim-Subscription-Key', 'f2ba0ba769304d5382e631df6d3a6066');
                    req.setHeader('applicationName', configApiSendInvoiceToScripturaService.applicationName__c); //Default
                    req.setHeader('cache-control', configApiSendInvoiceToScripturaService.cache_control__c); //Default
                    req.setHeader('secret', configApiSendInvoiceToScripturaService.secret__c); //Default
                    req.setEndpoint(configApiSendInvoiceToScripturaService.Endpoint__c); //https://securexacc-api.securex.eu/genservices/documentfactoryservice/api/job/batch
                    //System.debug('QLE Ocp-Apim-Subscription-Key ' + configApiSendInvoiceToScripturaService.Ocp_Apim_Subscription_Key__c); 
                    //System.debug('QLE Content-Type ' + configApiSendInvoiceToScripturaService.Content_Type__c); 
                    //System.debug('QLE endPoint ' + configApiSendInvoiceToScripturaService.Endpoint__c); 
                    //req.setEndpoint('https://securextst-api.securex.eu/genservices/documentfactoryservice/api/job/ondemand');
                    req.setBody(jsonBody);
    
                    if(!Test.isRunningTest())
                    {
                        //Execute web service call here
                        Http http = new Http();
                        HttpResponse res = http.send(req);
    
                        if(res.getStatusCode() == 200)
                        {
                            inv.Status__c = InvoiceManager.INVOICE_STATUS_DELIVERED_TO_SCRIPTURA;
                            invoiceToUpdate.add(inv);
                        }
                        else if(res.getStatusCode() == 409)
                        {
                            inv.Status__c = InvoiceManager.INVOICE_STATUS_ERROR_TO_SCRIPTURA;
                            inv.Invoicing_On_Hold__c = true;
                            inv.Error_reason__c = 'Status ' +  res.getStatus() + '. Status Code :  ' + res.getStatusCode() + '.' ;
                            invoiceToUpdate.add(inv);
                            insertTask.add(ServiceAppointmentManager.generateTaskMCMQueue(null,inv.Contract_Home__r.Contract_Country__c.left(2),inv.Id,Label.errorSendingInvoiceToScriptura,Label.errorScriptura,1));
    
                            
                        }
                        else if(res.getStatusCode() == 500)
                        {
                            inv.Status__c = InvoiceManager.INVOICE_STATUS_ERROR_TO_SCRIPTURA;
                            inv.Invoicing_On_Hold__c = true;
                            inv.Error_reason__c = 'Status ' +  res.getStatus() + '. Status Code :  ' + res.getStatusCode() + '.' ;
                            invoiceToUpdate.add(inv);
                            insertTask.add(ServiceAppointmentManager.generateTaskMCMQueue(null,inv.Contract_Home__r.Contract_Country__c.left(2),inv.Id,Label.errorSendingInvoiceToScriptura,Label.error500Scriptura,1));
    
                            
                        }
                        else
                        {
                            inv.Status__c = InvoiceManager.INVOICE_STATUS_ERROR;
                            inv.Invoicing_On_Hold__c = true;
                            inv.Error_reason__c = 'Status ' +  res.getStatus() + '. Status Code :  ' + res.getStatusCode() + '.' ;
                            invoiceToUpdate.add(inv);
                        }
                    }                                                   
                }   
            }
            if(!invoiceToUpdate.isEmpty()) update invoiceToUpdate;
            if(!insertTask.isEmpty()) insert insertTask;

/*         }

        catch(Exception e)
        {
            System.debug('QLE exception ' + e.getMessage()); 
        } */

    } 

    global void finish(Database.BatchableContext bc)
    {
		Invoice_Batch_Result__c result = new Invoice_Batch_Result__c(Batch_Id__c = bc.getJobId()
                                                                            ,Status__c='Completed'
                                                                            ,Invoicing_Type__c=InvoiceManager.SEND_INVOICE_TO_SCRIPTURA); 
        insert result;
    }

}