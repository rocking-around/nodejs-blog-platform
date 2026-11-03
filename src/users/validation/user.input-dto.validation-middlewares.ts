import { body, query } from "express-validator";

const LOGIN_PATTERN = /^[a-zA-Z0-9_-]+$/;
const EMAIL_PATTERN = /^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$/;

export const userInputValidationMiddlewares = [
  body("login")
    .isString()
    .withMessage("login must be a string")
    .bail()
    .trim()
    .isLength({ min: 3, max: 10 })
    .withMessage("login must be between 3 and 10 characters")
    .bail()
    .matches(LOGIN_PATTERN)
    .withMessage("login has invalid characters"),
  body("password")
    .isString()
    .withMessage("password must be a string")
    .bail()
    .isLength({ min: 6, max: 20 })
    .withMessage("password must be between 6 and 20 characters"),
  body("email")
    .isString()
    .withMessage("email must be a string")
    .bail()
    .trim()
    .matches(EMAIL_PATTERN)
    .withMessage("email must be a valid email address"),
];

export const userSearchValidationMiddlewares = [
  query("searchLoginTerm")
    .optional()
    .isString()
    .withMessage("searchLoginTerm must be a string")
    .trim(),
  query("searchEmailTerm")
    .optional()
    .isString()
    .withMessage("searchEmailTerm must be a string")
    .trim(),
];
