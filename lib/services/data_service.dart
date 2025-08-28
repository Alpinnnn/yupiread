import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/photo_model.dart';
import '../models/ebook_model.dart';
import '../models/activity_type.dart';
import 'database_service.dart';

class DataService {
  static final DataService _instance = DataService._internal();
  factory DataService() => _instance;
  static DataService get instance => _instance;
  DataService._internal();

  final List<PhotoModel> _photos = [];
  final List<PhotoPageModel> _photoPages = [];
  final List<EbookModel> _ebooks = [];
  final List<ActivityModel> _activities = [];
  final List<String> _availableTags = [
    'Matematika',
    'Fisika',
    'Kimia',
    'Biologi',
    'Sejarah',
    'Geografi',
    'Bahasa',
    'Seni',
    'Olahraga',
    'Teknologi',
    'Kuliner',
    'Travel',
    'Personal',
    'Bisnis',
    'Kesehatan',
  ];
  List<String> _customTags = [];

  // User profile data
  String _username = 'User';
  String? _profileImagePath;
  int _readingStreak = 0;
  int _totalReadingTimeMinutes = 0;
  DateTime? _lastReadingDate;

  List<PhotoModel> get photos => List.unmodifiable(_photos);
  List<PhotoPageModel> get photoPages => List.unmodifiable(_photoPages);
  List<EbookModel> get ebooks => List.unmodifiable(_ebooks);
  List<ActivityModel> get activities => List.unmodifiable(_activities);
  List<String> get availableTags =>
      List.unmodifiable([..._availableTags, ..._customTags]);
  List<String> get customTags => List.unmodifiable(_customTags);

  // Initialize data when app starts
  Future<void> initializeData() async {
    await _loadPhotos();
    await _loadPhotoPages();
    await _loadEbooks();
    await _loadActivities();
    await _loadUserProfile();
    await _loadCustomTags();
  }

  String addPhoto({
    required String title,
    required String imagePath,
    List<String> tags = const [],
    String description = '',
  }) {
    final id = _generateId();
    final photo = PhotoModel(
      id: id,
      title: title,
      imagePath: imagePath,
      createdAt: DateTime.now(),
      tags: tags,
      description: description,
    );

    _photos.insert(0, photo); // Add to beginning for newest first
    _savePhotos(); // Save to persistent storage

    // Log activity with specific photo name
    _logActivity(
      title: 'Foto "$title" ditambahkan',
      description: 'Foto catatan baru berhasil disimpan',
      type: ActivityType.photoAdded,
    );

    return id;
  }

  bool deletePhoto(String id) {
    final index = _photos.indexWhere((photo) => photo.id == id);
    if (index != -1) {
      final photo = _photos[index];
      _photos.removeAt(index);
      _savePhotos(); // Save to persistent storage

      // Delete physical file
      _deletePhotoFile(photo.imagePath);

      // Log activity with specific photo name
      _logActivity(
        title: 'Foto "${photo.title}" dihapus',
        description: 'Foto catatan telah dihapus dari galeri',
        type: ActivityType.photoDeleted,
      );

      return true;
    }
    return false;
  }

  bool updatePhoto({
    required String id,
    String? title,
    List<String>? tags,
    String? description,
  }) {
    final index = _photos.indexWhere((photo) => photo.id == id);
    if (index != -1) {
      final oldPhoto = _photos[index];
      final newPhoto = oldPhoto.copyWith(
        title: title,
        tags: tags,
        description: description,
      );

      _photos[index] = newPhoto;
      _savePhotos(); // Save to persistent storage

      // Log activity based on what changed
      if (title != null && title != oldPhoto.title) {
        _logActivity(
          title: 'Foto "${oldPhoto.title}" diubah menjadi "$title"',
          description: 'Nama foto berhasil diperbarui',
          type: ActivityType.photoEdited,
        );
      } else {
        _logActivity(
          title: 'Foto "${newPhoto.title}" diedit',
          description: 'Detail foto berhasil diperbarui',
          type: ActivityType.photoEdited,
        );
      }

      return true;
    }
    return false;
  }

  PhotoModel? getPhoto(String id) {
    try {
      return _photos.firstWhere((photo) => photo.id == id);
    } catch (e) {
      return null;
    }
  }

  List<PhotoModel> getFilteredPhotos(List<String> selectedTags) {
    if (selectedTags.isEmpty) {
      return photos;
    }

    return _photos.where((photo) {
      return photo.tags.any((tag) => selectedTags.contains(tag));
    }).toList();
  }

  List<String> getUsedTags() {
    final Set<String> usedTags = {};

    // Add tags from regular photos
    for (final photo in _photos) {
      usedTags.addAll(photo.tags);
    }

    // Add tags from photo pages
    for (final photoPage in _photoPages) {
      usedTags.addAll(photoPage.tags);
    }

    return usedTags.toList()..sort();
  }

  // Save photo file to app directory
  Future<String> savePhotoFile(String sourcePath) async {
    try {
      final appDir = await getApplicationDocumentsDirectory();
      final photoDir = Directory('${appDir.path}/photos');
      if (!await photoDir.exists()) {
        await photoDir.create(recursive: true);
      }

      final fileName = '${DateTime.now().millisecondsSinceEpoch}.jpg';
      final targetPath = '${photoDir.path}/$fileName';

      final sourceFile = File(sourcePath);
      await sourceFile.copy(targetPath);

      return targetPath;
    } catch (e) {
      throw Exception('Failed to save photo: $e');
    }
  }

  // Delete photo file from storage
  Future<void> _deletePhotoFile(String imagePath) async {
    try {
      final file = File(imagePath);
      if (await file.exists()) {
        await file.delete();
      }
    } catch (e) {
      // Ignore deletion errors
    }
  }

  void _logActivity({
    required String title,
    required String description,
    required ActivityType type,
  }) {
    final activity = ActivityModel(
      id: _generateId(),
      title: title,
      description: description,
      timestamp: DateTime.now(),
      type: type,
    );

    _activities.insert(0, activity); // Add to beginning for newest first

    // Keep only last 20 activities
    if (_activities.length > 20) {
      _activities.removeRange(20, _activities.length);
    }

    _saveActivities(); // Save to persistent storage
  }

  void logEbookActivity({
    required String title,
    required String description,
    required ActivityType type,
  }) {
    _logActivity(title: title, description: description, type: type);
  }

  String _generateId() {
    return DateTime.now().millisecondsSinceEpoch.toString() +
        Random().nextInt(1000).toString();
  }

  // Get statistics for dashboard
  int get totalPhotos => _photos.length;
  int get totalEbooks => _ebooks.length;
  String get totalReadingTime => '12h 30m'; // Static for now
  int get activityStreak => 7; // Static for now

  // Ebook CRUD operations
  String addEbook({
    required String title,
    required String filePath,
    List<String> tags = const [],
    String description = '',
    int totalPages = 1,
    String fileType = 'pdf',
  }) {
    final id = _generateId();
    final ebook = EbookModel(
      id: id,
      title: title,
      filePath: filePath,
      fileType: fileType,
      createdAt: DateTime.now(),
      tags: tags,
      description: description,
      totalPages: totalPages,
    );

    _ebooks.insert(0, ebook); // Add to beginning for newest first
    _saveEbooks(); // Save to persistent storage

    // Log activity with specific ebook name
    _logActivity(
      title: 'Ebook "$title" ditambahkan',
      description: 'Ebook catatan baru berhasil disimpan',
      type: ActivityType.ebookAdded,
    );

    return id;
  }

  bool deleteEbook(String id) {
    final index = _ebooks.indexWhere((ebook) => ebook.id == id);
    if (index != -1) {
      final ebook = _ebooks[index];
      _ebooks.removeAt(index);
      _saveEbooks(); // Save to persistent storage

      // Delete physical file
      _deleteEbookFile(ebook.filePath);

      // Log activity with specific ebook name
      _logActivity(
        title: 'Ebook "${ebook.title}" dihapus',
        description: 'Ebook catatan telah dihapus dari galeri',
        type: ActivityType.ebookDeleted,
      );

      return true;
    }
    return false;
  }

  bool updateEbook({
    required String id,
    String? title,
    List<String>? tags,
    String? description,
  }) {
    final index = _ebooks.indexWhere((ebook) => ebook.id == id);
    if (index != -1) {
      final oldEbook = _ebooks[index];
      final newEbook = oldEbook.copyWith(
        title: title,
        tags: tags,
        description: description,
      );

      _ebooks[index] = newEbook;
      _saveEbooks(); // Save to persistent storage

      // Log activity based on what changed
      if (title != null && title != oldEbook.title) {
        _logActivity(
          title: 'Ebook "${oldEbook.title}" diubah menjadi "$title"',
          description: 'Nama ebook berhasil diperbarui',
          type: ActivityType.ebookEdited,
        );
      } else {
        _logActivity(
          title: 'Ebook "${newEbook.title}" diedit',
          description: 'Detail ebook berhasil diperbarui',
          type: ActivityType.ebookEdited,
        );
      }

      return true;
    }
    return false;
  }

  EbookModel? getEbook(String id) {
    try {
      return _ebooks.firstWhere((ebook) => ebook.id == id);
    } catch (e) {
      return null;
    }
  }

  List<EbookModel> getFilteredEbooks(List<String> selectedTags) {
    if (selectedTags.isEmpty) {
      return ebooks;
    }

    return _ebooks.where((ebook) {
      return ebook.tags.any((tag) => selectedTags.contains(tag));
    }).toList();
  }

  List<String> getUsedEbookTags() {
    final Set<String> usedTags = {};
    for (final ebook in _ebooks) {
      usedTags.addAll(ebook.tags);
    }
    return usedTags.toList()..sort();
  }

  // Delete ebook file from storage
  Future<void> _deleteEbookFile(String filePath) async {
    try {
      final file = File(filePath);
      if (await file.exists()) {
        await file.delete();
      }
    } catch (e) {
      // Ignore deletion errors
    }
  }

  // Update ebook progress tracking
  bool updateEbookProgress(String id, int currentPage) {
    final index = _ebooks.indexWhere((ebook) => ebook.id == id);
    if (index != -1) {
      final oldEbook = _ebooks[index];
      final newEbook = oldEbook.copyWith(
        currentPage: currentPage,
        lastReadAt: DateTime.now(),
      );

      _ebooks[index] = newEbook;
      _saveEbooks(); // Save to persistent storage

      return true;
    }
    return false;
  }

  // Update ebook title by file path
  Future<bool> updateEbookTitle(String filePath, String newTitle) async {
    final index = _ebooks.indexWhere((ebook) => ebook.filePath == filePath);
    if (index != -1) {
      final oldEbook = _ebooks[index];
      final newEbook = oldEbook.copyWith(title: newTitle);
      
      _ebooks[index] = newEbook;
      await _saveEbooks(); // Save to persistent storage
      
      _logActivity(
        title: 'Ebook "${oldEbook.title}" diubah menjadi "$newTitle"',
        description: 'Judul ebook berhasil diperbarui',
        type: ActivityType.ebookEdited,
      );
      
      return true;
    }
    return false;
  }

  // Update ebook total pages
  bool updateEbookTotalPages(String id, int totalPages) {
    final index = _ebooks.indexWhere((ebook) => ebook.id == id);
    if (index != -1) {
      final oldEbook = _ebooks[index];
      final newEbook = oldEbook.copyWith(totalPages: totalPages);

      _ebooks[index] = newEbook;
      _saveEbooks(); // Save to persistent storage

      return true;
    }
    return false;
  }

  // Save ebook file to app directory
  Future<String> saveEbookFile(String sourcePath) async {
    try {
      final appDir = await getApplicationDocumentsDirectory();
      final ebookDir = Directory('${appDir.path}/ebooks');
      if (!await ebookDir.exists()) {
        await ebookDir.create(recursive: true);
      }

      final fileName = '${DateTime.now().millisecondsSinceEpoch}.pdf';
      final targetPath = '${ebookDir.path}/$fileName';

      final sourceFile = File(sourcePath);
      await sourceFile.copy(targetPath);

      return targetPath;
    } catch (e) {
      throw Exception('Failed to save ebook: $e');
    }
  }

  // Photo Page CRUD operations
  String addPhotoPage({
    required String title,
    required List<String> imagePaths,
    required List<String> tags,
    String description = '',
  }) {
    final id = _generateId();
    final photoPage = PhotoPageModel(
      id: id,
      title: title,
      imagePaths: imagePaths,
      createdAt: DateTime.now(),
      tags: tags,
      description: description,
    );

    _photoPages.insert(0, photoPage); // Add to beginning for newest first
    _savePhotoPages(); // Save to persistent storage

    // Log activity with specific photo page name
    _logActivity(
      title: 'Halaman foto "$title" ditambahkan',
      description:
          'Halaman foto dengan ${imagePaths.length} foto berhasil disimpan',
      type: ActivityType.photoPageAdded,
    );

    return id;
  }

  bool deletePhotoPage(String id) {
    final index = _photoPages.indexWhere((photoPage) => photoPage.id == id);
    if (index != -1) {
      final photoPage = _photoPages[index];
      _photoPages.removeAt(index);
      _savePhotoPages(); // Save to persistent storage

      // Log activity with specific photo page name
      _logActivity(
        title: 'Halaman foto "${photoPage.title}" dihapus',
        description: 'Halaman foto catatan telah dihapus dari galeri',
        type: ActivityType.photoPageDeleted,
      );

      return true;
    }
    return false;
  }

  bool updatePhotoPage({
    required String id,
    String? title,
    String? description,
    List<String>? tags,
    List<String>? imagePaths,
  }) {
    final index = _photoPages.indexWhere((photoPage) => photoPage.id == id);
    if (index != -1) {
      final oldPhotoPage = _photoPages[index];
      final newPhotoPage = oldPhotoPage.copyWith(
        title: title,
        description: description,
        tags: tags,
        imagePaths: imagePaths,
      );

      _photoPages[index] = newPhotoPage;
      _savePhotoPages(); // Save to persistent storage

      // Log activity based on what changed
      if (title != null && title != oldPhotoPage.title) {
        _logActivity(
          title: 'Halaman foto "${oldPhotoPage.title}" diubah menjadi "$title"',
          description: 'Nama halaman foto berhasil diperbarui',
          type: ActivityType.photoPageEdited,
        );
      } else {
        _logActivity(
          title: 'Halaman foto "${newPhotoPage.title}" diedit',
          description: 'Detail halaman foto berhasil diperbarui',
          type: ActivityType.photoPageEdited,
        );
      }

      return true;
    }
    return false;
  }

  PhotoPageModel? getPhotoPage(String id) {
    try {
      return _photoPages.firstWhere((photoPage) => photoPage.id == id);
    } catch (e) {
      return null;
    }
  }

  List<PhotoPageModel> getFilteredPhotoPages(List<String> selectedTags) {
    if (selectedTags.isEmpty) {
      return _photoPages;
    }
    return _photoPages.where((photoPage) {
      return photoPage.tags.any((tag) => selectedTags.contains(tag));
    }).toList();
  }

  // Data persistence methods
  Future<void> _savePhotos() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final photosJson =
          _photos
              .map(
                (photo) => {
                  'id': photo.id,
                  'title': photo.title,
                  'imagePath': photo.imagePath,
                  'createdAt': photo.createdAt.millisecondsSinceEpoch,
                  'tags': photo.tags,
                  'description': photo.description,
                },
              )
              .toList();

      await prefs.setString('photos', jsonEncode(photosJson));
    } catch (e) {
      // Handle save error
    }
  }

  Future<void> _loadPhotos() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final photosString = prefs.getString('photos');

      if (photosString != null) {
        final photosJson = jsonDecode(photosString) as List;
        _photos.clear();

        for (final photoData in photosJson) {
          // Check if photo file still exists
          final file = File(photoData['imagePath']);
          if (await file.exists()) {
            final photo = PhotoModel(
              id: photoData['id'],
              title: photoData['title'],
              imagePath: photoData['imagePath'],
              createdAt: DateTime.fromMillisecondsSinceEpoch(
                photoData['createdAt'],
              ),
              tags: List<String>.from(photoData['tags']),
              description: photoData['description'] ?? '',
            );
            _photos.add(photo);
          }
        }
      }
    } catch (e) {
      // Handle load error
    }
  }

  Future<void> _savePhotoPages() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final photoPagesJson =
          _photoPages
              .map(
                (photoPage) => {
                  'id': photoPage.id,
                  'title': photoPage.title,
                  'imagePaths': photoPage.imagePaths,
                  'createdAt': photoPage.createdAt.millisecondsSinceEpoch,
                  'tags': photoPage.tags,
                  'description': photoPage.description,
                },
              )
              .toList();

      await prefs.setString('photoPages', jsonEncode(photoPagesJson));
    } catch (e) {
      // Handle save error
    }
  }

  Future<void> _loadPhotoPages() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final photoPagesString = prefs.getString('photoPages');

      if (photoPagesString != null) {
        final photoPagesJson = jsonDecode(photoPagesString) as List;
        _photoPages.clear();

        for (final photoPageData in photoPagesJson) {
          final photoPage = PhotoPageModel(
            id: photoPageData['id'],
            title: photoPageData['title'],
            imagePaths: List<String>.from(photoPageData['imagePaths']),
            createdAt: DateTime.fromMillisecondsSinceEpoch(
              photoPageData['createdAt'],
            ),
            tags: List<String>.from(photoPageData['tags']),
            description: photoPageData['description'] ?? '',
          );
          _photoPages.add(photoPage);
        }
      }
    } catch (e) {
      // Handle load error
    }
  }

  Future<void> _saveEbooks() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final ebooksJson =
          _ebooks
              .map(
                (ebook) => {
                  'id': ebook.id,
                  'title': ebook.title,
                  'filePath': ebook.filePath,
                  'createdAt': ebook.createdAt.millisecondsSinceEpoch,
                  'tags': ebook.tags,
                  'description': ebook.description,
                  'currentPage': ebook.currentPage,
                  'totalPages': ebook.totalPages,
                  'lastReadAt': ebook.lastReadAt?.millisecondsSinceEpoch,
                  'fileType': ebook.fileType,
                },
              )
              .toList();

      await prefs.setString('ebooks', jsonEncode(ebooksJson));
    } catch (e) {
      // Handle save error
    }
  }

  Future<void> _loadEbooks() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final ebooksString = prefs.getString('ebooks');

      if (ebooksString != null) {
        final ebooksJson = jsonDecode(ebooksString) as List;
        _ebooks.clear();

        for (final ebookData in ebooksJson) {
          // Check if ebook file still exists
          final file = File(ebookData['filePath']);
          if (await file.exists()) {
            final ebook = EbookModel(
              id: ebookData['id'],
              title: ebookData['title'],
              filePath: ebookData['filePath'],
              fileType: ebookData['fileType'] ?? 'pdf',
              createdAt: DateTime.fromMillisecondsSinceEpoch(
                ebookData['createdAt'],
              ),
              tags: List<String>.from(ebookData['tags']),
              description: ebookData['description'] ?? '',
              currentPage: ebookData['currentPage'],
              totalPages: ebookData['totalPages'],
              lastReadAt:
                  ebookData['lastReadAt'] != null
                      ? DateTime.fromMillisecondsSinceEpoch(
                        ebookData['lastReadAt'],
                      )
                      : null,
            );
            _ebooks.add(ebook);
          }
        }
      }
    } catch (e) {
      // Handle load error
    }
  }

  Future<void> _saveActivities() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final activitiesJson =
          _activities
              .map(
                (activity) => {
                  'id': activity.id,
                  'title': activity.title,
                  'description': activity.description,
                  'timestamp': activity.timestamp.millisecondsSinceEpoch,
                  'type': activity.type.toString(),
                },
              )
              .toList();

      await prefs.setString('activities', jsonEncode(activitiesJson));
    } catch (e) {
      // Handle save error
    }
  }

  Future<void> _loadActivities() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final activitiesString = prefs.getString('activities');

      if (activitiesString != null) {
        final activitiesJson = jsonDecode(activitiesString) as List;
        _activities.clear();

        for (final activityData in activitiesJson) {
          final activity = ActivityModel(
            id: activityData['id'],
            title: activityData['title'],
            description: activityData['description'],
            timestamp: DateTime.fromMillisecondsSinceEpoch(
              activityData['timestamp'],
            ),
            type: ActivityType.values.firstWhere(
              (e) => e.toString() == activityData['type'],
              orElse: () => ActivityType.photoAdded,
            ),
          );
          _activities.add(activity);
        }
      }
    } catch (e) {
      // Handle load error
    }
  }

  Future<void> _saveUserProfile() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userProfileJson = {
        'username': _username,
        'profileImagePath': _profileImagePath,
        'readingStreak': _readingStreak,
        'totalReadingTimeMinutes': _totalReadingTimeMinutes,
        'lastReadingDate': _lastReadingDate?.millisecondsSinceEpoch,
      };

      await prefs.setString('userProfile', jsonEncode(userProfileJson));
    } catch (e) {
      // Handle save error
    }
  }

  Future<void> _loadUserProfile() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userProfileString = prefs.getString('userProfile');

      if (userProfileString != null) {
        final userProfileJson = jsonDecode(userProfileString);
        _username = userProfileJson['username'];
        _profileImagePath = userProfileJson['profileImagePath'];
        _readingStreak = userProfileJson['readingStreak'];
        _totalReadingTimeMinutes = userProfileJson['totalReadingTimeMinutes'];
        _lastReadingDate =
            userProfileJson['lastReadingDate'] != null
                ? DateTime.fromMillisecondsSinceEpoch(
                  userProfileJson['lastReadingDate'],
                )
                : null;
      }
    } catch (e) {
      // Handle load error
    }
  }

  Future<void> _saveCustomTags() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('customTags', jsonEncode(_customTags));
    } catch (e) {
      // Handle save error
    }
  }

  Future<void> _loadCustomTags() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final customTagsString = prefs.getString('customTags');

      if (customTagsString != null) {
        _customTags = jsonDecode(customTagsString).cast<String>();
      }
    } catch (e) {
      // Handle load error
    }
  }

  // Remove all data method
  Future<void> removeAllData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Clear all SharedPreferences data
      await prefs.clear();
      
      // Reset all in-memory data to defaults
      _photos.clear();
      _photoPages.clear();
      _ebooks.clear();
      _activities.clear();
      _customTags.clear();
      
      // Reset user profile data
      _username = 'User';
      _profileImagePath = null;
      _readingStreak = 0;
      _totalReadingTimeMinutes = 0;
      
      // Clear app directory files (photos, ebooks, etc.)
      final appDir = await getApplicationDocumentsDirectory();
      final yupireadDir = Directory('${appDir.path}/yupiread');
      
      if (await yupireadDir.exists()) {
        await yupireadDir.delete(recursive: true);
      }
      
      // Reinitialize directory
      await yupireadDir.create(recursive: true);
      
    } catch (e) {
      throw Exception('Failed to remove all data: $e');
    }
  }

  // User profile getters
  String get username => _username;
  String? get profileImagePath => _profileImagePath;
  int get readingStreak => _readingStreak;
  int get totalReadingTimeMinutes => _totalReadingTimeMinutes;
  String get formattedReadingTime {
    if (_totalReadingTimeMinutes < 60) {
      return '$_totalReadingTimeMinutes menit';
    } else {
      final hours = _totalReadingTimeMinutes ~/ 60;
      final minutes = _totalReadingTimeMinutes % 60;
      return '${hours}h ${minutes}m';
    }
  }

  // User profile methods
  Future<void> updateProfile({
    String? username,
    String? profileImagePath,
  }) async {
    if (username != null) _username = username;
    if (profileImagePath != null) _profileImagePath = profileImagePath;
    await _saveUserProfile();
  }

  Future<void> addReadingTime(int minutes) async {
    _totalReadingTimeMinutes += minutes;

    final today = DateTime.now();
    final lastRead = _lastReadingDate;

    if (lastRead == null || !_isSameDay(lastRead, today)) {
      if (lastRead != null && _isConsecutiveDay(lastRead, today)) {
        _readingStreak++;
      } else {
        _readingStreak = 1;
      }
      _lastReadingDate = today;
    }

    await _saveUserProfile();
  }

  bool _isSameDay(DateTime date1, DateTime date2) {
    return date1.year == date2.year &&
        date1.month == date2.month &&
        date1.day == date2.day;
  }

  bool _isConsecutiveDay(DateTime lastDate, DateTime currentDate) {
    final difference = currentDate.difference(lastDate).inDays;
    return difference == 1;
  }

  // Custom tag management
  Future<bool> addCustomTag(String tag) async {
    final trimmedTag = tag.trim();
    if (trimmedTag.isEmpty ||
        _customTags.contains(trimmedTag) ||
        _availableTags.contains(trimmedTag)) {
      return false;
    }

    _customTags.add(trimmedTag);
    await _saveCustomTags();
    return true;
  }

  Future<bool> removeCustomTag(String tag) async {
    if (_customTags.remove(tag)) {
      await _saveCustomTags();
      return true;
    }
    return false;
  }
}
