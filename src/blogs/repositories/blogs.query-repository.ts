import { ObjectId, type Filter, type WithId } from "mongodb";
import { blogsCollection } from "../../db/collections.js";
import type { BlogQueryInput } from "../types/blog-query-input.js";
import type { Blog } from "../types/blog.js";

const escapeRegExp = (value: string): string =>
  value.replace(/[.*+?^${}()|[\]\\]/g, "\\$&");

export const blogsQueryRepository = {
  async findMany(
    query: BlogQueryInput,
  ): Promise<{ items: WithId<Blog>[]; totalCount: number }> {
    const filter: Filter<Blog> = {};

    if (query.searchNameTerm) {
      filter.name = {
        $regex: escapeRegExp(query.searchNameTerm),
        $options: "i",
      };
    }

    const skip = (query.pageNumber - 1) * query.pageSize;
    const [items, totalCount] = await Promise.all([
      blogsCollection
        .find(filter)
        .sort({ [query.sortBy]: query.sortDirection })
        .skip(skip)
        .limit(query.pageSize)
        .toArray(),
      blogsCollection.countDocuments(filter),
    ]);

    return { items, totalCount };
  },

  async findById(id: string): Promise<WithId<Blog> | null> {
    if (!ObjectId.isValid(id)) {
      return null;
    }

    return blogsCollection.findOne({ _id: new ObjectId(id) });
  },
};
