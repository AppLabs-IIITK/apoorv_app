import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../../constants.dart';

class SeedResult {
  final int locations;
  final int events;
  final List<String> warnings;

  const SeedResult({
    required this.locations,
    required this.events,
    this.warnings = const [],
  });

  bool get hasWarnings => warnings.isNotEmpty;
}

class MapSeedService {
  static final _firestore = FirebaseFirestore.instance;
  static const _assetPath = 'assets/data/apoorv_2026_seed.json';

  static Future<SeedResult> seedApoorvMapData() async {
    final rawJson = await rootBundle.loadString(_assetPath);
    final data = jsonDecode(rawJson) as Map<String, dynamic>;
    final locations = (data['locations'] as List<dynamic>)
        .map((item) => Map<String, dynamic>.from(item as Map))
        .toList();
    final events = (data['events'] as List<dynamic>)
        .map((item) => Map<String, dynamic>.from(item as Map))
        .toList();

    final warnings = <String>[];

    final locationBatches = _chunk(locations, 490);
    for (final chunk in locationBatches) {
      final batch = _firestore.batch();
      for (final location in chunk) {
        final id = location['id']?.toString();
        if (id == null || id.isEmpty) {
          warnings.add('Skipped a location without an id.');
          continue;
        }
        batch.set(
          _firestore.collection('locations').doc(id),
          {
            'location_name': location['location_name'],
            'latitude': location['latitude'],
            'longitude': location['longitude'],
            'marker_color': location['marker_color'],
            'text_color': location['text_color'],
            'created_at': location['created_at'],
          },
        );
      }
      await batch.commit();
    }

    final eventBatches = _chunk(events, 490);
    for (final chunk in eventBatches) {
      final batch = _firestore.batch();
      for (final event in chunk) {
        final id = event['id']?.toString();
        if (id == null || id.isEmpty) {
          warnings.add('Skipped an event without an id.');
          continue;
        }

        // Debug logging for Chenda Melam event
        if (id == 'event-chenda-melam-day1') {
          debugPrint('🔍 Seeding Chenda Melam: end_location_id = ${event['end_location_id']}');
        }

        batch.set(
          _firestore.collection('events').doc(id),
          {
            'title': event['title'],
            'description': event['description'],
            'image_file': event['image_file'],
            'registration_link': event['registration_link'],
            'color': event['color'],
            'text_color': event['text_color'],
            'day': event['day'],
            'time': event['time'],
            'location_id': event['location_id'],
            'end_location_id': event['end_location_id'],
            'room_number': event['room_number'],
            'created_at': event['created_at'],
          },
        );
      }
      await batch.commit();
    }

    return SeedResult(
      locations: locations.length,
      events: events.length,
      warnings: warnings,
    );
  }

  static List<List<T>> _chunk<T>(List<T> items, int size) {
    final chunks = <List<T>>[];
    for (var index = 0; index < items.length; index += size) {
      final end = index + size > items.length ? items.length : index + size;
      chunks.add(items.sublist(index, end));
    }
    return chunks;
  }

  static Future<void> showSeedDialog(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: Constants.blackColor,
        title: const Row(
          children: [
            Icon(Icons.dataset, color: Constants.redColor),
            SizedBox(width: 10),
            Text(
              'Seed Apoorv Data',
              style: TextStyle(color: Constants.whiteColor, fontSize: 18),
            ),
          ],
        ),
        content: const Text(
          'This imports the curated Apoorv 2026 map locations and events from the bundled JSON seed file.\n\n'
          'Existing documents with the same ids will be overwritten.',
          style: TextStyle(color: Constants.creamColor),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text(
              'Cancel',
              style: TextStyle(color: Constants.creamColor),
            ),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Constants.redColor,
              foregroundColor: Constants.whiteColor,
            ),
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Import'),
          ),
        ],
      ),
    );

    if (confirmed != true || !context.mounted) {
      return;
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const PopScope(
        canPop: false,
        child: AlertDialog(
          backgroundColor: Constants.blackColor,
          content: Padding(
            padding: EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(color: Constants.redColor),
                SizedBox(height: 16),
                Text(
                  'Importing seed data...',
                  style: TextStyle(color: Constants.creamColor),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    SeedResult? result;
    String? fatalError;

    try {
      result = await seedApoorvMapData();
    } catch (error) {
      fatalError = error.toString();
    }

    if (!context.mounted) {
      return;
    }

    Navigator.of(context).pop();

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: Constants.blackColor,
        title: Row(
          children: [
            Icon(
              fatalError == null ? Icons.check_circle : Icons.error,
              color: fatalError == null ? Colors.green : Colors.red,
            ),
            const SizedBox(width: 10),
            Text(
              fatalError == null ? 'Seed Complete' : 'Seed Failed',
              style: const TextStyle(
                color: Constants.whiteColor,
                fontSize: 18,
              ),
            ),
          ],
        ),
        content: fatalError != null
            ? Text(
                fatalError,
                style: const TextStyle(color: Colors.redAccent),
              )
            : Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${result!.locations} locations imported\n${result.events} events imported',
                    style: const TextStyle(color: Constants.creamColor),
                  ),
                  if (result.hasWarnings) ...[
                    const SizedBox(height: 12),
                    Text(
                      result.warnings.join('\n'),
                      style: const TextStyle(
                        color: Colors.amber,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ],
              ),
        actions: [
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Constants.redColor,
              foregroundColor: Constants.whiteColor,
            ),
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Done'),
          ),
        ],
      ),
    );
  }
}
