import 'dart:io';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../../../utils/Models/Feed.dart';
import 'marker_cache_service.dart';

class SupabaseService {
  static final supabase = Supabase.instance.client;
  static final _markerCache = MarkerCacheManager();
  static bool _isComparingCache = false;

  // Compare and update cache in background
  static Future<void> compareAndUpdateCache(Function onDataUpdated) async {
    if (_isComparingCache) return; // Prevent multiple simultaneous comparisons
    _isComparingCache = true;

    try {
      debugPrint('Starting cache comparison...');

      // Check markers
      final cachedMarkersJson = await _markerCache.getCachedMarkerData();
      final cachedEventsJson = await _markerCache.getCachedEventData();

      if (cachedMarkersJson == null || cachedEventsJson == null) {
        debugPrint('No cached data found');
        _isComparingCache = false;
        return;
      }

      final markersResponse =
          await supabase.from('locations').select().order('created_at');
      final eventsResponse =
          await supabase.from('events').select().order('created_at');

      debugPrint('Retrieved fresh data from Supabase');

      // Compare if cache is outdated
      final isMarkerCacheOutdated =
          _isMarkerCacheOutdated(cachedMarkersJson, markersResponse);
      final isEventCacheOutdated =
          _isEventCacheOutdated(cachedEventsJson, eventsResponse);

      if (isMarkerCacheOutdated || isEventCacheOutdated) {
        debugPrint('Cache is outdated, updating...');

        if (isMarkerCacheOutdated) {
          await _markerCache.cacheMarkerData(markersResponse);
          debugPrint('Marker cache updated');
        }

        if (isEventCacheOutdated) {
          await _markerCache.cacheEventData(eventsResponse);
          debugPrint('Event cache updated');
        }

        onDataUpdated();
      } else {
        debugPrint('Cache is up to date, no update needed');
      }
    } catch (e) {
      debugPrint('Error comparing cache: $e');
    } finally {
      _isComparingCache = false;
    }
  }

  // Helper to check if marker cache is outdated
  static bool _isMarkerCacheOutdated(
      List<dynamic> cachedData, List<dynamic> freshData) {
    debugPrint('Comparing marker cache with fresh data...');
    debugPrint('Cached markers length: ${cachedData.length}');
    debugPrint('Fresh markers length: ${freshData.length}');

    if (cachedData.length != freshData.length) {
      debugPrint('Marker cache outdated: Different number of markers');
      return true;
    }

    for (var i = 0; i < cachedData.length; i++) {
      final cached = cachedData[i];
      final fresh = freshData[i];

      // Compare relevant fields
      if (cached['id'] != fresh['id'] ||
          cached['location_name'] != fresh['location_name'] ||
          cached['latitude'] != fresh['latitude'] ||
          cached['longitude'] != fresh['longitude'] ||
          cached['marker_color'] != fresh['marker_color'] ||
          cached['text_color'] != fresh['text_color']) {
        debugPrint(
            'Marker cache outdated: Differences found in marker ${fresh['id']}');
        return true;
      }
    }
    return false;
  }

  // Helper to check if event cache is outdated
  static bool _isEventCacheOutdated(
      List<dynamic> cachedData, List<dynamic> freshData) {
    debugPrint('Comparing event cache with fresh data...');
    debugPrint('Cached events length: ${cachedData.length}');
    debugPrint('Fresh events length: ${freshData.length}');

    if (cachedData.length != freshData.length) {
      debugPrint('Event cache outdated: Different number of events');
      return true;
    }

    for (var i = 0; i < cachedData.length; i++) {
      final cached = cachedData[i];
      final fresh = freshData[i];

      // Compare relevant fields
      if (cached['id'] != fresh['id'] ||
          cached['title'] != fresh['title'] ||
          cached['description'] != fresh['description'] ||
          cached['image_file'] != fresh['image_file'] ||
          cached['color'] != fresh['color'] ||
          cached['text_color'] != fresh['text_color'] ||
          cached['day'] != fresh['day'] ||
          cached['time'] != fresh['time'] ||
          cached['location_id'] != fresh['location_id'] ||
          cached['room_number'] != fresh['room_number']) {
        debugPrint(
            'Event cache outdated: Differences found in event ${fresh['id']}');
        return true;
      }
    }
    return false;
  }

  // Upload image to Supabase storage
  static Future<String> uploadImage(String imagePath, String folder) async {
    try {
      final file = File(imagePath);
      final fileExt = imagePath.split('.').last;
      final fileName = '${DateTime.now().millisecondsSinceEpoch}.$fileExt';
      await supabase.storage.from('assets').upload('$folder/$fileName', file);
      return fileName;
    } catch (e) {
      debugPrint('Error uploading image: $e');
      rethrow;
    }
  }

  // Upload marker image
  static Future<String> uploadMarkerImage(String imagePath) async {
    return uploadImage(imagePath, 'marker_images');
  }

  // Upload event image
  static Future<String> uploadEventImage(String imagePath) async {
    return uploadImage(imagePath, 'event_images');
  }

  // Get image from Supabase storage with caching
  static Future<Image?> getMarkerImage(String fileNameOrUrl) async {
    try {
      // Check if it's a full URL or just a filename
      final isUrl = fileNameOrUrl.startsWith('http');
      final imageUrl = isUrl
          ? fileNameOrUrl
          : supabase.storage
              .from('assets')
              .getPublicUrl('marker_images/$fileNameOrUrl');

      // Try to get image from cache first
      final cachedImage = await _markerCache.getCachedMarkerImage(imageUrl);
      if (cachedImage != null) {
        debugPrint('Using cached marker image');
        return cachedImage;
      }

      // If not in cache, download and cache it
      debugPrint('Marker image not in cache, downloading...');
      final imagePath = await _markerCache.cacheMarkerImage(imageUrl);
      if (imagePath != null) {
        debugPrint('Successfully cached marker image');
        return Image.file(File(imagePath));
      }

      return Image.network(imageUrl);
    } catch (e) {
      debugPrint('Error getting marker image: $e');
      return null;
    }
  }

  // Get event image from Supabase storage with caching
  static Future<Image?> getEventImage(String fileNameOrUrl) async {
    try {
      // Check if it's a full URL or just a filename
      final isUrl = fileNameOrUrl.startsWith('http');
      final imageUrl = isUrl
          ? fileNameOrUrl
          : supabase.storage
              .from('assets')
              .getPublicUrl('event_images/$fileNameOrUrl');

      // Try to get image from cache first
      final cachedImage = await _markerCache.getCachedEventImage(imageUrl);
      if (cachedImage != null) {
        debugPrint('Using cached event image');
        return cachedImage;
      }

      // If not in cache, download and cache it
      debugPrint('Event image not in cache, downloading...');
      final imagePath = await _markerCache.cacheEventImage(imageUrl);
      if (imagePath != null) {
        debugPrint('Successfully cached event image');
        return Image.file(File(imagePath));
      }

      return Image.network(imageUrl);
    } catch (e) {
      debugPrint('Error getting event image: $e');
      return null;
    }
  }

  // Save location to Supabase database and update cache
  static Future<String> saveLocation(MapMarker marker) async {
    try {
      final response = await supabase.from('locations').insert({
        'location_name': marker.locationName,
        'latitude': marker.position.latitude,
        'longitude': marker.position.longitude,
        'marker_color': marker.markerColor.value,
        'text_color': marker.textColor.value,
        'created_at': marker.createdAt.toIso8601String(),
      }).select();

      // Get the ID generated by Supabase
      final locationId = response[0]['id'];

      // Update cache after successful save
      final markersJson = await supabase.from('locations').select();
      await _markerCache.cacheMarkerData(markersJson);

      return locationId;
    } catch (e) {
      debugPrint('Error saving location: $e');
      rethrow;
    }
  }

  // Save event to Supabase database and update cache
  static Future<String> saveEvent(Event event, String? imageFileName) async {
    try {
      final response = await supabase.from('events').insert({
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
      }).select();

      final eventId = response[0]['id'];
      debugPrint('Event saved with ID: $eventId');

      // Update cache after successful save
      final eventsJson = await supabase.from('events').select();
      await _markerCache.cacheEventData(eventsJson);

      return eventId;
    } catch (e) {
      debugPrint('Error saving event: $e');
      rethrow;
    }
  }

  // Get all markers and events from cache or Supabase
  static Future<List<MapMarker>> getMarkersWithEvents() async {
    try {
      debugPrint('Starting getMarkersWithEvents()...');

      // Try to get data from cache first
      final cachedMarkersJson = await _markerCache.getCachedMarkerData();
      final cachedEventsJson = await _markerCache.getCachedEventData();

      List<dynamic> markersJson;
      List<dynamic> eventsJson;

      if (cachedMarkersJson != null && cachedEventsJson != null) {
        debugPrint('Using cached markers and events');
        markersJson = cachedMarkersJson;
        eventsJson = cachedEventsJson;
      } else {
        // If not in cache, fetch from Supabase
        debugPrint('Fetching data from Supabase');
        markersJson =
            await supabase.from('locations').select().order('created_at');
        eventsJson = await supabase.from('events').select().order('created_at');

        // Cache the responses
        await _markerCache.cacheMarkerData(markersJson);
        await _markerCache.cacheEventData(eventsJson);
        debugPrint('Cached Supabase responses');
      }

      // First convert events
      final events = await _markerCache.convertJsonToEvents(eventsJson);
      debugPrint('Converted ${events.length} events');

      // Then convert markers with events
      final markers =
          await _markerCache.convertJsonToMarkers(markersJson, events);
      debugPrint('Converted ${markers.length} markers with events');

      return markers;
    } catch (e, stackTrace) {
      debugPrint('Error getting markers with events: $e');
      debugPrint('Stack trace: $stackTrace');
      return [];
    }
  }

  // Get events for a specific day
  static Future<List<Event>> getEventsByDay(int day) async {
    try {
      debugPrint('Getting events for day $day');

      // Try to get from cache first
      final cachedEventsJson = await _markerCache.getCachedEventData();
      List<dynamic> eventsJson;

      if (cachedEventsJson != null) {
        debugPrint('Using cached events');
        // Filter cached events by day
        eventsJson =
            cachedEventsJson.where((event) => event['day'] == day).toList();
      } else {
        // If not in cache, fetch from Supabase with filter
        debugPrint('Fetching events from Supabase for day $day');
        eventsJson =
            await supabase.from('events').select().eq('day', day).order('time');

        // We don't cache this filtered result
      }

      // Convert to Event objects
      final events = await _markerCache.convertJsonToEvents(eventsJson);
      debugPrint('Converted ${events.length} events for day $day');

      return events;
    } catch (e) {
      debugPrint('Error getting events for day $day: $e');
      return [];
    }
  }

  // Delete location and all associated events
  static Future<void> deleteLocation(String locationId) async {
    try {
      // First delete all events associated with this location
      await supabase.from('events').delete().eq('location_id', locationId);

      // Then delete the location
      await supabase.from('locations').delete().eq('id', locationId);

      // Update cache after successful delete
      final markersJson = await supabase.from('locations').select();
      final eventsJson = await supabase.from('events').select();
      await _markerCache.cacheMarkerData(markersJson);
      await _markerCache.cacheEventData(eventsJson);
    } catch (e) {
      debugPrint('Error deleting location: $e');
      rethrow;
    }
  }

  // Delete event
  static Future<void> deleteEvent(String eventId) async {
    try {
      // Get event image file before deleting
      final event = await supabase
          .from('events')
          .select('image_file')
          .eq('id', eventId)
          .single();

      // Delete image if exists
      final imageFile = event['image_file'] as String?;
      if (imageFile != null) {
        await supabase.storage
            .from('assets')
            .remove(['event_images/$imageFile']);
      }

      // Delete event record
      await supabase.from('events').delete().eq('id', eventId);

      // Update cache after successful delete
      final eventsJson = await supabase.from('events').select();
      await _markerCache.cacheEventData(eventsJson);
    } catch (e) {
      debugPrint('Error deleting event: $e');
      rethrow;
    }
  }

  // Update location
  static Future<void> updateLocation(MapMarker marker) async {
    try {
      await supabase.from('locations').update({
        'location_name': marker.locationName,
        'latitude': marker.position.latitude,
        'longitude': marker.position.longitude,
        'marker_color': marker.markerColor.value,
        'text_color': marker.textColor.value,
      }).eq('id', marker.id);

      // Update cache after successful update
      final markersJson = await supabase.from('locations').select();
      await _markerCache.cacheMarkerData(markersJson);
    } catch (e) {
      debugPrint('Error updating location: $e');
      rethrow;
    }
  }

  // Update event
  static Future<void> updateEvent(Event event, String? imageFileName) async {
    try {
      final updateData = {
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

      await supabase.from('events').update(updateData).eq('id', event.id);
      debugPrint('Event updated with ID: ${event.id}');

      // Update cache after successful update
      final eventsJson = await supabase.from('events').select();
      await _markerCache.cacheEventData(eventsJson);
    } catch (e) {
      debugPrint('Error updating event: $e');
      rethrow;
    }
  }
}
