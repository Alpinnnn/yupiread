import 'activity_type.dart';

class EbookModel {
  final String id;
  final String title;
  final String filePath;
  final String fileType; // 'pdf' or 'word'
  final int totalPages;
  final int currentPage;
  final DateTime createdAt;
  final DateTime lastReadAt;
  final List<String> tags;
  final String description;

  EbookModel({
    required this.id,
    required this.title,
    required this.filePath,
    this.fileType = 'pdf',
    this.totalPages = 1,
    this.currentPage = 1,
    required this.createdAt,
    DateTime? lastReadAt,
    this.tags = const [],
    this.description = '',
  }) : lastReadAt = lastReadAt ?? DateTime.now();

  double get progress => totalPages > 0 ? currentPage / totalPages : 0.0;

  String get progressPercentage => '${(progress * 100).toInt()}%';

  String get timeAgo {
    final now = DateTime.now();
    final difference = now.difference(lastReadAt);

    if (difference.inMinutes < 1) {
      return 'Baru saja';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes} menit lalu';
    } else if (difference.inHours < 24) {
      return '${difference.inHours} jam lalu';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} hari lalu';
    } else if (difference.inDays < 30) {
      final weeks = (difference.inDays / 7).floor();
      return '$weeks minggu lalu';
    } else {
      final months = (difference.inDays / 30).floor();
      return '$months bulan lalu';
    }
  }

  EbookModel copyWith({
    String? id,
    String? title,
    String? filePath,
    String? fileType,
    int? totalPages,
    int? currentPage,
    DateTime? createdAt,
    DateTime? lastReadAt,
    List<String>? tags,
    String? description,
  }) {
    return EbookModel(
      id: id ?? this.id,
      title: title ?? this.title,
      filePath: filePath ?? this.filePath,
      fileType: fileType ?? this.fileType,
      totalPages: totalPages ?? this.totalPages,
      currentPage: currentPage ?? this.currentPage,
      createdAt: createdAt ?? this.createdAt,
      lastReadAt: lastReadAt ?? this.lastReadAt,
      tags: tags ?? this.tags,
      description: description ?? this.description,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'filePath': filePath,
      'fileType': fileType,
      'totalPages': totalPages,
      'currentPage': currentPage,
      'createdAt': createdAt.toIso8601String(),
      'lastReadAt': lastReadAt.toIso8601String(),
      'tags': tags,
      'description': description,
    };
  }

  factory EbookModel.fromJson(Map<String, dynamic> json) {
    return EbookModel(
      id: json['id'],
      title: json['title'],
      filePath: json['filePath'],
      fileType: json['fileType'] ?? 'pdf',
      totalPages: json['totalPages'] ?? 1,
      currentPage: json['currentPage'] ?? 1,
      createdAt: DateTime.parse(json['createdAt']),
      lastReadAt:
          json['lastReadAt'] != null
              ? DateTime.parse(json['lastReadAt'])
              : DateTime.now(),
      tags: List<String>.from(json['tags'] ?? []),
      description: json['description'] ?? '',
    );
  }
}
