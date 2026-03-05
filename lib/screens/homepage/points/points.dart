import 'dart:async';

import 'package:apoorv_app/api.dart';
import 'package:apoorv_app/providers/receiver_provider.dart';
import 'package:apoorv_app/providers/user_info_provider.dart';
import 'package:apoorv_app/screens/homepage/Transactions/payment.dart';
import 'package:apoorv_app/screens/homepage/points/all_transactions.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import '../../../widgets/dialog.dart';
import '../../../widgets/points-widget/qr/generate_qr.dart';
import '../../../widgets/points-widget/qr/scan_qr.dart';
import 'package:flutter/material.dart';

import '../../../constants.dart';
import '../../../widgets/spinning_apoorv.dart';
import 'leaderboard.dart';

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

  final searchController = TextEditingController();
  bool searchFocus = false;
  FocusNode searchFocusNode = FocusNode();

  Map<String, dynamic>? _searchResults = {
    'success': false,
    'results': null,
  };

  Timer? timer;

  @override
  void initState() {
    super.initState();
    getTransactionHistory();
    if (widget.stream != null) {
      widget.stream!.listen((event) {
        if (event) {
          getTransactionHistory();
        }
      });
    }
  }

  @override
  void dispose() {
    searchController.dispose();
    timer?.cancel();
    super.dispose();
  }

  Future<void> getTransactionHistory() async {
    Provider.of<UserProvider>(context, listen: false).getUserInfo();
    if (context.mounted) {
      setState(() {
        myFuture = Provider.of<UserProvider>(context, listen: false)
            .getLatest2Transactions();
      });
    }
  }

  void _showTransactionDetails(Map<String, dynamic> txn) async {
    final fromUid = txn['from']?.toString() ?? '';
    final toUid = txn['to']?.toString() ?? '';
    final fromName = txn['fromName']?.toString() ?? 'Unknown';
    final toName = txn['toName']?.toString() ?? 'Unknown';
    final fromEmail = txn['fromEmail']?.toString() ?? '';
    final toEmail = txn['toEmail']?.toString() ?? '';
    final points = txn['transactionValue'] as int? ?? 0;
    final formattedTime = txn['formattedTime']?.toString() ?? '';

    final myUid = FirebaseAuth.instance.currentUser?.uid;

    // Fetch profile images
    String fromImage = '';
    String toImage = '';

    try {
      final fromDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(fromUid)
          .get();
      fromImage = (fromDoc.data()?['photoUrl'] as String?)?.trim() ?? '';
    } catch (_) {}

    try {
      final toDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(toUid)
          .get();
      toImage = (toDoc.data()?['photoUrl'] as String?)?.trim() ?? '';
    } catch (_) {}

    if (!mounted) return;

    showModalBottomSheet(
      context: context,
      backgroundColor: const Color.fromRGBO(18, 18, 18, 1),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Transaction Details',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Constants.yellowColor,
              ),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  '$points',
                  style: const TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: Constants.yellowColor,
                  ),
                ),
                const SizedBox(width: 8),
                const Text(
                  'Points',
                  style: TextStyle(
                    fontSize: 20,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              formattedTime,
              style: const TextStyle(
                fontSize: 14,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: _buildProfileCard(
                    context: context,
                    uid: fromUid,
                    name: fromName,
                    email: fromEmail,
                    profileImage: fromImage,
                    label: 'From',
                    isCurrentUser: fromUid == myUid,
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 12),
                  child: Icon(
                    Icons.arrow_forward,
                    color: Constants.yellowColor,
                    size: 32,
                  ),
                ),
                Expanded(
                  child: _buildProfileCard(
                    context: context,
                    uid: toUid,
                    name: toName,
                    email: toEmail,
                    profileImage: toImage,
                    label: 'To',
                    isCurrentUser: toUid == myUid,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileCard({
    required BuildContext context,
    required String uid,
    required String name,
    required String email,
    required String profileImage,
    required String label,
    required bool isCurrentUser,
  }) {
    return InkWell(
      onTap: isCurrentUser
          ? null
          : () {
              Navigator.pop(context);
              Navigator.pushNamed(
                context,
                '/payment',
                arguments: {
                  'uid': uid,
                  'fullName': name,
                  'email': email,
                  'profileImage': profileImage,
                  'fromSearch': true,
                },
              );
            },
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isCurrentUser
              ? Constants.redColor.withOpacity(0.2)
              : Constants.silverColor.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isCurrentUser ? Constants.redColor : Constants.silverColor,
            width: 2,
          ),
        ),
        child: Column(
          children: [
            Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                color: Colors.grey,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            profileImage.isNotEmpty
                ? CircleAvatar(
                    radius: 30,
                    backgroundImage: NetworkImage(profileImage),
                    onBackgroundImageError: (_, __) {},
                    child: profileImage.isEmpty
                        ? Text(
                            name.isNotEmpty ? name[0].toUpperCase() : '?',
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Constants.blackColor,
                            ),
                          )
                        : null,
                  )
                : CircleAvatar(
                    radius: 30,
                    backgroundColor: Constants.yellowColor,
                    child: Text(
                      name.isNotEmpty ? name[0].toUpperCase() : '?',
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Constants.blackColor,
                      ),
                    ),
                  ),
            const SizedBox(height: 8),
            Text(
              name,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            if (email.isNotEmpty)
              Text(
                email,
                style: const TextStyle(
                  fontSize: 11,
                  color: Colors.grey,
                ),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            if (isCurrentUser)
              const Padding(
                padding: EdgeInsets.only(top: 4),
                child: Text(
                  '(You)',
                  style: TextStyle(
                    fontSize: 11,
                    color: Constants.redColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            if (!isCurrentUser)
              const Padding(
                padding: EdgeInsets.only(top: 4),
                child: Text(
                  'Tap to pay',
                  style: TextStyle(
                    fontSize: 11,
                    color: Constants.yellowColor,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
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
                    () =>
                        dialogBuilder(context, message: message, function: () {
                          getTransactionHistory();
                          Navigator.of(context).pop();
                        }));

                return const Scaffold(body: Center(child: SpinningApoorv()));
              } else if (snapshot.hasData) {
                if (snapshot.data['success']) {
                  Provider.of<UserProvider>(context);
                  var providerContext = context.read<UserProvider>();

                  return GestureDetector(
                    onTap: () {
                      FocusManager.instance.primaryFocus?.unfocus();
                      setState(() {
                        searchFocus = false;
                        _searchResults!['results'] = null;
                      });
                    },
                    child: Scaffold(
                      resizeToAvoidBottomInset: false,
                      floatingActionButton: FloatingActionButton(
                        heroTag: null,
                        onPressed: () => getTransactionHistory(),
                        child: const Icon(Icons.refresh_rounded),
                      ),
                      body: Container(
                        // height: MediaQuery.of(context).size.height -
                        //     kBottomNavigationBarHeight,
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
                        // color: Constants.yellowColor,
                        child: SafeArea(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Stack(
                                children: [
                                  if (searchFocus)
                                    Container(
                                        margin: EdgeInsets.symmetric(
                                            horizontal: MediaQuery.of(context)
                                                    .size
                                                    .width *
                                                0.033),
                                        decoration: BoxDecoration(
                                          color: Constants.blackColor,
                                          borderRadius:
                                              BorderRadius.circular(30),
                                        ),
                                        padding:
                                            const EdgeInsets.only(bottom: 16),
                                        width: double.infinity,
                                        child: Column(
                                          children: [
                                            const SizedBox(
                                              height: kToolbarHeight,
                                              width: double.infinity,
                                            ),
                                            if (_searchResults == null)
                                              const Text('Some error occured'),
                                            if (_searchResults != null &&
                                                _searchResults!['results'] ==
                                                    null)
                                              const Text(
                                                  "Enter name to search for"),
                                            if (_searchResults != null &&
                                                _searchResults!['results'] !=
                                                    null &&
                                                _searchResults!['results']
                                                    .isEmpty)
                                              const Text("No users found"),
                                            if (_searchResults != null &&
                                                _searchResults!['results'] !=
                                                    null &&
                                                _searchResults!['results']
                                                    ?.isNotEmpty)
                                              ListView.builder(
                                                shrinkWrap: true,
                                                itemBuilder: (context, i) =>
                                                    ListTile(
                                                  title: Text(
                                                      _searchResults!['results']
                                                          [i]['fullName']),
                                                  subtitle: Text(
                                                      _searchResults!['results']
                                                          [i]['email']),
                                                  trailing: Text(
                                                      '${_searchResults!['results'][i]['points']} pts'),
                                                  onTap: () {
                                                    final user = _searchResults!['results'][i];
                                                    Provider.of<ReceiverProvider>(
                                                            context,
                                                            listen: false)
                                                        .setReceiverDataFromSearch(user);
                                                    Navigator.of(context)
                                                        .pushNamed(Payment.routeName)
                                                        .then((value) {
                                                      searchController.clear();
                                                      FocusManager
                                                          .instance.primaryFocus
                                                          ?.unfocus();
                                                      _searchResults![
                                                          'results'] = null;
                                                      setState(() {
                                                        searchFocus = false;
                                                      });
                                                    });
                                                  },
                                                ),
                                                itemCount:
                                                    _searchResults!['results']
                                                        .length,
                                              )
                                          ],
                                        )),
                                  GestureDetector(
                                    onTap: () {
                                      setState(() {
                                        searchFocus = true;
                                        searchFocusNode.requestFocus();
                                      });
                                    },
                                    child: Container(
                                      margin: EdgeInsets.symmetric(
                                          horizontal: MediaQuery.of(context)
                                                  .size
                                                  .width *
                                              0.033),
                                      decoration: BoxDecoration(
                                        color: Constants.blackColor,
                                        // border: Border.all(
                                        //   color: Colors.white,
                                        // ),
                                        borderRadius: BorderRadius.circular(30),
                                      ),
                                      child: AbsorbPointer(
                                        child: TextField(
                                          autofocus: searchFocus,
                                          decoration: const InputDecoration(
                                              border: InputBorder.none,
                                              hintText: "Search Someone",
                                              prefixIcon: Icon(
                                                Icons.search,
                                                size: 30,
                                              )),
                                          style: const TextStyle(
                                              color: Colors.white),
                                          controller: searchController,
                                          focusNode: searchFocusNode,
                                          onChanged: (value) {
                                            if (value.isNotEmpty &&
                                                value.trim().isNotEmpty) {
                                              if (timer != null) {
                                                timer!.cancel();
                                                timer = null;
                                              }
                                              timer = Timer(
                                                const Duration(seconds: 1),
                                                () async {
                                                  var res = await APICalls()
                                                      .getUsersSearchList(
                                                    searchController.text
                                                        .trim(),
                                                    context
                                                        .read<UserProvider>()
                                                        .idToken,
                                                  );

                                                  setState(() {
                                                    if (res['success']) {
                                                      _searchResults![
                                                          'success'] = true;
                                                      _searchResults![
                                                              'results'] =
                                                          res['results'];
                                                    } else {
                                                      _searchResults = null;
                                                    }
                                                  });
                                                },
                                              );
                                            } else {
                                              if (timer != null) {
                                                timer!.cancel();
                                              }
                                              setState(() {
                                                _searchResults!['results'] =
                                                    null;
                                              });
                                            }
                                          },
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              // Constants.gap,
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  Text(
                                    context
                                        .read<UserProvider>()
                                        .points
                                        .toString(),
                                    style: const TextStyle(
                                      fontSize: 72,
                                      fontWeight: FontWeight.bold,
                                      color: Constants.blackColor,
                                    ),
                                  ),
                                  const Text(
                                    "Points",
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 36,
                                      color: Constants.blackColor,
                                    ),
                                  ),
                                ],
                              ),
                              Constants.gap,
                              Flexible(
                                child: Container(
                                  // Container(
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
                                    physics:
                                        const AlwaysScrollableScrollPhysics(),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceEvenly,
                                      children: [
                                        const Text(
                                          "LAST TRANSACTIONS",
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 19,
                                          ),
                                        ),
                                        if (providerContext
                                            .transactions.isEmpty) ...[
                                          Constants.gap,
                                          const Center(
                                            child: Text(
                                                "No transactions to show here"),
                                          ),
                                          // Constants.gap,
                                        ],
                                        if (providerContext
                                            .transactions.isNotEmpty)
                                          ...List.generate(
                                            snapshot.data['transactions'].length,
                                            (index) => GestureDetector(
                                              onTap: () => _showTransactionDetails(
                                                providerContext.transactionData[index],
                                              ),
                                              child: snapshot.data['transactions'][index],
                                            ),
                                          ),
                                        // Constants.gap,
                                        Align(
                                          alignment: Alignment.centerRight,
                                          child: TextButton(
                                            onPressed: providerContext
                                                    .transactions.isNotEmpty
                                                ? () {
                                                    Navigator.of(context)
                                                        .restorablePushNamed(
                                                            AllTransactions
                                                                .routeName);
                                                  }
                                                : null, // Disable the button if there are no transactions
                                            style: const ButtonStyle(),
                                            child: const Text(
                                              'View More ->',
                                              style: TextStyle(
                                                fontSize: 16,
                                                fontWeight: FontWeight.bold,
                                              ),
                                              // textAlign: TextAlign.end,
                                            ),
                                          ),
                                        ),
                                        // Constants.gap,
                                        const Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceBetween,
                                          children: [GenerateQR(), ScanQR()],
                                        ),
                                        const SizedBox(
                                          height: 20,
                                        ),
                                        SizedBox(
                                          width:
                                              MediaQuery.of(context).size.width,
                                          child: ElevatedButton(
                                            onPressed: () {
                                              Navigator.pushNamed(
                                                context,
                                                Leaderboard.routeName,
                                              );
                                            },
                                            style: ElevatedButton.styleFrom(
                                              shape: RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(
                                                  24,
                                                ),
                                              ),
                                            ),
                                            child: const Text(
                                              "View Leaderboard",
                                              style: TextStyle(
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.bold),
                                            ),
                                          ),
                                        ),
                                        // Constants.gap,
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        // ),
                      ),
                    ),
                  );
                } else {
                  // Future.delayed(
                  //   Duration.zero,
                  //   () =>
                  //       showSnackbarOnScreen(context, snapshot.data['message']),
                  // );
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
