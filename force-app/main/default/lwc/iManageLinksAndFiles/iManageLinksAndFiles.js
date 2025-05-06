import { LightningElement, api, track } from "lwc";
import { DOCS_COLUMNS_DEFINITION, FOLDERS_COLUMNS_DEFINITION, ROW_ACTIONS, writeDebug } from "./helpers";
import { IManageLinksAndFilesPaging, IManageFoldersPaging } from "./paging";

import { loadScript /*, loadStyle */ } from "lightning/platformResourceLoader";
import { ShowToastEvent } from "lightning/platformShowToastEvent";
import iManageApi from "@salesforce/resourceUrl/iManageApi";

import iManageDocumentsIFrame from "c/iManageDocumentsIFrame";
import iManageFolderPickerIFrame from "c/iManageFolderPickerIFrame";
import GetIFrameFilePicker from "@salesforce/apex/iManageIFrameDialog.GetIFrameFilePicker";
import GetIFrameFolderPicker from "@salesforce/apex/iManageIFrameDialog.GetIFrameFolderPicker";
import SaveLinkToSalesforce from "@salesforce/apex/iManageFileWorker.SaveLinkToSalesforce";
import deleteLink from "@salesforce/apex/IManageLinksAndFilesHelper.deleteLink";
import deleteFolderLink from "@salesforce/apex/IManageLinksAndFilesHelper.deleteFolderLink";
import deleteFile from "@salesforce/apex/IManageLinksAndFilesHelper.deleteFile";
import isEnabledForRecord from "@salesforce/apex/IManageLinksAndFilesHelper.isEnabledForRecord";
import deleteIManageDocumentMetadata from "@salesforce/apex/IManageLinksAndFilesHelper.deleteIManageDocumentMetadata";
import changeIManageDocumentMetadataEntity from "@salesforce/apex/IManageLinksAndFilesHelper.changeIManageDocumentMetadataEntity";
import getIManageDocumentSettings from "@salesforce/apex/ConfigurationHelper.getIManageDocumentSettings";
import saveFolderLinkFromIManage from "@salesforce/apex/IManageLinksAndFilesHelper.saveFolderLinkFromIManage";
import getFilesAndLinksPaged from "@salesforce/apex/IManageLinksAndFilesHelper.getFilesAndLinksPaged";

const PAGE_SIZE = 10;

export default class IManageLinksAndFiles extends LightningElement {
  @api cardTitle;
  loading = false;
  saving = false;
  isDebug = true;
  isEnabled = undefined;
  isShowModal = false;

  docsGridColumns = undefined;
  docsViewColumns = undefined;
  docsListColumns = undefined;


  foldersGridColumns = FOLDERS_COLUMNS_DEFINITION;
  foldersViewColumns = FOLDERS_COLUMNS_DEFINITION.map((column) => column.fieldName);
  foldersListColumns = FOLDERS_COLUMNS_DEFINITION.map((column) => ({
    value: column.fieldName,
    label: column.label
  }));

  docsRecordsCount = undefined;
  foldersRecordsCount = undefined;
  docsHasNextPage = undefined;
  foldersHasNextPage = undefined;

  showIManageDocsIframe = false;
  iManageApiInitialized = false;

  allowSaveIManageDocAsCopy = false;
  allowSaveIManageDocAsLink = false;
  allowSaveIManageFolderAsLink = false;

  simplifiedMode = false;

  docsCurrentPage = 0;
  docsSortField = "id";
  docsSortDirection = "asc";

  @track docsGridData = [];
  @track foldersGridData = [];

  _recordId;
  @api set recordId(value) {
    this._recordId = value;
    this.writeDebug(`IManageLinksAndFiles. Set recordId: ${this._recordId}`);
    this.checkSettings(
      () => {  },// this.loadData(),
      () => { this.setSimplifiedMode(); }  // this.showNotConfiguredMessage()
    );
  }
  get recordId() {
    return this._recordId;
  }

  constructor() {
    super();

    this.writeDebug = writeDebug.bind(this);

    if (localStorage.getItem("imanage_documents_columns")) {
      this.docsViewColumns = localStorage.getItem("imanage_documents_columns");
      if (this.docsViewColumns.length > 0)
        this.docsGridColumns = DOCS_COLUMNS_DEFINITION.filter(
          (item) =>
            item.type === "action" || this.docsViewColumns.includes(item.fieldName)
        );
    }
  }

  async connectedCallback() {


    console.debug('IManageLinksAndFiles:connectedCallback');

    // var test = await getFilesAndLinksPaged({
    //   parentId: '0064H00001Rd6VTQAZ',
    //   size: 5,
    //   skip: 3,
    //   sortField: 'Document_SubClass__c', 
    //   sorfDirection:'desc'});

    // console.debug(test);

    var docSettings = await getIManageDocumentSettings();

    let classColumn = DOCS_COLUMNS_DEFINITION.find(function (el) {
      return el.fieldName === "metadataDocumentClass";
    });

    if (classColumn)
      classColumn.label = docSettings["iManageDocuments:ClassCaption"];

    let subClassColumn = DOCS_COLUMNS_DEFINITION.find(function (el) {
      return el.fieldName === "metadataDocumentSubClass";
    });

    if (subClassColumn)
      subClassColumn.label = docSettings["iManageDocuments:SubClassCaption"];

    this.docsGridColumns = DOCS_COLUMNS_DEFINITION;
    this.docsViewColumns = DOCS_COLUMNS_DEFINITION.map((column) => column.fieldName);
    this.docsListColumns = DOCS_COLUMNS_DEFINITION.map((column) => ({
      value: column.fieldName,
      label: column.label
    }));


    this.allowSaveIManageDocAsCopy =
      docSettings["iManageDocuments:Save_Document"];
    this.allowSaveIManageDocAsLink = docSettings["iManageDocuments:Save_Link"];
    this.allowSaveIManageFolderAsLink = docSettings["iManageDocuments:Save_Folder_Link"];

    this.docsGridColumns = [
      ...this.docsGridColumns,
      ...[
        {
          type: "action",
          typeAttributes: {
            rowActions: (row, cb) => this.getRowActions(row, cb)
          }
        }
      ]
    ];
    this.foldersGridColumns = [
      ...this.foldersGridColumns,
      ...[
        {
          type: "action",
          typeAttributes: {
            rowActions: (row, cb) => this.getRowActions(row, cb)
          }
        }
      ]
    ];

    if (this.simplifiedMode)
      this.setSimplifiedMode();
  }

  getRowActions(row, callback) {
    const rowActions = ROW_ACTIONS.filter(
      (a) => {
        if (a.name === "save_to_sf") {
          return !!row.isInIManage && this.allowSaveIManageDocAsCopy && !row.isIManageFolder
        }
        return true;
      }
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
    let table = this.template
      .querySelector(
        "c-i-manage-links-and-files-datatable.imanage-links-and-docs-dt"
      );
      if (table)
        table.appendChild(style);
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

  setSimplifiedMode() {
    const colums = ["metadataName", "metadataDocumentNumber", "metadataVersion"];

    this.docsGridColumns =  this.docsGridColumns.filter(
      (item) =>
        item.type === "action" || colums.includes(item.fieldName)
    );

    this.simplifiedMode = true;
    this.allowSaveIManageDocAsCopy = false;
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

  loadDocsData(forSort) {

    this.loading = true;

    let size = forSort ? this.docsGridData.length : PAGE_SIZE;

    Promise.all([getFilesAndLinksPaged({
      parentId: this._recordId,  
      size: size,
      skip: 0,
      sortField: this.getDocsSortField(),
      sortDirection: this.docsSortDirection })])
      .then(([filesAndLinksPaged]) => {
        console.debug("loadDocsData response:");
        console.debug(filesAndLinksPaged);

        this.docsGridData = filesAndLinksPaged.Data;
        this.docsHasNextPage = filesAndLinksPaged.HasNext;
        this.docsRecordsCount = filesAndLinksPaged.Total;
        this.docsCurrentPage = 0;
      })
      .catch((err) => this.handleErrors(err))
      .finally(() => {
        this.loading = false;
      });
  }

  loadFoldersData() {
    this.foldersPaging = new IManageFoldersPaging(this.recordId, PAGE_SIZE);

    this.loading = true;
    Promise.all([this.foldersPaging.getTotalRecords(), this.foldersPaging.loadPage(0)])
      .then(([totalRecords, { data, hasNext }]) => {
        this.foldersRecordsCount = totalRecords;

        this.foldersGridData = [...data];
        this.foldersHasNextPage = hasNext;
        this.writeDebug(
          "IManageLinksAndFiles.foldersGridData:",
          JSON.parse(JSON.stringify(this.foldersGridData))
        );
      })
      .catch((err) => this.handleErrors(err))
      .finally(() => {
        this.loading = false;
      });
  }

  get docsNextButtonDisabled() {
    return !this.docsHasNextPage || this.loading;
  }

  get foldersNextButtonDisabled() {
    return !this.foldersHasNextPage || this.loading;
  }

  get docsNextButtonVisible() {
    return this.docsHasNextPage;
  }

  get foldersNextButtonVisible() {
    return this.foldersHasNextPage;
  }

  onDocsSort(e) {
    this.docsSortField = e.detail.fieldName;
    this.docsSortDirection = e.detail.sortDirection;
    this.loadDocsData(true) 
  }

  getDocsSortField()
  {
    if (this.docsSortField === "fileUrl")
      return "fileUrlLabel"
    return this.docsSortField;
  }

  onDocsRowClick(e) {
    const { action, row } = e.detail;
    this.writeDebug(
      "IManageLinksAndFiles.onDocsRowClick",
      JSON.parse(JSON.stringify(row)),
      JSON.parse(JSON.stringify(action))
    );

    if (action.name === "save_to_sf") {
      const { id } = row;
      this.saveIManageLinkToSalesforce(id);
    }
    if (action.name === "delete") {
      this.deleteDocFromSalesforce(row);
    }
  }

  onFoldersRowClick(e) {
    const { action, row } = e.detail;
    this.writeDebug(
      "IManageLinksAndFiles.onFoldersRowClick",
      JSON.parse(JSON.stringify(row)),
      JSON.parse(JSON.stringify(action))
    );

    if (action.name === "delete") {
      this.deleteFolderFromSalesforce(row);
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
        this.loadDocsData();
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
        this.loadDocsData();
      }
    } catch (error) {
      this.handleErrors(error);
    }
  }

  async loadNewFolderLinkFromIManage() {
    try {
      const url = await GetIFrameFolderPicker();

      const result = await iManageFolderPickerIFrame.open({
        size: "large",
        title: "Save Folder Link",
        url: url,
        action: "save-link",
        // eslint-disable-next-line no-undef
        imanageApi: imanage,
        savedCallback: () => this.loadFoldersData(),
        selectedCallback: (folder) => this.saveIManageFolderLinkToSalesforce(folder)
      });

      if (result) {
        this.loadFoldersData();
      }
    } catch (error) {
      this.handleErrors(error);
    }
  }

  // loadPreviousPage() {
  //   this.writeDebug("IManageLinksAndFiles.loadPreviousPage: START");
  // }

  docsLoadNextPage() {
    this.loading = true;

    Promise.all([getFilesAndLinksPaged({
      parentId: this._recordId,
      size: PAGE_SIZE,
      skip: (this.docsCurrentPage  + 1) * PAGE_SIZE , 
      sortField: this.getDocsSortField(),
      sortDirection: this.docsSortDirection })])
      .then(([filesAndLinksPaged]) => {
        console.debug("docsLoadNextPage response:");
        console.debug(filesAndLinksPaged);

        this.docsGridData = [...this.docsGridData, ...filesAndLinksPaged.Data];
        this.docsHasNextPage = filesAndLinksPaged.HasNext;
        this.docsRecordsCount = filesAndLinksPaged.Total;
        this.docsCurrentPage++;
      })
      .catch((err) => this.handleErrors(err))
      .finally(() => {
        this.loading = false;
      });
  }

  foldersLoadNextPage() {
    this.loading = true;
    this.foldersPaging
      .loadNext()
      .then(({ data, hasNext }) => {
        this.foldersGridData = [...this.foldersGridData, ...data];
        this.foldersHasNextPage = hasNext;
        this.writeDebug(
          "IManageLinksAndFiles.foldersGridData:",
          JSON.parse(JSON.stringify(this.foldersGridData))
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
    await this.save(action, () => this.loadDocsData(), {
      reloadOnSeccess: true,
      showSpinner: true,
      successMessage: "The Link saved successfully"
    });
  }

  async saveIManageFolderLinkToSalesforce(folder) {
    const data = {
      recordId: this.recordId,
      folderData: folder
    };
    const action = new Promise((resolve, reject) => {
      saveFolderLinkFromIManage(data)
        .then((newLinkId) => resolve(newLinkId))
        .catch((err) => reject(err));
    });
    await this.save(action, () => this.loadFoldersData(), {
      reloadOnSeccess: true,
      showSpinner: true,
      successMessage: "Folder link saved successfuly"
    });
  }

  async deleteDocFromSalesforce(row) {
    const { id, isInIManage: isLink } = row;
    const action = isLink
      ? deleteLink
      : deleteFile;
    const deleteWithMetadata = new Promise((resolve, reject) => {
      action({ id })
        .then(() => deleteIManageDocumentMetadata({ entityId: id }))
        .then(() => resolve())
        .catch((err) => reject(err));
    });
    const successMessage = `The ${
      isLink ? "Link" : "File"
    } deleted successfully`;
    await this.save(deleteWithMetadata, () => this.loadDocsData(), {
      reloadOnSeccess: true,
      showSpinner: true,
      successMessage: successMessage
    });
  }

  async deleteFolderFromSalesforce(row) {
    const { id } = row;

    const successMessage = `The Folder link deleted successfully`;
    await this.save(deleteFolderLink({ id }), () => this.loadFoldersData(), {
      reloadOnSeccess: true,
      showSpinner: true,
      successMessage: successMessage
    });
  }

  get disableNewFileFromImanageButton() {
    return this.loading || !this.iManageApiInitialized;
  }

  get isDocsGridDataEmpty() {
    return (this.docsGridData || []).length === 0;
  }

  get isFoldersGridDataEmpty() {
    return (this.foldersGridData || []).length === 0;
  }

  get showSpinner() {
    return this.loading || this.saving;
  }

  async save(action, loadDataAction, params) {
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
        loadDataAction();
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
    this.docsViewColumns = e.detail.value;
    localStorage.setItem("imanage_documents_columns", this.docsViewColumns);
    this.docsGridColumns = DOCS_COLUMNS_DEFINITION.filter(
      (item) =>
        item.type === "action" || this.docsViewColumns.includes(item.fieldName)
    );
  }

  get isDocumentsTabVisible() {
    return this.allowSaveIManageDocAsCopy || this.allowSaveIManageDocAsLink;
  }

  get isFolderTabVisible() {
    return this.allowSaveIManageFolderAsLink && !this.simplifiedMode;
  }

  handleFoldersTabActive() {
    this.loadFoldersData();
  }

  handleDocumentsTabActive() {
    this.loadDocsData();
  }
}
