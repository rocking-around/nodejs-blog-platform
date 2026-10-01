import type { Request, Response } from "express";
import { blogsRepository } from "../../../blogs/repositories/blogs.repository.js";
import { HTTP_STATUSES } from "../../../core/types/http-statuses.js";
import type { PostInputDto } from "../../dto/post.input.dto.js";
import { postsRepository } from "../../repositories/posts.repository.js";

export const updatePostHandler = async (
  req: Request<{ id: string }, void, PostInputDto>,
  res: Response,
): Promise<Response> => {
  const blog = await blogsRepository.findById(req.body.blogId);

  if (!blog) {
    throw new Error("Validated blog was not found");
  }

  const isUpdated = await postsRepository.update(
    req.params.id,
    req.body,
    blog.name,
  );

  if (!isUpdated) {
    return res.sendStatus(HTTP_STATUSES.NOT_FOUND);
  }

  return res.sendStatus(HTTP_STATUSES.NO_CONTENT);
};
