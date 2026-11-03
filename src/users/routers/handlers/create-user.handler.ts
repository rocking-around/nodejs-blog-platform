import type { Request, Response } from "express";
import type { APIErrorResult } from "../../../core/types/APIErrorResult.js";
import { HTTP_STATUSES } from "../../../core/types/http-statuses.js";
import { usersService } from "../../application/users.service.js";
import type { UserInputDto } from "../../dto/user.input.dto.js";
import type { UserViewModel } from "../../types/user-view-model.js";
import { mapToUserViewModel } from "../mappers/map-to-user-view-model.util.js";

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

  return res
    .status(HTTP_STATUSES.CREATED)
    .send(mapToUserViewModel(result.user));
};
