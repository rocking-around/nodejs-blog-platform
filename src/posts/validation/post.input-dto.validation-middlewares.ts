import { body } from "express-validator";
import { blogsRepository } from "../../blogs/repositories/blogs.repository.js";

export const postInputValidationMiddlewares = [
  body("title")
    .isString()
    .withMessage("title must be a string")
    .bail()
    .trim()
    .notEmpty()
    .withMessage("title is required")
    .bail()
    .isLength({ max: 30 })
    .withMessage("title must not exceed 30 characters"),
  body("shortDescription")
    .isString()
    .withMessage("shortDescription must be a string")
    .bail()
    .trim()
    .notEmpty()
    .withMessage("shortDescription is required")
    .bail()
    .isLength({ max: 100 })
    .withMessage("shortDescription must not exceed 100 characters"),
  body("content")
    .isString()
    .withMessage("content must be a string")
    .bail()
    .trim()
    .notEmpty()
    .withMessage("content is required")
    .bail()
    .isLength({ max: 1000 })
    .withMessage("content must not exceed 1000 characters"),
  body("blogId")
    .isString()
    .withMessage("blogId must be a string")
    .bail()
    .trim()
    .notEmpty()
    .withMessage("blogId is required")
    .bail()
    .custom(async (blogId: string) => {
      if (!(await blogsRepository.findById(blogId))) {
        throw new Error("blog with the specified blogId does not exist");
      }

      return true;
    }),
];
