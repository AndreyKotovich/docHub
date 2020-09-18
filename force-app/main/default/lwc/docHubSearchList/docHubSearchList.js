import { LightningElement, api, track } from 'lwc';

export default class DocHubSearchList extends LightningElement {
    @track _items = [];
	@track isRefreshlist = true;

	@api get items() {
		return this._items;
	}
	set items(value) {
		this._items = [];
		this.isRefreshlist = true;
		console.log('items value');
		value.forEach(element => {
			this._items.push(element);
		});
	}

	handleScroll(e) {
		if (this.isRefreshlist &&(e.target.scrollHeight - e.target.scrollTop) <=
			this.template.querySelector('[data-id=listScroll]').offsetHeight) {
			this.isRefreshlist = false;
			this.dispatchEvent(new CustomEvent('refreshlist'));
		} 
	}
}