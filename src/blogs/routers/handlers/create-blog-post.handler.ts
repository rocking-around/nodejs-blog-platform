import type { Request, Response } from "express";
import { HTTP_STATUSES } from "../../../core/types/http-statuses.js";
import { postsService } from "../../../posts/application/posts.service.js";
import type { PostForBlogInputDto } from "../../../posts/dto/post-for-blog.input.dto.js";
import { postsQueryRepository } from "../../../posts/repositories/posts.query-repository.js";
import type { PostViewModel } from "../../../posts/types/post-view-model.js";

export const createBlogPostHandler = async (
  req: Request<{ blogId: string }, PostViewModel | void, PostForBlogInputDto>,
  res: Response<PostViewModel | void>,
): Promise<Response<PostViewModel | void>> => {
  const postId = await postsService.createForBlog(
    req.params.blogId,
    req.body,
  );

  if (!postId) {
    return res.sendStatus(HTTP_STATUSES.NOT_FOUND);
  }

  const createdPost = await postsQueryRepository.findById(postId);

  if (!createdPost) {
    throw new Error("Created post was not found by the query repository");
  }

  return res.status(HTTP_STATUSES.CREATED).send(createdPost);
};
