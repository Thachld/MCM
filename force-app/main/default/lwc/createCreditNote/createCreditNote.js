import { LightningElement, api, wire,track } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
import { refreshApex } from '@salesforce/apex';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import createCreditNote from '@salesforce/apex/createCreditNoteController.createCreditNote';
import getInvoiceInfo from '@salesforce/apex/createCreditNoteController.getInvoiceInfo';

//Custom Label
import LABEL_SELECT_ACTION from '@salesforce/label/c.Choose_Your_Action';
import LABEL_WARNING_SA from '@salesforce/label/c.No_SA_Selected';
import LABEL_WARNING_IDL from '@salesforce/label/c.No_IDL_Selected';
import LABEL_WARNING_NO_ACTION from '@salesforce/label/c.No_Action_Selected';
import LABEL_SUCCESS_CREATE_MESSAGE from '@salesforce/label/c.Success_Create_CN';
import LABEL_FAILED_CREATE_MESSAGE from '@salesforce/label/c.Failed_to_Create_CN';
import LABEL_EXIST_CN_MESSAGE from '@salesforce/label/c.Exist_Credit_Note';
import LABEL_SPINNER_MSG from '@salesforce/label/c.CN_Spinner_Mesage';
import LABEL_CREATE_CN_BTN from '@salesforce/label/c.Create_Credit_Note';

import LABEL_ACTION_ALL from '@salesforce/label/c.Total_Credit_note';
import LABEL_ACTION_SA from '@salesforce/label/c.Credit_note_SA';
import LABEL_ACTION_IDL from '@salesforce/label/c.Credit_note_IDL';

import LABEL_MODAL_TITLE from '@salesforce/label/c.CN_Modal_Title';
import LABEL_MODAL_BODY from '@salesforce/label/c.CN_Modal_Body';
import LABEL_MODAL_CONFIRM_BTN from '@salesforce/label/c.CN_Modal_BTN_Confirm';
import LABEL_MODAL_CANCEL_BTN from '@salesforce/label/c.CN_Modal_BTN_Cancel';

const options =[
    {'label' : LABEL_ACTION_ALL, 'value': 'ALL'},
    {'label' : LABEL_ACTION_SA, 'value': 'SA'},
    {'label' : LABEL_ACTION_IDL, 'value': 'IDL'}
];

export default class CreateCreditNote extends NavigationMixin(LightningElement) {
    @api recordId;

    @track invoiceInfo = [];
    invoicedata=[];
    error=[];     
    
    actionType = 'ALL';
    selectedSA = [];
    selectedIDL = [];
    isModalOpen = false;
    isSpinnerLoad = false;
    isSA = false;
    isIDL = false;       
    bodyBox = 'slds-box box-display-none';
    selectoptions = [];
    isExistCreditNote = false;

    LABEL_ACION = LABEL_SELECT_ACTION;
    LABEL_MD_TITLE = LABEL_MODAL_TITLE;
    LABEL_MD_BODY = LABEL_MODAL_BODY;
    LABEL_MD_CONFIRM_BTN = LABEL_MODAL_CONFIRM_BTN;
    LABEL_MD_CANCEL_BTN = LABEL_MODAL_CANCEL_BTN;
    LABEL_EXISTS_CN = LABEL_EXIST_CN_MESSAGE;
    LABEL_SPINNER_MESSAGE = LABEL_SPINNER_MSG;    
    LABEL_CREATE_CN = LABEL_CREATE_CN_BTN;

   
    @wire(getInvoiceInfo, {invoiceId:'$recordId' })    
    getExist(result) {
        this.invoiceInfo = result;
        if(result.data){
            this.invoicedata = result.data; 
            console.log('this.invoicedata' + JSON.stringify(this.invoicedata));

            let invoicingType =  this.invoicedata.InvoicingType;        
            if(invoicingType === 'Yearly contribution invoicing' || invoicingType === 'Pack invoicing'){
                this.selectoptions = [{'label' : LABEL_ACTION_ALL, 'value': 'ALL'}]
            }else{
                this.selectoptions =[
                    {'label' : LABEL_ACTION_ALL, 'value': 'ALL'},
                    {'label' : LABEL_ACTION_SA, 'value': 'SA'},
                    {'label' : LABEL_ACTION_IDL, 'value': 'IDL'}
                ];
            }

            if(this.invoicedata.IsExist){
                this.isExistCreditNote = true;
            }
            
        }else if (result.error) {
            console.log('getExist error', JSON.stringify(result.error)); 
        }
    }
   
    handleCreateCreditMemo(){
        if(this.actionType != null && this.actionType != undefined){
            if(this.actionType === 'ALL'){
                this.isModalOpen = true; 
            }else if(this.actionType === 'SA'){
                if(this.selectedSA.length != 0){
                    this.isModalOpen = true;    
                }else{
                    this.showNotification('warning', LABEL_WARNING_SA, 'Warning Message!');
                }
            }else if(this.actionType === 'IDL'){
                if(this.selectedIDL.length != 0){
                    this.isModalOpen = true;    
                }else{
                    this.showNotification('warning', LABEL_WARNING_IDL, 'Warning Message!');
                }
            }
                    
        }else{
            this.showNotification('warning', LABEL_WARNING_NO_ACTION, 'Warning Message!');
        }
        
    }

    handleOpenCreditNote(event){
        this.doNavigatetoNewCreditmemo(this.invoicedata.CreditNoteId);
    }

    handleSelectedCreditNoteType(event){
        let selectedvalue = event.target.value;
        this.actionType = selectedvalue;
        if(selectedvalue === 'SA'){
            this.isSA = true;
            this.isIDL = false;
            this.bodyBox = 'slds-box';
        }else if(selectedvalue === 'IDL'){
            this.isIDL = true;
            this.isSA = false;
            this.bodyBox = 'slds-box';
        }else{
            this.isIDL = false;
            this.isSA = false;
            this.bodyBox = 'slds-box box-display-none';
        }
    }

    showNotification(variant, message, title){
        const evt = new ShowToastEvent({     
            title : title,       
            message: message,
            variant: variant,
            mode: 'dismissible'
        });
        this.dispatchEvent(evt);
    }

    handleSelectedsa(event){        
        this.selectedSA = event.detail.value;        
    }

    handleSelectedidl(event){
        this.selectedIDL = event.detail.value;        
    }

    handleConfirm(){        
        this.isModalOpen = false;  
        this.isSpinnerLoad = true;
        
        let values = [];
        if(this.actionType === 'SA'){
            values = this.selectedSA;
        }else if(this.actionType === 'IDL'){
            values = this.selectedIDL;
        }

        createCreditNote({invoiceId: this.recordId, actionType: this.actionType, selectedValues : values})       
        .then(result=> {
            if(result){
                this.isSpinnerLoad = false;     
                console.log('result' + result.Id);
                refreshApex(this.invoiceInfo);  
                this.doNavigatetoNewCreditmemo(result.Id);
                this.showNotification('success', LABEL_SUCCESS_CREATE_MESSAGE, 'Success Message!');  
                   
            }    
        })
        .catch(error=>{
            this.isSpinnerLoad = false;     
            this.showNotification('error', LABEL_FAILED_CREATE_MESSAGE, 'Failed Message!');          
            console.log('error=>' + error);
            
        })   
        
    }

    closeModal(){
        this.isModalOpen = false;
    }

    doNavigatetoNewCreditmemo(recId){        
        this[NavigationMixin.Navigate]({
            type: 'standard__recordPage',
            attributes: {
                recordId: recId,
                objectApiName: 'Invoice__c', // objectApiName is optional
                actionName: 'view'
            }
        });
    }          
                
    
}