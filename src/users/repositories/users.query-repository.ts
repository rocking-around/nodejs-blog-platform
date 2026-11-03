import type { Filter, WithId } from "mongodb";
import { usersCollection } from "../../db/collections.js";
import type { UserQueryInput } from "../types/user-query-input.js";
import type { User } from "../types/user.js";

const escapeRegExp = (value: string): string =>
  value.replace(/[.*+?^${}()|[\]\\]/g, "\\$&");

export const usersQueryRepository = {
  async findMany(
    query: UserQueryInput,
  ): Promise<{ items: WithId<User>[]; totalCount: number }> {
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

    return { items, totalCount };
  },
};
