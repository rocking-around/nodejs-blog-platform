import { postsRepository } from "../../posts/repositories/posts.repository.js";
import { usersRepository } from "../../users/repositories/users.repository.js";
import type { CommentInputDto } from "../dto/comment.input.dto.js";
import { commentsRepository } from "../repositories/comments.repository.js";
import type { Comment } from "../types/comment.js";

export type CreateCommentResult =
  | { status: "success"; commentId: string }
  | { status: "postNotFound" }
  | { status: "userNotFound" };

export type MutateCommentResult = "success" | "notFound" | "forbidden";

export const commentsService = {
  async create(
    postId: string,
    userId: string,
    input: CommentInputDto,
  ): Promise<CreateCommentResult> {
    const [post, user] = await Promise.all([
      postsRepository.findById(postId),
      usersRepository.findById(userId),
    ]);

    if (!post) {
      return { status: "postNotFound" };
    }

    if (!user) {
      return { status: "userNotFound" };
    }

    const comment: Comment = {
      content: input.content,
      postId,
      commentatorInfo: {
        userId,
        userLogin: user.login,
      },
      createdAt: new Date().toISOString(),
    };

    return {
      status: "success",
      commentId: await commentsRepository.create(comment),
    };
  },

  async update(
    commentId: string,
    userId: string,
    input: CommentInputDto,
  ): Promise<MutateCommentResult> {
    const comment = await commentsRepository.findById(commentId);

    if (!comment) {
      return "notFound";
    }

    if (comment.commentatorInfo.userId !== userId) {
      return "forbidden";
    }

    return (await commentsRepository.update(commentId, input.content))
      ? "success"
      : "notFound";
  },

  async delete(
    commentId: string,
    userId: string,
  ): Promise<MutateCommentResult> {
    const comment = await commentsRepository.findById(commentId);

    if (!comment) {
      return "notFound";
    }

    if (comment.commentatorInfo.userId !== userId) {
      return "forbidden";
    }

    return (await commentsRepository.delete(commentId))
      ? "success"
      : "notFound";
  },
};
