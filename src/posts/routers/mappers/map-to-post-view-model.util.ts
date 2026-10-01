import type { WithId } from "mongodb";
import type { Post } from "../../types/post.js";
import type { PostViewModel } from "../../types/post-view-model.js";

export const mapToPostViewModel = (
  post: WithId<Post>,
): PostViewModel => ({
  id: post._id.toString(),
  title: post.title,
  shortDescription: post.shortDescription,
  content: post.content,
  blogId: post.blogId,
  blogName: post.blogName,
  createdAt: post.createdAt,
});
