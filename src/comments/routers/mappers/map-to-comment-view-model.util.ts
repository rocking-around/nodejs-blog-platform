import type { WithId } from "mongodb";
import type { CommentViewModel } from "../../types/comment-view-model.js";
import type { Comment } from "../../types/comment.js";

export const mapToCommentViewModel = (
  comment: WithId<Comment>,
): CommentViewModel => ({
  id: comment._id.toString(),
  content: comment.content,
  commentatorInfo: comment.commentatorInfo,
  createdAt: comment.createdAt,
});
