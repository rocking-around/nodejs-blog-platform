import { LightningElement } from "lwc";
import { loadScript } from "lightning/platformResourceLoader";
import { ShowToastEvent } from "lightning/platformShowToastEvent";

import iManageApi from "@salesforce/resourceUrl/iManageApi";
import loadFolderTemplates from "@salesforce/apex/ConfigurationHelper.loadFolderTemplates";
import getIManageWSDefaultFolderTemplateId from "@salesforce/apex/ConfigurationHelper.getIManageWSDefaultFolderTemplateId";
import saveIManageWSDefaultFolderTemplateId from "@salesforce/apex/ConfigurationHelper.saveIManageWSDefaultFolderTemplateId";
import getFoldersByWorkspace from "@salesforce/apex/iManageWorkspacesHelper.getFoldersByWorkspace";

export default class IManageWorkspaceSettings extends LightningElement {
  saving = false;
  showSpinner = false;
  isChanged = false;

  iManageApiInitialized = false;

  wsFolderTemplateId = undefined;
  wsFolderTemplateIdEdit = undefined;

  folderTemplateOptions = undefined;

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

      // load folder templates from iManage
      const resp = await loadFolderTemplates();
      this.folderTemplateOptions = Object.entries(resp).map(([key, value]) => ({
        label: value,
        value: key
      }));

      // load wsFolderTemplateId from custom settings
      this.wsFolderTemplateId = await getIManageWSDefaultFolderTemplateId();

      await this.test();
      
      this.resetEdit();
    } catch (error) {
      this.handleErrors(error);
    } finally {
      this.showSpinner = false;
    }
  }

  async test( ) {
    debugger;
    const workspaceTemplate = 'ACTIVE::ACTIVE!9';
    const offset = 0;
    const size = 10;
    const t = await getFoldersByWorkspace({
      workspaceTemplate,
      offset,
      size
    });
    console.log('+++++++++++++++++++++++', t);
  }

  onFolderTemplateChanged(e) {
    const { value } = e.detail;

    this.wsFolderTemplateIdEdit = value;

    if (
      this.wsFolderTemplateId !== this.wsFolderTemplateIdEdit &&
      !this.isChanged
    ) {
      this.isChanged = true;
    }
    if (
      this.wsFolderTemplateId === this.wsFolderTemplateIdEdit &&
      this.isChanged
    ) {
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

      await saveIManageWSDefaultFolderTemplateId({
        folderTemplateId: this.wsFolderTemplateIdEdit
      });

      this.dispatchEvent(
        new ShowToastEvent({
          title: "Save...",
          message: "iManage Workspace Folder Template saved successfuly",
          variant: "success"
        })
      );

      await this.loadData();
    } catch (error) {
      this.handleErrors(error);
    } finally {
      this.showSpinner = false;
      this.saving = false;
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
    this.wsFolderTemplateIdEdit = undefined;
    this.isChanged = false;
  }

  get isSaveBtnDisabled() {
    return this.saving || !this.isChanged;
  }

  get folderTemplateIdViewValue() {
    return this.isChanged
      ? this.wsFolderTemplateIdEdit
      : this.wsFolderTemplateId;
  }
}
