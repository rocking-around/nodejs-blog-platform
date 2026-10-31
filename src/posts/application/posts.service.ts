import type { WithId } from "mongodb";
import { blogsRepository } from "../../blogs/repositories/blogs.repository.js";
import type { PostForBlogInputDto } from "../dto/post-for-blog.input.dto.js";
import type { PostInputDto } from "../dto/post.input.dto.js";
import { postsRepository } from "../repositories/posts.repository.js";
import type { Post } from "../types/post.js";

export const postsService = {
  async create(input: PostInputDto): Promise<WithId<Post> | null> {
    return this.createForBlog(input.blogId, input);
  },

  async createForBlog(
    blogId: string,
    input: PostForBlogInputDto,
  ): Promise<WithId<Post> | null> {
    const blog = await blogsRepository.findById(blogId);

    if (!blog) {
      return null;
    }

    const post: Post = {
      title: input.title,
      shortDescription: input.shortDescription,
      content: input.content,
      blogId,
      blogName: blog.name,
      createdAt: new Date().toISOString(),
    };

    return postsRepository.create(post);
  },

  async update(id: string, input: PostInputDto): Promise<boolean> {
    const blog = await blogsRepository.findById(input.blogId);

    if (!blog) {
      return false;
    }

    return postsRepository.update(id, input, blog.name);
  },

  async delete(id: string): Promise<boolean> {
    return postsRepository.delete(id);
  },
};
