import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../constants.dart';

class TransactionDetailsModal extends StatefulWidget {
  final String fromUid;
  final String toUid;
  final String fromName;
  final String toName;
  final String fromEmail;
  final String toEmail;
  final int points;
  final String formattedTime;
  final String? myUid;

  const TransactionDetailsModal({
    super.key,
    required this.fromUid,
    required this.toUid,
    required this.fromName,
    required this.toName,
    required this.fromEmail,
    required this.toEmail,
    required this.points,
    required this.formattedTime,
    this.myUid,
  });

  @override
  State<TransactionDetailsModal> createState() => _TransactionDetailsModalState();
}

class _TransactionDetailsModalState extends State<TransactionDetailsModal> {
  String _fromImage = '';
  String _toImage = '';

  @override
  void initState() {
    super.initState();
    _fetchProfileImages();
  }

  Future<void> _fetchProfileImages() async {
    try {
      final fromDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.fromUid)
          .get();
      final toDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.toUid)
          .get();

      if (mounted) {
        setState(() {
          _fromImage = (fromDoc.data()?['photoUrl'] as String?)?.trim() ?? '';
          _toImage = (toDoc.data()?['photoUrl'] as String?)?.trim() ?? '';
        });
      }
    } catch (_) {
      // Images will remain empty, showing fallback
    }
  }

  Widget _buildProfileCard({
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
                    backgroundColor: Constants.yellowColor,
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
    return Padding(
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
                '${widget.points}',
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
            widget.formattedTime,
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
                  uid: widget.fromUid,
                  name: widget.fromName,
                  email: widget.fromEmail,
                  profileImage: _fromImage,
                  label: 'From',
                  isCurrentUser: widget.fromUid == widget.myUid,
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
                  uid: widget.toUid,
                  name: widget.toName,
                  email: widget.toEmail,
                  profileImage: _toImage,
                  label: 'To',
                  isCurrentUser: widget.toUid == widget.myUid,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}
