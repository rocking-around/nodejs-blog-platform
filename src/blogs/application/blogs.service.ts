import type { WithId } from "mongodb";
import type { BlogInputDto } from "../dto/blog.input.dto.js";
import { blogsRepository } from "../repositories/blogs.repository.js";
import type { Blog } from "../types/blog.js";

export const blogsService = {
  async create(input: BlogInputDto): Promise<WithId<Blog>> {
    const blog: Blog = {
      name: input.name,
      description: input.description,
      websiteUrl: input.websiteUrl,
      createdAt: new Date().toISOString(),
      isMembership: false,
    };

    return blogsRepository.create(blog);
  },

  async update(id: string, input: BlogInputDto): Promise<boolean> {
    return blogsRepository.update(id, input);
  },

  async delete(id: string): Promise<boolean> {
    return blogsRepository.delete(id);
  },
};
