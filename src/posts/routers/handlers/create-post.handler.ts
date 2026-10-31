import type { Request, Response } from "express";
import { HTTP_STATUSES } from "../../../core/types/http-statuses.js";
import { postsService } from "../../application/posts.service.js";
import type { PostInputDto } from "../../dto/post.input.dto.js";
import { mapToPostViewModel } from "../mappers/map-to-post-view-model.util.js";
import type { PostViewModel } from "../../types/post-view-model.js";

export const createPostHandler = async (
  req: Request<{}, PostViewModel, PostInputDto>,
  res: Response<PostViewModel>,
): Promise<Response<PostViewModel>> => {
  const createdPost = await postsService.create(req.body);

  if (!createdPost) {
    throw new Error("Validated blog was not found");
  }

  return res
    .status(HTTP_STATUSES.CREATED)
    .send(mapToPostViewModel(createdPost));
};
