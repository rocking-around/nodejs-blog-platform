import { Router } from "express";
import { inputValidationResultMiddleware } from "../../core/middleware/input-validation-result.middleware.js";
import { loginInputValidationMiddlewares } from "../validation/login.input-dto.validation-middlewares.js";
import { loginHandler } from "./handlers/login.handler.js";

export const authRouter: Router = Router({});

authRouter.post(
  "/login",
  loginInputValidationMiddlewares,
  inputValidationResultMiddleware,
  loginHandler,
);
