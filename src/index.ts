import express from "express";
import { env } from "./core/config/env.js";
import { runDb, stopDb } from "./db/mongo.db.js";
import { setupApp } from "./setup-app.js";

const app = express();

setupApp(app);

await runDb(env.mongoUrl);

const server = app.listen(env.port, () => {
  console.log(`Blog platform is listening on port ${env.port}`);
});

const shutdown = (): void => {
  server.close(() => {
    void stopDb().finally(() => process.exit(0));
  });
};

process.on("SIGINT", shutdown);
process.on("SIGTERM", shutdown);
