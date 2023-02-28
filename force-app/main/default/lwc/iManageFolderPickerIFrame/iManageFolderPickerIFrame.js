import { api } from "lwc";
import LightningModal from "lightning/modal";
import saveIManageDefaultFolderId from "@salesforce/apex/ConfigurationHelper.saveIManageDefaultFolderId";

export default class IManageFolderPickerIFrame extends LightningModal {
  @api url;
  @api imanageApi;
  @api title;
  @api savedCallback;

  iManageApiInitialized = false;
  unsubscribeIManage = undefined;
  saving = false;

  connectedCallback() {
    if (this.imanageApi) {
      this.initializeIManageApi();
    }
  }

  initializeIManageApi() {
    this.unsubscribeIManage = this.imanageApi.dialogs.handler(
      async (message) => {
        // process messages; examine message.type and use message.data
        switch (message.type) {
          case "unauthorized":
            console.log("unauthorized: ", message.data);
            this.handleErrors(message.type);
            break;
          case "select":
            // eslint-disable-next-line no-case-declarations
            const objectInfo = message.data.output_data.selected[0];
            if (objectInfo.wstype === "folder") {
              //console.log("Download file: ", objectInfo);
              await this.handleFolderSelected(objectInfo);
              this.close(objectInfo);
            }
            break;
          case "cancel":
            this.close();
            break;
          default:
            console.log("Unsupported message type received: ", message.type);
            this.handleErrors(
              `Unsupported message type received: ${message.type}`
            );
            break;
        }
      }
    );
  }

  close(result) {
    if (this.unsubscribeIManage) {
      this.unsubscribeIManage();
    }
    return super.close(result);
  }

  async handleFolderSelected({ id }) {
    // const selectEvent = new CustomEvent("select", {
    //   detail: { id, name }
    // });

    //this.dispatchEvent(new CustomEvent('select', { detail: { id, name  }}));

    try {
      this.showSpinner = true;
      this.saving = true;
      await saveIManageDefaultFolderId({
        folderId: id
      });

      if (this.savedCallback) {
        this.savedCallback();
      }
    } catch (error) {
      this.handleErrors(error);
    } finally {
      this.showSpinner = false;
      this.saving = false;
    }
  }

  handleErrors(err) {
    console.error(err);
    // if (this.errorCallback) {
    //     this.errorCallback(err);
    // }
  }
}
