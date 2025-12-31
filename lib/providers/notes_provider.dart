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
    _databaseService.getUserNotes(userId).listen((notesList) {
      _notes = notesList;
      notifyListeners();
    });
  }

  // Load favorite notes
  void loadFavoriteNotes(String userId) {
    _databaseService.getFavoriteNotes(userId).listen((notesList) {
      _favoriteNotes = notesList;
      notifyListeners();
    });
  }

  // Create a new note
  Future<bool> createNote(VideoNote note) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      String? noteId = await _databaseService.createNote(note);
      _isLoading = false;
      notifyListeners();
      return noteId != null;
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
      bool success = await _databaseService.toggleFavorite(
        noteId,
        currentStatus,
      );
      return success;
    } catch (e) {
      _errorMessage = 'Failed to toggle favorite: $e';
      notifyListeners();
      return false;
    }
  }

  // Delete a note
  Future<bool> deleteNote(String noteId, String userId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      bool success = await _databaseService.deleteNote(noteId, userId);
      _isLoading = false;
      notifyListeners();
      return success;
    } catch (e) {
      _isLoading = false;
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
    _notes = [];
    _favoriteNotes = [];
    _searchQuery = '';
    _errorMessage = null;
    notifyListeners();
  }
}
