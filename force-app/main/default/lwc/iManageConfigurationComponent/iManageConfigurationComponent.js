import { LightningElement, track } from "lwc";
import { ShowToastEvent } from "lightning/platformShowToastEvent";
import { loadStyle } from "lightning/platformResourceLoader";
import AppCSS from "@salesforce/resourceUrl/AppCSS";
import checkOrganizationLicense from "@salesforce/apex/ConfigurationHelper.checkOrganizationLicense";
import getGeneralSettings from "@salesforce/apex/ConfigurationHelper.getGeneralSettings";
import saveGeneralSettings from "@salesforce/apex/ConfigurationHelper.saveGeneralSettings";
import getIManageDocumentSettings from "@salesforce/apex/ConfigurationHelper.getIManageDocumentSettings";
import saveIManageDocumentsSettings from "@salesforce/apex/ConfigurationHelper.saveIManageDocumentsSettings";
import getMapping from "@salesforce/apex/IManageMappingHelper.getMapping";
import TestUpload from "@salesforce/apex/iManageWrapper.TestUpload";

import {
  GeneralSettingsForm,
  IManageDocumentSettingsForm,
  defaultGeneralSettings,
  DEFAULT_IMANAGE_MAPPING_ENTITY
} from "./settings";

export default class IManageConfigurationComponent extends LightningElement {
  loading = false;
  saving = false;
  invalidLicense = false;
  invalidLicenseMessages = undefined;

  generalSettingsModel = {
    changed: false,
    edit: false,
    fields: undefined
  };

  iManageDocSettingsModel = {
    changed: false,
    edit: false,
    fields: undefined
  };

  iManageMappingEntity = undefined;

  @track generalSettingsEdit = {};
  @track iManageDocSettingsEdit = {};

  @track isGeneralSettingsChanged = false;
  @track isIManageDocSettingsChanged = false;

  async connectedCallback() {
    try {
      await this.checkLicense();
      await this.loadGeneralSettings();
      await this.loadIManageDocumentsSettings();
      await this.loadImanageMapping();
    } catch (error) {
      this.handleErrors(error);
    }
  }

  async renderedCallback() {
    if (this.isInitialized) {
      return;
    }

    try {
      await loadStyle(this, AppCSS);
    } catch (err) {
      console.log(`Can't load AppCSS`, err);
    }
    this.isInitialized = true;
  }

  cancelGeneralSettingsChanges() {
    this.generalSettingsEdit = this.generalSettingsModel.selectFields(
      () => true,
      (x) => x.initialValue,
      (x) => x.name
    );
    this.generalSettingsModel = new GeneralSettingsForm(this.generalSettings);

    this.onGeneralSettingsChangedHandler(false);
  }

  cancelIManageDocumentSettingsChanges() {
    this.iManageDocSettingsEdit = this.iManageDocSettingsModel.selectFields(
      () => true,
      (x) => x.initialValue,
      (x) => x.name
    );

    this.iManageDocSettingsModel = new IManageDocumentSettingsForm(
      this.iManageDocSettings
    );
    this.onIManageDocSettingsChangedHandler(false);
  }

  async checkLicense() {
    try {
      await checkOrganizationLicense();
    } catch (error) {
      this.invalidLicense = true;
      this.invalidLicenseMessages = (error.body.message || "")
        .split("\n")
        .map((x, ind) => ({
          id: ind,
          value: x
        }));
      throw error;
    }
  }

  async loadGeneralSettings() {
    const settings = await getGeneralSettings();
    this.generalSettings = { ...defaultGeneralSettings, ...settings };
    this.generalSettingsModel = new GeneralSettingsForm(this.generalSettings);

    console.log(settings);

    this.generalSettingsEdit = this.generalSettingsModel.selectFields(
      () => true,
      (x) => x.initialValue,
      (x) => x.name
    );

    this.onGeneralSettingsChangedHandler(false);
  }

  async loadIManageDocumentsSettings() {
    this.iManageDocSettings = await getIManageDocumentSettings();
    this.iManageDocSettingsModel = new IManageDocumentSettingsForm(
      this.iManageDocSettings
    );
    this.iManageDocSettingsEdit = this.iManageDocSettingsModel.selectFields(
      () => true,
      (x) => x.initialValue,
      (x) => x.name
    );
    this.onIManageDocSettingsChangedHandler(false);
  }

  async loadImanageMapping() {
    const mapping = await getMapping();
    this.iManageMappingEntity =
      mapping?.EntityType || DEFAULT_IMANAGE_MAPPING_ENTITY;
  }

  onGeneralSettingChanged(e) {
    const { name } = e.target;
    const { value, checked } = e.detail;
    const isCkeckbox = checked !== undefined;
    const newValue = isCkeckbox ? checked : value;
    this.generalSettingsModel.setValue(name, newValue);
    this.onGeneralSettingsChangedHandler(this.generalSettingsModel.changed);

    const changedValues = this.generalSettingsModel.getChanged();

    this.generalSettingsEdit = {
      ...this.generalSettingsEdit,
      ...changedValues
    };
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

    const changedValues = this.iManageDocSettingsModel.getChanged();
    this.iManageDocSettingsEdit = {
      ...this.iManageDocSettingsEdit,
      ...changedValues
    };
  }

  onGeneralSettingsChangedHandler(value) {
    this.isGeneralSettingsChanged = value;
  }

  onIManageDocSettingsChangedHandler(value) {
    this.isIManageDocSettingsChanged = value;
  }

  
  handleTestUploadClick() {
    TestUpload().then((resp)  => {
        console.log(resp);
    })
    .catch((err) => {
      console.log(err);
    });
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

      console.log(data);

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
    let message = "";
    const pageErrors = err?.body?.pageErrors || [];
    if (pageErrors.length > 0) {
      message = pageErrors[0]?.message;
    }
    if (!message) {
      message = err.message || err?.body?.message || err;
    }
    this.dispatchEvent(
      new ShowToastEvent({
        title: "Error",
        message: message,
        variant: "error"
      })
    );
  }

  get areGeneralSettingsHasValuesAndSaved() {
    const isChanged = this.isGeneralSettingsChanged;
    let fields;
    if (this.generalSettingsModel.selectFields) {
      fields = this.generalSettingsModel.selectFields(
        () => true,
        (x) => x.value,
        (x) => x.name
      );
    }
    const allFieldsHasValue =
      fields && Object.values(fields).every((x) => x !== undefined);
    return !isChanged && allFieldsHasValue;
  }

  get hideSpinner() {
    return this.generalSettingsModel.fields || this.invalidLicense;
  }
}