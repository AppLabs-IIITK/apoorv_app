import 'dart:io';
import 'package:apoorv_app/utils/models/feed.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// MapDataService handles all data persistence for the maps feature.
///
/// Data (locations & events) is stored in **Firebase Firestore**.
/// Firestore offline persistence is enabled by default on Android/iOS,
/// so cached reads work out of the box without any manual JSON caching.
///
/// File uploads/retrieval (event/marker images) use **Supabase Storage**.
class MapDataService {
  static final _firestore = FirebaseFirestore.instance;
  static final _supabase = Supabase.instance.client;

  // ─────────────────────────────────────────
  // Firestore Streams
  // ─────────────────────────────────────────

  /// Returns a stream of all locations ordered by creation date.
  static Stream<QuerySnapshot> getLocationsStream() {
    return _firestore.collection('locations').orderBy('created_at').snapshots();
  }

  /// Returns a stream of all events ordered by creation date.
  static Stream<QuerySnapshot> getEventsStream() {
    return _firestore.collection('events').orderBy('created_at').snapshots();
  }

  /// Returns a stream of a specific event by ID.
  static Stream<DocumentSnapshot> getEventStream(String eventId) {
    return _firestore.collection('events').doc(eventId).snapshots();
  }

  // ─────────────────────────────────────────
  // Model builders — called by streams in maps.dart
  // ─────────────────────────────────────────

  /// Converts Firestore event docs → [Event] objects.
  /// Images are NOT loaded here — just the URL string is stored.
  /// The UI uses CachedNetworkImage to display images lazily.
  static List<Event> buildEventsFromDocs(
      List<QueryDocumentSnapshot> docs) {
    final List<Event> events = [];
    for (final doc in docs) {
      final data = doc.data() as Map<String, dynamic>;
      final imageFile = data['image_file'] as String?;
      final imageUrl = imageFile != null ? getEventImageUrl(imageFile) : null;
      events.add(Event(
        id: doc.id,
        title: data['title'] ?? '',
        description: data['description'],
        imageUrl: imageUrl,
        imageFile: imageFile,
        color: Color(data['color'] is String
            ? int.parse(data['color'] as String)
            : data['color'] as int),
        txtcolor: Color(data['text_color'] is String
            ? int.parse(data['text_color'] as String)
            : data['text_color'] as int),
        day: data['day'] as int,
        time: data['time'] ?? '',
        locationId: data['location_id'] ?? '',
        roomNumber: data['room_number'] ?? '',
        createdAt: DateTime.parse(data['created_at'] as String),
      ));
    }
    return events;
  }

  /// Converts Firestore location docs + pre-built [events] → [MapMarker] list.
  static List<MapMarker> buildMarkersFromDocs(
      List<QueryDocumentSnapshot> docs, List<Event> events) {
    return docs.map((doc) {
      final data = doc.data() as Map<String, dynamic>;
      final markerEvents =
          events.where((e) => e.locationId == doc.id).toList();
      return MapMarker(
        id: doc.id,
        locationName: data['location_name'] ?? '',
        position: LatLng(
          (data['latitude'] as num).toDouble(),
          (data['longitude'] as num).toDouble(),
        ),
        markerColor: Color(data['marker_color'] is String
            ? int.parse(data['marker_color'] as String)
            : data['marker_color'] as int),
        textColor: Color(data['text_color'] is String
            ? int.parse(data['text_color'] as String)
            : data['text_color'] as int),
        events: markerEvents,
        createdAt: DateTime.parse(data['created_at'] as String),
      );
    }).toList();
  }

  // ─────────────────────────────────────────
  // Image upload/retrieval (Supabase Storage)
  // ─────────────────────────────────────────

  /// Uploads a file to Supabase Storage and returns the generated filename.
  static Future<String> uploadImage(String imagePath, String folder) async {
    try {
      final file = File(imagePath);
      final fileExt = imagePath.split('.').last;
      final fileName = '${DateTime.now().millisecondsSinceEpoch}.$fileExt';
      await _supabase.storage.from('assets').upload('$folder/$fileName', file);
      return fileName;
    } catch (e) {
      debugPrint('MapDataService: Error uploading image: $e');
      rethrow;
    }
  }

  static Future<String> uploadMarkerImage(String imagePath) =>
      uploadImage(imagePath, 'marker_images');

  static Future<String> uploadEventImage(String imagePath) =>
      uploadImage(imagePath, 'event_images');

  /// Returns the public Supabase Storage URL for a given filename.
  static String getImageUrl(String fileNameOrUrl, String folder) {
    if (fileNameOrUrl.startsWith('http')) return fileNameOrUrl;
    return _supabase.storage
        .from('assets')
        .getPublicUrl('$folder/$fileNameOrUrl');
  }

  static String getEventImageUrl(String fileNameOrUrl) =>
      getImageUrl(fileNameOrUrl, 'event_images');

  static String getMarkerImageUrl(String fileNameOrUrl) =>
      getImageUrl(fileNameOrUrl, 'marker_images');

  // ─────────────────────────────────────────
  // Firestore CRUD — Locations
  // ─────────────────────────────────────────

  /// Saves a new location to Firestore.
  /// Returns the Firestore-generated document ID.
  /// The active stream in maps.dart will pick up the change automatically.
  static Future<String> saveLocation(MapMarker marker) async {
    try {
      final docRef = await _firestore.collection('locations').add({
        'location_name': marker.locationName,
        'latitude': marker.position.latitude,
        'longitude': marker.position.longitude,
        'marker_color': marker.markerColor.value,
        'text_color': marker.textColor.value,
        'created_at': marker.createdAt.toIso8601String(),
      });
      return docRef.id;
    } catch (e) {
      debugPrint('MapDataService: Error saving location: $e');
      rethrow;
    }
  }

  /// Updates an existing location in Firestore.
  static Future<void> updateLocation(MapMarker marker) async {
    try {
      await _firestore.collection('locations').doc(marker.id).update({
        'location_name': marker.locationName,
        'latitude': marker.position.latitude,
        'longitude': marker.position.longitude,
        'marker_color': marker.markerColor.value,
        'text_color': marker.textColor.value,
      });
    } catch (e) {
      debugPrint('MapDataService: Error updating location: $e');
      rethrow;
    }
  }

  /// Deletes a location and all its events in a single batch write.
  static Future<void> deleteLocation(String locationId) async {
    try {
      final eventsSnap = await _firestore
          .collection('events')
          .where('location_id', isEqualTo: locationId)
          .get();

      final batch = _firestore.batch();
      for (final doc in eventsSnap.docs) {
        batch.delete(doc.reference);
      }
      batch.delete(_firestore.collection('locations').doc(locationId));
      await batch.commit();
    } catch (e) {
      debugPrint('MapDataService: Error deleting location: $e');
      rethrow;
    }
  }

  // ─────────────────────────────────────────
  // Firestore CRUD — Events
  // ─────────────────────────────────────────

  /// Saves a new event to Firestore.
  /// Returns the Firestore-generated document ID.
  static Future<String> saveEvent(Event event, String? imageFileName) async {
    try {
      final docRef = await _firestore.collection('events').add({
        'title': event.title,
        'description': event.description,
        'image_file': imageFileName,
        'color': event.color.value,
        'text_color': event.txtcolor.value,
        'day': event.day,
        'time': event.time,
        'location_id': event.locationId,
        'room_number': event.roomNumber,
        'created_at': event.createdAt.toIso8601String(),
      });
      debugPrint('MapDataService: Event saved with ID: ${docRef.id}');
      return docRef.id;
    } catch (e) {
      debugPrint('MapDataService: Error saving event: $e');
      rethrow;
    }
  }

  /// Updates an existing event in Firestore.
  static Future<void> updateEvent(Event event, String? imageFileName) async {
    try {
      final updateData = <String, dynamic>{
        'title': event.title,
        'description': event.description,
        'color': event.color.value,
        'text_color': event.txtcolor.value,
        'day': event.day,
        'time': event.time,
        'location_id': event.locationId,
        'room_number': event.roomNumber,
      };
      if (imageFileName != null) {
        updateData['image_file'] = imageFileName;
      }
      await _firestore.collection('events').doc(event.id).update(updateData);
      debugPrint('MapDataService: Event updated with ID: ${event.id}');
    } catch (e) {
      debugPrint('MapDataService: Error updating event: $e');
      rethrow;
    }
  }

  /// Deletes an event from Firestore and removes its image from Supabase Storage.
  static Future<void> deleteEvent(String eventId) async {
    try {
      final doc = await _firestore.collection('events').doc(eventId).get();
      final imageFile = doc.data()?['image_file'] as String?;
      if (imageFile != null) {
        try {
          await _supabase.storage
              .from('assets')
              .remove(['event_images/$imageFile']);
        } catch (e) {
          debugPrint('MapDataService: Could not delete image file: $e');
          // Non-fatal — continue with Firestore delete
        }
      }
      await _firestore.collection('events').doc(eventId).delete();
    } catch (e) {
      debugPrint('MapDataService: Error deleting event: $e');
      rethrow;
    }
  }

  // ─────────────────────────────────────────
  // Ad-hoc queries (used outside the stream)
  // ─────────────────────────────────────────

  /// Fetches events for a specific [day] directly from Firestore.
  /// Firestore offline persistence serves this from cache when offline.
  static Future<List<Event>> getEventsByDay(int day) async {
    try {
      final snap = await _firestore
          .collection('events')
          .where('day', isEqualTo: day)
          .orderBy('time')
          .get();
      return buildEventsFromDocs(snap.docs);
    } catch (e) {
      debugPrint('MapDataService: Error getting events for day $day: $e');
      return [];
    }
  }
}
