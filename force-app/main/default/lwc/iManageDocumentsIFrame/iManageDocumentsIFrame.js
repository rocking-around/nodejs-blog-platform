import { api } from "lwc";
import LightningModal from "lightning/modal";
import { ShowToastEvent } from "lightning/platformShowToastEvent";
import SaveFileFromIManage from "@salesforce/apex/iManageFileWorker.SaveFileFromIManage";
import SaveLinkFromIManage from "@salesforce/apex/iManageFileWorker.SaveLinkFromIManage";
import saveIManageDocumentMetadata from "@salesforce/apex/IManageLinksAndFilesHelper.saveIManageDocumentMetadata";

export default class IManageDocumentsIFrame extends LightningModal {
  @api recordId;
  @api url;
  @api imanageApi;
  @api title;
  @api action;

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
            console.log("unauthorized: ", message.type);
            break;
          case "select":
            // eslint-disable-next-line no-case-declarations
            const objectInfo = message.data.output_data.selected[0];
            if (objectInfo.wstype === "document") {
              //console.log("Download file: ", objectInfo);
              const docInfo = await this.handleDocumentSelected(objectInfo);
              this.close(docInfo);
            }
            break;
          case "cancel":
            this.close();
            break;
          default:
            console.log("Unsupported message type received: ", message.type);
            break;
        }
      }
    );
  }
  // handleOkay() {
  //     this.close('okay');
  // }

  close(result) {
    if (this.unsubscribeIManage) {
      this.unsubscribeIManage();
    }
    return super.close(result);
  }

  async saveDocumentFromIManage(doc) {
    this.disableClose = true;
    let data = null;
    try {
      this.saving = true;
      const { id, name, extension } = doc;
      data = {
        recordId: this.recordId,
        docId: id,
        docName: name,
        docExtension: extension
      };
      const contentDocId = await SaveFileFromIManage(data);
      await this.saveDocumentMetadata(contentDocId, doc);
      //   await new Promise((resolve) => {
      //     setTimeout(resolve, 5000);
      //   });
    } catch (error) {
      this.dispatchEvent(
        new ShowToastEvent({
          title: "Error loading iManageApi",
          message: error.message,
          variant: "error"
        })
      );
    } finally {
      this.saving = false;
      this.disableClose = false;
    }
    return data;
  }

  async saveLinkFromIManage(doc) {
    this.disableClose = true;
    let data = null;
    this.saving = true;
    try {
      const { id, version } = doc;
      data = {
        recordId: this.recordId,
        docId: id,
        version: version
      };
      const linkId = await SaveLinkFromIManage(data);
      await this.saveDocumentMetadata(linkId, doc);
      //   await new Promise((resolve) => {
      //     setTimeout(resolve, 5000);
      //   });
    } catch (error) {
      this.dispatchEvent(
        new ShowToastEvent({
          title: "Error loading iManageApi",
          message: error.message,
          variant: "error"
        })
      );
    } finally {
      this.saving = false;
      this.disableClose = false;
    }
    this.disableClose = false;
    return data;
  }

  async saveDocumentMetadata(entityId, doc) {
    const {
      author,
      name,
      document_number,
      version,
      class: document_class
    } = doc;
    await saveIManageDocumentMetadata({
      entityId,
      metadata: {
        author,
        name,
        document_number,
        document_class,
        version
      }
    });
  }

  async handleDocumentSelected(doc) {
    switch (this.action) {
      case "save-document":
        return this.saveDocumentFromIManage(doc);
      case "save-link":
        return this.saveLinkFromIManage(doc);
      default:
        throw new Error(`Unknown action = "${this.action}"`);
    }
  }
}
