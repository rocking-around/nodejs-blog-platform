import { LightningElement } from "lwc";
import { loadScript } from "lightning/platformResourceLoader";
import { ShowToastEvent } from "lightning/platformShowToastEvent";

import iManageApi from "@salesforce/resourceUrl/iManageApi";
import loadFolderTemplates from "@salesforce/apex/ConfigurationHelper.loadFolderTemplates";
import getIManageWorkspaceSettings from "@salesforce/apex/ConfigurationHelper.getIManageWorkspaceSettings";
import saveIManageWorkspaceSettings from "@salesforce/apex/ConfigurationHelper.saveIManageWorkspaceSettings";

const WS_SETTINGS_PREFIX = "iManageWs";
const WS_SETTINGS_PREFIX_DELIMETER = ":";
export default class IManageWorkspaceSettings extends LightningElement {
  saving = false;
  loading = true;
  isChanged = false;

  iManageApiInitialized = false;

  wsSettingsDefault = {
    Name_Pattern: "",
    Folder_Template_Id: "",
    Create_Ws_Enabled: false,
    Auto_Create: false,
    Owner_Id: ""
  };

  wsSettings = undefined;
  wsSettingsEdt = undefined;

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
    const wsSettings = await getIManageWorkspaceSettings();
    this.applySettingsFromDb(wsSettings);
    this.loading = false;
  }

  applySettingsFromDb(source) {
    const data = {};
    for (const [key, value] of Object.entries(source)) {
      const [fieldPrefix, fieldName] = key.split(WS_SETTINGS_PREFIX_DELIMETER);
      if (fieldPrefix === WS_SETTINGS_PREFIX) {
        data[fieldName] = value;
      }
    }

    this.wsSettings = { ...this.wsSettingsDefault, ...data };

    this.resetEdit();
  }

  onIManageWsSettingChanged(e) {
    const { name } = e.target;
    const { value, checked } = e.detail;
    const isCkeckbox = checked !== undefined;
    const newValue = isCkeckbox ? checked : value;

    this.wsSettingsEdt[name] = newValue;
    this.isChanged = this.detectChanges().length > 0;
  }

  async saveClick() {
    if (!this.isChanged) {
      return;
    }

    try {
      this.saving = true;

      const data = {};
      for (const [key, value] of Object.entries(this.wsSettingsEdt)) {
        const fieldName = `${WS_SETTINGS_PREFIX}${WS_SETTINGS_PREFIX_DELIMETER}${key}`;
        data[fieldName] = value;
      }

      await saveIManageWorkspaceSettings({ data });

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
    // this.wsFolderTemplateIdEdit = undefined;
    this.isChanged = false;
    this.wsSettingsEdt = { ...this.wsSettings };
  }

  get isSaveBtnDisabled() {
    return this.saving || !this.isChanged;
  }

  get folderTemplateIdViewValue() {
    return this.isChanged
      ? this.wsFolderTemplateIdEdit
      : this.wsFolderTemplateId;
  }

  detectChanges() {
    const result = [];
    for (const oKey of Object.keys(this.wsSettingsEdt)) {
      if (this.wsSettingsEdt[oKey] !== this.wsSettings[oKey]) {
        result.push({
          key: oKey,
          oldValue: this.wsSettings[oKey],
          newValue: this.wsSettingsEdt[oKey]
        });
      }
    }
    return result;
  }

  get showSpinner() {
    return this.loading || this.saving;
  }
}