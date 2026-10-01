import type { Blog } from "./blog.js";

export type BlogViewModel = Blog & {
  id: string;
};
