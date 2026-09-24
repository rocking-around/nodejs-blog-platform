import express from "express";
import { setupApp } from "./setup-app.js";

const app = express();
const port = process.env.PORT ?? 5001;

setupApp(app);

app.listen(port, () => {
  console.log(`Blog platform is listening on port ${port}`);
});
