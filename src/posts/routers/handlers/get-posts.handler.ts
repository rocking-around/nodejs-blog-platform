import type { Request, Response } from "express";
import type { PaginatedViewModel } from "../../../core/types/paginated-view-model.js";
import { HTTP_STATUSES } from "../../../core/types/http-statuses.js";
import { postsQueryRepository } from "../../repositories/posts.query-repository.js";
import type { PostQueryInput } from "../../types/post-query-input.js";
import type { PostViewModel } from "../../types/post-view-model.js";

export const getPostsHandler = async (
  req: Request<{}, PaginatedViewModel<PostViewModel>, {}, PostQueryInput>,
  res: Response<PaginatedViewModel<PostViewModel>>,
): Promise<Response<PaginatedViewModel<PostViewModel>>> => {
  const result = await postsQueryRepository.findMany(req.query);

  return res.status(HTTP_STATUSES.OK).send(result);
};
