import 'dart:async';

import 'package:apoorv_app/providers/user_info_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../constants.dart';
import '../../../widgets/dialog.dart';
import '../../../widgets/signup-flow/logout.dart';
import '../../../widgets/spinning_apoorv.dart';

class Profile2Screen extends StatefulWidget {
  static const routeName = '/profile-2';
  const Profile2Screen({super.key});

  @override
  State<Profile2Screen> createState() => _Profile2ScreenState();
}

class _Profile2ScreenState extends State<Profile2Screen> {
  Future<Map<String, dynamic>>? _myFuture;

  @override
  void initState() {
    super.initState();
    _updateProfileData();
  }

  Future<void> _updateProfileData() async {
    setState(() {
      _myFuture =
          Provider.of<UserProvider>(context, listen: false).getUserInfo();
    });
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
        future: _myFuture,
        builder: (BuildContext ctx, AsyncSnapshot snapshot) {
          switch (snapshot.connectionState) {
            case ConnectionState.waiting:
              return const Scaffold(body: Center(child: SpinningApoorv()));

            case ConnectionState.done:
            default:
              if (snapshot.hasError) {
                var message =
                    "There was a connection error! Check your connection and try again";

                Future.delayed(
                    const Duration(seconds: 1),
                    () {
                      if (!context.mounted) return;
                      dialogBuilder(context, message: message, function: () {
                        _updateProfileData();
                        Navigator.of(context).pop();
                      });
                    });

                return const Scaffold(body: Center(child: SpinningApoorv()));
              } else if (snapshot.hasData) {
                if (snapshot.data['error'] != null) {
                  var message = snapshot.data['error'];

                  Future.delayed(
                      const Duration(seconds: 1),
                      () {
                        if (!context.mounted) return;
                        dialogBuilder(context, message: message,
                                function: () {
                          _updateProfileData();
                          Navigator.of(context).pop();
                        });
                      });

                  return const Scaffold(body: Center(child: SpinningApoorv()));
                }
                if (snapshot.data['success']) {
                  Provider.of<UserProvider>(ctx);
                  var providerContext = ctx.read<UserProvider>();

                  return Scaffold(
                    floatingActionButton: FloatingActionButton(
                      heroTag: null,
                      onPressed: () => _updateProfileData(),
                      child: const Icon(Icons.refresh_rounded),
                    ),
                    body: Container(
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Constants.gradientHigh,
                            Constants.gradientLow
                          ],
                          begin: Alignment.topCenter,
                          end: Alignment.center,
                        ),
                      ),
                      child: SafeArea(
                        child: SingleChildScrollView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          child: Column(
                            children: [
                              // Top section with profile info
                              Padding(
                                padding: EdgeInsets.all(
                                    MediaQuery.of(ctx).size.width * 0.05),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    const SizedBox(height: 20),
                                    // Profile Picture - smaller size
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(60),
                                      child: (providerContext.profilePhotoUrl !=
                                                  null &&
                                              providerContext
                                                  .profilePhotoUrl!.isNotEmpty)
                                          ? Image.network(
                                              providerContext.profilePhotoUrl!,
                                              height: 120,
                                              width: 120,
                                              fit: BoxFit.cover,
                                              errorBuilder:
                                                  (context, error, stackTrace) {
                                                return Container(
                                                  height: 120,
                                                  width: 120,
                                                  color: Constants.yellowColor,
                                                  alignment: Alignment.center,
                                                  child: Text(
                                                    providerContext
                                                            .userName.isNotEmpty
                                                        ? providerContext
                                                            .userName[0]
                                                            .toUpperCase()
                                                        : '?',
                                                    style: const TextStyle(
                                                      fontSize: 48,
                                                      fontWeight: FontWeight.bold,
                                                      color: Constants.blackColor,
                                                    ),
                                                  ),
                                                );
                                              },
                                            )
                                          : Container(
                                              height: 120,
                                              width: 120,
                                              color: Constants.yellowColor,
                                              alignment: Alignment.center,
                                              child: Text(
                                                providerContext
                                                        .userName.isNotEmpty
                                                    ? providerContext.userName[0]
                                                        .toUpperCase()
                                                    : '?',
                                                style: const TextStyle(
                                                  fontSize: 48,
                                                  fontWeight: FontWeight.bold,
                                                  color: Constants.blackColor,
                                                ),
                                              ),
                                            ),
                                    ),
                                    const SizedBox(height: 16),
                                    // Name
                                    Text(
                                      providerContext.userName,
                                      style: const TextStyle(
                                        color: Constants.blackColor,
                                        fontSize: 24,
                                        fontWeight: FontWeight.bold,
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                    const SizedBox(height: 4),
                                    // College
                                    Text(
                                      providerContext.userCollegeName,
                                      style: const TextStyle(
                                        color: Constants.blackColor,
                                        fontSize: 16,
                                        fontWeight: FontWeight.w500,
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                  ],
                                ),
                              ),

                              // Bottom section with details
                              Container(
                                width: double.infinity,
                                decoration: const BoxDecoration(
                                  color: Constants.blackColor,
                                  borderRadius: BorderRadius.only(
                                    topLeft: Radius.circular(24),
                                    topRight: Radius.circular(24),
                                  ),
                                ),
                                padding: EdgeInsets.all(
                                    MediaQuery.of(context).size.width * 0.05),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      "PROFILE DETAILS",
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 19,
                                      ),
                                    ),
                                    const SizedBox(height: 24),

                                    // Email
                                    _buildDetailItem(
                                      "Email",
                                      providerContext.userEmail,
                                      Icons.email_outlined,
                                    ),

                                    const SizedBox(height: 16),

                                    // Phone
                                    _buildDetailItem(
                                      "Phone",
                                      providerContext.userPhNo,
                                      Icons.phone_outlined,
                                    ),

                                    // Roll Number (if applicable)
                                    if (providerContext.fromCollege &&
                                        (providerContext.userRollNo ?? '')
                                            .trim()
                                            .isNotEmpty) ...[
                                      const SizedBox(height: 16),
                                      _buildDetailItem(
                                        "Roll Number",
                                        providerContext.userRollNo!,
                                        Icons.badge_outlined,
                                      ),
                                    ],

                                    const SizedBox(height: 16),

                                    // College
                                    _buildDetailItem(
                                      "College",
                                      providerContext.userCollegeName,
                                      Icons.school_outlined,
                                    ),

                                    const SizedBox(height: 32),

                                    // Logout Button
                                    const SizedBox(
                                      width: double.infinity,
                                      child: LogoutButton(),
                                    ),

                                    const SizedBox(height: 20),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                } else {
                  return Center(child: Text(snapshot.data['message']));
                }
              } else {
                return const Scaffold(body: Center(child: SpinningApoorv()));
              }
          }
        });
  }

  Widget _buildDetailItem(String label, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[900],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(
            icon,
            color: Constants.yellowColor,
            size: 24,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    color: Colors.grey,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}