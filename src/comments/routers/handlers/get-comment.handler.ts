import type { Request, Response } from "express";
import { HTTP_STATUSES } from "../../../core/types/http-statuses.js";
import { commentsQueryRepository } from "../../repositories/comments.query-repository.js";
import type { CommentViewModel } from "../../types/comment-view-model.js";

export const getCommentHandler = async (
  req: Request<{ id: string }, CommentViewModel | void>,
  res: Response<CommentViewModel | void>,
): Promise<Response<CommentViewModel | void>> => {
  const comment = await commentsQueryRepository.findById(req.params.id);

  if (!comment) {
    return res.sendStatus(HTTP_STATUSES.NOT_FOUND);
  }

  return res.status(HTTP_STATUSES.OK).send(comment);
};
