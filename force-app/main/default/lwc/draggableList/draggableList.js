import { LightningElement, api, track } from 'lwc';

export default class DraggableList extends LightningElement {

	dragIndex = {
		'c-draggable-item-link': -1,
		'c-draggable-item': -1
	}

	@api title;
	@track _items = [];
	@track _items2 = [];

	@api set items(value) {
		this._items = [];
		value.forEach(element => {
			this._items.push(element);
		});
	}

	get items() {
		return this._items;
	}

	@api set items2(value) {
		this._items2 = [];
		value.forEach(element => {
			this._items2.push(element);
		});
	}

	get items2() {
		return this._items2;
	}

	allowDrop(ev) {
		// on dragover I swap the elements
		// console.log('allowDrop ev', ev);

		// var el = this.template.elementFromPoint(ev.clientX, ev.clientY); 
		// console.log('allowDrop el', el);
		// console.log('allowDrop el.nodeName', el.nodeName);

		// //this.nodeName = String(el.nodeName).toLowerCase();
		// console.log('allowDrop this.nodeName', this.nodeName);
		// this.swapElement(ev.target);

		// ev.preventDefault();
		// ev.stopPropagation();
		// ev.dataTransfer.dropEffect = "move";
		// ev.target.parentElement.classList.add('dragover');
	}

	dropItem(ev) {
		ev.preventDefault();
		ev.stopPropagation();
		this.swapElement(ev.target);

		ev.dataTransfer.clearData('text/index');
		this.dragIndex = {
			'c-draggable-item-link': -1,
			'c-draggable-item': -1
		}
		ev.target.parentElement.classList.remove('dragover');

	}

	swapElement(el) {
		var idxSource = this.dragIndex[this.nodeName];
		var idxTarget = el.index;
		this.swapArray(idxSource, idxTarget);
		this.toggleDraggableClass();
		this.dragIndex[this.nodeName] = idxTarget;
		this.dispatchEvent(new CustomEvent('listchanged', {}));
	}

	startDrag(ev) {
		var el = this.template.elementFromPoint(ev.clientX, ev.clientY);
		this.nodeName = String(el.nodeName).toLowerCase();
		this.dragIndex[this.nodeName] = ev.target.querySelector(this.nodeName).index
		ev.dataTransfer.setData('text/index', this.dragIndex[this.nodeName]);
		ev.dataTransfer.dropEffect = "move";
	}

	swapArray(idx1, idx2) {
		if (this.nodeName === 'c-draggable-item') {
			[this._items[idx1], this._items[idx2]] = [this._items[idx2], this._items[idx1]];
		} else {
			[this._items2[idx1], this._items2[idx2]] = [this._items2[idx2], this._items2[idx1]];
		}
	}

	dragLeave(ev) {
		var el = ev.target.parentElement;
		if (el) {
			el.classList.remove('dragover');
		}
	}

	dragEnd(ev) {
		var el = this.template.elementFromPoint(ev.clientX, ev.clientY);
		if (this.nodeName !== String(el.nodeName).toLowerCase() && (
				String(el.nodeName).toLowerCase()  === 'c-draggable-item' || 
				String(el.nodeName).toLowerCase()  === 'c-draggable-item-link'
			) || (String(el.nodeName).toLowerCase()  === 'div' && (el.dataset.id === 'unlinked' || el.dataset.id === 'linked'))) {
			
			if (this.nodeName === 'c-draggable-item' && el.dataset.id === undefined) {
				this._items2.push(...this._items.splice(this.dragIndex[this.nodeName], 1));
			} 
			if (this.nodeName === 'c-draggable-item-link'  && el.dataset.id === undefined) {
				this._items.push(...this._items2.splice(this.dragIndex[this.nodeName], 1));
			}

			if (String(el.nodeName).toLowerCase()  === 'div') {
				if (this.nodeName === 'c-draggable-item' && el.dataset.id === 'linked') {
					this._items2.push(...this._items.splice(this.dragIndex[this.nodeName], 1));
				} 
				if (this.nodeName === 'c-draggable-item-link' && el.dataset.id === 'unlinked') {
					this._items.push(...this._items2.splice(this.dragIndex[this.nodeName], 1));
				}
			}
		};
		this.dragIndex = {
			'c-draggable-item-link': -1,
			'c-draggable-item': -1
		}
		ev.preventDefault();
		ev.stopPropagation();
		this.toggleDraggableClass();

		this.dispatchEvent(new CustomEvent('listchanged', {}));
	}

	toggleDraggableClass() {
		var elms = this.template.querySelectorAll(this.nodeName);
		elms.forEach(el => {
			if (el.index === this.dragIndex[this.nodeName]) {
				el.parentElement.classList.add('dragover');
			} else {
				el.parentElement.classList.remove('dragover');
			}
		});
	}

	handleEditButton(e) {
		this.dispatchEvent(new CustomEvent('openeditwindow', { detail: { id: e.detail.id } }));
	}

}