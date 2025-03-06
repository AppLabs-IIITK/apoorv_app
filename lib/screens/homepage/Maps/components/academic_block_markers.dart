import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../../../../../../constants.dart';
import '../../../../../../utils/Models/Feed.dart';

class AcademicBlockMarkers extends StatefulWidget {
  final List<MapMarker> markers;
  final Function(MapMarker) onMarkerTapped;

  const AcademicBlockMarkers({
    super.key,
    required this.markers,
    required this.onMarkerTapped,
  });

  @override
  State<AcademicBlockMarkers> createState() => _AcademicBlockMarkersState();
}

class _AcademicBlockMarkersState extends State<AcademicBlockMarkers> {
  List<MapMarker> _academicMarkers = [];
  LatLng _blockPosition = const LatLng(0, 0);

  // For search functionality
  String _searchQuery = '';
  List<MapMarker> _filteredMarkers = [];

  // For floor filtering
  String _selectedFloor = 'All Floors';

  @override
  void initState() {
    super.initState();
    _groupMarkers();
  }

  @override
  void didUpdateWidget(AcademicBlockMarkers oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.markers != oldWidget.markers) {
      _groupMarkers();
    }
  }

  void _groupMarkers() {
    // Filter academic block markers (BB, BC, BD)
    _academicMarkers = widget.markers.where((marker) {
      final name = marker.locationName;
      return name.startsWith('BB') ||
          name.startsWith('BC') ||
          name.startsWith('BD');
    }).toList();

    // Use hardcoded position for academic block group
    if (_academicMarkers.isNotEmpty) {
      _blockPosition = const LatLng(9.755107, 76.64907);
      debugPrint(
          'Academic Block Position: ${_blockPosition.latitude}, ${_blockPosition.longitude}');
      debugPrint('Number of academic markers: ${_academicMarkers.length}');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_academicMarkers.isEmpty) return const MarkerLayer(markers: []);

    return MarkerLayer(
      markers: [
        Marker(
          width: 200.0, // Increased width for better visibility
          height: 100.0, // Increased height for better visibility
          point: _blockPosition,
          rotate: true, // Enable rotation if needed
          child: GestureDetector(
            onTap: () => _showRoomSelectionBottomSheet(_academicMarkers),
            child: _buildBlockMarkerWidget(_academicMarkers),
          ),
        ),
      ],
    );
  }

  Widget _buildBlockMarkerWidget(List<MapMarker> markers) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Stack(
          children: [
            Container(
              decoration: BoxDecoration(
                color: Constants.redColor,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Constants.blackColor.withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              padding: const EdgeInsets.all(8),
              child: const Icon(
                Icons.school,
                color: Constants.whiteColor,
                size: 28.0,
              ),
            ),
            Positioned(
              right: 0,
              bottom: 0,
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: Constants.redColor,
                  shape: BoxShape.circle,
                  border: Border.all(color: Constants.blackColor, width: 1),
                ),
                child: Text(
                  markers.length.toString(),
                  style: const TextStyle(
                    color: Constants.whiteColor,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: Constants.redColor,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: const Text(
            'Academic Block',
            style: TextStyle(
              color: Constants.whiteColor,
              fontWeight: FontWeight.w600,
              fontSize: 13,
            ),
            textAlign: TextAlign.center,
          ),
        ),
      ],
    );
  }

  // Extract floor number from room name (e.g., "BC 301" -> "3")
  String _getFloorFromRoomName(String roomName) {
    // Try to extract a 3-digit room number
    final RegExp regExp = RegExp(r'(\d{3})');
    final match = regExp.firstMatch(roomName);

    if (match != null) {
      // First digit of room number is the floor
      return match.group(1)!.substring(0, 1);
    }

    return '0'; // Default to ground floor if no match
  }

  // Get list of floors for a block
  List<String> _getFloorsForBlock(List<MapMarker> markers) {
    final Set<String> floors = {'All Floors'};

    for (final marker in markers) {
      final floor = _getFloorFromRoomName(marker.locationName);
      floors.add('Floor $floor');
    }

    return floors.toList()..sort();
  }

  void _showRoomSelectionBottomSheet(List<MapMarker> markers) {
    // Initialize filtered markers with all markers
    _filteredMarkers = List.from(markers);
    _searchQuery = '';
    _selectedFloor = 'All Floors';

    // Get floors for all rooms
    final floors = _getFloorsForBlock(markers);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(builder: (context, setModalState) {
          // Filter markers based on search query and selected floor
          void filterMarkers() {
            _filteredMarkers = markers.where((marker) {
              final matchesSearch = marker.locationName
                  .toLowerCase()
                  .contains(_searchQuery.toLowerCase());
              final matchesFloor = _selectedFloor == 'All Floors' ||
                  ('Floor ${_getFloorFromRoomName(marker.locationName)}' ==
                      _selectedFloor);
              return matchesSearch && matchesFloor;
            }).toList();
          }

          return DraggableScrollableSheet(
            initialChildSize: 0.6,
            minChildSize: 0.3,
            maxChildSize: 0.9,
            builder: (context, scrollController) {
              return Container(
                decoration: const BoxDecoration(
                  color: Constants.blackColor,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Handle bar
                    Center(
                      child: Container(
                        margin: const EdgeInsets.only(top: 10),
                        width: 40,
                        height: 5,
                        decoration: BoxDecoration(
                          color: Constants.creamColor.withOpacity(0.5),
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                    // Block name
                    const Padding(
                      padding: EdgeInsets.all(16),
                      child: Row(
                        children: [
                          Icon(
                            Icons.school,
                            color: Constants.redColor,
                            size: 24,
                          ),
                          SizedBox(width: 8),
                          Text(
                            'Academic Block',
                            style: TextStyle(
                              color: Constants.whiteColor,
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Floor selector
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Select Floor',
                            style: TextStyle(
                              color: Constants.creamColor,
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          SizedBox(
                            height: 40,
                            child: ListView.builder(
                              scrollDirection: Axis.horizontal,
                              itemCount: floors.length,
                              itemBuilder: (context, index) {
                                final floor = floors[index];
                                final isSelected = floor == _selectedFloor;

                                return GestureDetector(
                                  onTap: () {
                                    setModalState(() {
                                      _selectedFloor = floor;
                                      filterMarkers();
                                    });
                                  },
                                  child: Container(
                                    margin: const EdgeInsets.only(right: 8),
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 16),
                                    decoration: BoxDecoration(
                                      color: isSelected
                                          ? Constants.redColor
                                          : Constants.blackColor,
                                      borderRadius: BorderRadius.circular(20),
                                      border: Border.all(
                                        color: isSelected
                                            ? Constants.redColor
                                            : Constants.creamColor
                                                .withOpacity(0.3),
                                      ),
                                    ),
                                    child: Center(
                                      child: Text(
                                        floor,
                                        style: TextStyle(
                                          color: isSelected
                                              ? Constants.whiteColor
                                              : Constants.creamColor,
                                          fontWeight: isSelected
                                              ? FontWeight.bold
                                              : FontWeight.normal,
                                        ),
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Search bar
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: TextField(
                        decoration: InputDecoration(
                          hintText: 'Search rooms...',
                          hintStyle: TextStyle(
                              color: Constants.creamColor.withOpacity(0.5)),
                          prefixIcon: Icon(Icons.search,
                              color: Constants.creamColor.withOpacity(0.5)),
                          suffixIcon: _searchQuery.isNotEmpty
                              ? IconButton(
                                  icon: const Icon(Icons.clear,
                                      color: Constants.creamColor),
                                  onPressed: () {
                                    setModalState(() {
                                      _searchQuery = '';
                                      filterMarkers();
                                    });
                                  },
                                )
                              : null,
                          filled: true,
                          fillColor: Constants.blackColor.withOpacity(0.3),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide(
                                color: Constants.creamColor.withOpacity(0.2)),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide(
                                color: Constants.creamColor.withOpacity(0.2)),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide(
                                color: Constants.redColor.withOpacity(0.5)),
                          ),
                        ),
                        style: const TextStyle(color: Constants.whiteColor),
                        onChanged: (value) {
                          setModalState(() {
                            _searchQuery = value;
                            filterMarkers();
                          });
                        },
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Room count
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Text(
                        '${_filteredMarkers.length} ${_filteredMarkers.length == 1 ? 'room' : 'rooms'} found',
                        style: TextStyle(
                          color: Constants.creamColor.withOpacity(0.7),
                          fontSize: 14,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    // Rooms list
                    Expanded(
                      child: _filteredMarkers.isEmpty
                          ? _buildNoRoomsFound()
                          : ListView.builder(
                              controller: scrollController,
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 16),
                              itemCount: _filteredMarkers.length,
                              itemBuilder: (context, index) {
                                final marker = _filteredMarkers[index];
                                return _buildRoomItem(marker);
                              },
                            ),
                    ),
                  ],
                ),
              );
            },
          );
        });
      },
    );
  }

  Widget _buildNoRoomsFound() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.search_off,
            color: Constants.creamColor,
            size: 48,
          ),
          const SizedBox(height: 16),
          Text(
            'No rooms found matching "$_searchQuery"',
            style: const TextStyle(
              color: Constants.creamColor,
              fontSize: 16,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildRoomItem(MapMarker marker) {
    // Count events for this room
    final eventCount = marker.events.length;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      color: Constants.blackColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: BorderSide(color: Constants.creamColor.withOpacity(0.2)),
      ),
      child: InkWell(
        onTap: () {
          Navigator.pop(context);
          widget.onMarkerTapped(marker);
        },
        borderRadius: BorderRadius.circular(10),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: marker.markerColor,
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Icon(
                    Icons.meeting_room,
                    color: marker.textColor,
                    size: 20,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      marker.locationName,
                      style: const TextStyle(
                        color: Constants.whiteColor,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (eventCount > 0)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(
                          '$eventCount ${eventCount == 1 ? 'event' : 'events'} scheduled',
                          style: TextStyle(
                            color: Constants.creamColor.withOpacity(0.7),
                            fontSize: 12,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios,
                color: Constants.creamColor.withOpacity(0.5),
                size: 16,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
