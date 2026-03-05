import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';

/// MarkerCacheManager caches Supabase Storage images (marker & event photos)
/// to disk so they don't need to be re-downloaded on every app launch.
///
/// Note: Firestore data caching is handled automatically by Firestore's
/// built-in offline persistence — no manual JSON caching needed here.
class MarkerCacheManager extends CacheManager {
  static const key = 'markerImageCache';
  static MarkerCacheManager? _instance;
  static const Duration _maxAge = Duration(hours: 24);

  factory MarkerCacheManager() {
    _instance ??= MarkerCacheManager._();
    return _instance!;
  }

  MarkerCacheManager._()
      : super(
          Config(
            key,
            stalePeriod: _maxAge,
            maxNrOfCacheObjects: 200,
            repo: JsonCacheInfoRepository(databaseName: key),
            fileService: HttpFileService(),
          ),
        );

  static const String markerImagePrefix = 'marker_image_';
  static const String eventImagePrefix = 'event_image_';

  // ─────────────────────────────────────────
  // Image cache helpers
  // ─────────────────────────────────────────

  /// Downloads [imageUrl] and stores it on disk. Returns the local file path.
  Future<String?> cacheImage(String imageUrl, String prefix) async {
    try {
      final fileInfo = await downloadFile(imageUrl, key: '$prefix$imageUrl');
      return fileInfo.file.path;
    } catch (e) {
      debugPrint('MarkerCacheManager: Error caching image: $e');
      return null;
    }
  }

  /// Returns a cached [Image] for [imageUrl], downloading if necessary.
  Future<Image?> getCachedImage(String imageUrl, String prefix) async {
    try {
      final fileInfo = await getFileFromCache('$prefix$imageUrl');
      if (fileInfo != null) return Image.file(fileInfo.file);

      final imagePath = await cacheImage(imageUrl, prefix);
      if (imagePath != null) return Image.file(File(imagePath));

      return Image.network(imageUrl);
    } catch (e) {
      debugPrint('MarkerCacheManager: Error loading cached image: $e');
      return Image.network(imageUrl);
    }
  }

  Future<String?> cacheMarkerImage(String imageUrl) =>
      cacheImage(imageUrl, markerImagePrefix);

  Future<Image?> getCachedMarkerImage(String imageUrl) =>
      getCachedImage(imageUrl, markerImagePrefix);

  Future<String?> cacheEventImage(String imageUrl) =>
      cacheImage(imageUrl, eventImagePrefix);

  Future<Image?> getCachedEventImage(String imageUrl) =>
      getCachedImage(imageUrl, eventImagePrefix);
}
