import { Router } from "express";
import { bearerAuthMiddleware } from "../../auth/middleware/bearer-auth.middleware.js";
import { inputValidationResultMiddleware } from "../../core/middleware/input-validation-result.middleware.js";
import { commentInputValidationMiddlewares } from "../validation/comment.input-dto.validation-middlewares.js";
import { deleteCommentHandler } from "./handlers/delete-comment.handler.js";
import { getCommentHandler } from "./handlers/get-comment.handler.js";
import { updateCommentHandler } from "./handlers/update-comment.handler.js";

export const commentsRouter: Router = Router({});

commentsRouter.get("/:id", getCommentHandler);
commentsRouter.put(
  "/:commentId",
  bearerAuthMiddleware,
  commentInputValidationMiddlewares,
  inputValidationResultMiddleware,
  updateCommentHandler,
);
commentsRouter.delete(
  "/:commentId",
  bearerAuthMiddleware,
  deleteCommentHandler,
);
