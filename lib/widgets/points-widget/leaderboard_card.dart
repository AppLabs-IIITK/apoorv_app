import 'package:apoorv_app/providers/user_info_provider.dart';
import 'package:flutter/material.dart';

import 'package:apoorv_app/constants.dart';
import 'package:provider/provider.dart';

import '../profile_avatar.dart';

class LeaderboardCard extends StatelessWidget {
  final String? name;
  final int? points;
  final int? rank;
  final String? image;
  final String? uid;
  final String? email;

  const LeaderboardCard({
    super.key,
    this.name,
    this.points,
    this.rank,
    this.image,
    this.uid,
    this.email,
  });

  @override
  Widget build(BuildContext context) {
    Color? color;
    double? spreadRadius;

    String showRank = "";

    if (((rank! / 10).floor() % 10) == 1) {
      showRank = "${rank}th";
    } else {
      if (rank! % 10 == 1) {
        showRank = "${rank}st";
      } else if (rank! % 10 == 2) {
        showRank = "${rank}nd";
      } else if (rank! % 10 == 3) {
        showRank = "${rank}rd";
      } else {
        showRank = "${rank}th";
      }
    }

    Map<Color, Color> styleColor = {
      Constants.yellowColor: Constants.blackColor,
      Constants.silverColor: Constants.blackColor,
      Constants.redColor: Constants.whiteColor,
    };

    switch ((rank! % 2)) {
      case 0:
        color = Constants.yellowColor;
        break;
      case 1:
        color = Constants.silverColor;
        break;
    }

    final isCurrentUser = uid == Provider.of<UserProvider>(context, listen: false).uid;
    if (isCurrentUser) {
      color = Constants.redColor;
      spreadRadius = 6;
    }

    return InkWell(
      onTap: isCurrentUser ? null : () {
        Navigator.pushNamed(
          context,
          '/payment',
          arguments: {
            'uid': uid,
            'fullName': name,
            'email': email ?? '',
            'profileImage': image,
            'fromSearch': true,
          },
        );
      },
      child: Container(
        padding: const EdgeInsets.symmetric(
          vertical: 10,
        ),
        margin: EdgeInsets.symmetric(
            horizontal: MediaQuery.of(context).size.width * 0.02),
        child: Container(
            // height: 70,
            width: MediaQuery.of(context).size.width * 0.9,
            decoration: BoxDecoration(
              boxShadow: [
                BoxShadow(
                  color: color ?? Colors.grey,
                  spreadRadius: spreadRadius ?? 2,
                  // blurRadius: blurRadius ?? 2,
                  offset: const Offset(0, 3),
                )
              ],
              border: Border.all(
                color: color ?? Colors.grey.shade300,
              ),
              borderRadius: BorderRadius.circular(24),
              color: color ?? Colors.grey.shade300,
            ),
            child: ListTile(
                title: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              // crossAxisAlignment: CrossAxisAlignment.,
              children: [
                Row(
                  children: [
                    Text(
                      showRank,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: styleColor[color],
                      ),
                    ),
                    const SizedBox(
                      width: 10,
                    ),
                    CircleAvatar(
                      radius: 22,
                      backgroundColor: Constants.yellowColor,
                      child: ProfileAvatar(
                        imageUrl: image,
                        name: name,
                        radius: 22,
                        backgroundColor: Constants.yellowColor,
                        textColor: Constants.blackColor,
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    name!,
                    style: TextStyle(
                      fontSize: 16,
                      color: styleColor[color],
                    ),
                    softWrap: true,
                  ),
                ),
                Row(
                  children: [
                    Text(
                      '$points ',
                      style: TextStyle(
                        fontSize: 16,
                        color: styleColor[color],
                      ),
                    ),
                    Icon(
                      Icons.stars,
                      color: styleColor[color],
                      size: 20,
                    ),
                  ],
                )
              ],
            ))),
      ),
    );
  }
}
