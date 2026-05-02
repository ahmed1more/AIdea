import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/app_user.dart';
import '../services/auth_service.dart';

class AuthProvider extends ChangeNotifier {
  final AuthService _authService = AuthService();

  AppUser? _user;
  bool _isLoading = false;
  bool _isUploadingPhoto = false;
  String? _errorMessage;
  DateTime? _lastResetEmailSent;

  AppUser? get user => _user;
  bool get isLoading => _isLoading;
  bool get isUploadingPhoto => _isUploadingPhoto;
  String? get errorMessage => _errorMessage;
  bool get isAuthenticated => _user != null;

  int get resetCooldownRemaining {
    if (_lastResetEmailSent == null) return 0;
    final diff = DateTime.now().difference(_lastResetEmailSent!).inMinutes;
    return (10 - diff).clamp(0, 10);
  }

  /// True when a social-login user hasn't filled in gender/birthDate yet.
  bool get needsProfileCompletion =>
      _user != null &&
      (_user!.gender == null || _user!.gender!.isEmpty) &&
      (_user!.birthDate == null || _user!.birthDate!.isEmpty);

  AuthProvider() {
    _initAuth();
  }

  Future<void> _initAuth() async {
    // 1. Try to load cached user first
    _user = await _authService.getCachedUser();
    if (_user != null) {
      notifyListeners();
    }

    // 2. Listen to Firebase auth state changes
    _authService.authStateChanges.listen((User? firebaseUser) async {
      if (firebaseUser != null) {
        _user = await _authService.getUserData(firebaseUser.uid);
        notifyListeners();
      } else {
        _user = null;
        await _authService.clearCachedUser();
        notifyListeners();
      }
    });
  }

  // Sign up
  Future<bool> signUp({
    required String email,
    required String password,
    required String displayName,
    String? gender,
    String? birthDate,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _user = await _authService.signUp(
        email: email,
        password: password,
        displayName: displayName,
        gender: gender,
        birthDate: birthDate,
      );
      _isLoading = false;
      notifyListeners();
      return _user != null;
    } catch (e) {
      _isLoading = false;
      _errorMessage = _getErrorMessage(e);
      notifyListeners();
      return false;
    }
  }

  // Sign in
  Future<bool> signIn({required String email, required String password}) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _user = await _authService.signIn(email: email, password: password);
      _isLoading = false;
      notifyListeners();
      return _user != null;
    } catch (e) {
      _isLoading = false;
      _errorMessage = _getErrorMessage(e);
      notifyListeners();
      return false;
    }
  }

  // Sign in with Google
  Future<bool> signInWithGoogle() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _user = await _authService.signInWithGoogle();
      _isLoading = false;
      notifyListeners();
      return _user != null;
    } catch (e) {
      _isLoading = false;
      _errorMessage = _getErrorMessage(e);
      notifyListeners();
      return false;
    }
  }


  // Sign out
  Future<void> signOut() async {
    _isLoading = true;
    notifyListeners();

    try {
      await _authService.signOut();
      _user = null;
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _errorMessage = _getErrorMessage(e);
      notifyListeners();
    }
  }

  // Reset password
  Future<bool> resetPassword(String email) async {
    final remaining = resetCooldownRemaining;
    if (remaining > 0) {
      _errorMessage =
          'Please wait $remaining minute${remaining > 1 ? 's' : ''} before requesting another reset email.';
      notifyListeners();
      return false;
    }

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _authService.resetPassword(email);
      _lastResetEmailSent = DateTime.now();
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isLoading = false;
      _errorMessage = _getErrorMessage(e);
      notifyListeners();
      return false;
    }
  }

  // Update display name
  Future<bool> updateDisplayName(String newName) async {
    try {
      final updatedUser = await _authService.updateDisplayName(newName);
      if (updatedUser != null) {
        _user = updatedUser;
        notifyListeners();
        return true;
      }
      return false;
    } catch (e) {
      _errorMessage = 'Failed to update profile: $e';
      notifyListeners();
      return false;
    }
  }

  // Update profile photo (mobile — uses dart:io File)
  Future<bool> updateProfilePhoto(File imageFile) async {
    _isUploadingPhoto = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final updatedUser = await _authService.updateProfilePhoto(imageFile);
      if (updatedUser != null) {
        _user = updatedUser;
        _isUploadingPhoto = false;
        notifyListeners();
        return true;
      }
      _isUploadingPhoto = false;
      notifyListeners();
      return false;
    } catch (e) {
      _isUploadingPhoto = false;
      _errorMessage = 'Failed to update photo: ${_getErrorMessage(e)}';
      notifyListeners();
      return false;
    }
  }

  // Update profile photo (web — uses Uint8List bytes)
  Future<bool> updateProfilePhotoBytes(Uint8List imageBytes) async {
    _isUploadingPhoto = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final updatedUser = await _authService.updateProfilePhotoBytes(imageBytes);
      if (updatedUser != null) {
        _user = updatedUser;
        _isUploadingPhoto = false;
        notifyListeners();
        return true;
      }
      _isUploadingPhoto = false;
      notifyListeners();
      return false;
    } catch (e) {
      _isUploadingPhoto = false;
      _errorMessage = 'Failed to update photo: ${_getErrorMessage(e)}';
      notifyListeners();
      return false;
    }
  }

  // Complete profile after social sign-in (gender + birthDate)
  Future<bool> updateProfileCompletion({
    String? gender,
    String? birthDate,
  }) async {
    try {
      final updatedUser = await _authService.updateProfileCompletion(
        gender: gender,
        birthDate: birthDate,
      );
      if (updatedUser != null) {
        _user = updatedUser;
        notifyListeners();
        return true;
      }
      return false;
    } catch (e) {
      _errorMessage = 'Failed to update profile: ${_getErrorMessage(e)}';
      notifyListeners();
      return false;
    }
  }

  // Remove profile photo
  Future<bool> removeProfilePhoto() async {
    _isUploadingPhoto = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final success = await _authService.removeProfilePhoto();
      if (success != null) {
        if (_user != null) {
          _user = _user!.copyWith(photoUrl: '');
        }
        _isUploadingPhoto = false;
        notifyListeners();
        return true;
      }
      _isUploadingPhoto = false;
      notifyListeners();
      return false;
    } catch (e) {
      _isUploadingPhoto = false;
      _errorMessage = 'Failed to remove photo: ${_getErrorMessage(e)}';
      notifyListeners();
      return false;
    }
  }

  // Change password
  Future<bool> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _authService.changePassword(
        currentPassword: currentPassword,
        newPassword: newPassword,
      );
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isLoading = false;
      _errorMessage = _getErrorMessage(e);
      notifyListeners();
      return false;
    }
  }

  // Delete account
  Future<bool> deleteAccount(String password) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _authService.deleteAccount(password);
      _user = null;
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isLoading = false;
      _errorMessage = _getErrorMessage(e);
      notifyListeners();
      return false;
    }
  }

  // Clear error message
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  // Convert Firebase errors to user-friendly messages
  String _getErrorMessage(dynamic error) {
    if (error is FirebaseAuthException) {
      switch (error.code) {
        // Modern Firebase SDK (v9+) consolidated error code
        case 'invalid-credential':
          return 'Invalid email or password. Please try again.';
        // Legacy / still-used codes
        case 'user-not-found':
          return 'No account found with this email.';
        case 'wrong-password':
          return 'Incorrect password. Please try again.';
        case 'email-already-in-use':
          return 'An account already exists with this email.';
        case 'invalid-email':
          return 'The email address is not valid.';
        case 'weak-password':
          return 'The password is too weak (minimum 6 characters).';
        case 'operation-not-allowed':
          return 'Email/password accounts are not enabled.';
        case 'user-disabled':
          return 'This account has been disabled. Contact support.';
        case 'too-many-requests':
          return 'Too many failed attempts. Please wait a moment and try again.';
        case 'network-request-failed':
          return 'No internet connection. Please check your network.';
        case 'requires-recent-login':
          return 'Please sign in again before making this change.';
        case 'account-exists-with-different-credential':
          return 'An account already exists with this email using a different sign-in method.';
        case 'popup-blocked':
          return 'Sign-in popup was blocked. Please allow popups and try again.';
        case 'cancelled-popup-request':
          return 'Sign-in was cancelled. Please try again.';
        case 'credential-already-in-use':
          return 'This credential is already linked to another account.';
        default:
          return error.message ?? 'An error occurred. Please try again.';
      }
    }
    return error.toString();
  }
}
