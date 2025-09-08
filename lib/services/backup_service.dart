import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:googleapis/drive/v3.dart' as drive;
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:archive/archive_io.dart';
import 'data_service.dart';

class BackupService extends ChangeNotifier {
  static final BackupService _instance = BackupService._internal();
  factory BackupService() => _instance;
  static BackupService get instance => _instance;
  BackupService._internal() {
    _initializeGoogleSignIn();
  }

  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: [
      'email',
      'https://www.googleapis.com/auth/drive.file',
    ],
  );

  bool _isBackingUp = false;
  bool _isRestoring = false;
  double _backupProgress = 0.0;
  double _restoreProgress = 0.0;
  String _backupStatus = '';
  String _restoreStatus = '';
  bool _isInitialized = false;

  bool get isBackingUp => _isBackingUp;
  bool get isRestoring => _isRestoring;
  double get backupProgress => _backupProgress;
  double get restoreProgress => _restoreProgress;
  String get backupStatus => _backupStatus;
  String get restoreStatus => _restoreStatus;

  /// Initialize Google Sign In and restore previous session
  Future<void> _initializeGoogleSignIn() async {
    if (_isInitialized) return;
    
    try {
      // Try to restore previous sign-in session silently
      await _googleSignIn.signInSilently();
      _isInitialized = true;
      notifyListeners();
    } catch (e) {
      debugPrint('Failed to restore Google Sign In session: $e');
      _isInitialized = true;
    }
  }

  /// Ensure Google Sign In is initialized
  Future<void> _ensureInitialized() async {
    if (!_isInitialized) {
      await _initializeGoogleSignIn();
    }
  }

  /// Initialize the backup service (call this when app starts)
  Future<void> initialize() async {
    await _ensureInitialized();
  }

  /// Sign in to Google Drive
  Future<bool> signInToGoogleDrive() async {
    try {
      await _ensureInitialized();
      final account = await _googleSignIn.signIn();
      if (account != null) {
        notifyListeners();
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('Google Sign In Error: $e');
      return false;
    }
  }

  /// Sign out from Google Drive
  Future<void> signOutFromGoogleDrive() async {
    await _googleSignIn.signOut();
    notifyListeners();
  }

  /// Check if user is signed in to Google Drive
  bool get isSignedInToGoogleDrive {
    return _googleSignIn.currentUser != null;
  }

  /// Get current user email
  String? get currentUserEmail => _googleSignIn.currentUser?.email;

  /// Create authenticated HTTP client
  Future<http.Client?> _createAuthenticatedClient() async {
    await _ensureInitialized();
    
    final account = _googleSignIn.currentUser;
    if (account == null) return null;

    try {
      final authHeaders = await account.authHeaders;
      return _GoogleAuthClient(authHeaders);
    } catch (e) {
      debugPrint('Failed to get auth headers: $e');
      // Try to refresh authentication
      final refreshedAccount = await _googleSignIn.signInSilently();
      if (refreshedAccount != null) {
        final authHeaders = await refreshedAccount.authHeaders;
        return _GoogleAuthClient(authHeaders);
      }
      return null;
    }
  }

  /// Backup all app data to Google Drive
  Future<bool> backupToGoogleDrive() async {
    if (_isBackingUp) return false;

    _isBackingUp = true;
    _backupProgress = 0.0;
    _backupStatus = 'Memulai backup...';
    notifyListeners();

    try {
      // Create authenticated client
      final client = await _createAuthenticatedClient();
      if (client == null) {
        throw Exception('Gagal membuat koneksi ke Google Drive');
      }

      final driveApi = drive.DriveApi(client);

      // Step 1: Create backup data structure
      _backupStatus = 'Mengumpulkan data aplikasi...';
      _backupProgress = 0.1;
      notifyListeners();

      final backupData = await _createBackupData();

      // Step 2: Create temporary backup file
      _backupStatus = 'Membuat file backup...';
      _backupProgress = 0.3;
      notifyListeners();

      final backupFile = await _createBackupFile(backupData);

      // Step 3: Upload to Google Drive
      _backupStatus = 'Mengupload ke Google Drive...';
      _backupProgress = 0.7;
      notifyListeners();

      final fileName = 'yupiread_backup_${DateTime.now().millisecondsSinceEpoch}.zip';
      
      // Check if backup folder exists, create if not
      final folderId = await _getOrCreateBackupFolder(driveApi);
      
      final driveFile = drive.File()
        ..name = fileName
        ..parents = [folderId];

      await driveApi.files.create(
        driveFile,
        uploadMedia: drive.Media(backupFile.openRead(), backupFile.lengthSync()),
      );

      // Clean up temporary file
      await backupFile.delete();

      _backupStatus = 'Backup berhasil!';
      _backupProgress = 1.0;
      notifyListeners();

      return true;
    } catch (e) {
      _backupStatus = 'Backup gagal: ${e.toString()}';
      debugPrint('Backup Error: $e');
      return false;
    } finally {
      _isBackingUp = false;
      notifyListeners();
    }
  }

  /// Restore app data from Google Drive
  Future<bool> restoreFromGoogleDrive(String fileId) async {
    if (_isRestoring) return false;

    _isRestoring = true;
    _restoreProgress = 0.0;
    _restoreStatus = 'Memulai restore...';
    notifyListeners();

    try {
      // Create authenticated client
      final client = await _createAuthenticatedClient();
      if (client == null) {
        throw Exception('Gagal membuat koneksi ke Google Drive');
      }

      final driveApi = drive.DriveApi(client);

      // Step 1: Download backup file
      _restoreStatus = 'Mendownload backup dari Google Drive...';
      _restoreProgress = 0.2;
      notifyListeners();

      final response = await driveApi.files.get(
        fileId,
        downloadOptions: drive.DownloadOptions.fullMedia,
      ) as drive.Media;

      // Step 2: Save downloaded file
      _restoreStatus = 'Menyimpan file backup...';
      _restoreProgress = 0.4;
      notifyListeners();

      final tempDir = await getTemporaryDirectory();
      final backupFile = File('${tempDir.path}/restore_backup.zip');
      
      final bytes = <int>[];
      await for (final chunk in response.stream) {
        bytes.addAll(chunk);
      }
      await backupFile.writeAsBytes(bytes);

      // Step 3: Extract and restore data
      _restoreStatus = 'Mengekstrak data...';
      _restoreProgress = 0.6;
      notifyListeners();

      await _restoreFromBackupFile(backupFile);

      // Clean up
      await backupFile.delete();

      _restoreStatus = 'Restore berhasil!';
      _restoreProgress = 1.0;
      notifyListeners();

      return true;
    } catch (e) {
      _restoreStatus = 'Restore gagal: ${e.toString()}';
      debugPrint('Restore Error: $e');
      return false;
    } finally {
      _isRestoring = false;
      notifyListeners();
    }
  }

  /// Get list of backup files from Google Drive
  Future<List<BackupFileInfo>> getBackupFiles() async {
    try {
      final client = await _createAuthenticatedClient();
      if (client == null) return [];

      final driveApi = drive.DriveApi(client);
      final folderId = await _getOrCreateBackupFolder(driveApi);

      final fileList = await driveApi.files.list(
        q: "'$folderId' in parents and name contains 'yupiread_backup'",
        orderBy: 'createdTime desc',
        pageSize: 50,
      );

      return fileList.files?.map((file) => BackupFileInfo(
        id: file.id!,
        name: file.name!,
        size: file.size != null ? int.tryParse(file.size!) ?? 0 : 0,
        createdTime: file.createdTime ?? DateTime.now(),
      )).toList() ?? [];
    } catch (e) {
      debugPrint('Get Backup Files Error: $e');
      return [];
    }
  }

  /// Delete backup file from Google Drive
  Future<bool> deleteBackupFile(String fileId) async {
    try {
      final client = await _createAuthenticatedClient();
      if (client == null) return false;

      final driveApi = drive.DriveApi(client);
      await driveApi.files.delete(fileId);
      return true;
    } catch (e) {
      debugPrint('Delete Backup File Error: $e');
      return false;
    }
  }

  /// Create backup data structure
  Future<Map<String, dynamic>> _createBackupData() async {
    final prefs = await SharedPreferences.getInstance();
    final appDir = await getApplicationDocumentsDirectory();

    // Get all SharedPreferences data
    final prefsData = <String, dynamic>{};
    for (final key in ['photos', 'photoPages', 'ebooks', 'activities', 'userProfile', 'customTags']) {
      final value = prefs.getString(key);
      if (value != null) {
        prefsData[key] = value;
      }
    }

    // Get file paths
    final photosDir = Directory('${appDir.path}/photos');
    final ebooksDir = Directory('${appDir.path}/ebooks');

    final photoFiles = <String>[];
    final ebookFiles = <String>[];

    if (await photosDir.exists()) {
      await for (final entity in photosDir.list()) {
        if (entity is File) {
          photoFiles.add(entity.path);
        }
      }
    }

    if (await ebooksDir.exists()) {
      await for (final entity in ebooksDir.list()) {
        if (entity is File) {
          ebookFiles.add(entity.path);
        }
      }
    }

    return {
      'version': '1.0',
      'timestamp': DateTime.now().toIso8601String(),
      'preferences': prefsData,
      'photoFiles': photoFiles,
      'ebookFiles': ebookFiles,
    };
  }

  /// Create backup ZIP file
  Future<File> _createBackupFile(Map<String, dynamic> backupData) async {
    final tempDir = await getTemporaryDirectory();
    final backupFile = File('${tempDir.path}/yupiread_backup.zip');

    final encoder = ZipFileEncoder();
    encoder.create(backupFile.path);

    // Add metadata
    final metadataJson = jsonEncode({
      'version': backupData['version'],
      'timestamp': backupData['timestamp'],
      'preferences': backupData['preferences'],
    });
    encoder.addArchiveFile(ArchiveFile('metadata.json', metadataJson.length, utf8.encode(metadataJson)));

    // Add photo files
    final photoFiles = backupData['photoFiles'] as List<String>;
    for (final filePath in photoFiles) {
      final file = File(filePath);
      if (await file.exists()) {
        final fileName = 'photos/${file.path.split('/').last}';
        encoder.addFile(file, fileName);
      }
    }

    // Add ebook files
    final ebookFiles = backupData['ebookFiles'] as List<String>;
    for (final filePath in ebookFiles) {
      final file = File(filePath);
      if (await file.exists()) {
        final fileName = 'ebooks/${file.path.split('/').last}';
        encoder.addFile(file, fileName);
      }
    }

    encoder.close();
    return backupFile;
  }

  /// Restore from backup file
  Future<void> _restoreFromBackupFile(File backupFile) async {
    final tempDir = await getTemporaryDirectory();
    final extractDir = Directory('${tempDir.path}/extract');
    
    if (await extractDir.exists()) {
      await extractDir.delete(recursive: true);
    }
    await extractDir.create();

    // Extract ZIP file
    final bytes = await backupFile.readAsBytes();
    final archive = ZipDecoder().decodeBytes(bytes);

    for (final file in archive) {
      final filename = file.name;
      if (file.isFile) {
        final data = file.content as List<int>;
        final extractedFile = File('${extractDir.path}/$filename');
        await extractedFile.create(recursive: true);
        await extractedFile.writeAsBytes(data);
      }
    }

    // Read metadata
    final metadataFile = File('${extractDir.path}/metadata.json');
    if (await metadataFile.exists()) {
      final metadataJson = await metadataFile.readAsString();
      final metadata = jsonDecode(metadataJson);

      // Restore SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      final prefsData = metadata['preferences'] as Map<String, dynamic>;
      for (final entry in prefsData.entries) {
        await prefs.setString(entry.key, entry.value);
      }
    }

    // Restore files
    final appDir = await getApplicationDocumentsDirectory();
    
    // Restore photos
    final photosExtractDir = Directory('${extractDir.path}/photos');
    if (await photosExtractDir.exists()) {
      final photosTargetDir = Directory('${appDir.path}/photos');
      if (!await photosTargetDir.exists()) {
        await photosTargetDir.create(recursive: true);
      }

      await for (final entity in photosExtractDir.list()) {
        if (entity is File) {
          final targetFile = File('${photosTargetDir.path}/${entity.path.split('/').last}');
          await entity.copy(targetFile.path);
        }
      }
    }

    // Restore ebooks
    final ebooksExtractDir = Directory('${extractDir.path}/ebooks');
    if (await ebooksExtractDir.exists()) {
      final ebooksTargetDir = Directory('${appDir.path}/ebooks');
      if (!await ebooksTargetDir.exists()) {
        await ebooksTargetDir.create(recursive: true);
      }

      await for (final entity in ebooksExtractDir.list()) {
        if (entity is File) {
          final targetFile = File('${ebooksTargetDir.path}/${entity.path.split('/').last}');
          await entity.copy(targetFile.path);
        }
      }
    }

    // Clean up
    await extractDir.delete(recursive: true);

    // Reload data in DataService
    await DataService.instance.initializeData();
  }

  /// Get or create backup folder in Google Drive
  Future<String> _getOrCreateBackupFolder(drive.DriveApi driveApi) async {
    const folderName = 'Yupiread Backups';

    // Search for existing folder
    final folderList = await driveApi.files.list(
      q: "name='$folderName' and mimeType='application/vnd.google-apps.folder'",
      pageSize: 1,
    );

    if (folderList.files?.isNotEmpty == true) {
      return folderList.files!.first.id!;
    }

    // Create new folder
    final folder = drive.File()
      ..name = folderName
      ..mimeType = 'application/vnd.google-apps.folder';

    final createdFolder = await driveApi.files.create(folder);
    return createdFolder.id!;
  }
}

/// Custom HTTP client with Google authentication
class _GoogleAuthClient extends http.BaseClient {
  final Map<String, String> _headers;
  final http.Client _client = http.Client();

  _GoogleAuthClient(this._headers);

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) {
    request.headers.addAll(_headers);
    return _client.send(request);
  }

  @override
  void close() {
    _client.close();
  }
}

/// Backup file information
class BackupFileInfo {
  final String id;
  final String name;
  final int size;
  final DateTime createdTime;

  BackupFileInfo({
    required this.id,
    required this.name,
    required this.size,
    required this.createdTime,
  });

  String get formattedSize {
    if (size < 1024) return '$size B';
    if (size < 1024 * 1024) return '${(size / 1024).toStringAsFixed(1)} KB';
    return '${(size / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  String get formattedDate {
    final now = DateTime.now();
    final difference = now.difference(createdTime);

    if (difference.inDays > 0) {
      return '${difference.inDays} hari lalu';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} jam lalu';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} menit lalu';
    } else {
      return 'Baru saja';
    }
  }
}
