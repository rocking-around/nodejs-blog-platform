import type { Request, Response } from "express";
import { HTTP_STATUSES } from "../../../core/types/http-statuses.js";
import { blogsRepository } from "../../repositories/blogs.repository.js";
import type { BlogViewModel } from "../../types/blog-view-model.js";
import { mapToBlogViewModel } from "../mappers/map-to-blog-view-model.util.js";

export const getBlogsHandler = async (
  _req: Request,
  res: Response<BlogViewModel[]>,
): Promise<Response<BlogViewModel[]>> => {
  const blogs = await blogsRepository.findAll();
  return res.status(HTTP_STATUSES.OK).send(blogs.map(mapToBlogViewModel));
};
