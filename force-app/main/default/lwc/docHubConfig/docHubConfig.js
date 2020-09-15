import { LightningElement, track } from 'lwc';
import getRegisterStatus from '@salesforce/apex/DocHubConfigController.getRegisterStatus';
import registerOrg from '@salesforce/apex/DocHubConfigController.registerOrg';

export default class DocHubConfig extends LightningElement {

    @track isLoading = false;
    @track isRegisterStatus = false;
    @track registerMessage;

    connectedCallback() {
        this.isLoading = true;
        this.registerMessage = '';
        getRegisterStatus()
        .then(res => {
            this.isRegisterStatus = res;
            if (this.isRegisterStatus) {
                return Promise.resolve({ status : 'Success' });
            }
            return registerOrg();
        })
        .then(res => {
            this.isRegisterStatus = res && res.status && res.status === 'Success' ? true : false;
            this.registerMessage = res && res.status && res.status === 'Error' ? `(${res.error.message})` : '';
            this.isLoading = false;
        })
        .catch(error => {
            console.log('error ', error);
            this.isRegisterStatus = false;
            this.registerMessage = error;
            this.isLoading = false;
        });
    }
}