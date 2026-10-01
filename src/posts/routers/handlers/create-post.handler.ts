import type { Request, Response } from "express";
import { blogsRepository } from "../../../blogs/repositories/blogs.repository.js";
import { HTTP_STATUSES } from "../../../core/types/http-statuses.js";
import type { PostInputDto } from "../../dto/post.input.dto.js";
import { postsRepository } from "../../repositories/posts.repository.js";
import { mapToPostViewModel } from "../mappers/map-to-post-view-model.util.js";
import type { Post } from "../../types/post.js";
import type { PostViewModel } from "../../types/post-view-model.js";

export const createPostHandler = async (
  req: Request<{}, PostViewModel, PostInputDto>,
  res: Response<PostViewModel>,
): Promise<Response<PostViewModel>> => {
  const blog = await blogsRepository.findById(req.body.blogId);

  if (!blog) {
    throw new Error("Validated blog was not found");
  }

  const post: Post = {
    title: req.body.title,
    shortDescription: req.body.shortDescription,
    content: req.body.content,
    blogId: req.body.blogId,
    blogName: blog.name,
    createdAt: new Date().toISOString(),
  };

  const createdPost = await postsRepository.create(post);

  return res
    .status(HTTP_STATUSES.CREATED)
    .send(mapToPostViewModel(createdPost));
};
