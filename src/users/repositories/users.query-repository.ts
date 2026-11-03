import { ObjectId, type Filter } from "mongodb";
import { mapToPaginatedViewModel } from "../../core/mappers/map-to-paginated-view-model.util.js";
import type { PaginatedViewModel } from "../../core/types/paginated-view-model.js";
import { usersCollection } from "../../db/collections.js";
import { mapToUserViewModel } from "../routers/mappers/map-to-user-view-model.util.js";
import type { UserQueryInput } from "../types/user-query-input.js";
import type { UserViewModel } from "../types/user-view-model.js";
import type { User } from "../types/user.js";

const escapeRegExp = (value: string): string =>
  value.replace(/[.*+?^${}()|[\]\\]/g, "\\$&");

export const usersQueryRepository = {
  async findMany(
    query: UserQueryInput,
  ): Promise<PaginatedViewModel<UserViewModel>> {
    const searchConditions: Filter<User>[] = [];

    if (query.searchLoginTerm) {
      searchConditions.push({
        login: {
          $regex: escapeRegExp(query.searchLoginTerm),
          $options: "i",
        },
      });
    }

    if (query.searchEmailTerm) {
      searchConditions.push({
        email: {
          $regex: escapeRegExp(query.searchEmailTerm),
          $options: "i",
        },
      });
    }

    const filter: Filter<User> =
      searchConditions.length > 0 ? { $or: searchConditions } : {};
    const skip = (query.pageNumber - 1) * query.pageSize;
    const [items, totalCount] = await Promise.all([
      usersCollection
        .find(filter)
        .sort({ [query.sortBy]: query.sortDirection })
        .skip(skip)
        .limit(query.pageSize)
        .toArray(),
      usersCollection.countDocuments(filter),
    ]);

    return mapToPaginatedViewModel(
      items,
      {
        pageNumber: query.pageNumber,
        pageSize: query.pageSize,
        totalCount,
      },
      mapToUserViewModel,
    );
  },

  async findById(id: string): Promise<UserViewModel | null> {
    if (!ObjectId.isValid(id)) {
      return null;
    }

    const user = await usersCollection.findOne({ _id: new ObjectId(id) });
    return user ? mapToUserViewModel(user) : null;
  },
};
