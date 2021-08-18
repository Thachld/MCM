({
    init: function (cmp, event, helper)
    {

        helper.setFocusedTabLabel(cmp,$A.get('$Label.c.CreateInvoicingBatchTitle'));
        helper.setFocusedTabIcon(cmp); 
        helper.setTypeOfInvoicingOptions(cmp);
        helper.searchContractsBlockedForInvoicing(cmp);
        helper.searchRecentInvoicingBatches(cmp);
        cmp.set('v.disabled', false);
        cmp.set('v.showSpinner', false);
    },

    handleClick : function(cmp, event, helper )
    {
        cmp.set('v.disabled', true);
        cmp.set('v.showSpinner', true);
        // var checked = helper.validateInput(cmp);
        // if(checked!='NOK')
        // {
            console.log('QLE v.selectedValue ' + cmp.get('v.selectedValue'));
            var action = cmp.get('c.launchInvoicingBatch');
            var params = {
                "typeOfInvoicing":cmp.get('v.selectedValue') ,
                "startDate":cmp.get('v.startDate')  ,
                "endDate":cmp.get('v.endDate')  ,
            };
            action.setParams(params);
            action.setCallback(this, function(rsp){
                //store state of response
                var state = rsp.getState();
                if (state === "SUCCESS")
                {
                    cmp.set('v.disabled', false);
                    cmp.set('v.showSpinner', false);
                    var severity = 'success';
                    var title = '';
                    var messageContainer = cmp.find("messageContainer");
                    messageContainer.displayMessage(severity,title,$A.get('$Label.c.BatchSuccessfullyInserted'));
                    helper.searchRecentInvoicingBatches(cmp);
                    return; 
                }
                else 
                {
                    helper.displayError(cmp,rsp);
                    cmp.set('v.disabled', false);
                    cmp.set('v.showSpinner', false);
                }
            });
            $A.enqueueAction(action);
        //}
    }

})