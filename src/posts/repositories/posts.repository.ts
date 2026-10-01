import { ObjectId, type WithId } from "mongodb";
import { postsCollection } from "../../db/collections.js";
import type { PostInputDto } from "../dto/post.input.dto.js";
import type { Post } from "../types/post.js";

export const postsRepository = {
  async findAll(): Promise<WithId<Post>[]> {
    return postsCollection.find({}).toArray();
  },

  async findById(id: string): Promise<WithId<Post> | null> {
    if (!ObjectId.isValid(id)) {
      return null;
    }

    return postsCollection.findOne({ _id: new ObjectId(id) });
  },

  async create(post: Post): Promise<WithId<Post>> {
    const result = await postsCollection.insertOne(post);
    return { ...post, _id: result.insertedId };
  },

  async update(
    id: string,
    input: PostInputDto,
    blogName: string,
  ): Promise<boolean> {
    if (!ObjectId.isValid(id)) {
      return false;
    }

    const result = await postsCollection.updateOne(
      { _id: new ObjectId(id) },
      {
        $set: {
          title: input.title,
          shortDescription: input.shortDescription,
          content: input.content,
          blogId: input.blogId,
          blogName,
        },
      },
    );

    return result.matchedCount === 1;
  },

  async delete(id: string): Promise<boolean> {
    if (!ObjectId.isValid(id)) {
      return false;
    }

    const result = await postsCollection.deleteOne({ _id: new ObjectId(id) });
    return result.deletedCount === 1;
  },
};
