import express from "express";

import {healthRouter} from "./routes/health.js";
import {authRouter} from "./routes/auth.js";

const app = express();

app.use(express.json());

// CORS (intentionally permissive for now)
app.use((req, res, next) => {
  res.set("Access-Control-Allow-Origin", "*");
  res.set("Access-Control-Allow-Methods", "GET, POST, OPTIONS");
  res.set("Access-Control-Allow-Headers", "Content-Type, Authorization");

  if (req.method === "OPTIONS") {
    res.status(204).send("");
    return;
  }

  next();
});

app.use("/health", healthRouter);
app.use("/auth", authRouter);

app.use((req, res) => {
  res.status(404).json({error: "Not found"});
});

export {app};
