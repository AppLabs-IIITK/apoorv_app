import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';

class Content {
  const Content({
    required this.txtcolor,
    required this.body,
    required this.color, // marker color
    this.image,
    this.description,
  });
  final String body;
  final Color color;
  final Color txtcolor;
  final Image? image;
  final String? description;
}

class Event {
  final String id;
  final String title;
  final String? description;
  final Image? image;
  final String? imageFile;
  final Color color;
  final Color txtcolor;
  final int day; // 1, 2, or 3
  final String time; // e.g. "10:00 AM - 12:00 PM"
  final String locationId; // ID of the associated marker/location
  final String roomNumber; // Room number within the location
  final DateTime createdAt;

  Event({
    required this.id,
    required this.title,
    this.description,
    this.image,
    this.imageFile,
    required this.color,
    required this.txtcolor,
    required this.day,
    required this.time,
    required this.locationId,
    required this.roomNumber,
    required this.createdAt,
  });

  // Helper method to determine floor based on room number
  String get floor {
    if (roomNumber.isEmpty) return 'Ground';

    // Extract the first digit if it exists
    final firstChar = roomNumber.substring(0, 1);
    if (RegExp(r'[0-9]').hasMatch(firstChar)) {
      if (firstChar == '0') return 'Ground';
      return 'Floor $firstChar';
    }

    // If room number starts with G or g, it's ground floor
    if (firstChar.toLowerCase() == 'g') return 'Ground';

    return 'Other';
  }
}

class MapMarker {
  String id;
  final String locationName; // Name of the building/location
  final LatLng position;
  final Color markerColor;
  final Color textColor;
  final List<Event> events; // List of events at this location
  final DateTime createdAt;

  MapMarker({
    required this.id,
    required this.locationName,
    required this.position,
    required this.markerColor,
    required this.textColor,
    this.events = const [],
    required this.createdAt,
  });
}
