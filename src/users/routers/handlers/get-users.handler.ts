import type { Request, Response } from "express";
import { mapToPaginatedViewModel } from "../../../core/mappers/map-to-paginated-view-model.util.js";
import { HTTP_STATUSES } from "../../../core/types/http-statuses.js";
import type { PaginatedViewModel } from "../../../core/types/paginated-view-model.js";
import { usersQueryRepository } from "../../repositories/users.query-repository.js";
import type { UserQueryInput } from "../../types/user-query-input.js";
import type { UserViewModel } from "../../types/user-view-model.js";
import { mapToUserViewModel } from "../mappers/map-to-user-view-model.util.js";

export const getUsersHandler = async (
  req: Request<{}, PaginatedViewModel<UserViewModel>, {}, UserQueryInput>,
  res: Response<PaginatedViewModel<UserViewModel>>,
): Promise<Response<PaginatedViewModel<UserViewModel>>> => {
  const { items, totalCount } = await usersQueryRepository.findMany(req.query);
  const result = mapToPaginatedViewModel(
    items,
    {
      pageNumber: req.query.pageNumber,
      pageSize: req.query.pageSize,
      totalCount,
    },
    mapToUserViewModel,
  );

  return res.status(HTTP_STATUSES.OK).send(result);
};
