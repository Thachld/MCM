import { LightningElement, wire, api } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
import getServiceAppointmentLineItems from '@salesforce/apex/createCreditNoteController.getServiceAppointmentLineItems';

//Custom Label
import LABEL_IDL_NAME from '@salesforce/label/c.IDL_Name';
import LABEL_SA_NAME from '@salesforce/label/c.SA_Name';
import LABEL_NAME_PATIENT from '@salesforce/label/c.Name_Patient';
import LABEL_SERVICE_DATE from '@salesforce/label/c.Service_Date';
import LABEL_SERVICE from '@salesforce/label/c.Service';

const COLUMNS = [
    {
        label: LABEL_IDL_NAME,
        type: "button",
        sortable:"true",
        fieldName: "Name",
        typeAttributes: { label: { fieldName: "Name" }, name: "gotoIDL", variant: "base" }
    }, 
    {
        label: LABEL_SA_NAME,
        type: "button",
        sortable:"true",
        fieldName: "AppointmentNumber",
        typeAttributes: { label: { fieldName: "AppointmentNumber" }, name: "gotoSA", variant: "base" }
    }, 
    {
        label: LABEL_NAME_PATIENT,
        type: "button",
        sortable:"true",
        fieldName: "Name_patient__c",
        typeAttributes: { label: { fieldName: "Name_patient__c" }, name: "gotoPatient", variant: "base" }
    },
    {
        label: LABEL_SERVICE,
        type: "button",
        sortable:"true",
        fieldName: "serviceName",
        typeAttributes: { label: { fieldName: "serviceName" }, name: "gotoService", variant: "base" }
    },    
    {label:LABEL_SERVICE_DATE, fieldName:'Service_date__c', type : 'Date', sortable:"true"},
]

export default class SaLineItemDataTable extends NavigationMixin(LightningElement) {
    @api invoiceid;
    columns = COLUMNS;
    data = [];
    error = [];
    
    sortBy;
    sortDirection;


    @wire(getServiceAppointmentLineItems, {invoiceId:'$invoiceid' })
    serviceLineItems(result) {
        if (result.data) {
            this.data = result.data.map(row=>{
                return {...row, serviceName : row.Service__r.Name,
                                Employee__c : row.Service_Appointment__r.Employee__c,
                                AppointmentNumber : row.Service_Appointment__r.AppointmentNumber,
                            }
            });
            this.error = undefined;

        } else if (result.error) {
            this.error = result.error;
            this.data = undefined;
        }
    }


    getSelectedRows(event){
        const rowselected = event.detail.selectedRows;
        
        var selectedIDLIds = [];
        for(let i = 0; i < rowselected.length; i ++){
            var row = rowselected[i];
            selectedIDLIds.push(row.Id);
        }

        const selectionEvent = new CustomEvent('selectedidl', {detail:{ value: selectedIDLIds }});
        this.dispatchEvent(selectionEvent);
    }

    handleSortdata(event) {
        // field name
        this.sortBy = event.detail.fieldName;

        // sort direction
        this.sortDirection = event.detail.sortDirection;

        // calling sortdata function to sort the data based on direction and selected field
        this.sortData(event.detail.fieldName, event.detail.sortDirection);
    }

    sortData(fieldname, direction) {
        // serialize the data before calling sort function
        let parseData = JSON.parse(JSON.stringify(this.data));

        // Return the value stored in the field
        let keyValue = (a) => {
            return a[fieldname];
        };

        // cheking reverse direction 
        let isReverse = direction === 'asc' ? 1: -1;

        // sorting data 
        parseData.sort((x, y) => {
            x = keyValue(x) ? keyValue(x) : ''; // handling null values
            y = keyValue(y) ? keyValue(y) : '';

            // sorting values based on direction
            return isReverse * ((x > y) - (y > x));
        });

        // set the sorted data to data table data
        this.data = parseData;

    }

    handleRowAction(event) {
        if (event.detail.action.name === "gotoIDL") {
            this[NavigationMixin.GenerateUrl]({
                type: "standard__recordPage",
                attributes: {
                    objectApiName: 'InvoiceLineItem__c',
                    recordId: event.detail.row.Id,
                    actionName: "view"
                }
            }).then((url) => {
                window.open(url, "_blank");
            });
        }else if(event.detail.action.name === 'gotoPatient'){
            this[NavigationMixin.GenerateUrl]({
                type: "standard__recordPage",
                attributes: {
                    objectApiName: 'Employee__c',
                    recordId: event.detail.row.Employee__c,
                    actionName: "view"
                }
            }).then((url) => {
                window.open(url, "_blank");
            });
        }else if(event.detail.action.name === 'gotoService'){
            this[NavigationMixin.GenerateUrl]({
                type: "standard__recordPage",
                attributes: {
                    objectApiName: 'Service__c',
                    recordId: event.detail.row.Service__c,
                    actionName: "view"
                }
            }).then((url) => {
                window.open(url, "_blank");
            });
        }
        else if(event.detail.action.name === 'gotoSA'){
            this[NavigationMixin.GenerateUrl]({
                type: "standard__recordPage",
                attributes: {
                    objectApiName: 'ServiceAppointment',
                    recordId: event.detail.row.Service_Appointment__c,
                    actionName: "view"
                }
            }).then((url) => {
                window.open(url, "_blank");
            });
        }           
    }
}