import { LightningElement, api } from 'lwc';

export default class DocHubSearchItem extends LightningElement {
    @api item = {};
    
    get typeIcon() {
		return 'doctype:gdoc';
	}
}