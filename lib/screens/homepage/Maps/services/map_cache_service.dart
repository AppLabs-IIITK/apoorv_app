import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:cached_network_image/cached_network_image.dart';

class MapTileCacheManager extends CacheManager {
  static const key = 'mapTileCache';
  static MapTileCacheManager? _instance;

  factory MapTileCacheManager() {
    _instance ??= MapTileCacheManager._();
    return _instance!;
  }

  MapTileCacheManager._()
      : super(
          Config(
            key,
            stalePeriod: const Duration(days: 1),
            maxNrOfCacheObjects: 1000,
            repo: JsonCacheInfoRepository(databaseName: key),
            fileService: HttpFileService(),
          ),
        );
}

class CachedTileProvider extends TileProvider {
  final MapTileCacheManager cacheManager;
  final Set<String> _cachedUrls = {};

  final Set<int> zoomLevelsToCache;

  CachedTileProvider({required this.zoomLevelsToCache})
      : cacheManager = MapTileCacheManager();

  bool _shouldCacheZoomLevel(int zoom) {
    return zoomLevelsToCache.contains(zoom);
  }

  @override
  ImageProvider getImage(TileCoordinates coordinates, TileLayer options) {
    final url = getTileUrl(coordinates, options);

    if (_shouldCacheZoomLevel(coordinates.z)) {
      if (!_cachedUrls.contains(url)) {
        _cachedUrls.add(url);
      }
      return CachedNetworkImageProvider(
        url,
        cacheManager: cacheManager,
      );
    } else {
      return NetworkImage(url);
    }
  }
}
