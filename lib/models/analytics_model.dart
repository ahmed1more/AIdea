import 'package:cloud_firestore/cloud_firestore.dart';

class AnalyticsModel {
  final String userId;
  final int notesCount;
  final int totalMinutes;
  final double totalSavedHours;
  final String favoriteCategory;
  final int currentStreak;
  final int thisWeekVideos;
  final double thisMonthSavedHours;
  final Map<String, int> categoryCount;
  final int favoriteNotesCount;
  final int totalKeyPoints;
  final DateTime? lastUpdated;

  AnalyticsModel({
    required this.userId,
    this.notesCount = 0,
    this.totalMinutes = 0,
    this.totalSavedHours = 0.0,
    this.favoriteCategory = 'None',
    this.currentStreak = 0,
    this.thisWeekVideos = 0,
    this.thisMonthSavedHours = 0.0,
    Map<String, int>? categoryCount,
    this.favoriteNotesCount = 0,
    this.totalKeyPoints = 0,
    this.lastUpdated,
  }) : categoryCount = categoryCount ?? const {};

  Map<String, dynamic> toMap() {
    return {
<<<<<<< HEAD
      'notesCount': notesCount,
=======
      'userId': userId,
      'totalVideos': totalVideos,
>>>>>>> 17b0fa43a279a9158f921fe5e1a944e9829db677
      'totalMinutes': totalMinutes,
      'totalSavedHours': totalSavedHours,
      'favoriteCategory': favoriteCategory,
      'currentStreak': currentStreak,
      'thisWeekVideos': thisWeekVideos,
      'thisMonthSavedHours': thisMonthSavedHours,
      'categoryCount': categoryCount,
      'favoriteNotesCount': favoriteNotesCount,
      'totalKeyPoints': totalKeyPoints,
      'lastUpdated': lastUpdated != null ? Timestamp.fromDate(lastUpdated!) : null,
    };
  }

  factory AnalyticsModel.fromFirestore(DocumentSnapshot doc) {
    final Map<String, dynamic> data = doc.data() as Map<String, dynamic>? ?? {};
    
    // Safely parse categoryCount
    final Map<String, int> categoryCount = {};
    if (data['categoryCount'] is Map) {
      final rawMap = data['categoryCount'] as Map;
      rawMap.forEach((key, value) {
        categoryCount[key.toString()] = (value as num).toInt();
      });
    }

    DateTime? lastUpdatedDate;
    final lastUpdatedVal = data['lastUpdated'];
    if (lastUpdatedVal is Timestamp) {
      lastUpdatedDate = lastUpdatedVal.toDate();
    } else if (lastUpdatedVal is String) {
      lastUpdatedDate = DateTime.tryParse(lastUpdatedVal);
    }

    return AnalyticsModel(
<<<<<<< HEAD
      userId: doc.id,
      notesCount: (data['notesCount'] as num?)?.toInt() ?? (data['totalVideos'] as num?)?.toInt() ?? 0,
=======
      userId: data['userId'] as String? ?? doc.id,
      totalVideos: (data['totalVideos'] as num?)?.toInt() ?? 0,
>>>>>>> 17b0fa43a279a9158f921fe5e1a944e9829db677
      totalMinutes: (data['totalMinutes'] as num?)?.toInt() ?? 0,
      totalSavedHours: (data['totalSavedHours'] as num?)?.toDouble() ?? 0.0,
      favoriteCategory: data['favoriteCategory'] as String? ?? 'None',
      currentStreak: (data['currentStreak'] as num?)?.toInt() ?? 0,
      thisWeekVideos: (data['thisWeekVideos'] as num?)?.toInt() ?? 0,
      thisMonthSavedHours: (data['thisMonthSavedHours'] as num?)?.toDouble() ?? 0.0,
      categoryCount: categoryCount,
      favoriteNotesCount: (data['favoriteNotesCount'] as num?)?.toInt() ?? 0,
      totalKeyPoints: (data['totalKeyPoints'] as num?)?.toInt() ?? 0,
      lastUpdated: lastUpdatedDate,
    );
  }
}
