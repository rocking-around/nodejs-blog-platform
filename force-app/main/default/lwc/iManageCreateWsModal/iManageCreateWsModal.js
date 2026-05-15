import { api } from "lwc";
import LightningModal from "lightning/modal";
import loadFolderTemplates from "@salesforce/apex/ConfigurationHelper.loadFolderTemplates";

export default class IManageCreateWsModal extends LightningModal {
  @api recordId;
  @api wsSettings;
  @api imData;
  @api newWsName;

  @api createWs;
  @api createdCallback;
  // MAGIC: if param name = 'errorCallback' -> error in SF
  @api ifErrorCallback;

  loading = true;
  saving = false;
  folderTemplateOptions = undefined;
  folderTemplate = undefined;
  wsErrors = undefined;

  async connectedCallback() {
    await this.loadData();
    this.validateWsName(this.newWsName);
  }

  async loadData() {
    try {
      this.loading = true;

      // load folder templates from iManage
      const resp = await loadFolderTemplates();
      let folderTemplateOptions = Object.entries(resp).map(([key, value]) => ({
        label: value,
        value: key
      }));
      folderTemplateOptions = folderTemplateOptions.sort(
        this.compareFolderTemplateOptions()
      );
      this.folderTemplateOptions = folderTemplateOptions;

      // load data from custom settings
      await this.loadWsSettings();
    } catch (error) {
      this.handleErrors(error);
    } finally {
      this.loading = false;
    }
  }

  compareFolderTemplateOptions() {
    return (a, b) => a.label.localeCompare(b.label);
  }

  async loadWsSettings() {
    this.folderTemplate = this.wsTemplate || this.wsSettings["iManageWs:Folder_Template_Id"];
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
      this.ifErrorCallback(err.message || err?.body?.message || err);
    }
  }

  validateWsName() {
    const wsNamePlaceholders = ["{CLIENTCODE}", "{MATTERCODE}", "{CLIENTNAME}", "{MATTERNAME}"];
    if (!this.newWsName) {
      this.errors.push(`Workspace name is empty`);
      return;
    }
    for (let i = 0; i < wsNamePlaceholders.length; i++) {
      const placeholder = wsNamePlaceholders[i];
      if (this.newWsName.includes(placeholder)) {
        this.wsErrors = this.wsErrors || [];
        this.wsErrors.push({
          id: i,
          msg: `${placeholder} is empty`
        });
      }
    }
  }

  get isCreateBtnDisabled() {
    return this.hasErrors || !this.folderTemplate;
  }

  get showSpinner() {
    return this.loading || this.saving;
  }

  get hasErrors() {
    return (this.wsErrors || []).length > 0;
  }

  get wsTemplate() {
    if (!this.imData || !this.imData.wsTemplate) {
      return undefined;
    }

    if (this.imData.wsTemplate.includes('::')) {
      return this.imData.wsTemplate;
    }

    let library = this.imData.wsTemplate.split('!')[0];

    return `${library}::${this.imData.wsTemplate}`;
  }
}