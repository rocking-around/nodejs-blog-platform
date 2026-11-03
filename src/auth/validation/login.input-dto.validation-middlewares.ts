import { body } from "express-validator";

export const loginInputValidationMiddlewares = [
  body("loginOrEmail")
    .isString()
    .withMessage("loginOrEmail must be a string")
    .bail()
    .trim()
    .notEmpty()
    .withMessage("loginOrEmail is required"),
  body("password")
    .isString()
    .withMessage("password must be a string")
    .bail()
    .notEmpty()
    .withMessage("password is required"),
];
