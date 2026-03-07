import 'package:apoorv_app/screens/homepage/Maps/components/event_image.dart';
import 'package:apoorv_app/utils/models/feed.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../../../constants.dart';
// import '../../../../../utils/Models/Feed.dart';
import '../../../../../providers/app_config_provider.dart';
import 'services/map_data_service.dart';
import 'components/map_markers.dart';
import 'components/academic_block_markers.dart';
import 'services/map_cache_service.dart';
import 'screens/event_details.dart';
import 'screens/all_events.dart';
import 'components/marker_dialogs.dart';
// import 'services/migration_service.dart'; // TODO: remove after migration

// Map boundaries and zoom constraints
const minZoom = 17.0;
const maxZoom = 21.0;
const initialZoom = 17.5;

const minLat = 9.750682; // Southwest corner latitude
const maxLat = 9.758735; // Northeast corner latitude
const minLong = 76.646042; // Southwest corner longitude
const maxLong = 76.653665; // Northeast corner longitude

final mapBounds = LatLngBounds(
  const LatLng(minLat, minLong), // Southwest corner
  const LatLng(maxLat, maxLong), // Northeast corner
);

// Define zoom levels to cache
final zoomLevelsToCache = {
  initialZoom.floor() - 1,
  initialZoom.floor(),
  initialZoom.ceil(),
  initialZoom.ceil() + 1,
};

class MapsScreen extends StatefulWidget {
  static const routeName = '/maps';
  const MapsScreen({super.key});

  @override
  State<MapsScreen> createState() => _MapsScreenState();
}

class _MapsScreenState extends State<MapsScreen> {
  final MapController mapController = MapController();
  bool _isSatelliteMode = true;
  List<MapMarker> markers = [];
  Color selectedMarkerColor = Constants.redColor;
  Color selectedTextColor = Constants.whiteColor;
  int selectedDay = 1;
  MapMarker? selectedMarker;
  List<Event> filteredEvents = [];

  // ── Placement mode (add/move location) ──────────────────────────────
  bool _isPlacementMode = false;
  LatLng _placementPosition = const LatLng(9.754969, 76.650201);
  Function(LatLng)? _onPlacementConfirmed;
  String _placementHint = 'Pan map to position the pin, then confirm';

  // ── Firestore streams ────────────────────────────────────────────────
  StreamSubscription<QuerySnapshot>? _locationsSubscription;
  StreamSubscription<QuerySnapshot>? _eventsSubscription;
  List<QueryDocumentSnapshot> _locationsDocs = [];
  List<QueryDocumentSnapshot> _eventsDocs = [];
  bool _locationsLoaded = false;
  bool _eventsLoaded = false;

  @override
  void initState() {
    super.initState();
    _setupStreams();
  }

  @override
  void dispose() {
    _locationsSubscription?.cancel();
    _eventsSubscription?.cancel();
    super.dispose();
  }

  /// Subscribes to the locations and events Firestore collections.
  /// Fires [_rebuildMarkers] whenever either collection changes.
  /// Firestore offline persistence means this works seamlessly offline too.
  void _setupStreams() {
    _locationsSubscription = MapDataService.getLocationsStream().listen(
      (snap) {
        _locationsDocs = snap.docs;
        _locationsLoaded = true;
        _rebuildMarkers();
      },
      onError: (error) {
        debugPrint('🔴 Locations stream error: $error');
        // Stream errored — fall back to a one-off get()
        _fallbackFetchLocations();
      },
    );

    _eventsSubscription = MapDataService.getEventsStream().listen(
      (snap) {
        _eventsDocs = snap.docs;
        _eventsLoaded = true;
        _rebuildMarkers();
      },
      onError: (error) {
        debugPrint('🔴 Events stream error: $error');
        // Stream errored — fall back to a one-off get()
        _fallbackFetchEvents();
      },
    );
  }

  /// One-off Firestore fetch for locations (fallback when stream fails).
  Future<void> _fallbackFetchLocations() async {
    try {
      final snap = await FirebaseFirestore.instance
          .collection('locations')
          .orderBy('created_at')
          .get();
      if (mounted) {
        _locationsDocs = snap.docs;
        _locationsLoaded = true;
        _rebuildMarkers();
      }
    } catch (e) {
      debugPrint('🔴 Fallback locations fetch also failed: $e');
    }
  }

  /// One-off Firestore fetch for events (fallback when stream fails).
  Future<void> _fallbackFetchEvents() async {
    try {
      final snap = await FirebaseFirestore.instance
          .collection('events')
          .orderBy('created_at')
          .get();
      if (mounted) {
        _eventsDocs = snap.docs;
        _eventsLoaded = true;
        _rebuildMarkers();
      }
    } catch (e) {
      debugPrint('🔴 Fallback events fetch also failed: $e');
    }
  }

  /// Converts the latest Firestore snapshot docs into [MapMarker] objects
  /// and triggers a rebuild. Called whenever either stream emits.
  /// Only rebuilds once both streams have loaded at least once.
  void _rebuildMarkers() {
    // Wait for both streams to emit at least once
    if (!_locationsLoaded || !_eventsLoaded) {
      debugPrint('⏳ _rebuildMarkers skipped — locationsLoaded=$_locationsLoaded, eventsLoaded=$_eventsLoaded');
      return;
    }

    debugPrint('🔄 _rebuildMarkers — ${_locationsDocs.length} locations, ${_eventsDocs.length} events');
    final events = MapDataService.buildEventsFromDocs(_eventsDocs);
    final newMarkers =
        MapDataService.buildMarkersFromDocs(_locationsDocs, events);
    debugPrint('✅ Built ${newMarkers.length} markers');
    if (mounted) {
      setState(() {
        markers = newMarkers;
        // If there's a selected marker, try to update it with the new data
        if (selectedMarker != null) {
          try {
            selectedMarker = newMarkers.firstWhere(
              (m) => m.id == selectedMarker!.id,
            );
            _updateFilteredEvents();
          } catch (e) {
            // Marker was deleted, clear selection
            selectedMarker = null;
            filteredEvents = [];
          }
        }
      });
    }
  }

  void _handleColorSelection(Color markerColor, Color textColor) {
    setState(() {
      selectedMarkerColor = markerColor;
      selectedTextColor = textColor;
    });
  }

  void _handleMarkerTapped(MapMarker marker) {
    setState(() {
      selectedMarker = marker;
      _updateFilteredEvents();
    });

    _showEventBottomSheet();
  }

  void _updateFilteredEvents() {
    if (selectedMarker != null) {
      final dayEvents = selectedMarker!.events
          .where((event) => event.day == selectedDay)
          .toList();

      // Sort events by time
      dayEvents.sort((a, b) => a.time.compareTo(b.time));

      setState(() {
        filteredEvents = dayEvents;
      });
    }
  }

  void _showEventBottomSheet() {
    if (selectedMarker == null) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(builder: (context, setModalState) {
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
                  // Location name row with optional admin add-event button
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            selectedMarker!.locationName,
                            style: const TextStyle(
                              color: Constants.whiteColor,
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        Consumer<AppConfigProvider>(
                          builder: (context, config, _) {
                            if (!config.isAdmin) return const SizedBox.shrink();
                            return IconButton(
                              icon: const Icon(Icons.add_circle_outline,
                                  color: Constants.redColor),
                              tooltip: 'Add Event',
                              onPressed: () {
                                Navigator.pop(context);
                                MarkerDialogs.showAddEventDialog(
                                  context: context,
                                  locationId: selectedMarker!.id,
                                  locationName: selectedMarker!.locationName,
                                  selectedColor: selectedMarker!.markerColor,
                                  selectedTextColor: selectedMarker!.textColor,
                                  onColorsSelected: _handleColorSelection,
                                );
                              },
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                  // Day selector
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: _buildDaySelectorForBottomSheet(setModalState),
                  ),
                  const SizedBox(height: 16),
                  // Events list
                  Expanded(
                    child: filteredEvents.isEmpty
                        ? _buildNoEventsMessage()
                        : _buildEventsList(scrollController),
                  ),
                ],
              ),
            );
          },
        );
      }),
    );
  }

  // New method specifically for the bottom sheet
  Widget _buildDaySelectorForBottomSheet(StateSetter setModalState) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [1, 2, 3].map((day) {
        final isSelected = day == selectedDay;
        return GestureDetector(
          onTap: () {
            // Update both the parent state and the modal state
            setState(() {
              selectedDay = day;
            });

            // Update the modal state to reflect the change
            setModalState(() {
              // This will rebuild just the bottom sheet with the new day
            });

            // Update filtered events
            _updateFilteredEvents();
          },
          child: Container(
            width: 80,
            padding: const EdgeInsets.symmetric(vertical: 10),
            decoration: BoxDecoration(
              color: isSelected ? Constants.redColor : Constants.blackColor,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: isSelected ? Constants.redColor : Constants.creamColor,
              ),
            ),
            child: Center(
              child: Text(
                'Day $day',
                style: TextStyle(
                  color:
                      isSelected ? Constants.whiteColor : Constants.creamColor,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildNoEventsMessage() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.event_busy,
            color: Constants.creamColor,
            size: 48,
          ),
          SizedBox(height: 16),
          Text(
            'No events scheduled',
            style: TextStyle(
              color: Constants.creamColor,
              fontSize: 18,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEventsList(ScrollController scrollController) {
    return ListView.builder(
      controller: scrollController,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: filteredEvents.length,
      itemBuilder: (context, index) {
        final event = filteredEvents[index];
        return _buildEventCard(event);
      },
    );
  }

  Widget _buildEventCard(Event event) {
    return GestureDetector(
      onTap: () {
        Navigator.pop(context); // Close the bottom sheet
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => EventDetailsScreen(
              event: event,
              locationName: selectedMarker!.locationName,
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
            if (event.imageUrl != null)
              Padding(
                padding: const EdgeInsets.only(top: 8, left: 8, right: 8),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    color: Colors.black,
                    width: double.infinity,
                    height: 150,
                    child: EventImage(
                      imageUrl: event.imageUrl!,
                      fit: BoxFit.cover,
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
                  const SizedBox(height: 8),
                  if (event.description != null &&
                      event.description!.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Text(
                        event.description!,
                        style: TextStyle(
                          color: event.txtcolor.withOpacity(0.8),
                        ),
                      ),
                    ),
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
                      const SizedBox(width: 16),
                      if (event.roomNumber.isNotEmpty) ...[
                        Icon(Icons.room, color: event.txtcolor, size: 16),
                        const SizedBox(width: 4),
                        Text(
                          event.roomNumber,
                          style: TextStyle(
                            color: event.txtcolor,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
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

  // ── Placement mode ───────────────────────────────────────────────────

  void _enterPlacementMode({
    required LatLng initialPosition,
    required Function(LatLng) onConfirmed,
    String hint = 'Pan map to position the pin, then confirm',
  }) {
    setState(() {
      _isPlacementMode = true;
      _placementPosition = initialPosition;
      _onPlacementConfirmed = onConfirmed;
      _placementHint = hint;
    });
    mapController.move(initialPosition, mapController.camera.zoom);
  }

  void _exitPlacementMode() {
    setState(() {
      _isPlacementMode = false;
      _onPlacementConfirmed = null;
    });
  }

  Widget _buildPlacementOverlay() {
    return Stack(
      children: [
        // Fixed crosshair pin at the screen center
        // The map moves beneath it — the pin's bottom point is the exact chosen LatLng
        Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Pin icon — shifted up so its tip lands on the map center point
              Transform.translate(
                offset: const Offset(0, -4),
                child: const Icon(
                  Icons.location_on,
                  color: Constants.redColor,
                  size: 52,
                  shadows: [
                    Shadow(
                      color: Colors.black54,
                      offset: Offset(0, 3),
                      blurRadius: 8,
                    ),
                  ],
                ),
              ),
              // Tiny shadow dot directly below the pin tip
              Container(
                width: 8,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.black38,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ],
          ),
        ),
        // Bottom confirmation panel
        Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          child: Container(
            decoration: BoxDecoration(
              color: Constants.blackColor,
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(20)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.5),
                  blurRadius: 24,
                  offset: const Offset(0, -4),
                ),
              ],
            ),
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 10, 20, 16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Handle bar
                    Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.white24,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        const Icon(Icons.open_with,
                            color: Constants.creamColor, size: 16),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _placementHint,
                            style: const TextStyle(
                              color: Constants.creamColor,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: _exitPlacementMode,
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Constants.creamColor,
                              side: const BorderSide(color: Colors.white24),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              padding:
                                  const EdgeInsets.symmetric(vertical: 14),
                            ),
                            child: const Text('Cancel'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          flex: 2,
                          child: FilledButton(
                            onPressed: () {
                              // Capture BOTH before _exitPlacementMode nulls them
                              final pos = _placementPosition;
                              final callback = _onPlacementConfirmed;
                              _exitPlacementMode();
                              callback?.call(pos);
                            },
                            style: FilledButton.styleFrom(
                              backgroundColor: Constants.redColor,
                              foregroundColor: Constants.whiteColor,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              padding:
                                  const EdgeInsets.symmetric(vertical: 14),
                            ),
                            child: const Text(
                              'Confirm Location',
                              style:
                                  TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildZoomControls() {
    return Positioned(
      right: 16,
      bottom: 60,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          FloatingActionButton(
            heroTag: 'zoomIn',
            mini: true,
            backgroundColor: Constants.blackColor,
            onPressed: () {
              final currentZoom = mapController.camera.zoom;
              if (currentZoom < maxZoom) {
                mapController.move(
                  mapController.camera.center,
                  currentZoom + 1,
                );
              }
            },
            child: const Icon(Icons.add, color: Constants.redColor),
          ),
          const SizedBox(height: 8),
          FloatingActionButton(
            heroTag: 'zoomOut',
            mini: true,
            backgroundColor: Constants.blackColor,
            onPressed: () {
              final currentZoom = mapController.camera.zoom;
              if (currentZoom > minZoom) {
                mapController.move(
                  mapController.camera.center,
                  currentZoom - 1,
                );
              }
            },
            child: const Icon(Icons.remove, color: Constants.redColor),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Filter out academic block markers (BB, BC, BD) for regular marker layer
    final regularMarkers = markers.where((marker) {
      final name = marker.locationName;
      return !(name.startsWith('BB') ||
          name.startsWith('BC') ||
          name.startsWith('BD'));
    }).toList();

    // Get academic block markers for the academic block layer
    final academicMarkers = markers.where((marker) {
      final name = marker.locationName;
      return name.startsWith('BB') ||
          name.startsWith('BC') ||
          name.startsWith('BD');
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('APOORV 2026 Map'),
        backgroundColor: Constants.blackColor,
        actions: [
          // Admin-only: Add new location pin
          Consumer<AppConfigProvider>(
            builder: (context, config, _) {
              if (!config.isAdmin) return const SizedBox.shrink();
              return IconButton(
                icon: const Icon(Icons.add_location_alt,
                    color: Constants.redColor),
                tooltip: 'Add Location',
                onPressed: () {
                  _enterPlacementMode(
                    initialPosition: mapController.camera.center,
                    hint: 'Pan map to place the new location pin',
                    onConfirmed: (position) {
                      MarkerDialogs.showAddLocationDialog(
                        context: context,
                        position: position,
                        selectedMarkerColor: selectedMarkerColor,
                        selectedTextColor: selectedTextColor,
                        onMarkerAdded: (newMarker) {
                          setState(() {
                            markers.add(newMarker);
                          });
                        },
                        onColorsSelected: _handleColorSelection,
                      );
                    },
                  );
                },
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.event, color: Constants.redColor),
            tooltip: 'View All Events',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => AllEventsScreen(
                    markers: markers,
                  ),
                ),
              );
            },
          ),
          // ─── TEMPORARY — remove after Supabase → Firestore migration ───
          // Consumer<AppConfigProvider>(
          //   builder: (context, config, _) {
          //     if (!config.isAdmin) return const SizedBox.shrink();
          //     return IconButton(
          //       icon: const Icon(Icons.upload_rounded, color: Colors.amber),
          //       tooltip: 'Migrate from Supabase (temp)',
          //       onPressed: () =>
          //           MigrationService.showMigrationDialog(context),
          //     );
          //   },
          // ),
          // ───────────────────────────────────────────────────────────────
          IconButton(
            icon: Icon(_isSatelliteMode ? Icons.map : Icons.satellite),
            color: Constants.redColor,
            onPressed: () {
              setState(() {
                _isSatelliteMode = !_isSatelliteMode;
              });
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          FlutterMap(
            mapController: mapController,
            options: MapOptions(
              initialCenter: const LatLng(9.754969, 76.650201),
              initialZoom: initialZoom,
              minZoom: minZoom,
              maxZoom: maxZoom,
              interactionOptions: const InteractionOptions(
                flags: InteractiveFlag.all,
              ),
              keepAlive: true,
              backgroundColor: Constants.blackColor,
              onPositionChanged: (camera, hasGesture) {
                if (_isPlacementMode) {
                  setState(() {
                    _placementPosition =
                        camera.center ?? _placementPosition;
                  });
                }
              },
              cameraConstraint:
                  CameraConstraint.containCenter(bounds: mapBounds),
            ),
            children: [
              TileLayer(
                urlTemplate: _isSatelliteMode
                    ? 'https://mt1.google.com/vt/lyrs=s&x={x}&y={y}&z={z}'
                    : 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.example.app',
                tileProvider:
                    CachedTileProvider(zoomLevelsToCache: zoomLevelsToCache),
                minZoom: minZoom,
                maxZoom: maxZoom,
                keepBuffer: 8,
              ),
              // Regular markers (non-academic blocks)
              MapMarkerLayer(
                markers: regularMarkers,
                onMarkerTapped: _handleMarkerTapped,
                onMoveLocation: (marker) {
                  final config = Provider.of<AppConfigProvider>(context,
                      listen: false);
                  if (!config.isAdmin) return;
                  _enterPlacementMode(
                    initialPosition: marker.position,
                    hint:
                        'Pan map to new position for "${marker.locationName}"',
                    onConfirmed: (newPosition) async {
                      final updated = MapMarker(
                        id: marker.id,
                        locationName: marker.locationName,
                        position: newPosition,
                        markerColor: marker.markerColor,
                        textColor: marker.textColor,
                        events: marker.events,
                        createdAt: marker.createdAt,
                      );
                      setState(() {
                        final idx =
                            markers.indexWhere((m) => m.id == marker.id);
                        if (idx != -1) markers[idx] = updated;
                      });
                      // Capture before async gap — avoids BuildContext-across-async-gap lint
                      final messenger = ScaffoldMessenger.of(context);
                      try {
                        await MapDataService.updateLocation(updated);
                      } catch (e) {
                        debugPrint('MapDataService: Error moving location: $e');
                        if (mounted) {
                          messenger.showSnackBar(
                            SnackBar(content: Text('Failed to move: $e')),
                          );
                        }
                      }
                    },
                  );
                },
              ),
              // Academic block markers (BB, BC, BD)
              AcademicBlockMarkers(
                markers: academicMarkers,
                onMarkerTapped: _handleMarkerTapped,
              ),
            ],
          ),
          _buildZoomControls(),
          if (_isPlacementMode) _buildPlacementOverlay(),
        ],
      ),
    );
  }
}
