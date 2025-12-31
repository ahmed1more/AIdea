import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/video_note.dart';

class DatabaseService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Create a new video note
  Future<String?> createNote(VideoNote note) async {
    try {
      DocumentReference docRef = await _firestore
          .collection('notes')
          .add(note.toMap());

      // Update user's notes count
      await _firestore.collection('users').doc(note.userId).update({
        'notesCount': FieldValue.increment(1),
      });

      return docRef.id;
    } catch (e) {
      print('Error creating note: $e');
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
      print('Error getting note: $e');
      return null;
    }
  }

  // Update a note
  Future<bool> updateNote(String noteId, Map<String, dynamic> updates) async {
    try {
      updates['updatedAt'] = Timestamp.fromDate(DateTime.now());
      await _firestore.collection('notes').doc(noteId).update(updates);
      return true;
    } catch (e) {
      print('Error updating note: $e');
      return false;
    }
  }

  // Toggle favorite status
  Future<bool> toggleFavorite(String noteId, bool currentStatus) async {
    try {
      await _firestore.collection('notes').doc(noteId).update({
        'isFavorite': !currentStatus,
        'updatedAt': Timestamp.fromDate(DateTime.now()),
      });
      return true;
    } catch (e) {
      print('Error toggling favorite: $e');
      return false;
    }
  }

  // Delete a note
  Future<bool> deleteNote(String noteId, String userId) async {
    try {
      await _firestore.collection('notes').doc(noteId).delete();

      // Update user's notes count
      await _firestore.collection('users').doc(userId).update({
        'notesCount': FieldValue.increment(-1),
      });

      return true;
    } catch (e) {
      print('Error deleting note: $e');
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
