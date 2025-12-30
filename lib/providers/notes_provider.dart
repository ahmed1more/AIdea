import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/note_model.dart';
import 'auth_provider.dart';

// Firestore instance
final firestoreProvider = Provider<FirebaseFirestore>((ref) {
  return FirebaseFirestore.instance;
});

// Notes stream provider - real-time updates from Firebase
final notesStreamProvider = StreamProvider<List<Note>>((ref) {
  final user = ref.watch(currentUserProvider);
  if (user == null) return Stream.value([]);

  return FirebaseFirestore.instance
      .collection('notes')
      .where('userId', isEqualTo: user.uid)
      .orderBy('updatedAt', descending: true)
      .snapshots()
      .map((snapshot) {
        return snapshot.docs.map((doc) => Note.fromFirestore(doc)).toList();
      });
});

// Single note provider
final noteProvider = StreamProvider.family<Note?, String>((ref, noteId) {
  return FirebaseFirestore.instance
      .collection('notes')
      .doc(noteId)
      .snapshots()
      .map((doc) => doc.exists ? Note.fromFirestore(doc) : null);
});

// Notes service for CRUD operations
class NotesService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Create note
  Future<String> createNote(Note note) async {
    try {
      final docRef = await _firestore.collection('notes').add(note.toMap());
      return docRef.id;
    } catch (e) {
      throw Exception('Failed to create note: $e');
    }
  }

  // Update note
  Future<void> updateNote(Note note) async {
    try {
      await _firestore.collection('notes').doc(note.id).update(note.toMap());
    } catch (e) {
      throw Exception('Failed to update note: $e');
    }
  }

  // Delete note
  Future<void> deleteNote(String noteId) async {
    try {
      await _firestore.collection('notes').doc(noteId).delete();
    } catch (e) {
      throw Exception('Failed to delete note: $e');
    }
  }

  // Toggle favorite
  Future<void> toggleFavorite(String noteId, bool currentState) async {
    try {
      await _firestore.collection('notes').doc(noteId).update({
        'isFavorite': !currentState,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Failed to toggle favorite: $e');
    }
  }

  // Get notes by category
  Stream<List<Note>> getNotesByCategory(String userId, String category) {
    return _firestore
        .collection('notes')
        .where('userId', isEqualTo: userId)
        .where('category', isEqualTo: category)
        .orderBy('updatedAt', descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.map((doc) => Note.fromFirestore(doc)).toList();
        });
  }

  // Get favorite notes
  Stream<List<Note>> getFavoriteNotes(String userId) {
    return _firestore
        .collection('notes')
        .where('userId', isEqualTo: userId)
        .where('isFavorite', isEqualTo: true)
        .orderBy('updatedAt', descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.map((doc) => Note.fromFirestore(doc)).toList();
        });
  }

  // Search notes
  Future<List<Note>> searchNotes(String userId, String query) async {
    try {
      final snapshot = await _firestore
          .collection('notes')
          .where('userId', isEqualTo: userId)
          .get();

      final notes = snapshot.docs
          .map((doc) => Note.fromFirestore(doc))
          .toList();

      // Filter locally for now (Firestore doesn't support full-text search natively)
      return notes.where((note) {
        final lowerQuery = query.toLowerCase();
        return note.title.toLowerCase().contains(lowerQuery) ||
            note.content.toLowerCase().contains(lowerQuery) ||
            note.tags.any((tag) => tag.toLowerCase().contains(lowerQuery));
      }).toList();
    } catch (e) {
      throw Exception('Failed to search notes: $e');
    }
  }

  // Get notes count
  Future<int> getNotesCount(String userId) async {
    try {
      final snapshot = await _firestore
          .collection('notes')
          .where('userId', isEqualTo: userId)
          .count()
          .get();
      return snapshot.count ?? 0;
    } catch (e) {
      return 0;
    }
  }

  // Batch delete notes
  Future<void> deleteMultipleNotes(List<String> noteIds) async {
    try {
      final batch = _firestore.batch();
      for (var id in noteIds) {
        batch.delete(_firestore.collection('notes').doc(id));
      }
      await batch.commit();
    } catch (e) {
      throw Exception('Failed to delete notes: $e');
    }
  }
}

// Notes service provider
final notesServiceProvider = Provider<NotesService>((ref) {
  return NotesService();
});

// Filtered notes provider
final filteredNotesProvider = Provider.family<List<Note>, NotesFilter>((
  ref,
  filter,
) {
  final notesAsync = ref.watch(notesStreamProvider);

  return notesAsync.when(
    data: (notes) {
      return notes.where((note) {
        // Search filter
        if (filter.searchQuery != null && filter.searchQuery!.isNotEmpty) {
          final query = filter.searchQuery!.toLowerCase();
          final matchesTitle = note.title.toLowerCase().contains(query);
          final matchesContent = note.content.toLowerCase().contains(query);
          final matchesTags = note.tags.any(
            (tag) => tag.toLowerCase().contains(query),
          );

          if (!matchesTitle && !matchesContent && !matchesTags) {
            return false;
          }
        }

        // Category filter
        if (filter.category != null && note.category != filter.category) {
          return false;
        }

        // Favorites filter
        if (filter.favoritesOnly && !note.isFavorite) {
          return false;
        }

        return true;
      }).toList();
    },
    loading: () => [],
    error: (_, __) => [],
  );
});

class NotesFilter {
  final String? searchQuery;
  final String? category;
  final bool favoritesOnly;

  NotesFilter({this.searchQuery, this.category, this.favoritesOnly = false});
}

// Statistics provider
final notesStatsProvider = Provider<NotesStats>((ref) {
  final notesAsync = ref.watch(notesStreamProvider);

  return notesAsync.when(
    data: (notes) {
      final categories = <String, int>{};
      var favoritesCount = 0;

      for (var note in notes) {
        if (note.category != null) {
          categories[note.category!] = (categories[note.category!] ?? 0) + 1;
        }
        if (note.isFavorite) {
          favoritesCount++;
        }
      }

      return NotesStats(
        totalNotes: notes.length,
        favoritesCount: favoritesCount,
        categoriesCount: categories,
      );
    },
    loading: () =>
        const NotesStats(totalNotes: 0, favoritesCount: 0, categoriesCount: {}),
    error: (_, __) =>
        const NotesStats(totalNotes: 0, favoritesCount: 0, categoriesCount: {}),
  );
});

class NotesStats {
  final int totalNotes;
  final int favoritesCount;
  final Map<String, int> categoriesCount;

  const NotesStats({
    required this.totalNotes,
    required this.favoritesCount,
    required this.categoriesCount,
  });
}
