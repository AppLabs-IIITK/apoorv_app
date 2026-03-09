import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';

import 'package:apoorv_app/utils/models/feed.dart';

String _buildShareText(Event event, String locationName) {
  final where =
      '$locationName${event.roomNumber.isNotEmpty ? ' - Room ${event.roomNumber}' : ''}';
  final desc = (event.description ?? '').trim();
  final regLink = (event.registrationLink ?? '').trim();

  final lines = <String>[
    event.title.trim(),
    'Day ${event.day} • ${event.time}',
    where,
    if (desc.isNotEmpty) '',
    if (desc.isNotEmpty) desc,
    if (regLink.isNotEmpty) '',
    if (regLink.isNotEmpty) 'Register: $regLink',
  ];

  if (event.imageUrl != null && event.imageUrl!.trim().isNotEmpty) {
    lines.add('Image: ${event.imageUrl}');
  }

  return lines.join('\n');
}

Future<void> shareEvent({
  required BuildContext context,
  required Event event,
  required String locationName,
}) async {
  final text = _buildShareText(event, locationName);
  await Share.share(text, subject: event.title);
}
