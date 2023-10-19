import { LightningElement, api } from "lwc";
import { ShowToastEvent } from "lightning/platformShowToastEvent";
import getIManageWorkspaceSettings from "@salesforce/apex/ConfigurationHelper.getIManageWorkspaceSettings";
import iManageCreateWsModal from "c/iManageCreateWsModal";
export default class IManageCreateWsContainer extends LightningElement {
  @api recordId;
  loading = true;

  wsSettings = undefined;

  error = {}; //code, message

  async connectedCallback() {
    // check option automatic sync to iManage

    // check if ws already exists

    await this.loadData();
    this.loading = false;
  }

  async loadData() {
    this.wsSettings = await getIManageWorkspaceSettings();
    this.wsFolderTemplate = this.wsSettings["iManageWs:Folder_Template_Id"];
  }

  async handleCreateWsClick() {
    const result = await iManageCreateWsModal.open({
      size: "large",
      recordId: this.recordId,
      createdCallback: () => this.loadData(),
      ifErrorCallback: (err) => this.handleErrors(err)
    });

    if (result) {
      this.dispatchEvent(
        new ShowToastEvent({
          title: "Create Workspace...",
          message: `The Workspace "${result.name}" created successfuly`,
          variant: "success"
        })
      );
    }
  }

  get createWsBtnDisabled() {
    return this.loading;
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

  get createWsEnabled() {
    return (
      this.wsSettings &&
      this.wsSettings["iManageWs:Create_Ws_Enabled"] &&
      !this.wsSettings["iManageWs:Auto_Create"]
    );
  }
}
