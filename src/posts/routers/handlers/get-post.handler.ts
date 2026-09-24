import type { Request, Response } from "express";
import { HTTP_STATUSES } from "../../../core/types/http-statuses.js";
import { postsRepository } from "../../repositories/posts.repository.js";
import type { Post } from "../../types/post.js";

export const getPostHandler = (
  req: Request<{ id: string }>,
  res: Response<Post | void>,
) => {
  const post = postsRepository.findById(req.params.id);

  if (!post) {
    return res.sendStatus(HTTP_STATUSES.NOT_FOUND);
  }

  return res.status(HTTP_STATUSES.OK).send(post);
};
