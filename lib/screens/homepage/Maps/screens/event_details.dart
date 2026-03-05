import 'package:apoorv_app/utils/models/feed.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../../../../constants.dart';
import '../../../../../providers/app_config_provider.dart';
import '../components/marker_dialogs.dart';
import '../services/map_data_service.dart';

class EventDetailsScreen extends StatefulWidget {
  final Event event;
  final String locationName;

  const EventDetailsScreen({
    super.key,
    required this.event,
    required this.locationName,
  });

  @override
  State<EventDetailsScreen> createState() => _EventDetailsScreenState();
}

class _EventDetailsScreenState extends State<EventDetailsScreen> {
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DocumentSnapshot>(
      stream: MapDataService.getEventStream(widget.event.id),
      builder: (context, snapshot) {
        // Build event from snapshot or use the original
        Event displayEvent = widget.event;
        if (snapshot.hasData && snapshot.data!.exists) {
          final data = snapshot.data!.data() as Map<String, dynamic>;
          // Rebuild the event with updated data
          displayEvent = Event(
            id: widget.event.id,
            title: data['title'] ?? widget.event.title,
            description: data['description'] ?? widget.event.description,
            imageUrl: widget.event.imageUrl, // Keep the cached image URL
            imageFile: data['image_file'] ?? widget.event.imageFile,
            color: Color(data['color'] is String
                ? int.parse(data['color'] as String)
                : data['color'] as int),
            txtcolor: Color(data['text_color'] is String
                ? int.parse(data['text_color'] as String)
                : data['text_color'] as int),
            day: data['day'] as int,
            time: data['time'] ?? widget.event.time,
            locationId: data['location_id'] ?? widget.event.locationId,
            roomNumber: data['room_number'] ?? widget.event.roomNumber,
            createdAt: DateTime.parse(data['created_at'] as String),
          );
        }

        return _buildScaffold(context, displayEvent);
      },
    );
  }

  Widget _buildScaffold(BuildContext context, Event event) {
    return Scaffold(
      backgroundColor: Constants.blackColor,
      appBar: AppBar(
        backgroundColor: Constants.blackColor,
        title: Text(
          event.title,
          style: const TextStyle(color: Constants.whiteColor),
        ),
        actions: [
          Consumer<AppConfigProvider>(
            builder: (context, config, _) {
              if (!config.isAdmin) return const SizedBox.shrink();
              return Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.edit, color: Constants.redColor),
                    onPressed: () => _showEditEventDialog(context, event),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete, color: Constants.redColor),
                    onPressed: () => _showDeleteEventDialog(context, event),
                  ),
                ],
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (event.imageUrl != null)
              Padding(
                padding: const EdgeInsets.all(16),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.grey[850],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Constants.blackColor.withOpacity(0.3),
                      width: 1,
                    ),
                  ),
                  width: double.infinity,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.network(
                      event.imageUrl!,
                      fit: BoxFit.cover,
                      loadingBuilder: (context, child, loadingProgress) {
                        if (loadingProgress == null) return child;
                        return const Center(
                          child: CircularProgressIndicator(color: Constants.redColor),
                        );
                      },
                      errorBuilder: (context, error, stackTrace) => const Center(
                        child: Icon(Icons.broken_image, color: Constants.creamColor, size: 48),
                      ),
                    ),
                  ),
                ),
              ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Event title
                  Text(
                    event.title,
                    style: const TextStyle(
                      color: Constants.whiteColor,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Location and room
                  _buildInfoRow(
                    Icons.location_on,
                    '${widget.locationName}${event.roomNumber.isNotEmpty ? ' - Room ${event.roomNumber}' : ''}',
                  ),

                  // Day and time
                  _buildInfoRow(
                    Icons.calendar_today,
                    'Day ${event.day}',
                  ),
                  _buildInfoRow(
                    Icons.access_time,
                    event.time,
                  ),

                  const SizedBox(height: 24),

                  // Description
                  if (event.description != null &&
                      event.description!.isNotEmpty) ...[
                    const Text(
                      'Description',
                      style: TextStyle(
                        color: Constants.creamColor,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      event.description!,
                      style: const TextStyle(
                        color: Constants.creamColor,
                        fontSize: 16,
                      ),
                    ),
                  ],

                  const SizedBox(height: 32),

                  // Share button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Share functionality coming soon!'),
                          ),
                        );
                      },
                      icon: const Icon(Icons.share),
                      label: const Text('Share Event'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Constants.redColor,
                        foregroundColor: Constants.whiteColor,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(icon, color: Constants.redColor, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                color: Constants.creamColor,
                fontSize: 16,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showEditEventDialog(BuildContext context, Event event) {
    MarkerDialogs.showEditEventDialog(
      context: context,
      event: event,
      locationName: widget.locationName,
      onColorsSelected: (_, __) {},
    );
  }

  void _showDeleteEventDialog(BuildContext context, Event event) {
    MarkerDialogs.showDeleteEventDialog(
      context: context,
      eventId: event.id,
      onEventDeleted: () {
        Navigator.of(context).pop(); // Return to previous screen
      },
    );
  }
}
