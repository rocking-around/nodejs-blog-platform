import { ObjectId } from "mongodb";
import { mapToPaginatedViewModel } from "../../core/mappers/map-to-paginated-view-model.util.js";
import type { PaginatedViewModel } from "../../core/types/paginated-view-model.js";
import { commentsCollection } from "../../db/collections.js";
import { mapToCommentViewModel } from "../routers/mappers/map-to-comment-view-model.util.js";
import type { CommentQueryInput } from "../types/comment-query-input.js";
import type { CommentViewModel } from "../types/comment-view-model.js";

export const commentsQueryRepository = {
  async findById(id: string): Promise<CommentViewModel | null> {
    if (!ObjectId.isValid(id)) {
      return null;
    }

    const comment = await commentsCollection.findOne({
      _id: new ObjectId(id),
    });

    return comment ? mapToCommentViewModel(comment) : null;
  },

  async findManyByPostId(
    postId: string,
    query: CommentQueryInput,
  ): Promise<PaginatedViewModel<CommentViewModel>> {
    const filter = { postId };
    const skip = (query.pageNumber - 1) * query.pageSize;
    const [items, totalCount] = await Promise.all([
      commentsCollection
        .find(filter)
        .sort({ [query.sortBy]: query.sortDirection })
        .skip(skip)
        .limit(query.pageSize)
        .toArray(),
      commentsCollection.countDocuments(filter),
    ]);

    return mapToPaginatedViewModel(
      items,
      {
        pageNumber: query.pageNumber,
        pageSize: query.pageSize,
        totalCount,
      },
      mapToCommentViewModel,
    );
  },
};
