import * as crypto from "node:crypto";
import { db } from "../../db/db.js";
import type { BlogInputDto } from "../dto/blog.input.dto.js";
import type { Blog } from "../types/blog.js";

export const blogsRepository = {
  createId(): string {
    return crypto.randomUUID();
  },

  findAll(): Blog[] {
    return db.blogs;
  },

  findById(id: string): Blog | undefined {
    return db.blogs.find((blog) => blog.id === id);
  },

  create(blog: Blog): void {
    db.blogs.push(blog);
  },

  update(id: string, input: BlogInputDto): boolean {
    const blog = this.findById(id);

    if (!blog) {
      return false;
    }

    blog.name = input.name;
    blog.description = input.description;
    blog.websiteUrl = input.websiteUrl;
    return true;
  },

  delete(id: string): boolean {
    const index = db.blogs.findIndex((blog) => blog.id === id);

    if (index === -1) {
      return false;
    }

    db.blogs.splice(index, 1);
    return true;
  },
};
