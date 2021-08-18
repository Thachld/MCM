({

    
    setFocusedTabLabel : function(cmp,tabName) {
        var workspaceAPI = cmp.find("workspace");
        workspaceAPI.getFocusedTabInfo().then(function(response) {
            var focusedTabId = response.tabId;
            workspaceAPI.setTabLabel({
                tabId: focusedTabId,
                label: tabName
            });
        })
        .catch(function(error) {
            console.log(error);
        });
    },

    setFocusedTabIcon : function(cmp) {
        var workspaceAPI = cmp.find("workspace");
        workspaceAPI.getFocusedTabInfo().then(function(response) {
            var focusedTabId = response.tabId;
                workspaceAPI.setTabIcon({
                tabId: focusedTabId,
                icon: "utility:file",
                iconAlt: ""
            });
        })
        .catch(function(error) {
            console.log(error);
        });
    },

    closeFocusedTab : function(cmp) {
        var workspaceAPI =  cmp.find("workspace");
        workspaceAPI.getFocusedTabInfo().then(function(response) {
            var focusedTabId = response.tabId;
            workspaceAPI.closeTab({tabId: focusedTabId});
        })
        .catch(function(error) {
            console.log(error);
        });
    },
    
    setTypeOfInvoicingOptions : function(cmp) {

        cmp.set('v.options',[{ id: 'Service Invoicing', label: $A.get('$Label.c.ServiceInvoicing'), selected: true },
            { id: 'Yearly contribution invoicing', label: $A.get('$Label.c.YearlyContributionInvoicing')},
            { id: 'Doctor Remuneration', label: $A.get('$Label.c.DoctorRemuneration')},
            //{ id: 'End of year invoicing', label: $A.get('$Label.c.EndOfYearInvoicing'), selected: true }
        ]);
        
    },

    searchContractsBlockedForInvoicing : function(cmp) {
        cmp.set('v.columns', [
            {label: $A.get('$Label.c.ContractName'), fieldName: 'contractLink', type: 'url',  typeAttributes: {label: { fieldName: 'contractName' }, target: '_blank'}, hideDefaultActions: true},
            {label: $A.get('$Label.c.AccountName'), fieldName: 'accountLink', type: 'url', typeAttributes: {label: { fieldName: 'accountName' }, target: '_blank'}, hideDefaultActions: true}]);
        var action = cmp.get('c.findAllContractsBlockedForInvoicing');
        action.setCallback(this, function(rsp){
            //store state of response
            var state = rsp.getState();
            if (state === "SUCCESS")
            {
                cmp.set('v.disabled', false);
                cmp.set('v.showSpinner', false);
                var contractList = rsp.getReturnValue();
                if(contractList!= null)
                {
                    cmp.set('v.contractHomes', contractList);
                }
                for(let key in contractList){
                    let ct = contractList[key];
                    ct['contractLink'] = "/"+ct.Id;
                    ct['contractName'] = ct.Name;
                    ct['accountLink'] = "/"+ct.Account__c;
                    ct['accountName'] = ct.Account__r.Commercial_Account_Name__c;
                }
                cmp.set('v.data', contractList);
            }
            else 
            {
                helper.displayError(cmp,rsp);
                cmp.set('v.disabled', false);
                cmp.set('v.showSpinner', false);
            }
        });
        $A.enqueueAction(action);     
    },

    searchRecentInvoicingBatches : function(cmp) {
        cmp.set('v.resultColumns', [
            {label: $A.get('$Label.c.BatchName'), fieldName: 'batchLink', type: 'url',  typeAttributes: {label: { fieldName: 'batchName' }, target: '_blank'}, hideDefaultActions: true},
            {label: $A.get('$Label.c.BatchStatus'), fieldName: 'batchStatus', hideDefaultActions: true},
            {label: $A.get('$Label.c.NumberOfInvoicesCreated'), fieldName: 'numberOfInvoiceCreated', hideDefaultActions: true},
            {label: $A.get('$Label.c.NumberOfErrors'), fieldName: 'numberOfErrors', hideDefaultActions: true},
            {label: $A.get('$Label.c.InvoicingType'), fieldName: 'invoicingType', hideDefaultActions: true},
            {label: $A.get('$Label.c.BatchCreatedDate'), fieldName: 'createdDate', hideDefaultActions: true}]);
        var action = cmp.get('c.findRecentInvoicingBatches');
        action.setCallback(this, function(rsp){
            //store state of response
            var state = rsp.getState();
            if (state === "SUCCESS")
            {
                cmp.set('v.disabled', false);
                cmp.set('v.showSpinner', false);
                var batchResultList = rsp.getReturnValue();
                for(let key in batchResultList){
                    let baResult = batchResultList[key];
                    baResult['batchLink'] = "/"+baResult.Id;
                    baResult['batchName'] = baResult.Name;
                    baResult['batchStatus'] = baResult.Status__c;
                    baResult['numberOfInvoiceCreated'] = baResult.Number_of_invoice_created__c;
                    baResult['numberOfErrors'] = baResult.Number_of_errors__c;
                    baResult['invoicingType'] = baResult.Invoicing_Type__c;
                    baResult['createdDate'] = baResult.CreatedDate;
                }
                cmp.set('v.batchResults', batchResultList);
            }
            else 
            {
                helper.displayError(cmp,rsp);
                cmp.set('v.disabled', false);
                cmp.set('v.showSpinner', false);
            }
        });
        $A.enqueueAction(action);     
    },

    validateInput : function(cmp) {
        let startDate = cmp.get("v.startDate");
        let endDate = cmp.get("v.endDate");
        let typeOfInvoicing = cmp.get("v.selectedValue");
        if( typeOfInvoicing =='Service Invoicing' && (startDate > endDate || startDate==null || endDate==null))
        {
            var severity = 'error';
            var title = '';
            var message = "Invalid invoicing period";
            var messageContainer = cmp.find("messageContainer");
            messageContainer.displayMessage(severity,title,message);
            cmp.set('v.disabled', false);
            cmp.set('v.showSpinner', false);
            return 'NOK';
        }
    },

    displayError : function (cmp,rsp) {
		var errors = rsp.getError();
		var message = 'Unknown error'; // Default error message
		// Retrieve the error message sent by the server
		if (errors && Array.isArray(errors) && errors.length > 0)
		{
			message = errors[0].message;
		}
		var severity = 'error';
        var title = '';
        var messageContainer = cmp.find("messageContainer");
        messageContainer.displayMessage(severity,title,message);
        return;
	}

  
})