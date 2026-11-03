import type { Request, Response } from "express";
import { HTTP_STATUSES } from "../../../core/types/http-statuses.js";
import { authService } from "../../application/auth.service.js";
import type { LoginInputDto } from "../../dto/login.input.dto.js";

export const loginHandler = async (
  req: Request<{}, void, LoginInputDto>,
  res: Response,
): Promise<Response> => {
  const isAuthenticated = await authService.checkCredentials(req.body);

  if (!isAuthenticated) {
    return res.sendStatus(HTTP_STATUSES.UNAUTHORIZED);
  }

  return res.sendStatus(HTTP_STATUSES.NO_CONTENT);
};
