import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:path_provider/path_provider.dart';
import '../models/photo_model.dart';

class DataService {
  static final DataService _instance = DataService._internal();
  factory DataService() => _instance;
  DataService._internal();

  final List<PhotoModel> _photos = [];
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

  List<PhotoModel> get photos => List.unmodifiable(_photos);
  List<ActivityModel> get activities => List.unmodifiable(_activities);
  List<String> get availableTags => List.unmodifiable(_availableTags);

  // Initialize data when app starts
  Future<void> initializeData() async {
    await _loadPhotos();
    await _loadActivities();
    if (_activities.isEmpty) {
      initializeSampleData();
    }
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
    for (final photo in _photos) {
      usedTags.addAll(photo.tags);
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
  int get totalEbooks => 8; // Static for now, can be made dynamic later
  String get totalReadingTime => '12h 30m'; // Static for now
  int get activityStreak => 7; // Static for now

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

  // Initialize with some sample activities
  void initializeSampleData() {
    if (_activities.isEmpty) {
      _activities.addAll([
        ActivityModel(
          id: _generateId(),
          title: 'Ebook "Catatan Kuliah" dibaca',
          description: 'Melanjutkan membaca hingga halaman 45',
          timestamp: DateTime.now().subtract(const Duration(hours: 5)),
          type: ActivityType.ebookRead,
        ),
        ActivityModel(
          id: _generateId(),
          title: 'Ebook baru dibuat',
          description: '"Panduan Belajar" berhasil dibuat',
          timestamp: DateTime.now().subtract(const Duration(days: 1)),
          type: ActivityType.ebookCreated,
        ),
      ]);
      _saveActivities();
    }
  }
}
