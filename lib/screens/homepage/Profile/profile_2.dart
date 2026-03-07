import 'dart:async';

import 'package:apoorv_app/providers/app_config_provider.dart';
import 'package:apoorv_app/providers/user_info_provider.dart';
import 'package:apoorv_app/screens/homepage/Profile/manage_shopkeepers.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../../constants.dart';
import '../../../widgets/dialog.dart';
import '../../../widgets/signup-flow/logout.dart';
import '../../../widgets/spinning_apoorv.dart';
import '../Transactions/inspect_transactions.dart';

class Profile2Screen extends StatefulWidget {
  static const routeName = '/profile-2';
  const Profile2Screen({super.key});

  @override
  State<Profile2Screen> createState() => _Profile2ScreenState();
}

class _Profile2ScreenState extends State<Profile2Screen> {
  Future<Map<String, dynamic>>? _myFuture;
  // Timer? timer;

  @override
  void initState() {
    super.initState();
    _updateProfileData(); // Call the function to initially fetch and update profile data
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<UserProvider>().ensureShopkeeperModeLoaded();
    });
    // timer = Timer.periodic(const Duration(seconds: 10), (timer) {
    //   _updateProfileData(); // Call the function to fetch and update profile data every 10 seconds
    // });
  }

  @override
  void dispose() {
    super.dispose();
    // timer?.cancel();
  }

  // Function to fetch and update profile data
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
                  final config = ctx.watch<AppConfigProvider>();
                  final useShopkeeperPoints = providerContext.isShopkeeper &&
                      providerContext.shopkeeperModeEnabled;
                  final displayPoints = useShopkeeperPoints
                      ? providerContext.shopPoints
                      : providerContext.points;
                  final displayLabel =
                      useShopkeeperPoints ? "Shop Coins" : "Apoorv Coins";

                  return Scaffold(
                    floatingActionButton: config.canManageContent
                        ? Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              FloatingActionButton.small(
                                heroTag: null,
                                tooltip: 'Manage Shop Keepers',
                                onPressed: () {
                                  Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (_) =>
                                          const ManageShopkeepersScreen(),
                                    ),
                                  );
                                },
                                child: const Icon(Icons.storefront_outlined),
                              ),
                              const SizedBox(height: 10),
                              FloatingActionButton.small(
                                heroTag: null,
                                tooltip: 'Refresh Profile',
                                onPressed: () => _updateProfileData(),
                                child: const Icon(Icons.refresh_rounded),
                              ),
                            ],
                          )
                        : FloatingActionButton(
                            heroTag: null,
                            onPressed: () => _updateProfileData(),
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
                      child: SafeArea(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Padding(
                              padding: EdgeInsets.symmetric(
                                  horizontal:
                                      MediaQuery.of(ctx).size.width * 0.05),
                              child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          InkWell(
                                            onTap: () {
                                              Navigator.of(context).push(
                                                MaterialPageRoute(
                                                  builder: (_) =>
                                                      InspectTransactionsScreen(
                                                    uid: providerContext.uid,
                                                    name: providerContext.userName,
                                                    email: providerContext.userEmail,
                                                  ),
                                                ),
                                              );
                                            },
                                            child: ClipRRect(
                                              borderRadius: BorderRadius.circular(
                                                  MediaQuery.of(context)
                                                          .size
                                                          .width *
                                                      0.33 /
                                                      2),
                                              child: (providerContext
                                                              .profilePhotoUrl !=
                                                          null &&
                                                      providerContext
                                                          .profilePhotoUrl!
                                                          .isNotEmpty)
                                                  ? Image.network(
                                                      providerContext
                                                          .profilePhotoUrl!,
                                                      height: MediaQuery.of(
                                                                  context)
                                                              .size
                                                              .width *
                                                          0.33,
                                                      width: MediaQuery.of(context)
                                                              .size
                                                              .width *
                                                          0.33,
                                                      fit: BoxFit.cover,
                                                      errorBuilder: (context,
                                                          error, stackTrace) {
                                                        return Container(
                                                          height: MediaQuery.of(
                                                                      context)
                                                                  .size
                                                                  .width *
                                                              0.33,
                                                          width: MediaQuery.of(
                                                                      context)
                                                                  .size
                                                                  .width *
                                                              0.33,
                                                          color: Constants
                                                              .yellowColor,
                                                          alignment:
                                                              Alignment.center,
                                                          child: Text(
                                                            providerContext
                                                                    .userName
                                                                    .isNotEmpty
                                                                ? providerContext
                                                                    .userName[0]
                                                                    .toUpperCase()
                                                                : '?',
                                                            style:
                                                                const TextStyle(
                                                              fontSize: 48,
                                                              fontWeight:
                                                                  FontWeight.bold,
                                                              color: Constants
                                                                  .blackColor,
                                                            ),
                                                          ),
                                                        );
                                                      },
                                                    )
                                                  : Container(
                                                      height: MediaQuery.of(
                                                                  context)
                                                              .size
                                                              .width *
                                                          0.33,
                                                      width: MediaQuery.of(context)
                                                              .size
                                                              .width *
                                                          0.33,
                                                      color:
                                                          Constants.yellowColor,
                                                      alignment: Alignment.center,
                                                      child: Text(
                                                        providerContext
                                                                .userName
                                                                .isNotEmpty
                                                            ? providerContext
                                                                .userName[0]
                                                                .toUpperCase()
                                                            : '?',
                                                        style: const TextStyle(
                                                          fontSize: 48,
                                                          fontWeight:
                                                              FontWeight.bold,
                                                          color:
                                                              Constants.blackColor,
                                                        ),
                                                      ),
                                                    ),
                                            ),
                                          ),
                                          SizedBox(
                                            width:
                                                MediaQuery.of(ctx).size.width *
                                                    0.45,
                                            child: Column(
                                              mainAxisAlignment:
                                                  MainAxisAlignment.spaceEvenly,
                                              children: [
                                                FilledButton(
                                                  onPressed: () {},
                                                  style: ButtonStyle(
                                                    backgroundColor:
                                                        MaterialStateProperty
                                                            .all<Color>(Constants
                                                                .yellowColor),
                                                    foregroundColor:
                                                        MaterialStateProperty
                                                            .all<Color>(
                                                                Colors.black),
                                                  ),
                                                  child: SizedBox(
                                                    width: double.infinity,
                                                    child: Text(
                                                      "$displayLabel: $displayPoints",
                                                      textAlign:
                                                          TextAlign.center,
                                                      style: const TextStyle(
                                                          fontWeight:
                                                              FontWeight.bold),
                                                    ),
                                                  ),
                                                ),
                                                Constants.gap,
                                                if (providerContext.isShopkeeper) ...[
                                                  Container(
                                                    padding: const EdgeInsets.symmetric(
                                                        horizontal: 8, vertical: 6),
                                                    decoration: BoxDecoration(
                                                      color: Constants.blackColor,
                                                      borderRadius:
                                                          BorderRadius.circular(12),
                                                      border: Border.all(
                                                        color: Constants.yellowColor,
                                                        width: 1,
                                                      ),
                                                    ),
                                                    child: Row(
                                                      children: [
                                                        const Expanded(
                                                          child: Text(
                                                            "Shopkeeper mode",
                                                            style: TextStyle(
                                                              color: Colors.white,
                                                              fontSize: 12,
                                                              fontWeight:
                                                                  FontWeight.w600,
                                                            ),
                                                          ),
                                                        ),
                                                        Switch(
                                                          value: providerContext
                                                              .shopkeeperModeEnabled,
                                                          activeColor:
                                                              Constants.yellowColor,
                                                          onChanged: (val) {
                                                            providerContext
                                                                .setShopkeeperModeEnabled(
                                                                    val);
                                                          },
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                  Constants.gap,
                                                ],
                                                const LogoutButton(),
                                              ],
                                            ),
                                          )
                                        ]),
                                    Constants.gap,
                                    Text(providerContext.userName,
                                        style: const TextStyle(
                                          color: Constants.blackColor,
                                          fontSize: 24,
                                          fontWeight: FontWeight.bold,
                                        )),
                                    const Text("Email",
                                        style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            color: Constants.blackColor,
                                            fontSize: 16)),
                                    Text(providerContext.userEmail,
                                        style: const TextStyle(
                                            color: Constants.blackColor,
                                            fontSize: 16)),
                                    const Text("Phone",
                                        style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 16,
                                            color: Constants.blackColor)),
                                    Text(providerContext.userPhNo,
                                        style: const TextStyle(
                                            color: Constants.blackColor,
                                            fontSize: 16)),
                                    if (providerContext.fromCollege &&
                                        (providerContext.userRollNo ?? '')
                                            .trim()
                                            .isNotEmpty) ...[
                                      const Text('Roll No',
                                          style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 16,
                                              color: Constants.blackColor)),
                                      Text(providerContext.userRollNo!,
                                          style: const TextStyle(
                                            color: Constants.blackColor,
                                            fontSize: 16,
                                          )),
                                    ],
                                    const Text('College',
                                        style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 16,
                                            color: Constants.blackColor)),
                                    Text(providerContext.userCollegeName,
                                        style: const TextStyle(
                                            color: Constants.blackColor,
                                            fontSize: 16)),
                                    if (!providerContext.fromCollege) ...[
                                      const Text('',
                                          style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 16,
                                              color: Constants.blackColor)),
                                      const Text('',
                                          style: TextStyle(
                                              color: Constants.blackColor,
                                              fontSize: 16)),
                                    ],
                                  ]),
                            ),
                            Constants.gap,
                            Expanded(
                              child: Container(
                                // width: double.infinity,
                                alignment: Alignment.center,
                                padding: EdgeInsets.all(
                                    MediaQuery.of(ctx).size.width * 0.05),
                                decoration: const BoxDecoration(
                                  borderRadius: BorderRadius.only(
                                    topLeft: Radius.circular(24),
                                    topRight: Radius.circular(24),
                                  ),
                                  color: Constants.blackColor,
                                ),
                                child: QrImageView(
                                  data: providerContext.uid,
                                  backgroundColor: Constants.whiteColor,
                                  // size: MediaQuery.of(context).size.width * 0.75,
                                ),
                              ),
                            ),
                          ],
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
