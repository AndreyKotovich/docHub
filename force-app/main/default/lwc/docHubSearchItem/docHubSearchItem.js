import { LightningElement, api } from 'lwc';

export default class DocHubSearchItem extends LightningElement {
    @api item = {};

    get typeIcon() {
		return 'doctype:gdoc';
	}

	get areFragmentsFound() {
        return !!this.item.fragments && this.item.fragments.length > 0;
    }

    renderedCallback() {
        const templateContainer = this.template.querySelector(`[data-id="${this.item.id}"]`);

        const nameContainer = templateContainer.querySelector('[data-id="item-name"]');
        nameContainer.innerHTML = this.item.name;

        if (!!this.item.fragments && this.item.fragments.length > 0) {
            const hitsContainer = templateContainer.querySelector('[data-id="item-hits"]');
            for (const fragment of this.item.fragments) {
                const paragraphElement = document.createElement("p");
                paragraphElement.innerHTML = `"${fragment}"`;
                hitsContainer.appendChild(paragraphElement);
            }
        }
    }
}