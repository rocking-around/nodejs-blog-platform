import { Router, type RequestHandler } from "express";
import { superAdminGuardMiddleware } from "../../auth/middleware/super-admin.guard.middleware.js";
import { bearerAuthMiddleware } from "../../auth/middleware/bearer-auth.middleware.js";
import { createPostCommentHandler } from "../../comments/routers/handlers/create-post-comment.handler.js";
import { getPostCommentsHandler } from "../../comments/routers/handlers/get-post-comments.handler.js";
import { CommentSortField } from "../../comments/types/comment-sort-field.js";
import { commentInputValidationMiddlewares } from "../../comments/validation/comment.input-dto.validation-middlewares.js";
import { inputValidationResultMiddleware } from "../../core/middleware/input-validation-result.middleware.js";
import { paginationAndSortingValidation } from "../../core/middleware/pagination-and-sorting.validation-middlewares.js";
import { sanitizeQueryMiddleware } from "../../core/middleware/sanitize-query.middleware.js";
import { PostSortField } from "../types/post-sort-field.js";
import { postInputValidationMiddlewares } from "../validation/post.input-dto.validation-middlewares.js";
import { createPostHandler } from "./handlers/create-post.handler.js";
import { deletePostHandler } from "./handlers/delete-post.handler.js";
import { getPostHandler } from "./handlers/get-post.handler.js";
import { getPostsHandler } from "./handlers/get-posts.handler.js";
import { updatePostHandler } from "./handlers/update-post.handler.js";

export const postsRouter: Router = Router({});

postsRouter.get(
  "/",
  paginationAndSortingValidation(
    Object.values(PostSortField),
    PostSortField.CreatedAt,
  ),
  inputValidationResultMiddleware,
  sanitizeQueryMiddleware,
  getPostsHandler as unknown as RequestHandler,
);
postsRouter.post(
  "/",
  superAdminGuardMiddleware,
  postInputValidationMiddlewares,
  inputValidationResultMiddleware,
  createPostHandler,
);
postsRouter.get(
  "/:postId/comments",
  paginationAndSortingValidation(
    Object.values(CommentSortField),
    CommentSortField.CreatedAt,
  ),
  inputValidationResultMiddleware,
  sanitizeQueryMiddleware,
  getPostCommentsHandler as unknown as RequestHandler,
);
postsRouter.post(
  "/:postId/comments",
  bearerAuthMiddleware,
  commentInputValidationMiddlewares,
  inputValidationResultMiddleware,
  createPostCommentHandler,
);
postsRouter.get("/:id", getPostHandler);
postsRouter.put(
  "/:id",
  superAdminGuardMiddleware,
  postInputValidationMiddlewares,
  inputValidationResultMiddleware,
  updatePostHandler,
);
postsRouter.delete("/:id", superAdminGuardMiddleware, deletePostHandler);
