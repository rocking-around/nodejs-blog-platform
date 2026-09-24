import type { NextFunction, Request, Response } from "express";

const SUPER_ADMIN_CREDENTIALS = "admin:qwerty";

export const superAdminGuardMiddleware = (
  req: Request,
  res: Response,
  next: NextFunction,
) => {
  const authorization = req.headers.authorization;

  if (!authorization?.startsWith("Basic ")) {
    return res.sendStatus(401);
  }

  const encodedCredentials = authorization.slice("Basic ".length);
  const credentials = Buffer.from(encodedCredentials, "base64").toString("utf8");

  if (credentials !== SUPER_ADMIN_CREDENTIALS) {
    return res.sendStatus(401);
  }

  next();
};
