import 'package:apoorv_app/providers/user_info_provider.dart';
import 'package:apoorv_app/router.dart';
import 'package:apoorv_app/screens/signup-flow/signup.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../constants.dart';
import '../../widgets/signup-flow/sign_in_with_google.dart';
import '../../widgets/snackbar.dart';

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});
  static const routeName = '/welcome';
  @override
  // ignore: library_private_types_in_public_api
  _WelcomeScreenState createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> {
  bool popStatus = true;
  int popCount = 0;

  bool isProcessing = false;

  @override
  void initState() {
    super.initState();
    popScreen(context);
  }

  Future<void> popScreen(BuildContext context) async {
    popStatus = await Navigator.maybePop(context);
    if (mounted) {
      setState(() {});
    }
  }

  void showAppCloseConfirmation(BuildContext context) {
    const snackBar = SnackBar(
      content: Text("Press back again to exit"),
      backgroundColor: Colors.white,
    );
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(snackBar);
  }

  @override
  Widget build(BuildContext context) {
    // int count=0;
    return PopScope(
      canPop: popStatus,
      onPopInvoked: (bool didPop) async {
        if (didPop) {
          return;
        }
        popCount += 1;
        if (popCount == 1) {
          showAppCloseConfirmation(context);
          setState(() {
            popStatus = true;
          });
        }
      },
      child: Scaffold(
        body: Padding(
            padding: EdgeInsets.symmetric(
                horizontal: MediaQuery.sizeOf(context).width * 0.05),
            child: SafeArea(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  Image.asset('assets/images/upscaled_phoenix_red_title.png'),
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 12),
                    width: double.infinity,
                    child: Container(
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Constants.gradientLow,
                            Constants.gradientHigh
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        // color: Constants.yellowColor,
                        borderRadius: BorderRadius.all(Radius.circular(50)),
                      ),
                      child: FilledButton.icon(
                        onPressed: isProcessing
                            ? null
                            : () async {
                                setState(() {
                                  isProcessing = true;
                                });

                                try {
                                  final userCredential = await signInWithGoogle(context);

                                  if (userCredential != null && context.mounted) {
                                    // Check if user needs to complete signup
                                    final user = FirebaseAuth.instance.currentUser;
                                    if (user != null) {
                                      final doc = await FirebaseFirestore.instance
                                          .collection('users')
                                          .doc(user.uid)
                                          .get();

                                      final data = doc.data();
                                      final name = (data?['name'] as String?)?.trim() ?? '';
                                      final phone = (data?['phone'] as String?)?.trim() ?? '';

                                      if (name.isEmpty || phone.isEmpty) {
                                        // Redirect to signup to complete profile
                                        if (context.mounted) {
                                          showSnackbarOnScreen(context, "Please complete your profile");
                                          Navigator.of(context)
                                              .restorablePushReplacementNamed(SignUpScreen.routeName);
                                        }
                                      } else {
                                        // Profile complete, go to home
                                        if (context.mounted) {
                                          showSnackbarOnScreen(context, "User Signed in!");
                                          Provider.of<UserProvider>(context, listen: false)
                                              .refreshGoogleServiceData();
                                          Navigator.of(context)
                                              .restorablePushReplacementNamed(Routing.routeName);
                                        }
                                      }
                                    }
                                  } else {
                                    // Sign-in was cancelled or failed
                                    setState(() {
                                      isProcessing = false;
                                    });
                                  }
                                } catch (e) {
                                  if (context.mounted) {
                                    showSnackbarOnScreen(context, "Authentication failed");
                                  }
                                  setState(() {
                                    isProcessing = false;
                                  });
                                }
                              },
                        style: ButtonStyle(
                            backgroundColor: MaterialStateProperty.all<Color>(
                                Colors.transparent)),
                        icon: SizedBox(
                          height: 64,
                          child: isProcessing
                              ? null
                              : Image.asset(
                                  'assets/images/google.png',
                                  fit: BoxFit.contain,
                                ),
                        ),
                        label: isProcessing
                            ? const CircularProgressIndicator(
                                color: Constants.redColorAlt,
                              )
                            : const Text(
                                'Sign In with Google',
                                style: TextStyle(
                                  fontSize: 20,
                                  // fontFamily: 'Inter',
                                  color: Colors.black,
                                ),
                              ),
                      ),
                    ),
                  )
                ],
              ),
            )),
      ),
    );
  }
}
