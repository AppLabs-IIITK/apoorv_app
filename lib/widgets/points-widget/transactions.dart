import 'package:flutter/material.dart';

import '../../constants.dart';

class TransactionsWidget extends StatelessWidget {
  final String? name;
  final String? date;
  final String? type;
  final int? points;
  final String? fromUid;
  final String? toUid;
  final String? fromEmail;
  final String? toEmail;
  final VoidCallback? onTap;
  final bool isShop;

  const TransactionsWidget({
    super.key,
    this.name,
    this.date,
    this.type,
    this.points,
    this.fromUid,
    this.toUid,
    this.fromEmail,
    this.toEmail,
    this.onTap,
    this.isShop = false,
  });

  @override
  Widget build(BuildContext context) {
    String? transactedPoints;
    Color? textColor;
    Color? widgetColor;
    switch (type) {
      case 'credit':
        transactedPoints = '+$points';
        textColor = Constants.greenColor;
        widgetColor = Constants.silverColor;
        break;
      case 'debit':
        transactedPoints = '- $points';
        textColor = Constants.redColorAlt;
        widgetColor = Constants.yellowColor;
        break;
    }
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 5),
        child: Container(
          decoration: BoxDecoration(
            color: widgetColor,
            borderRadius: BorderRadius.circular(15),
          ),
          padding: const EdgeInsets.all(10),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(name!,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w600,
                            color: Color.fromRGBO(18, 18, 18, 1),
                          )),
                      if (isShop) ...[
                        const SizedBox(width: 6),
                        const Text(
                          'shop',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: Color.fromRGBO(18, 18, 18, 0.6),
                          ),
                        ),
                      ],
                    ],
                  ),
                  Text(
                    date!,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Color.fromRGBO(18, 18, 18, 1),
                    ),
                  ),
                ],
              ),
              Column(
                children: [
                  Text(
                    transactedPoints!,
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                      color: textColor,
                    ),
                  ),
                  const Text(
                    "Points",
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Color.fromRGBO(18, 18, 18, 1),
                    ),
                  ),
                ],
              )
            ],
          ),
        ),
      ),
    );
  }
}
