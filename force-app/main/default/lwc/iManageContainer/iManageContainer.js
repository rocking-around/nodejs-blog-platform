import {
    LightningElement,
    api
} from 'lwc';

export default class IManageContainer extends LightningElement {
    @api matterId;
    @api height = '500px';
    @api referrerPolicy = 'no-referrer';
    @api sandbox = '';
    @api width = '100%';
    @api title = '';

    get showIFrame(){
      return this.matterId && this.url.length;
    }

    get url(){
      return `http://localhost:5000?m=${this.matterId}`;
    }
}