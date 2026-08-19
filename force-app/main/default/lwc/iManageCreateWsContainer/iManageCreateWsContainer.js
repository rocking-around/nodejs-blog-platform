import { LightningElement, api } from "lwc";
import { ShowToastEvent } from "lightning/platformShowToastEvent";
import getIManageWorkspaceSettings from "@salesforce/apex/ConfigurationHelper.getIManageWorkspaceSettings";
import getIManageDataFromSObject from "@salesforce/apex/IManageMappingHelper.getIManageDataFromSObject";
import findEntityWorkspaceInCache from "@salesforce/apex/iManageWorkspacesHelper.findEntityWorkspaceInCache";
import findEntityWorkspaceInImanageAndPutToCache from "@salesforce/apex/iManageWorkspacesHelper.findEntityWorkspaceInImanageAndPutToCache";
import prepareCustomFields from "@salesforce/apex/IManageWsProvisioningService.prepareCustomFields";
import getActiveProvisioning from "@salesforce/apex/IManageWsProvisioningService.getActiveProvisioning";
import startProvisioning from "@salesforce/apex/IManageWsProvisioningService.startProvisioning";
import getProvisioningStatus from "@salesforce/apex/IManageWsProvisioningService.getProvisioningStatus";
import iManageCreateWsModal from "c/iManageCreateWsModal";

const POLLING_INTERVAL_MS = 5000;

export default class IManageCreateWsContainer extends LightningElement {
  @api recordId;
  loading = true;

  wsSettings = undefined;
  isWorkspaceExists = true;
  clientId = undefined;
  matterId = undefined;
  clientName = undefined;
  matterName = undefined;
  wsTemplate = undefined;

  error = {}; //code, message
  pollingTimer;
  pollingCancelled = false;
  pollingResolve;

  async connectedCallback() {
    this.pollingCancelled = false;
    // check option automatic sync to iManage
    await this.loadData();
    this.loading = false;

    // The feature is temporarily disabled.
    // await this.tryAutoCreateWs();
  }

  disconnectedCallback() {
    this.pollingCancelled = true;
    if (this.pollingTimer) {
      clearTimeout(this.pollingTimer);
      this.pollingTimer = undefined;
    }
    if (this.pollingResolve) {
      this.pollingResolve(null);
      this.pollingResolve = undefined;
    }
  }

  async loadData() {
    this.wsSettings = await getIManageWorkspaceSettings();
    this.wsFolderTemplate = this.wsSettings["iManageWs:Folder_Template_Id"];

    // check if ws already exists;
    try {
      this.isWorkspaceExists = await this.isWsExistInIManage();
    } catch (e) {
      console.error(e);
    }
  }

  async isWsExistInIManage() {
    const dataFromCache = await findEntityWorkspaceInCache({
      entityId: this.recordId
    });
    console.log('*** IManageCreateWsContainer::findEntityWorkspaceInCache: ', dataFromCache);
    let result = !!Object.keys(dataFromCache).length;
    if (!result) {
      const activeProvisioningJson = await getActiveProvisioning({
        entityId: this.recordId
      });
      if (activeProvisioningJson) {
        return false;
      }
      const dataFromImanage = await findEntityWorkspaceInImanageAndPutToCache({
        entityId: this.recordId
      });
      console.log('*** IManageCreateWsContainer::findEntityWorkspaceInImanageAndPutToCache: ', dataFromImanage);
      result = !!Object.keys(dataFromImanage).length;
    }
    console.log('*** IManageCreateWsContainer::isWsExistInIManage: ', result);
    return result;
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
    const data = await getIManageDataFromSObject({
      entityId: this.recordId
    });
    this.clientId = data.clientId;
    this.matterId = data.matterId;
    this.clientName = data.clientName;
    this.matterName = data.matterName;
    this.wsTemplate = data.wsTemplate;

    const result = await iManageCreateWsModal.open({
      size: "medium",
      recordId: this.recordId,
      wsSettings: this.wsSettings,
      imData: data,
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
      if (value) {
        wsName = wsName.replaceAll(placeholder, value);
      }
    }
    return wsName;
  }

  async createWs(folderTemplate, autoCreate) {
    await prepareCustomFields({
      entityId: this.recordId,
      libraryId: folderTemplate.split('::', 1)[0]
    });

    const data = {
      custom1: this.clientId, // client alias
      custom2: this.matterId, // matter alias
      wsName: this.wsName,
      workspaceTemplate: folderTemplate // libraryId::templateId
    };
    console.log("**** create ws data: ", data);
    if (!this.validate(data)) {
      return null;
    }
    const [libraryId, templateId] = folderTemplate.split("::", 2);
    const operationId = await startProvisioning({
      requestJson: JSON.stringify({
        entityId: this.recordId,
        workspaceName: this.wsName,
        clientId: this.clientId,
        matterId: this.matterId,
        libraryId,
        templateId,
        autoCreated: autoCreate,
        source: "SF"
      })
    });
    return this.pollProvisioning(operationId);
  }

  pollProvisioning(operationId) {
    return new Promise((resolve, reject) => {
      this.pollingResolve = resolve;
      const poll = async () => {
        if (this.pollingCancelled) {
          return;
        }
        try {
          const operationJson = await getProvisioningStatus({ operationId });
          const operation = JSON.parse(operationJson);
          if (this.pollingCancelled) {
            return;
          }
          if (operation.status === "Completed") {
            this.pollingResolve = undefined;
            resolve({
              id: operation.workspaceId,
              name: operation.workspaceName,
              database: operation.workspaceDatabase
            });
            return;
          }
          if (operation.status === "Failed") {
            this.pollingResolve = undefined;
            reject(
              new Error(operation.lastError || "Workspace provisioning failed.")
            );
            return;
          }
          // eslint-disable-next-line @lwc/lwc/no-async-operation
          this.pollingTimer = setTimeout(poll, POLLING_INTERVAL_MS);
        } catch (error) {
          this.pollingResolve = undefined;
          reject(error);
        }
      };
      poll();
    });
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
