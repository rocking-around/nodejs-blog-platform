import type { Request, Response } from "express";
import { blogsService } from "../../application/blogs.service.js";
import { HTTP_STATUSES } from "../../../core/types/http-statuses.js";

export const deleteBlogHandler = async (
  req: Request<{ id: string }>,
  res: Response,
): Promise<Response> => {
  const isDeleted = await blogsService.delete(req.params.id);

  if (!isDeleted) {
    return res.sendStatus(HTTP_STATUSES.NOT_FOUND);
  }

  return res.sendStatus(HTTP_STATUSES.NO_CONTENT);
};
