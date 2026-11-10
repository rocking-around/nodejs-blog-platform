import type { PaginationAndSorting } from "../../core/types/pagination-and-sorting.js";
import type { CommentSortField } from "./comment-sort-field.js";

export type CommentQueryInput = PaginationAndSorting<CommentSortField>;
