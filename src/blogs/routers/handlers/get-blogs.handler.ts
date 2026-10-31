import type { Request, Response } from "express";
import { mapToPaginatedViewModel } from "../../../core/mappers/map-to-paginated-view-model.util.js";
import type { PaginatedViewModel } from "../../../core/types/paginated-view-model.js";
import { HTTP_STATUSES } from "../../../core/types/http-statuses.js";
import { blogsQueryRepository } from "../../repositories/blogs.query-repository.js";
import type { BlogQueryInput } from "../../types/blog-query-input.js";
import type { BlogViewModel } from "../../types/blog-view-model.js";
import { mapToBlogViewModel } from "../mappers/map-to-blog-view-model.util.js";

export const getBlogsHandler = async (
  req: Request<{}, PaginatedViewModel<BlogViewModel>, {}, BlogQueryInput>,
  res: Response<PaginatedViewModel<BlogViewModel>>,
): Promise<Response<PaginatedViewModel<BlogViewModel>>> => {
  const { items, totalCount } = await blogsQueryRepository.findMany(req.query);
  const result = mapToPaginatedViewModel(
    items,
    {
      pageNumber: req.query.pageNumber,
      pageSize: req.query.pageSize,
      totalCount,
    },
    mapToBlogViewModel,
  );

  return res.status(HTTP_STATUSES.OK).send(result);
};
