import 'dart:async';
import 'dart:convert';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:flutter/foundation.dart';
import '../models/photo_model.dart';
import '../models/ebook_model.dart';
import '../models/activity_type.dart';

class DatabaseService {
  static final DatabaseService _instance = DatabaseService._internal();
  factory DatabaseService() => _instance;
  static DatabaseService get instance => _instance;
  DatabaseService._internal();

  static Database? _database;
  static const String _databaseName = 'yupiread.db';
  static const int _databaseVersion = 1;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, _databaseName);

    return await openDatabase(
      path,
      version: _databaseVersion,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    // Photos table
    await db.execute('''
      CREATE TABLE photos (
        id TEXT PRIMARY KEY,
        title TEXT NOT NULL,
        imagePath TEXT NOT NULL,
        createdAt INTEGER NOT NULL,
        tags TEXT NOT NULL,
        description TEXT NOT NULL DEFAULT ''
      )
    ''');

    // Photo pages table
    await db.execute('''
      CREATE TABLE photo_pages (
        id TEXT PRIMARY KEY,
        title TEXT NOT NULL,
        imagePaths TEXT NOT NULL,
        createdAt INTEGER NOT NULL,
        tags TEXT NOT NULL,
        description TEXT NOT NULL DEFAULT ''
      )
    ''');

    // Ebooks table
    await db.execute('''
      CREATE TABLE ebooks (
        id TEXT PRIMARY KEY,
        title TEXT NOT NULL,
        filePath TEXT NOT NULL,
        fileType TEXT NOT NULL DEFAULT 'pdf',
        createdAt INTEGER NOT NULL,
        tags TEXT NOT NULL,
        description TEXT NOT NULL DEFAULT '',
        currentPage INTEGER NOT NULL DEFAULT 0,
        totalPages INTEGER NOT NULL DEFAULT 1,
        lastReadAt INTEGER
      )
    ''');

    // Activities table
    await db.execute('''
      CREATE TABLE activities (
        id TEXT PRIMARY KEY,
        title TEXT NOT NULL,
        description TEXT NOT NULL,
        timestamp INTEGER NOT NULL,
        type TEXT NOT NULL
      )
    ''');

    // User profile table
    await db.execute('''
      CREATE TABLE user_profile (
        id INTEGER PRIMARY KEY CHECK (id = 1),
        username TEXT NOT NULL DEFAULT 'User',
        profileImagePath TEXT,
        readingStreak INTEGER NOT NULL DEFAULT 0,
        totalReadingTimeMinutes INTEGER NOT NULL DEFAULT 0,
        lastReadingDate INTEGER
      )
    ''');

    // Custom tags table
    await db.execute('''
      CREATE TABLE custom_tags (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        tag TEXT NOT NULL UNIQUE
      )
    ''');

    // Create indexes for better performance
    await db.execute('CREATE INDEX idx_photos_created_at ON photos(createdAt DESC)');
    await db.execute('CREATE INDEX idx_photo_pages_created_at ON photo_pages(createdAt DESC)');
    await db.execute('CREATE INDEX idx_ebooks_created_at ON ebooks(createdAt DESC)');
    await db.execute('CREATE INDEX idx_activities_timestamp ON activities(timestamp DESC)');

    // Insert default user profile
    await db.insert('user_profile', {
      'id': 1,
      'username': 'User',
      'readingStreak': 0,
      'totalReadingTimeMinutes': 0,
    });
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    // Handle database schema upgrades here
    if (kDebugMode) {
      print('Upgrading database from version $oldVersion to $newVersion');
    }
  }

  // Photo operations
  Future<String> insertPhoto(PhotoModel photo) async {
    final db = await database;
    await db.insert(
      'photos',
      {
        'id': photo.id,
        'title': photo.title,
        'imagePath': photo.imagePath,
        'createdAt': photo.createdAt.millisecondsSinceEpoch,
        'tags': jsonEncode(photo.tags),
        'description': photo.description,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    return photo.id;
  }

  Future<List<PhotoModel>> getAllPhotos() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'photos',
      orderBy: 'createdAt DESC',
    );

    return List.generate(maps.length, (i) {
      return PhotoModel(
        id: maps[i]['id'],
        title: maps[i]['title'],
        imagePath: maps[i]['imagePath'],
        createdAt: DateTime.fromMillisecondsSinceEpoch(maps[i]['createdAt']),
        tags: List<String>.from(jsonDecode(maps[i]['tags'])),
        description: maps[i]['description'] ?? '',
      );
    });
  }

  Future<PhotoModel?> getPhoto(String id) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'photos',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );

    if (maps.isEmpty) return null;

    final map = maps.first;
    return PhotoModel(
      id: map['id'],
      title: map['title'],
      imagePath: map['imagePath'],
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['createdAt']),
      tags: List<String>.from(jsonDecode(map['tags'])),
      description: map['description'] ?? '',
    );
  }

  Future<void> updatePhoto(PhotoModel photo) async {
    final db = await database;
    await db.update(
      'photos',
      {
        'title': photo.title,
        'tags': jsonEncode(photo.tags),
        'description': photo.description,
      },
      where: 'id = ?',
      whereArgs: [photo.id],
    );
  }

  Future<void> deletePhoto(String id) async {
    final db = await database;
    await db.delete(
      'photos',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // Photo page operations
  Future<String> insertPhotoPage(PhotoPageModel photoPage) async {
    final db = await database;
    await db.insert(
      'photo_pages',
      {
        'id': photoPage.id,
        'title': photoPage.title,
        'imagePaths': jsonEncode(photoPage.imagePaths),
        'createdAt': photoPage.createdAt.millisecondsSinceEpoch,
        'tags': jsonEncode(photoPage.tags),
        'description': photoPage.description,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    return photoPage.id;
  }

  Future<List<PhotoPageModel>> getAllPhotoPages() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'photo_pages',
      orderBy: 'createdAt DESC',
    );

    return List.generate(maps.length, (i) {
      return PhotoPageModel(
        id: maps[i]['id'],
        title: maps[i]['title'],
        imagePaths: List<String>.from(jsonDecode(maps[i]['imagePaths'])),
        createdAt: DateTime.fromMillisecondsSinceEpoch(maps[i]['createdAt']),
        tags: List<String>.from(jsonDecode(maps[i]['tags'])),
        description: maps[i]['description'] ?? '',
      );
    });
  }

  Future<PhotoPageModel?> getPhotoPage(String id) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'photo_pages',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );

    if (maps.isEmpty) return null;

    final map = maps.first;
    return PhotoPageModel(
      id: map['id'],
      title: map['title'],
      imagePaths: List<String>.from(jsonDecode(map['imagePaths'])),
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['createdAt']),
      tags: List<String>.from(jsonDecode(map['tags'])),
      description: map['description'] ?? '',
    );
  }

  Future<void> updatePhotoPage(PhotoPageModel photoPage) async {
    final db = await database;
    await db.update(
      'photo_pages',
      {
        'title': photoPage.title,
        'imagePaths': jsonEncode(photoPage.imagePaths),
        'tags': jsonEncode(photoPage.tags),
        'description': photoPage.description,
      },
      where: 'id = ?',
      whereArgs: [photoPage.id],
    );
  }

  Future<void> deletePhotoPage(String id) async {
    final db = await database;
    await db.delete(
      'photo_pages',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // Ebook operations
  Future<String> insertEbook(EbookModel ebook) async {
    final db = await database;
    await db.insert(
      'ebooks',
      {
        'id': ebook.id,
        'title': ebook.title,
        'filePath': ebook.filePath,
        'fileType': ebook.fileType,
        'createdAt': ebook.createdAt.millisecondsSinceEpoch,
        'tags': jsonEncode(ebook.tags),
        'description': ebook.description,
        'currentPage': ebook.currentPage,
        'totalPages': ebook.totalPages,
        'lastReadAt': ebook.lastReadAt?.millisecondsSinceEpoch,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    return ebook.id;
  }

  Future<List<EbookModel>> getAllEbooks() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'ebooks',
      orderBy: 'createdAt DESC',
    );

    return List.generate(maps.length, (i) {
      return EbookModel(
        id: maps[i]['id'],
        title: maps[i]['title'],
        filePath: maps[i]['filePath'],
        fileType: maps[i]['fileType'] ?? 'pdf',
        createdAt: DateTime.fromMillisecondsSinceEpoch(maps[i]['createdAt']),
        tags: List<String>.from(jsonDecode(maps[i]['tags'])),
        description: maps[i]['description'] ?? '',
        currentPage: maps[i]['currentPage'] ?? 0,
        totalPages: maps[i]['totalPages'] ?? 1,
        lastReadAt: maps[i]['lastReadAt'] != null
            ? DateTime.fromMillisecondsSinceEpoch(maps[i]['lastReadAt'])
            : null,
      );
    });
  }

  Future<EbookModel?> getEbook(String id) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'ebooks',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );

    if (maps.isEmpty) return null;

    final map = maps.first;
    return EbookModel(
      id: map['id'],
      title: map['title'],
      filePath: map['filePath'],
      fileType: map['fileType'] ?? 'pdf',
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['createdAt']),
      tags: List<String>.from(jsonDecode(map['tags'])),
      description: map['description'] ?? '',
      currentPage: map['currentPage'] ?? 0,
      totalPages: map['totalPages'] ?? 1,
      lastReadAt: map['lastReadAt'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['lastReadAt'])
          : null,
    );
  }

  Future<void> updateEbook(EbookModel ebook) async {
    final db = await database;
    await db.update(
      'ebooks',
      {
        'title': ebook.title,
        'tags': jsonEncode(ebook.tags),
        'description': ebook.description,
        'currentPage': ebook.currentPage,
        'totalPages': ebook.totalPages,
        'lastReadAt': ebook.lastReadAt?.millisecondsSinceEpoch,
      },
      where: 'id = ?',
      whereArgs: [ebook.id],
    );
  }

  Future<void> deleteEbook(String id) async {
    final db = await database;
    await db.delete(
      'ebooks',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // Activity operations
  Future<void> insertActivity(ActivityModel activity) async {
    final db = await database;
    await db.insert(
      'activities',
      {
        'id': activity.id,
        'title': activity.title,
        'description': activity.description,
        'timestamp': activity.timestamp.millisecondsSinceEpoch,
        'type': activity.type.toString(),
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );

    // Keep only last 20 activities
    await _cleanupOldActivities();
  }

  Future<void> _cleanupOldActivities() async {
    final db = await database;
    await db.execute('''
      DELETE FROM activities 
      WHERE id NOT IN (
        SELECT id FROM activities 
        ORDER BY timestamp DESC 
        LIMIT 20
      )
    ''');
  }

  Future<List<ActivityModel>> getAllActivities() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'activities',
      orderBy: 'timestamp DESC',
      limit: 20,
    );

    return List.generate(maps.length, (i) {
      return ActivityModel(
        id: maps[i]['id'],
        title: maps[i]['title'],
        description: maps[i]['description'],
        timestamp: DateTime.fromMillisecondsSinceEpoch(maps[i]['timestamp']),
        type: ActivityType.values.firstWhere(
          (e) => e.toString() == maps[i]['type'],
          orElse: () => ActivityType.photoAdded,
        ),
      );
    });
  }

  // User profile operations
  Future<Map<String, dynamic>> getUserProfile() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'user_profile',
      where: 'id = ?',
      whereArgs: [1],
      limit: 1,
    );

    if (maps.isEmpty) {
      // Create default profile if not exists
      await db.insert('user_profile', {
        'id': 1,
        'username': 'User',
        'readingStreak': 0,
        'totalReadingTimeMinutes': 0,
      });
      return {
        'username': 'User',
        'profileImagePath': null,
        'readingStreak': 0,
        'totalReadingTimeMinutes': 0,
        'lastReadingDate': null,
      };
    }

    final map = maps.first;
    return {
      'username': map['username'],
      'profileImagePath': map['profileImagePath'],
      'readingStreak': map['readingStreak'],
      'totalReadingTimeMinutes': map['totalReadingTimeMinutes'],
      'lastReadingDate': map['lastReadingDate'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['lastReadingDate'])
          : null,
    };
  }

  Future<void> updateUserProfile(Map<String, dynamic> profile) async {
    final db = await database;
    final updateData = <String, dynamic>{
      'username': profile['username'],
      'profileImagePath': profile['profileImagePath'],
      'readingStreak': profile['readingStreak'],
      'totalReadingTimeMinutes': profile['totalReadingTimeMinutes'],
    };

    if (profile['lastReadingDate'] != null) {
      updateData['lastReadingDate'] = 
          (profile['lastReadingDate'] as DateTime).millisecondsSinceEpoch;
    }

    await db.update(
      'user_profile',
      updateData,
      where: 'id = ?',
      whereArgs: [1],
    );
  }

  // Custom tags operations
  Future<void> insertCustomTag(String tag) async {
    final db = await database;
    await db.insert(
      'custom_tags',
      {'tag': tag},
      conflictAlgorithm: ConflictAlgorithm.ignore,
    );
  }

  Future<List<String>> getAllCustomTags() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'custom_tags',
      orderBy: 'tag ASC',
    );

    return List.generate(maps.length, (i) => maps[i]['tag'] as String);
  }

  Future<void> deleteCustomTag(String tag) async {
    final db = await database;
    await db.delete(
      'custom_tags',
      where: 'tag = ?',
      whereArgs: [tag],
    );
  }

  // Utility operations
  Future<void> clearAllData() async {
    final db = await database;
    await db.transaction((txn) async {
      await txn.delete('photos');
      await txn.delete('photo_pages');
      await txn.delete('ebooks');
      await txn.delete('activities');
      await txn.delete('custom_tags');
      await txn.update(
        'user_profile',
        {
          'username': 'User',
          'profileImagePath': null,
          'readingStreak': 0,
          'totalReadingTimeMinutes': 0,
          'lastReadingDate': null,
        },
        where: 'id = ?',
        whereArgs: [1],
      );
    });
  }

  Future<void> close() async {
    final db = _database;
    if (db != null) {
      await db.close();
      _database = null;
    }
  }
}
