import type { Request, Response } from "express";
import { HTTP_STATUSES } from "../../../core/types/http-statuses.js";
import { blogsRepository } from "../../repositories/blogs.repository.js";
import type { BlogViewModel } from "../../types/blog-view-model.js";
import { mapToBlogViewModel } from "../mappers/map-to-blog-view-model.util.js";

export const getBlogHandler = async (
  req: Request<{ id: string }>,
  res: Response<BlogViewModel | void>,
): Promise<Response<BlogViewModel | void>> => {
  const blog = await blogsRepository.findById(req.params.id);

  if (!blog) {
    return res.sendStatus(HTTP_STATUSES.NOT_FOUND);
  }

  return res.status(HTTP_STATUSES.OK).send(mapToBlogViewModel(blog));
};
