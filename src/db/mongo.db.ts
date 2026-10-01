import { MongoClient, type Db } from "mongodb";
import { env } from "../core/config/env.js";
import { initCollections } from "./collections.js";

export let client: MongoClient;
let database: Db | undefined;

export const runDb = async (url: string): Promise<void> => {
  client = new MongoClient(url);
  database = client.db(env.mongoDatabaseName);
  initCollections(database);

  try {
    await client.connect();
    await database.command({ ping: 1 });
    console.log("Connected to MongoDB");
  } catch (error) {
    await client.close();
    database = undefined;
    throw new Error(`MongoDB connection failed: ${String(error)}`);
  }
};

export const stopDb = async (): Promise<void> => {
  if (!client) {
    return;
  }

  await client.close();
  database = undefined;
};

export const pingDb = async (): Promise<void> => {
  if (!database) {
    throw new Error("MongoDB is not connected");
  }

  await database.command({ ping: 1 });
};
