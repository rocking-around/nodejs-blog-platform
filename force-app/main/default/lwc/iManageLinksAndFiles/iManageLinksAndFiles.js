import { LightningElement, api, track } from "lwc";
import { COLUMNS_DEFINITION, writeDebug } from "./helpers";
import IManageLinksAndFilesPaging from "./paging";

const PAGE_SIZE = 10;

export default class IManageLinksAndFiles extends LightningElement {
  loading = false;
  isDebug = true;
  gridColumns = COLUMNS_DEFINITION;

  recordsCount = undefined;
  hasNextPage = undefined;

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
  connectedCallback() {
    //setTimeout (()=> {this.loading = false}, 5000);
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
      .catch(this.handleErrors)
      .finally(() => {
        this.loading = false;
      });
  }

  get nextButtonDisabled() {
    return !this.hasNextPage || this.loading;
  }

  onRowClick(e) {
    const { action, row } = e.detail;
    this.writeDebug(
      "IManageLinksAndFiles.onRowClick",
      JSON.parse(JSON.stringify(row)),
      JSON.parse(JSON.stringify(action))
    );
  }

  loadNewDocumentFromIManage() {
    this.writeDebug("IManageLinksAndFiles.loadNewDocumentFromIManage: START");
  }

  loadNewLinkFromIManage() {
    this.writeDebug("IManageLinksAndFiles.loadNewLinkFromIManage: START");
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
  }
}
