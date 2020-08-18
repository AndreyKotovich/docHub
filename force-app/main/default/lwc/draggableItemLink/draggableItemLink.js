import { LightningElement, api } from 'lwc';
export default class DraggableItemLink extends LightningElement 
{
	@api item = {};
	@api index = -1;
	handleEdit(e) {
		console.log('handleEdit ', e);
		this.dispatchEvent(new CustomEvent('editbutton', { detail: { id: e.currentTarget.dataset.id } }));
	}
}