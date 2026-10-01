import { Router } from "express";
import { HTTP_STATUSES } from "../../core/types/http-statuses.js";
import { getAllCollections } from "../../db/collections.js";

export const testingRouter: Router = Router({});

testingRouter.delete("/all-data", async (_req, res) => {
  await Promise.all(
    getAllCollections().map((collection) => collection.deleteMany({})),
  );
  return res.sendStatus(HTTP_STATUSES.NO_CONTENT);
});
