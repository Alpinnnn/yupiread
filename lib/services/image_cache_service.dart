import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

class ImageCacheService {
  static final ImageCacheService _instance = ImageCacheService._internal();
  factory ImageCacheService() => _instance;
  static ImageCacheService get instance => _instance;
  ImageCacheService._internal();

  final Map<String, Uint8List> _memoryCache = {};
  final Map<String, DateTime> _cacheTimestamps = {};
  static const int maxMemoryCacheSize = 50; // Maximum items in memory cache
  static const Duration cacheExpiry = Duration(hours: 24); // Cache expiry time
  
  Directory? _cacheDirectory;

  Future<void> initialize() async {
    final appDir = await getApplicationDocumentsDirectory();
    _cacheDirectory = Directory('${appDir.path}/image_cache');
    if (!await _cacheDirectory!.exists()) {
      await _cacheDirectory!.create(recursive: true);
    }
    
    // Clean expired cache on startup
    await _cleanExpiredCache();
  }

  String _getCacheKey(String imagePath) {
    return imagePath.hashCode.toString();
  }

  Future<Uint8List?> getCachedImage(String imagePath) async {
    final cacheKey = _getCacheKey(imagePath);
    
    // Check memory cache first
    if (_memoryCache.containsKey(cacheKey)) {
      final timestamp = _cacheTimestamps[cacheKey];
      if (timestamp != null && DateTime.now().difference(timestamp) < cacheExpiry) {
        return _memoryCache[cacheKey];
      } else {
        // Remove expired item from memory cache
        _memoryCache.remove(cacheKey);
        _cacheTimestamps.remove(cacheKey);
      }
    }

    // Check disk cache
    if (_cacheDirectory != null) {
      final cacheFile = File('${_cacheDirectory!.path}/$cacheKey.cache');
      if (await cacheFile.exists()) {
        final stats = await cacheFile.stat();
        if (DateTime.now().difference(stats.modified) < cacheExpiry) {
          try {
            final bytes = await cacheFile.readAsBytes();
            // Add to memory cache
            _addToMemoryCache(cacheKey, bytes);
            return bytes;
          } catch (e) {
            // If cache file is corrupted, delete it
            await cacheFile.delete();
          }
        } else {
          // Delete expired cache file
          await cacheFile.delete();
        }
      }
    }

    // Load original image and cache it
    return await _loadAndCacheImage(imagePath);
  }

  Future<Uint8List?> _loadAndCacheImage(String imagePath) async {
    try {
      final file = File(imagePath);
      if (!await file.exists()) {
        return null;
      }

      final bytes = await file.readAsBytes();
      final cacheKey = _getCacheKey(imagePath);

      // Add to memory cache
      _addToMemoryCache(cacheKey, bytes);

      // Save to disk cache
      if (_cacheDirectory != null) {
        final cacheFile = File('${_cacheDirectory!.path}/$cacheKey.cache');
        await cacheFile.writeAsBytes(bytes);
      }

      return bytes;
    } catch (e) {
      if (kDebugMode) {
        print('Error loading image: $e');
      }
      return null;
    }
  }

  void _addToMemoryCache(String cacheKey, Uint8List bytes) {
    // Remove oldest items if cache is full
    if (_memoryCache.length >= maxMemoryCacheSize) {
      _evictOldestFromMemoryCache();
    }

    _memoryCache[cacheKey] = bytes;
    _cacheTimestamps[cacheKey] = DateTime.now();
  }

  void _evictOldestFromMemoryCache() {
    if (_cacheTimestamps.isEmpty) return;

    // Find oldest entry
    String? oldestKey;
    DateTime? oldestTime;

    for (final entry in _cacheTimestamps.entries) {
      if (oldestTime == null || entry.value.isBefore(oldestTime)) {
        oldestTime = entry.value;
        oldestKey = entry.key;
      }
    }

    if (oldestKey != null) {
      _memoryCache.remove(oldestKey);
      _cacheTimestamps.remove(oldestKey);
    }
  }

  Future<void> _cleanExpiredCache() async {
    if (_cacheDirectory == null || !await _cacheDirectory!.exists()) {
      return;
    }

    try {
      final files = await _cacheDirectory!.list().toList();
      for (final file in files) {
        if (file is File && file.path.endsWith('.cache')) {
          final stats = await file.stat();
          if (DateTime.now().difference(stats.modified) > cacheExpiry) {
            await file.delete();
          }
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error cleaning cache: $e');
      }
    }
  }

  Future<void> clearCache() async {
    // Clear memory cache
    _memoryCache.clear();
    _cacheTimestamps.clear();

    // Clear disk cache
    if (_cacheDirectory != null && await _cacheDirectory!.exists()) {
      try {
        await _cacheDirectory!.delete(recursive: true);
        await _cacheDirectory!.create(recursive: true);
      } catch (e) {
        if (kDebugMode) {
          print('Error clearing cache: $e');
        }
      }
    }
  }

  Future<int> getCacheSize() async {
    int totalSize = 0;

    // Memory cache size
    for (final bytes in _memoryCache.values) {
      totalSize += bytes.length;
    }

    // Disk cache size
    if (_cacheDirectory != null && await _cacheDirectory!.exists()) {
      try {
        final files = await _cacheDirectory!.list().toList();
        for (final file in files) {
          if (file is File) {
            final stats = await file.stat();
            totalSize += stats.size;
          }
        }
      } catch (e) {
        if (kDebugMode) {
          print('Error calculating cache size: $e');
        }
      }
    }

    return totalSize;
  }

  String formatCacheSize(int bytes) {
    if (bytes < 1024) {
      return '$bytes B';
    } else if (bytes < 1024 * 1024) {
      return '${(bytes / 1024).toStringAsFixed(1)} KB';
    } else {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
  }

  // Preload images for better performance
  Future<void> preloadImages(List<String> imagePaths) async {
    for (final path in imagePaths) {
      // Load in background without blocking UI
      getCachedImage(path);
    }
  }
}
