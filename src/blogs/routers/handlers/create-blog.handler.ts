import type { Request, Response } from "express";
import { HTTP_STATUSES } from "../../../core/types/http-statuses.js";
import type { BlogInputDto } from "../../dto/blog.input.dto.js";
import { blogsRepository } from "../../repositories/blogs.repository.js";
import type { Blog } from "../../types/blog.js";

export const createBlogHandler = (
  req: Request<{}, Blog, BlogInputDto>,
  res: Response<Blog>,
) => {
  const blog: Blog = {
    id: blogsRepository.createId(),
    name: req.body.name,
    description: req.body.description,
    websiteUrl: req.body.websiteUrl,
  };

  blogsRepository.create(blog);

  return res.status(HTTP_STATUSES.CREATED).send(blog);
};
