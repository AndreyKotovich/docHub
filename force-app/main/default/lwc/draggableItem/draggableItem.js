import { LightningElement, api } from 'lwc';
export default class DraggableItem extends LightningElement {
	@api item = {};
	@api index = -1;
	handleEdit(e) {
		console.log('ev.target', e.currentTarget.dataset.id);
		this.dispatchEvent(new CustomEvent('editbutton', { detail: { id: e.currentTarget.dataset.id } }));
	}
}