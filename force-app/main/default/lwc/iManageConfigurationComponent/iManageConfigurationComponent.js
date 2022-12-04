import { LightningElement, track } from "lwc";
import { ShowToastEvent } from "lightning/platformShowToastEvent";
import getGeneralSettings from "@salesforce/apex/ConfigurationHelper.getGeneralSettings";
import saveGeneralSettings from "@salesforce/apex/ConfigurationHelper.saveGeneralSettings";
import getIManageDocumentSettings from "@salesforce/apex/ConfigurationHelper.getIManageDocumentSettings";
import saveIManageDocumentsSettings from "@salesforce/apex/ConfigurationHelper.saveIManageDocumentsSettings";

import { GeneralSettingsForm, IManageDocumentSettingsForm } from "./settings";

export default class IManageConfigurationComponent extends LightningElement {
  loading = false;
  saving = false;

  @track generalSettingsModel = {
    changed: false,
    edit: false,
    fields: undefined
  };

  @track iManageDocSettingsModel = {
    changed: false,
    edit: false,
    fields: undefined
  };

  @track isGeneralSettingsChanged = false;
  @track isIManageDocSettingsChanged = false;

  async connectedCallback() {
    await this.loadGeneralSettings();
    await this.loadIManageDocumentsSettings();
  }

  get iManageDocSettings_Matter() {
    return this.iManageDocSettingsModel?.fields?.Matter?.value;
  }

  get iManageDocSettings_MatterDocument() {
    return this.iManageDocSettingsModel?.fields?.Matter_Document?.value;
  }

  cancelCommonSettingsChanges() {
    this.generalSettingsModel = new GeneralSettingsForm(this.generalSettings);
    this.onGeneralSettingsChangedHandler(false);
  }

  cancelIManageDocumentSettingsChanges() {
    this.iManageDocSettingsModel = new IManageDocumentSettingsForm(
      this.iManageDocSettings
    );
    this.onIManageDocSettingsChangedHandler(false);
  }

  async loadGeneralSettings() {
    this.generalSettings = await getGeneralSettings();
    this.generalSettingsModel = new GeneralSettingsForm(this.generalSettings);
    this.onGeneralSettingsChangedHandler(false);
  }

  async loadIManageDocumentsSettings() {
    this.iManageDocSettings = await getIManageDocumentSettings();
    this.iManageDocSettingsModel = new IManageDocumentSettingsForm(
      this.iManageDocSettings
    );
    this.onIManageDocSettingsChangedHandler(false);
  }

  onGeneralSettingChanged(e) {
    const { name } = e.target;
    const { value, checked } = e.detail;
    const isCkeckbox = checked !== undefined;
    const newValue = isCkeckbox ? checked : value;
    this.generalSettingsModel.setValue(name, newValue);
    this.onGeneralSettingsChangedHandler(this.generalSettingsModel.changed);
  }

  onIManageDocumentSettingChanged(e) {
    const { name } = e.target;
    const { value, checked } = e.detail;
    const isCkeckbox = checked !== undefined;
    const newValue = isCkeckbox ? checked : value;
    this.iManageDocSettingsModel.setValue(name, newValue);
    this.onIManageDocSettingsChangedHandler(
      this.iManageDocSettingsModel.changed
    );
  }

  onGeneralSettingsChangedHandler(value) {
    this.isGeneralSettingsChanged = value;
  }

  onIManageDocSettingsChangedHandler(value) {
    this.isIManageDocSettingsChanged = value;
  }

  async saveCommonSettings() {
    const data = this.generalSettingsModel.getChanged({
      fieldNameWithPrefix: true
    });

    try {
      this.saving = true;
      await saveGeneralSettings({
        data
      });
      this.dispatchEvent(
        new ShowToastEvent({
          title: "Save...",
          message: "General Settings saved successfuly",
          variant: "success"
        })
      );
      this.loadGeneralSettings();
    } catch (error) {
      this.handleErrors(error);
    } finally {
      this.saving = false;
    }
  }

  async saveIManageDocSettings() {
    const data = this.iManageDocSettingsModel.getChanged({
      fieldNameWithPrefix: true
    });

    try {
      this.saving = true;
      await saveIManageDocumentsSettings({
        data
      });
      this.dispatchEvent(
        new ShowToastEvent({
          title: "Save...",
          message: "iManage Document Settings saved successfuly",
          variant: "success"
        })
      );
      this.loadIManageDocumentsSettings();
    } catch (error) {
      this.handleErrors(error);
    } finally {
      this.saving = false;
    }
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
}
