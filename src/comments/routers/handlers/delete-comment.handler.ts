import type { Request, Response } from "express";
import { HTTP_STATUSES } from "../../../core/types/http-statuses.js";
import { commentsService } from "../../application/comments.service.js";

export const deleteCommentHandler = async (
  req: Request<{ commentId: string }>,
  res: Response,
): Promise<Response> => {
  if (!req.userId) {
    return res.sendStatus(HTTP_STATUSES.UNAUTHORIZED);
  }

  const result = await commentsService.delete(
    req.params.commentId,
    req.userId,
  );

  if (result === "notFound") {
    return res.sendStatus(HTTP_STATUSES.NOT_FOUND);
  }

  if (result === "forbidden") {
    return res.sendStatus(HTTP_STATUSES.FORBIDDEN);
  }

  return res.sendStatus(HTTP_STATUSES.NO_CONTENT);
};
