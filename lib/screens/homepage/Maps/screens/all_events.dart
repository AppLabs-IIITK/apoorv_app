import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import '../../../../../../constants.dart';
import '../../../../../../utils/Models/Feed.dart';
import '../components/marker_dialogs.dart';
import 'event_details.dart';

class AllEventsScreen extends StatefulWidget {
  final List<MapMarker> markers;
  final Function(Event) onEventUpdated;
  final Function(String) onEventDeleted;

  const AllEventsScreen({
    super.key,
    required this.markers,
    required this.onEventUpdated,
    required this.onEventDeleted,
  });

  @override
  State<AllEventsScreen> createState() => _AllEventsScreenState();
}

class _AllEventsScreenState extends State<AllEventsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  int _selectedDay = 1;
  List<Event> _allEvents = [];
  List<Event> _filteredEvents = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(_handleTabChange);
    _loadEvents();
  }

  @override
  void dispose() {
    _tabController.removeListener(_handleTabChange);
    _tabController.dispose();
    super.dispose();
  }

  void _handleTabChange() {
    if (!_tabController.indexIsChanging) {
      final newDay = _tabController.index + 1;

      setState(() {
        _selectedDay = newDay;
      });

      // Call filter events after state is updated
      _filterEvents();
    }
  }

  Future<void> _loadEvents() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Extract all events from markers
      final allEvents = <Event>[];

      for (final marker in widget.markers) {
        for (final event in marker.events) {
          // Create a copy of the event with the location name
          final eventWithLocation = Event(
            id: event.id,
            title: event.title,
            description: event.description,
            image: event.image,
            imageFile: event.imageFile,
            color: event.color,
            txtcolor: event.txtcolor,
            day: event.day,
            time: event.time,
            locationId: event.locationId,
            roomNumber: event.roomNumber,
            createdAt: event.createdAt,
          );

          allEvents.add(eventWithLocation);
        }
      }

      setState(() {
        _allEvents = allEvents;
        _isLoading = false;
      });

      _filterEvents();
    } catch (e) {
      setState(() {
        _isLoading = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load events: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _filterEvents() {
    final dayEvents =
        _allEvents.where((event) => event.day == _selectedDay).toList();

    // Sort by time
    dayEvents.sort((a, b) {
      // Extract start time from format "HH:MM AM/PM - HH:MM AM/PM"
      String getStartTime(String timeRange) {
        final startTime = timeRange.split('-')[0].trim();
        // Convert to 24-hour format for proper sorting
        final parts = startTime.split(' ');
        final time = parts[0].split(':');
        int hours = int.parse(time[0]);
        final minutes = int.parse(time[1]);
        final isPM = parts[1].toUpperCase() == 'PM';

        if (isPM && hours != 12) {
          hours += 12;
        } else if (!isPM && hours == 12) {
          hours = 0;
        }

        return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}';
      }

      final aStartTime = getStartTime(a.time);
      final bStartTime = getStartTime(b.time);
      return aStartTime.compareTo(bStartTime);
    });

    setState(() {
      _filteredEvents = dayEvents;
    });
  }

  String _getLocationName(String locationId) {
    final marker = widget.markers.firstWhere(
      (m) => m.id == locationId,
      orElse: () => MapMarker(
        id: '',
        locationName: 'Unknown Location',
        position: const LatLng(0, 0),
        markerColor: Colors.grey,
        textColor: Colors.white,
        events: [],
        createdAt: DateTime.now(),
      ),
    );

    return marker.locationName;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Constants.blackColor,
      appBar: AppBar(
        backgroundColor: Constants.blackColor,
        title: const Text('All Events'),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Constants.redColor,
          onTap: (index) {
            // Handle tab tap directly here for immediate response
            final newDay = index + 1;

            if (_selectedDay != newDay) {
              setState(() {
                _selectedDay = newDay;
              });

              _filterEvents();
            }
          },
          tabs: const [
            Tab(text: 'Day 1'),
            Tab(text: 'Day 2'),
            Tab(text: 'Day 3'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Constants.redColor))
          : _filteredEvents.isEmpty
              ? _buildNoEventsMessage()
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _filteredEvents.length,
                  itemBuilder: (context, index) {
                    final event = _filteredEvents[index];
                    return _buildEventCard(event);
                  },
                ),
    );
  }

  Widget _buildNoEventsMessage() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.event_busy,
            color: Constants.creamColor,
            size: 48,
          ),
          const SizedBox(height: 16),
          Text(
            'No events on Day $_selectedDay',
            style: const TextStyle(
              color: Constants.creamColor,
              fontSize: 18,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildEventCard(Event event) {
    final locationName = _getLocationName(event.locationId);

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => EventDetailsScreen(
              event: event,
              locationName: locationName,
              onEventUpdated: widget.onEventUpdated,
              onEventDeleted: widget.onEventDeleted,
            ),
          ),
        );
      },
      child: Card(
        margin: const EdgeInsets.only(bottom: 16),
        color: event.color,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (event.image != null)
              Padding(
                padding: const EdgeInsets.only(top: 8, left: 8, right: 8),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    color: Colors.black,
                    width: double.infinity,
                    height: 150,
                    child: Center(
                      child: event.image,
                    ),
                  ),
                ),
              ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    event.title,
                    style: TextStyle(
                      color: event.txtcolor,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (event.description != null &&
                      event.description!.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 8, bottom: 12),
                      child: Text(
                        event.description!,
                        style: TextStyle(
                          color: event.txtcolor.withOpacity(0.8),
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  Row(
                    children: [
                      Icon(Icons.location_on, color: event.txtcolor, size: 16),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          '$locationName${event.roomNumber.isNotEmpty ? ' - Room ${event.roomNumber}' : ''}',
                          style: TextStyle(
                            color: event.txtcolor,
                            fontWeight: FontWeight.w500,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Icons.access_time, color: event.txtcolor, size: 16),
                      const SizedBox(width: 4),
                      Text(
                        event.time,
                        style: TextStyle(
                          color: event.txtcolor,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
