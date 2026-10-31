import type { Request, Response } from "express";
import { HTTP_STATUSES } from "../../../core/types/http-statuses.js";
import { postsService } from "../../application/posts.service.js";
import type { PostInputDto } from "../../dto/post.input.dto.js";

export const updatePostHandler = async (
  req: Request<{ id: string }, void, PostInputDto>,
  res: Response,
): Promise<Response> => {
  const isUpdated = await postsService.update(req.params.id, req.body);

  if (!isUpdated) {
    return res.sendStatus(HTTP_STATUSES.NOT_FOUND);
  }

  return res.sendStatus(HTTP_STATUSES.NO_CONTENT);
};
