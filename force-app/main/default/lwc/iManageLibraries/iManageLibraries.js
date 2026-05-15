import { LightningElement } from "lwc";
import { ShowToastEvent } from "lightning/platformShowToastEvent";

//import iManageApi from "@salesforce/resourceUrl/iManageApi";
import getIManageAvailableLibraries from "@salesforce/apex/ConfigurationHelper.GetIManageAvailableLibraries";
import saveIManageLibraries from "@salesforce/apex/ConfigurationHelper.SaveIManageLibraries";
import getIManageLibraries from "@salesforce/apex/ConfigurationHelper.GetIManageLibraries";

export default class IManageLibraries extends LightningElement {
  saving = false;
  showSpinner = false;
  isChanged = false;

  availableLibraries = undefined;
  libraries = undefined;
  librariesEdit = [];

  async connectedCallback() {
    await this.loadData();
  }

  async loadData() {
    try {
      this.showSpinner = true;
      this.libraries = await getIManageLibraries();
      this.availableLibraries = await getIManageAvailableLibraries();
      this.librariesEdit = this.libraries?.split(";") ?? [];
      this.resetEdit();
    } catch (error) {
      this.handleErrors(error);
    } finally {
      this.showSpinner = false;
    }
  }

  handleChange(e) {
    const { value } = e.detail;

    this.librariesEdit = value;

    if (this.libraries !== this.librariesEdit && !this.isChanged) {
      this.isChanged = true;
    }
    if (this.libraries === this.librariesEdit && this.isChanged) {
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
      await saveIManageLibraries({
        libraries: this.librariesEdit?.join(";") ?? ""
      });

      this.dispatchEvent(
        new ShowToastEvent({
          title: "Save...",
          message: "iManage Libraries saved successfuly",
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
    this.librariesEdit = this.libraries?.split(";") ?? [];
    this.isChanged = false;
  }

  get isSaveBtnDisabled() {
    return this.saving || !this.isChanged;
  }

  get librariesViewValue() {
    return this.isChanged ? this.librariesEdit : this.libraries;
  }

  get librariesAvailableOptions() {
    if (this.availableLibraries === undefined || this.availableLibraries === "")
      return [];
    return this.availableLibraries
      .split(";")
      .map((x) => ({ label: x, value: x }));
  }
}