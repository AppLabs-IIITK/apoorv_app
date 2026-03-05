import 'package:apoorv_app/router.dart';
import 'package:flutter/material.dart';

import 'widgets/spinning_apoorv.dart';

class LoadingScreen extends StatelessWidget {
  const LoadingScreen({super.key});

  void delayLoad(BuildContext context) {
    Future.delayed(Durations.extralong4, () {
      if (!context.mounted) return;
      Navigator.of(context).pushReplacementNamed(Routing.routeName);
    });
  }

  @override
  Widget build(BuildContext context) {
    delayLoad(context);

    return const Scaffold(
      body: Center(
        child: SpinningApoorv(),
      ),
    );
  }
}
