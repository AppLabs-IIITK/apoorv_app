import 'package:apoorv_app/widgets/snackbar.dart';
import 'package:apoorv_app/widgets/spinning_apoorv.dart';
import 'package:provider/provider.dart';

import '../../constants.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../providers/user_info_provider.dart';
import 'letsgo.dart';

class SignUpScreen extends StatefulWidget {
  static const routeName = '/sign-up';
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final TextEditingController userNameController = TextEditingController();
  final TextEditingController userPhNoController = TextEditingController();
  final TextEditingController userRollNoController = TextEditingController();
  final TextEditingController userCollegeNameController =
      TextEditingController();

  final _formKey = GlobalKey<FormState>();

  bool isProcessing = false;

  @override
  void dispose() {
    userNameController.dispose();
    userRollNoController.dispose();
    userCollegeNameController.dispose();
    userPhNoController.dispose();
    super.dispose();
  }

  bool isChecked = true;

  bool popStatus = true;
  int popCount = 0;

  @override
  void initState() {
    super.initState();
    Provider.of<UserProvider>(context, listen: false)
        .refreshGoogleServiceData();
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
                                controller: userPhNoController,
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return "Phone number is required";
                                  } else if (value.length != 10) {
                                    return "Phone number must be exactly 10 digits long";
                                  }
                                  return null;
                                },
                                keyboardType: TextInputType.phone,
                                inputFormatters: [
                                  LengthLimitingTextInputFormatter(10),
                                  FilteringTextInputFormatter.digitsOnly,
                                ],
                                decoration: InputDecoration(
                                  border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(16)),
                                  filled: true,
                                  fillColor: Constants.yellowColor,
                                  hintText: 'Phone Number',
                                  hintStyle:
                                      const TextStyle(color: Colors.black),
                                )),
                            Constants.gap,
                            if (isChecked)
                              Column(
                                children: [
                                  TextFormField(
                                      controller: userRollNoController,
                                      validator: (value) {
                                        if (value == null ||
                                            value.isEmpty ||
                                            !RegExp(r"(2021|2022|2023|2024|2025)(bcs|bec|bcy|bcd)0\d{3}")
                                                .hasMatch(
                                                    value.toLowerCase())) {
                                          return "You know the format";
                                        }
                                        return null;
                                      },
                                      decoration: InputDecoration(
                                        border: OutlineInputBorder(
                                            borderSide:
                                                const BorderSide(width: 50),
                                            borderRadius:
                                                BorderRadius.circular(16)),
                                        filled: true,
                                        fillColor: Constants.yellowColor,
                                        hintText: 'Roll Number',
                                        hintStyle: const TextStyle(
                                            color: Colors.black),
                                      )),
                                  Constants.gap,
                                ],
                              ),
                            if (!isChecked)
                              Column(
                                children: [
                                  TextFormField(
                                      controller: userCollegeNameController,
                                      validator: (value) {
                                        if (value == null || value.isEmpty) {
                                          return "Fill your college name!";
                                        }
                                        return null;
                                      },
                                      decoration: InputDecoration(
                                        border: OutlineInputBorder(
                                            borderRadius:
                                                BorderRadius.circular(16)),
                                        filled: true,
                                        fillColor: Constants.yellowColor,
                                        hintText: "College Name",
                                        hintStyle: const TextStyle(
                                            color: Colors.black),
                                      )),
                                  Constants.gap,
                                ],
                              ),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Transform.scale(
                                  scale: 1.2,
                                  child: Checkbox(
                                    fillColor: isChecked? MaterialStateProperty.all(Constants.redColor): MaterialStateProperty.all(Colors.transparent),
                                    checkColor: Colors.white,
                                    value: isChecked,
                                    onChanged: (bool? value) {
                                      userCollegeNameController.clear();
                                      userRollNoController.clear();
                                      setState(() {
                                        isChecked = value!;
                                      });
                                    },
                                  ),
                                ),
                                const Text(
                                    style: TextStyle(fontSize: 17),
                                    "From IIIT Kottayam"),
                              ],
                            ),
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
                                      Map<String, Object> args;
                                      if (_formKey.currentState!.validate()) {
                                        userProvider.fromCollege = isChecked;
                                        if (isChecked) {
                                          userProvider.changeSameCollegeDetails(
                                              newUserName:
                                                  userNameController.text,
                                              newUserRollNo:
                                                  userRollNoController.text,
                                              newUserPhNo:
                                                  userPhNoController.text);
                                        } else {
                                          userProvider
                                              .changeOtherCollegeDetails(
                                            newUserName:
                                                userNameController.text,
                                            newUserCollegeName:
                                                userCollegeNameController.text,
                                            newUserPhNo:
                                                userPhNoController.text,
                                          );
                                        }
                                        // ScaffoldMessenger.of(context).showSnackBar(
                                        //   const SnackBar(content: Text('Logging In')),
                                        //   );
                                        if (isChecked) {
                                          args = {
                                            'fromCollege': isChecked,
                                            'role': "user",
                                            'fullName': userNameController.text,
                                            'rollNumber':
                                                userRollNoController.text,
                                            'phone': userPhNoController.text,
                                            'collegeName': 'IIIT Kottayam',
                                            'email': context
                                                .read<UserProvider>()
                                                .userEmail,
                                          };
                                        } else {
                                          args = {
                                            'fromCollege': isChecked,
                                            'role': "user",
                                            'fullName': userNameController.text,
                                            'phone': userPhNoController.text,
                                            'collegeName':
                                                userCollegeNameController.text,
                                            'email': context
                                                .read<UserProvider>()
                                                .userEmail,
                                          };
                                        }

                                        // print(args);
                                        var response =
                                            await Provider.of<UserProvider>(
                                                    context,
                                                    listen: false)
                                                .uploadUserData(args);

                                        if (context.mounted) {
                                          if (response['success']) {
                                            showSnackbarOnScreen(
                                                context, response['message']);

                                            Navigator.of(context)
                                                .restorablePushReplacementNamed(
                                                    LetsGoPage.routeName);
                                          } else {
                                            showSnackbarOnScreen(
                                                context, response['error']);
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
