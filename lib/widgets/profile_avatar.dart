import 'package:flutter/material.dart';

class ProfileAvatar extends StatelessWidget {
  final String? imageUrl;
  final String? name;
  final double radius;
  final Color backgroundColor;
  final Color textColor;

  const ProfileAvatar({
    super.key,
    required this.imageUrl,
    required this.name,
    required this.radius,
    required this.backgroundColor,
    required this.textColor,
  });

  static bool _isValidHttpUrl(String url) {
    final uri = Uri.tryParse(url);
    if (uri == null) return false;
    final scheme = uri.scheme.toLowerCase();
    return (scheme == 'http' || scheme == 'https') && uri.host.isNotEmpty;
  }

  @override
  Widget build(BuildContext context) {
    final url = (imageUrl ?? '').trim();
    final hasImage = url.isNotEmpty && _isValidHttpUrl(url);
    final trimmedName = (name ?? '').trim();
    final initial = trimmedName.isNotEmpty ? trimmedName[0].toUpperCase() : '?';

    // Not using CircleAvatar internally so callers can wrap with their own
    // CircleAvatar when they need nested styling/layout.
    if (hasImage) {
      return ClipOval(
        child: Image.network(
          url,
          width: radius * 2,
          height: radius * 2,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => _fallback(initial),
        ),
      );
    }

    return _fallback(initial);
  }

  Widget _fallback(String initial) {
    return Center(
      child: Text(
        initial,
        style: TextStyle(
          fontSize: radius * 0.8,
          fontWeight: FontWeight.bold,
          color: textColor,
          height: 1.0,
        ),
      ),
    );
  }
}
