import type { FieldError } from "./FieldError.js";

export type APIErrorResult = {
  errorsMessages: FieldError[] | null;
};
