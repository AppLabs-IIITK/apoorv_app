import express from "express";

import {healthRouter} from "./routes/health.js";
import {authRouter} from "./routes/auth.js";
import {transactionRouter} from "./routes/transaction.js";

const app = express();

app.use(express.json());

import cors from "cors";

app.use(cors({
  origin: "*",
  methods: ["GET", "POST", "PUT", "DELETE", "OPTIONS"],
  allowedHeaders: ["Content-Type", "Authorization"]
}));

app.use("/health", healthRouter);
app.use("/auth", authRouter);
app.use("/transaction", transactionRouter);

app.use((req, res) => {
  res.status(404).json({error: "Not found"});
});

export {app};
