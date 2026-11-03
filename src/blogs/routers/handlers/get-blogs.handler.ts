import type { Request, Response } from "express";
import type { PaginatedViewModel } from "../../../core/types/paginated-view-model.js";
import { HTTP_STATUSES } from "../../../core/types/http-statuses.js";
import { blogsQueryRepository } from "../../repositories/blogs.query-repository.js";
import type { BlogQueryInput } from "../../types/blog-query-input.js";
import type { BlogViewModel } from "../../types/blog-view-model.js";

export const getBlogsHandler = async (
  req: Request<{}, PaginatedViewModel<BlogViewModel>, {}, BlogQueryInput>,
  res: Response<PaginatedViewModel<BlogViewModel>>,
): Promise<Response<PaginatedViewModel<BlogViewModel>>> => {
  const result = await blogsQueryRepository.findMany(req.query);

  return res.status(HTTP_STATUSES.OK).send(result);
};
