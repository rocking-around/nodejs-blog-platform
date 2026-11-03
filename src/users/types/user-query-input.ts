import type { PaginationAndSorting } from "../../core/types/pagination-and-sorting.js";
import type { UserSortField } from "./user-sort-field.js";

export type UserQueryInput = PaginationAndSorting<UserSortField> & {
  searchLoginTerm?: string;
  searchEmailTerm?: string;
};
