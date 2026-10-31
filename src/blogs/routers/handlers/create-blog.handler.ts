import type { Request, Response } from "express";
import { blogsService } from "../../application/blogs.service.js";
import { HTTP_STATUSES } from "../../../core/types/http-statuses.js";
import type { BlogInputDto } from "../../dto/blog.input.dto.js";
import { mapToBlogViewModel } from "../mappers/map-to-blog-view-model.util.js";
import type { BlogViewModel } from "../../types/blog-view-model.js";

export const createBlogHandler = async (
  req: Request<{}, BlogViewModel, BlogInputDto>,
  res: Response<BlogViewModel>,
): Promise<Response<BlogViewModel>> => {
  const createdBlog = await blogsService.create(req.body);

  return res
    .status(HTTP_STATUSES.CREATED)
    .send(mapToBlogViewModel(createdBlog));
};
