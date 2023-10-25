import { LightningElement, api } from "lwc";
import { ShowToastEvent } from "lightning/platformShowToastEvent";
import getIManageWorkspaceSettings from "@salesforce/apex/ConfigurationHelper.getIManageWorkspaceSettings";
import getIManageDataFromSObject from "@salesforce/apex/IManageMappingHelper.getIManageDataFromSObject";
import isEntityWorkspaceAlreadyCreated from "@salesforce/apex/iManageWorkspacesHelper.isEntityWorkspaceAlreadyCreated";
import createWorkspace from "@salesforce/apex/iManageWorkspacesHelper.createWorkspace";
import updateEntityToWsMapping from "@salesforce/apex/iManageWorkspacesHelper.updateEntityToWsMapping";
import iManageCreateWsModal from "c/iManageCreateWsModal";
export default class IManageCreateWsContainer extends LightningElement {
  @api recordId;
  loading = true;

  wsSettings = undefined;
  isWorkspaceExists = true;
  clientId = undefined;
  matterId = undefined;
  clientName = undefined;
  matterName = undefined;

  error = {}; //code, message

  async connectedCallback() {
    // check option automatic sync to iManage
    await this.loadData();
    this.loading = false;

    // The feature is temporarily disabled.
    // await this.tryAutoCreateWs();
  }

  async loadData() {
    this.wsSettings = await getIManageWorkspaceSettings();
    this.wsFolderTemplate = this.wsSettings["iManageWs:Folder_Template_Id"];

    const { clientId, matterId, clientName, matterName } =
      await getIManageDataFromSObject({
        entityId: this.recordId
      });
    this.clientId = clientId;
    this.matterId = matterId;
    this.clientName = clientName;
    this.matterName = matterName;

    // check if ws already exists
    // const wsName = this.wsName;
    // this.isWorkspaceExists = await isWorkspaceWithNameExists({
    //   name: wsName
    // });
    this.isWorkspaceExists = await isEntityWorkspaceAlreadyCreated({
      entityId: this.recordId
    });
  }

  // The feature is temporarily disabled.
  // async tryAutoCreateWs() {
  //   const folderTemplate = (
  //     this.wsSettings
  //       ? this.wsSettings["iManageWs:Folder_Template_Id"] || ""
  //       : ""
  //   ).trim();
  //   if (this.createWsEnabled && this.autoCreateWsEnabled && folderTemplate.length > 0) {
  //     try {
  //       await this.createWs(folderTemplate, true);
  //     } catch (error) {
  //       console.error('Auto-creation iManage Workspace ERROR: ', error);
  //     }
  //   }
  // }

  async handleCreateWsClick() {
    const result = await iManageCreateWsModal.open({
      size: "large",
      recordId: this.recordId,
      wsSettings: this.wsSettings,
      newWsName: this.wsName,
      createWs: (ft) => this.createWs(ft, false),
      createdCallback: () => this.loadData(),
      ifErrorCallback: (err) => this.handleErrors(err)
    });

    if (result) {
      this.dispatchEvent(
        new ShowToastEvent({
          title: "Create Workspace...",
          message: `The Workspace "${result.name}" (#${result.id}) created successfuly`,
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
      this.wsSettings["iManageWs:Create_Ws_Enabled"]
    );
  }

  get autoCreateWsEnabled() {
    return (
      this.wsSettings &&
      this.wsSettings["iManageWs:Auto_Create"]
    );
  }

  get isVisible() {
    return this.createWsEnabled && !this.isWorkspaceExists && !this.autoCreateWsEnabled;
  }

  get wsName() {
    if (!this.wsSettings) {
      return undefined;
    }
    let wsName = (this.wsSettings["iManageWs:Name_Pattern"] || "").trim();

    if (!wsName.length) {
      return undefined;
    }

    const wsNamePlaceholders = {
      "{CLIENTCODE}": this.clientId,
      "{MATTERCODE}": this.matterId,
      "{CLIENTNAME}": this.clientName,
      "{MATTERNAME}": this.matterName
    };
    //const ts = new Date().toISOString().split(".")[0].replace(/[^\d]/gi, "");
    for (const [placeholder, value] of Object.entries(wsNamePlaceholders)) {
      wsName = wsName.replaceAll(placeholder, value);
    }
    return wsName;
  }

  async createWs(folderTemplate, autoCreate) {
    const data = {
      custom1: this.clientId, // client alias
      custom2: this.matterId, // matter alias
      wsName: this.wsName,
      workspaceTemplate: folderTemplate // "libraryId::te
    };
    console.log("**** create ws data: ", data);
    if (!this.validate(data)) {
      return null;
    }
    const ws = await createWorkspace(data);

    await this.tryUpdateEntityToWsMapping(ws, autoCreate);

    return {
      id: ws.id,
      name: ws.name,
      database: ws.database
    };
  }

  async tryUpdateEntityToWsMapping(ws, autoCreate) {
    try {
      await updateEntityToWsMapping({
        entityId: this.recordId,
        workspaceId: ws.id,
        libraryId: ws.database,
        autoCreated: autoCreate,
        source: 'SF'
      });
    } catch (error) {
      this.handleErrors(error);
    }
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
      this.handleErrors(errors.join("\n"));
    }
    return isValid;
  }
}
