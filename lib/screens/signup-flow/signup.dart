import 'package:apoorv_app/widgets/snackbar.dart';
import 'package:apoorv_app/widgets/spinning_apoorv.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';

import '../../constants.dart';
import 'package:flutter/material.dart';

import '../../providers/user_info_provider.dart';
import '../homepage/homepage.dart';

class SignUpScreen extends StatefulWidget {
  static const routeName = '/sign-up';
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final TextEditingController userNameController = TextEditingController();
  final TextEditingController userRollNoController = TextEditingController();
  final TextEditingController userPhoneController = TextEditingController();

  final _formKey = GlobalKey<FormState>();

  bool isProcessing = false;

  @override
  void dispose() {
    userNameController.dispose();
    userRollNoController.dispose();
    userPhoneController.dispose();
    super.dispose();
  }

  bool popStatus = true;
  int popCount = 0;

  @override
  void initState() {
    super.initState();
    Provider.of<UserProvider>(context, listen: false)
        .refreshGoogleServiceData();

    // Prefill roll number from Firestore (created during login) and keep it read-only.
    _prefillRollNumber();
    popScreen(context);
  }

  Future<void> _prefillRollNumber() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      final doc = await FirebaseFirestore.instance
          .collection("users")
          .doc(user.uid)
          .get();
      final data = doc.data();
      final roll = (data == null) ? null : (data["rollNumber"] as String?);
      if (roll != null && roll.trim().isNotEmpty && mounted) {
        setState(() {
          userRollNoController.text = roll;
        });
      }
    } catch (e) {
      // Non-fatal; user can still continue with just name.
      print("Failed to prefill roll number: $e");
    }
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
    var userProvider = Provider.of<UserProvider>(context);
    // BaseClient.printAuthTokenForTest();
    // print(FirebaseAuth.instance.currentUser!.uid);
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
        body: SafeArea(
          child: Padding(
            padding: EdgeInsets.symmetric(
                horizontal: MediaQuery.of(context).size.width * 0.05),
            child: LayoutBuilder(builder: (context, constraints) {
              return SingleChildScrollView(
                // reverse: false,
                child: ConstrainedBox(
                  constraints: BoxConstraints(minHeight: constraints.maxHeight),
                  child: Column(
                    // mainAxisAlignment: MainAxisAlignment.spaceAround,
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      RichText(
                        text: const TextSpan(
                          children: [
                            TextSpan(
                                text: 'Give us a Quick Introduction\n',
                                style: TextStyle(color: Constants.yellowColor)),
                            TextSpan(
                                text: 'About ',
                                style: TextStyle(color: Constants.yellowColor)),
                            TextSpan(
                                text: 'Yourself',
                                style: TextStyle(color: Constants.redColor)),
                          ],
                          style: TextStyle(
                              fontFamily: 'Libre Baskerville', fontSize: 22),
                        ),
                        textAlign: TextAlign.center,
                      ),
                      Icon(
                        Icons.account_circle_outlined,
                        color: Constants.yellowColor,
                        size: MediaQuery.of(context).size.width * 0.4,
                      ),
                      Form(
                        key: _formKey,
                        child: Column(
                          children: [
                            TextFormField(
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return "Full name is required";
                                  }
                                  return null;
                                },
                                controller: userNameController,
                                decoration: InputDecoration(
                                  border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(16)),
                                  filled: true,
                                  fillColor: Constants.yellowColor,
                                  hintText: "Full Name",
                                  hintStyle:
                                      const TextStyle(color: Colors.black),
                                )),
                            Constants.gap,
                            TextFormField(
                                controller: userRollNoController,
                                enabled: false,
                                decoration: InputDecoration(
                                  border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(16)),
                                  filled: true,
                                  fillColor: Constants.silverColor,
                                  hintText: "Roll Number",
                                  hintStyle:
                                      const TextStyle(color: Colors.black54),
                                )),
                            Constants.gap,
                            TextFormField(
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return "Phone number is required";
                                  }
                                  if (value.length != 10) {
                                    return "Phone number must be 10 digits";
                                  }
                                  return null;
                                },
                                controller: userPhoneController,
                                keyboardType: TextInputType.phone,
                                maxLength: 10,
                                decoration: InputDecoration(
                                  border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(16)),
                                  filled: true,
                                  fillColor: Constants.yellowColor,
                                  hintText: "Phone Number",
                                  hintStyle:
                                      const TextStyle(color: Colors.black),
                                )),
                            Constants.gap,
                            FilledButton(
                              onPressed: isProcessing
                                  ? null
                                  : () async {
                                      if (!isProcessing) {
                                        setState(() {
                                          isProcessing = true;
                                        });
                                      }
                                      if (_formKey.currentState!.validate()) {
                                        try {
                                          final user =
                                              FirebaseAuth.instance.currentUser;
                                          if (user == null) {
                                            throw Exception("Not signed in");
                                          }

                                           await FirebaseFirestore.instance
                                               .collection("users")
                                               .doc(user.uid)
                                               .set(
                                             {
                                                "name":
                                                    userNameController.text.trim(),
                                                "nameLower": userNameController
                                                    .text
                                                    .trim()
                                                    .toLowerCase(),
                                                "phone":
                                                    userPhoneController.text.trim(),
                                              },
                                              SetOptions(merge: true),
                                            );

                                          userProvider.userName =
                                              userNameController.text.trim();
                                          userProvider.userPhNo =
                                              userPhoneController.text.trim();

                                          if (context.mounted) {
                                            showSnackbarOnScreen(
                                                context, "Onboarding complete");
                                            Navigator.of(context)
                                                .restorablePushReplacementNamed(
                                                    HomePage.routeName);
                                          }
                                        } catch (e) {
                                          if (context.mounted) {
                                            showSnackbarOnScreen(
                                                context, "Failed to save name");
                                          }
                                        } finally {
                                          if (mounted) {
                                            setState(() {
                                              isProcessing = false;
                                            });
                                          }
                                        }
                                      }
                                    },
                              child: Container(
                                height: 48,
                                alignment: Alignment.center,
                                child: Container(
                                  height: 48,
                                  alignment: Alignment.center,
                                  child: isProcessing
                                      ? const SpinningApoorv()
                                      : const Text(
                                          'Continue',
                                          style: TextStyle(fontSize: 20),
                                          textAlign: TextAlign.center,
                                        ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Padding(
                          padding: EdgeInsets.only(
                              bottom: MediaQuery.of(context).viewInsets.bottom))
                    ],
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}
