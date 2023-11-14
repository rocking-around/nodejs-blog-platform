import { LightningElement, api } from 'lwc';
import iManageFolderPickerIFrame from "c/iManageFolderPickerIFrame";

export default class OpenIManageIframeInDialogButton extends LightningElement {
    @api url;
    @api label;

    clickHandle() {
        this.openDialog();
    }

    async openDialog() {
        await iManageFolderPickerIFrame.open({
            size: "large",
            title: "Folder",
            url: this.url,
            // eslint-disable-next-line no-undef
            imanageApi: imanage
        });
    }
}