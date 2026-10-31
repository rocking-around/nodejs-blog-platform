import { query } from "express-validator";
import { SortDirection } from "../types/sort-direction.js";

const DEFAULT_PAGE_NUMBER = 1;
const DEFAULT_PAGE_SIZE = 10;

export const paginationAndSortingValidation = <TSortBy extends string>(
  sortFields: readonly TSortBy[],
  defaultSortBy: TSortBy,
) => [
  query("pageNumber")
    .default(DEFAULT_PAGE_NUMBER)
    .isInt({ min: 1 })
    .withMessage("pageNumber must be a positive integer")
    .toInt(),
  query("pageSize")
    .default(DEFAULT_PAGE_SIZE)
    .isInt({ min: 1, max: 100 })
    .withMessage("pageSize must be between 1 and 100")
    .toInt(),
  query("sortBy")
    .default(defaultSortBy)
    .isIn(sortFields)
    .withMessage(`sortBy must be one of: ${sortFields.join(", ")}`),
  query("sortDirection")
    .default(SortDirection.Desc)
    .isIn(Object.values(SortDirection))
    .withMessage("sortDirection must be asc or desc"),
];
