import { ObjectId, type WithId } from "mongodb";
import { commentsCollection } from "../../db/collections.js";
import type { Comment } from "../types/comment.js";

export const commentsRepository = {
  async findById(id: string): Promise<WithId<Comment> | null> {
    if (!ObjectId.isValid(id)) {
      return null;
    }

    return commentsCollection.findOne({ _id: new ObjectId(id) });
  },

  async create(comment: Comment): Promise<string> {
    const result = await commentsCollection.insertOne(comment);
    return result.insertedId.toString();
  },

  async update(id: string, content: string): Promise<boolean> {
    if (!ObjectId.isValid(id)) {
      return false;
    }

    const result = await commentsCollection.updateOne(
      { _id: new ObjectId(id) },
      { $set: { content } },
    );

    return result.matchedCount === 1;
  },

  async delete(id: string): Promise<boolean> {
    if (!ObjectId.isValid(id)) {
      return false;
    }

    const result = await commentsCollection.deleteOne({
      _id: new ObjectId(id),
    });

    return result.deletedCount === 1;
  },
};
