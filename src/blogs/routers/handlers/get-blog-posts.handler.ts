import type { Request, Response } from "express";
import { mapToPaginatedViewModel } from "../../../core/mappers/map-to-paginated-view-model.util.js";
import { HTTP_STATUSES } from "../../../core/types/http-statuses.js";
import type { PaginatedViewModel } from "../../../core/types/paginated-view-model.js";
import { blogsQueryRepository } from "../../repositories/blogs.query-repository.js";
import { postsQueryRepository } from "../../../posts/repositories/posts.query-repository.js";
import type { PostQueryInput } from "../../../posts/types/post-query-input.js";
import type { PostViewModel } from "../../../posts/types/post-view-model.js";
import { mapToPostViewModel } from "../../../posts/routers/mappers/map-to-post-view-model.util.js";

export const getBlogPostsHandler = async (
  req: Request<
    { blogId: string },
    PaginatedViewModel<PostViewModel> | void,
    {},
    PostQueryInput
  >,
  res: Response<PaginatedViewModel<PostViewModel> | void>,
): Promise<Response<PaginatedViewModel<PostViewModel> | void>> => {
  const blog = await blogsQueryRepository.findById(req.params.blogId);

  if (!blog) {
    return res.sendStatus(HTTP_STATUSES.NOT_FOUND);
  }

  const { items, totalCount } = await postsQueryRepository.findMany(
    req.query,
    req.params.blogId,
  );
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
