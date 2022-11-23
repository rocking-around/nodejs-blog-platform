import { LightningElement, api, track } from "lwc";
import { COLUMNS_DEFINITION, writeDebug } from "./helpers";
import IManageLinksAndFilesPaging from "./paging";

import { loadScript /*, loadStyle */ } from "lightning/platformResourceLoader";
import { ShowToastEvent } from "lightning/platformShowToastEvent";
import iManageApi from "@salesforce/resourceUrl/iManageApi";

import iManageDocumentsIFrame from "c/iManageDocumentsIFrame";
import GetIFrameFilePicker from "@salesforce/apex/iManageIFrameDialog.GetIFrameFilePicker";

const PAGE_SIZE = 10;

export default class IManageLinksAndFiles extends LightningElement {
  loading = false;
  isDebug = true;
  gridColumns = COLUMNS_DEFINITION;

  recordsCount = undefined;
  hasNextPage = undefined;

  showIManageDocsIframe = false;
  iManageApiInitialized = false;

  @track gridData = [];

  _recordId;
  @api set recordId(value) {
    this._recordId = value;
    this.writeDebug(`IManageLinksAndFiles. Set recordId: ${this._recordId}`);
    this.loadData();
  }
  get recordId() {
    return this._recordId;
  }

  constructor() {
    super();
    this.writeDebug = writeDebug.bind(this);
  }

  async connectedCallback() {
    //setTimeout (()=> {this.loading = false}, 5000);
  }

  async renderedCallback() {
    if (this.iManageApiInitialized) {
      return;
    }
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

  loadData() {
    this.paging = new IManageLinksAndFilesPaging(this.recordId, PAGE_SIZE);

    this.loading = true;
    Promise.all([this.paging.getTotalRecords(), this.paging.loadPage(0)])
      //Promise.all([Promise.resolve(0), Promise.resolve({data:[], hasNext: false})])
      .then(([totalRecords, { data, hasNext }]) => {
        this.recordsCount = totalRecords;

        this.gridData = [...data];
        this.hasNextPage = hasNext;
        this.writeDebug(
          "IManageLinksAndFiles.gridData:",
          JSON.parse(JSON.stringify(this.gridData))
        );
      })
      .catch(this.handleErrors)
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
  }

  async loadNewDocumentFromIManage() {
    try {
      const { Data: url } = await GetIFrameFilePicker();

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
        this.dispatchEvent(
          new ShowToastEvent({
            title: "Save Document...",
            message: `The Document "${result.docName}.${result.docExtension}" saved successfuly`,
            variant: "success"
          })
        );
        this.loadData();
      }
    } catch (error) {
      this.handleErrors(error);
    }
  }

  async loadNewLinkFromIManage() {
    try {
      const { Data: url } = await GetIFrameFilePicker();

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
            title: "Save Link...",
            message: `Link saved successfuly`,
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
      .catch(this.handleErrors)
      .finally(() => {
        this.loading = false;
      });
  }

  handleErrors(err) {
    console.error(err);
    this.dispatchEvent(
      new ShowToastEvent({
        title: "Error",
        message: err.message,
        variant: "error"
      })
    );
  }

  get disableNewFileFromImanageButton() {
    return this.loading || !this.iManageApiInitialized;
  }

  get isGridDataEmpty() {
    return (this.gridData || []).length === 0;
  }
}
