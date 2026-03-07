import express from "express";
import * as admin from "firebase-admin";

const router = express.Router();

function getBearerToken(req: express.Request): string | null {
  const header = (req.headers.authorization || "").toString();
  const parts = header.split(" ");
  if (parts.length === 2 && parts[0] === "Bearer" && parts[1]) {
    return parts[1];
  }
  return null;
}

async function requireAuth(req: express.Request): Promise<admin.auth.DecodedIdToken> {
  const token = getBearerToken(req);
  if (!token) {
    throw new Error("missing-auth");
  }
  return await admin.auth().verifyIdToken(token);
}

router.post("/", async (req, res) => {
  try {
    const decoded = await requireAuth(req);
    const fromUid = decoded.uid;

    const to = (req.body?.to || req.body?.toUid || "").toString().trim();
    const amountRaw = req.body?.amount;
    const amount = typeof amountRaw === "number" ? amountRaw : parseInt(amountRaw, 10);
    const rawMode = (req.body?.mode || "user").toString().trim().toLowerCase();
    const mode = rawMode === "shop" ? "shop" : "user";

    if (!to) {
      res.status(400).json({success: false, message: "to is required"});
      return;
    }
    if (!Number.isFinite(amount) || amount <= 0) {
      res.status(400).json({success: false, message: "amount must be > 0"});
      return;
    }
    if (to === fromUid) {
      res.status(400).json({success: false, message: "cannot send to self"});
      return;
    }

    const db = admin.firestore();
    const fromRef = db.collection("users").doc(fromUid);
    const toRef = db.collection("users").doc(to);
    const txnRef = db.collection("transactions").doc();

    const result = await db.runTransaction(async (t) => {
      const [fromSnap, toSnap] = await Promise.all([t.get(fromRef), t.get(toRef)]);
      if (!fromSnap.exists) {
        throw new Error("from-user-not-found");
      }
      if (!toSnap.exists) {
        throw new Error("to-user-not-found");
      }

      const fromData = fromSnap.data() || {};
      const toData = toSnap.data() || {};

      const fromPoints = typeof fromData.points === "number" ? fromData.points : 0;
      const toPoints = typeof toData.points === "number" ? toData.points : 0;
      const fromShopPoints =
        typeof fromData.shopPoints === "number" ? fromData.shopPoints : 0;
      const isShopkeeper = fromData.isShopkeeper === true;

      const fromEmail = (fromData.email || decoded.email || "").toString();
      const toEmail = (toData.email || "").toString();
      const fromName = (fromData.name || fromData.fullName || "").toString();
      const toName = (toData.name || toData.fullName || "").toString();

      let adminOk: boolean | null = null;
      const allowAdminBypass = async () => {
        if (adminOk !== null) return adminOk;

        const configRef = db.collection("app_config").doc("global");
        const configSnap = await t.get(configRef);
        const fromEmailNorm = (fromEmail || "").trim().toLowerCase();

        adminOk =
          !!fromEmailNorm &&
          (((configSnap.get("adminEmails") as string[] | undefined) ?? []).some(
            (e) => (e || "").trim().toLowerCase() === fromEmailNorm,
          ));
        return adminOk;
      };

      if (mode === "shop") {
        if (!isShopkeeper) {
          throw new Error("not-shopkeeper");
        }
        if (amount > 150 && !(await allowAdminBypass())) {
          throw new Error("shop-limit-exceeded");
        }
        if (fromShopPoints < amount) {
          throw new Error("insufficient-shop-points");
        }
        const existingQuery = db
          .collection("transactions")
          .where("from", "==", fromUid)
          .where("to", "==", to)
          .where("type", "==", "shop")
          .limit(1);
        const existingSnap = await t.get(existingQuery);
        if (!existingSnap.empty && !(await allowAdminBypass())) {
          throw new Error("shop-limit-reached");
        }

        t.update(fromRef, {shopPoints: fromShopPoints - amount});
        t.update(toRef, {points: toPoints + amount});
      } else {
        if (fromPoints < amount) {
          throw new Error("insufficient-points");
        }
        t.update(fromRef, {points: fromPoints - amount});
        t.update(toRef, {points: toPoints + amount});
      }

      t.set(txnRef, {
        from: fromUid,
        to,
        involvedPartiesUids: [fromUid, to],
        involvedPartiesEmails: [fromEmail.trim().toLowerCase(), toEmail.trim().toLowerCase()],
        fromName,
        toName,
        fromEmail,
        toEmail,
        transactionValue: amount,
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
        type: mode,
      });

      return {
        transactionId: txnRef.id,
        fromPoints: mode === "shop" ? fromPoints : fromPoints - amount,
        fromShopPoints:
          mode === "shop" ? fromShopPoints - amount : fromShopPoints,
        toPoints: toPoints + amount,
      };
    });

    res.status(200).json({
      success: true,
      message: "Transaction completed successfully",
      ...result,
    });
  } catch (error: unknown) {
    const msg = error instanceof Error ? error.message : "unknown";
    if (msg === "missing-auth") {
      res.status(401).json({success: false, message: "Unauthorized"});
      return;
    }
    if (msg === "insufficient-points") {
      res.status(400).json({success: false, message: "Insufficient points"});
      return;
    }
    if (msg === "insufficient-shop-points") {
      res.status(400).json({success: false, message: "Insufficient shop points"});
      return;
    }
    if (msg === "not-shopkeeper") {
      res.status(403).json({success: false, message: "Not a shopkeeper"});
      return;
    }
    if (msg === "shop-limit-exceeded") {
      res.status(400).json({
        success: false,
        message: "Shop rewards are limited to 150 points per person",
      });
      return;
    }
    if (msg === "shop-limit-reached") {
      res.status(400).json({
        success: false,
        message: "You have already rewarded this user with shop points",
      });
      return;
    }
    if (msg === "from-user-not-found" || msg === "to-user-not-found") {
      res.status(404).json({success: false, message: "User not found"});
      return;
    }
    console.error("Transaction error:", error);
    res.status(500).json({success: false, message: "Failed to process transaction"});
  }
});

export {router as transactionRouter};
