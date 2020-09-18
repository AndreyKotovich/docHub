import { LightningElement, track } from 'lwc';
import searchDocuments from '@salesforce/apex/DocHubSearchController.searchDocuments';
import getNamespacePrefix from '@salesforce/apex/DocHubSearchController.getNamespacePrefix';

export default class DocHubSearch extends LightningElement {

    @track documentList = [];
    @track curDocumentList = [];
    @track originDocumentList = [];
    @track searchKey = '';
    @track isLoading = false;
    @track prefix = '';

    connectedCallback() {
        this.isLoading = true;
        getNamespacePrefix()
            .then((res) => {
                this.isLoading = false;
                this.prefix = res;
            })
            .catch((error) => {
                console.log('searchDocuments Error', JSON.parse(JSON.stringify(error)));
                this.isLoading = false;
            });
    }

    handleKeyUp(e) {
        if (e.keyCode === 13) {
            this.documentList = [];
            this.originDocumentList = [];
            this.curDocumentList = [];

            this.searchKey = e.target.value;
            if(this.searchKey === '') {
                return;
            }
            this.isLoading = true;
            
            searchDocuments({searchKey: this.searchKey})
                .then((res) => {
                    // console.log('searchDocuments ', res.status);
                    // console.log('searchDocuments ', res.result);
                    this.documentList = JSON.parse(res.result);
                    this.documentList.forEach((e) => e.url = this.getUrl(e.Id));
                    this.originDocumentList = this.documentList.splice();
                    this.curDocumentList = this.documentList.splice(0, 20);
                    //console.log('searchDocuments documentList ', JSON.parse(JSON.stringify(this.documentList)));
                    this.isLoading = false;
                })
                .catch((error) => {
                    console.log('searchDocuments Error', JSON.parse(JSON.stringify(error)));
                    this.isLoading = false;
                });
        }
    }

    getUrl(docId) {
        return `/apex/${this.prefix}DocumentViewPage?Id=${docId}`;
    }

    refreshListDocument() {
        if (this.documentList.length > 0) {
            this.isLoading = true;
            this.curDocumentList = [...this.curDocumentList, ...this.documentList.splice(0, 20)];
            this.isLoading = false;
        }        
    }
}