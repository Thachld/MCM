/*******************************************************************************
* @author		Novera - QLE
* @date		    2020-11-26
* @description  Callout to Scriptura service for printing
********************************************************************************/

public without sharing class sendInvoiceToScripturaService 
{ 
    public static Map<String, Map<String,String>> countryTranslation{
        get{
            if(countryTranslation==null)
            {
                Map<String, Map<String,String>> translation = new Map<String, Map<String,String>>();
                Map<String,String> translationNL = new  Map<String,String>();
                Map<String,String> translationFR = new  Map<String,String>();
                for(Country_NIS__c cn : [SELECT Country_Code__c, Country_Name_FR_Short__c, Country_Name_NL_Short__c FROM Country_NIS__c WHERE Country_Code__c!=null])
                {             
                    translationNL.put(cn.Country_Code__c,cn.Country_Name_NL_Short__c);
                    translationFR.put(cn.Country_Code__c,cn.Country_Name_FR_Short__c);
                    
                }
                translation.put('NL',translationNL);
                translation.put('FR',translationFR);
                countryTranslation = translation;
            } 
            return countryTranslation;
        }
        set;
    }

    //Remuneration
    public static String requestsendRemunerationToScripturaService(Invoice__c inv, Account invoicingAccount, List<InvoiceLineItem__c> invLineItemList, Map<Id,List<Service_Appointment_Line_Item__c>> saliPerAccId)
    {
        List<Invoice__c> invoiceToUpdate = new List<Invoice__c>();
        String contractCountry = inv.Contract_Home__r.Contract_Country__c; 
        String invLanguage = inv.Billing_Language__c=='NL'?'NL':'FR'; 
        String dptNumber = invoicingAccount.Department_Number__c!=null?String.valueOf(invoicingAccount.Department_Number__c).leftPad(3,'0'):'';
        DateTime docDate = inv.Document_Date__c;
        DateTime firstDayOfMonth = System.today().addMonths(-1).toStartOfMonth(); //Invoicing process is launched for services of last month
        DateTime lastDayOfMonth = firstDayOfMonth.addMonths(1).addDays(-1);

        sendInvoiceToScripturaServiceRequest requestData = new sendInvoiceToScripturaServiceRequest();

        requestData.processType = 'batch'; //Default 'batch'
        String documentName = '';
        switch on invLanguage {
            when 'NL'  {
                documentName = 'MCM - Onkostennota dokter - ' + inv.Invoice_Number__c; //OAPPMEDCHECK-945
            }
            when else {
                documentName = 'CVM - Note honoraire - ' + inv.Invoice_Number__c; //OAPPMEDCHECK-945
            }
        }
        //requestData.documentNaam = invLanguage=='NL'?'MCM - Onkostennota dokter':'CVM - Note honoraire'; //OAPPMEDCHECK-820
        requestData.documentNaam = documentName;
        requestData.eventFlow = 'archive'; //OAPPMEDCHECK-946
        requestData.templateSet = contractCountry=='BEL'?'MCM/HonoraireMCM':'MCM/HonoraireSMS'; //Default 'FactuurMCM'
        requestData.cdws = buildCdws(inv,invoicingAccount, contractCountry, invLanguage);
        requestData.contact = buildContactInfo(inv,invoicingAccount, null);
        requestData.datas = buildData(inv, invoicingAccount,null,dptNumber, invLineItemList, firstDayOfMonth, lastDayOfMonth, saliPerAccId, invLanguage);
        requestData.emails = buildEmail(inv,invoicingAccount, docDate, dptNumber, contractCountry, invLanguage);
        if(contractCountry=='FRA')
        {
            System.debug('QLE requestData.neotouches contractCountry ' + contractCountry);
            requestData.neotouches = buildFileName(inv, contractCountry); //OAPPMEDCHECK-946
            requestData.jobFlowDatas = buildJobFlowData(contractCountry);   
        }
        String jsonBody = JSON.serializePretty(requestData, true);
        //System.debug('jsonBody ' + jsonBody);
        return jsonBody;

    }
    
    //Invoice
    public static String requestsendInvoiceToScripturaService(Invoice__c inv, Account invoicingAccount,  AccountContactRelation invoicingResponsable,  List<InvoiceLineItem__c> invLineItemList, Map<Id,List<Service_Appointment_Line_Item__c>> saliPerAccId) 
    {
        List<Invoice__c> invoiceToUpdate = new List<Invoice__c>();
        String contractCountry = inv.Contract_Home__r.Contract_Country__c; 
        String invLanguage = inv.Billing_Language__c=='NL'?'NL':'FR'; 
        String dptNumber = invoicingAccount.Department_Number__c!=null?String.valueOf(invoicingAccount.Department_Number__c).leftPad(3,'0'):'';
        DateTime docDate = inv.Document_Date__c;
        DateTime firstDayOfMonth = System.today().addMonths(-1).toStartOfMonth(); //Invoicing process is launched for services of last month
        DateTime lastDayOfMonth = firstDayOfMonth.addMonths(1).addDays(-1);

        sendInvoiceToScripturaServiceRequest requestData = new sendInvoiceToScripturaServiceRequest();
        
        requestData.processType = 'batch'; //Default 'batch'
        String documentName = '';
        switch on invLanguage {
            when 'NL'  {
                documentName = 'MCM - Factuur - ' + inv.Invoice_Number__c; //OAPPMEDCHECK-945
            }
            when else {
                documentName = 'CVM - Facture - ' + inv.Invoice_Number__c; //OAPPMEDCHECK-945
            }
        }
        //requestData.documentNaam = invLanguage=='NL'?'MCM - Factuur':'CVM - Facture'; //OAPPMEDCHECK-820
        requestData.documentNaam = documentName; 
        requestData.eventFlow = contractCountry=='FRA'?'archive':'email'; //OAPPMEDCHECK-820

        /*      TO BE CONFIRMED WHEN NO IMPEDIMENT  - 612
         if(contractCountry=='BE')
        {
            if(invoicingResponsable.Invoicing_recipient_email__c==TRUE && invoicingResponsable.Contact.Email!=null)
            {
                requestData.eventFlow = 'email'; //OAPPMEDCHECK-612
            }
            else
            {
                requestData.eventFlow = 'print'; //OAPPMEDCHECK-612
            }
        } */
        requestData.templateSet = contractCountry=='BEL'?'MCM/FactuurMCM':'MCM/FactuurSMS'; //Default 'FactuurMCM'
        requestData.cdws = buildCdws(inv,invoicingAccount, contractCountry, invLanguage);
        requestData.contact = buildContactInfo(inv,invoicingAccount,invoicingResponsable);
        requestData.datas = buildData(inv, invoicingAccount,invoicingResponsable ,dptNumber, invLineItemList, firstDayOfMonth, lastDayOfMonth, saliPerAccId, invLanguage);
        requestData.emails = buildEmail(inv,invoicingAccount,docDate, dptNumber, contractCountry, invLanguage ); 
        requestData.neotouches = buildFileName(inv, contractCountry);       
        requestData.jobFlowDatas = buildJobFlowData(contractCountry);       
        String jsonBody = JSON.serializePretty(requestData, true);
        //System.debug('jsonBody ' + jsonBody);
        return jsonBody;

    }

    // Credit notes
    public static String requestsendCreditNotesToScripturaService(Invoice__c inv, Account invoicingAccount,  AccountContactRelation invoicingResponsable,  List<InvoiceLineItem__c> invLineItemList, Map<Id,List<Service_Appointment_Line_Item__c>> saliPerAccId) 
    {
        List<Invoice__c> invoiceToUpdate = new List<Invoice__c>();
        String contractCountry = inv.Contract_Home__r.Contract_Country__c; 
        String invLanguage = inv.Billing_Language__c=='NL'?'NL':'FR'; 
        String dptNumber = invoicingAccount.Department_Number__c!=null?String.valueOf(invoicingAccount.Department_Number__c).leftPad(3,'0'):'';
        DateTime docDate = inv.Document_Date__c;
        DateTime firstDayOfMonth = System.today().addMonths(-1).toStartOfMonth(); //Invoicing process is launched for services of last month
        DateTime lastDayOfMonth = firstDayOfMonth.addMonths(1).addDays(-1);

        sendInvoiceToScripturaServiceRequest requestData = new sendInvoiceToScripturaServiceRequest();
        
        requestData.processType = 'batch'; //Default 'batch'
        String documentName = '';
        switch on invLanguage {
            when 'NL'  {
                documentName = 'MCM - Creditnota - ' + inv.Invoice_Number__c; //OAPPMEDCHECK-945
            }
            when else {
                documentName = 'CVM - Avoir - ' + inv.Invoice_Number__c; //OAPPMEDCHECK-945
            }
        }
        requestData.documentNaam = documentName; 
        requestData.eventFlow = contractCountry=='FRA'?'archive':'email'; //OAPPMEDCHECK-820
        requestData.templateSet = contractCountry=='BEL'?'MCM/FactuurMCM':'MCM/FactuurSMS'; //Default 'FactuurMCM'
        requestData.cdws = buildCdws(inv,invoicingAccount, contractCountry, invLanguage);
        requestData.contact = buildContactInfo(inv,invoicingAccount,invoicingResponsable);
        requestData.datas = buildData(inv, invoicingAccount,invoicingResponsable ,dptNumber, invLineItemList, firstDayOfMonth, lastDayOfMonth, saliPerAccId, invLanguage);
        requestData.emails = buildEmail(inv,invoicingAccount,docDate, dptNumber, contractCountry, invLanguage ); 
        requestData.neotouches = buildFileName(inv, contractCountry);       
        requestData.jobFlowDatas = buildJobFlowData(contractCountry);       
        String jsonBody = JSON.serializePretty(requestData, true);
        //System.debug('jsonBody ' + jsonBody);
        return jsonBody;

    }

    public static List<fileName> buildFileName(Invoice__c inv, String contractCountry)
    {
        List<fileName> fileNames = new List<fileName>();
        if(contractCountry=='FRA')//OAPPMEDCHECK-299 
        {
            fileName fileN = new fileName();
            fileN.fileName = 'PDFMCM' + inv.Name.remove('I-') + '_' + inv.Invoice_Number__c + '.pdf';
            fileNames.add(fileN);
        }
        System.debug('QLE fileNames ' + fileNames); 
        return fileNames;
    }
    
    public static List<jobFlowData> buildJobFlowData(String contractCountry)
    {
        List<jobFlowData> jobFlowDatList = new List<jobFlowData>();
        if(contractCountry=='FRA')//OAPPMEDCHECK-299
        {
            jobFlowData jobFlowDat = new jobFlowData();
            jobFlowDat.key = 'enable-neotouch';
            jobFlowDat.value = true;
            jobFlowDatList.add(jobFlowDat);
        }
        return jobFlowDatList;
    }

    public static List<cdws> buildCdws(Invoice__c inv, Account invoicingAccount, String contractCountry, String invLanguage )
    {
        List<cdws> cdwsList = new List<cdws>();
        cdws cdwsData = new cdws();
        cdwsData.cdwArchivingPeriod = '10'; //Default '10'
        cdwsData.cdwCallingApplication = contractCountry=='BEL'?'MCM':'SMS'; // if Belgium => Default 'MCM', if France => Default 'SMS'
        if(inv.Document_Type__c=='30')
        {
            cdwsData.cdwDocumentType = invLanguage=='NL'?'Factuur':'Facture'; //Factuur/Facture
        }
        else if(inv.Document_Type__c=='19')
        {
            cdwsData.cdwDocumentType = invLanguage=='NL'?'Onkostennota':'Honoraire'; //Onkostennota/Honoraire
        }
        else if(inv.Document_Type__c=='40')
        {
            cdwsData.cdwDocumentType = invLanguage=='NL'?'Creditnota':'Avoir'; //Onkostennota/Honoraire
        }
        cdwsData.pdate1 = String.valueOf(inv.Document_Date__c);
        DateTime firstDayOfMonth = System.today().addMonths(-1).toStartOfMonth(); //Invoicing process is launched for services of last month
        DateTime lastDayOfMonth = firstDayOfMonth.addMonths(1).addDays(-1);
        cdwsData.date2 = firstDayOfMonth.format('yyyyMMdd');
        cdwsData.date3 = lastDayOfMonth.format('yyyyMMdd'); 
        cdwsData.num1 =  Integer.valueOf(cdwsData.date2); 
        cdwsData.num2 =  Integer.valueOf(cdwsData.date3); 
        cdwsData.docTypeName = 'ALL type PDF';//Default 'ALL type PDF'
        if(inv.Document_Type__c=='30'|| inv.Document_Type__c=='40')
        {
            cdwsData.docid = contractCountry=='BEL'?'PDFMCM0001':'PDFSMS0001'; 
            cdwsData.fileName = cdwsData.cdwArchivingPeriod + '_' + cdwsData.docid +'_' + inv.Invoice_Number__c + '.PDF'; // '10_PDFMCM0001_3020004578.PDF'  
        }
        if(inv.Document_Type__c=='19')
        {
            cdwsData.docid = contractCountry=='BEL'?'PDFMCM0003':'PDFSMS0003'; 
            cdwsData.fileName = cdwsData.cdwArchivingPeriod + '_' + cdwsData.docid +'_' + inv.Invoice_Number__c + '.PDF'; // '10_PDFMCM0003_3020004578.PDF'  
        }
        cdwsData.l = inv.Billing_Language__c=='NL'?'N':'F'; // "Invoice.Billing_Language__c but only 1 character"
        cdwsData.mon1 = inv.Total_including_VAT_Currency__c.setScale(2);
        cdwsData.n3 = inv.Total_including_VAT_Currency__c==0?'00':inv.Total_including_VAT_Currency__c>0?'01':'02'; // If Invoice.Total_including_VAT_Currency__c = 0 => '00' If Invoice.Total_including_VAT_Currency__c > 0 => '01' If Invoice.Total_including_VAT_Currency__c < 0 => '02'
        if(inv.Document_Type__c=='30' || inv.Document_Type__c=='40')
        {
            cdwsData.ptext1 = invoicingAccount.Parent_Securex_Number__c!=null?invoicingAccount.Parent_Securex_Number__c:'';
        }
        if(inv.Document_Type__c=='19')
        {
            String riziv= invoicingAccount.RIZIV__c!=null?invoicingAccount.RIZIV__c:'';
            String mid= invoicingAccount.MID_number__c!=null?String.valueOf(invoicingAccount.MID_number__c):'';
            cdwsData.ptext1 = contractCountry=='BE'?riziv:mid;
        }
        cdwsData.text3 = inv.Billing_Name__c!=null?inv.Billing_Name__c:''; // 'ICS ANTWERPEN'; Invoice.Billing_Name__c TO CHECK
        if(inv.Document_Type__c=='30'|| inv.Document_Type__c=='40')
        {
            cdwsData.text4 = inv.Contract_Home__r.Contract_Digit__c!=null?String.valueOf(MATH.FLOOR(inv.Contract_Home__r.Contract_Digit__c)):''; 
        }
        if(inv.Document_Type__c=='19')
        {
            cdwsData.text4 = invoicingAccount.MID_number__c!=null?String.valueOf(invoicingAccount.MID_number__c):''; 
        }
        cdwsData.text6 = inv.Invoice_Number__c!=null?inv.Invoice_Number__c:''; 
        cdwsData.text7 = inv.Billing_Postal_Code__c!=null?String.valueOf(inv.Billing_Postal_Code__c):'';
        
        cdwsList.add(cdwsData);
        return cdwsList;
    }
        

    public static contactInfo buildContactInfo(Invoice__c inv, Account invoicingAccount,AccountContactRelation invoicingResponsable )
    {
        contactInfo contInfo = new contactInfo();
        contInfo.street = inv.Billing_Street__c!=null?inv.Billing_Street__c:'';
        contInfo.houseNumber = inv.Billing_HouseNr__c!=null?inv.Billing_HouseNr__c:''; 
        contInfo.boxNumber=inv.Billing_Postal_Box__c!=null?inv.Billing_Postal_Box__c:'';        
        contInfo.zipCode=inv.Billing_Postal_Code__c!=null?inv.Billing_Postal_Code__c:'';
        contInfo.city=inv.Billing_City__c!=null?inv.Billing_City__c:'';    
        String billingCountry;
        if(countryTranslation!=null)
        {
            switch on inv.Billing_Language__c{
                when'NL' {   
                    Map<String,String> translationNL = countryTranslation.get('NL');
                    billingCountry = translationNL!=null && inv.Billing_Country__c!=null?translationNL.get(inv.Billing_Country__c):null;
                }
                when else
                {
                    Map<String,String> translationFR = countryTranslation.get('FR');
                    billingCountry = translationFR!=null && inv.Billing_Country__c!=null?translationFR.get(inv.Billing_Country__c):null;
                }
            }
        }
        contInfo.country= billingCountry!=null?billingCountry:''; 
        //contInfo.countryCode= inv.Billing_Country__c!=null?inv.Billing_Country__c:''; // Invoice > Billing Country (code);
        if(inv.Document_Type__c=='30' || inv.Document_Type__c=='40') //19 = null
        {
            contInfo.firstName=inv.Contact_FirstName__c!=null?inv.Contact_FirstName__c:'';    
            contInfo.lastName=inv.Contact_LastName__c!=null?inv.Contact_LastName__c:'';    
        }
        System.debug('QLE inv.Billing_Language__c ' + inv.Billing_Language__c); 
        contInfo.language=inv.Billing_Language__c=='NL'?'NL':'FR'; //"Invoice.Billing_Language__c => 2 characters"    
        
        if(inv.Document_Type__c=='30' || inv.Document_Type__c=='40')
        {
            if(invoicingResponsable.Invoicing_recipient_email__c==TRUE)
            {
                contInfo.email= invoicingResponsable.Contact.Email;    
                //contInfo.email= 'liesbeth.de.colvenaer@securex.be';      
            }     
            if(invoicingResponsable.Invoicing_recipient_internal_mailbox__c==true)
            {
                contInfo.email= 'corinne.rasclard@securex.fr';         
            }
        }
        else if (inv.Document_Type__c=='19')
        {
            contInfo.email= invoicingAccount.Account_Email__c;
        }

        return contInfo;
    }


    public static List<data> buildData(Invoice__c inv, Account invoicingAccount, AccountContactRelation invoicingResponsible, String dptNumber, List<InvoiceLineItem__c> invLineItemList, DateTime firstDayOfMonth, DateTime lastDayOfMonth,Map<Id,List<Service_Appointment_Line_Item__c>> saliPerAccId, String invLanguage )
    {
        data data1 = new data();
        List<data> dataList = new List<data>();
        data1.dataId = 'paymentdocument-data';
        data1.dataValue = writePaymentDocString(inv, invoicingAccount, invoicingResponsible, dptNumber, invLineItemList, firstDayOfMonth, lastDayOfMonth, saliPerAccId).replaceAll('(\\r)|(\\n)','');
        data1.dataValueType = 'XML';
        dataList.add(data1);

        data data2= new data();
        data2.dataId = 'email-data';
        data2.dataValue = writeEmailDocString(inv, invLanguage).replaceAll('(\\r)|(\\n)','');
        data2.dataValueType = 'XML';
        dataList.add(data2);

        if(saliPerAccId!=null)
        {
            data data3 = new data();
            data3.dataId = 'performance-data';
            data3.dataValue = writePerformanceDocString(inv, invoicingAccount, dptNumber, saliPerAccId, firstDayOfMonth, lastDayOfMonth).replaceAll('(\\r)|(\\n)','');
            data3.dataValueType = 'XML';
            dataList.add(data3);
        }

        return dataList;

    }


public static List<email> buildEmail(Invoice__c inv, Account invoicingAccount, DateTime docDate, String dptNumber, String contractCountry, String invLanguage)
{
        email em = new email();
        List<email> emailList = new List<email>();
        em.fromEmail = contractCountry=='BEL'?'camcm@securex.be':'lille.comptabilite@securex.fr'; 
        //em.fromName = contractCountry=='BEL'?'SecurexMCM':'Securex SMS'; 
        em.fromName = contractCountry=='BEL'?'SecurexMCM':'Securex CVM'; 
        em.replyToEmail = contractCountry=='BEL'?'camcm@securex.be':'lille.comptabilite@securex.fr';
        em.replyToName = 'Securex'; //Default
        String startSubj ='';
        
        if(inv.Document_Type__c=='30')
        {
            if(contractCountry=='BEL')
            {
                if(invLanguage=='NL')
                {
                    startSubj ='FACTUUR MCM ';
                }
                else {
                    startSubj ='FACTURE MCM ';
                }
            }
            else if(contractCountry=='FRA')
            {
                startSubj ='FACTURE CVM ';
            }    
            em.subject = startSubj + MATH.FLOOR(inv.Contract_Home__r.Contract_Digit__c) + '/' + dptNumber + ' '  + inv.Invoice_Number__c + ' ' + docDate.format('dd-MM-yyyy');
        }
        else if (inv.Document_Type__c=='19')
        {
            if(contractCountry=='BEL')
            {
                if(invLanguage=='NL')
                {
                    startSubj ='ONKOSTENNOTA MCM ';
                }
                else {
                    startSubj ='NOTE HONORAIRE MCM ';
                }
            }
            else if(contractCountry=='FRA')
            {
                startSubj ='NOTE HONORAIRE CVM ';
            }  
            em.subject = startSubj + inv.Invoice_Number__c + ' ' + docDate.format('dd-MM-yyyy');
        }
        else if(inv.Document_Type__c=='40')
        {
            if(contractCountry=='BEL')
            {
                if(invLanguage=='NL')
                {
                    startSubj ='CREDITNOTA MCM ';
                }
                else {
                    startSubj ='NOTE DE CREDIT MCM ';
                }
            }
            else if(contractCountry=='FRA')
            {
                startSubj ='AVOIR CVM ';
            }    
            em.subject = startSubj + MATH.FLOOR(inv.Contract_Home__r.Contract_Digit__c) + '/' + dptNumber + ' '  + inv.Invoice_Number__c + ' ' + docDate.format('dd-MM-yyyy');
        }          
        emailList.add(em); 
        return emailList;
    }
    
    public static String writePaymentDocString(Invoice__c inv, Account invoicingAccount, AccountContactRelation invoicingResponsable , String dptNumber, List<InvoiceLineItem__c> invLineItemList, DateTime firstDayOfMonth, DateTime lastDayOfMonth,Map<Id,List<Service_Appointment_Line_Item__c>> saliPerAccId)
    {
        DateTime docDate = inv.Document_Date__c;
        DateTime InitialInvDocDate = inv.Initial_Invoice__r.Document_Date__c;
        DateTime dueDate = inv.Due_Date__c;
        String invLanguage = inv.Billing_Language__c;
        String billingCountry = inv.Billing_Country__c;
        String shippingCountry = inv.Shipping_Country__c;
        String contractCountry = inv.Contract_Home__r.Contract_Country__c; 
        String headQuarterOffice; 
      
        XmlStreamWriter paymentDoc = new XmlStreamWriter();
        //<paymentDocument>
        paymentDoc.writeStartElement(null,'paymentDocument',null);
            //<paymentDocumentLocation>
            paymentDoc.writeStartElement(null,'paymentDocumentLocation',null);
                if(inv.Document_Type__c=='30'|| inv.Document_Type__c=='40')
                {
                    paymentDoc.writeCharacters(contractCountry=='BEL'?'Gent':'Lille'); //Gent	Lille
                }
                else if (inv.Document_Type__c=='19')
                {
                    String bilingCity= inv.Billing_City__c!=null?inv.Billing_City__c:'';
                    paymentDoc.writeCharacters(contractCountry=='BEL'?'Gent':bilingCity); //Gent	Lille
                }
            //</paymentDocumentLocation>
            paymentDoc.writeEndElement();
            //<paymentDocumentType>
            paymentDoc.writeStartElement(null,'paymentDocumentType',null);
                //30 -> 01, 40 -> 03
                paymentDoc.writeCharacters(inv.Document_Type__c=='30'?'01':inv.Document_Type__c=='19'?'02':inv.Document_Type__c=='40'?'03':'');
            //</paymentDocumentType>
            paymentDoc.writeEndElement();
            //<invoiceNbr>
            paymentDoc.writeStartElement(null,'invoiceNbr',null);
                paymentDoc.writeCharacters(inv.Invoice_Number__c!=null?inv.Invoice_Number__c:''); 
            //</invoiceNbr>
            paymentDoc.writeEndElement();
            String dateUntilStr;
            String dateFromStr;
            if(inv.Invoicing_Type__c=='Yearly contribution invoicing')
            {
                DateTime nextDueDateMinus1Day = inv.Contract_Home__r.Next_due_date__c.addDays(-1);
                DateTime nextDueDateMinus1Year = inv.Contract_Home__r.Next_due_date__c.addYears(-1);
                dateUntilStr = nextDueDateMinus1Day.format('dd/MM/yyyy');
                dateFromStr = nextDueDateMinus1Year.format('dd/MM/yyyy');
            }
            else if(inv.Invoicing_Type__c=='Pack invoicing')
            {
                dateUntilStr = '';
                dateFromStr = '';
            }
            else
            {
                dateUntilStr = lastDayOfMonth.format('dd/MM/yyyy');
                dateFromStr = firstDayOfMonth.format('dd/MM/yyyy');
            }
            //<billingPeriod>
            paymentDoc.writeStartElement(null,'billingPeriod',null);
                //dateUntil>
                paymentDoc.writeStartElement(null,'dateUntil',null);
                    paymentDoc.writeCharacters(dateUntilStr); 
                paymentDoc.writeEndElement();
                //<dateFrom>
                paymentDoc.writeStartElement(null,'dateFrom',null);
                    paymentDoc.writeCharacters(dateFromStr);
                paymentDoc.writeEndElement();
            //</billingPeriod>
            paymentDoc.writeEndElement();

            //<supplier>
            paymentDoc.writeStartElement(null,'supplier',null);
                //<logoIdentification>
                paymentDoc.writeStartElement(null,'logoIdentification',null);
                    if(inv.Document_Type__c=='30' || inv.Document_Type__c=='40' )
                    {
                        paymentDoc.writeCharacters('Securex'); //Default
                    }
                    else if (inv.Document_Type__c=='19')
                    {
                        paymentDoc.writeCharacters(contractCountry=='BEL'?'Securex':''); //Default
                    }
                //</logoIdentification>
                paymentDoc.writeEndElement();
                //<organisationNameCode>
                paymentDoc.writeStartElement(null,'organisationNameCode',null);
                    if(contractCountry=='BEL')
                    {
                        if(invLanguage=='NL')
                        {
                            paymentDoc.writeCharacters('MEDISCHE CONTROLE'); 
                        }
                        else {
                            paymentDoc.writeCharacters('CONTRÔLE MEDICAL'); 
                        }
                    }
                    else if(contractCountry=='FRA')
                    {
                        if(inv.Document_Type__c=='30'||inv.Document_Type__c=='40')
                        {
                            paymentDoc.writeCharacters('CONTRE-VISITES MEDICALES');
                        }    
                    }
                //</organisationNameCode>
                paymentDoc.writeEndElement();
                //<contactInfo>
                paymentDoc.writeStartElement(null,'contactInfo',null);
                    //<emailAddress>
                    // paymentDoc.writeStartElement(null,'emailAddress',null);
                    //     paymentDoc.writeCharacters(contractCountry=='BEL'?'camcm@securex.be':'lille.comptabilite@securex.fr'); //camcm@securex.be	lille.comptabilite@securex.fr
                    // paymentDoc.writeEndElement();
                    //<websiteReferenceCode>
                    paymentDoc.writeStartElement(null,'websiteReferenceCode',null); // "If Belgium => Default 'SecurexBE' If France => Default 'SecurexFR'"
                        if(inv.Document_Type__c=='30'|| inv.Document_Type__c=='40')
                        {
                        paymentDoc.writeCharacters(contractCountry=='BEL'?'SecurexBE':'SecurexFR');
                        }
                        else if (inv.Document_Type__c=='19')
                        {
                        paymentDoc.writeCharacters(contractCountry=='BEL'?'SecurexBE':'');
                        }
                    //</websiteReferenceCode>
                    paymentDoc.writeEndElement();
                    //<postalAddress>
                    paymentDoc.writeStartElement(null,'postalAddress',null);
                        //<postalCodeLocation>
                        paymentDoc.writeStartElement(null,'postalCodeLocation',null);
                            if(inv.Document_Type__c=='30'|| inv.Document_Type__c=='40')
                            {
                                paymentDoc.writeCharacters(contractCountry=='BEL'?'9000 Gent':'59046 Lille Cedex'); // 9000 Gent	59046 Lille Cedex
                            }
                            else if (inv.Document_Type__c=='19')
                            {
                                paymentDoc.writeCharacters(contractCountry=='BEL'?'9000 Gent':''); // 9000 Gent	
                            }
                        paymentDoc.writeEndElement(); 
                        //<streetHouseNbr>
                        paymentDoc.writeStartElement(null,'streetHouseNbr',null);
                            if(inv.Document_Type__c=='30'|| inv.Document_Type__c=='40')
                            {
                                paymentDoc.writeCharacters(contractCountry=='BEL'?'Verenigde-Natieslaan 1':'20 rue des Vicaires'); //Verenigde-Natieslaan 1	20 rue des Vicaires
                            }
                            else if (inv.Document_Type__c=='19')
                            {
                                paymentDoc.writeCharacters(contractCountry=='BEL'?'Verenigde-Natieslaan 1':''); //Verenigde-Natieslaan 1
                            }
                        paymentDoc.writeEndElement(); 
                        //<companyName>
                        paymentDoc.writeStartElement(null,'companyName',null);
                        if(inv.Document_Type__c=='30' || inv.Document_Type__c=='40')
                        {
                            paymentDoc.writeCharacters('Securex'); //Default
                        }
                        else if (inv.Document_Type__c=='19')
                        {
                            paymentDoc.writeCharacters(contractCountry=='BEL'?'Securex':''); //Default
                        }
                        paymentDoc.writeEndElement(); 
                    //</postalAddress>
                    paymentDoc.writeEndElement();  
                    //<telephoneNbr>
                    paymentDoc.writeStartElement(null,'telephoneNbr',null);
                        if(inv.Document_Type__c=='30'|| inv.Document_Type__c=='40')
                        {
                            paymentDoc.writeCharacters(contractCountry=='BEL'?'+32 78 15 41 10':'+33 3 20 06 72 00'); //+32 78 15 41 10	+33 3 20 06 72 00
                        }
                        else if (inv.Document_Type__c=='19')
                        {
                            paymentDoc.writeCharacters(contractCountry=='BEL'?'+32 78 15 41 10':''); //+32 78 15 41 10
                        }
                    paymentDoc.writeEndElement();                    
                //</contactInfo>    
                paymentDoc.writeEndElement();
                //<legalEntityNoticeCodePart1>
                paymentDoc.writeStartElement(null,'legalEntityNoticeCodePart1',null);
                    if(inv.Document_Type__c=='30'|| inv.Document_Type__c=='40')
                    {
                        paymentDoc.writeCharacters(contractCountry=='BEL'?'SecurexMCM':'SecurexSMS'); //"If Belgium => Default 'SecurexMCM' If France => Default 'SecurexSMS'"
                    }
                    else if (inv.Document_Type__c=='19')
                    {
                        paymentDoc.writeCharacters(contractCountry=='BEL'?'SecurexMCM':''); //"If Belgium => Default 'SecurexMCM' If France => Default 'SecurexSMS'"
                    }
                paymentDoc.writeEndElement(); 
                //<companyIdentification/>
                paymentDoc.writeEmptyElement(null,'companyIdentification',null); // Default empty          
                //<legalEntityNoticeCodePart2>
                paymentDoc.writeStartElement(null,'legalEntityNoticeCodePart2',null); //"If Belgium => Default 'SecurexMCM' If France => Default 'SecurexSMS'"
                    if(inv.Document_Type__c=='30'|| inv.Document_Type__c=='40')
                    {
                        paymentDoc.writeCharacters(contractCountry=='BEL'?'SecurexMCM':'SecurexSMS'); //"If Belgium => Default 'SecurexMCM' If France => Default 'SecurexSMS'"
                    }
                    else if (inv.Document_Type__c=='19')
                    {
                        paymentDoc.writeCharacters(contractCountry=='BEL'?'SecurexMCM':''); //"If Belgium => Default 'SecurexMCM' If France => Default 'SecurexSMS'"
                    }
                paymentDoc.writeEndElement();                 
            //</supplier>
            paymentDoc.writeEndElement();
            //<paymentDocumentDate>
            paymentDoc.writeStartElement(null,'paymentDocumentDate',null);
                paymentDoc.writeCharacters(docDate.format('dd/MM/yyyy'));
            paymentDoc.writeEndElement();  
            //<payment>
            paymentDoc.writeStartElement(null,'payment',null);
                //<standardInvoice>
                paymentDoc.writeStartElement(null,'standardInvoice',null);
                    //<paymentLineGroup>
                    paymentDoc.writeStartElement(null,'paymentLineGroup',null);
                    for(InvoiceLineItem__c ili : invLineItemList)
                    {
                        //<paymentLine>
                        paymentDoc.writeStartElement(null,'paymentLine',null);
                            //<unitPrice>
                            paymentDoc.writeStartElement(null,'unitPrice',null);
                                paymentDoc.writeCharacters(ili.Unit_Price__c!=null?String.valueOf(ili.Unit_Price__c.setScale(2,RoundingMode.HALF_UP)):''); // InvoiceLineItem__c.Unit_Price__c  
                            paymentDoc.writeEndElement(); 
                            //<VATRate>
                            if(inv.Specific_VAT__c!=null)
                            {
                                paymentDoc.writeStartElement(null,'VATRate',null);
                                    Decimal specificVAT = inv.Specific_VAT__c.setScale(2,RoundingMode.HALF_UP);
                                    paymentDoc.writeCharacters(String.valueOf(specificVAT));
                                paymentDoc.writeEndElement(); 
                            }
                            //<quantity>
                            paymentDoc.writeStartElement(null,'quantity',null);
                                paymentDoc.writeCharacters(ili.Quantity__c!=null?String.valueOf(ili.Quantity__c):''); // InvoiceLinteItem__c.Quantity__c
                            paymentDoc.writeEndElement(); 
                            //<amountExclVAT>
                            paymentDoc.writeStartElement(null,'amountExclVAT',null);
                                paymentDoc.writeCharacters(ili.Amount_Excluding_VAT_Currency__c!=null?String.valueOf(ili.Amount_Excluding_VAT_Currency__c.setScale(2)):'0'); // InvoiceLinteItem__c.Amount_Excluding_VAT_Currency__c
                            paymentDoc.writeEndElement(); 
                            //<serviceDescription>
                            if(!ili.Service_Appointment_Line_Items__r.isEmpty())
                            {
                                
                                paymentDoc.writeStartElement(null,'serviceDescription',null);
                                    if(invLanguage=='NL') 
                                    {
                                    paymentDoc.writeCharacters(ili.Service_Appointment_Line_Items__r[0].Service__r.Service_Name_NL__c!=null?String.valueOf(ili.Service_Appointment_Line_Items__r[0].Service__r.Service_Name_NL__c):''); // InvoiceLinteItem__c.Contractual_Service_Line_Item__c.Service__c.Name
                                    }
                                    else 
                                    {
                                    paymentDoc.writeCharacters(ili.Service_Appointment_Line_Items__r[0].Service__r.Service_Name_FR__c!=null?String.valueOf(ili.Service_Appointment_Line_Items__r[0].Service__r.Service_Name_FR__c):''); // InvoiceLinteItem__c.Contractual_Service_Line_Item__c.Service__c.Name
                                    }
                                paymentDoc.writeEndElement(); 
                                
                            }
                            else if (ili.Description__c!=null && ili.Description__c!=null) 
                            {
                                paymentDoc.writeStartElement(null,'serviceDescription',null);
                                    paymentDoc.writeCharacters(ili.Description__c);
                                paymentDoc.writeEndElement(); 
                            }
                        //</paymentLine>                                                                                        
                        paymentDoc.writeEndElement();  
                        //<subtotalLine>
                        if(inv.Document_Type__c=='30'|| inv.Document_Type__c=='40')
                        {
                            paymentDoc.writeStartElement(null,'subtotalLine',null);
                                //<amount/>
                                paymentDoc.writeEmptyElement(null,'amount',null); //Default empty 
                                //<description/>
                                paymentDoc.writeEmptyElement(null,'description',null); //Default empty
                            //</subtotalLine>                           
                            paymentDoc.writeEndElement();  
                        }
                    }
                    //</paymentLineGroup>    
                    paymentDoc.writeEndElement();  
                    //<heading>
                    paymentDoc.writeEmptyElement(null,'heading',null); //Default empty
                    paymentDoc.writeStartElement(null,'paymentTotalAmount',null);
                        paymentDoc.writeCharacters(String.valueOf(inv.Total_excluded_VAT_Currency__c.setScale(2)));
                    paymentDoc.writeEndElement();
                    //<alreadyPaidAmount>
                    if(inv.Document_Type__c=='30'|| inv.Document_Type__c=='40')
                    {
                        paymentDoc.writeStartElement(null,'alreadyPaidAmount',null);
                            paymentDoc.writeCharacters('');
                        paymentDoc.writeEndElement();   
                    }
                    //<remainingToBePaid>
                    paymentDoc.writeStartElement(null,'remainingToBePaid',null);
                        paymentDoc.writeCharacters(String.valueOf(inv.Total_including_VAT_Currency__c.setScale(2))); //Invoice__c.Total_including_VAT_Currency__c
                    paymentDoc.writeEndElement();   
                    //<footerTextCode>
                    paymentDoc.writeStartElement(null,'footerTextCode',null);
                        paymentDoc.writeCharacters(inv.VAT_Code_Text__c!=null?inv.VAT_Code_Text__c:''); // "If Belgium => Default 'MCM0001' If France => Default 'SMS0001'"
                        //paymentDoc.writeCharacters(contractCountry=='BEL'?'MCM0001':'SMS0001'); // "If Belgium => Default 'MCM0001' If France => Default 'SMS0001'"
                    paymentDoc.writeEndElement();     
                    //<currencyCode>
                    paymentDoc.writeStartElement(null,'currencyCode',null);
                        paymentDoc.writeCharacters('EUR'); //Default EUR
                    paymentDoc.writeEndElement();   
                    //<FlagMentionVAT>   
                    paymentDoc.writeStartElement(null,'FlagMentionVAT',null);
                        paymentDoc.writeCharacters(inv.Specific_VAT__c==0.00 ||inv.Specific_VAT__c==null?'false':'true'); 
                    paymentDoc.writeEndElement();
                    //<VAT>   
                    paymentDoc.writeStartElement(null,'VAT',null);
                        paymentDoc.writeStartElement(null,'rate',null);
                            Decimal specificVAT = inv.Specific_VAT__c!=null?inv.Specific_VAT__c.setScale(2,RoundingMode.HALF_UP):0.00;
                            paymentDoc.writeCharacters(String.valueOf(specificVAT));
                        paymentDoc.writeEndElement();
                        paymentDoc.writeStartElement(null,'baseAmount',null);
                            paymentDoc.writeCharacters(inv.Total_excluded_VAT_Currency__c!=null?String.valueOf(inv.Total_excluded_VAT_Currency__c.setScale(2)):''); 
                        paymentDoc.writeEndElement();  
                        paymentDoc.writeStartElement(null,'amount',null);
                            paymentDoc.writeCharacters(inv.Total_VAT_Currency__c!=null?String.valueOf(inv.Total_VAT_Currency__c.setScale(2)):''); 
                        paymentDoc.writeEndElement();    
                    paymentDoc.writeEndElement();                            
                    //<typeOfPayment>   
                    paymentDoc.writeStartElement(null,'typeOfPayment',null);
                        //<bankTransfer>
                        paymentDoc.writeStartElement(null,'bankTransfer',null);
                        if(inv.Document_Type__c=='30'|| inv.Document_Type__c=='40')
                        {
                            //<reference>
                            paymentDoc.writeStartElement(null,'reference',null);
                                //<freeForm>
                                paymentDoc.writeStartElement(null,'freeForm',null);
                                if(inv.Document_Type__c=='30')
                                {
                                    paymentDoc.writeCharacters(String.valueOf(inv.Invoice_Number__c)); 
                                }
                                if(inv.Document_Type__c=='40')
                                {
                                    paymentDoc.writeCharacters(String.valueOf(inv.Initial_Invoice__r.Invoice_Number__c)); 
                                }
                                paymentDoc.writeEndElement(); 
                            paymentDoc.writeEndElement(); 
                            //<BICNbr>
                            paymentDoc.writeStartElement(null,'BICNbr',null);
                                paymentDoc.writeCharacters(contractCountry=='BEL'?'KREDBEBB':'NORDFRPP'); // KREDBEBB	NORDFRPP
                            paymentDoc.writeEndElement();
                            }
                            //<dueDate>
                            paymentDoc.writeStartElement(null,'dueDate',null);
                            if(inv.Document_Type__c=='30')
                            {
                                paymentDoc.writeCharacters(dueDate.format('dd/MM/yyyy')); //Invoice.Due_Date__c
                            }
                            if(inv.Document_Type__c=='40')
                            {
                                paymentDoc.writeCharacters(InitialInvDocDate.format('dd/MM/yyyy')); 
                            }
                            paymentDoc.writeEndElement();                                
                            if(inv.Document_Type__c=='30'|| inv.Document_Type__c=='40')
                            {
                                //<IBANNbr>
                                paymentDoc.writeStartElement(null,'IBANNbr',null);
                                    paymentDoc.writeCharacters(contractCountry=='BEL'?'BE06 4400 3455 6122':'FR76 3007 6029 1961 1346 0020 017'); //BE06 4400 3455 6122	FR76 3007 6029 1961 1346 0020 017
                                paymentDoc.writeEndElement();  
                                //<amountPayable>
                                paymentDoc.writeStartElement(null,'amountPayable',null);
                                    paymentDoc.writeCharacters(String.valueOf(inv.Total_including_VAT_Currency__c.setScale(2)));
                                paymentDoc.writeEndElement(); 
                            }
                        //</bankTransfer>  
                        paymentDoc.writeEndElement(); 
                        if(inv.Document_Type__c=='30' || inv.Document_Type__c=='40')
                        {
                            //<code>
                            paymentDoc.writeStartElement(null,'code',null);
                            //30 -> 01 , 40 -> 07
                            paymentDoc.writeCharacters(inv.Document_Type__c=='30'?'01':inv.Document_Type__c=='40'?'07':''); 
                            //</code>
                            paymentDoc.writeEndElement();
                        }
                    //</typeOfPayment>
                    paymentDoc.writeEndElement();                                                                                        
                //</standardInvoice>
                paymentDoc.writeEndElement();  
                //</payment>
                paymentDoc.writeEndElement(); 
                //<version>
                paymentDoc.writeStartElement(null,'version',null);
                paymentDoc.writeCharacters('V1'); //Default V1
                paymentDoc.writeEndElement(); 
                //<customer>
                paymentDoc.writeStartElement(null,'customer',null);
                //email OAPPMEDCHECK-943+980
                String emailAdr = ''; 
                if(inv.Document_Type__c=='30'|| inv.Document_Type__c=='40')
                {                  
                    if(invoicingResponsable.Contact.Email != null && invoicingResponsable.Invoicing_recipient_email__c==TRUE)
                    {
                        emailAdr= invoicingResponsable.Contact.Email;   
                    }     
                }
                else if (inv.Document_Type__c=='19')
                {                    
                    emailAdr= invoicingAccount.Account_Email__c;
                }

                //<email> OAPPMEDCHECK-943
                if(inv.Document_Type__c=='19' || invoicingResponsable.Invoicing_recipient_email__c==TRUE)
                {
                    if(emailAdr!=null)
                    {
                        paymentDoc.writeStartElement(null,'email',null);
                            paymentDoc.writeCharacters(emailAdr);
                        paymentDoc.writeEndElement();
                    }
                }
                //<email/>   
                
                //<postalAddress>
                paymentDoc.writeStartElement(null,'postalAddress',null);
                    //<departmentName>
                    paymentDoc.writeStartElement(null,'departmentName',null);
                    if(inv.Document_Type__c=='30'|| inv.Document_Type__c=='40')
                    {
                        paymentDoc.writeCharacters(inv.Shipping_Street_Extension__c!=null?inv.Shipping_Street_Extension__c:''); //Street Extension
                    } 
                    else if(inv.Document_Type__c=='19')
                    {
                        String billing = inv.Billing_Street_Extension__c!=null?inv.Billing_Street_Extension__c:''; //Street Extension
                        paymentDoc.writeCharacters( contractCountry=='BEL'?billing:'');
                    }
                    //</departmentName>
                    paymentDoc.writeEndElement(); 
                    //country
                    if(shippingCountry!=null && shippingCountry!=contractCountry) //only send value if different than Contract Country
                    {
                        String shippingCountryTranslation;
                        if(countryTranslation!=null)
                        {
                            switch on inv.Billing_Language__c
                            {
                                when'NL' 
                                {   
                                    Map<String,String> translationNL = countryTranslation.get('NL');
                                    shippingCountryTranslation = translationNL!=null?translationNL.get(shippingCountry):null;
                                }
                                when else
                                {
                                    Map<String,String> translationFR = countryTranslation.get('FR');
                                    shippingCountryTranslation = translationFR!=null?translationFR.get(shippingCountry):null;
                                }
                            }
                        }
                        if(shippingCountryTranslation!=null)
                        {
                            paymentDoc.writeStartElement(null,'country',null);
                            if(inv.Document_Type__c=='30'|| inv.Document_Type__c=='40')
                            {
                                paymentDoc.writeCharacters(shippingCountryTranslation); //only if different of Contract Country.           
                            }
                            else if(inv.Document_Type__c=='19')
                            {
                                paymentDoc.writeCharacters(contractCountry=='BEL'?shippingCountryTranslation:''); //only if different of Contract Country.  FR -empty         
                            }
                            paymentDoc.writeEndElement();  
                        }
                    }
                    //<postalCodeLocation>
                    paymentDoc.writeStartElement(null,'postalCodeLocation',null);
                    String postalCodeLocation;
                    if(inv.Shipping_Postal_Code__c!=null)
                    {
                        postalCodeLocation = inv.Shipping_Postal_Code__c;
                        if(inv.Shipping_City__c!=null)
                        {
                            postalCodeLocation = postalCodeLocation + ' ' + inv.Shipping_City__c;
                        }
                    }
                    String postalCodeLocationBilling;
                    if(inv.Billing_Postal_Code__c!=null)
                    {
                        postalCodeLocationBilling = inv.Billing_Postal_Code__c;
                        if(inv.Billing_City__c!=null)
                        {
                            postalCodeLocationBilling = postalCodeLocationBilling + ' ' + inv.Billing_City__c;
                        }
                    }
                    if(inv.Document_Type__c=='30'|| inv.Document_Type__c=='40')
                    {
                        paymentDoc.writeCharacters(postalCodeLocation!=null?postalCodeLocation:'');//Account.Invoicing_postal_code__c  Account.Invoicing_city__c  
                    }
                    else if(inv.Document_Type__c=='19')
                    {
                        String billingPostCode = postalCodeLocationBilling!=null?postalCodeLocationBilling:'';
                        paymentDoc.writeCharacters(contractCountry=='BEL'?postalCodeLocationBilling:'59046 Lille Cedex');//Billing_postal_code__c Billing_city__c  FR: 59046 Lille Cedex  
                    }
                    //<postalCodeLocation/>
                    paymentDoc.writeEndElement(); 
                    //streetHouseNbr
                    String streetHouseNbr;
                    if(inv.Shipping_Street__c!=null)
                    {
                        streetHouseNbr = inv.Shipping_Street__c;
                        if(inv.Shipping_House_Nr__c!=null)
                        { 
                            if(contractCountry=='BEL')
                            {
                             streetHouseNbr = streetHouseNbr + ' ' + inv.Shipping_House_Nr__c;
                            }
                            if(contractCountry=='FRA')
                            {
                                streetHouseNbr = inv.Shipping_House_Nr__c + ' ' + streetHouseNbr;
                            }
                        }
                    }
                    if(inv.Billing_Street__c!=null)
                    {
                        streetHouseNbr = inv.Billing_Street__c;
                        if(inv.Billing_HouseNr__c!=null)
                        { 
                            if(contractCountry=='BEL')
                            {
                            streetHouseNbr = streetHouseNbr + ' ' + inv.Billing_HouseNr__c;
                            }
                            if(contractCountry=='FRA')
                            {
                                streetHouseNbr = inv.Billing_HouseNr__c + ' ' + streetHouseNbr;
                            }
                        }
                    }
                    else 
                    {
                        streetHouseNbr = inv.Shipping_House_Nr_Alpha__c;
                    }
                    //<streetHouseNbr>
                    paymentDoc.writeStartElement(null,'streetHouseNbr',null);
                    if(inv.Document_Type__c=='30'|| inv.Document_Type__c=='40')
                    {
                        paymentDoc.writeCharacters(streetHouseNbr!=null?streetHouseNbr:'');// Account.Correspondence_street__c Account.Invoicing_house_number__c
                    }
                    else if (inv.Document_Type__c=='19')
                    {
                        String houseNbrStreet= streetHouseNbr!=null?streetHouseNbr:'';
                        paymentDoc.writeCharacters(contractCountry=='BE'?houseNbrStreet:'20 rue des Vicaires');// Account.Correspondence_street__c Account.Invoicing_house_number__c FR: 20 rue des Vicaires
                    }
                    //<streetHouseNbr/>
                    paymentDoc.writeEndElement(); 
                    //addressedPersonName
                    paymentDoc.writeStartElement(null,'addressedPersonName',null);
                    if(inv.Document_Type__c=='30'|| inv.Document_Type__c=='40')
                    {
                        paymentDoc.writeCharacters(inv.Shipping_Name__c!=null?inv.Shipping_Name__c:'');
                    }
                    else if (inv.Document_Type__c=='19')
                    {
                        String billingName = inv.Billing_Name__c!=null?inv.Billing_Name__c:'';
                        paymentDoc.writeCharacters(contractCountry=='BE'?billingName:'Securex Medical Services');
                    }    
                    paymentDoc.writeEndElement();      
                    //companyName
                    if(inv.Document_Type__c=='30'|| inv.Document_Type__c=='40')
                    {
                        String cmpName = '';
                        if(inv.Contact_FirstName__c!=null && inv.Contact_LastName__c!=null)
                        {
                            cmpName = inv.Contact_FirstName__c + ' ' + inv.Contact_LastName__c;
                        }
                        else if(inv.Contact_FirstName__c!=null)
                        {   
                            cmpName = inv.Contact_FirstName__c;
                        }
                        else if(inv.Contact_LastName__c!=null)
                        {
                            cmpName = inv.Contact_LastName__c;
                        }
                        paymentDoc.writeStartElement(null,'companyName',null);
                            paymentDoc.writeCharacters(cmpName); 
                        paymentDoc.writeEndElement();                                                                                               
                    }
                //</postalAddress>
                paymentDoc.writeEndElement();
                //<referenceNbr>
                paymentDoc.writeStartElement(null,'referenceNbr',null); 	
                if(inv.Document_Type__c=='30'|| inv.Document_Type__c=='40')
                {
                    paymentDoc.writeCharacters(invoicingAccount.Parent_Securex_Number__c!=null?invoicingAccount.Parent_Securex_Number__c:'');
                } 
                else if(inv.Document_Type__c=='19')
                {
                    paymentDoc.writeCharacters(contractCountry=='BE'?invoicingAccount.RIZIV__c:String.valueOf(invoicingAccount.MID_number__c)); // BE: RIZIV FR:MID
                }
                //<referenceNbr/>
                paymentDoc.writeEndElement();
                //PurchaseOrderLabel
                if(inv.Document_Type__c=='30'|| inv.Document_Type__c=='40')
                {
                    String purchaseOrderLabel = '';
                    switch on contractCountry
                    {
                        when 'BEL'
                        {
                            switch on inv.Billing_Language__c
                            {
                                when 'NL'
                                {
                                    purchaseOrderLabel = 'PO nr';
                                }
                                when else
                                {
                                    purchaseOrderLabel = 'N° PO';
                                }
                            }
                        }
                        when 'FRA'
                        {
                            purchaseOrderLabel = 'Bon de commande';
                        }
                    }
                    //<PurchaseOrderLabel>
                    paymentDoc.writeStartElement(null,'PurchaseOrderLabel',null); 	
                        paymentDoc.writeCharacters(purchaseOrderLabel);
                    //<PurchaseOrderLabel/>
                    paymentDoc.writeEndElement();      
                }
                Set<String> allPOs = new Set<String>();
                List<Service_Appointment_Line_Item__c> saliList = new List<Service_Appointment_Line_Item__c>(); 
                if(saliPerAccId!=null)
                {
                    for(List<Service_Appointment_Line_Item__c> l :  saliPerAccId.values())
                    {
                        saliList.addAll(l); 
                    }
                }
                for(Service_Appointment_Line_Item__c  sali : saliList)
                {
                    if(sali.Service_Appointment__r.Absence_Registration__r.External_Reference__c!=null) allPOs.add(sali.Service_Appointment__r.Absence_Registration__r.External_Reference__c); 
                }
                if(inv.PO_Number__c!=null) allPOs.add(inv.PO_Number__c);
                List<String> allPOsList = new List<String>(allPOs);
                String concatPOs = String.join(allPOsList,';');
                //<purchaseOrder>
                paymentDoc.writeStartElement(null,'purchaseOrder',null); //OAPPMEDCHECK-538 OAPPMEDCHECK-708
                if(inv.Document_Type__c=='30'|| inv.Document_Type__c=='40')
                {
                    paymentDoc.writeCharacters(concatPOs);
                } 
                else if(inv.Document_Type__c=='19')
                {
                    if(contractCountry=='FRA' && inv.Invoice_Digit_Doctor__c!=null) paymentDoc.writeCharacters(String.valueOf(MATH.FLOOR(inv.Invoice_Digit_Doctor__c)));
                }
                //<purchaseOrder/>
                paymentDoc.writeEndElement();
                //<headQuarterOffice>
                paymentDoc.writeStartElement(null,'headQuarterOffice',null); 
                    if(inv.Billing_country__c!=null && inv.Billing_country__c!=contractCountry) //only send value if different than Contract Country
                    {
                        String HQofficeCountry='';
                        if(countryTranslation!=null)
                        {
                            switch on inv.Billing_Language__c{
                                when'NL' {   
                                    Map<String,String> translationNL = countryTranslation.get('NL');
                                    HQofficeCountry = translationNL!=null?translationNL.get(inv.Shipping_country__c):null;
                                }
                                when else
                                {
                                    Map<String,String> translationFR = countryTranslation.get('FR');
                                    HQofficeCountry = translationFR!=null?translationFR.get(inv.Shipping_country__c):null;
                                }
                            }
                        }
                        //<country>
                        paymentDoc.writeStartElement(null,'country',null);
                        if(inv.Document_Type__c=='30'|| inv.Document_Type__c=='40')
                        {
                            paymentDoc.writeCharacters(HQofficeCountry!=null?HQofficeCountry:''); 
                        }
                        else if(inv.Document_Type__c=='19')
                        {
                            String HQCountry= HQofficeCountry!=null?HQofficeCountry:'';
                            paymentDoc.writeCharacters(contractCountry=='FRA'?HQCountry:''); 
                        } 
                        //<country/>
                        paymentDoc.writeEndElement();    
                    }
                    //postalCodeLocation
                    if(inv.Billing_Postal_Code__c!=null && inv.Billing_city__c!=null)
                    {
                        String postalCodeLoc = inv.Billing_Postal_Code__c + ' ' + inv.Billing_city__c;
                        //<postalCodeLocation>
                        paymentDoc.writeStartElement(null,'postalCodeLocation',null); 
                        if(inv.Document_Type__c=='30'|| inv.Document_Type__c=='40')
                        {
                            paymentDoc.writeCharacters(postalCodeLoc); 
                        }
                        else if(inv.Document_Type__c=='19')
                        {
                            paymentDoc.writeCharacters(contractCountry=='FRA'?postalCodeLoc:''); 
                        }
                        //<postalCodeLocation/>
                        paymentDoc.writeEndElement();
                    }
                    //streetHouseNbr
                    //<streetHouseNbr>
                    paymentDoc.writeStartElement(null,'streetHouseNbr',null);
                    String streetHouseNbrAcc;
                    if(inv.Billing_Street__c!=null)
                    {
                        streetHouseNbrAcc = inv.Billing_Street__c;
                        if(inv.Billing_HouseNr__c!=null)
                        {
                            if(contractCountry=='BEL')
                            {
                                streetHouseNbrAcc = streetHouseNbrAcc + ' ' + inv.Billing_HouseNr__c;
                            }
                            if(contractCountry=='FRA')
                            {
                                streetHouseNbrAcc = inv.Billing_HouseNr__c  + ' ' +  streetHouseNbrAcc;
                            }
                        }
                    }
                    else
                    {
                        streetHouseNbrAcc = inv.Billing_Postal_Box__c;
                    }
                    if(inv.Document_Type__c=='30'|| inv.Document_Type__c=='40')
                    {
                        paymentDoc.writeCharacters(streetHouseNbrAcc!=null?streetHouseNbrAcc:''); 
                    } 
                    else if(inv.Document_Type__c=='19')
                    {
                        String HQStreet =streetHouseNbrAcc!=null?streetHouseNbrAcc:'';
                        paymentDoc.writeCharacters(contractCountry=='FRA'?HQStreet:''); 
                    }
                    //<streetHouseNbr/>
                    paymentDoc.writeEndElement();
                    //name1
                    //<name1>
                    paymentDoc.writeStartElement(null,'name1',null); 
                    if(inv.Document_Type__c=='30'|| inv.Document_Type__c=='40')
                    {
                        paymentDoc.writeCharacters(inv.Billing_Name__c!=null?inv.Billing_Name__c:'');
                    } 
                    else if(inv.Document_Type__c=='19')
                    {
                        String HQname1 =inv.Billing_Name__c!=null?inv.Billing_Name__c:'';
                        paymentDoc.writeCharacters(contractCountry=='FRA'?HQname1:''); 
                    }
                     //<name1/>
                    paymentDoc.writeEndElement();  
                    //name2
                    if(inv.Document_Type__c=='30'|| inv.Document_Type__c=='40')
                    {
                        //<name2>
                        paymentDoc.writeStartElement(null,'name2',null); 
                            paymentDoc.writeCharacters(inv.Billing_Name_2__c!=null?inv.Billing_Name_2__c:'');
                        //<name2/>
                        paymentDoc.writeEndElement();  
                    }
                //</headQuarterOffice>                                                                              
                paymentDoc.writeEndElement(); 
                //<contractReference>
                paymentDoc.writeStartElement(null,'contractReference',null);
                if(inv.Document_Type__c=='30'|| inv.Document_Type__c=='40')
                {
                    paymentDoc.writeCharacters(MATH.FLOOR(inv.Contract_Home__r.Contract_Digit__c) + '/' + dptNumber); 
                }                    
                else if(inv.Document_Type__c=='19')
                {
                    String regMedBoard = invoicingAccount.Registration_Medical_Board__c!=null?invoicingAccount.Registration_Medical_Board__c:'';
                    paymentDoc.writeCharacters(contractCountry=='FRA'?regMedBoard:'');// TO DO BE 
                }
                paymentDoc.writeEndElement();  
                //<companyIdentification>
                paymentDoc.writeStartElement(null,'companyIdentification',null); 
                String vatNumber = '';
                switch on contractCountry {
                    when 'FRA' {
                        if(invoicingAccount.VAT_Number__c!=null)vatNumber=invoicingAccount.VAT_Number__c;
                    }
                    when 'BEL' {
                        vatNumber=invoicingAccount.VAT_number_MCM__c!=null?invoicingAccount.VAT_number_MCM__c:invoicingAccount.Parent__r.VAT_Number__c;
                    }
                }
                    //<VATNumber/>
                    paymentDoc.writeStartElement(null,'VATNumber',null);   
                        paymentDoc.writeCharacters(vatNumber);
                    paymentDoc.writeEndElement();  
                    //<enterpriseNumber/>
                    paymentDoc.writeStartElement(null,'enterpriseNumber',null);   
                    {
                        if(inv.Document_Type__c=='30'|| inv.Document_Type__c=='40')
                        {
                            //paymentDoc.writeCharacters(contractCountry=='BEL' && invoicingAccount.Enterprise_Number__c!=null?invoicingAccount.Enterprise_Number__c:'');
                            //paymentDoc.writeCharacters(contractCountry=='BEL'?vatNumber.remove('BE'):''); removed following ticket 1320
                            paymentDoc.writeCharacters(contractCountry=='BEL' && invoicingAccount.Enterprise_Number__c!=null?invoicingAccount.Parent__r.Enterprise_Number__c:invoicingAccount.Parent__r.SIRET_Number__c!=null?invoicingAccount.Parent__r.SIRET_Number__c:'');
                        }
                        else if(inv.Document_Type__c=='19')
                        {
                            paymentDoc.writeCharacters(contractCountry=='BEL' && invoicingAccount.Enterprise_Number__c!=null?invoicingAccount.Enterprise_Number__c:invoicingAccount.SIRET_Number__c!=null?invoicingAccount.SIRET_Number__c:'');
                        }

                    }
                    paymentDoc.writeEndElement(); 
                //<companyIdentification/>
                paymentDoc.writeEndElement();  
            //</customer>
            paymentDoc.writeEndElement(); 
        //</paymentDocument>
        paymentDoc.writeEndElement(); // Quand Document_Type__c=='19' il y a un end tag en trop
        String paymentDocString = paymentDoc.getXmlString();
        return paymentDocString;
    }    

    public static String writeEmailDocString(Invoice__c inv, String invLanguage)
    {
        XmlStreamWriter emailDoc = new XmlStreamWriter();
        String contractCountry = inv.Contract_Home__r.Contract_Country__c;
        DateTime docDate = inv.Document_Date__c;
        String invoiceMonth;
        switch on inv.Billing_Language__c{
            when'NL' {   
                switch on docDate.format('MMMM'){
                    when'January' {   
                        invoiceMonth = 'januari';
                    }
                    when'February' {   
                        invoiceMonth = 'jebruari';
                    }
                    when'March' {   
                        invoiceMonth = 'maart';
                    }
                    when'April' {   
                        invoiceMonth = 'april';
                    }
                    when'May' {   
                        invoiceMonth = 'mei';
                    }
                    when'June' {   
                        invoiceMonth = 'juni';
                    }
                    when'July' {   
                        invoiceMonth = 'juli';
                    }
                    when'August' {   
                        invoiceMonth = 'augustus';
                    }
                    when'September ' {   
                        invoiceMonth = 'september';
                    }
                    when'October' {   
                        invoiceMonth = 'oktober';
                    }
                    when'November' {   
                        invoiceMonth = 'november';
                    }
                    when else {
                        invoiceMonth = 'december';
                    }
                }   
            }
            when else {
                switch on docDate.format('MMMM'){
                    when'January' {   
                        invoiceMonth = 'janvier';
                    }
                    when'February' {   
                        invoiceMonth = 'février';
                    }
                    when'March' {   
                        invoiceMonth = 'mars';
                    }
                    when'April' {   
                        invoiceMonth = 'avril';
                    }
                    when'May' {   
                        invoiceMonth = 'mai';
                    }
                    when'June' {   
                        invoiceMonth = 'juin';
                    }
                    when'July' {   
                        invoiceMonth = 'july';
                    }
                    when'August' {   
                        invoiceMonth = 'août';
                    }
                    when'September' {   
                        invoiceMonth = 'septembre';
                    }
                    when'October' {   
                        invoiceMonth = 'octobre';
                    }
                    when'November' {   
                        invoiceMonth = 'novembre';
                    }
                    when else {
                        invoiceMonth = 'décembre';
                    }
                }                   
            }

        }

        //<data>
        emailDoc.writeStartElement(null,'data',null);
            //<period>
            emailDoc.writeStartElement(null,'period',null);
                emailDoc.writeCharacters(invoiceMonth + ' ' + docDate.year());
            emailDoc.writeEndElement();
            //<invoiceNbr>
            emailDoc.writeStartElement(null,'invoiceNbr',null);
                emailDoc.writeCharacters(String.valueOf(inv.Invoice_Number__c)); 
            emailDoc.writeEndElement();
            //<signature>
            emailDoc.writeStartElement(null,'signature',null);
                //<emailAddress>
                emailDoc.writeStartElement(null,'emailAddress',null);
                    emailDoc.writeCharacters(contractCountry=='BEL'?'camcm@securex.be':'lille.comptabilite@securex.fr'); 
                emailDoc.writeEndElement();
                 //<contact>
                 emailDoc.writeStartElement(null,'contact',null);
                    emailDoc.writeCharacters(invLanguage=='NL'?'Client advisor':'Adviseur clients'); 
                emailDoc.writeEndElement();       
                 //<telephoneNbr>
                 emailDoc.writeStartElement(null,'telephoneNbr',null);
                    emailDoc.writeCharacters(contractCountry=='BEL'?'+32 78 15 41 10':'+33 3 20 06 72 00');
                emailDoc.writeEndElement();                                                
            //</signature>
            emailDoc.writeEndElement();
            //<Securex-data>    
            emailDoc.writeStartElement(null,'Securex-data',null);
                //<organisationNameCode>
                emailDoc.writeStartElement(null,'organisationNameCode',null);
                    emailDoc.writeCharacters(contractCountry=='BEL'?'MCM01':'SMS01'); //Default
                 //</organisationNameCode>
                emailDoc.writeEndElement(); 
            //</Securex-data>    
            emailDoc.writeEndElement();   
        //</data>
        emailDoc.writeEndElement(); 
        return emailDoc.getXmlString(); 
    }

    public static String writePerformanceDocString(Invoice__c inv, Account invoicingAccount, String dptNumber, Map<Id,List<Service_Appointment_Line_Item__c>> saliPerAccId,  DateTime firstDayOfMonth, DateTime lastDayOfMonth)
    {
        String contractCountry = inv.Contract_Home__r.Contract_Country__c;
        String invLanguage = inv.Billing_Language__c=='NL'?'NL':'FR'; 
        XmlStreamWriter performanceDoc = new XmlStreamWriter();
        //<providedServicesView>
        performanceDoc.writeStartElement(null,'providedServicesView',null);
            //<organisationNameCode>
            performanceDoc.writeStartElement(null,'organisationNameCode',null);
                if(inv.Document_Type__c=='30'|| inv.Document_Type__c=='40')
                {
                    performanceDoc.writeCharacters(contractCountry=='BEL'?'MCM01':'SMS01'); 
                } 
                else if(inv.Document_Type__c=='19')
                {
                    performanceDoc.writeCharacters(contractCountry=='BEL'?'MCM01':''); 
                }
            performanceDoc.writeEndElement(); 
            //<LogoIdentification>
            performanceDoc.writeStartElement(null,'LogoIdentification',null);
                if(inv.Document_Type__c=='30'|| inv.Document_Type__c=='40')
                {
                    performanceDoc.writeCharacters('Securex');
                } 
                else if(inv.Document_Type__c=='19')
                {
                    performanceDoc.writeCharacters(contractCountry=='BEL'?'Securex':''); 
                }
            performanceDoc.writeEndElement();  
            //<invoiceNbr>
            performanceDoc.writeStartElement(null,'invoiceNbr',null);
                if(inv.Document_Type__c=='30'|| inv.Document_Type__c=='40')
                {
                    performanceDoc.writeCharacters(String.valueOf(inv.Invoice_Number__c)); 
                } 
                else if(inv.Document_Type__c=='19')
                {
                    performanceDoc.writeCharacters(contractCountry=='BEL'?String.valueOf(inv.Invoice_Number__c):''); // TO DO FR
                }
            performanceDoc.writeEndElement();
            //<contractReferenceName>
            performanceDoc.writeStartElement(null,'contractReferenceName',null);
                if(inv.Document_Type__c=='30'||inv.Document_Type__c=='40')
                {
                    performanceDoc.writeCharacters(String.valueOf(inv.Invoicing_Account__r.Name)); 
                } 
                else if(inv.Document_Type__c=='19')
                {
                    performanceDoc.writeCharacters(String.valueOf(inv.Billing_name__c)); 
                }
            performanceDoc.writeEndElement();   
            //<services>
            performanceDoc.writeStartElement(null,'services',null);
                //<totalAmount>
                performanceDoc.writeStartElement(null,'totalAmount',null);
                    performanceDoc.writeCharacters(String.valueOf(inv.Total_excluded_VAT_Currency__c.setScale(2))); //VAT excluded
                performanceDoc.writeEndElement(); 
                //<period>
                performanceDoc.writeStartElement(null,'period',null);
                    //<endDate>
                    performanceDoc.writeStartElement(null,'endDate',null);
                        performanceDoc.writeCharacters(lastDayOfMonth.format('dd/MM/yyyy')); 
                    performanceDoc.writeEndElement();
                    //<startDate>
                    performanceDoc.writeStartElement(null,'startDate',null);
                        performanceDoc.writeCharacters(firstDayOfMonth.format('dd/MM/yyyy')); 
                    performanceDoc.writeEndElement();  
                 //</period>             
                performanceDoc.writeEndElement();
                if(saliPerAccId!=null && !saliPerAccId.isEmpty()) 
                {
                    if(inv.Document_Type__c=='30'|| inv.Document_Type__c=='40')
                    {
                        for(Id accId : saliPerAccId.keySet())
                        {
                             //<department>
                             performanceDoc.writeStartElement(null,'department',null);
                                List<Service_Appointment_Line_Item__c> saliPerDep = saliPerAccId.get(accId);
                                //<nbr>
                                if(saliPerDep[0].Service_Appointment__r.Account.departmentCode_Customer__c!=null)
                                {
                                    performanceDoc.writeStartElement(null,'nbr',null);
                                        performanceDoc.writeCharacters(String.valueOf(saliPerDep[0].Service_Appointment__r.Account.Department_Number__c).leftPad(3,'0')+' - '+saliPerDep[0].Service_Appointment__r.Account.departmentCode_Customer__c); 
                                    performanceDoc.writeEndElement();   
                                }
                                else
                                {
                                    performanceDoc.writeStartElement(null,'nbr',null);
                                        performanceDoc.writeCharacters(String.valueOf(saliPerDep[0].Service_Appointment__r.Account.Department_Number__c).leftPad(3,'0'));
                                    performanceDoc.writeEndElement(); 
                                }
                            Decimal amountPerDep = 0;
                            for(Service_Appointment_Line_Item__c sali : saliPerDep)
                            {
                                amountPerDep = amountPerDep + sali.Amount__c;
                                //<detail>
                                performanceDoc.writeStartElement(null,'detail',null);
                                if(sali.Service_Date__c!=null)
                                {
                                    DateTime serviceDT = sali.Service_Date__c;
                                    //<performanceDate>
                                    performanceDoc.writeStartElement(null,'performanceDate',null);
                                        performanceDoc.writeCharacters(serviceDT.format('dd/MM/yyyy'));
                                    performanceDoc.writeEndElement();
                                } 
                                    //<patientName>
                                    performanceDoc.writeStartElement(null,'patientName',null);
                                        performanceDoc.writeCharacters(sali.Name_patient__c!=null?sali.Name_patient__c:'TEST');
                                    performanceDoc.writeEndElement();
                                    //<ourReference>
                                    performanceDoc.writeStartElement(null,'ourReference',null);
                                        performanceDoc.writeCharacters(sali.Service_Appointment__r.AppointmentNumber!=null?String.valueOf(sali.Service_Appointment__r.AppointmentNumber):''); 
                                    performanceDoc.writeEndElement();
                                    //<amount>
                                    performanceDoc.writeStartElement(null,'amount',null);
                                        performanceDoc.writeCharacters(String.valueOf(sali.Amount__c.setscale(2)));
                                    performanceDoc.writeEndElement(); 
                                    String custRef=''; 
                                    if(contractCountry=='FRA')  
                                    {
                                        if(sali.Service_Appointment__r.Absence_Registration__r.External_Reference__c!=null) custRef=sali.Service_Appointment__r.Absence_Registration__r.External_Reference__c;
                                    }
                                    else if(contractCountry=='BEL')
                                    {
                                        if(sali.Service_Appointment__r.Employee__r.Employee_Number__c!=null) custRef=sali.Service_Appointment__r.Employee__r.Employee_Number__c;
                                    }
                                    //<customerReference/>
                                    performanceDoc.writeStartElement(null,'customerReference',null);
                                        performanceDoc.writeCharacters(custRef);// TO DO 19 don't send -> condition?7/09
                                    performanceDoc.writeEndElement();
                                    //<serviceDescription>
                                    performanceDoc.writeStartElement(null,'serviceDescription',null);
                                        if(invLanguage=='NL')
                                        {
                                        performanceDoc.writeCharacters(sali.Service__r.Service_Name_NL__c!=null?sali.Service__r.Service_Name_NL__c:'');
                                        }
                                        else 
                                        {
                                        performanceDoc.writeCharacters(sali.Service__r.Service_Name_FR__c!=null?sali.Service__r.Service_Name_FR__c:'');
                                        }
                                    performanceDoc.writeEndElement();
                                    performanceDoc.writeStartElement(null,'controlDoctorName',null);
                                        performanceDoc.writeCharacters(sali.Name_doctor__c!=null?sali.Name_doctor__c:'Test Doctor');// 19- don't send on 7/9?
                                    performanceDoc.writeEndElement();                            
                                //</detail>
                                performanceDoc.writeEndElement();  
                            }
                                //<amount>
                                performanceDoc.writeStartElement(null,'amount',null);
                                    performanceDoc.writeCharacters(String.valueOf(amountPerDep.setScale(2))); //VAT excluded to add logic to compute total amount per department
                                performanceDoc.writeEndElement(); 
                            //</department> 
                            performanceDoc.writeEndElement(); 
                        }                  
                    }
                    else if(inv.Document_Type__c=='19')
                    {
                        Decimal totalAmount = 0;
                        //<department>
                        performanceDoc.writeStartElement(null,'department',null);
                        for(Id accId : saliPerAccId.keySet())
                        {
                            List<Service_Appointment_Line_Item__c> saliPerDep = saliPerAccId.get(accId);
                            for(Service_Appointment_Line_Item__c sali : saliPerDep)
                            {
                                totalAmount = totalAmount + sali.Amount__c;
                                //<detail>
                                performanceDoc.writeStartElement(null,'detail',null);
                                if(sali.Service_Date__c!=null)
                                {
                                    DateTime serviceDT = sali.Service_Date__c;
                                    //<performanceDate>
                                    performanceDoc.writeStartElement(null,'performanceDate',null);
                                        performanceDoc.writeCharacters(serviceDT.format('dd/MM/yyyy'));
                                    performanceDoc.writeEndElement();
                                } 
                                    //<patientName>
                                    performanceDoc.writeStartElement(null,'patientName',null);
                                        performanceDoc.writeCharacters(sali.Name_patient__c!=null?sali.Name_patient__c:'TEST');
                                    performanceDoc.writeEndElement();
                                    //<ourReference>
                                    performanceDoc.writeStartElement(null,'ourReference',null);
                                        performanceDoc.writeCharacters(sali.Service_Appointment__r.AppointmentNumber!=null?String.valueOf(sali.Service_Appointment__r.AppointmentNumber):''); 
                                    performanceDoc.writeEndElement();
                                    //<amount>
                                    performanceDoc.writeStartElement(null,'amount',null);
                                        performanceDoc.writeCharacters(String.valueOf(sali.Amount__c.setscale(2)));
                                    performanceDoc.writeEndElement(); 
                                    String custRef=''; 
                                    if(contractCountry=='FRA')  
                                    {
                                        if(sali.Service_Appointment__r.Absence_Registration__r.External_Reference__c!=null) custRef=sali.Service_Appointment__r.Absence_Registration__r.External_Reference__c;
                                    }
                                    else if(contractCountry=='BEL')
                                    {
                                        if(sali.Service_Appointment__r.Employee__r.Employee_Number__c!=null) custRef=sali.Service_Appointment__r.Employee__r.Employee_Number__c;
                                    }
                                    //<customerReference/>
                                    performanceDoc.writeStartElement(null,'customerReference',null);
                                        performanceDoc.writeCharacters(custRef);// TO DO 19
                                    performanceDoc.writeEndElement();
                                    //<serviceDescription>
                                    performanceDoc.writeStartElement(null,'serviceDescription',null);
                                        if(invLanguage=='NL')
                                        {
                                        performanceDoc.writeCharacters(sali.Service__r.Service_Name_NL__c!=null?sali.Service__r.Service_Name_NL__c:'');
                                        }
                                        else 
                                        {
                                        performanceDoc.writeCharacters(sali.Service__r.Service_Name_FR__c!=null?sali.Service__r.Service_Name_FR__c:'');
                                        }
                                    performanceDoc.writeEndElement();
                                    performanceDoc.writeStartElement(null,'controlDoctorName',null);
                                        performanceDoc.writeCharacters(sali.Name_doctor__c!=null?sali.Name_doctor__c:'Test Doctor');
                                    performanceDoc.writeEndElement();                            
                                //</detail>
                                performanceDoc.writeEndElement();  
                            }
                        }  
                        //<amount>
                        performanceDoc.writeStartElement(null,'amount',null);
                            performanceDoc.writeCharacters(String.valueOf(totalAmount)); //VAT excluded to add logic to compute total amount per department
                        performanceDoc.writeEndElement(); 
                        //</department> 
                        performanceDoc.writeEndElement(); 
                    }
                }
            //</services>      
            performanceDoc.writeEndElement();    
            //<legalEntityNoticeCodePart1>
            performanceDoc.writeStartElement(null,'legalEntityNoticeCodePart1',null);
                if(inv.Document_Type__c=='30'|| inv.Document_Type__c=='40')
                {
                    performanceDoc.writeCharacters(contractCountry=='BEL'?'SecurexMCM':'SecurexSMS');  
                } 
                else if(inv.Document_Type__c=='19')
                {
                    performanceDoc.writeCharacters(contractCountry=='BEL'?'SecurexMCM':'');  
                }
            performanceDoc.writeEndElement();
            //<invoiceDate>
            performanceDoc.writeStartElement(null,'invoiceDate',null);
                performanceDoc.writeCharacters(String.valueOf(inv.Document_Date__c));
            performanceDoc.writeEndElement();
            //<contractReference>
            performanceDoc.writeStartElement(null,'contractReference',null);
                if(inv.Document_Type__c=='30'|| inv.Document_Type__c=='40')
                {
                    performanceDoc.writeCharacters(MATH.FLOOR(inv.Contract_Home__r.Contract_Digit__c) + '/' + dptNumber); 
                }
                else if(inv.Document_Type__c=='19')
                {
                    performanceDoc.writeCharacters(inv.Contract_Home__r.Name); 
                }
            performanceDoc.writeEndElement();
            //<legalEntityNoticeCodePart2>
            performanceDoc.writeStartElement(null,'legalEntityNoticeCodePart2',null);
                if(inv.Document_Type__c=='30'|| inv.Document_Type__c=='40')
                {
                    performanceDoc.writeCharacters(String.valueOf(contractCountry=='BEL'?'SecurexMCM':'SecurexSMS')); 
                } 
                else if(inv.Document_Type__c=='19')
                {
                    performanceDoc.writeCharacters(String.valueOf(contractCountry=='BEL'?'SecurexMCM':'')); 
                }
            performanceDoc.writeEndElement();                                                                                                         
        //</providedServicesView>
        performanceDoc.writeEndElement(); 
        return performanceDoc.getXmlString();

    }
    
    // Request builder
    public class sendInvoiceToScripturaServiceRequest
    {
        public String bundleId;
           public String bundleSize;
           public List<cdws> cdws;
           public contactInfo contact;
           public List<data> datas;
           public String documentNaam;
           public List<email> emails;
           public String eregistereds;
           public String eventFlow;
           public String gjMessages;
           public List<jobFlowData> jobFlowDatas;
           public String jobId;
           public String pom;
           public String processType;
           public String reference;
           public String templateSet;
           public String templateSetDatas;
           public String tenforces;
           public String archiveAsDuplicate;
           public List<fileName> neotouches;
    }

    public class fileName
    {
        public String fileName;
    }

    public class jobFlowData
    {
        public String key;
        public Boolean value;
    }

     public class cdws
    {
        public String attachments;
        public String cdwArchivingPeriod;
        public String cdwCallingApplication;
        public String cdwDocumentType;
        public String date2;
        public String date3;
        public String docTypeName;
        public String docid;
        public String fileName;
        public String l;
        public Decimal mon1;
        public String n3;
        public Integer num1;
        public Integer num2;
        public String pdate1;
        public String pgs;
        public String ptext1;
        public String ptext2; 
        public String text10;
        public String text11;
        public String text12;
        public String text3;
        public String text4;
        public String text5;
        public String text6;
        public String text7;
        public String text8;
        public String text9;
        public String wfv;
        public String workflow1;

    }

    public class contactInfo
    {
        public String boxNumber;                                                                               
        public String city;                                                                                      
        public String country;                                                                                   
        public String countryCode;                                                                               
        public String email;                                                                                     
        public String firstName;                                                                                 
        public String houseNumber;                                                                               
        public String language;                                                                                  
        public String lastName;                                                                                  
        public String mobilePhoneNumber;                                                                         
        public String reference;                                                                                 
        public String street;                                                                                    
        public String zipCode;                                                                                   
    }

    public class data 
    {
        public String dataId;
        public String dataValue;
        public String dataValueType;
    }

    public class email 
    {
        //public String attachments;
        //public String ccRecipients;
        public String fromEmail;
        public String fromName;
        public String replyToEmail;
        public String replyToName;
        public String subject;

    }

}