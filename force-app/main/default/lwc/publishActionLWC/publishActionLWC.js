import { LightningElement, api, track } from 'lwc';
import publishDocument from '@salesforce/apex/DocHubConnectionController.publishDocument';;
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

export default class PublishActionLWC extends LightningElement {
    @track _recordId;
    @api get recordId() {
        return this._recordId;
    }
    set recordId(value) {
        this._recordId = value;
        this.invokeCallout();
    }

    invokeCallout() {
        publishDocument({ recordId: this._recordId })
            .then((res) => {
                console.log('publishDocument res', res);
                this.showToastMessage(res.message || res.error.message, res.status, 'dismissable');

                const closeQuickActionEvent = new CustomEvent('closeQuickAction', {});
                this.dispatchEvent(closeQuickActionEvent);
            })
            .catch((error) => {
                this.showToastMessage(error, 'error', 'dismissable');
                const closeQuickActionEvent = new CustomEvent('closeQuickAction', {});
                this.dispatchEvent(closeQuickActionEvent);
            });
    }

    showToastMessage(title, variant, mode) {
        this.dispatchEvent(
            new ShowToastEvent({
                title: title,
                variant: variant,
                mode: mode
            })
        );
    }
}