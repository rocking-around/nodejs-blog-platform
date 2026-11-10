import type { Request, Response } from "express";
import { HTTP_STATUSES } from "../../../core/types/http-statuses.js";
import { commentsService } from "../../application/comments.service.js";
import type { CommentInputDto } from "../../dto/comment.input.dto.js";
import { commentsQueryRepository } from "../../repositories/comments.query-repository.js";
import type { CommentViewModel } from "../../types/comment-view-model.js";

export const createPostCommentHandler = async (
  req: Request<
    { postId: string },
    CommentViewModel | void,
    CommentInputDto
  >,
  res: Response<CommentViewModel | void>,
): Promise<Response<CommentViewModel | void>> => {
  if (!req.userId) {
    return res.sendStatus(HTTP_STATUSES.UNAUTHORIZED);
  }

  const result = await commentsService.create(
    req.params.postId,
    req.userId,
    req.body,
  );

  if (result.status === "postNotFound") {
    return res.sendStatus(HTTP_STATUSES.NOT_FOUND);
  }

  if (result.status === "userNotFound") {
    return res.sendStatus(HTTP_STATUSES.UNAUTHORIZED);
  }

  const comment = await commentsQueryRepository.findById(result.commentId);
  if (!comment) {
    throw new Error("Created comment was not found by the query repository");
  }

  return res.status(HTTP_STATUSES.CREATED).send(comment);
};
