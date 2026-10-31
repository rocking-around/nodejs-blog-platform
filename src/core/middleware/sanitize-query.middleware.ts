import type { NextFunction, Request, Response } from "express";
import { matchedData } from "express-validator";

export const sanitizeQueryMiddleware = (
  req: Request,
  _res: Response,
  next: NextFunction,
): void => {
  const sanitizedQuery = matchedData(req, {
    locations: ["query"],
    includeOptionals: true,
  });

  Object.defineProperty(req, "query", {
    value: { ...req.query, ...sanitizedQuery },
    configurable: true,
    enumerable: true,
    writable: false,
  });

  next();
};
