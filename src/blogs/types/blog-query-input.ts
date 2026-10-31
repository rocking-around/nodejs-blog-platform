import type { PaginationAndSorting } from "../../core/types/pagination-and-sorting.js";
import type { BlogSortField } from "./blog-sort-field.js";

export type BlogQueryInput = PaginationAndSorting<BlogSortField> & {
  searchNameTerm?: string;
};
