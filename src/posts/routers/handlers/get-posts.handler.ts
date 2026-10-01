import type { Request, Response } from "express";
import { HTTP_STATUSES } from "../../../core/types/http-statuses.js";
import { postsRepository } from "../../repositories/posts.repository.js";
import type { PostViewModel } from "../../types/post-view-model.js";
import { mapToPostViewModel } from "../mappers/map-to-post-view-model.util.js";

export const getPostsHandler = async (
  _req: Request,
  res: Response<PostViewModel[]>,
): Promise<Response<PostViewModel[]>> => {
  const posts = await postsRepository.findAll();
  return res.status(HTTP_STATUSES.OK).send(posts.map(mapToPostViewModel));
};
