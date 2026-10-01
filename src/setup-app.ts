import express, { type Express } from "express";
import { BLOGS_PATH } from "./blogs/constants/blogs-paths.js";
import { blogsRouter } from "./blogs/routers/blogs.router.js";
import { env } from "./core/config/env.js";
import { pingDb } from "./db/mongo.db.js";
import { POSTS_PATH } from "./posts/constants/posts-paths.js";
import { postsRouter } from "./posts/routers/posts.router.js";
import { testingRouter } from "./testing/routers/testing.router.js";

export const setupApp = (app: Express) => {
  app.use(express.json());
  app.get("/health", async (_req, res) => {
    await pingDb();
    return res.status(200).send({ status: "ok" });
  });
  app.use(`${env.apiPath}${BLOGS_PATH}`, blogsRouter);
  app.use(`${env.apiPath}${POSTS_PATH}`, postsRouter);
  app.use(`${env.apiPath}/testing`, testingRouter);

  return app;
};
