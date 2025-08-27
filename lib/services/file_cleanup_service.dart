import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

class FileCleanupService {
  static final FileCleanupService _instance = FileCleanupService._internal();
  factory FileCleanupService() => _instance;
  static FileCleanupService get instance => _instance;
  FileCleanupService._internal();

  static const Duration _tempFileExpiry = Duration(days: 7);
  static const Duration _cacheExpiry = Duration(days: 30);
  static const int _maxCacheSizeMB = 500;

  Future<void> performCleanup() async {
    try {
      await Future.wait([
        _cleanupTempFiles(),
        _cleanupOldCacheFiles(),
        _cleanupOrphanedFiles(),
        _enforceCacheSizeLimit(),
      ]);
    } catch (e) {
      if (kDebugMode) {
        print('Error during cleanup: $e');
      }
    }
  }

  Future<void> _cleanupTempFiles() async {
    try {
      final tempDir = await getTemporaryDirectory();
      if (!await tempDir.exists()) return;

      final files = await tempDir.list(recursive: true).toList();
      final now = DateTime.now();

      for (final file in files) {
        if (file is File) {
          final stats = await file.stat();
          if (now.difference(stats.modified) > _tempFileExpiry) {
            try {
              await file.delete();
            } catch (e) {
              if (kDebugMode) {
                print('Failed to delete temp file: ${file.path}');
              }
            }
          }
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error cleaning temp files: $e');
      }
    }
  }

  Future<void> _cleanupOldCacheFiles() async {
    try {
      final appDir = await getApplicationDocumentsDirectory();
      final cacheDir = Directory('${appDir.path}/image_cache');
      
      if (!await cacheDir.exists()) return;

      final files = await cacheDir.list().toList();
      final now = DateTime.now();

      for (final file in files) {
        if (file is File && file.path.endsWith('.cache')) {
          final stats = await file.stat();
          if (now.difference(stats.modified) > _cacheExpiry) {
            try {
              await file.delete();
            } catch (e) {
              if (kDebugMode) {
                print('Failed to delete cache file: ${file.path}');
              }
            }
          }
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error cleaning cache files: $e');
      }
    }
  }

  Future<void> _cleanupOrphanedFiles() async {
    try {
      final appDir = await getApplicationDocumentsDirectory();
      final photosDir = Directory('${appDir.path}/photos');
      final ebooksDir = Directory('${appDir.path}/ebooks');

      // This would require integration with DatabaseService to check
      // which files are still referenced in the database
      // For now, we'll skip this to avoid circular dependencies
      
      if (kDebugMode) {
        print('Orphaned file cleanup would require database integration');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error cleaning orphaned files: $e');
      }
    }
  }

  Future<void> _enforceCacheSizeLimit() async {
    try {
      final appDir = await getApplicationDocumentsDirectory();
      final cacheDir = Directory('${appDir.path}/image_cache');
      
      if (!await cacheDir.exists()) return;

      final files = await cacheDir.list().toList();
      final fileStats = <FileSystemEntity, FileStat>{};
      int totalSize = 0;

      // Calculate total cache size
      for (final file in files) {
        if (file is File) {
          final stats = await file.stat();
          fileStats[file] = stats;
          totalSize += stats.size;
        }
      }

      final maxSizeBytes = _maxCacheSizeMB * 1024 * 1024;
      if (totalSize <= maxSizeBytes) return;

      // Sort files by last modified (oldest first)
      final sortedFiles = fileStats.entries.toList()
        ..sort((a, b) => a.value.modified.compareTo(b.value.modified));

      // Delete oldest files until under size limit
      for (final entry in sortedFiles) {
        if (totalSize <= maxSizeBytes) break;

        try {
          await entry.key.delete();
          totalSize -= entry.value.size;
        } catch (e) {
          if (kDebugMode) {
            print('Failed to delete cache file for size limit: ${entry.key.path}');
          }
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error enforcing cache size limit: $e');
      }
    }
  }

  Future<Map<String, dynamic>> getCacheInfo() async {
    try {
      final appDir = await getApplicationDocumentsDirectory();
      final cacheDir = Directory('${appDir.path}/image_cache');
      
      if (!await cacheDir.exists()) {
        return {
          'totalSize': 0,
          'fileCount': 0,
          'formattedSize': '0 B',
        };
      }

      final files = await cacheDir.list().toList();
      int totalSize = 0;
      int fileCount = 0;

      for (final file in files) {
        if (file is File) {
          final stats = await file.stat();
          totalSize += stats.size;
          fileCount++;
        }
      }

      return {
        'totalSize': totalSize,
        'fileCount': fileCount,
        'formattedSize': _formatBytes(totalSize),
      };
    } catch (e) {
      return {
        'totalSize': 0,
        'fileCount': 0,
        'formattedSize': '0 B',
        'error': e.toString(),
      };
    }
  }

  String _formatBytes(int bytes) {
    if (bytes < 1024) {
      return '$bytes B';
    } else if (bytes < 1024 * 1024) {
      return '${(bytes / 1024).toStringAsFixed(1)} KB';
    } else if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    } else {
      return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
    }
  }

  Future<void> clearAllCache() async {
    try {
      final appDir = await getApplicationDocumentsDirectory();
      final cacheDir = Directory('${appDir.path}/image_cache');
      
      if (await cacheDir.exists()) {
        await cacheDir.delete(recursive: true);
        await cacheDir.create(recursive: true);
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error clearing all cache: $e');
      }
      rethrow;
    }
  }

  Future<void> schedulePeriodicCleanup() async {
    // This would typically be called on app startup
    // and could be enhanced with a background service
    await performCleanup();
  }
}
