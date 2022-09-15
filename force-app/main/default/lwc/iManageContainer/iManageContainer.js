import {
    LightningElement,
    api
} from 'lwc';

export default class IManageContainer extends LightningElement {
    //@api matterId;
    @api height = '500px';
    @api referrerPolicy = 'no-referrer';
    @api sandbox = '';
    @api url = '';
    @api width = '100%';
    @api title = '';
}