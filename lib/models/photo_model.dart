import 'activity_type.dart';

class PhotoPageModel {
  final String id;
  final String title;
  final String description;
  final List<String> imagePaths;
  final DateTime createdAt;
  final List<String> tags;

  PhotoPageModel({
    required this.id,
    required this.title,
    required this.imagePaths,
    required this.createdAt,
    required this.tags,
    this.description = '',
  });

  PhotoPageModel copyWith({
    String? id,
    String? title,
    String? description,
    List<String>? imagePaths,
    DateTime? createdAt,
    List<String>? tags,
  }) {
    return PhotoPageModel(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      imagePaths: imagePaths ?? this.imagePaths,
      createdAt: createdAt ?? this.createdAt,
      tags: tags ?? this.tags,
    );
  }

  String get timeAgo {
    final now = DateTime.now();
    final difference = now.difference(createdAt);

    if (difference.inDays > 30) {
      return '${(difference.inDays / 30).floor()} bulan lalu';
    } else if (difference.inDays > 7) {
      return '${(difference.inDays / 7).floor()} minggu lalu';
    } else if (difference.inDays > 0) {
      return '${difference.inDays} hari lalu';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} jam lalu';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} menit lalu';
    } else {
      return 'Baru saja';
    }
  }

  String get coverImagePath => imagePaths.isNotEmpty ? imagePaths.first : '';

  int get photoCount => imagePaths.length;
}

class PhotoModel {
  final String id;
  final String title;
  final String imagePath;
  final DateTime createdAt;
  final List<String> tags;
  final String description;

  PhotoModel({
    required this.id,
    required this.title,
    required this.imagePath,
    required this.createdAt,
    required this.tags,
    this.description = '',
  });

  PhotoModel copyWith({
    String? id,
    String? title,
    String? imagePath,
    DateTime? createdAt,
    List<String>? tags,
    String? description,
  }) {
    return PhotoModel(
      id: id ?? this.id,
      title: title ?? this.title,
      imagePath: imagePath ?? this.imagePath,
      createdAt: createdAt ?? this.createdAt,
      tags: tags ?? this.tags,
      description: description ?? this.description,
    );
  }

  String get timeAgo {
    final now = DateTime.now();
    final difference = now.difference(createdAt);

    if (difference.inDays > 30) {
      return '${(difference.inDays / 30).floor()} bulan lalu';
    } else if (difference.inDays > 7) {
      return '${(difference.inDays / 7).floor()} minggu lalu';
    } else if (difference.inDays > 0) {
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

class ActivityModel {
  final String id;
  final String title;
  final String description;
  final DateTime timestamp;
  final ActivityType type;

  ActivityModel({
    required this.id,
    required this.title,
    required this.description,
    required this.timestamp,
    required this.type,
  });

  String get timeAgo {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

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

extension ActivityTypeExtension on ActivityType {
  String get icon {
    switch (this) {
      case ActivityType.photoAdded:
        return 'photo_camera';
      case ActivityType.photoDeleted:
        return 'delete';
      case ActivityType.photoEdited:
        return 'edit';
      case ActivityType.photoViewed:
        return 'visibility';
      case ActivityType.photoPageAdded:
        return 'collections';
      case ActivityType.photoPageDeleted:
        return 'delete_sweep';
      case ActivityType.photoPageEdited:
        return 'edit_note';
      case ActivityType.ebookRead:
        return 'menu_book';
      case ActivityType.ebookCreated:
        return 'add_circle';
      case ActivityType.ebookAdded:
        return 'add_circle';
      case ActivityType.ebookCompleted:
        return 'check_circle';
      case ActivityType.ebookDeleted:
        return 'delete';
      case ActivityType.ebookEdited:
        return 'edit';
    }
  }

  int get colorValue {
    switch (this) {
      case ActivityType.photoAdded:
        return 0xFF3B82F6;
      case ActivityType.photoDeleted:
        return 0xFFEF4444;
      case ActivityType.photoEdited:
        return 0xFFF59E0B;
      case ActivityType.photoViewed:
        return 0xFF06B6D4;
      case ActivityType.photoPageAdded:
        return 0xFF8B5CF6;
      case ActivityType.photoPageDeleted:
        return 0xFFEF4444;
      case ActivityType.photoPageEdited:
        return 0xFFF59E0B;
      case ActivityType.ebookRead:
        return 0xFF10B981;
      case ActivityType.ebookCreated:
        return 0xFF8B5CF6;
      case ActivityType.ebookAdded:
        return 0xFF8B5CF6;
      case ActivityType.ebookCompleted:
        return 0xFF10B981;
      case ActivityType.ebookDeleted:
        return 0xFFEF4444;
      case ActivityType.ebookEdited:
        return 0xFFF59E0B;
    }
  }
}
