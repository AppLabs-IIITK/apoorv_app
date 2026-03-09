import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import 'package:apoorv_app/utils/models/feed.dart';

String _buildShareText(Event event, String locationName) {
  final isOnline = locationName.trim().isEmpty || locationName.trim() == 'Online';
  final where = isOnline
      ? 'Online'
      : '$locationName${event.roomNumber.isNotEmpty ? ' - Room ${event.roomNumber}' : ''}';
  final desc = (event.description ?? '').trim();
  final regLink = (event.registrationLink ?? '').trim();

  return <String>[
    event.title.trim(),
    if (event.day != 0) 'Day ${event.day} • ${event.time}' else event.time,
    where,
    if (desc.isNotEmpty) '',
    if (desc.isNotEmpty) desc,
    if (regLink.isNotEmpty) '',
    if (regLink.isNotEmpty) 'Register: $regLink',
  ].join('\n');
}

String _guessExtension(String url) {
  final lower = url.toLowerCase();
  if (lower.contains('.png')) return 'png';
  if (lower.contains('.webp')) return 'webp';
  if (lower.contains('.gif')) return 'gif';
  return 'jpg';
}

String _mimeForExt(String ext) {
  switch (ext) {
    case 'png':
      return 'image/png';
    case 'webp':
      return 'image/webp';
    case 'gif':
      return 'image/gif';
    default:
      return 'image/jpeg';
  }
}

Future<File> _writeTempImage({
  required Uint8List bytes,
  required String eventId,
  required String ext,
}) async {
  final dir = await getTemporaryDirectory();
  final safeId = eventId.replaceAll(RegExp(r'[^a-zA-Z0-9_-]'), '_');
  final file = File('${dir.path}${Platform.pathSeparator}event_$safeId.$ext');
  await file.writeAsBytes(bytes, flush: true);
  return file;
}

Future<void> shareEvent({
  required BuildContext context,
  required Event event,
  required String locationName,
}) async {
  final text = _buildShareText(event, locationName);
  final url = (event.imageUrl ?? '').trim();

  if (url.isEmpty) {
    await Share.share(text, subject: event.title);
    return;
  }

  try {
    final resp = await http.get(Uri.parse(url));
    if (resp.statusCode < 200 || resp.statusCode >= 300) {
      await Share.share('$text\n\nImage: $url', subject: event.title);
      return;
    }

    final ext = _guessExtension(url);
    final file = await _writeTempImage(
      bytes: resp.bodyBytes,
      eventId: event.id,
      ext: ext,
    );

    await Share.shareXFiles(
      [XFile(file.path, mimeType: _mimeForExt(ext))],
      text: text,
      subject: event.title,
    );
  } catch (_) {
    await Share.share('$text\n\nImage: $url', subject: event.title);
  }
}
