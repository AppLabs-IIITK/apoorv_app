import 'package:apoorv_app/screens/homepage/Maps/maps.dart';
import 'package:apoorv_app/screens/homepage/Profile/profile_2.dart';

import '../../constants.dart';
import 'points/points.dart';
import 'package:flutter/material.dart';
import './feed/feed.dart';

class HomePage extends StatefulWidget {
  static const routeName = '/home-page';
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int currentPageIndex = 0;

  late final List<Widget> screens;

  bool popStatus = true;
  int popCount = 0;

  @override
  void initState() {
    super.initState();
    // Build once and keep tab state alive across tab switches.
    screens = [
      const FeedScreen(),
      const MapsScreen(),
      PointsScreen(stream: st.stream),
      const Profile2Screen(),
    ];
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
    // BaseClient.printAuthTokenForTest();
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
        resizeToAvoidBottomInset: false,
        body: IndexedStack(
          index: currentPageIndex,
          children: screens,
        ),
        bottomNavigationBar: NavigationBar(
          onDestinationSelected: (int index) {
            setState(() {
              currentPageIndex = index;
            });
          },
          indicatorColor: Constants.redColor,
          selectedIndex: currentPageIndex,
          destinations: const <Widget>[
            NavigationDestination(
              selectedIcon: Icon(Icons.home),
              icon: Icon(Icons.home_outlined),
              label: 'Home',
            ),
            NavigationDestination(
              selectedIcon: Icon(Icons.map),
              icon: Icon(Icons.map_outlined),
              label: 'Maps',
            ),
            NavigationDestination(
              selectedIcon: Icon(Icons.stars),
              icon: Icon(Icons.stars_outlined),
              label: 'Points',
            ),
            NavigationDestination(
              selectedIcon: Icon(Icons.account_circle),
              icon: Icon(Icons.account_circle_outlined),
              label: 'Profile',
            ),
          ],
        ),
      ),
    );
  }
}
