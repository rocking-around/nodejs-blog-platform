import { Router, type RequestHandler } from "express";
import { superAdminGuardMiddleware } from "../../auth/middleware/super-admin.guard.middleware.js";
import { inputValidationResultMiddleware } from "../../core/middleware/input-validation-result.middleware.js";
import { paginationAndSortingValidation } from "../../core/middleware/pagination-and-sorting.validation-middlewares.js";
import { sanitizeQueryMiddleware } from "../../core/middleware/sanitize-query.middleware.js";
import { postForBlogInputValidationMiddlewares } from "../../posts/validation/post.input-dto.validation-middlewares.js";
import { PostSortField } from "../../posts/types/post-sort-field.js";
import { BlogSortField } from "../types/blog-sort-field.js";
import {
  blogInputValidationMiddlewares,
  blogSearchNameTermValidationMiddleware,
} from "../validation/blog.input-dto.validation-middlewares.js";
import { createBlogPostHandler } from "./handlers/create-blog-post.handler.js";
import { createBlogHandler } from "./handlers/create-blog.handler.js";
import { deleteBlogHandler } from "./handlers/delete-blog.handler.js";
import { getBlogHandler } from "./handlers/get-blog.handler.js";
import { getBlogPostsHandler } from "./handlers/get-blog-posts.handler.js";
import { getBlogsHandler } from "./handlers/get-blogs.handler.js";
import { updateBlogHandler } from "./handlers/update-blog.handler.js";

export const blogsRouter: Router = Router({});

blogsRouter.get(
  "/",
  paginationAndSortingValidation(
    Object.values(BlogSortField),
    BlogSortField.CreatedAt,
  ),
  blogSearchNameTermValidationMiddleware,
  inputValidationResultMiddleware,
  sanitizeQueryMiddleware,
  getBlogsHandler as unknown as RequestHandler,
);
blogsRouter.post(
  "/",
  superAdminGuardMiddleware,
  blogInputValidationMiddlewares,
  inputValidationResultMiddleware,
  createBlogHandler,
);
blogsRouter.get(
  "/:blogId/posts",
  paginationAndSortingValidation(
    Object.values(PostSortField),
    PostSortField.CreatedAt,
  ),
  inputValidationResultMiddleware,
  sanitizeQueryMiddleware,
  getBlogPostsHandler as unknown as RequestHandler,
);
blogsRouter.post(
  "/:blogId/posts",
  superAdminGuardMiddleware,
  postForBlogInputValidationMiddlewares,
  inputValidationResultMiddleware,
  createBlogPostHandler,
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
