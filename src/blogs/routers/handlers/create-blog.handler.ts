import type { Request, Response } from "express";
import { HTTP_STATUSES } from "../../../core/types/http-statuses.js";
import type { BlogInputDto } from "../../dto/blog.input.dto.js";
import { blogsRepository } from "../../repositories/blogs.repository.js";
import { mapToBlogViewModel } from "../mappers/map-to-blog-view-model.util.js";
import type { Blog } from "../../types/blog.js";
import type { BlogViewModel } from "../../types/blog-view-model.js";

export const createBlogHandler = async (
  req: Request<{}, BlogViewModel, BlogInputDto>,
  res: Response<BlogViewModel>,
): Promise<Response<BlogViewModel>> => {
  const blog: Blog = {
    name: req.body.name,
    description: req.body.description,
    websiteUrl: req.body.websiteUrl,
    createdAt: new Date().toISOString(),
    isMembership: false,
  };

  const createdBlog = await blogsRepository.create(blog);

  return res
    .status(HTTP_STATUSES.CREATED)
    .send(mapToBlogViewModel(createdBlog));
};
