import 'package:cloud_firestore/cloud_firestore.dart';

class VideoNote {
  final String id;
  final String userId;
  final String videoUrl;
  final String videoTitle;
  final String thumbnail;
  final String notes;
  final List<String> categories; // ← multi-category (was single String)
  final List<String> keyPoints;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isFavorite;
  final int videoDuration;

  VideoNote({
    required this.id,
    required this.userId,
    required this.videoUrl,
    required this.videoTitle,
    required this.thumbnail,
    required this.notes,
    List<String>? categories,
    required this.keyPoints,
    required this.createdAt,
    required this.updatedAt,
    this.isFavorite = false,
    this.videoDuration = 0,
  }) : categories = categories ?? const ['Technology & AI'];

  // ─── Predefined Categories ────────────────────────────────────────────
  static const List<String> predefinedCategories = [
    "Technology & AI",
    "Business & Finance",
    "Education",
    "Science",
    "Productivity & Self-Growth",
    "Health & Wellness",
    "Sports & Fitness",
    "Entertainment",
    "History",
    "Philosophy",
    "Arts & Culture"
  ];

  // Convert to Map for Firestore — field names must match note.txt schema exactly
  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'videoUrl': videoUrl,
      'videoTitle': videoTitle,
      'notes': notes,
      'thumbnail': thumbnail,
      'category': categories,
      'keyPoints': keyPoints,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'isFavorite': isFavorite,
      'videoDuration': videoDuration,
    };
  }

  // Create from Firestore — supports legacy camelCase and snake_case fields
  factory VideoNote.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;

    // Backward-compat for categories
    List<String> categoriesList;
    if (data.containsKey('category')) {
      final catData = data['category'];
      if (catData is List) {
        categoriesList = List<String>.from(catData);
      } else if (catData is String) {
        categoriesList = catData.isNotEmpty ? [catData] : ['Technology & AI'];
      } else {
        categoriesList = ['Technology & AI'];
      }
    } else if (data.containsKey('video_categories') &&
        data['video_categories'] is List) {
      categoriesList = List<String>.from(data['video_categories'] as List);
    } else if (data.containsKey('categories') && data['categories'] is List) {
      categoriesList = List<String>.from(data['categories'] as List);
    } else {
      categoriesList = ['Technology & AI'];
    }

    // Completely remove 'Uncategorized' and ensure there's a valid default
    categoriesList.remove('Uncategorized');
    if (categoriesList.isEmpty) {
      categoriesList.add('Technology & AI');
    }

    // Helper for Timestamp conversion
    DateTime parseDate(String camel) {
      final val = data[camel];
      if (val is Timestamp) {
        return val.toDate();
      }
      if (val is String) {
        return DateTime.tryParse(val) ?? DateTime.now();
      }
      return DateTime.now();
    }

    final videoUrl = data['videoUrl'] ?? data['video_url'] ?? '';
    String thumbnail = data['thumbnail'] ?? '';

    // Reconstruct thumbnail if missing (since we don't store it anymore to match reference)
    if (thumbnail.isEmpty && videoUrl.isNotEmpty) {
      if (videoUrl.contains('youtube.com') || videoUrl.contains('youtu.be')) {
        final regExp = RegExp(r'(?:v=|\/)([0-9A-Za-z_-]{11}).*');
        final match = regExp.firstMatch(videoUrl);
        final videoId = match?.group(1);
        if (videoId != null) {
          thumbnail = 'https://img.youtube.com/vi/$videoId/mqdefault.jpg';
        }
      }
    }

    int videoDuration = data['videoDuration'] ?? data['video_duration'] ?? 0;
    if (videoDuration == 0) {
      final notesContent = data['notes'] ?? data['summary_content'] ?? '';
      final regExp = RegExp(r'(?:المدة|Duration):\s*\**(\d+):(\d+)');
      final match = regExp.firstMatch(notesContent);
      if (match != null) {
        final minutes = int.tryParse(match.group(1) ?? '0') ?? 0;
        final seconds = int.tryParse(match.group(2) ?? '0') ?? 0;
        videoDuration = (minutes * 60) + seconds;
      }
    }

    return VideoNote(
      id: doc.id,
      userId: data['userId'] ?? data['user_id'] ?? '',
      videoUrl: videoUrl,
      videoTitle: data['videoTitle'] ?? data['video_title'] ?? '',
      thumbnail: thumbnail,
      notes: data['notes'] ?? data['summary_content'] ?? '',
      categories: categoriesList,
      keyPoints: List<String>.from(data['keyPoints'] ?? []),
      createdAt: parseDate('createdAt'),
      updatedAt: parseDate('updatedAt'),
      isFavorite: data['isFavorite'] ?? false,
      videoDuration: videoDuration,
    );
  }

  // Copy with method for updates
  VideoNote copyWith({
    String? id,
    String? userId,
    String? videoUrl,
    String? videoTitle,
    String? thumbnail,
    String? notes,
    List<String>? categories,
    List<String>? keyPoints,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isFavorite,
    int? videoDuration,
  }) {
    return VideoNote(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      videoUrl: videoUrl ?? this.videoUrl,
      videoTitle: videoTitle ?? this.videoTitle,
      thumbnail: thumbnail ?? this.thumbnail,
      notes: notes ?? this.notes,
      categories: categories ?? this.categories,
      keyPoints: keyPoints ?? this.keyPoints,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isFavorite: isFavorite ?? this.isFavorite,
      videoDuration: videoDuration ?? this.videoDuration,
    );
  }

  // Getters for analytics mapping
  int get durationMinutes => videoDuration ~/ 60;
  String get category => categories.isNotEmpty ? categories.first : 'Technology & AI';
}
