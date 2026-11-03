import type { Request, Response } from "express";
import { blogsService } from "../../application/blogs.service.js";
import { HTTP_STATUSES } from "../../../core/types/http-statuses.js";
import type { BlogInputDto } from "../../dto/blog.input.dto.js";
import { blogsQueryRepository } from "../../repositories/blogs.query-repository.js";
import type { BlogViewModel } from "../../types/blog-view-model.js";

export const createBlogHandler = async (
  req: Request<{}, BlogViewModel, BlogInputDto>,
  res: Response<BlogViewModel>,
): Promise<Response<BlogViewModel>> => {
  const blogId = await blogsService.create(req.body);
  const createdBlog = await blogsQueryRepository.findById(blogId);

  if (!createdBlog) {
    throw new Error("Created blog was not found by the query repository");
  }

  return res.status(HTTP_STATUSES.CREATED).send(createdBlog);
};
