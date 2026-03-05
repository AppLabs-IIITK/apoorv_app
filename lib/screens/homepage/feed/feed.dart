import 'package:apoorv_app/api.dart';
import 'package:apoorv_app/providers/user_info_provider.dart';
import 'package:apoorv_app/screens/homepage/feed/single_feed.dart';
import 'package:apoorv_app/widgets/dialog.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../constants.dart';
import '../../../widgets/spinning_apoorv.dart';

class FeedScreen extends StatefulWidget {
  static const routeName = '/feed';
  const FeedScreen({super.key});

  @override
  State<FeedScreen> createState() => _FeedScreenState();
}

class _FeedScreenState extends State<FeedScreen> {
  Future<Map<String, dynamic>>? _myFuture;

  @override
  void initState() {
    super.initState();
    _updateFeedData();
  }

  Future<void> _updateFeedData() async {
    setState(() {
      _myFuture = APICalls().getFeed(context.read<UserProvider>().idToken);
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
                if (snapshot.data['error'] != null) {
                  var e = snapshot.data['error'] as String;
                  var message = "";
                  if (e.contains("connection")) {
                    message =
                        "There was a connection error! Check your connection and try again";
                  } else {
                    message = e;
                  }
                  Future.delayed(
                      const Duration(seconds: 1),
                      () {
                        if (!context.mounted) return;
                        dialogBuilder(context, message: message,
                                function: () {
                          _updateFeedData();
                          Navigator.of(context).pop();
                        });
                      });

                  return const Scaffold(body: Center(child: SpinningApoorv()));
                } else if (snapshot.data['success']) {
                  var providerContext = context.read<UserProvider>();

                  var data = snapshot.data['body'] as List;
                  return Scaffold(
                    floatingActionButton: FloatingActionButton(
                      heroTag: null,
                      onPressed: () => _updateFeedData(),
                      child: const Icon(Icons.refresh_rounded),
                    ),
                    body: SizedBox(
                      width: MediaQuery.of(context).size.width,
                      child: Column(
                        children: [
                          Container(
                            width: double.infinity,
                            height: MediaQuery.of(context).size.height / 4,
                            decoration: const BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    Constants.gradientHigh,
                                    Constants.gradientMid,
                                  ],
                                  begin: Alignment.topCenter,
                                  end: Alignment.center,
                                ),
                                borderRadius: BorderRadius.only(
                                  bottomLeft: Radius.circular(30),
                                  bottomRight: Radius.circular(30),
                                )),
                            child: Padding(
                              padding: EdgeInsets.symmetric(
                                  horizontal:
                                      MediaQuery.of(context).size.width * 0.07),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Flexible(
                                        child: Text(
                                          "Welcome,\n${providerContext.userName.split(' ')[0]}",
                                          style: const TextStyle(
                                            color: Constants.blackColor,
                                            fontSize: 36,
                                            fontWeight: FontWeight.bold,
                                            fontFamily: 'GOT'
                                          ),
                                          softWrap: true,
                                        ),
                                      ),
                                    ],
                                  ),
                                  Image.asset(
                                    "assets/images/Apoorv-logo.png",
                                    height: MediaQuery.of(context).size.height /
                                        5.9,
                                    width:
                                        MediaQuery.of(context).size.width / 4,
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(
                            height: 20,
                          ),
                          Container(
                            padding: EdgeInsets.symmetric(
                                horizontal:
                                    MediaQuery.of(context).size.width * 0.05),
                            width: double.infinity,
                            child: const Text(
                              "Feed",
                              style: TextStyle(
                                color: Constants.whiteColor,
                                fontSize: 30,
                              ),
                              textAlign: TextAlign.left,
                            ),
                          ),
                          Constants.gap,
                          // ListView.builder( {
                          if (data.isEmpty)
                            const Expanded(
                              child: Center(
                                child: Text(
                                  "Wow, such empty",
                                  style: TextStyle(fontSize: 24),
                                ),
                              ),
                            ),

                          Expanded(
                            child: ListView.builder(
                                itemCount: data.length,
                                itemBuilder: (BuildContext context, int i) {
                                  var message = data[i]['title'];
                                  if (data[i]['text'] != null) {
                                    message =
                                        "${data[i]['title']}\n${data[i]['text']}";
                                  }
                                  if (data[i]['imageUrl'] != null) {
                                    return SingleFeed(
                                      index: i,
                                      title: message,
                                      priority: data[i]['priority'],
                                      imageUrl: data[i]['imageUrl'],
                                    );
                                  } else {
                                    return SingleFeed(
                                      index: i,
                                      title: message,
                                      priority: data[i]['priority'],
                                    );
                                  }
                                }),
                          ),
                          // Constants.gap,
                        ],
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
