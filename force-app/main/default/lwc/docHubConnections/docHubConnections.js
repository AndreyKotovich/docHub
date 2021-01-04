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
    @track isAuthorizeRef = false;
    @track fileName = '';

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

    get isAuthorizeAvail() {
        return (!this.isGoogleOAuth2 && !this.isGoogleServiceAccount) ? true : 
            (this.isGoogleOAuth2 ? false : (this.isGoogleServiceAccount && this.uploadedFiles.length > 0) ? false : true);
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
            } else {
                this.clientOptionsGoogleOAuth2.connectionName = this.template.querySelector('[data-field=connectionName]').value;
                this.clientOptionsGoogleOAuth2.connectionOrigin = 'GoogleDrive';
                this.clientOptionsGoogleOAuth2.typeAccess = this.template.querySelector('[data-field=typeAccessForGoogle]').value;
                this.clientOptionsGoogleOAuth2.currentUrl = window.location.href;
                this.onAddConnectionGoogleAuth2();
            }
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
        createGoogleDriveAuthURL({ generalData: this.clientOptionsGoogleOAuth2 })
            .then(res => {
                window.location.href = res.url;
            })
            .catch(error => {
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
                this.isLoading = false;
                this.showToastMessage('Success', 'success', 'dismissable');

            })
            .catch(error => { console.log('Error', JSON.parse(JSON.stringify(error))); });
    }

    onAuthorize() {
        if (this.isGoogleOAuth2) {
            this.clientOptionsGoogleOAuth2.connectionName = this.currentConnection.name;
            this.clientOptionsGoogleOAuth2.connectionOrigin = this.currentConnection.origin;
            this.clientOptionsGoogleOAuth2.typeAccess = this.currentConnection.typeAccess;
            this.clientOptionsGoogleOAuth2.currentUrl = window.location.href;
            this.onAddConnectionGoogleAuth2();
        }

        if (this.isGoogleServiceAccount) {
            if (this.uploadedFiles.length === 0) {
                this.showToastMessage('Upload the JSON file', 'error', 'dismissable');
            } else {
                let clientOptionsGoogleServiceAccount = {};
                clientOptionsGoogleServiceAccount.connectionName = this.currentConnection.name;
                readJsonFileForGoogleServiceAccount({ idContentDocument: this.uploadedFiles[0].documentId })
                    .then(resJson => {
                        clientOptionsGoogleServiceAccount.state = resJson;
                        clientOptionsGoogleServiceAccount.connectionOrigin = this.currentConnection.origin;
                        clientOptionsGoogleServiceAccount.typeAccess = this.currentConnection.typeAccess;
                        return createConnection({ generalData: clientOptionsGoogleServiceAccount })
                    })
                    .then(result => {
                        this.isLoading = false;
                        this.showToastMessage('Success', 'success', 'dismissable');
                        this.getConnectioAndDocumentDetails({ id: this.currentConnection.id});
                    })
                    .catch(error => { console.log('Error', JSON.parse(JSON.stringify(error))); });
            }
        }
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
        let strFileName = this.uploadedFiles[0].name + ' Files uploaded successfully!';
        this.showToastMessage(strFileName, 'Success', 'dismissable');
        this.fileName = this.uploadedFiles[0].name;
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

    _linkDocument(doc) {
        this.isLoading = true;
        linkDocument({
            generalData: {
                connectionId: JSON.stringify(this.currentConnection.id),
                documentId: doc.id,
                id: doc.sfid,
                folder: this.folderBreadcrumbs[this.folderBreadcrumbs.length - 1].name,
                connectionEmail: this.currentConnection.email,
                origin: this.currentConnection.origin,
            }
        })
            .then((res) => {
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

    _unlinkDocument(doc) {
        this.isLoading = true;
        unlinkDocument({ Id: doc.sfid, reason: 'Manually' })
            .then((res) => {
                let updateDoc = this._currentRowDocument.find(e => e.sfid === doc.sfid);
                if (updateDoc) { updateDoc.Status__c = 'Unlinked'; }
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
                let resConnectionList = JSON.parse(res);
                this.dataConnection = resConnectionList.result || [];
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
                let resDocumentInfo = JSON.parse(res);
                if (resDocumentInfo.status && resDocumentInfo.status.toLowerCase() === 'error') {
                    return Promise.reject(resDocumentInfo.error.message);
                }
                let documentInfo = resDocumentInfo.result || {};
                this.currentDocument = documentInfo.document || {};

                documentInfo.publish.forEach(el => {
                    let autoPub = el.reason === 'auto' ? ` automatically when ${el.note}` : '';
                    let name = `Published ${autoPub} by ${el.user} on ${this.formatDate(el.date)}`;
                    this.publishList.push({ id: el.id, name: name });
                });

                documentInfo.access.forEach(el => {
                    let name = `${el.user} on ${this.formatDate(el.date)}`;
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
        this.isLoading = true;
        this.isAuthorizeRef = false;
        this.isGoogleOAuth2 = false;
        this.isGoogleServiceAccount = false;
        this.fileName = '';
        this.uploadedFiles = [];
        getConnectionIdInfo({ connectionId: this.currentConnection.id })
            .then((res) => {
                let connectionInfo = JSON.parse(res);
                if (connectionInfo.status && connectionInfo.status.toLowerCase() === 'error') {
                    return Promise.reject(connectionInfo.error.message);
                }
                this.currentConnection = connectionInfo.result || {};
                return this._getConnectionDocumentList();
            })
            .then((res) => {
                let connectionDocInfo = JSON.parse(res);
                if (connectionDocInfo.status && connectionDocInfo.status.toLowerCase() === 'error') {
                    this.isAuthorizeRef = true;
                    if (this.currentConnection.origin === 'GoogleDrive' && this.currentConnection.typeAccess === 'OAuth2') {
                        this.isGoogleOAuth2 = true;
                    }

                    if (this.currentConnection.origin === 'GoogleDrive' && this.currentConnection.typeAccess === 'ServiceAccount') {
                        this.isGoogleServiceAccount = true;
                    }
                }

                this.isInfoConnection = true;
                this.isLoading = false;
            })
            .catch((error) => {
                console.log('getConnectionIdInfo error', error);
                this.isInfoConnection = true;
                this.isAuthorizeRef = true;
                this.isLoading = false;
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
        return getConnectionDocumentList({
            generalData: param
        })
            .then((res) => {
                if (res.status && res.status.toLowerCase() === 'error') { return Promise.resolve(JSON.stringify({ "status": "error", "message": res.error.message })); }
                if (this.currentRowDocument.length > 0) {
                    this.currentRowDocument = [...this.currentRowDocument, ...JSON.parse(res.files)];
                }
                else {
                    this.currentRowDocument = JSON.parse(res.files)
                }
                this.nextPageToken = res.nextPageToken;
                return Promise.resolve(JSON.stringify({ "status": "success" }));
            })
            .catch((error) => {
                console.log('getConnectionDocumentList catch ', error);
                this.isLoading = false;
                return Promise.resolve({ "status": "error", "message": error });
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
                this.getDocumentInfo(e.detail);
                break;
            case 'Unlinked':
                this._unlinkDocument(e.detail);
                break;
            case 'Linked':
                this._linkDocument(e.detail);
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

    refreshListDocument() {
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
        return `${publishDate.getMonth()}/${publishDate.getDate()}/${publishDate.getFullYear()} ${this.formatAMPM(publishDate)}`;
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