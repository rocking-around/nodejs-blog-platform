import type { Blog } from "../blogs/types/blog.js";
import type { Post } from "../posts/types/post.js";

export const db: { blogs: Blog[]; posts: Post[] } = {
  blogs: [],
  posts: [],
};
