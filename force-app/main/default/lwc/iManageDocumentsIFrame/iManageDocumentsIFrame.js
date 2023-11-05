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
            const documents = message.data.output_data.selected.filter(
              (objectInfo) => objectInfo.wstype === "document"
            );
            if (documents.length > 0) {
              //console.log("Download file: ", objectInfo);
              const docInfos = await this.handleDocumentSelected(documents);
              this.close(docInfos);
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

  async saveItemsFromIManage(docs, action) {
    const result = [];
    this.disableClose = true;
    this.saving = true;

    for (let doc of docs) {
      try {
        // eslint-disable-next-line no-await-in-loop
        const data = await action(doc);
        result.push(data);
      } catch (error) {
        this.dispatchEvent(
          new ShowToastEvent({
            title: "Error loading iManageApi",
            message: error.message,
            variant: "error"
          })
        );
      }
    }

    this.saving = false;
    this.disableClose = false;

    return result;
  }

  async saveDocumentFromIManage(doc) {
    const { id, name, extension } = doc;
    const data = {
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
    return data;
  }

  async saveLinkFromIManage(doc) {
    const { id, version } = doc;
    const data = {
      recordId: this.recordId,
      docId: id,
      version: version
    };
    const linkId = await SaveLinkFromIManage(data);
    await this.saveDocumentMetadata(linkId, doc);
    //   await new Promise((resolve) => {
    //     setTimeout(resolve, 5000);
    //   });
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

  async handleDocumentSelected(docs) {
    let action;
    switch (this.action) {
      case "save-document":
        action = async (doc) => this.saveDocumentFromIManage(doc);
        break;
      case "save-link":
        action = async (doc) => this.saveLinkFromIManage(doc);
        break;
      default:
        throw new Error(`Unknown action = "${this.action}"`);
    }
    return this.saveItemsFromIManage(docs, action);
  }
}
