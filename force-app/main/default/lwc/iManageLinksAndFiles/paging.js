import getLinks from "@salesforce/apex/IManageLinksAndFilesHelper.getLinks";
import getFolderLinks from "@salesforce/apex/IManageLinksAndFilesHelper.getFolderLinks";
import getFiles from "@salesforce/apex/IManageLinksAndFilesHelper.getFiles";
import getMetadata from "@salesforce/apex/IManageLinksAndFilesHelper.getIManageDocumentsMetadata";
import getLinksCount from "@salesforce/apex/IManageLinksAndFilesHelper.getLinksCount";
import getFolderLinksCount from "@salesforce/apex/IManageLinksAndFilesHelper.getFolderLinksCount";
import getFilesCount from "@salesforce/apex/IManageLinksAndFilesHelper.getFilesCount";
import GetIFrameFolderPicker from "@salesforce/apex/iManageIFrameDialog.GetIFrameFolderPicker";
import { mapLinksToGridModel, mapFolderLinksToGridModel, mapFilesToGridModel, buildFilderLinkUrl } from "./helpers";

const DEFAULT_PAGING_SOURCE = {
  getData: new Promise((resolve) => {
    resolve([]);
  }),
  getCount: new Promise((resolve) => {
    resolve(0);
  }),
  map: (x) => x,
  metadataRef: (x) => x?.id
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

const getFolderLinksExt = (data) => {
  return new Promise((resolve) => {
    Promise.all([
      getFolderLinks(data),
      GetIFrameFolderPicker()
    ])
    .then(([folderLinks, imUrl]) => {
      const result = folderLinks.map(x => {
        const url = buildFilderLinkUrl(x, imUrl);
        return {...x, iframeUrl: url};
      });
      resolve(result);
    });
  });
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
          // console.log(results);
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
      map: mapFilesToGridModel,
      metadataRef: (x) => x.ContentDocumentId
    });
    this.addSource({
      getData: getLinks,
      getCount: getLinksCount,
      map: mapLinksToGridModel,
      metadataRef: (x) => x.Id
    });
    this.addSource({
      //getData: getFolderLinks,
      getData: getFolderLinksExt,
      getCount: getFolderLinksCount,
      map: mapFolderLinksToGridModel,
      metadataRef: (x) => x.Id
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
          const entityIds = results.reduce((result, item, idx) => {
            const metadataRefs = item.map((x) =>
              this.sources[idx].metadataRef(x)
            );
            return [...result, ...metadataRefs];
          }, []);
          return getMetadata({ entityIds }).then((metadata) => {
            return { data: results, metadata };
          });
        })
        .then(({ data: docsAndLinks, metadata }) => {
          const data = docsAndLinks.reduce((result, item, idx) => {
            const itemsWithMetadata = item.map((x) => {
              const metadataRef = this.sources[idx].metadataRef(x);
              const xMetadata = metadata.find(
                (r) => r.EntityId__c === metadataRef
              );
              return { ...x, ...{ metadata: xMetadata } };
            });
            const pageItems = this.sources[idx].map(itemsWithMetadata);
            return [...result, ...pageItems];
          }, []);
          this._page = page;

          data.sort(this.sortByLastModifiedDate);

          const hasPrev = this._page !== 0;
          const hasNext = docsAndLinks.some((x) => x.length === this._pageSize);
          const result = new PageResult(this._page, hasPrev, hasNext, data);
          resolve(result);
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
