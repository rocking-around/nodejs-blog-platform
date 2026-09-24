import * as crypto from "node:crypto";
import { db } from "../../db/db.js";
import type { PostInputDto } from "../dto/post.input.dto.js";
import type { Post } from "../types/post.js";

export const postsRepository = {
  createId(): string {
    return crypto.randomUUID();
  },

  findAll(): Post[] {
    return db.posts;
  },

  findById(id: string): Post | undefined {
    return db.posts.find((post) => post.id === id);
  },

  create(post: Post): void {
    db.posts.push(post);
  },

  update(id: string, input: PostInputDto, blogName: string): boolean {
    const post = this.findById(id);

    if (!post) {
      return false;
    }

    post.title = input.title;
    post.shortDescription = input.shortDescription;
    post.content = input.content;
    post.blogId = input.blogId;
    post.blogName = blogName;
    return true;
  },

  delete(id: string): boolean {
    const index = db.posts.findIndex((post) => post.id === id);

    if (index === -1) {
      return false;
    }

    db.posts.splice(index, 1);
    return true;
  },
};
