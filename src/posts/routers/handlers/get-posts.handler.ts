import type { Request, Response } from "express";
import { HTTP_STATUSES } from "../../../core/types/http-statuses.js";
import { postsRepository } from "../../repositories/posts.repository.js";
import type { Post } from "../../types/post.js";

export const getPostsHandler = (_req: Request, res: Response<Post[]>) => {
  return res.status(HTTP_STATUSES.OK).send(postsRepository.findAll());
};
