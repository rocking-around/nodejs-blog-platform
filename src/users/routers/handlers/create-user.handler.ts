import type { Request, Response } from "express";
import type { APIErrorResult } from "../../../core/types/APIErrorResult.js";
import { HTTP_STATUSES } from "../../../core/types/http-statuses.js";
import { usersService } from "../../application/users.service.js";
import type { UserInputDto } from "../../dto/user.input.dto.js";
import { usersQueryRepository } from "../../repositories/users.query-repository.js";
import type { UserViewModel } from "../../types/user-view-model.js";

export const createUserHandler = async (
  req: Request<{}, UserViewModel | APIErrorResult, UserInputDto>,
  res: Response<UserViewModel | APIErrorResult>,
): Promise<Response<UserViewModel | APIErrorResult>> => {
  const result = await usersService.create(req.body);

  if (result.status === "error") {
    return res
      .status(HTTP_STATUSES.BAD_REQUEST)
      .send({ errorsMessages: [result.error] });
  }

  const createdUser = await usersQueryRepository.findById(result.userId);

  if (!createdUser) {
    throw new Error("Created user was not found by the query repository");
  }

  return res.status(HTTP_STATUSES.CREATED).send(createdUser);
};
