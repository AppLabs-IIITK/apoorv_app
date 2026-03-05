import 'package:apoorv_app/screens/signup-flow/welcome.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../constants.dart';
import '../providers/shopkeeper_provider.dart';
import '../widgets/dialog.dart';
import '../widgets/spinning_apoorv.dart';

class ShopkeeperProfileScreen extends StatefulWidget {
  static const routeName = '/shopkeeper-profile';
  const ShopkeeperProfileScreen({super.key});

  @override
  State<ShopkeeperProfileScreen> createState() =>
      _ShopkeeperProfileScreenState();
}

class _ShopkeeperProfileScreenState extends State<ShopkeeperProfileScreen> {
  Future<Map<String, dynamic>>? _myFuture;

  @override
  void initState() {
    super.initState();
    _updateProfileData();
  }

  @override
  void dispose() {
    super.dispose();
  }

  // Function to fetch and update profile data
  Future<void> _updateProfileData() async {
    setState(() {
      _myFuture =
          Provider.of<ShopkeeperProvider>(context, listen: false).getUserInfo();
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
                  Provider.of<ShopkeeperProvider>(ctx);
                  var providerContext = context.read<ShopkeeperProvider>();
                  return Scaffold(
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
                            Padding(
                              padding: EdgeInsets.symmetric(
                                  horizontal:
                                      MediaQuery.of(context).size.width * 0.05),
                              child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceAround,
                                        children: [
                                          ClipRRect(
                                            borderRadius: BorderRadius.circular(
                                                MediaQuery.of(context)
                                                        .size
                                                        .width *
                                                    0.33 /
                                                    2),
                                            child: Image.network(
                                              providerContext.profilePhoto,
                                              height: MediaQuery.of(context)
                                                      .size
                                                      .width *
                                                  0.33,
                                              width: MediaQuery.of(context)
                                                      .size
                                                      .width *
                                                  0.33,
                                              fit: BoxFit
                                                  .cover, // You might want to add this to cover the entire circular area
                                            ),
                                          ),
                                          SizedBox(
                                            width: MediaQuery.of(context)
                                                    .size
                                                    .width *
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
                                                      "Shop Points: ${context.read<ShopkeeperProvider>().shopPoints}",
                                                      textAlign:
                                                          TextAlign.center,
                                                      // style: TextStyle(fontSize: 16),
                                                    ),
                                                  ),
                                                ),
                                                Constants.gap,
                                                FilledButton(
                                                  onPressed: () {
                                                    Navigator.of(context)
                                                        .pushReplacementNamed(
                                                            WelcomeScreen
                                                                .routeName);
                                                  },
                                                  style: ButtonStyle(
                                                    backgroundColor:
                                                        MaterialStateProperty
                                                            .all<Color>(
                                                                Constants
                                                                    .redColor),
                                                    foregroundColor:
                                                        MaterialStateProperty
                                                            .all<Color>(Constants
                                                                .whiteColor),
                                                  ),
                                                  child: const SizedBox(
                                                    width: double.infinity,
                                                    child: Text(
                                                      "Logout",
                                                      textAlign:
                                                          TextAlign.center,
                                                      style: TextStyle(
                                                          fontSize: 16),
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          )
                                        ]),
                                    Constants.gap,
                                    const Text("Email",
                                        style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            color: Constants.blackColor,
                                            fontSize: 16)),
                                    Text(
                                        context
                                            .read<ShopkeeperProvider>()
                                            .shopkeeperEmail,
                                        style: const TextStyle(
                                            color: Constants.blackColor,
                                            fontSize: 16)),
                                    Container(
                                      color: Constants.whiteColor,
                                      width: MediaQuery.of(context).size.width *
                                          0.8,
                                      child: Image.network(
                                        'https://drive.google.com/uc?export=view&id=1IHBaPuam7Q8mv2JUMBcCtlOf9pQr2Ncx',
                                        fit: BoxFit.contain,
                                      ),
                                    ),
                                  ]),
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
