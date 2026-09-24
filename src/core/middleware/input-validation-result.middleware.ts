import type { NextFunction, Request, Response } from "express";
import { validationResult } from "express-validator";
import type { APIErrorResult } from "../types/APIErrorResult.js";

export const inputValidationResultMiddleware = (
  req: Request,
  res: Response<APIErrorResult>,
  next: NextFunction,
) => {
  const validationErrors = validationResult(req);

  if (validationErrors.isEmpty()) {
    return next();
  }

  const errorsMessages = validationErrors.array({ onlyFirstError: true }).map((error) => ({
    message: error.msg,
    field: error.type === "field" ? error.path : null,
  }));

  return res.status(400).send({ errorsMessages });
};
