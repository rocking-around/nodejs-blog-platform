import type { Request, Response } from "express";
import { HTTP_STATUSES } from "../../../core/types/http-statuses.js";
import { authService } from "../../application/auth.service.js";
import type { LoginInputDto } from "../../dto/login.input.dto.js";
import type { LoginSuccessViewModel } from "../../types/login-success-view-model.js";

export const loginHandler = async (
  req: Request<{}, LoginSuccessViewModel | void, LoginInputDto>,
  res: Response<LoginSuccessViewModel | void>,
): Promise<Response<LoginSuccessViewModel | void>> => {
  const accessToken = await authService.login(req.body);

  if (!accessToken) {
    return res.sendStatus(HTTP_STATUSES.UNAUTHORIZED);
  }

  return res.status(HTTP_STATUSES.OK).send({ accessToken });
};
