import type { Request, Response } from "express";
import { HTTP_STATUSES } from "../../../core/types/http-statuses.js";
import type { BlogInputDto } from "../../dto/blog.input.dto.js";
import { blogsRepository } from "../../repositories/blogs.repository.js";

export const updateBlogHandler = (
  req: Request<{ id: string }, void, BlogInputDto>,
  res: Response,
) => {
  const isUpdated = blogsRepository.update(req.params.id, req.body);

  if (!isUpdated) {
    return res.sendStatus(HTTP_STATUSES.NOT_FOUND);
  }

  return res.sendStatus(HTTP_STATUSES.NO_CONTENT);
};
