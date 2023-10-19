import { api } from "lwc";
import LightningModal from "lightning/modal";
import loadFolderTemplates from "@salesforce/apex/ConfigurationHelper.loadFolderTemplates";
import getIManageWorkspaceSettings from "@salesforce/apex/ConfigurationHelper.getIManageWorkspaceSettings";
import createWorkspace from "@salesforce/apex/iManageWorkspacesHelper.createWorkspace";
import getIManageDataFromSObject from "@salesforce/apex/IManageMappingHelper.getIManageDataFromSObject";

export default class IManageCreateWsModal extends LightningModal {
  @api recordId;
  @api createdCallback;
  // MAGIC: if param name = 'errorCallback' -> error in SF
  @api ifErrorCallback;

  loading = true;
  saving = false;

  wsSettings = undefined;
  folderTemplateOptions = undefined;
  folderTemplate = undefined;
  clientId = undefined;
  matterId = undefined;
  clientName = undefined;
  matterName = undefined;

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

      const { clientId, matterId, clientName, matterName } =
        await getIManageDataFromSObject({
          entityId: this.recordId
        });
      this.clientId = clientId;
      this.matterId = matterId;
      this.clientName = clientName;
      this.matterName = matterName;
    } catch (error) {
      this.handleErrors(error);
    } finally {
      this.loading = false;
    }
  }

  async loadWsSettings() {
    this.wsSettings = await getIManageWorkspaceSettings();
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

      const result = await this.createWs();
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

  async createWs() {
    const data = {
      custom1: this.clientId, // client alias
      custom2: this.matterId, // matter alias
      wsName: this.wsName,
      workspaceTemplate: this.folderTemplate // "libraryId::templateId"
    };

    console.log("**** create ws data: ", data);
    if (!this.validate(data)) {
      return null;
    }

    await createWorkspace(data);

    return {
      id: undefined, // TODO: find ws by id and return data
      name: this.wsName
    };
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

  get isCreateBtnDisabled() {
    return false;
  }

  get showSpinner() {
    return this.loading || this.saving;
  }

  get wsName() {
    if (!this.wsSettings) {
        return undefined;
    }
    let wsName = (this.wsSettings["iManageWs:Name_Pattern"] || '').trim();

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
}

