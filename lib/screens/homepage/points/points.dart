import 'dart:async';

import 'package:apoorv_app/providers/user_info_provider.dart';
import 'package:provider/provider.dart';
import '../../../widgets/dialog.dart';
import 'package:flutter/material.dart';

import '../../../constants.dart';
import '../../../widgets/spinning_apoorv.dart';
import 'leaderboard.dart';
import 'carnival_games.dart';

StreamController<bool> st = StreamController<bool>.broadcast();

class PointsScreen extends StatefulWidget {
  static const routeName = '/points';
  final Stream<bool>? stream;
  const PointsScreen({this.stream, super.key});

  @override
  State<PointsScreen> createState() => _PointsScreenState();
}

class _PointsScreenState extends State<PointsScreen> {
  Future<Map<String, dynamic>>? myFuture;

  @override
  void initState() {
    super.initState();
    getUserInfo();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<UserProvider>().ensureShopkeeperModeLoaded();
    });
    if (widget.stream != null) {
      widget.stream!.listen((event) {
        if (event) {
          getUserInfo();
        }
      });
    }
  }

  Future<void> getUserInfo() async {
    Provider.of<UserProvider>(context, listen: false).getUserInfo();
    if (context.mounted) {
      setState(() {
        myFuture = Future.value({'success': true});
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
        future: myFuture,
        builder: (BuildContext context, AsyncSnapshot snapshot) {
          switch (snapshot.connectionState) {
            case ConnectionState.waiting:
              return const Scaffold(
                body: Center(
                  child: SpinningApoorv(),
                ),
              );

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
                        getUserInfo();
                        Navigator.of(context).pop();
                      });
                    });

                return const Scaffold(body: Center(child: SpinningApoorv()));
              } else if (snapshot.hasData) {
                if (snapshot.data['success']) {
                  Provider.of<UserProvider>(context);

                  return Scaffold(
                    floatingActionButton: FloatingActionButton(
                      heroTag: null,
                      onPressed: () => getUserInfo(),
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
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            // Points Display - REMOVED
                            const SizedBox(height: 40),
                            Constants.gap,
                            // Bottom Section
                            Flexible(
                              child: Container(
                                alignment: Alignment.center,
                                decoration: const BoxDecoration(
                                  color: Constants.blackColor,
                                  borderRadius: BorderRadius.only(
                                    topLeft: Radius.circular(24),
                                    topRight: Radius.circular(24),
                                  ),
                                ),
                                padding: EdgeInsets.all(
                                    MediaQuery.of(context).size.width * 0.05),
                                child: SingleChildScrollView(
                                  physics: const AlwaysScrollableScrollPhysics(),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                    children: [
                                      // Carnival Games Card
                                      Container(
                                        width: MediaQuery.of(context).size.width,
                                        padding: const EdgeInsets.all(20),
                                        decoration: BoxDecoration(
                                          gradient: const LinearGradient(
                                            colors: [
                                              Constants.gradientHigh,
                                              Constants.gradientLow,
                                            ],
                                            begin: Alignment.topLeft,
                                            end: Alignment.bottomRight,
                                          ),
                                          borderRadius: BorderRadius.circular(16),
                                        ),
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            const Row(
                                              children: [
                                                Icon(
                                                  Icons.games,
                                                  color: Constants.blackColor,
                                                  size: 28,
                                                ),
                                                SizedBox(width: 12),
                                                Text(
                                                  "🎯 Carnival Games",
                                                  style: TextStyle(
                                                    fontSize: 20,
                                                    fontWeight: FontWeight.bold,
                                                    color: Constants.blackColor,
                                                  ),
                                                ),
                                              ],
                                            ),
                                            const SizedBox(height: 12),
                                            const Text(
                                              "Step into the Apoorv Carnival and play exciting mini games! Win prizes and compete with friends.",
                                              style: TextStyle(
                                                fontSize: 15,
                                                color: Constants.blackColor,
                                              ),
                                            ),
                                            const SizedBox(height: 16),
                                            SizedBox(
                                              width: double.infinity,
                                              child: ElevatedButton(
                                                onPressed: () {
                                                  Navigator.pushNamed(
                                                    context,
                                                    CarnivalGamesScreen.routeName,
                                                  );
                                                },
                                                style: ElevatedButton.styleFrom(
                                                  backgroundColor: Constants.blackColor,
                                                  foregroundColor: Constants.yellowColor,
                                                  shape: RoundedRectangleBorder(
                                                    borderRadius: BorderRadius.circular(12),
                                                  ),
                                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                                ),
                                                child: const Row(
                                                  mainAxisAlignment: MainAxisAlignment.center,
                                                  children: [
                                                    Icon(Icons.launch, size: 20),
                                                    SizedBox(width: 8),
                                                    Text(
                                                      "Play Carnival Games",
                                                      style: TextStyle(
                                                        fontSize: 16,
                                                        fontWeight: FontWeight.bold,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(height: 24),
                                      // Leaderboard Button
                                      SizedBox(
                                        width: MediaQuery.of(context).size.width,
                                        child: ElevatedButton(
                                          onPressed: () {
                                            Navigator.pushNamed(
                                              context,
                                              Leaderboard.routeName,
                                            );
                                          },
                                          style: ElevatedButton.styleFrom(
                                            shape: RoundedRectangleBorder(
                                              borderRadius: BorderRadius.circular(24),
                                            ),
                                            padding: const EdgeInsets.symmetric(vertical: 16),
                                          ),
                                          child: const Row(
                                            mainAxisAlignment: MainAxisAlignment.center,
                                            children: [
                                              Icon(Icons.leaderboard, size: 24),
                                              SizedBox(width: 12),
                                              Text(
                                                "View Leaderboard",
                                                style: TextStyle(
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                      const SizedBox(height: 20),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                } else {
                  final msg = (snapshot.data['message'] ??
                          snapshot.data['error'] ??
                          'Failed to load')
                      .toString();
                  return Center(child: Text(msg));
                }
              } else {
                return const Scaffold(body: Center(child: SpinningApoorv()));
              }
          }
        });
  }
}