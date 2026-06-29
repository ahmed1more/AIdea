import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/video_note.dart';
import '../models/analytics_model.dart';

class DatabaseService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // ─── Notes ────────────────────────────────────────────────────────────────

  // Create a new video note and update analytics
  Future<String?> createNote(VideoNote note) async {
    try {
      DocumentReference docRef = await _firestore
          .collection('notes')
          .add(note.toMap())
          .timeout(const Duration(seconds: 30));

      // FIX: was missing — this is why all analytics stayed at 0
      await updateUserAnalytics(note.userId, note);

      return docRef.id;
    } catch (e) {
      debugPrint('Error creating note: $e');
      return null;
    }
  }

  // Get all notes for a user
  Stream<List<VideoNote>> getUserNotes(String userId) {
    return _firestore
        .collection('notes')
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) => VideoNote.fromFirestore(doc))
              .toList();
        });
  }

  // Get favorite notes for a user
  Stream<List<VideoNote>> getFavoriteNotes(String userId) {
    return _firestore
        .collection('notes')
        .where('userId', isEqualTo: userId)
        .where('isFavorite', isEqualTo: true)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) => VideoNote.fromFirestore(doc))
              .toList();
        });
  }

  // Get a single note by ID
  Future<VideoNote?> getNote(String noteId) async {
    try {
      DocumentSnapshot doc = await _firestore
          .collection('notes')
          .doc(noteId)
          .get();

      if (doc.exists) {
        return VideoNote.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      debugPrint('Error getting note: $e');
      return null;
    }
  }

  // Update a note
  Future<bool> updateNote(String noteId, Map<String, dynamic> updates) async {
    try {
      final mappedUpdates = <String, dynamic>{};
      updates.forEach((key, value) {
        switch (key) {
          case 'videoTitle':
            mappedUpdates['videoTitle'] = value;
            break;
          case 'notes':
            mappedUpdates['notes'] = value;
            break;
          case 'categories':
            mappedUpdates['category'] = value;
            break;
          case 'videoUrl':
            mappedUpdates['videoUrl'] = value;
            break;
          case 'userId':
            mappedUpdates['userId'] = value;
            break;
          default:
            mappedUpdates[key] = value;
        }
      });

      mappedUpdates['updatedAt'] = Timestamp.fromDate(DateTime.now());
      await _firestore
          .collection('notes')
          .doc(noteId)
          .update(mappedUpdates)
          .timeout(const Duration(seconds: 30));
      return true;
    } catch (e) {
      debugPrint('Error updating note: $e');
      return false;
    }
  }

  // Toggle favorite status
  Future<bool> toggleFavorite(String noteId, bool currentStatus) async {
    try {
      final docRef = _firestore.collection('notes').doc(noteId);
      final docSnap = await docRef.get();
      if (!docSnap.exists) return false;
      final data = docSnap.data();
      final userId = data?['userId'] as String?;

      await docRef
          .update({
            'isFavorite': !currentStatus,
            'updatedAt': Timestamp.fromDate(DateTime.now()),
          })
          .timeout(const Duration(seconds: 30));

      if (userId != null) {
        final analyticsRef = _firestore.collection('analytics').doc(userId);
        try {
          await _firestore.runTransaction((transaction) async {
            final analyticsSnap = await transaction.get(analyticsRef);
            if (analyticsSnap.exists) {
              final analytics = AnalyticsModel.fromFirestore(analyticsSnap);
              final newFavCount = currentStatus
                  ? (analytics.favoriteNotesCount > 0
                        ? analytics.favoriteNotesCount - 1
                        : 0)
                  : analytics.favoriteNotesCount + 1;
              transaction.update(analyticsRef, {
                'favoriteNotesCount': newFavCount,
              });
            }
          });
        } catch (e) {
          debugPrint('Error updating favorite analytics: $e');
        }
      }

      return true;
    } catch (e) {
      debugPrint('Error toggling favorite: $e');
      return false;
    }
  }

  // Delete a note
  Future<bool> deleteNote(String noteId, String userId) async {
    try {
      int videoDuration = 0;
      String noteCategory = 'Technology & AI';
      bool isFavorite = false;
      int keyPointsCount = 0;

      try {
        final noteDoc = await _firestore.collection('notes').doc(noteId).get();
        if (noteDoc.exists) {
          final data = noteDoc.data();
          if (data != null) {
            videoDuration =
                data['videoDuration'] ?? data['video_duration'] ?? 0;
            isFavorite = data['isFavorite'] ?? false;

            final keyPointsData = data['keyPoints'] ?? data['key_points'];
            if (keyPointsData is List) {
              keyPointsCount = keyPointsData.length;
            }

            if (videoDuration == 0) {
              final notesContent =
                  data['notes'] ?? data['summary_content'] ?? '';
              final regExp = RegExp(r'(?:المدة|Duration):\s*\**(\d+):(\d+)');
              final match = regExp.firstMatch(notesContent);
              if (match != null) {
                final minutes = int.tryParse(match.group(1) ?? '0') ?? 0;
                final seconds = int.tryParse(match.group(2) ?? '0') ?? 0;
                videoDuration = (minutes * 60) + seconds;
              }
            }

            final catData =
                data['category'] ??
                data['categories'] ??
                data['video_categories'];
            if (catData is List && catData.isNotEmpty) {
              noteCategory = catData.first.toString();
            } else if (catData is String && catData.isNotEmpty) {
              noteCategory = catData;
            }
          }
        }
      } catch (e) {
        debugPrint('Error fetching note for analytics decrement: $e');
      }

      await _firestore
          .collection('notes')
          .doc(noteId)
          .delete()
          .timeout(const Duration(seconds: 30));

      await decrementUserAnalytics(
        userId,
        videoDuration ~/ 60,
        noteCategory,
        isFavorite,
        keyPointsCount,
      );

      return true;
    } catch (e) {
      debugPrint('Error deleting note: $e');
      return false;
    }
  }

  // Search notes by title or content
  Stream<List<VideoNote>> searchNotes(String userId, String query) {
    return _firestore
        .collection('notes')
        .where('userId', isEqualTo: userId)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) => VideoNote.fromFirestore(doc))
              .where(
                (note) =>
                    note.videoTitle.toLowerCase().contains(
                      query.toLowerCase(),
                    ) ||
                    note.notes.toLowerCase().contains(query.toLowerCase()),
              )
              .toList();
        });
  }

  // ─── Analytics ────────────────────────────────────────────────────────────

  // Get user analytics stream
  Stream<AnalyticsModel?> getUserAnalytics(String userId) {
    return _firestore.collection('analytics').doc(userId).snapshots().asyncMap((
      snapshot,
    ) async {
      if (snapshot.exists) {
        return AnalyticsModel.fromFirestore(snapshot);
      }

      // Analytics doc missing — rebuild from existing notes
      final notesSnap = await _firestore
          .collection('notes')
          .where('userId', isEqualTo: userId)
          .get();

      if (notesSnap.docs.isEmpty) return null;

      await initializeUserAnalytics(userId);
      for (final doc in notesSnap.docs) {
        final note = VideoNote.fromFirestore(doc);
        await updateUserAnalytics(userId, note);
      }

      // Return null here — Firestore will emit the real document on the next
      // snapshot tick after the writes above complete.
      return null;
    });
  }

  // Initialize empty analytics document for a new user
  Future<void> initializeUserAnalytics(String userId) async {
    try {
      await _firestore.collection('analytics').doc(userId).set({
        'userId': userId,
        'notesCount': 0,
        'totalMinutes': 0,
        'totalSavedHours': 0.0,
        'favoriteCategory': 'None',
        'currentStreak': 0,
        'thisWeekVideos': 0,
        'thisMonthSavedHours': 0.0,
        'categoryCount': <String, int>{},
        'favoriteNotesCount': 0,
        'totalKeyPoints': 0,
        'lastUpdated': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e) {
      debugPrint('Error initializing analytics: $e');
    }
  }

  // Update user analytics when a new note is saved
  Future<void> updateUserAnalytics(String userId, VideoNote newNote) async {
    final docRef = _firestore.collection('analytics').doc(userId);

    try {
      await _firestore
          .runTransaction((transaction) async {
            final docSnapshot = await transaction.get(docRef);

            AnalyticsModel analytics;
            if (docSnapshot.exists) {
              analytics = AnalyticsModel.fromFirestore(docSnapshot);
            } else {
              analytics = AnalyticsModel(userId: userId);
            }

            final now = DateTime.now();
            final newNotesCount = analytics.notesCount + 1;
            final newTotalMinutes =
                analytics.totalMinutes + newNote.durationMinutes;
            final newTotalSavedHours = newTotalMinutes / 60.0;
            final newFavCount =
                analytics.favoriteNotesCount + (newNote.isFavorite ? 1 : 0);
            final newKeyPoints =
                analytics.totalKeyPoints + newNote.keyPoints.length;

            // Update categoryCount
            final newCategoryCount = Map<String, int>.from(
              analytics.categoryCount,
            );
            final noteCategory = newNote.category;
            newCategoryCount[noteCategory] =
                (newCategoryCount[noteCategory] ?? 0) + 1;

            // Recalculate favoriteCategory
            String newFavoriteCategory = analytics.favoriteCategory;
            if (newCategoryCount.isNotEmpty) {
              String bestCat = newFavoriteCategory;
              int maxCount = -1;
              newCategoryCount.forEach((cat, catCount) {
                if (catCount > maxCount) {
                  maxCount = catCount;
                  bestCat = cat;
                }
              });
              newFavoriteCategory = bestCat;
            }

            // thisMonthSavedHours — reset on new month
            double newThisMonthSavedHours = analytics.thisMonthSavedHours;
            if (analytics.lastUpdated == null ||
                now.year != analytics.lastUpdated!.year ||
                now.month != analytics.lastUpdated!.month) {
              newThisMonthSavedHours = newNote.durationMinutes / 60.0;
            } else {
              newThisMonthSavedHours += newNote.durationMinutes / 60.0;
            }

            // thisWeekVideos — reset on new week
            int newThisWeekVideos = analytics.thisWeekVideos;
            bool weekChanged = false;
            if (analytics.lastUpdated == null) {
              weekChanged = true;
            } else {
              final startOfNowWeek = DateTime(
                now.year,
                now.month,
                now.day,
              ).subtract(Duration(days: now.weekday - 1));
              final startOfLastWeek = DateTime(
                analytics.lastUpdated!.year,
                analytics.lastUpdated!.month,
                analytics.lastUpdated!.day,
              ).subtract(Duration(days: analytics.lastUpdated!.weekday - 1));
              weekChanged = startOfNowWeek != startOfLastWeek;
            }
            newThisWeekVideos = weekChanged ? 1 : newThisWeekVideos + 1;

            // currentStreak
            int newStreak = analytics.currentStreak;
            if (analytics.lastUpdated == null) {
              newStreak = 1;
            } else {
              final lastDate = DateTime(
                analytics.lastUpdated!.year,
                analytics.lastUpdated!.month,
                analytics.lastUpdated!.day,
              );
              final nowDate = DateTime(now.year, now.month, now.day);
              final difference = nowDate.difference(lastDate).inDays;

              if (difference == 1) {
                newStreak += 1;
              } else if (difference > 1) {
                newStreak = 1;
              } else if (difference == 0 && newStreak == 0) {
                newStreak = 1;
              }
            }

            transaction.set(docRef, {
              'notesCount': newNotesCount,
              'totalMinutes': newTotalMinutes,
              'totalSavedHours': newTotalSavedHours,
              'favoriteCategory': newFavoriteCategory,
              'currentStreak': newStreak,
              'thisWeekVideos': newThisWeekVideos,
              'thisMonthSavedHours': newThisMonthSavedHours,
              'categoryCount': newCategoryCount,
              'favoriteNotesCount': newFavCount,
              'totalKeyPoints': newKeyPoints,
              'lastUpdated': FieldValue.serverTimestamp(),
              'userId': userId,
            }, SetOptions(merge: true));
          })
          .timeout(const Duration(seconds: 15));
    } catch (e) {
      debugPrint('Error updating user analytics: $e');
    }
  }

  // Decrement user analytics when a note is deleted
  Future<void> decrementUserAnalytics(
    String userId,
    int durationMinutes,
    String category,
    bool isFavorite,
    int keyPointsCount,
  ) async {
    final docRef = _firestore.collection('analytics').doc(userId);

    try {
      await _firestore
          .runTransaction((transaction) async {
            final docSnapshot = await transaction.get(docRef);
            if (!docSnapshot.exists) return;

            final analytics = AnalyticsModel.fromFirestore(docSnapshot);
            final now = DateTime.now();

            final newNotesCount = analytics.notesCount > 0
                ? analytics.notesCount - 1
                : 0;
            final newTotalMinutes = analytics.totalMinutes >= durationMinutes
                ? analytics.totalMinutes - durationMinutes
                : 0;
            final newTotalSavedHours = newTotalMinutes / 60.0;

            final newFavCount = isFavorite
                ? (analytics.favoriteNotesCount > 0
                      ? analytics.favoriteNotesCount - 1
                      : 0)
                : analytics.favoriteNotesCount;

            final newKeyPoints = analytics.totalKeyPoints >= keyPointsCount
                ? analytics.totalKeyPoints - keyPointsCount
                : 0;

            final newCategoryCount = Map<String, int>.from(
              analytics.categoryCount,
            );
            if (newCategoryCount.containsKey(category)) {
              newCategoryCount[category] =
                  (newCategoryCount[category] ?? 0) - 1;
              if (newCategoryCount[category]! <= 0) {
                newCategoryCount.remove(category);
              }
            }

            String newFavoriteCategory = 'None';
            if (newCategoryCount.isNotEmpty) {
              String bestCat = 'None';
              int maxCount = -1;
              newCategoryCount.forEach((cat, catCount) {
                if (catCount > maxCount) {
                  maxCount = catCount;
                  bestCat = cat;
                }
              });
              newFavoriteCategory = bestCat;
            }

            double newThisMonthSavedHours = analytics.thisMonthSavedHours;
            if (analytics.lastUpdated != null &&
                now.year == analytics.lastUpdated!.year &&
                now.month == analytics.lastUpdated!.month) {
              final decHours = durationMinutes / 60.0;
              newThisMonthSavedHours = newThisMonthSavedHours >= decHours
                  ? newThisMonthSavedHours - decHours
                  : 0.0;
            }

            int newThisWeekVideos = analytics.thisWeekVideos;
            if (analytics.lastUpdated != null) {
              final startOfNowWeek = DateTime(
                now.year,
                now.month,
                now.day,
              ).subtract(Duration(days: now.weekday - 1));
              final startOfLastWeek = DateTime(
                analytics.lastUpdated!.year,
                analytics.lastUpdated!.month,
                analytics.lastUpdated!.day,
              ).subtract(Duration(days: analytics.lastUpdated!.weekday - 1));
              if (startOfNowWeek == startOfLastWeek) {
                newThisWeekVideos = newThisWeekVideos > 0
                    ? newThisWeekVideos - 1
                    : 0;
              }
            }

            transaction.set(docRef, {
              'notesCount': newNotesCount,
              'totalMinutes': newTotalMinutes,
              'totalSavedHours': newTotalSavedHours,
              'favoriteCategory': newFavoriteCategory,
              'thisWeekVideos': newThisWeekVideos,
              'thisMonthSavedHours': newThisMonthSavedHours,
              'categoryCount': newCategoryCount,
              'favoriteNotesCount': newFavCount,
              'totalKeyPoints': newKeyPoints,
              'lastUpdated': FieldValue.serverTimestamp(),
              'userId': userId,
            }, SetOptions(merge: true));
          })
          .timeout(const Duration(seconds: 15));
    } catch (e) {
      debugPrint('Error decrementing analytics: $e');
    }
  }
}
