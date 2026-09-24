import { Router } from "express";
import { superAdminGuardMiddleware } from "../../auth/middleware/super-admin.guard.middleware.js";
import { inputValidationResultMiddleware } from "../../core/middleware/input-validation-result.middleware.js";
import { postInputValidationMiddlewares } from "../validation/post.input-dto.validation-middlewares.js";
import { createPostHandler } from "./handlers/create-post.handler.js";
import { deletePostHandler } from "./handlers/delete-post.handler.js";
import { getPostHandler } from "./handlers/get-post.handler.js";
import { getPostsHandler } from "./handlers/get-posts.handler.js";
import { updatePostHandler } from "./handlers/update-post.handler.js";

export const postsRouter: Router = Router({});

postsRouter.get("/", getPostsHandler);
postsRouter.post(
  "/",
  superAdminGuardMiddleware,
  postInputValidationMiddlewares,
  inputValidationResultMiddleware,
  createPostHandler,
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
