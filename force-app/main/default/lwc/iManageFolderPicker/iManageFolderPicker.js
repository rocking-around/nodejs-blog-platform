import { LightningElement } from "lwc";
import { loadScript } from "lightning/platformResourceLoader";
import { ShowToastEvent } from "lightning/platformShowToastEvent";

import iManageApi from "@salesforce/resourceUrl/iManageApi";
import GetIFrameFolderPicker from "@salesforce/apex/iManageIFrameDialog.GetIFrameFolderPicker";
import saveManualIManageDefaultFolderPath from "@salesforce/apex/ConfigurationHelper.saveManualIManageDefaultFolderPath";
import getIManageDefaultFolderId from "@salesforce/apex/ConfigurationHelper.getIManageDefaultFolderId";
import iManageFolderPickerIFrame from "c/iManageFolderPickerIFrame";

export default class IManageFolderPicker extends LightningElement {
  saving = false;
  showSpinner = false;
  isChanged = false;

  iManageApiInitialized = false;
  folderId = undefined;
  folderIdEdit = undefined;
  pickBtnDisabled = false;

  async connectedCallback() {
    await this.loadData();
  }

  async renderedCallback() {
    if (this.iManageApiInitialized) {
      return;
    }

    this.iManageApiInitialized = true;
    try {
      await loadScript(this, iManageApi);
    } catch (error) {
      this.iManageApiInitialized = false;
      this.dispatchEvent(
        new ShowToastEvent({
          title: "Error loading iManageApi",
          message: error.message,
          variant: "error"
        })
      );
    }
  }

  async loadData() {
    try {
      this.showSpinner = true;
      this.folderId = await getIManageDefaultFolderId();
      this.resetEdit();
    } catch (error) {
      this.handleErrors(error);
    } finally {
      this.showSpinner = false;
    }
  }

  async pickFolderClick() {
    this.pickBtnDisabled = true;
    this.openPickFolderDialog(() => {
      this.pickBtnDisabled = false;
    });
  }

  async openPickFolderDialog(onCloseDialogCallback) {
    try {
      const url = await GetIFrameFolderPicker();

      const result = await iManageFolderPickerIFrame.open({
        size: "large",
        title: "Select Folder",
        url: url,
        // eslint-disable-next-line no-undef
        imanageApi: imanage,
        // onselect: (e) => {
        //     e.stopPropagation();
        //     this.onFolderIdChanged(e);
        // }
        savedCallback: () => this.loadData()
        //errorCallback: (err) => this.handleErrors(err)
      });

      if (result) {
        this.dispatchEvent(
          new ShowToastEvent({
            title: "Save Folder...",
            message: `The Folder "${result.name}" saved successfuly`,
            variant: "success"
          })
        );
      }
    } catch (error) {
      this.handleErrors(error);
    } finally {
      if (onCloseDialogCallback) {
        onCloseDialogCallback();
      }
    }
  }

  onFolderIdChanged(e) {
    const { value } = e.detail;

    this.folderIdEdit = value;

    if (this.folderId !== this.folderIdEdit && !this.isChanged) {
      this.isChanged = true;
    }
    if (this.folderId === this.folderIdEdit && this.isChanged) {
      this.isChanged = false;
    }
  }

  async saveClick() {
    if (!this.isChanged) {
      return;
    }

    try {
      this.showSpinner = true;
      this.saving = true;
      this.pickBtnDisabled = true;

      await saveManualIManageDefaultFolderPath({
        folderPath: this.folderIdEdit
      });

      this.dispatchEvent(
        new ShowToastEvent({
          title: "Save...",
          message: "iManage Folder Id saved successfuly",
          variant: "success"
        })
      );

      await this.loadData();
    } catch (error) {
      this.handleErrors(error);
    } finally {
      this.showSpinner = false;
      this.saving = false;
      this.pickBtnDisabled = false;
    }
  }

  cancelClick() {
    this.resetEdit();
  }

  handleErrors(err) {
    console.error(err);
    this.dispatchEvent(
      new ShowToastEvent({
        title: "Error",
        message: err.message || err?.body?.message || err,
        variant: "error"
      })
    );
  }

  resetEdit() {
    this.folderIdEdit = undefined;
    this.isChanged = false;
  }

  get isSaveBtnDisabled() {
    return this.saving || !this.isChanged;
  }

  get folderIdViewValue() {
    return this.isChanged ? this.folderIdEdit : this.folderId;
  }
}
