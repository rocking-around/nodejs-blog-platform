export type PaginatedViewModel<TItem> = {
  pagesCount: number;
  page: number;
  pageSize: number;
  totalCount: number;
  items: TItem[];
};
