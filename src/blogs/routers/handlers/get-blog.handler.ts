import type { Request, Response } from "express";
import { HTTP_STATUSES } from "../../../core/types/http-statuses.js";
import { blogsRepository } from "../../repositories/blogs.repository.js";
import type { Blog } from "../../types/blog.js";

export const getBlogHandler = (
  req: Request<{ id: string }>,
  res: Response<Blog | void>,
) => {
  const blog = blogsRepository.findById(req.params.id);

  if (!blog) {
    return res.sendStatus(HTTP_STATUSES.NOT_FOUND);
  }

  return res.status(HTTP_STATUSES.OK).send(blog);
};
