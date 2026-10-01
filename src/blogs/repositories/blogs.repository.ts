import { ObjectId, type WithId } from "mongodb";
import { blogsCollection } from "../../db/collections.js";
import type { BlogInputDto } from "../dto/blog.input.dto.js";
import type { Blog } from "../types/blog.js";

export const blogsRepository = {
  async findAll(): Promise<WithId<Blog>[]> {
    return blogsCollection.find({}).toArray();
  },

  async findById(id: string): Promise<WithId<Blog> | null> {
    if (!ObjectId.isValid(id)) {
      return null;
    }

    return blogsCollection.findOne({ _id: new ObjectId(id) });
  },

  async create(blog: Blog): Promise<WithId<Blog>> {
    const result = await blogsCollection.insertOne(blog);
    return { ...blog, _id: result.insertedId };
  },

  async update(id: string, input: BlogInputDto): Promise<boolean> {
    if (!ObjectId.isValid(id)) {
      return false;
    }

    const result = await blogsCollection.updateOne(
      { _id: new ObjectId(id) },
      {
        $set: {
          name: input.name,
          description: input.description,
          websiteUrl: input.websiteUrl,
        },
      },
    );

    return result.matchedCount === 1;
  },

  async delete(id: string): Promise<boolean> {
    if (!ObjectId.isValid(id)) {
      return false;
    }

    const result = await blogsCollection.deleteOne({ _id: new ObjectId(id) });
    return result.deletedCount === 1;
  },
};
