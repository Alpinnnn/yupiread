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

enum ActivityType {
  photoAdded,
  photoDeleted,
  photoEdited,
  ebookRead,
  ebookCreated,
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
      case ActivityType.ebookRead:
        return 'menu_book';
      case ActivityType.ebookCreated:
        return 'add_circle';
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
      case ActivityType.ebookRead:
        return 0xFF10B981;
      case ActivityType.ebookCreated:
        return 0xFF8B5CF6;
    }
  }
}
