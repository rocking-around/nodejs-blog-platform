import type { Request, Response } from "express";
import { HTTP_STATUSES } from "../../../core/types/http-statuses.js";
import type { PaginatedViewModel } from "../../../core/types/paginated-view-model.js";
import { usersQueryRepository } from "../../repositories/users.query-repository.js";
import type { UserQueryInput } from "../../types/user-query-input.js";
import type { UserViewModel } from "../../types/user-view-model.js";

export const getUsersHandler = async (
  req: Request<{}, PaginatedViewModel<UserViewModel>, {}, UserQueryInput>,
  res: Response<PaginatedViewModel<UserViewModel>>,
): Promise<Response<PaginatedViewModel<UserViewModel>>> => {
  const result = await usersQueryRepository.findMany(req.query);

  return res.status(HTTP_STATUSES.OK).send(result);
};
