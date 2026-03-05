import 'dart:convert';

import 'package:apoorv_app/app_config.dart';
import 'package:apoorv_app/widgets/snackbar.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:http/http.dart' as http;

const _googleClientId =
    "389271534594-f2ki17289n40i9iei81s0f48g13sf04k.apps.googleusercontent.com";

Future<UserCredential?> signInWithGoogle(BuildContext context) async {
  try {
    String? idToken;
    String? firebaseIdToken;

    if (kIsWeb) {
      final GoogleAuthProvider googleProvider = GoogleAuthProvider();
      googleProvider.addScope('email');
      googleProvider.addScope('profile');

      final UserCredential userCredential = await FirebaseAuth.instance.signInWithPopup(googleProvider);
      firebaseIdToken = await userCredential.user?.getIdToken();

      if (firebaseIdToken == null) {
        if (!context.mounted) return null;
        showSnackbarOnScreen(context, "Failed to get Firebase ID token");
        return null;
      }
    } else {
      final googleSignIn = GoogleSignIn(
        clientId: _googleClientId,
        scopes: ['email', 'profile'],
      );

      final GoogleSignInAccount? googleUser = await googleSignIn.signIn();

      if (googleUser == null) {
        return null;
      }

      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      idToken = googleAuth.idToken;
      if (idToken == null) {
        await googleSignIn.signOut();
        if (!context.mounted) return null;
        showSnackbarOnScreen(context, "Failed to get Google ID token");
        return null;
      }
    }

    final Map<String, dynamic> body = {};
    if (idToken != null) body["idToken"] = idToken;
    if (firebaseIdToken != null) body["firebaseIdToken"] = firebaseIdToken;

    final response = await http.post(
      Uri.parse("${AppConfig.functionsUrl}/auth/google"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode(body),
    );

    if (response.statusCode == 403) {
      if (!kIsWeb) {
        await GoogleSignIn().signOut();
      } else {
        await FirebaseAuth.instance.signOut();
      }
      if (!context.mounted) return null;
      showSnackbarOnScreen(context, "Use your IIIT Kottayam email");
      return null;
    }

    if (response.statusCode != 200) {
      if (!kIsWeb) {
        await GoogleSignIn().signOut();
      } else {
        await FirebaseAuth.instance.signOut();
      }
      if (!context.mounted) return null;
      showSnackbarOnScreen(context, "Authentication failed");
      return null;
    }

    final responseData = jsonDecode(response.body) as Map<String, dynamic>;
    final customToken = responseData["customToken"] as String;
    return await FirebaseAuth.instance.signInWithCustomToken(customToken);
  } on Exception catch (e) {
    if (!context.mounted) return null;
    showSnackbarOnScreen(context, e.toString());
    return null;
  }
}
