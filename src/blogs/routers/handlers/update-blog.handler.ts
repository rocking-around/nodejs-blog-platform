import type { Request, Response } from "express";
import { blogsService } from "../../application/blogs.service.js";
import { HTTP_STATUSES } from "../../../core/types/http-statuses.js";
import type { BlogInputDto } from "../../dto/blog.input.dto.js";

export const updateBlogHandler = async (
  req: Request<{ id: string }, void, BlogInputDto>,
  res: Response,
): Promise<Response> => {
  const isUpdated = await blogsService.update(req.params.id, req.body);

  if (!isUpdated) {
    return res.sendStatus(HTTP_STATUSES.NOT_FOUND);
  }

  return res.sendStatus(HTTP_STATUSES.NO_CONTENT);
};
