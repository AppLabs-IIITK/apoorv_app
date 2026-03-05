import * as admin from "firebase-admin";
import * as functions from "firebase-functions/v2/https";

import {app} from "./api/index.js";

admin.initializeApp();

export const api = functions.onRequest(
  {
    region: "asia-south1",
    cors: true,
  },
  app
);
