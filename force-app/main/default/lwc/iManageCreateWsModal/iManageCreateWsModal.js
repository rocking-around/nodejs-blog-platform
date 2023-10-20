import { api } from "lwc";
import LightningModal from "lightning/modal";
import loadFolderTemplates from "@salesforce/apex/ConfigurationHelper.loadFolderTemplates";

export default class IManageCreateWsModal extends LightningModal {
  @api recordId;
  @api wsSettings;
  @api newWsName;

  @api createWs;
  @api createdCallback;
  // MAGIC: if param name = 'errorCallback' -> error in SF
  @api ifErrorCallback;

  loading = true;
  saving = false;
  folderTemplateOptions = undefined;
  folderTemplate = undefined;

  async connectedCallback() {
    await this.loadData();
  }

  async loadData() {
    try {
      this.loading = true;

      // load folder templates from iManage
      const resp = await loadFolderTemplates({
        libraryId: "ACTIVE" //TODO: what library is have to be here?
      });
      this.folderTemplateOptions = Object.entries(resp).map(([key, value]) => ({
        label: value,
        value: key
      }));

      // load data from custom settings
      await this.loadWsSettings();

    } catch (error) {
      this.handleErrors(error);
    } finally {
      this.loading = false;
    }
  }

  async loadWsSettings() {
    this.folderTemplate = this.wsSettings["iManageWs:Folder_Template_Id"];
    this.loading = false;
  }

  onFolderTemplateChanged(e) {
    const { value } = e.detail;
    this.folderTemplate = value;
  }

  async createClick() {
    try {
      this.saving = true;

      const result = await this.createWs(this.folderTemplate);
      if (!result) {
        return;
      }

      if (this.createdCallback) {
        this.createdCallback();
      }

      this.close(result);
    } catch (error) {
      this.handleErrors(error);
    } finally {
      this.saving = false;
    }
  }

  cancelClick() {
    this.close(undefined);
  }

  close(result) {
    return super.close(result);
  }

  handleErrors(err) {
    if (this.ifErrorCallback) {
        this.ifErrorCallback(err.message || err?.body?.message || err)
    }
  }

  get isCreateBtnDisabled() {
    return false;
  }

  get showSpinner() {
    return this.loading || this.saving;
  }
}

