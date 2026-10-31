import type { SortDirection } from "./sort-direction.js";

export type PaginationAndSorting<TSortBy extends string> = {
  pageNumber: number;
  pageSize: number;
  sortBy: TSortBy;
  sortDirection: SortDirection;
};
