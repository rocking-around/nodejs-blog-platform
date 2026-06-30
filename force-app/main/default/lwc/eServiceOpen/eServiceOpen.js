import { LightningElement, api } from 'lwc';
import GetClientMatterCode from "@salesforce/apex/iManageIFrameDialog.GetClientMatterCode";

export default class EServiceOpen extends LightningElement {
    @api recordId;

    @api
    async invoke() {
        console.log('RecordId:', this.recordId);

        alert('Hello 5!');

        GetClientMatterCode({
            entityId: this.recordId
        })
        .then((resp) => {
            console.log("*********** GetClientMatterCode:", JSON.stringify(resp));

        })
        .catch((err) => {
            console.error(err);
        })
        .finally(() => {
        });

    }
}