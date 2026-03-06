import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';

import '../../../../constants.dart';
import '../services/marker_cache_service.dart';

/// A widget that displays an event image with platform-aware caching.
///
/// - **Web**: Uses [Image.network] directly (browser handles caching).
/// - **Android**: Shows cached image instantly if available, otherwise
///   falls back to [Image.network] while caching in the background
///   so the next load is instant.
class EventImage extends StatefulWidget {
  final String imageUrl;
  final BoxFit fit;

  const EventImage({
    super.key,
    required this.imageUrl,
    this.fit = BoxFit.cover,
  });

  @override
  State<EventImage> createState() => _EventImageState();
}

class _EventImageState extends State<EventImage> {
  Image? _cachedImage;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    if (!kIsWeb) {
      _loadCachedImage();
    }
  }

  @override
  void didUpdateWidget(EventImage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.imageUrl != widget.imageUrl && !kIsWeb) {
      _isLoading = true;
      _cachedImage = null;
      _loadCachedImage();
    }
  }

  Future<void> _loadCachedImage() async {
    try {
      final cacheManager = MarkerCacheManager();
      final cachedImage = await cacheManager.getCachedEventImage(widget.imageUrl);
      if (mounted) {
        setState(() {
          _cachedImage = cachedImage;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('EventImage: cache load failed: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // If not web, finished checking cache, and cache was found -> show cached
    if (!kIsWeb && !_isLoading && _cachedImage != null) {
      return Image(
        image: _cachedImage!.image,
        fit: widget.fit,
        errorBuilder: (context, error, stackTrace) => const Center(
          child: Icon(Icons.broken_image, color: Constants.creamColor),
        ),
      );
    }

    // Default fallback: Web, loading phase, or empty cache -> stream from network
    return Image.network(
      widget.imageUrl,
      fit: widget.fit,
      loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null) return child;
        return const Center(
          child: CircularProgressIndicator(color: Constants.redColor),
        );
      },
      errorBuilder: (context, error, stackTrace) => const Center(
        child: Icon(Icons.broken_image, color: Constants.creamColor),
      ),
    );
  }
}
