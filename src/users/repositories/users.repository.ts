import { ObjectId, type WithId } from "mongodb";
import { usersCollection } from "../../db/collections.js";
import type { User } from "../types/user.js";

export const usersRepository = {
  async findByLogin(login: string): Promise<WithId<User> | null> {
    return usersCollection.findOne({ login });
  },

  async findByEmail(email: string): Promise<WithId<User> | null> {
    return usersCollection.findOne({ email });
  },

  async findByLoginOrEmail(loginOrEmail: string): Promise<WithId<User> | null> {
    return usersCollection.findOne({
      $or: [{ login: loginOrEmail }, { email: loginOrEmail }],
    });
  },

  async create(user: User): Promise<string> {
    const result = await usersCollection.insertOne(user);
    return result.insertedId.toString();
  },

  async delete(id: string): Promise<boolean> {
    if (!ObjectId.isValid(id)) {
      return false;
    }

    const result = await usersCollection.deleteOne({ _id: new ObjectId(id) });
    return result.deletedCount === 1;
  },
};
