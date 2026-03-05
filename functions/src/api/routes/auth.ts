import express from "express";
import * as admin from "firebase-admin";
import {OAuth2Client} from "google-auth-library";

const router = express.Router();

// Provided Google OAuth client id
const GOOGLE_CLIENT_ID =
  "389271534594-f2ki17289n40i9iei81s0f48g13sf04k.apps.googleusercontent.com";

const googleClient = new OAuth2Client(GOOGLE_CLIENT_ID);

interface GoogleAuthRequest {
  idToken: string;
}

interface AuthResponse {
  customToken: string;
  user: {
    uid: string;
    email: string;
    rollNumber?: string;
    isNewUser: boolean;
  };
}

/**
 * Format: 25bcs001@iiitkottayam.ac.in -> 2025BCS0001
 */
function extractRollNumber(email: string): string | null {
  if (!email.endsWith("iiitkottayam.ac.in")) {
    return null;
  }

  const localPart = email.split("@")[0] || "";
  const regExp = /(\d+)([a-zA-Z]+)(\d+)/;
  const match = regExp.exec(localPart);
  if (!match) {
    return null;
  }

  const year = match[1];
  const branch = match[2].toUpperCase();
  const number = match[3].padStart(4, "0");
  return `20${year}${branch}${number}`;
}

async function verifyGoogleIdToken(idToken: string) {
  const ticket = await googleClient.verifyIdToken({
    idToken,
    audience: GOOGLE_CLIENT_ID,
  });

  const payload = ticket.getPayload();
  if (!payload) {
    throw new Error("Invalid token payload");
  }

  const email = payload.email;
  if (!email) {
    throw new Error("Email missing in token payload");
  }

  return {
    email,
    emailVerified: payload.email_verified || false,
    name: payload.name || null,
    photoUrl: payload.picture || null,
  };
}

router.post("/google", async (req, res) => {
  try {
    const {idToken}: GoogleAuthRequest = req.body;

    if (!idToken) {
      res.status(400).json({
        error: "Bad Request",
        message: "idToken is required",
      });
      return;
    }

    let googleData: {email: string; emailVerified: boolean; photoUrl: string | null};
    try {
      googleData = await verifyGoogleIdToken(idToken);
    } catch (error) {
      console.error("Failed to verify Google ID token:", error);
      res.status(401).json({
        error: "Unauthorized",
        message: "Invalid Google ID token",
      });
      return;
    }

    if (!googleData.emailVerified) {
      res.status(401).json({
        error: "Unauthorized",
        message: "Email not verified",
      });
      return;
    }

    const email = googleData.email;

    if (!email.endsWith("iiitkottayam.ac.in")) {
      res.status(403).json({
        error: "Forbidden",
        message: "Only IIIT Kottayam email addresses are allowed",
        email,
      });
      return;
    }

    const rollNumber = extractRollNumber(email);
    const emailLocalPart = email.split("@")[0];
    const photoUrl = googleData.photoUrl;

    const firebaseUser = await (async () => {
      try {
        return await admin.auth().getUserByEmail(email);
      } catch (error: unknown) {
        const err = error as {code?: unknown};
        if (err?.code === "auth/user-not-found") {
          return await admin.auth().createUser({
            email,
            emailVerified: true,
            photoURL: photoUrl || undefined,
          });
        }
        throw error;
      }
    })();

    // Ensure Auth user has photo URL
    if (photoUrl) {
      await admin.auth().updateUser(firebaseUser.uid, {
        photoURL: photoUrl || undefined,
      });
    }

    // Create user doc immediately on login.
    // Doc id = uid (so Flutter can always read by auth uid)
    const userDoc = admin.firestore().collection("users").doc(firebaseUser.uid);
    const snap = await userDoc.get();
    const isNewUser = !snap.exists;

    if (isNewUser) {
      await userDoc.set({
        uid: firebaseUser.uid,
        email,
        emailLocalPart,
        rollNumber,
        // Mirror legacy API keys so Flutter can switch to Firestore with minimal changes
        photoUrl: photoUrl,
        phone: "",
        fromCollege: true,
        collegeName: "IIIT Kottayam",
        points: 0,
        name: null,
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
        lastLogin: admin.firestore.FieldValue.serverTimestamp(),
      });
    } else {
      await userDoc.update({
        email,
        emailLocalPart,
        rollNumber,
        ...(photoUrl ? {photoUrl} : {}),
        lastLogin: admin.firestore.FieldValue.serverTimestamp(),
      });
    }

    const customToken = await admin.auth().createCustomToken(firebaseUser.uid);

    const response: AuthResponse = {
      customToken,
      user: {
        uid: firebaseUser.uid,
        email,
        rollNumber: rollNumber || undefined,
        isNewUser,
      },
    };

    res.status(200).json(response);
  } catch (error: unknown) {
    console.error("Error in Google auth:", error);
    const message =
      error instanceof Error ? error.message : "Failed to authenticate";
    res.status(500).json({
      error: "Internal Server Error",
      message,
    });
  }
});

export {router as authRouter};
