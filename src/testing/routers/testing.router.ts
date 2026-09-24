import { Router } from "express";
import { HTTP_STATUSES } from "../../core/types/http-statuses.js";
import { db } from "../../db/db.js";

export const testingRouter: Router = Router({});

testingRouter.delete("/all-data", (_req, res) => {
  db.blogs.length = 0;
  db.posts.length = 0;
  return res.sendStatus(HTTP_STATUSES.NO_CONTENT);
});
