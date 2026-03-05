import 'package:flutter/material.dart';

void showSnackbarOnScreen(BuildContext context, String content) {
  if (!context.mounted) return;
  ScaffoldMessenger.of(context).hideCurrentSnackBar();
  ScaffoldMessenger.of(context)
      .showSnackBar(SnackBar(content: Text(content)));
}
