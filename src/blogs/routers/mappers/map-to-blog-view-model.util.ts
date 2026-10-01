import type { WithId } from "mongodb";
import type { Blog } from "../../types/blog.js";
import type { BlogViewModel } from "../../types/blog-view-model.js";

export const mapToBlogViewModel = (
  blog: WithId<Blog>,
): BlogViewModel => ({
  id: blog._id.toString(),
  name: blog.name,
  description: blog.description,
  websiteUrl: blog.websiteUrl,
  createdAt: blog.createdAt,
  isMembership: blog.isMembership,
});
