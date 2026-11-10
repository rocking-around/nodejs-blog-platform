import type { NextFunction, Request, Response } from "express";
import { HTTP_STATUSES } from "../../core/types/http-statuses.js";
import { usersRepository } from "../../users/repositories/users.repository.js";
import { jwtService } from "../application/jwt.service.js";

export const bearerAuthMiddleware = async (
  req: Request,
  res: Response,
  next: NextFunction,
): Promise<void> => {
  req.userId = null;

  const authorization = req.headers.authorization;
  if (!authorization) {
    res.sendStatus(HTTP_STATUSES.UNAUTHORIZED);
    return;
  }

  const [scheme, token, extra] = authorization.split(" ");
  if (scheme !== "Bearer" || !token || extra) {
    res.sendStatus(HTTP_STATUSES.UNAUTHORIZED);
    return;
  }

  const userId = jwtService.getUserId(token);
  if (!userId || !(await usersRepository.findById(userId))) {
    res.sendStatus(HTTP_STATUSES.UNAUTHORIZED);
    return;
  }

  req.userId = userId;
  next();
};
