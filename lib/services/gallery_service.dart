import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:saver_gallery/saver_gallery.dart';
import 'package:path_provider/path_provider.dart';

/// Service untuk menangani penyimpanan foto ke galeri perangkat
/// Menggunakan pendekatan hybrid dengan saver_gallery package dan fallback manual
class GalleryService {
  static final GalleryService _instance = GalleryService._internal();
  factory GalleryService() => _instance;
  GalleryService._internal();

  /// Menyimpan foto ke galeri perangkat
  /// 
  /// [imagePath] - Path file gambar yang akan disimpan
  /// [fileName] - Nama file (opsional, akan generate otomatis jika null)
  /// [albumName] - Nama album/folder (default: 'Yupiread')
  /// 
  /// Returns [SaveResult] dengan status dan pesan
  Future<SaveResult> saveImageToGallery({
    required String imagePath,
    String? fileName,
    String albumName = 'Yupiread',
  }) async {
    try {
      // Validasi file exists
      final sourceFile = File(imagePath);
      if (!await sourceFile.exists()) {
        return SaveResult(
          success: false,
          message: 'File tidak ditemukan: $imagePath',
        );
      }

      // Request permission
      final hasPermission = await _requestStoragePermission();
      if (!hasPermission) {
        return SaveResult(
          success: false,
          message: 'Permission ditolak. Silakan berikan izin akses storage.',
        );
      }

      // Generate filename jika tidak disediakan
      final finalFileName = fileName ?? _generateFileName(imagePath);

      // Coba menggunakan saver_gallery terlebih dahulu (recommended approach)
      try {
        final result = await _saveWithSaverGallery(
          imagePath: imagePath,
          fileName: finalFileName,
          albumName: albumName,
        );
        
        if (result.success) {
          return result;
        }
      } catch (e) {
        debugPrint('SaverGallery failed, trying fallback: $e');
      }

      // Fallback ke manual approach jika saver_gallery gagal
      final fallbackResult = await _saveWithManualApproach(
        imagePath: imagePath,
        fileName: finalFileName,
        albumName: albumName,
      );

      return fallbackResult;
    } catch (e) {
      debugPrint('Error in saveImageToGallery: $e');
      return SaveResult(
        success: false,
        message: 'Gagal menyimpan foto: ${e.toString()}',
      );
    }
  }

  /// Menyimpan multiple foto ke galeri
  /// 
  /// [imagePaths] - List path file gambar
  /// [baseFileName] - Base name untuk file (akan ditambah index)
  /// [albumName] - Nama album/folder
  /// 
  /// Returns [BatchSaveResult] dengan detail hasil
  Future<BatchSaveResult> saveMultipleImagesToGallery({
    required List<String> imagePaths,
    String baseFileName = 'photo',
    String albumName = 'Yupiread',
  }) async {
    final results = <SaveResult>[];
    int successCount = 0;

    for (int i = 0; i < imagePaths.length; i++) {
      final fileName = '${baseFileName}_${i + 1}';
      final result = await saveImageToGallery(
        imagePath: imagePaths[i],
        fileName: fileName,
        albumName: albumName,
      );
      
      results.add(result);
      if (result.success) {
        successCount++;
      }
    }

    return BatchSaveResult(
      totalFiles: imagePaths.length,
      successCount: successCount,
      failedCount: imagePaths.length - successCount,
      results: results,
    );
  }

  /// Menggunakan saver_gallery package (recommended approach)
  Future<SaveResult> _saveWithSaverGallery({
    required String imagePath,
    required String fileName,
    required String albumName,
  }) async {
    try {
      // Read file as bytes
      final sourceFile = File(imagePath);
      final imageBytes = await sourceFile.readAsBytes();

      final result = await SaverGallery.saveImage(
        imageBytes,
        quality: 100,
        fileName: fileName,
        androidRelativePath: "Pictures/$albumName",
        skipIfExists: false,
      );

      // SaverGallery returns a Map<String, dynamic>
      final resultMap = result as Map<String, dynamic>;
      final isSuccess = resultMap['isSuccess'] as bool? ?? false;
      final filePath = resultMap['filePath'] as String?;
      final errorMessage = resultMap['errorMessage'] as String?;

      if (isSuccess) {
        return SaveResult(
          success: true,
          message: 'Foto berhasil disimpan ke galeri',
          filePath: filePath,
        );
      } else {
        return SaveResult(
          success: false,
          message: errorMessage ?? 'Gagal menyimpan dengan SaverGallery',
        );
      }
    } catch (e) {
      debugPrint('SaverGallery error: $e');
      rethrow;
    }
  }

  /// Fallback manual approach untuk kompatibilitas
  Future<SaveResult> _saveWithManualApproach({
    required String imagePath,
    required String fileName,
    required String albumName,
  }) async {
    try {
      final sourceFile = File(imagePath);
      
      // Tentukan direktori tujuan
      Directory? targetDir;
      
      // Coba berbagai lokasi sesuai prioritas
      final locations = [
        '/storage/emulated/0/Pictures/$albumName',
        '/storage/emulated/0/DCIM/$albumName',
      ];
      
      for (final location in locations) {
        try {
          targetDir = Directory(location);
          break;
        } catch (e) {
          continue;
        }
      }
      
      // Fallback ke external storage jika gagal
      if (targetDir == null) {
        final externalDir = await getExternalStorageDirectory();
        if (externalDir == null) {
          return SaveResult(
            success: false,
            message: 'Tidak dapat mengakses storage eksternal',
          );
        }
        targetDir = Directory('${externalDir.path}/Pictures/$albumName');
      }

      // Buat direktori jika belum ada
      if (!await targetDir.exists()) {
        await targetDir.create(recursive: true);
      }

      // Generate path file tujuan
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final extension = imagePath.split('.').last.toLowerCase();
      final targetPath = '${targetDir.path}/${fileName}_$timestamp.$extension';

      // Copy file
      await sourceFile.copy(targetPath);
      
      // Trigger media scanner (best effort)
      await _triggerMediaScan(targetPath);
      
      return SaveResult(
        success: true,
        message: 'Foto berhasil disimpan ke galeri (manual)',
        filePath: targetPath,
      );
    } catch (e) {
      debugPrint('Manual approach error: $e');
      return SaveResult(
        success: false,
        message: 'Gagal menyimpan dengan pendekatan manual: ${e.toString()}',
      );
    }
  }

  /// Request storage permission dengan handling untuk berbagai versi Android
  Future<bool> _requestStoragePermission() async {
    try {
      // Android 13+ (API 33+) - READ_MEDIA_IMAGES
      if (await Permission.photos.status.isGranted) {
        return true;
      }
      
      // Android 12 and below - READ_EXTERNAL_STORAGE/WRITE_EXTERNAL_STORAGE
      if (await Permission.storage.status.isGranted) {
        return true;
      }
      
      // Request photos permission (Android 13+)
      final photosPermission = await Permission.photos.request();
      if (photosPermission.isGranted) {
        return true;
      }
      
      // Request storage permission (Android 12 and below)
      final storagePermission = await Permission.storage.request();
      if (storagePermission.isGranted) {
        return true;
      }
      
      return false;
    } catch (e) {
      debugPrint('Permission request error: $e');
      return false;
    }
  }

  /// Generate nama file unik
  String _generateFileName(String originalPath) {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final extension = originalPath.split('.').last.toLowerCase();
    return 'yupiread_$timestamp.$extension';
  }

  /// Trigger media scanner untuk membuat file terdeteksi di galeri
  Future<void> _triggerMediaScan(String filePath) async {
    try {
      final directory = Directory(filePath).parent;
      final nomediaFile = File('${directory.path}/.nomedia');
      
      // Create and delete .nomedia to trigger media scan
      if (await nomediaFile.exists()) {
        await nomediaFile.delete();
      }
      await nomediaFile.create();
      await nomediaFile.delete();
    } catch (e) {
      debugPrint('Media scan trigger failed: $e');
    }
  }

  /// Check apakah permission sudah diberikan
  Future<bool> hasStoragePermission() async {
    return await Permission.photos.status.isGranted || 
           await Permission.storage.status.isGranted;
  }

  /// Buka pengaturan aplikasi untuk permission
  Future<void> openPermissionSettings() async {
    await openAppSettings();
  }
}

/// Result class untuk single save operation
class SaveResult {
  final bool success;
  final String message;
  final String? filePath;

  SaveResult({
    required this.success,
    required this.message,
    this.filePath,
  });

  @override
  String toString() {
    return 'SaveResult(success: $success, message: $message, filePath: $filePath)';
  }
}

/// Result class untuk batch save operation
class BatchSaveResult {
  final int totalFiles;
  final int successCount;
  final int failedCount;
  final List<SaveResult> results;

  BatchSaveResult({
    required this.totalFiles,
    required this.successCount,
    required this.failedCount,
    required this.results,
  });

  bool get hasAnySuccess => successCount > 0;
  bool get allSuccess => successCount == totalFiles;
  double get successRate => totalFiles > 0 ? successCount / totalFiles : 0.0;

  String get summaryMessage {
    if (allSuccess) {
      return 'Semua $totalFiles foto berhasil disimpan ke galeri';
    } else if (hasAnySuccess) {
      return '$successCount dari $totalFiles foto berhasil disimpan ke galeri';
    } else {
      return 'Gagal menyimpan semua foto ke galeri';
    }
  }

  @override
  String toString() {
    return 'BatchSaveResult(total: $totalFiles, success: $successCount, failed: $failedCount)';
  }
}
