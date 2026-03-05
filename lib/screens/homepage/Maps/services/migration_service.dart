// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:flutter/material.dart';
// import 'package:supabase_flutter/supabase_flutter.dart';

// class MigrationResult {
//   final int locations;
//   final int events;
//   final List<String> errors;

//   const MigrationResult({
//     required this.locations,
//     required this.events,
//     this.errors = const [],
//   });

//   bool get hasErrors => errors.isNotEmpty;
// }

// /// One-shot migration: Supabase → Firestore.
// ///
// /// Preserves Supabase UUIDs as Firestore document IDs so that
// /// existing `location_id` references in events remain valid.
// ///
// /// Safe to run multiple times — uses [SetOptions(merge: false)] which
// /// overwrites existing docs, effectively making it idempotent.
// class MigrationService {
//   static final _firestore = FirebaseFirestore.instance;
//   static final _supabase = Supabase.instance.client;

//   /// Migrates all rows from Supabase `locations` and `events` tables
//   /// to Firestore collections with the same names.
//   static Future<MigrationResult> migrateAll() async {
//     final errors = <String>[];
//     int migratedLocations = 0;
//     int migratedEvents = 0;

//     // ── 1. Fetch from Supabase ────────────────────────────────────────────
//     debugPrint('MigrationService: Fetching locations from Supabase...');
//     final List<dynamic> locationsRaw =
//         await _supabase.from('locations').select();

//     debugPrint('MigrationService: Fetching events from Supabase...');
//     final List<dynamic> eventsRaw = await _supabase.from('events').select();

//     debugPrint(
//         'MigrationService: Found ${locationsRaw.length} locations, '
//         '${eventsRaw.length} events.');

//     // ── 2. Write locations to Firestore ───────────────────────────────────
//     // Firestore batch limit is 500 — split if needed.
//     final locationBatches = _chunk(locationsRaw, 490);
//     for (final batch in locationBatches) {
//       final wBatch = _firestore.batch();
//       for (final loc in batch) {
//         final id = loc['id']?.toString();
//         if (id == null) {
//           errors.add('Location missing id: $loc');
//           continue;
//         }
//         final docRef = _firestore.collection('locations').doc(id);
//         wBatch.set(docRef, {
//           'location_name': loc['location_name'],
//           'latitude': (loc['latitude'] as num).toDouble(),
//           'longitude': (loc['longitude'] as num).toDouble(),
//           'marker_color': loc['marker_color'],
//           'text_color': loc['text_color'],
//           'created_at': loc['created_at'],
//         });
//         migratedLocations++;
//       }
//       await wBatch.commit();
//     }
//     debugPrint(
//         'MigrationService: Wrote $migratedLocations locations to Firestore.');

//     // ── 3. Write events to Firestore ──────────────────────────────────────
//     final eventBatches = _chunk(eventsRaw, 490);
//     for (final batch in eventBatches) {
//       final wBatch = _firestore.batch();
//       for (final event in batch) {
//         final id = event['id']?.toString();
//         if (id == null) {
//           errors.add('Event missing id: $event');
//           continue;
//         }
//         final docRef = _firestore.collection('events').doc(id);
//         wBatch.set(docRef, {
//           'title': event['title'],
//           'description': event['description'],
//           'image_file': event['image_file'],
//           'color': event['color'],
//           'text_color': event['text_color'],
//           'day': event['day'],
//           'time': event['time'],
//           'location_id': event['location_id']?.toString(),
//           'room_number': event['room_number'] ?? '',
//           'created_at': event['created_at'],
//         });
//         migratedEvents++;
//       }
//       await wBatch.commit();
//     }
//     debugPrint(
//         'MigrationService: Wrote $migratedEvents events to Firestore.');

//     return MigrationResult(
//       locations: migratedLocations,
//       events: migratedEvents,
//       errors: errors,
//     );
//   }

//   // Splits [list] into chunks of at most [size].
//   static List<List<T>> _chunk<T>(List<T> list, int size) {
//     final chunks = <List<T>>[];
//     for (var i = 0; i < list.length; i += size) {
//       chunks.add(list.sublist(i, i + size > list.length ? list.length : i + size));
//     }
//     return chunks;
//   }

//   /// Shows the migration dialog (confirm → progress → result).
//   /// Call this from a temporary admin button.
//   static Future<void> showMigrationDialog(BuildContext context) async {
//     final confirmed = await showDialog<bool>(
//       context: context,
//       builder: (ctx) => AlertDialog(
//         backgroundColor: Colors.grey[900],
//         title: const Row(
//           children: [
//             Icon(Icons.warning_amber, color: Colors.amber),
//             SizedBox(width: 8),
//             Text('Migrate Data',
//                 style: TextStyle(color: Colors.white, fontSize: 18)),
//           ],
//         ),
//         content: const Text(
//           'This will copy all data from Supabase (locations & events) '
//           'into Firestore.\n\n'
//           'Existing Firestore documents with the same ID will be overwritten.\n\n'
//           'Run this once during initial migration.',
//           style: TextStyle(color: Colors.white70),
//         ),
//         actions: [
//           TextButton(
//             onPressed: () => Navigator.of(ctx).pop(false),
//             child: const Text('Cancel',
//                 style: TextStyle(color: Colors.white54)),
//           ),
//           FilledButton(
//             style: FilledButton.styleFrom(backgroundColor: Colors.amber[700]),
//             onPressed: () => Navigator.of(ctx).pop(true),
//             child: const Text('Run Migration'),
//           ),
//         ],
//       ),
//     );

//     if (confirmed != true || !context.mounted) return;

//     // Show progress indicator
//     showDialog(
//       context: context,
//       barrierDismissible: false,
//       builder: (_) => const PopScope(
//         canPop: false,
//         child: AlertDialog(
//           backgroundColor: Colors.black,
//           content: Padding(
//             padding: EdgeInsets.all(24),
//             child: Column(
//               mainAxisSize: MainAxisSize.min,
//               children: [
//                 CircularProgressIndicator(),
//                 SizedBox(height: 16),
//                 Text('Migrating…',
//                     style: TextStyle(color: Colors.white70)),
//               ],
//             ),
//           ),
//         ),
//       ),
//     );

//     MigrationResult? result;
//     String? fatalError;

//     try {
//       result = await migrateAll();
//     } catch (e) {
//       fatalError = e.toString();
//       debugPrint('MigrationService: Fatal error — $e');
//     }

//     if (!context.mounted) return;
//     Navigator.of(context).pop(); // close progress dialog

//     // Show result
//     showDialog(
//       context: context,
//       builder: (ctx) => AlertDialog(
//         backgroundColor: Colors.grey[900],
//         title: Row(
//           children: [
//             Icon(
//               fatalError != null
//                   ? Icons.error
//                   : (result!.hasErrors ? Icons.warning_amber : Icons.check_circle),
//               color: fatalError != null
//                   ? Colors.red
//                   : (result!.hasErrors ? Colors.amber : Colors.green),
//             ),
//             const SizedBox(width: 8),
//             Text(
//               fatalError != null ? 'Migration Failed' : 'Migration Complete',
//               style: const TextStyle(color: Colors.white, fontSize: 18),
//             ),
//           ],
//         ),
//         content: fatalError != null
//             ? Text(fatalError,
//                 style: const TextStyle(color: Colors.red, fontSize: 13))
//             : Column(
//                 mainAxisSize: MainAxisSize.min,
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   Text(
//                     '✅  ${result!.locations} locations migrated\n'
//                     '✅  ${result.events} events migrated',
//                     style: const TextStyle(color: Colors.white70),
//                   ),
//                   if (result.hasErrors) ...[
//                     const SizedBox(height: 12),
//                     Text(
//                       '⚠️  ${result.errors.length} error(s):\n'
//                       '${result.errors.join('\n')}',
//                       style: const TextStyle(
//                           color: Colors.amber, fontSize: 12),
//                     ),
//                   ],
//                 ],
//               ),
//         actions: [
//           FilledButton(
//             onPressed: () => Navigator.of(ctx).pop(),
//             child: const Text('Done'),
//           ),
//         ],
//       ),
//     );
//   }
// }
