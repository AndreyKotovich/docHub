import { LightningElement, api } from 'lwc';
export default class DocumentItem extends LightningElement {
	@api item = {};

	get isFolder() {
		return this.item.mimeType === 'application/vnd.google-apps.folder';
	}

	get isLinked() {
		return this.item.Status__c === 'Linked';
	}

	get owner() {
		return this.item.owners && this.item.owners[0] ? this.item.owners[0].displayName : '';
	}

	get typeIcon() {
		return 'doctype:gdoc';
	}

	handleEdit(e) {
		this.dispatchEvent(new CustomEvent('eventitem', { detail: this.getDetail('EditDocument') }));
	}

	handleUnlinked(e) {
		this.dispatchEvent(new CustomEvent('eventitem', { detail: this.getDetail('Unlinked') }));
	}

	handleLinked(e) {
		this.dispatchEvent(new CustomEvent('eventitem', { detail: this.getDetail('Linked') }));
	}

	handleOpenFolder(e) {
		this.dispatchEvent(new CustomEvent('eventitem', { detail: this.getDetail('OpenFolder') }));
	}

	getDetail(method) {
		return { method: method, id: this.item.id, sfid: this.item.sfid, name: this.item.name };
	}
}