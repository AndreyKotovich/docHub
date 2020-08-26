import { LightningElement, api, track, wire } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import readJsonFileForGoogleServiceAccount from '@salesforce/apex/DocHubConnectionController.readJsonFileForGoogleServiceAccount';
import createGoogleDriveAuthURL from '@salesforce/apex/DocHubConnectionController.createGoogleDriveAuthURL';
import createConnection from '@salesforce/apex/DocHubConnectionController.createConnection';
import linkDocument from '@salesforce/apex/DocHubConnectionController.linkDocument';
import unlinkDocument from '@salesforce/apex/DocHubConnectionController.unlinkDocument';
import getConnectionList from '@salesforce/apex/DocHubConnectionController.getConnectionList';
import getConnectionIdInfo from '@salesforce/apex/DocHubConnectionController.getConnectionIdInfo';
import getConnectionDocumentList from '@salesforce/apex/DocHubConnectionController.getConnectionDocumentList';
import getDocumentInfo from '@salesforce/apex/DocHubConnectionController.getDocumentInfo';

const _FOLDERBREADCRUMBS = [{ label: 'Root', name: 'root', id: 'root' }];
const _TYPEACCESSFORGOOGLE = [
    { value: '', label: '' },
    { value: 'OAuth2', label: 'OAuth 2.0' },
    { value: 'ServiceAccount', label: 'Service Account' }
];

export default class docHubConnections extends LightningElement {

    @api recordIdFileServiceAccount;
    @track isAddModal = false;
    @track isDocInfo = false;
    @track isLoading = false;

    @track dataConnection = [];
    @track currentDoc = [];
    // Google
    @track redirectUrlGoogleOAuth2;
    @track clientOptionsGoogleOAuth2 = {};
    @track typeAccessForGoogle = _TYPEACCESSFORGOOGLE;
    @track isGoogleOAuth2 = false;
    @track isGoogleServiceAccount = false;

    @track uploadedFiles;
    @track searchKey = '';
    @track nextPageToken = '';
    @track currentConnection = {};
    @track currentDocument = {};
    @track folderBreadcrumbs = _FOLDERBREADCRUMBS;
    @track _currentRowDocument = [];

    get acceptedFormats() {
        return ['.json'];
    }

    get isConnectionList() {
        return this.dataConnection.length > 0;
    }

    get isCurrentRowDocument() {
        // return this.currentRowDocument.length > 0 || (this.currentRowDocument.length === 0 && this.searchKey !== '');
        return true;
    }

    get isPublishList() {
        return this.publishList.length > 0;
    }

    get isAccessList() {
        return this.accessList.length > 0;
    }

    get isInfoConnection() {
        return this._isInfoConnection;
    }
    set isInfoConnection(value) {
        if (!value) {
            this.isLoading = true;
            this._getConnectionList();
        }
        this._isInfoConnection = value;
    }

    get currentRowDocument() {
        return this._currentRowDocument;
    }
    set currentRowDocument(value) {
        this._currentRowDocument = value;
    }

    constructor() {
        super();
        this.isInfoConnection = false;
    }

    connectedCallback() {
        this.parameters = this.getQueryParameters();
        if (this.parameters && this.parameters.c__state && this.parameters.c__state !== 'undefined') {
            let state = JSON.parse(window.atob(this.parameters.c__state));
            if (state && state.status) {
                let msg = state.status === 'Success' ? state.message : state.error ? state.error.message : '';
                this.showToastMessage(msg, state.status, 'dismissable');
                let old_url = window.location.href;
                let new_url = old_url.substring(0, (old_url).indexOf('?'));
                history.replaceState(null, null, new_url);
            }
        }
    }

    onAddConnection() {
        let allValid, allCombobox;
        if (this.isGoogleOAuth2) {
            allValid = [...this.template.querySelectorAll('lightning-input')]
                .reduce((validSoFar, inputCmp) => {
                    inputCmp.reportValidity();
                    return validSoFar && inputCmp.checkValidity();
                }, true);
            allCombobox = [...this.template.querySelectorAll('lightning-combobox')]
                .reduce((validSoFar, inputCmp) => {
                    inputCmp.reportValidity();
                    return validSoFar && inputCmp.checkValidity();
                }, true);

            if (!allValid || !allCombobox) {
                this.showToastMessage('You must enter values in the appropriate fields', 'error', 'dismissable');
            } else { console.log('isGoogleOAuth2'); this.onAddConnectionGoogleAuth2(); }
        }
        if (this.isGoogleServiceAccount) {
            allValid = [...this.template.querySelectorAll('lightning-input')]
                .reduce((validSoFar, inputCmp) => {
                    inputCmp.reportValidity();
                    return validSoFar && inputCmp.checkValidity();
                }, true);

            if (!allValid || this.uploadedFiles.length === 0) {
                this.showToastMessage('You must enter values in the appropriate fields', 'error', 'dismissable');
            } else { console.log('onAddConnectionGoogleServiceAccount'); this.onAddConnectionGoogleServiceAccount(); }
        }
        if (!this.isGoogleOAuth2 && !this.isGoogleServiceAccount) {
            allValid = [...this.template.querySelectorAll('lightning-input')]
                .reduce((validSoFar, inputCmp) => {
                    inputCmp.reportValidity();
                    return validSoFar && inputCmp.checkValidity();
                }, true);
            allCombobox = [...this.template.querySelectorAll('lightning-combobox')]
                .reduce((validSoFar, inputCmp) => {
                    inputCmp.reportValidity();
                    return validSoFar && inputCmp.checkValidity();
                }, true);

            if (!allValid || !allCombobox) {
                this.showToastMessage('You must enter values in the appropriate fields', 'error', 'dismissable');
            }
        }
    }

    onAddConnectionGoogleAuth2() {
        this.clientOptionsGoogleOAuth2.connectionName = this.template.querySelector('[data-field=connectionName]').value;
        this.clientOptionsGoogleOAuth2.connectionOrigin = 'GoogleDrive';
        this.clientOptionsGoogleOAuth2.typeAccess = this.template.querySelector('[data-field=typeAccessForGoogle]').value;
        this.clientOptionsGoogleOAuth2.currentUrl = window.location.href;

        createGoogleDriveAuthURL({ generalData: this.clientOptionsGoogleOAuth2 })
            .then(res => {
                window.location.href = res.Url;
            })
            .cathc(error => {
                console.log('Error', JSON.parse(JSON.stringify(error)));
            })
    }

    onAddConnectionGoogleServiceAccount() {
        let clientOptionsGoogleServiceAccount = {};
        clientOptionsGoogleServiceAccount.connectionName = this.template.querySelector('[data-field=connectionName]').value;
        readJsonFileForGoogleServiceAccount({ idContentDocument: this.uploadedFiles[0].documentId })
            .then(resJson => {
                clientOptionsGoogleServiceAccount.state = resJson;
                clientOptionsGoogleServiceAccount.connectionOrigin = 'GoogleDrive';
                clientOptionsGoogleServiceAccount.typeAccess = this.template.querySelector('[data-field=typeAccessForGoogle]').value;
                return createConnection({ generalData: clientOptionsGoogleServiceAccount })
            })
            .then(result => {
                this.handleAddModal();
                sethislf.isLoading = false;
                this.showToastMessage('Success', 'success', 'dismissable');

            })
            .catch(error => { console.log('Error', JSON.parse(JSON.stringify(error))); });
    }

    handleFieldChange(e) {
        if (e.currentTarget.dataset.field === 'typeAccessForGoogle') {
            this.isGoogleOAuth2 = false;
            this.isGoogleServiceAccount = false;
            if (e.target.value === 'OAuth2') { this.isGoogleOAuth2 = true; this.isGoogleServiceAccount = false; }
            if (e.target.value === 'ServiceAccount') { this.isGoogleOAuth2 = false; this.isGoogleServiceAccount = true; }
        }
    }

    handleUploadFinished(e) {
        this.uploadedFiles = e.detail.files;
        console.log('this.handleUploadFinished', this.uploadedFiles[0].documentId)
    }

    handleAddModal() {
        this.isAddModal = !this.isAddModal;
        this.isGoogleOAuth2 = false;
        this.isGoogleServiceAccount = false;
        this.uploadedFiles = [];
        this.isInfoConnection = false;
    }

    handleCloseDocInfoModal() {
        this.isDocInfo = false;
    }

    openConnection(e) {
        this.getConnectioAndDocumentDetails({ id: e.currentTarget.dataset.id });
    }

    linkDocument(doc) {
        console.log('linkDocument', doc);
        this.isLoading = true;
        linkDocument({
            generalData: {
                connectionId: JSON.stringify(this.currentConnection.id),
                documentId: doc.id,
                id: doc.sfid,
                folder: this.folderBreadcrumbs[this.folderBreadcrumbs.length -1].name,
                connectionEmail: this.currentConnection.email                
            }
        })
            .then((res) => {
                console.log(' linkDocument res ', JSON.parse(JSON.stringify(res)));

                let updateDoc = this._currentRowDocument.find(e => e.id === doc.id);
                if (updateDoc) {
                    updateDoc.Status__c = 'Linked';
                    updateDoc.sfid = res.result.sfid;
                }
                this.isLoading = false;
                this.showToastMessage(res.message, res.status, 'dismissable');
            })
            .catch(error => {
                this.isLoading = false;
                console.log('Error', JSON.parse(JSON.stringify(error)));
            });
    }

    unlinkDocument(doc) {
        console.log('unlinkDocument doc', doc)
        this.isLoading = true;
        unlinkDocument({ Id: doc.sfid })
            .then((res) => {
                console.log(' documentUnlink res ', res);
                let updateDoc = this._currentRowDocument.find(e => e.sfid === doc.sfid);
                if (updateDoc) {
                    updateDoc.Status__c = 'Unlinked';
                }
                this.isLoading = false;
                this.showToastMessage(res.message, res.status, 'dismissable');
            })
            .catch(error => {
                this.isLoading = false;
                console.log('Error', JSON.parse(JSON.stringify(error)));
            });
    }

    _getConnectionList() {
        getConnectionList()
            .then(res => {
                console.log('this.res', JSON.parse(JSON.stringify(res)));
                this.dataConnection = JSON.parse(res);
                console.log('this.dataConnection', JSON.parse(JSON.stringify(this.dataConnection)));
                this.isLoading = false;
            })
            .catch(error => { console.log('getConnectionList Error', JSON.parse(JSON.stringify(error))); this.isLoading = false; });
    }

    getDocumentInfo(row) {
        this.currentDocument = {};
        this.isLoading = true;
        this.publishList = [];
        this.accessList = [];
        getDocumentInfo({ connectionId: JSON.stringify(this.currentConnection.id), documentId: row.id })
            .then((res) => {
                let documentInfo = JSON.parse(res);
                console.log(' getDocumentInfo res ', JSON.parse(res));
                this.currentDocument = documentInfo.document;

                documentInfo.publish.forEach(el => {
                    let autoPub = el.reason === 'auto' ? ' automatically when opened' : '';
                    let name = 'Published' + autoPub + ' by ' + el.user + ' on ' + this.formatDate(el.date);
                    this.publishList.push({ id: el.id, name: name });
                });

                documentInfo.access.forEach(el => {
                    let name = el.user + ' on ' + this.formatDate(el.date);
                    this.accessList.push({ id: el.id, name: name });
                });

                this.isLoading = false;
                this.isDocInfo = true;
            })
            .catch(error => {
                this.isLoading = false;
                console.log('Error', JSON.parse(JSON.stringify(error)));
            });
    }

    getConnectioAndDocumentDetails(row) {
        this.currentConnection = row;
        this.currentRowDocument = [];
        this.folderBreadcrumbs = _FOLDERBREADCRUMBS.slice();
        this.searchKey = '';
        //this.nextPageToken = 'root';

        console.log('this.curssrentRow ', JSON.parse(JSON.stringify(this.currentConnection)));
        this.isLoading = true;
        getConnectionIdInfo({ connectionId: this.currentConnection.id })
            .then((res) => {
                console.log('resssss', JSON.parse(JSON.stringify(res)));
                this.currentConnection = JSON.parse(res);
                return this._getConnectionDocumentList();
            })
            .then((res) => {
                this.isInfoConnection = true;
                this.isLoading = false;
            })
            .catch(error => {
                this.isLoading = false;
                console.log('Error', JSON.parse(JSON.stringify(error)));
            })
    }

    _getConnectionDocumentList(pageToken = '', folder) {
        this.isLoading = true;
        let param = {
            connectionId: this.currentConnection.id,
            searchKey: this.searchKey,
            pageToken: pageToken,
        }

        if (folder) { param.folder = folder; }
        console.log('_getConnectionDocumentList param ', param);
        return getConnectionDocumentList({
            generalData: param
        })
            .then((res) => {
                if (this.currentRowDocument.length > 0) {
                    this.currentRowDocument = [...this.currentRowDocument, ...JSON.parse(res.files)];
                }
                else {
                    this.currentRowDocument = JSON.parse(res.files)
                }
                this.nextPageToken = res.nextPageToken;
                return Promise.resolve();
            })
            .catch(error => {
                this.isLoading = false;
                return Promise.reject(error);
            })
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

    getQueryParameters() {
        var params = {};
        var search = location.search.substring(1);
        if (search) {
            params = JSON.parse('{"' + search.replace(/&/g, '","').replace(/=/g, '":"') + '"}', (key, value) => {
                return key === "" ? value : decodeURIComponent(value)
            });
        }
        return params;
    }

    backToConnections() {
        this.isInfoConnection = false;
    }

    handleEventItem(e) {
        switch (e.detail.method) {
            case 'EditDocument':
                this.getDocumentInfo({ id: e.detail.id });
                break;
            case 'Unlinked':
                this.unlinkDocument({ id: e.detail.id, sfid: e.detail.sfid });
                break;
            case 'Linked':
                this.linkDocument({ id: e.detail.id, sfid: e.detail.sfid });
                break;
            case 'OpenFolder':
                this.openFolder(e.detail);
                break;
        }
    }

    openFolder(detail, isAdd = true) {
        this.currentRowDocument = [];
        this.searchKey = '';
        this._getConnectionDocumentList('', detail.id)
            .then((res) => {
                if (isAdd) {
                    this.folderBreadcrumbs.push({ label: detail.name, name: detail.name, id: detail.id });
                }
                this.isLoading = false;
            })
            .catch(error => {
                this.isLoading = false;
                console.log('Error', JSON.parse(JSON.stringify(error)));
            })
    }

    handleKeyUp(e) {
        if (e.keyCode === 13) {
            this.searchKey = e.target.value;
            this.currentRowDocument = [];
            this.folderBreadcrumbs = _FOLDERBREADCRUMBS.slice();
            this._getConnectionDocumentList()
                .then((res) => {
                    this.isLoading = false;
                })
                .catch(error => {
                    this.isLoading = false;
                    console.log('Error', JSON.parse(JSON.stringify(error)));
                })
        }
    }

    handleNavigateTo(e) {
        let folderId = e.currentTarget.dataset.id;
        let folderInx = this.folderBreadcrumbs.findIndex(el => el.id === folderId);
        this.folderBreadcrumbs = this.folderBreadcrumbs.slice(0, folderInx + 1);
        this.openFolder({ id: folderId }, false);
    }

    refreshListDocumet() {
        if (this.nextPageToken !== '') {
            this._getConnectionDocumentList(this.nextPageToken)
                .then((res) => {
                    this.isLoading = false;
                })
                .catch(error => {
                    this.isLoading = false;
                    console.log('Error', JSON.parse(JSON.stringify(error)));
                })
        }
    }

    formatDate(date) {
        let publishDate = new Date(date)
        return publishDate.getMonth() + '/' + publishDate.getDate() + '/' + publishDate.getFullYear() + ' ' + this.formatAMPM(publishDate)
    }

    formatAMPM(date) {
        var hours = date.getHours();
        var minutes = date.getMinutes();
        var ampm = hours >= 12 ? 'pm' : 'am';
        hours = hours % 12;
        hours = hours ? hours : 12; // the hour '0' should be '12'
        minutes = minutes < 10 ? '0' + minutes : minutes;
        var strTime = hours + ':' + minutes + ampm;
        return strTime;
    }

}