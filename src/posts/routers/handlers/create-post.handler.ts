import type { Request, Response } from "express";
import { blogsRepository } from "../../../blogs/repositories/blogs.repository.js";
import { HTTP_STATUSES } from "../../../core/types/http-statuses.js";
import type { PostInputDto } from "../../dto/post.input.dto.js";
import { postsRepository } from "../../repositories/posts.repository.js";
import type { Post } from "../../types/post.js";

export const createPostHandler = (
  req: Request<{}, Post, PostInputDto>,
  res: Response<Post>,
) => {
  const blog = blogsRepository.findById(req.body.blogId)!;
  const post: Post = {
    id: postsRepository.createId(),
    title: req.body.title,
    shortDescription: req.body.shortDescription,
    content: req.body.content,
    blogId: req.body.blogId,
    blogName: blog.name,
  };

  postsRepository.create(post);

  return res.status(HTTP_STATUSES.CREATED).send(post);
};
