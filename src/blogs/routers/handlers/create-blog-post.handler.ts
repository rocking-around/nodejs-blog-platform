import type { Request, Response } from "express";
import { HTTP_STATUSES } from "../../../core/types/http-statuses.js";
import { postsService } from "../../../posts/application/posts.service.js";
import type { PostForBlogInputDto } from "../../../posts/dto/post-for-blog.input.dto.js";
import { mapToPostViewModel } from "../../../posts/routers/mappers/map-to-post-view-model.util.js";
import type { PostViewModel } from "../../../posts/types/post-view-model.js";

export const createBlogPostHandler = async (
  req: Request<{ blogId: string }, PostViewModel | void, PostForBlogInputDto>,
  res: Response<PostViewModel | void>,
): Promise<Response<PostViewModel | void>> => {
  const createdPost = await postsService.createForBlog(
    req.params.blogId,
    req.body,
  );

  if (!createdPost) {
    return res.sendStatus(HTTP_STATUSES.NOT_FOUND);
  }

  return res
    .status(HTTP_STATUSES.CREATED)
    .send(mapToPostViewModel(createdPost));
};
