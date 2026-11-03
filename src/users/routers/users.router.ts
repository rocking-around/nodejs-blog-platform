import { Router, type RequestHandler } from "express";
import { superAdminGuardMiddleware } from "../../auth/middleware/super-admin.guard.middleware.js";
import { inputValidationResultMiddleware } from "../../core/middleware/input-validation-result.middleware.js";
import { paginationAndSortingValidation } from "../../core/middleware/pagination-and-sorting.validation-middlewares.js";
import { sanitizeQueryMiddleware } from "../../core/middleware/sanitize-query.middleware.js";
import { UserSortField } from "../types/user-sort-field.js";
import {
  userInputValidationMiddlewares,
  userSearchValidationMiddlewares,
} from "../validation/user.input-dto.validation-middlewares.js";
import { createUserHandler } from "./handlers/create-user.handler.js";
import { deleteUserHandler } from "./handlers/delete-user.handler.js";
import { getUsersHandler } from "./handlers/get-users.handler.js";

export const usersRouter: Router = Router({});

usersRouter.use(superAdminGuardMiddleware);

usersRouter.get(
  "/",
  paginationAndSortingValidation(
    Object.values(UserSortField),
    UserSortField.CreatedAt,
  ),
  userSearchValidationMiddlewares,
  inputValidationResultMiddleware,
  sanitizeQueryMiddleware,
  getUsersHandler as unknown as RequestHandler,
);
usersRouter.post(
  "/",
  userInputValidationMiddlewares,
  inputValidationResultMiddleware,
  createUserHandler,
);
usersRouter.delete("/:id", deleteUserHandler);
