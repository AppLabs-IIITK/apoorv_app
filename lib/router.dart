import 'providers/user_info_provider.dart';
import 'screens/homepage/homepage.dart';
import 'screens/signup-flow/welcome.dart';
import 'screens/signup-flow/signup.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'widgets/dialog.dart';
import 'widgets/snackbar.dart';
import 'widgets/spinning_apoorv.dart';

class Routing extends StatefulWidget {
  static const routeName = '/routing';
  const Routing({super.key});

  @override
  State<Routing> createState() => _RoutingState();
}

class _RoutingState extends State<Routing> {
  Future<int> getStartupPage(BuildContext context) async {
    Provider.of<UserProvider>(context, listen: false);
    if (FirebaseAuth.instance.currentUser == null) {
      return 0;
    }

    // Minimal onboarding gate:
    // - if Firestore user doc has non-empty name -> go Home
    // - else -> go onboarding (name)
    try {
      final uid = FirebaseAuth.instance.currentUser!.uid;
      final doc = await FirebaseFirestore.instance
          .collection("users")
          .doc(uid)
          .get();

      final data = doc.data();
      final name = (data == null) ? null : (data["name"] as String?);
      final hasName = name != null && name.trim().isNotEmpty;

      // Keep provider minimally updated for UI.
      if (!context.mounted) return -1;
      final prov = Provider.of<UserProvider>(context, listen: false);
      prov.refreshUID(listen: false);
      prov.refreshIdToken(listen: false);
      if (FirebaseAuth.instance.currentUser?.email != null) {
        prov.updateEmail(FirebaseAuth.instance.currentUser!.email!);
      }
      if (FirebaseAuth.instance.currentUser?.photoURL != null) {
        prov.updateProfilePhoto(FirebaseAuth.instance.currentUser!.photoURL!);
      }
      if (hasName) {
        prov.userName = name;
      }

      return hasName ? 2 : 1;
    } catch (e) {
      print("Error while routing: $e");
      return -1;
    }
  }

  late Future<int> _myFuture;

  @override
  void initState() {
    super.initState();
    _myFuture = getStartupPage(context);
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: _myFuture,
      builder: (BuildContext context, AsyncSnapshot snapshot) {
        switch (snapshot.connectionState) {
          case ConnectionState.waiting:
            return const Scaffold(body: Center(child: SpinningApoorv()));

          case ConnectionState.done:
          default:
            if (snapshot.hasError) {
              return Scaffold(
                  body: Center(child: Text(snapshot.error.toString())));
            } else if (snapshot.hasData) {
              // print(snapshot.data);
              var userProgress = snapshot.data;
              if (userProgress == 0) {
                // If no Firebase auth currentuser, then call welcomeScreen()
                SchedulerBinding.instance.addPostFrameCallback((_) {
                  Navigator.of(context)
                      .pushReplacementNamed(WelcomeScreen.routeName);
                });
              } else if (userProgress == 2) {
                // If firebase auth currentuser present, and in database then call homepage
                SchedulerBinding.instance.addPostFrameCallback((_) {
                  Navigator.of(context)
                      .pushReplacementNamed(HomePage.routeName);
                });
              } else if (userProgress == 1) {
                SchedulerBinding.instance.addPostFrameCallback((_) {
                  Navigator.of(context)
                      .pushReplacementNamed(SignUpScreen.routeName);
                });
              } else if (userProgress == -1) {
                var message =
                    "There was a connection error! Check your connection and try again";

                Future.delayed(
                    const Duration(seconds: 1),
                    () {
                      if (!context.mounted) return;
                      dialogBuilder(context, message: message, function: () {
                        setState(() {
                          _myFuture = getStartupPage(context);
                        });
                        Navigator.of(context).pop();
                      });
                    });

                return const Scaffold(body: Center(child: SpinningApoorv()));
              } else {
                Future.delayed(
                  const Duration(seconds: 0),
                  () {
                    if (!context.mounted) return;
                    showSnackbarOnScreen(context, "No data on Screen");
                  },
                );
                return const Center(child: Text("No data on Screen"));
              }
            }
            // else {
            return const Scaffold(body: Center(child: SpinningApoorv()));
          // }
        }
      },
    );
  }
}
