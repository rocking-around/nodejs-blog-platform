import { body } from "express-validator";

export const commentInputValidationMiddlewares = [
  body("content")
    .isString()
    .withMessage("content must be a string")
    .bail()
    .trim()
    .isLength({ min: 20, max: 300 })
    .withMessage("content must be between 20 and 300 characters"),
];
