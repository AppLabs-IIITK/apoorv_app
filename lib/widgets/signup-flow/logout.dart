import 'package:apoorv_app/screens/signup-flow/welcome.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../../constants.dart';

class LogoutButton extends StatelessWidget {
  const LogoutButton({super.key});

  @override
  Widget build(BuildContext context) {
    return FilledButton(
      onPressed: () async {
        await FirebaseAuth.instance.signOut();
        if (!kIsWeb) {
          await GoogleSignIn().signOut();
        }

        if (context.mounted) {
          Navigator.of(context)
              .restorablePushReplacementNamed(WelcomeScreen.routeName);
        }
      },
      style: ButtonStyle(
        backgroundColor: MaterialStateProperty.all<Color>(Constants.redColor),
        foregroundColor: MaterialStateProperty.all<Color>(Constants.whiteColor),
      ),
      child: const SizedBox(
        width: double.infinity,
        child: Text(
          "Logout",
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}
