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
  final ScrollController _scrollController = ScrollController();

  final List<Map<String, dynamic>> _users = [];
  DocumentSnapshot<Map<String, dynamic>>? _lastDocument;
  bool _hasMore = true;
  bool _isLoadingInitial = true;
  bool _isLoadingMore = false;
  String? _error;

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
      await _refresh();
    } catch (e) {
      if (!mounted) return;
      showSnackbarOnScreen(context, 'Seeding failed: $e');
    }
  }

  @override
  void initState() {
    super.initState();

    _scrollController.addListener(() {
      if (!_hasMore || _isLoadingMore || _isLoadingInitial) return;
      if (!_scrollController.hasClients) return;

      final pos = _scrollController.position;
      // Load next page when close to bottom.
      if (pos.pixels >= pos.maxScrollExtent - 300) {
        _fetchMore();
      }
    });

    _refresh();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _refresh() async {
    setState(() {
      _error = null;
      _users.clear();
      _lastDocument = null;
      _hasMore = true;
      _isLoadingInitial = true;
    });

    final page = await APICalls().getLeaderboardPage(limit: 25);
    if (!mounted) return;

    if (page['success'] == true) {
      setState(() {
        _users.addAll((page['results'] as List).cast<Map<String, dynamic>>());
        _lastDocument = page['lastDocument'] as DocumentSnapshot<Map<String, dynamic>>?;
        _hasMore = (page['hasMore'] as bool?) ?? false;
        _isLoadingInitial = false;
      });
    } else {
      setState(() {
        _error = (page['error'] ?? 'Failed to fetch leaderboard').toString();
        _isLoadingInitial = false;
      });
    }
  }

  Future<void> _fetchMore() async {
    if (!_hasMore || _isLoadingMore) return;
    setState(() {
      _isLoadingMore = true;
      _error = null;
    });

    final page = await APICalls().getLeaderboardPage(
      lastDocument: _lastDocument,
      limit: 25,
    );

    if (!mounted) return;

    if (page['success'] == true) {
      setState(() {
        _users.addAll((page['results'] as List).cast<Map<String, dynamic>>());
        _lastDocument = page['lastDocument'] as DocumentSnapshot<Map<String, dynamic>>?;
        _hasMore = (page['hasMore'] as bool?) ?? false;
        _isLoadingMore = false;
      });
    } else {
      setState(() {
        _error = (page['error'] ?? 'Failed to fetch more').toString();
        _isLoadingMore = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final providerContext = context.read<UserProvider>();

    if (_users.length == 1) {
      Future.delayed(
          Duration.zero,
          () {
            if (!context.mounted) return;
            showSnackbarOnScreen(
                context, "Looks like you are the only one here!");
          });
    }
    if (_users.isNotEmpty && _users[0]['uid'] == providerContext.uid) {
      Future.delayed(
          Duration.zero,
          () {
            if (!context.mounted) return;
            showSnackbarOnScreen(
                context, "Congrats, you are the top of the board");
          });
    }

    return Scaffold(
      backgroundColor: const Color.fromRGBO(18, 18, 18, 1),
      floatingActionButton: kDebugMode
          ? FloatingActionButton.small(
              heroTag: null,
              onPressed: () => _seedLeaderboardAndTransactions(),
              child: const Icon(Icons.casino_rounded),
            )
          : null,
      body: CustomMaterialIndicator(
        indicatorBuilder: (context, controller) =>
            Image.asset("assets/images/phoenix_74.png"),
        onRefresh: () => _refresh(),
        child: SafeArea(
          child: CustomScrollView(
            controller: _scrollController,
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              SliverToBoxAdapter(
                child: Container(
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
                        "Pull to refresh to update the leaderboard",
                        style: TextStyle(
                          color: Colors.black,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              if (_isLoadingInitial)
                const SliverFillRemaining(
                  hasScrollBody: false,
                  child: Center(
                    child: SpinningApoorv(),
                  ),
                )
              else if (_error != null)
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: Center(
                    child: Text(
                      _error!,
                      style: const TextStyle(color: Colors.white),
                      textAlign: TextAlign.center,
                    ),
                  ),
                )
              else ...[
                const SliverToBoxAdapter(child: SizedBox(height: 20)),
                if (_users.isEmpty)
                  const SliverToBoxAdapter(
                    child: Center(
                      child: Text(
                        "No winner's yet",
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                  )
                else ...[
                  SliverToBoxAdapter(
                    child: Center(
                      child: Winner(
                        image: _users[0]['profileImage'],
                        name: _users[0]['fullName'],
                        points: _users[0]['points'],
                        uid: _users[0]['uid'],
                        email: _users[0]['email'],
                      ),
                    ),
                  ),
                  const SliverToBoxAdapter(child: SizedBox(height: 10)),
                  SliverPadding(
                    padding: EdgeInsets.symmetric(
                      horizontal: MediaQuery.of(context).size.width * 0.03,
                    ),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, i) {
                          final idx = i + 1;
                          final u = _users[idx];
                          return LeaderboardCard(
                            name: u['fullName'],
                            image: u['profileImage'],
                            points: u['points'],
                            rank: idx + 1,
                            uid: u['uid'],
                            email: u['email'],
                          );
                        },
                        childCount: (_users.length > 1) ? (_users.length - 1) : 0,
                      ),
                    ),
                  ),
                ],

                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    child: Center(
                      child: _isLoadingMore
                          ? const SizedBox(
                              height: 32,
                              width: 32,
                              child: CircularProgressIndicator(),
                            )
                          : (!_hasMore
                              ? const Text(
                                  'End of leaderboard',
                                  style: TextStyle(color: Colors.white70),
                                )
                              : const SizedBox.shrink()),
                    ),
                  ),
                ),
              ]
            ],
          ),
        ),
      ),
    );
  }
}
