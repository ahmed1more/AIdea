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
  }) : categories = categories ?? const ['Uncategorized'];

  // ─── Predefined Categories ────────────────────────────────────────────
  static const List<String> predefinedCategories = [
    'Uncategorized',
    'Education',
    'Technology & AI',
    'Science',
    'Business & Finance',
    'Self-Development',
    'Entertainment',
    'Gaming',
    'Sports & Fitness',
    'Music',
    'Art & Design',
    'Cooking & Food',
    'Travel',
    'Health & Wellness',
    'News & Politics',
    'History',
    'Philosophy',
    'Mathematics',
    'Programming',
    'Psychology',
    'Language Learning',
    'Film & Cinema',
    'Lifestyle',
    'Nature & Environment',
    'DIY & Crafts',
    'Spirituality',
    'Relationships',
    'Law & Society',
    'Economics',
    'Architecture & Design',
  ];

  // Convert to Map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'user_id': userId,
      'video_url': videoUrl,
      'video_title': videoTitle,
      'summary_content': notes,
      'category': categories,
      'createdAt': Timestamp.fromDate(createdAt),
      'isFavorite': isFavorite,
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
        categoriesList = catData.isNotEmpty ? [catData] : ['Uncategorized'];
      } else {
        categoriesList = ['Uncategorized'];
      }
    } else if (data.containsKey('video_categories') &&
        data['video_categories'] is List) {
      categoriesList = List<String>.from(data['video_categories'] as List);
    } else if (data.containsKey('categories') && data['categories'] is List) {
      categoriesList = List<String>.from(data['categories'] as List);
    } else {
      categoriesList = ['Uncategorized'];
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

    final videoUrl = data['video_url'] ?? data['videoUrl'] ?? '';
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

    return VideoNote(
      id: doc.id,
      userId: data['user_id'] ?? data['userId'] ?? '',
      videoUrl: videoUrl,
      videoTitle: data['video_title'] ?? data['videoTitle'] ?? '',
      thumbnail: thumbnail,
      notes: data['summary_content'] ?? data['notes'] ?? '',
      categories: categoriesList,
      keyPoints: List<String>.from(data['keyPoints'] ?? []),
      createdAt: parseDate('createdAt'),
      updatedAt: parseDate('updatedAt'),
      isFavorite: data['isFavorite'] ?? false,
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
    );
  }
}
