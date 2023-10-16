import { LightningElement, api } from 'lwc';
import { ShowToastEvent } from "lightning/platformShowToastEvent";
import getIManageDataFromSObject from "@salesforce/apex/IManageMappingHelper.getIManageDataFromSObject";
import createWorkspace from "@salesforce/apex/iManageWorkspacesHelper.createWorkspace";
import getIManageWSDefaultFolderTemplateId from "@salesforce/apex/ConfigurationHelper.getIManageWSDefaultFolderTemplateId";

export default class IManageCreateWsContainer extends LightningElement {
  @api recordId;
  loading = true;

  clientId = undefined;
  matterId = undefined;
  wsFolderTemplate = undefined;

  error = {}; //code, message

  async connectedCallback() {
    // check option automatic sync to iManage

    // check if clientId and matterId are not empty

    await this.loadData();
    this.loading = false;
  }

  async loadData() {
    const { clientId, matterId } = await getIManageDataFromSObject({
      entityId: this.recordId
    });
    this.clientId = clientId;
    this.matterId = matterId;

    this.wsFolderTemplate = await getIManageWSDefaultFolderTemplateId();
  }

  async handleCreateWsClick() {
    const ts = new Date().toISOString().split(".")[0].replace(/[^\d]/gi, "");
    const wsName = `${this.clientId} - ${this.matterId} _${ts}`;

    const data = {
      custom1: this.clientId, // client alias
      custom2: this.matterId, // matter alias
      wsName,
      workspaceTemplate: this.wsFolderTemplate // "libraryId::templateId"
    };

    console.log('**** handleCreateWsClick: ', data)
    if (!this.validate(data)) {
      return;
    }

    try {
      this.loading = true;

      await createWorkspace(data);

      this.dispatchEvent(
        new ShowToastEvent({
          title: "Create WS...",
          message: "iManage Workspace created successfuly",
          variant: "success"
        })
      );

      await this.loadData();
    } catch (error) {
      this.handleErrors(error);
    } finally {
      this.loading = false;
    }
  }

  get createWsBtnDisabled() {
    return this.loading;
  }

  validate(data) {
    let errors = [];
    if (!data.custom1) {
      errors.push("Client is empty");
    }
    if (!data.custom2) {
      errors.push("Matter is empty");
    }
    if (!data.workspaceTemplate) {
      errors.push("Workspace template is empty");
    }

    const isValid = errors.length === 0;

    if (!isValid) {
      this.dispatchEvent(
        new ShowToastEvent({
          title: "Error",
          message: errors.join("\n"),
          variant: "error"
        })
      );
    }

    return isValid;
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