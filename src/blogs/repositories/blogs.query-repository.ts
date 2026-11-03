import { ObjectId, type Filter } from "mongodb";
import { mapToPaginatedViewModel } from "../../core/mappers/map-to-paginated-view-model.util.js";
import type { PaginatedViewModel } from "../../core/types/paginated-view-model.js";
import { blogsCollection } from "../../db/collections.js";
import { mapToBlogViewModel } from "../routers/mappers/map-to-blog-view-model.util.js";
import type { BlogQueryInput } from "../types/blog-query-input.js";
import type { BlogViewModel } from "../types/blog-view-model.js";
import type { Blog } from "../types/blog.js";

const escapeRegExp = (value: string): string =>
  value.replace(/[.*+?^${}()|[\]\\]/g, "\\$&");

export const blogsQueryRepository = {
  async findMany(
    query: BlogQueryInput,
  ): Promise<PaginatedViewModel<BlogViewModel>> {
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

    return mapToPaginatedViewModel(
      items,
      {
        pageNumber: query.pageNumber,
        pageSize: query.pageSize,
        totalCount,
      },
      mapToBlogViewModel,
    );
  },

  async findById(id: string): Promise<BlogViewModel | null> {
    if (!ObjectId.isValid(id)) {
      return null;
    }

    const blog = await blogsCollection.findOne({ _id: new ObjectId(id) });
    return blog ? mapToBlogViewModel(blog) : null;
  },
};
