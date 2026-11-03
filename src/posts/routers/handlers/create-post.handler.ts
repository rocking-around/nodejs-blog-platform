import type { Request, Response } from "express";
import { HTTP_STATUSES } from "../../../core/types/http-statuses.js";
import { postsService } from "../../application/posts.service.js";
import type { PostInputDto } from "../../dto/post.input.dto.js";
import { postsQueryRepository } from "../../repositories/posts.query-repository.js";
import type { PostViewModel } from "../../types/post-view-model.js";

export const createPostHandler = async (
  req: Request<{}, PostViewModel, PostInputDto>,
  res: Response<PostViewModel>,
): Promise<Response<PostViewModel>> => {
  const postId = await postsService.create(req.body);

  if (!postId) {
    throw new Error("Validated blog was not found");
  }

  const createdPost = await postsQueryRepository.findById(postId);

  if (!createdPost) {
    throw new Error("Created post was not found by the query repository");
  }

  return res.status(HTTP_STATUSES.CREATED).send(createdPost);
};
