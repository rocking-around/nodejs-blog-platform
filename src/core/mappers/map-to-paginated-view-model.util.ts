import type { PaginatedViewModel } from "../types/paginated-view-model.js";

export const mapToPaginatedViewModel = <TDocument, TViewModel>(
  documents: TDocument[],
  meta: { pageNumber: number; pageSize: number; totalCount: number },
  mapItem: (document: TDocument) => TViewModel,
): PaginatedViewModel<TViewModel> => ({
  pagesCount: Math.ceil(meta.totalCount / meta.pageSize),
  page: meta.pageNumber,
  pageSize: meta.pageSize,
  totalCount: meta.totalCount,
  items: documents.map(mapItem),
});
