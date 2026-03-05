import 'package:apoorv_app/api.dart';
import 'package:apoorv_app/widgets/spinning_apoorv.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:custom_refresh_indicator/custom_refresh_indicator.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:math';

import '../../../providers/user_info_provider.dart';
import '../../../widgets/points-widget/leaderboard_card.dart';
import 'package:apoorv_app/constants.dart';
import '../../../widgets/points-widget/winner.dart';
import '../../../widgets/snackbar.dart';

class Leaderboard extends StatefulWidget {
  static const routeName = '/leaderboard';
  const Leaderboard({super.key});

  @override
  State<Leaderboard> createState() => _LeaderboardState();
}

class _LeaderboardState extends State<Leaderboard> {
  Future<Map<String, dynamic>>? _myFuture;

  Future<void> _seedLeaderboardAndTransactions() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        if (!mounted) return;
        showSnackbarOnScreen(context, 'Not signed in');
        return;
      }

      final rnd = Random();
      final now = DateTime.now();
      final seedTag = now.millisecondsSinceEpoch.toString();

      final myUid = user.uid;
      final myEmail = (user.email ?? '').trim();

      String myName = (context.read<UserProvider>().userName).trim();
      if (myName.isEmpty || myName == 'Your Name') {
        // Try to read from Firestore if provider hasn't been populated yet.
        final meSnap = await FirebaseFirestore.instance
            .collection('users')
            .doc(myUid)
            .get();
        final me = meSnap.data();
        final n = (me == null) ? null : (me['name'] as String?);
        if (n != null && n.trim().isNotEmpty) myName = n.trim();
      }

      // 1) Seed users
      const seedUserCount = 25;
      final seeded = <Map<String, String>>[]; // {uid, name, email}

      final batch = FirebaseFirestore.instance.batch();
      for (var i = 0; i < seedUserCount; i++) {
        final idx = (i + 1).toString().padLeft(2, '0');
        final uid = 'debug_${seedTag}_$idx';
        final name = 'Test User $idx';
        final email = 'test$idx@iiitkottayam.ac.in';
        final emailLocalPart = 'test$idx';
        final rollNumber = '2025TST${(i + 1).toString().padLeft(4, '0')}';
        final points = rnd.nextInt(1001); // 0..1000

        seeded.add({'uid': uid, 'name': name, 'email': email});

        batch.set(
          FirebaseFirestore.instance.collection('users').doc(uid),
          {
            'uid': uid,
            'email': email,
            'emailLocalPart': emailLocalPart,
            'rollNumber': rollNumber,
            'photoUrl': 'https://i.pravatar.cc/200?u=$uid',
            'phone': '',
            'fromCollege': true,
            'collegeName': 'IIIT Kottayam',
            'points': points,
            'name': name,
            'nameLower': name.toLowerCase(),
            'createdAt': FieldValue.serverTimestamp(),
            'lastLogin': FieldValue.serverTimestamp(),
          },
          SetOptions(merge: true),
        );
      }

      // 2) Seed transactions as individual docs in `transactions/*`.
      // Store uid/email for both sides so we can debug logs later.
      const txnCount = 18;
      for (var i = 0; i < txnCount; i++) {
        final other = seeded[rnd.nextInt(seeded.length)];
        final debit = rnd.nextBool();
        final amount = rnd.nextInt(200) + 1;
        final updatedAt = Timestamp.fromDate(now.subtract(Duration(minutes: i * 13)));

        final fromUid = debit ? myUid : other['uid']!;
        final toUid = debit ? other['uid']! : myUid;
        final fromName = debit ? myName : other['name']!;
        final toName = debit ? other['name']! : myName;
        final fromEmail = debit ? myEmail : other['email']!;
        final toEmail = debit ? other['email']! : myEmail;

        final docRef = FirebaseFirestore.instance.collection('transactions').doc();
        batch.set(docRef, {
          'from': fromUid,
          'to': toUid,
          // Query helpers
          'involvedPartiesUids': [fromUid, toUid],
          'involvedPartiesEmails': [
            fromEmail.trim().toLowerCase(),
            toEmail.trim().toLowerCase(),
          ],
          // Display/debug fields
          'fromName': fromName,
          'toName': toName,
          'fromEmail': fromEmail,
          'toEmail': toEmail,
          'transactionValue': amount,
          'updatedAt': updatedAt,
          'type': 'seed',
        });
      }

      await batch.commit();

      if (!mounted) return;
      showSnackbarOnScreen(context, 'Seeded $seedUserCount users + $txnCount txns');
      await getLeaderboardUpdates();
    } catch (e) {
      if (!mounted) return;
      showSnackbarOnScreen(context, 'Seeding failed: $e');
    }
  }

  @override
  void initState() {
    super.initState();
    getLeaderboardUpdates();
  }

  Future<void> getLeaderboardUpdates() async {
    await Future.delayed(
      const Duration(seconds: 2),
      () {
        var s = "";
      },
    );
    setState(() {
      _myFuture =
          APICalls().getLeaderboard(context.read<UserProvider>().idToken);
    });
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
        future: _myFuture,
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
                return Scaffold(
                  body: Center(child: Text(snapshot.error.toString())),
                );
              } else if (snapshot.hasData) {
                // print(snapshot.data);
                if (snapshot.data['success']) {
                  var providerContext = context.read<UserProvider>();

                  var data = snapshot.data['results'] as List;

                  if (data.length == 1) {
                    Future.delayed(
                        Duration.zero,
                        () => showSnackbarOnScreen(
                            context, "Looks like you are the only one here!"));
                  }
                  if (data[0]['uid'] == providerContext.uid) {
                    Future.delayed(
                        Duration.zero,
                        () => showSnackbarOnScreen(
                            context, "Congrats, you are the top of the board"));
                  }

                  return Scaffold(
                    backgroundColor: const Color.fromRGBO(18, 18, 18, 1),
                    floatingActionButton: kDebugMode
                        ? FloatingActionButton.small(
                            onPressed: () => _seedLeaderboardAndTransactions(),
                            child: const Icon(Icons.casino_rounded),
                          )
                        : null,
                    body: CustomMaterialIndicator(
                      indicatorBuilder: (context, controller) =>
                          Image.asset("assets/images/phoenix_74.png"),
                      onRefresh: () => getLeaderboardUpdates(),
                      child: SingleChildScrollView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        child: SizedBox(
                          height: MediaQuery.of(context).size.height,
                          child: SafeArea(
                              child: Column(
                            children: [
                              Container(
                                decoration: const BoxDecoration(
                                  borderRadius: BorderRadius.only(
                                    bottomRight: Radius.circular(20),
                                    bottomLeft: Radius.circular(20),
                                  ),
                                  gradient: LinearGradient(
                                    colors: [
                                      Constants.gradientHigh,
                                      Constants.gradientMid,
                                    ],
                                    begin: Alignment.topCenter,
                                    end: Alignment.bottomCenter,
                                  ),
                                ),
                                padding: const EdgeInsets.all(20.0),
                                width: MediaQuery.of(context).size.width,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    InkWell(
                                      child: const Icon(
                                        Icons.arrow_back_outlined,
                                        size: 30,
                                        color: Colors.black,
                                      ),
                                      onTap: () {
                                        Navigator.pop(context);
                                      },
                                    ),
                                    const Text(
                                      "Leaderboard",
                                      style: TextStyle(
                                        color: Colors.black,
                                        fontSize: 24,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                    Constants.gap,
                                    const Text(
                                      "The leaderboard will be displayed until the auction starts",
                                      style: TextStyle(
                                          color: Colors.black,
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600),
                                    ),
                                    const Text(
                                      "Please refresh the page to update the leaderboard",
                                      style: TextStyle(
                                        color: Colors.black,
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(
                                height: 20,
                              ),
                              if (data.isEmpty)
                                const Center(child: Text("No winner's yet")),
                              Center(
                                  child: Winner(
                                image: data[0]['profileImage'],
                                name: data[0]['fullName'],
                                points: data[0]['points'],
                                uid: data[0]['uid'],
                                email: data[0]['email'],
                              )),
                              Expanded(
                                child: Padding(
                                  padding: EdgeInsets.symmetric(
                                    horizontal:
                                        MediaQuery.of(context).size.width *
                                            0.03,
                                  ),
                                  child: ListView.builder(
                                    itemBuilder: (context, i) =>
                                        LeaderboardCard(
                                      name: data[i + 1]['fullName'],
                                      image: data[i + 1]['profileImage'],
                                      points: data[i + 1]['points'],
                                      rank: i + 2,
                                      uid: data[i + 1]['uid'],
                                      email: data[i + 1]['email'],
                                    ),
                                    itemCount: data.length - 1,
                                  ),
                                ),
                              ),
                            ],
                          )),
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
}
