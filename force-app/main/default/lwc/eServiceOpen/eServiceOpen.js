import { LightningElement, api } from 'lwc';
import GetClientMatterCode from "@salesforce/apex/iManageIFrameDialog.GetClientMatterCode";

export default class EServiceOpen extends LightningElement {
    @api recordId;

    @api
    async invoke() {
        console.log('RecordId:', this.recordId);

        GetClientMatterCode({
            entityId: this.recordId
        })
        .then((resp) => {
            console.log("*********** ClientMatterCode:", JSON.stringify(resp));

            const parts = resp.split(".");

            if (parts.length !== 2) 
                throw new Error("Invalid clientMatterCode format");

            const [clientCode, matterCode] = parts;
            const url = " https://eservices.csk.legal/new?client=" + clientCode + "&matter=" + matterCode;
            console.log("url: " + url)
            window.open(url, "_blank");
        })
        .catch((err) => {
            console.error(err);
        })
        .finally(() => {
        });
    }
}