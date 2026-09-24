import { Router } from "express";
import { superAdminGuardMiddleware } from "../../auth/middleware/super-admin.guard.middleware.js";
import { inputValidationResultMiddleware } from "../../core/middleware/input-validation-result.middleware.js";
import { blogInputValidationMiddlewares } from "../validation/blog.input-dto.validation-middlewares.js";
import { createBlogHandler } from "./handlers/create-blog.handler.js";
import { deleteBlogHandler } from "./handlers/delete-blog.handler.js";
import { getBlogHandler } from "./handlers/get-blog.handler.js";
import { getBlogsHandler } from "./handlers/get-blogs.handler.js";
import { updateBlogHandler } from "./handlers/update-blog.handler.js";

export const blogsRouter: Router = Router({});

blogsRouter.get("/", getBlogsHandler);
blogsRouter.post(
  "/",
  superAdminGuardMiddleware,
  blogInputValidationMiddlewares,
  inputValidationResultMiddleware,
  createBlogHandler,
);
blogsRouter.get("/:id", getBlogHandler);
blogsRouter.put(
  "/:id",
  superAdminGuardMiddleware,
  blogInputValidationMiddlewares,
  inputValidationResultMiddleware,
  updateBlogHandler,
);
blogsRouter.delete("/:id", superAdminGuardMiddleware, deleteBlogHandler);
