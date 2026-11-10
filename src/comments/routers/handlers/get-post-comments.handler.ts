import type { Request, Response } from "express";
import type { PaginatedViewModel } from "../../../core/types/paginated-view-model.js";
import { HTTP_STATUSES } from "../../../core/types/http-statuses.js";
import { postsRepository } from "../../../posts/repositories/posts.repository.js";
import { commentsQueryRepository } from "../../repositories/comments.query-repository.js";
import type { CommentQueryInput } from "../../types/comment-query-input.js";
import type { CommentViewModel } from "../../types/comment-view-model.js";

export const getPostCommentsHandler = async (
  req: Request<
    { postId: string },
    PaginatedViewModel<CommentViewModel> | void,
    {},
    CommentQueryInput
  >,
  res: Response<PaginatedViewModel<CommentViewModel> | void>,
): Promise<Response<PaginatedViewModel<CommentViewModel> | void>> => {
  if (!(await postsRepository.findById(req.params.postId))) {
    return res.sendStatus(HTTP_STATUSES.NOT_FOUND);
  }

  const comments = await commentsQueryRepository.findManyByPostId(
    req.params.postId,
    req.query,
  );

  return res.status(HTTP_STATUSES.OK).send(comments);
};
