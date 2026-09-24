import type { Request, Response } from "express";
import { HTTP_STATUSES } from "../../../core/types/http-statuses.js";
import { blogsRepository } from "../../repositories/blogs.repository.js";
import type { Blog } from "../../types/blog.js";

export const getBlogsHandler = (_req: Request, res: Response<Blog[]>) => {
  return res.status(HTTP_STATUSES.OK).send(blogsRepository.findAll());
};
