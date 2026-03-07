import 'share_event_stub.dart'
    if (dart.library.io) 'share_event_io.dart' as impl;

import 'package:flutter/material.dart';

import 'package:apoorv_app/utils/models/feed.dart';

Future<void> shareEvent({
  required BuildContext context,
  required Event event,
  required String locationName,
}) {
  return impl.shareEvent(
    context: context,
    event: event,
    locationName: locationName,
  );
}
