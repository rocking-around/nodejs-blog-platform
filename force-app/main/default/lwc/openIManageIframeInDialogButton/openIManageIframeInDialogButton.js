import { LightningElement, api } from 'lwc';
import iManageFolderPickerIFrame from "c/iManageFolderPickerIFrame";
import GetIFrameFolderPicker from "@salesforce/apex/iManageIFrameDialog.GetIFrameFolderPicker";


export default class OpenIManageIframeInDialogButton extends LightningElement {
    @api wstype;
    @api imId;
    @api label;
    @api dialogTitle;

    clickHandle() {
        this.openDialog();
    }

    async openDialog() {
        const fpUrl = await this.getIframeUrl();
        const url = this.buildFilderLinkUrl(this.imId, fpUrl);
        await iManageFolderPickerIFrame.open({
            size: "large",
            title: this.dialogTitle || "View",
            url: url,
            // eslint-disable-next-line no-undef
            imanageApi: imanage
        });
    }

    async getIframeUrl() {
        let url;
        if (this.wstype === 'folder') {
            url = await GetIFrameFolderPicker();
        } else {
            throw new Error(`Invalid value: wstype = ${this.wstype}`);
        }
        return url;
    }

    buildFilderLinkUrl(imId, imFolderUrl) {
        const url = new URL(imFolderUrl);
        url.searchParams.set('start', imId);
        url.searchParams.set('mode', 'open');
        return url.toString();
    }
}