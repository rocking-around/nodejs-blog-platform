import type { Request, Response } from "express";
import { HTTP_STATUSES } from "../../../core/types/http-statuses.js";
import { postsRepository } from "../../repositories/posts.repository.js";
import type { PostViewModel } from "../../types/post-view-model.js";
import { mapToPostViewModel } from "../mappers/map-to-post-view-model.util.js";

export const getPostHandler = async (
  req: Request<{ id: string }>,
  res: Response<PostViewModel | void>,
): Promise<Response<PostViewModel | void>> => {
  const post = await postsRepository.findById(req.params.id);

  if (!post) {
    return res.sendStatus(HTTP_STATUSES.NOT_FOUND);
  }

  return res.status(HTTP_STATUSES.OK).send(mapToPostViewModel(post));
};
