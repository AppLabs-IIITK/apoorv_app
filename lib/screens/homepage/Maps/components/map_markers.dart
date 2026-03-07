import 'package:apoorv_app/providers/app_config_provider.dart';
import 'package:apoorv_app/utils/models/feed.dart';
import 'package:provider/provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import '../../../../../../constants.dart';
// import '../../../../../../utils/Models/Feed.dart';
import 'marker_dialogs.dart';

class MapMarkerLayer extends StatelessWidget {
  final List<MapMarker> markers;
  final Function(MapMarker) onMarkerTapped;
  /// If provided, shows a "Move Location" option in the long-press menu.
  final Function(MapMarker)? onMoveLocation;

  const MapMarkerLayer({
    super.key,
    required this.markers,
    required this.onMarkerTapped,
    this.onMoveLocation,
  });

  @override
  Widget build(BuildContext context) {
    final config = Provider.of<AppConfigProvider>(context, listen: false);

    return MarkerLayer(
      markers: markers.map((marker) {
        return Marker(
          width: 150.0,
          height: 80.0,
          point: marker.position,
          child: GestureDetector(
            onTap: () => onMarkerTapped(marker),
            onLongPress: config.canManageContent
                ? () => _showMarkerOptions(context, marker)
                : null,
            child: _buildMarkerWidget(marker),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildMarkerWidget(MapMarker marker) {
    return Column(
      children: [
        Container(
          decoration: BoxDecoration(
            color: marker.markerColor,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Constants.blackColor.withOpacity(0.3),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          padding: const EdgeInsets.all(6),
          child: Icon(
            Icons.location_on,
            color: marker.textColor,
            size: 24.0,
          ),
        ),
        Flexible(
          child: Container(
            constraints: const BoxConstraints(
              maxWidth: 140,
            ),
            margin: const EdgeInsets.only(top: 4),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: marker.markerColor,
              borderRadius: BorderRadius.circular(8),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Text(
              marker.locationName,
              style: TextStyle(
                color: marker.textColor,
                fontWeight: FontWeight.w500,
                fontSize: 12,
                height: 1.2,
              ),
              textAlign: TextAlign.center,
              overflow: TextOverflow.ellipsis,
              maxLines: 2,
              softWrap: true,
            ),
          ),
        ),
      ],
    );
  }

  void _showMarkerOptions(BuildContext context, MapMarker marker) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Colors.black,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  marker.locationName,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 24),
                _buildOptionButton(
                  context,
                  'Edit Location',
                  Icons.edit,
                  () {
                    Navigator.of(context).pop();
                    _showEditLocationDialog(context, marker);
                  },
                ),
                const SizedBox(height: 12),
                if (onMoveLocation != null) ...[
                  _buildOptionButton(
                    context,
                    'Move Location',
                    Icons.open_with,
                    () {
                      Navigator.of(context).pop();
                      onMoveLocation!(marker);
                    },
                  ),
                  const SizedBox(height: 12),
                ],
                _buildOptionButton(
                  context,
                  'Add Event',
                  Icons.event_available,
                  () {
                    Navigator.of(context).pop();
                    _showAddEventDialog(context, marker);
                  },
                ),
                const SizedBox(height: 12),
                _buildOptionButton(
                  context,
                  'Delete Location',
                  Icons.delete,
                  () {
                    Navigator.of(context).pop();
                    _showDeleteLocationDialog(context, marker);
                  },
                  color: Colors.red,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildOptionButton(
    BuildContext context,
    String text,
    IconData icon,
    VoidCallback onPressed, {
    Color color = Colors.white,
  }) {
    return SizedBox(
      width: double.infinity,
      child: TextButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, color: color),
        label: Text(
          text,
          style: TextStyle(color: color),
        ),
        style: TextButton.styleFrom(
          alignment: Alignment.centerLeft,
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        ),
      ),
    );
  }

  void _showEditLocationDialog(BuildContext context, MapMarker marker) {
    MarkerDialogs.showEditLocationDialog(
      context: context,
      marker: marker,
      selectedMarkerColor: marker.markerColor,
      selectedTextColor: marker.textColor,
      onColorsSelected: (markerColor, textColor) {},
    );
  }

  void _showAddEventDialog(BuildContext context, MapMarker marker) {
    MarkerDialogs.showAddEventDialog(
      context: context,
      locationId: marker.id,
      locationName: marker.locationName,
      selectedColor: marker.markerColor,
      selectedTextColor: marker.textColor,
      onColorsSelected: (markerColor, textColor) {},
    );
  }

  void _showDeleteLocationDialog(BuildContext context, MapMarker marker) {
    MarkerDialogs.showDeleteLocationDialog(
      context: context,
      locationId: marker.id,
    );
  }
}
