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
      updates['updatedAt'] = Timestamp.fromDate(DateTime.now());
      await _firestore
          .collection('notes')
          .doc(noteId)
          .update(updates)
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
            'isFavorite': !currentStatus,
            'updatedAt': Timestamp.fromDate(DateTime.now()),
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
}
