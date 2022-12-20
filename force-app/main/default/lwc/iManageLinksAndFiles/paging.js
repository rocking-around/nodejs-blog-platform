import getLinks from "@salesforce/apex/IManageLinksAndFilesHelper.getLinks";
import getFiles from "@salesforce/apex/IManageLinksAndFilesHelper.getFiles";
import getMetadata from "@salesforce/apex/IManageLinksAndFilesHelper.getIManageDocumentsMetadata";
import getLinksCount from "@salesforce/apex/IManageLinksAndFilesHelper.getLinksCount";
import getFilesCount from "@salesforce/apex/IManageLinksAndFilesHelper.getFilesCount";
import { mapLinksToGridModel, mapFilesToGridModel } from "./helpers";

const DEFAULT_PAGING_SOURCE = {
  getData: new Promise((resolve) => {
    resolve([]);
  }),
  getCount: new Promise((resolve) => {
    resolve(0);
  }),
  map: (x) => x
};

class PageResult {
  _hasNext = false;
  _hasPrevious = false;
  _data = [];
  _currentPage = 0;
  constructor(page, hasPrev, hasNext, data) {
    this._currentPage = page;
    this._hasPrevious = hasPrev;
    this._hasNext = hasNext;
    this._data = data;
  }
  get hasNext() {
    return this._hasNext;
  }
  get hasPrevious() {
    return this._hasPrevious;
  }
  get data() {
    return this._data;
  }
  get currentPage() {
    return this._currentPage;
  }
}

export default class IManageLinksAndFilesPaging {
  _pageSize;
  _page = 0;
  _recordId = undefined;
  _totalRecords = undefined;

  sources = [];

  constructor(recordId, pageSize) {
    this._pageSize = pageSize;
    this._recordId = recordId;
    this.initPaging();
  }

  addSource(source) {
    const src = { ...DEFAULT_PAGING_SOURCE, ...source };
    this.sources.push(src);
  }

  getTotalRecords() {
    return new Promise((resolve, reject) => {
      if (this._totalRecords) {
        resolve(this._totalRecords);
      }
      const methods = this.sources.map((x) =>
        x.getCount({ parentId: this._recordId })
      );
      Promise.all(methods)
        .then(([...results]) => {
          console.log(results);
          this._totalRecords = results.reduce((a, b) => a + b, 0);
          resolve(this._totalRecords);
        })
        .catch((err) => reject(err));
    });
  }

  initPaging() {
    this.addSource({
      getData: getFiles,
      getCount: getFilesCount,
      map: mapFilesToGridModel
    });
    this.addSource({
      getData: getLinks,
      getCount: getLinksCount,
      map: mapLinksToGridModel
    });
  }

  loadPage(page) {
    return new Promise((resolve, reject) => {
      const methods = this.sources.map((x) =>
        x.getData({
          parentId: this._recordId,
          size: this._pageSize,
          skip: page * this._pageSize // TODO: smart paging
        })
      );
      Promise.all(methods)
        .then(([...results]) => {
          const data = results.reduce((result, item, idx) => {
            const pageItems = this.sources[idx].map(item);
            return [...result, ...pageItems];
          }, []);
          this._page = page;
          const hasPrev = this._page !== 0;
          const hasNext = results.some((x) => x.length === this._pageSize);
          this.getEntitiesMetadata(data).then(([...resultsWithMetadata]) => {
            resultsWithMetadata.sort(this.sortByLastModifiedDate);
            resolve(new PageResult(this._page, hasPrev, hasNext, data));
          })
          .catch((err) => reject(err));
        })
        .catch((err) => reject(err));
    });
  }

  getEntitiesMetadata(data) {
    return new Promise((resolve, reject) => {
      getMetadata({ entityIds: data.map((x) => x.Id) })
      .then(([...results]) => {
        resolve(data.map((x) => ({...x, ...results.find(r => r.EntityId__c === x.Id)})));
      })
      .catch((err) => reject(err));
    });
  }

  loadNext() {
    return this.loadPage(this._page + 1);
  }

  sortByLastModifiedDate(a, b) {
    const d1 = new Date(a.lastModifiedDate);
    const d2 = new Date(b.lastModifiedDate);
    if (d1 < d2) {
      return -1;
    }
    if (d1 > d2) {
      return 1;
    }

    return 0;
  }
}
