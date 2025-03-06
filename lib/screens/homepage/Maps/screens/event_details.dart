import 'package:flutter/material.dart';
import '../../../../../../constants.dart';
import '../../../../../../utils/Models/Feed.dart';
import '../components/marker_dialogs.dart';

class EventDetailsScreen extends StatelessWidget {
  final Event event;
  final String locationName;
  final Function(Event) onEventUpdated;
  final Function(String) onEventDeleted;

  const EventDetailsScreen({
    super.key,
    required this.event,
    required this.locationName,
    required this.onEventUpdated,
    required this.onEventDeleted,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Constants.blackColor,
      appBar: AppBar(
        backgroundColor: Constants.blackColor,
        title: Text(
          event.title,
          style: const TextStyle(color: Constants.whiteColor),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (event.image != null)
              Padding(
                padding: const EdgeInsets.all(16),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.grey[850], // Grayish background color
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Constants.blackColor.withOpacity(0.3),
                      width: 1,
                    ),
                  ),
                  width: double.infinity,
                  child: Center(
                    child: event.image,
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
                    '$locationName${event.roomNumber.isNotEmpty ? ' - Room ${event.roomNumber}' : ''}',
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
                        // Implement share functionality
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

  void _showEditEventDialog(BuildContext context) {
    MarkerDialogs.showEditEventDialog(
      context: context,
      event: event,
      locationName: locationName,
      onEventUpdated: onEventUpdated,
      onColorsSelected: (_, __) {},
    );
  }

  void _showDeleteEventDialog(BuildContext context) {
    MarkerDialogs.showDeleteEventDialog(
      context: context,
      eventId: event.id,
      onEventDeleted: () {
        onEventDeleted(event.id);
        Navigator.of(context).pop(); // Return to previous screen
      },
    );
  }
}
