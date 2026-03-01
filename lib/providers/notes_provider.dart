import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/video_note.dart';
import '../services/database_service.dart';

class NotesProvider extends ChangeNotifier {
  final DatabaseService _databaseService = DatabaseService();

  List<VideoNote> _notes = [];
  List<VideoNote> _favoriteNotes = [];
  bool _isLoading = false;
  String? _errorMessage;
  String _searchQuery = '';
  StreamSubscription? _notesSubscription;
  StreamSubscription? _favoritesSubscription;

  List<VideoNote> get notes => _searchQuery.isEmpty
      ? _notes
      : _notes
            .where(
              (note) =>
                  note.videoTitle.toLowerCase().contains(
                    _searchQuery.toLowerCase(),
                  ) ||
                  note.notes.toLowerCase().contains(_searchQuery.toLowerCase()),
            )
            .toList();

  List<VideoNote> get favoriteNotes => _favoriteNotes;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  String get searchQuery => _searchQuery;

  // Load user notes
  void loadUserNotes(String userId) {
    _notesSubscription?.cancel();
    _notesSubscription = _databaseService
        .getUserNotes(userId)
        .listen(
          (notesList) {
            _notes = notesList;
            notifyListeners();
          },
          onError: (error) {
            debugPrint('Notes stream error: $error');
          },
        );
  }

  // Load favorite notes
  void loadFavoriteNotes(String userId) {
    _favoritesSubscription?.cancel();
    _favoritesSubscription = _databaseService
        .getFavoriteNotes(userId)
        .listen(
          (notesList) {
            _favoriteNotes = notesList;
            notifyListeners();
          },
          onError: (error) {
            debugPrint('Favorites stream error: $error');
          },
        );
  }

  // Create a new note
  Future<bool> createNote(VideoNote note) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      String? noteId = await _databaseService.createNote(note);
      _isLoading = false;
      if (noteId != null) {
        // We no longer optimistically add the note here.
        // The Firestore snapshots() listener in DatabaseService will
        // automatically detect the new document and update the stream,
        // which will trigger loadUserNotes() and update the list.
        return true;
      }
      notifyListeners();
      return false;
    } catch (e) {
      _isLoading = false;
      _errorMessage = 'Failed to create note: $e';
      notifyListeners();
      return false;
    }
  }

  // Update a note
  Future<bool> updateNote(String noteId, Map<String, dynamic> updates) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      bool success = await _databaseService.updateNote(noteId, updates);
      _isLoading = false;
      if (success) {
        // Optimistically update the note in local lists
        final noteIndex = _notes.indexWhere((n) => n.id == noteId);
        if (noteIndex != -1) {
          final oldNote = _notes[noteIndex];
          _notes[noteIndex] = oldNote.copyWith(
            videoTitle: updates['videoTitle'] as String? ?? oldNote.videoTitle,
            notes: updates['notes'] as String? ?? oldNote.notes,
            keyPoints: updates['keyPoints'] != null
                ? List<String>.from(updates['keyPoints'])
                : oldNote.keyPoints,
            updatedAt: DateTime.now(),
          );
        }
        // Also update in favorites list
        final favIndex = _favoriteNotes.indexWhere((n) => n.id == noteId);
        if (favIndex != -1) {
          final oldNote = _favoriteNotes[favIndex];
          _favoriteNotes[favIndex] = oldNote.copyWith(
            videoTitle: updates['videoTitle'] as String? ?? oldNote.videoTitle,
            notes: updates['notes'] as String? ?? oldNote.notes,
            keyPoints: updates['keyPoints'] != null
                ? List<String>.from(updates['keyPoints'])
                : oldNote.keyPoints,
            updatedAt: DateTime.now(),
          );
        }
      }
      notifyListeners();
      return success;
    } catch (e) {
      _isLoading = false;
      _errorMessage = 'Failed to update note: $e';
      notifyListeners();
      return false;
    }
  }

  // Toggle favorite
  Future<bool> toggleFavorite(String noteId, bool currentStatus) async {
    try {
      // Optimistically update local state immediately
      final noteIndex = _notes.indexWhere((n) => n.id == noteId);
      if (noteIndex != -1) {
        _notes[noteIndex] = _notes[noteIndex].copyWith(
          isFavorite: !currentStatus,
        );
      }
      if (currentStatus) {
        // Was favorite, remove from favorites list
        _favoriteNotes.removeWhere((n) => n.id == noteId);
      } else {
        // Wasn't favorite, add to favorites list
        if (noteIndex != -1) {
          _favoriteNotes.insert(0, _notes[noteIndex]);
        }
      }
      notifyListeners();

      bool success = await _databaseService.toggleFavorite(
        noteId,
        currentStatus,
      );

      if (!success) {
        // Revert on failure
        if (noteIndex != -1) {
          _notes[noteIndex] = _notes[noteIndex].copyWith(
            isFavorite: currentStatus,
          );
        }
        if (!currentStatus) {
          _favoriteNotes.removeWhere((n) => n.id == noteId);
        } else if (noteIndex != -1) {
          _favoriteNotes.insert(0, _notes[noteIndex]);
        }
        notifyListeners();
      }
      return success;
    } catch (e) {
      _errorMessage = 'Failed to toggle favorite: $e';
      notifyListeners();
      return false;
    }
  }

  // Delete a note
  Future<bool> deleteNote(String noteId, String userId) async {
    // Save for rollback
    final removedNote = _notes.firstWhere(
      (n) => n.id == noteId,
      orElse: () => VideoNote(
        id: '',
        userId: '',
        videoUrl: '',
        videoTitle: '',
        thumbnail: '',
        notes: '',
        keyPoints: [],
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
    );
    final removedIndex = _notes.indexWhere((n) => n.id == noteId);

    // Optimistically remove from local lists immediately
    _notes.removeWhere((n) => n.id == noteId);
    _favoriteNotes.removeWhere((n) => n.id == noteId);
    notifyListeners();

    try {
      bool success = await _databaseService.deleteNote(noteId, userId);
      if (!success && removedNote.id.isNotEmpty) {
        // Revert on failure
        if (removedIndex >= 0 && removedIndex <= _notes.length) {
          _notes.insert(removedIndex, removedNote);
        } else {
          _notes.add(removedNote);
        }
        if (removedNote.isFavorite) {
          _favoriteNotes.add(removedNote);
        }
        notifyListeners();
      }
      return success;
    } catch (e) {
      // Revert on error
      if (removedNote.id.isNotEmpty) {
        if (removedIndex >= 0 && removedIndex <= _notes.length) {
          _notes.insert(removedIndex, removedNote);
        } else {
          _notes.add(removedNote);
        }
        if (removedNote.isFavorite) {
          _favoriteNotes.add(removedNote);
        }
      }
      _errorMessage = 'Failed to delete note: $e';
      notifyListeners();
      return false;
    }
  }

  // Set search query
  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  // Clear search
  void clearSearch() {
    _searchQuery = '';
    notifyListeners();
  }

  // Clear error message
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  // Clear all data (on logout)
  void clear() {
    _notesSubscription?.cancel();
    _favoritesSubscription?.cancel();
    _notes = [];
    _favoriteNotes = [];
    _searchQuery = '';
    _errorMessage = null;
    notifyListeners();
  }
}
