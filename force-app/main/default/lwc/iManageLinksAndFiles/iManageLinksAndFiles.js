import { LightningElement, api, track } from "lwc";
import { COLUMNS_DEFINITION, ROW_ACTIONS, writeDebug } from "./helpers";
import IManageLinksAndFilesPaging from "./paging";

import { loadScript /*, loadStyle */ } from "lightning/platformResourceLoader";
import { ShowToastEvent } from "lightning/platformShowToastEvent";
import iManageApi from "@salesforce/resourceUrl/iManageApi";

import iManageDocumentsIFrame from "c/iManageDocumentsIFrame";
import GetIFrameFilePicker from "@salesforce/apex/iManageIFrameDialog.GetIFrameFilePicker";
import SaveLinkToSalesforce from "@salesforce/apex/iManageFileWorker.SaveLinkToSalesforce";
import deleteLink from "@salesforce/apex/IManageLinksAndFilesHelper.deleteLink";
import deleteFile from "@salesforce/apex/IManageLinksAndFilesHelper.deleteFile";
import isEnabledForRecord from "@salesforce/apex/IManageLinksAndFilesHelper.isEnabledForRecord";
import deleteIManageDocumentMetadata from "@salesforce/apex/IManageLinksAndFilesHelper.deleteIManageDocumentMetadata";
import changeIManageDocumentMetadataEntity from "@salesforce/apex/IManageLinksAndFilesHelper.changeIManageDocumentMetadataEntity";
import getIManageDocumentSettings from "@salesforce/apex/ConfigurationHelper.getIManageDocumentSettings";

const PAGE_SIZE = 10;

export default class IManageLinksAndFiles extends LightningElement {
  @api cardTitle;
  loading = false;
  saving = false;
  isDebug = true;
  isEnabled = undefined;
  isShowModal = false;
  gridColumns = COLUMNS_DEFINITION;
  viewColumns = COLUMNS_DEFINITION.map((column) => column.fieldName);
  listColumns = COLUMNS_DEFINITION.map((column) => ({
    value: column.fieldName,
    label: column.label
  }));

  recordsCount = undefined;
  hasNextPage = undefined;

  showIManageDocsIframe = false;
  iManageApiInitialized = false;

  allowSaveIManageDocAsCopy = false;
  allowSaveIManageDocAsLink = false;

  @track gridData = [];

  _recordId;
  @api set recordId(value) {
    this._recordId = value;
    this.writeDebug(`IManageLinksAndFiles. Set recordId: ${this._recordId}`);
    this.checkSettings(
      () => this.loadData(),
      () => this.showNotConfiguredMessage()
    );
  }
  get recordId() {
    return this._recordId;
  }

  constructor() {
    super();
    this.writeDebug = writeDebug.bind(this);

    if (localStorage.getItem("imanage_documents_columns")) {
      this.viewColumns = localStorage.getItem("imanage_documents_columns");
      if (this.viewColumns.length > 0)
        this.gridColumns = COLUMNS_DEFINITION.filter(
          (item) =>
            item.type === "action" || this.viewColumns.includes(item.fieldName)
        );
    }
  }

  async connectedCallback() {
    var docSettings = await getIManageDocumentSettings();
    this.allowSaveIManageDocAsCopy =
      docSettings["iManageDocuments:Save_Document"];
    this.allowSaveIManageDocAsLink = docSettings["iManageDocuments:Save_Link"];

    this.gridColumns = [
      ...this.gridColumns,
      ...[
        {
          type: "action",
          typeAttributes: {
            rowActions: (row, cb) => this.getRowActions(row, cb)
          }
        }
      ]
    ];
  }

  getRowActions(row, callback) {
    const rowActions = ROW_ACTIONS.filter(
      (a) =>
        a.name !== "save_to_sf" ||
        (!!row.isInIManage && this.allowSaveIManageDocAsCopy)
    );
    callback(rowActions);
  }

  async renderedCallback() {
    if (this.iManageApiInitialized) {
      return;
    }
    this.overrideCss();

    this.iManageApiInitialized = true;
    try {
      await loadScript(this, iManageApi);
    } catch (error) {
      this.iManageApiInitialized = false;
      this.dispatchEvent(
        new ShowToastEvent({
          title: "Error loading iManageApi",
          message: error.message,
          variant: "error"
        })
      );
    }
  }

  overrideCss() {
    const style = document.createElement("style");
    style.innerText = `.imanage-links-and-docs-dt .slds-scrollable_y[lightning-datatable_table], 
    .imanage-links-and-docs-dt table[lightning-datatable_table] { width: 100% !important;}`;
    this.template
      .querySelector(
        "c-i-manage-links-and-files-datatable.imanage-links-and-docs-dt"
      )
      .appendChild(style);
  }

  async checkSettings(onSuccess, onFail) {
    try {
      this.isEnabled = await isEnabledForRecord({
        recordId: this.recordId
      });
      if (this.isEnabled) {
        onSuccess();
      } else {
        onFail();
      }
    } catch (error) {
      this.handleErrors(error);
    }
  }

  showNotConfiguredMessage() {
    this.dispatchEvent(
      new ShowToastEvent({
        title: "Not Configured",
        message:
          "The module is not configured. Please contact the Administrator.",
        variant: "warning"
      })
    );
  }

  loadData() {
    this.paging = new IManageLinksAndFilesPaging(this.recordId, PAGE_SIZE);

    this.loading = true;
    Promise.all([this.paging.getTotalRecords(), this.paging.loadPage(0)])
      .then(([totalRecords, { data, hasNext }]) => {
        this.recordsCount = totalRecords;

        this.gridData = [...data];
        this.hasNextPage = hasNext;
        this.writeDebug(
          "IManageLinksAndFiles.gridData:",
          JSON.parse(JSON.stringify(this.gridData))
        );
      })
      .catch((err) => this.handleErrors(err))
      .finally(() => {
        this.loading = false;
      });
  }

  get nextButtonDisabled() {
    return !this.hasNextPage || this.loading;
  }

  get nextButtonVisible() {
    return this.hasNextPage;
  }

  onRowClick(e) {
    const { action, row } = e.detail;
    this.writeDebug(
      "IManageLinksAndFiles.onRowClick",
      JSON.parse(JSON.stringify(row)),
      JSON.parse(JSON.stringify(action))
    );

    if (action.name === "save_to_sf") {
      const { id } = row;
      this.saveIManageLinkToSalesforce(id);
    }
    if (action.name === "delete") {
      this.deleteFromSalesforce(row);
    }
  }

  async loadNewDocumentFromIManage() {
    try {
      const url = await GetIFrameFilePicker();

      const result = await iManageDocumentsIFrame.open({
        size: "large",
        title: "Save Document",
        recordId: this.recordId,
        url: url,
        action: "save-document",
        // eslint-disable-next-line no-undef
        imanageApi: imanage
      });

      if (result) {
        for (let doc of result) {
          this.dispatchEvent(
            new ShowToastEvent({
              title: "Save Document...",
              message: `The Document "${doc.docName}.${doc.docExtension}" saved successfuly`,
              variant: "success"
            })
          );
        }
        this.loadData();
      }
    } catch (error) {
      this.handleErrors(error);
    }
  }

  async loadNewLinkFromIManage() {
    try {
      const url = await GetIFrameFilePicker();

      const result = await iManageDocumentsIFrame.open({
        size: "large",
        title: "Save Link",
        recordId: this.recordId,
        url: url,
        action: "save-link",
        // eslint-disable-next-line no-undef
        imanageApi: imanage
      });

      if (result) {
        this.dispatchEvent(
          new ShowToastEvent({
            title: "Save Links...",
            message: `Links saved successfuly`,
            variant: "success"
          })
        );
        this.loadData();
      }
    } catch (error) {
      this.handleErrors(error);
    }
  }

  loadPreviousPage() {
    this.writeDebug("IManageLinksAndFiles.loadPreviousPage: START");
  }

  loadNextPage() {
    this.loading = true;
    this.paging
      .loadNext()
      .then(({ data, hasNext }) => {
        this.gridData = [...this.gridData, ...data];
        this.hasNextPage = hasNext;
        this.writeDebug(
          "IManageLinksAndFiles.gridData:",
          JSON.parse(JSON.stringify(this.gridData))
        );
      })
      .catch((err) => this.handleErrors(err))
      .finally(() => {
        this.loading = false;
      });
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

  async saveIManageLinkToSalesforce(linkId) {
    const action = new Promise((resolve, reject) => {
      SaveLinkToSalesforce({ linkId })
        .then((newLinkId) =>
          changeIManageDocumentMetadataEntity({
            entityId: linkId,
            newEntityId: newLinkId
          })
        )
        .then(() => resolve())
        .catch((err) => reject(err));
    });
    await this.save(action, {
      reloadOnSeccess: true,
      showSpinner: true,
      successMessage: "The Link saved successfully"
    });
  }

  async deleteFromSalesforce(row) {
    const { id, isInIManage: isLink } = row;
    const action = isLink ? deleteLink : deleteFile;
    const deleteWithMetadata = new Promise((resolve, reject) => {
      action({ id })
        .then(() => deleteIManageDocumentMetadata({ entityId: id }))
        .then(() => resolve())
        .catch((err) => reject(err));
    });
    const successMessage = `The ${
      isLink ? "Link" : "File"
    } deleted successfully`;
    await this.save(deleteWithMetadata, {
      reloadOnSeccess: true,
      showSpinner: true,
      successMessage: successMessage
    });
  }

  get disableNewFileFromImanageButton() {
    return this.loading || !this.iManageApiInitialized;
  }

  get isGridDataEmpty() {
    return (this.gridData || []).length === 0;
  }

  get showSpinner() {
    return this.loading || this.saving;
  }

  async save(action, params) {
    const { reloadOnSeccess, showSpinner, successMessage } = params;
    try {
      if (showSpinner) {
        this.saving = true;
      }
      await action;

      this.dispatchEvent(
        new ShowToastEvent({
          title: "Save...",
          message: successMessage,
          variant: "success"
        })
      );

      if (reloadOnSeccess) {
        this.loadData();
      }
    } catch (error) {
      this.handleErrors(error);
    } finally {
      if (showSpinner) {
        this.saving = false;
      }
    }
  }

  showModalBox() {
    this.isShowModal = true;
  }

  hideModalBox() {
    this.isShowModal = false;
  }

  handleManageColumnChange(e) {
    this.viewColumns = e.detail.value;
    localStorage.setItem("imanage_documents_columns", this.viewColumns);
    this.gridColumns = COLUMNS_DEFINITION.filter(
      (item) =>
        item.type === "action" || this.viewColumns.includes(item.fieldName)
    );
  }
}
