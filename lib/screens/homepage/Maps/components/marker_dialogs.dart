import 'package:apoorv_app/screens/homepage/Maps/services/supabase_service.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:latlong2/latlong.dart';
import '../../../../../../constants.dart';
import '../../../../../../utils/Models/Feed.dart';
import 'color_picker_dialog.dart';

class MarkerDialogs {
  // Add Location Dialog
  static Future<void> showAddLocationDialog({
    required BuildContext context,
    required LatLng position,
    required Color selectedMarkerColor,
    required Color selectedTextColor,
    required Function(MapMarker) onMarkerAdded,
    required Function(Color, Color) onColorsSelected,
  }) async {
    String locationName = '';

    return showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Constants.blackColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Container(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildTextField(
                  label: 'Location Name',
                  hint: 'Enter building or location name',
                  onChanged: (value) => locationName = value,
                ),
                const SizedBox(height: 24),
                _buildActionButtons(
                  context: context,
                  onImagePicked: null, // No image for locations
                  onColorsPicked: () async {
                    await showDialog(
                      context: context,
                      builder: (context) => ColorPickerDialog(
                        initialMarkerColor: selectedMarkerColor,
                        initialTextColor: selectedTextColor,
                        onColorsSelected: onColorsSelected,
                      ),
                    );
                  },
                  onSave: () async {
                    if (locationName.isNotEmpty) {
                      final marker = MapMarker(
                        id: '', // Let Supabase generate the UUID
                        locationName: locationName,
                        position: position,
                        markerColor: selectedMarkerColor,
                        textColor: selectedTextColor,
                        events: [],
                        createdAt: DateTime.now(),
                      );

                      try {
                        final locationId =
                            await SupabaseService.saveLocation(marker);
                        // Update marker with the generated ID
                        final updatedMarker = MapMarker(
                          id: locationId,
                          locationName: marker.locationName,
                          position: marker.position,
                          markerColor: marker.markerColor,
                          textColor: marker.textColor,
                          events: marker.events,
                          createdAt: marker.createdAt,
                        );
                        onMarkerAdded(updatedMarker);
                        if (context.mounted) {
                          Navigator.of(context).pop();
                        }
                      } catch (e) {
                        if (context.mounted) {
                          _showErrorSnackBar(
                              context, 'Failed to save location: $e');
                        }
                      }
                    }
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // Edit Location Dialog
  static Future<void> showEditLocationDialog({
    required BuildContext context,
    required MapMarker marker,
    required Color selectedMarkerColor,
    required Color selectedTextColor,
    required Function(MapMarker) onMarkerUpdated,
    required Function(Color, Color) onColorsSelected,
  }) async {
    String locationName = marker.locationName;
    Color markerColor = marker.markerColor;
    Color textColor = marker.textColor;

    return showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Constants.blackColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Container(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildTextField(
                  label: 'Location Name',
                  initialValue: locationName,
                  onChanged: (value) => locationName = value,
                ),
                const SizedBox(height: 24),
                _buildActionButtons(
                  context: context,
                  onImagePicked: null, // No image for locations
                  onColorsPicked: () async {
                    await showDialog(
                      context: context,
                      builder: (context) => ColorPickerDialog(
                        initialMarkerColor: markerColor,
                        initialTextColor: textColor,
                        onColorsSelected: (newMarkerColor, newTextColor) {
                          markerColor = newMarkerColor;
                          textColor = newTextColor;
                          onColorsSelected(newMarkerColor, newTextColor);
                        },
                      ),
                    );
                  },
                  onSave: () async {
                    if (locationName.isNotEmpty) {
                      final updatedMarker = MapMarker(
                        id: marker.id,
                        locationName: locationName,
                        position: marker.position,
                        markerColor: markerColor,
                        textColor: textColor,
                        events: marker.events,
                        createdAt: marker.createdAt,
                      );

                      try {
                        await SupabaseService.updateLocation(updatedMarker);
                        onMarkerUpdated(updatedMarker);
                        if (context.mounted) {
                          Navigator.of(context).pop();
                        }
                      } catch (e) {
                        if (context.mounted) {
                          _showErrorSnackBar(
                              context, 'Failed to update location: $e');
                        }
                      }
                    }
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // Add Event Dialog
  static Future<void> showAddEventDialog({
    required BuildContext context,
    required String locationId,
    required String locationName,
    required Color selectedColor,
    required Color selectedTextColor,
    required Function(Event) onEventAdded,
    required Function(Color, Color) onColorsSelected,
  }) async {
    String title = '';
    String description = '';
    String roomNumber = '';
    String time = '';
    int day = 1;
    String? imageFileName;
    Image? eventImage;
    Color eventColor = selectedColor;
    Color textColor = selectedTextColor;

    return showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return Dialog(
              backgroundColor: Constants.blackColor,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: SingleChildScrollView(
                child: Container(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Add Event at $locationName',
                        style: const TextStyle(
                          color: Constants.whiteColor,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      _buildTextField(
                        label: 'Event Title',
                        hint: 'Enter event title',
                        onChanged: (value) => title = value,
                      ),
                      const SizedBox(height: 16),
                      _buildTextField(
                        label: 'Description',
                        hint: 'Enter event description',
                        onChanged: (value) => description = value,
                        maxLines: 3,
                      ),
                      const SizedBox(height: 16),
                      _buildTextField(
                        label: 'Room Number',
                        hint: 'e.g. 201, G01',
                        onChanged: (value) => roomNumber = value,
                      ),
                      const SizedBox(height: 16),
                      _buildTextField(
                        label: 'Time',
                        hint: 'e.g. 10:00 AM - 12:00 PM',
                        onChanged: (value) => time = value,
                      ),
                      const SizedBox(height: 16),
                      _buildDaySelector(
                        selectedDay: day,
                        onDaySelected: (value) {
                          setState(() {
                            day = value;
                          });
                        },
                      ),
                      const SizedBox(height: 16),
                      if (eventImage != null) _buildImagePreview(eventImage!),
                      _buildActionButtons(
                        context: context,
                        onImagePicked: () async {
                          final result = await _pickEventImage();
                          if (result != null) {
                            imageFileName = result.$1;
                            setState(() {
                              eventImage = result.$2;
                            });
                          }
                        },
                        onColorsPicked: () async {
                          await showDialog(
                            context: context,
                            builder: (context) => ColorPickerDialog(
                              initialMarkerColor: eventColor,
                              initialTextColor: textColor,
                              onColorsSelected: (newColor, newTextColor) {
                                setState(() {
                                  eventColor = newColor;
                                  textColor = newTextColor;
                                });
                                onColorsSelected(newColor, newTextColor);
                              },
                            ),
                          );
                        },
                        onSave: () async {
                          if (title.isNotEmpty && time.isNotEmpty) {
                            final event = Event(
                              id: '', // Let Supabase generate the UUID
                              title: title,
                              description: description,
                              image: eventImage,
                              imageFile: imageFileName,
                              color: eventColor,
                              txtcolor: textColor,
                              day: day,
                              time: time,
                              locationId: locationId,
                              roomNumber: roomNumber,
                              createdAt: DateTime.now(),
                            );

                            try {
                              final eventId = await SupabaseService.saveEvent(
                                  event, imageFileName);

                              // Update the event with the generated ID
                              final updatedEvent = Event(
                                id: eventId,
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

                              onEventAdded(updatedEvent);
                              if (context.mounted) {
                                Navigator.of(context).pop();
                              }
                            } catch (e) {
                              if (context.mounted) {
                                _showErrorSnackBar(
                                    context, 'Failed to save event: $e');
                              }
                            }
                          } else {
                            _showErrorSnackBar(
                                context, 'Title and time are required');
                          }
                        },
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  // Edit Event Dialog
  static Future<void> showEditEventDialog({
    required BuildContext context,
    required Event event,
    required String locationName,
    required Function(Event) onEventUpdated,
    required Function(Color, Color) onColorsSelected,
  }) async {
    String title = event.title;
    String description = event.description ?? '';
    String roomNumber = event.roomNumber;
    String time = event.time;
    int day = event.day;
    String? imageFileName;
    Image? eventImage = event.image;
    Color eventColor = event.color;
    Color textColor = event.txtcolor;

    return showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return Dialog(
              backgroundColor: Constants.blackColor,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: SingleChildScrollView(
                child: Container(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Edit Event at $locationName',
                        style: const TextStyle(
                          color: Constants.whiteColor,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      _buildTextField(
                        label: 'Event Title',
                        initialValue: title,
                        onChanged: (value) => title = value,
                      ),
                      const SizedBox(height: 16),
                      _buildTextField(
                        label: 'Description',
                        initialValue: description,
                        onChanged: (value) => description = value,
                        maxLines: 3,
                      ),
                      const SizedBox(height: 16),
                      _buildTextField(
                        label: 'Room Number',
                        initialValue: roomNumber,
                        onChanged: (value) => roomNumber = value,
                      ),
                      const SizedBox(height: 16),
                      _buildTextField(
                        label: 'Time',
                        initialValue: time,
                        onChanged: (value) => time = value,
                      ),
                      const SizedBox(height: 16),
                      _buildDaySelector(
                        selectedDay: day,
                        onDaySelected: (value) {
                          setState(() {
                            day = value;
                          });
                        },
                      ),
                      const SizedBox(height: 16),
                      if (eventImage != null) _buildImagePreview(eventImage!),
                      _buildActionButtons(
                        context: context,
                        onImagePicked: () async {
                          final result = await _pickEventImage();
                          if (result != null) {
                            imageFileName = result.$1;
                            setState(() {
                              eventImage = result.$2;
                            });
                          }
                        },
                        onColorsPicked: () async {
                          await showDialog(
                            context: context,
                            builder: (context) => ColorPickerDialog(
                              initialMarkerColor: eventColor,
                              initialTextColor: textColor,
                              onColorsSelected: (newColor, newTextColor) {
                                setState(() {
                                  eventColor = newColor;
                                  textColor = newTextColor;
                                });
                                onColorsSelected(newColor, newTextColor);
                              },
                            ),
                          );
                        },
                        onSave: () async {
                          if (title.isNotEmpty && time.isNotEmpty) {
                            final updatedEvent = Event(
                              id: event.id,
                              title: title,
                              description: description,
                              image: eventImage,
                              imageFile: imageFileName ?? event.imageFile,
                              color: eventColor,
                              txtcolor: textColor,
                              day: day,
                              time: time,
                              locationId: event.locationId,
                              roomNumber: roomNumber,
                              createdAt: event.createdAt,
                            );

                            try {
                              await SupabaseService.updateEvent(
                                  updatedEvent, imageFileName);
                              onEventUpdated(updatedEvent);
                              if (context.mounted) {
                                Navigator.of(context).pop();
                              }
                            } catch (e) {
                              if (context.mounted) {
                                _showErrorSnackBar(
                                    context, 'Failed to update event: $e');
                              }
                            }
                          } else {
                            _showErrorSnackBar(
                                context, 'Title and time are required');
                          }
                        },
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  // Delete Location Dialog
  static Future<void> showDeleteLocationDialog({
    required BuildContext context,
    required String locationId,
    required Function() onMarkerDeleted,
  }) async {
    return showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Constants.blackColor,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Delete Location',
                  style: TextStyle(
                    color: Constants.whiteColor,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Are you sure you want to delete this location? All events at this location will also be deleted.',
                  style: TextStyle(color: Constants.creamColor),
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text(
                        'Cancel',
                        style: TextStyle(color: Constants.creamColor),
                      ),
                    ),
                    const SizedBox(width: 16),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Constants.redColor,
                        foregroundColor: Constants.whiteColor,
                      ),
                      onPressed: () async {
                        try {
                          await SupabaseService.deleteLocation(locationId);
                          onMarkerDeleted();
                          if (context.mounted) {
                            Navigator.of(context).pop();
                          }
                        } catch (e) {
                          if (context.mounted) {
                            _showErrorSnackBar(
                                context, 'Failed to delete location: $e');
                          }
                        }
                      },
                      child: const Text('Delete'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // Delete Event Dialog
  static Future<void> showDeleteEventDialog({
    required BuildContext context,
    required String eventId,
    required Function() onEventDeleted,
  }) async {
    return showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Constants.blackColor,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Delete Event',
                  style: TextStyle(
                    color: Constants.whiteColor,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Are you sure you want to delete this event?',
                  style: TextStyle(color: Constants.creamColor),
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text(
                        'Cancel',
                        style: TextStyle(color: Constants.creamColor),
                      ),
                    ),
                    const SizedBox(width: 16),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Constants.redColor,
                        foregroundColor: Constants.whiteColor,
                      ),
                      onPressed: () async {
                        try {
                          await SupabaseService.deleteEvent(eventId);
                          onEventDeleted();
                          if (context.mounted) {
                            Navigator.of(context).pop();
                          }
                        } catch (e) {
                          if (context.mounted) {
                            _showErrorSnackBar(
                                context, 'Failed to delete event: $e');
                          }
                        }
                      },
                      child: const Text('Delete'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // Helper Widgets
  static Widget _buildTextField({
    required String label,
    String? hint,
    String? initialValue,
    required Function(String) onChanged,
    int? maxLines,
  }) {
    return TextField(
      controller: initialValue != null
          ? TextEditingController(text: initialValue)
          : null,
      style: const TextStyle(color: Constants.whiteColor),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        labelStyle: const TextStyle(color: Constants.creamColor),
        hintStyle: const TextStyle(color: Constants.creamColor),
        enabledBorder: const UnderlineInputBorder(
          borderSide: BorderSide(color: Constants.redColor),
        ),
        focusedBorder: const UnderlineInputBorder(
          borderSide: BorderSide(color: Constants.whiteColor),
        ),
      ),
      maxLines: maxLines,
      onChanged: onChanged,
    );
  }

  static Widget _buildDaySelector({
    required int selectedDay,
    required Function(int) onDaySelected,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Day',
          style: TextStyle(color: Constants.creamColor),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [1, 2, 3].map((day) {
            final isSelected = day == selectedDay;
            return GestureDetector(
              onTap: () => onDaySelected(day),
              child: Container(
                width: 60,
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  color: isSelected ? Constants.redColor : Constants.blackColor,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color:
                        isSelected ? Constants.redColor : Constants.creamColor,
                  ),
                ),
                child: Center(
                  child: Text(
                    'Day $day',
                    style: TextStyle(
                      color: isSelected
                          ? Constants.whiteColor
                          : Constants.creamColor,
                      fontWeight:
                          isSelected ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  static Widget _buildImagePreview(Image image) {
    return Container(
      height: 120,
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 16),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: image,
      ),
    );
  }

  static Widget _buildActionButtons({
    required BuildContext context,
    required Function()? onImagePicked,
    required Function() onColorsPicked,
    required Function() onSave,
  }) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            if (onImagePicked != null)
              TextButton.icon(
                onPressed: onImagePicked,
                icon: const Icon(Icons.image, color: Constants.creamColor),
                label: const Text(
                  'Add Image',
                  style: TextStyle(color: Constants.creamColor),
                ),
              ),
            TextButton.icon(
              onPressed: onColorsPicked,
              icon: const Icon(Icons.color_lens, color: Constants.creamColor),
              label: const Text(
                'Colors',
                style: TextStyle(color: Constants.creamColor),
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text(
                'Cancel',
                style: TextStyle(color: Constants.creamColor),
              ),
            ),
            const SizedBox(width: 16),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Constants.redColor,
                foregroundColor: Constants.whiteColor,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              onPressed: onSave,
              child: const Text('Save'),
            ),
          ],
        ),
      ],
    );
  }

  // Helper methods
  static Future<(String, Image)?> _pickEventImage() async {
    final ImagePicker imagePicker = ImagePicker();
    final XFile? image = await imagePicker.pickImage(
      source: ImageSource.gallery,
    );
    if (image != null) {
      try {
        final imageFileName =
            await SupabaseService.uploadEventImage(image.path);
        final newImage = await SupabaseService.getEventImage(imageFileName);
        if (newImage != null) {
          return (imageFileName, newImage);
        }
      } catch (e) {
        debugPrint('Failed to upload image: $e');
      }
    }
    return null;
  }

  static void _showErrorSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }
}
