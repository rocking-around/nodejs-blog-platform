import type { PaginationAndSorting } from "../../core/types/pagination-and-sorting.js";
import type { PostSortField } from "./post-sort-field.js";

export type PostQueryInput = PaginationAndSorting<PostSortField>;
