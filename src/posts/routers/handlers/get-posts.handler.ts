import type { Request, Response } from "express";
import { mapToPaginatedViewModel } from "../../../core/mappers/map-to-paginated-view-model.util.js";
import type { PaginatedViewModel } from "../../../core/types/paginated-view-model.js";
import { HTTP_STATUSES } from "../../../core/types/http-statuses.js";
import { postsQueryRepository } from "../../repositories/posts.query-repository.js";
import type { PostQueryInput } from "../../types/post-query-input.js";
import type { PostViewModel } from "../../types/post-view-model.js";
import { mapToPostViewModel } from "../mappers/map-to-post-view-model.util.js";

export const getPostsHandler = async (
  req: Request<{}, PaginatedViewModel<PostViewModel>, {}, PostQueryInput>,
  res: Response<PaginatedViewModel<PostViewModel>>,
): Promise<Response<PaginatedViewModel<PostViewModel>>> => {
  const { items, totalCount } = await postsQueryRepository.findMany(req.query);
  const result = mapToPaginatedViewModel(
    items,
    {
      pageNumber: req.query.pageNumber,
      pageSize: req.query.pageSize,
      totalCount,
    },
    mapToPostViewModel,
  );

  return res.status(HTTP_STATUSES.OK).send(result);
};
