import type { Request, Response } from "express";
import { HTTP_STATUSES } from "../../../core/types/http-statuses.js";
import { commentsService } from "../../application/comments.service.js";
import type { CommentInputDto } from "../../dto/comment.input.dto.js";

export const updateCommentHandler = async (
  req: Request<{ commentId: string }, void, CommentInputDto>,
  res: Response,
): Promise<Response> => {
  if (!req.userId) {
    return res.sendStatus(HTTP_STATUSES.UNAUTHORIZED);
  }

  const result = await commentsService.update(
    req.params.commentId,
    req.userId,
    req.body,
  );

  if (result === "notFound") {
    return res.sendStatus(HTTP_STATUSES.NOT_FOUND);
  }

  if (result === "forbidden") {
    return res.sendStatus(HTTP_STATUSES.FORBIDDEN);
  }

  return res.sendStatus(HTTP_STATUSES.NO_CONTENT);
};
