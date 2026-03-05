import 'package:apoorv_app/constants.dart';
import 'package:flutter/material.dart';

class SingleFeed extends StatelessWidget {
  const SingleFeed({
    super.key,
    required this.title,
    this.priority = false,
    this.imageUrl,
    required this.index,
  });
  final int index;
  final String title;
  final bool priority;
  final String? imageUrl;

  static const feedColor = [
    Constants.creamColor,
    Constants.whiteColor,
  ];

  static const textColor = Constants.blackColor;

  @override
  Widget build(BuildContext context) {
    ShapeBorder? border;
    if (priority) {
      border = RoundedRectangleBorder(
        side: const BorderSide(
          color: Constants.redColorAlt,
          width: 5.0,
        ),
        borderRadius: BorderRadius.circular(24),
      );
    }
    return Card(
      shape: border,
      margin: EdgeInsets.only(
        left: MediaQuery.of(context).size.width * 0.03,
        right: MediaQuery.of(context).size.width * 0.03,
        bottom: MediaQuery.of(context).size.width * 0.03,
      ),
      color: feedColor[index % 2],
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                Image.asset("assets/images/Apoorv.png"),
                const SizedBox(width: 16),
                Expanded(
                    child: Text(
                  title,
                  style: const TextStyle(
                    color: textColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                )),
              ],
            ),
            if (imageUrl != null) ...{
              Constants.gap,
              Image.network(
                imageUrl!,
                fit: BoxFit.cover,
              ),
            }
          ],
        ),
      ),
    );
  }
}
