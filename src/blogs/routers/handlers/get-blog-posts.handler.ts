import type { Request, Response } from "express";
import { HTTP_STATUSES } from "../../../core/types/http-statuses.js";
import type { PaginatedViewModel } from "../../../core/types/paginated-view-model.js";
import { blogsQueryRepository } from "../../repositories/blogs.query-repository.js";
import { postsQueryRepository } from "../../../posts/repositories/posts.query-repository.js";
import type { PostQueryInput } from "../../../posts/types/post-query-input.js";
import type { PostViewModel } from "../../../posts/types/post-view-model.js";

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

  const result = await postsQueryRepository.findMany(
    req.query,
    req.params.blogId,
  );

  return res.status(HTTP_STATUSES.OK).send(result);
};
