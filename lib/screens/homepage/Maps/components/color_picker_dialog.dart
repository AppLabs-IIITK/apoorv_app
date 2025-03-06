import 'package:flutter/material.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import '../../../../../../constants.dart';

class ColorPickerDialog extends StatefulWidget {
  final Color initialMarkerColor;
  final Color initialTextColor;
  final Function(Color markerColor, Color textColor) onColorsSelected;

  const ColorPickerDialog({
    super.key,
    required this.initialMarkerColor,
    required this.initialTextColor,
    required this.onColorsSelected,
  });

  @override
  State<ColorPickerDialog> createState() => _ColorPickerDialogState();
}

class _ColorPickerDialogState extends State<ColorPickerDialog> {
  late Color pickerMarkerColor;
  late Color pickerTextColor;
  bool showMarkerPicker = true;

  final List<Color> presetColors = [
    Constants.redColor,
    Constants.creamColor,
    Constants.whiteColor,
    Constants.blackColor,
    Constants.greenColor,
    Constants.redColorAlt,

    const Color(0xFF2196F3), // Blue
    const Color(0xFF4CAF50), // Green
    const Color(0xFFFFC107), // Amber
    const Color(0xFF9C27B0), // Purple
    const Color(0xFFE91E63), // Pink
    const Color(0xFF795548), // Brown
    const Color(0xFF607D8B), // Blue Grey
    const Color(0xFF009688), // Teal
  ];

  @override
  void initState() {
    super.initState();
    pickerMarkerColor = widget.initialMarkerColor;
    pickerTextColor = widget.initialTextColor;
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Constants.blackColor,
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildToggleButtons(),
              const SizedBox(height: 16),
              _buildPresetColors(),
              _buildColorPicker(),
              _buildPreview(),
              _buildActionButtons(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildToggleButtons() {
    return Row(
      children: [
        _buildToggleButton(
          isSelected: showMarkerPicker,
          icon: Icons.location_on,
          label: 'Bg Color',
          onPressed: () => setState(() => showMarkerPicker = true),
        ),
        const SizedBox(width: 8),
        _buildToggleButton(
          isSelected: !showMarkerPicker,
          icon: Icons.text_fields,
          label: 'Text Color',
          onPressed: () => setState(() => showMarkerPicker = false),
        ),
      ],
    );
  }

  Widget _buildToggleButton({
    required bool isSelected,
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
  }) {
    return Expanded(
      child: TextButton(
        onPressed: onPressed,
        style: TextButton.styleFrom(
          backgroundColor: isSelected
              ? Constants.redColor.withOpacity(0.1)
              : Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              color: isSelected ? Constants.redColor : Constants.creamColor,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? Constants.redColor : Constants.creamColor,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPresetColors() {
    return Container(
      height: 50,
      margin: const EdgeInsets.only(bottom: 16),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: presetColors.length,
        itemBuilder: (context, index) {
          final color = presetColors[index];
          final isSelected = showMarkerPicker
              ? pickerMarkerColor.value == color.value
              : pickerTextColor.value == color.value;
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: GestureDetector(
              onTap: () {
                setState(() {
                  if (showMarkerPicker) {
                    pickerMarkerColor = color;
                  } else {
                    pickerTextColor = color;
                  }
                });
              },
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isSelected
                        ? Constants.redColor
                        : color == Constants.blackColor
                            ? Constants.creamColor.withOpacity(0.3)
                            : Colors.transparent,
                    width: isSelected ? 2 : 1,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Constants.blackColor.withOpacity(0.2),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                    if (color == Constants.blackColor)
                      const BoxShadow(
                        color: Colors.white24,
                        blurRadius: 1,
                        spreadRadius: 1,
                      ),
                  ],
                ),
                child: isSelected
                    ? Center(
                        child: Icon(
                          Icons.check,
                          color: color == Constants.blackColor
                              ? Constants.whiteColor
                              : color.computeLuminance() > 0.5
                                  ? Constants.blackColor
                                  : Constants.whiteColor,
                          size: 20,
                        ),
                      )
                    : null,
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildColorPicker() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: ColorPicker(
        pickerColor: showMarkerPicker ? pickerMarkerColor : pickerTextColor,
        onColorChanged: (color) {
          setState(() {
            if (showMarkerPicker) {
              pickerMarkerColor = color;
            } else {
              pickerTextColor = color;
            }
          });
        },
        labelTypes: const [],
        pickerAreaHeightPercent: 0.7,
        enableAlpha: false,
        displayThumbColor: true,
      ),
    );
  }

  Widget _buildPreview() {
    return Container(
      padding: const EdgeInsets.all(12),
      margin: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        color: Constants.blackColor.withOpacity(0.3),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: pickerMarkerColor,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.location_on,
              color: pickerTextColor,
              size: 24,
            ),
          ),
          const SizedBox(width: 12),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 6,
            ),
            decoration: BoxDecoration(
              color: pickerMarkerColor,
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              'Preview Text',
              style: TextStyle(
                color: pickerTextColor,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return Row(
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
          onPressed: () {
            widget.onColorsSelected(pickerMarkerColor, pickerTextColor);
            Navigator.of(context).pop();
          },
          child: const Text('Apply Colors'),
        ),
      ],
    );
  }
}
