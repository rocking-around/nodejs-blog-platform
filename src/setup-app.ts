import express, { type Express } from "express";
import { BLOGS_PATH } from "./blogs/constants/blogs-paths.js";
import { blogsRouter } from "./blogs/routers/blogs.router.js";
import { POSTS_PATH } from "./posts/constants/posts-paths.js";
import { postsRouter } from "./posts/routers/posts.router.js";
import { testingRouter } from "./testing/routers/testing.router.js";

const API_PATH = "/ht_02/api";

export const setupApp = (app: Express) => {
  app.use(express.json());
  app.use(`${API_PATH}${BLOGS_PATH}`, blogsRouter);
  app.use(`${API_PATH}${POSTS_PATH}`, postsRouter);
  app.use(`${API_PATH}/testing`, testingRouter);

  return app;
};
