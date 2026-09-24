import type { Request, Response } from "express";
import { blogsRepository } from "../../../blogs/repositories/blogs.repository.js";
import { HTTP_STATUSES } from "../../../core/types/http-statuses.js";
import type { PostInputDto } from "../../dto/post.input.dto.js";
import { postsRepository } from "../../repositories/posts.repository.js";

export const updatePostHandler = (
  req: Request<{ id: string }, void, PostInputDto>,
  res: Response,
) => {
  const blog = blogsRepository.findById(req.body.blogId)!;
  const isUpdated = postsRepository.update(req.params.id, req.body, blog.name);

  if (!isUpdated) {
    return res.sendStatus(HTTP_STATUSES.NOT_FOUND);
  }

  return res.sendStatus(HTTP_STATUSES.NO_CONTENT);
};
