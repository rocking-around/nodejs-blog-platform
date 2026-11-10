import type { Request, Response } from "express";
import { HTTP_STATUSES } from "../../../core/types/http-statuses.js";
import { usersQueryRepository } from "../../../users/repositories/users.query-repository.js";
import type { MeViewModel } from "../../types/me-view-model.js";

export const meHandler = async (
  req: Request,
  res: Response<MeViewModel | void>,
): Promise<Response<MeViewModel | void>> => {
  const user = req.userId
    ? await usersQueryRepository.findById(req.userId)
    : null;

  if (!user) {
    return res.sendStatus(HTTP_STATUSES.UNAUTHORIZED);
  }

  return res.status(HTTP_STATUSES.OK).send({
    email: user.email,
    login: user.login,
    userId: user.id,
  });
};
