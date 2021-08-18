import { LightningElement, wire, api } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
import getServiceAppointments from '@salesforce/apex/createCreditNoteController.getServiceAppointments';

//Custom Label
import LABEL_SA_NAME from '@salesforce/label/c.SA_Name';
import LABEL_NAME_PATIENT from '@salesforce/label/c.Name_Patient';
import LABEL_SERVICE_DATE from '@salesforce/label/c.Service_Date';
import LABEL_SERVICE from '@salesforce/label/c.Service';

const COLUMNS = [
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
    {label:LABEL_SERVICE_DATE, fieldName:'Service_date__c', type : 'Date', sortable:"true"}    
];

export default class ServiceAppointmentDataTable extends NavigationMixin(LightningElement) {
    @api invoiceid;
    columns = COLUMNS;    
    data = [];
    error = [];
    sortBy='AppointmentNumber';
    sortDirection = 'asc';


    @wire(getServiceAppointments, {invoiceId:'$invoiceid' })
    serviceAppointments(result) {
        if (result.data) {
            this.data = result.data;
            this.error = undefined;

        } else if (result.error) {
            this.error = result.error;
            this.data = undefined;
        }
    }

    getSelectedRows(event){
        const rowselected = event.detail.selectedRows;
        
        var selectedSAIds = [];
        for(let i = 0; i < rowselected.length; i ++){
            var row = rowselected[i];
            selectedSAIds.push(row.Id);
        }

        const selectionEvent = new CustomEvent('selectedsa', { detail: { value: selectedSAIds } } );
        this.dispatchEvent(selectionEvent);       
    }

    
    updateColumnSorting(event){
        let fieldName = event.detail.fieldName;
        let direction = event.detail.sortDirection;
        //assign the values
        this.sortBy = fieldName;
        this.sortDirection = direction;
        //call the custom sort method.
        this.sortData(fieldName, direction);
    }

    sortData(fieldName, direction) {
        var data = JSON.parse(JSON.stringify(this.data));
        //function to return the value stored in the field
        var key =(a) => a[fieldName]; 
        var reverse = direction === 'asc' ? 1: -1;
        data.sort((a,b) => {
            let valueA = key(a) ? key(a).toLowerCase() : '';
            let valueB = key(b) ? key(b).toLowerCase() : '';
            return reverse * ((valueA > valueB) - (valueB > valueA));
        });

        //set sorted data to opportunities attribute
        this.data = data;
    }

    handleRowAction(event) {
        if (event.detail.action.name === "gotoSA") {
            this[NavigationMixin.GenerateUrl]({
                type: "standard__recordPage",
                attributes: {
                    objectApiName: 'ServiceAppointment',
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
            })
            .then((url) => {
                window.open(url, "_blank");
            });
        }   
    }
}