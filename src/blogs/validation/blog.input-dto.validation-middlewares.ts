import { body } from "express-validator";

const WEBSITE_URL_PATTERN =
  /^https:\/\/([a-zA-Z0-9_-]+\.)+[a-zA-Z0-9_-]+(\/[a-zA-Z0-9_-]+)*\/?$/;

export const blogInputValidationMiddlewares = [
  body("name")
    .isString()
    .withMessage("name must be a string")
    .bail()
    .trim()
    .notEmpty()
    .withMessage("name is required")
    .bail()
    .isLength({ max: 15 })
    .withMessage("name must not exceed 15 characters"),
  body("description")
    .isString()
    .withMessage("description must be a string")
    .bail()
    .trim()
    .notEmpty()
    .withMessage("description is required")
    .bail()
    .isLength({ max: 500 })
    .withMessage("description must not exceed 500 characters"),
  body("websiteUrl")
    .isString()
    .withMessage("websiteUrl must be a string")
    .bail()
    .trim()
    .notEmpty()
    .withMessage("websiteUrl is required")
    .bail()
    .isLength({ max: 100 })
    .withMessage("websiteUrl must not exceed 100 characters")
    .bail()
    .matches(WEBSITE_URL_PATTERN)
    .withMessage("websiteUrl must be a valid URL"),
];
