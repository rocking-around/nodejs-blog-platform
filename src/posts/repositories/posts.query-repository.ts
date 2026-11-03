import { ObjectId, type Filter } from "mongodb";
import { mapToPaginatedViewModel } from "../../core/mappers/map-to-paginated-view-model.util.js";
import type { PaginatedViewModel } from "../../core/types/paginated-view-model.js";
import { postsCollection } from "../../db/collections.js";
import { mapToPostViewModel } from "../routers/mappers/map-to-post-view-model.util.js";
import type { PostQueryInput } from "../types/post-query-input.js";
import type { PostViewModel } from "../types/post-view-model.js";
import type { Post } from "../types/post.js";

export const postsQueryRepository = {
  async findMany(
    query: PostQueryInput,
    blogId?: string,
  ): Promise<PaginatedViewModel<PostViewModel>> {
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

    return mapToPaginatedViewModel(
      items,
      {
        pageNumber: query.pageNumber,
        pageSize: query.pageSize,
        totalCount,
      },
      mapToPostViewModel,
    );
  },

  async findById(id: string): Promise<PostViewModel | null> {
    if (!ObjectId.isValid(id)) {
      return null;
    }

    const post = await postsCollection.findOne({ _id: new ObjectId(id) });
    return post ? mapToPostViewModel(post) : null;
  },
};
