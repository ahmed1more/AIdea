import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/video_note.dart';

class DatabaseService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Create a new video note
  Future<String?> createNote(VideoNote note) async {
    try {
      DocumentReference docRef = await _firestore
          .collection('notes')
          .add(note.toMap())
          .timeout(const Duration(seconds: 10));

      // Update user's notes count
      _firestore
          .collection('users')
          .doc(note.userId)
          .update({'notesCount': FieldValue.increment(1)})
          .catchError((e) => debugPrint('Error updating notes count: $e'));

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
        .where('user_id', isEqualTo: userId)
        .orderBy('created_at', descending: true)
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
        .where('user_id', isEqualTo: userId)
        .where('is_favorite', isEqualTo: true)
        .orderBy('created_at', descending: true)
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
      // Map camelCase to snake_case for updates if needed
      final mappedUpdates = <String, dynamic>{};
      updates.forEach((key, value) {
        if (key == 'videoTitle') {
          mappedUpdates['video_title'] = value;
        } else if (key == 'notes') {
          mappedUpdates['summary_content'] = value;
        } else if (key == 'keyPoints') {
          mappedUpdates['key_points'] = value;
        } else if (key == 'categories') {
          mappedUpdates['video_categories'] = value;
        } else {
          mappedUpdates[key] = value;
        }
      });

      mappedUpdates['updated_at'] = Timestamp.fromDate(DateTime.now());
      await _firestore
          .collection('notes')
          .doc(noteId)
          .update(mappedUpdates)
          .timeout(const Duration(seconds: 10));
      return true;
    } catch (e) {
      debugPrint('Error updating note: $e');
      return false;
    }
  }

  // Toggle favorite status
  Future<bool> toggleFavorite(String noteId, bool currentStatus) async {
    try {
      await _firestore
          .collection('notes')
          .doc(noteId)
          .update({
            'is_favorite': !currentStatus,
            'updated_at': Timestamp.fromDate(DateTime.now()),
          })
          .timeout(const Duration(seconds: 10));
      return true;
    } catch (e) {
      debugPrint('Error toggling favorite: $e');
      return false;
    }
  }

  // Delete a note
  Future<bool> deleteNote(String noteId, String userId) async {
    try {
      await _firestore
          .collection('notes')
          .doc(noteId)
          .delete()
          .timeout(const Duration(seconds: 10));

      // Update user's notes count
      _firestore
          .collection('users')
          .doc(userId)
          .update({'notesCount': FieldValue.increment(-1)})
          .catchError((e) => debugPrint('Error updating notes count: $e'));

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
        .where('user_id', isEqualTo: userId)
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
}
