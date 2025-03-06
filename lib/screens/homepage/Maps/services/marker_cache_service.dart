import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../../../utils/Models/Feed.dart';
import 'package:latlong2/latlong.dart';
import 'dart:io';

class MarkerCacheManager extends CacheManager {
  static const key = 'markerCache';
  static MarkerCacheManager? _instance;
  static const Duration _maxAge = Duration(hours: 1);

  factory MarkerCacheManager() {
    _instance ??= MarkerCacheManager._();
    return _instance!;
  }

  MarkerCacheManager._()
      : super(
          Config(
            key,
            stalePeriod: _maxAge,
            maxNrOfCacheObjects: 100,
            repo: JsonCacheInfoRepository(databaseName: key),
            fileService: HttpFileService(),
          ),
        );

  static const String markersJsonKey = 'markers_json_cache';
  static const String eventsJsonKey = 'events_json_cache';
  static const String markerImagePrefix = 'marker_image_';
  static const String eventImagePrefix = 'event_image_';

  /// Caches marker data in JSON format
  Future<void> cacheMarkerData(List<dynamic> markersJson) async {
    final jsonString = jsonEncode(markersJson);
    await putFile(
      markersJsonKey,
      Uint8List.fromList(utf8.encode(jsonString)),
      key: markersJsonKey,
      maxAge: _maxAge,
    );
    debugPrint('Cached ${markersJson.length} markers');
  }

  /// Caches event data in JSON format
  Future<void> cacheEventData(List<dynamic> eventsJson) async {
    // Convert image_file to complete URLs before caching
    final eventsWithUrls = eventsJson.map((event) {
      if (event['image_file'] != null) {
        event = Map<String, dynamic>.from(event);
        event['image_url'] = Supabase.instance.client.storage
            .from('assets')
            .getPublicUrl('event_images/${event['image_file']}');
      }
      return event;
    }).toList();

    final jsonString = jsonEncode(eventsWithUrls);
    await putFile(
      eventsJsonKey,
      Uint8List.fromList(utf8.encode(jsonString)),
      key: eventsJsonKey,
      maxAge: _maxAge,
    );
    debugPrint('Cached ${eventsJson.length} events with URLs');
  }

  /// Retrieves cached marker data
  Future<List<dynamic>?> getCachedMarkerData() async {
    try {
      final fileInfo = await getFileFromCache(markersJsonKey);
      if (fileInfo != null) {
        final jsonString = await fileInfo.file.readAsString();
        final markersJson = jsonDecode(jsonString) as List<dynamic>;
        debugPrint('Loaded ${markersJson.length} markers from cache');
        return markersJson;
      }
    } catch (e) {
      debugPrint('Error loading markers from cache: $e');
    }
    return null;
  }

  /// Retrieves cached event data
  Future<List<dynamic>?> getCachedEventData() async {
    try {
      final fileInfo = await getFileFromCache(eventsJsonKey);
      if (fileInfo != null) {
        final jsonString = await fileInfo.file.readAsString();
        final eventsJson = jsonDecode(jsonString) as List<dynamic>;
        debugPrint('Loaded ${eventsJson.length} events from cache');
        return eventsJson;
      }
    } catch (e) {
      debugPrint('Error loading events from cache: $e');
    }
    return null;
  }

  /// Caches an image and returns the cached file path
  Future<String?> cacheImage(String imageUrl, String prefix) async {
    try {
      final fileInfo = await downloadFile(
        imageUrl,
        key: '$prefix$imageUrl',
      );
      return fileInfo.file.path;
    } catch (e) {
      debugPrint('Error caching image: $e');
      return null;
    }
  }

  /// Gets a cached image
  Future<Image?> getCachedImage(String imageUrl, String prefix) async {
    try {
      debugPrint('Attempting to get cached image for URL: $imageUrl');

      // First try to get from cache
      final fileInfo = await getFileFromCache('$prefix$imageUrl');
      if (fileInfo != null) {
        debugPrint('Found image in cache');
        return Image.file(fileInfo.file);
      }

      // If not in cache, download and cache it
      debugPrint('Image not in cache, downloading...');
      final imagePath = await cacheImage(imageUrl, prefix);
      if (imagePath != null) {
        debugPrint('Successfully cached image at: $imagePath');
        return Image.file(File(imagePath));
      }

      // If caching failed, fall back to network image
      debugPrint('Caching failed, falling back to network image');
      return Image.network(imageUrl);
    } catch (e) {
      debugPrint('Error loading cached image: $e');
      // Try network image as last resort
      return Image.network(imageUrl);
    }
  }

  /// Caches a marker image and returns the cached file path
  Future<String?> cacheMarkerImage(String imageUrl) async {
    return cacheImage(imageUrl, markerImagePrefix);
  }

  /// Gets a cached marker image
  Future<Image?> getCachedMarkerImage(String imageUrl) async {
    return getCachedImage(imageUrl, markerImagePrefix);
  }

  /// Caches an event image and returns the cached file path
  Future<String?> cacheEventImage(String imageUrl) async {
    return cacheImage(imageUrl, eventImagePrefix);
  }

  /// Gets a cached event image
  Future<Image?> getCachedEventImage(String imageUrl) async {
    return getCachedImage(imageUrl, eventImagePrefix);
  }

  /// Converts marker JSON to MapMarker objects
  Future<List<MapMarker>> convertJsonToMarkers(
      List<dynamic> markersJson, List<Event> events) async {
    final List<MapMarker> markers = [];

    for (var markerData in markersJson) {
      // Filter events for this marker
      final markerEvents = events
          .where((event) => event.locationId == markerData['id'])
          .toList();

      markers.add(MapMarker(
        id: markerData['id'],
        locationName: markerData['location_name'],
        position: LatLng(
          (markerData['latitude'] as num).toDouble(),
          (markerData['longitude'] as num).toDouble(),
        ),
        markerColor: Color(markerData['marker_color'] is String
            ? int.parse(markerData['marker_color'])
            : markerData['marker_color'] as int),
        textColor: Color(markerData['text_color'] is String
            ? int.parse(markerData['text_color'])
            : markerData['text_color'] as int),
        events: markerEvents,
        createdAt: DateTime.parse(markerData['created_at']),
      ));
    }

    return markers;
  }

  /// Converts event JSON to Event objects
  Future<List<Event>> convertJsonToEvents(List<dynamic> eventsJson) async {
    final List<Event> events = [];

    for (var eventData in eventsJson) {
      Image? eventImage;
      final imageUrl = eventData['image_url'] as String?;

      // If imageUrl is null, construct it from image_file
      if (imageUrl != null) {
        eventImage = await getCachedEventImage(imageUrl);
      } else if (eventData['image_file'] != null) {
        final constructedUrl = Supabase.instance.client.storage
            .from('assets')
            .getPublicUrl('event_images/${eventData['image_file']}');
        eventImage = await getCachedEventImage(constructedUrl);
      }

      events.add(Event(
        id: eventData['id'],
        title: eventData['title'],
        description: eventData['description'],
        image: eventImage,
        imageFile: eventData['image_file'],
        color: Color(eventData['color'] is String
            ? int.parse(eventData['color'])
            : eventData['color'] as int),
        txtcolor: Color(eventData['text_color'] is String
            ? int.parse(eventData['text_color'])
            : eventData['text_color'] as int),
        day: eventData['day'] as int,
        time: eventData['time'],
        locationId: eventData['location_id'],
        roomNumber: eventData['room_number'] ?? '',
        createdAt: DateTime.parse(eventData['created_at']),
      ));
    }

    return events;
  }
}
