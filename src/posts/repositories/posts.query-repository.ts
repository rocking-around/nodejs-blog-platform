import { ObjectId, type Filter, type WithId } from "mongodb";
import { postsCollection } from "../../db/collections.js";
import type { PostQueryInput } from "../types/post-query-input.js";
import type { Post } from "../types/post.js";

export const postsQueryRepository = {
  async findMany(
    query: PostQueryInput,
    blogId?: string,
  ): Promise<{ items: WithId<Post>[]; totalCount: number }> {
    const filter: Filter<Post> = blogId ? { blogId } : {};
    const skip = (query.pageNumber - 1) * query.pageSize;
    const [items, totalCount] = await Promise.all([
      postsCollection
        .find(filter)
        .sort({ [query.sortBy]: query.sortDirection })
        .skip(skip)
        .limit(query.pageSize)
        .toArray(),
      postsCollection.countDocuments(filter),
    ]);

    return { items, totalCount };
  },

  async findById(id: string): Promise<WithId<Post> | null> {
    if (!ObjectId.isValid(id)) {
      return null;
    }

    return postsCollection.findOne({ _id: new ObjectId(id) });
  },
};
