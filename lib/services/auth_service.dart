import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:async';
import 'package:logger/logger.dart';
import '../models/app_user.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final Logger logger = Logger();

  // Get current user
  User? get currentUser => _auth.currentUser;

  // Auth state stream
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Sign up with email and password
  Future<AppUser?> signUp({
    required String email,
    required String password,
    required String displayName,
  }) async {
    try {
      UserCredential result = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      User? user = result.user;
      if (user != null) {
        // Update display name
        await user.updateDisplayName(displayName);

        // Create user document in Firestore
        AppUser newUser = AppUser(
          id: user.uid,
          email: email,
          displayName: displayName,
          createdAt: DateTime.now(),
          notesCount: 0,
        );

        // Create user document in Firestore
        try {
          await _firestore
              .collection('users')
              .doc(user.uid)
              .set(newUser.toMap())
              .timeout(const Duration(seconds: 10));
        } catch (e) {
          logger.e('Error creating user document: $e');
          try {
            await user.delete(); // Rollback auth creation
          } catch (deleteError) {
            logger.e('Error deleting orphaned user: $deleteError');
          }
          throw Exception(
            'Failed to setup your database profile. Check Firestore rules or connection. Error: $e',
          );
        }

        // Cache the user locally
        cacheUser(newUser);

        return newUser;
      }
      return null;
    } catch (e) {
      logger.e('Error signing up: $e');
      rethrow;
    }
  }

  // Sign in with email and password
  Future<AppUser?> signIn({
    required String email,
    required String password,
  }) async {
    // Step 1: Authenticate with Firebase Auth (always requires network)
    final UserCredential result = await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );

    final User? user = result.user;
    if (user == null) return null;

    // Step 2: Try to fetch full profile from Firestore.
    // If Firestore is offline, fall back to building a basic AppUser from
    // the Firebase Auth data so the login still succeeds.
    try {
      final DocumentSnapshot doc = await _firestore
          .collection('users')
          .doc(user.uid)
          .get()
          .timeout(const Duration(seconds: 10));

      if (!doc.exists) {
        logger.w('User document missing from Firestore.');
        await _auth.signOut();
        await clearCachedUser();
        throw FirebaseAuthException(
          code: 'user-not-found',
          message: 'Account doesn\'t exist. Please sign up.',
        );
      }

      final appUser = AppUser.fromFirestore(doc);
      await cacheUser(appUser);
      return appUser;
    } catch (e) {
      if (e is FirebaseAuthException) rethrow; // Pass up our custom exception

      if (e is FirebaseException && e.code == 'unavailable') {
        logger.i('Device is offline. Using fallback auth data.');
      } else {
        logger.e('Firestore unreachable: $e');
      }
      // Build a minimal AppUser from what Firebase Auth gives us
      final fallbackUser = AppUser(
        id: user.uid,
        email: user.email ?? email,
        displayName: user.displayName ?? email.split('@').first,
        createdAt: DateTime.now(),
        notesCount: 0,
      );
      await cacheUser(fallbackUser);
      return fallbackUser;
    }
  }

  // Sign out
  Future<void> signOut() async {
    try {
      await _auth.signOut();
      await clearCachedUser();
    } catch (e) {
      logger.e('Error signing out: $e');
      rethrow;
    }
  }

  // Get user data from Firestore
  Future<AppUser?> getUserData(String uid) async {
    try {
      DocumentSnapshot doc = await _firestore
          .collection('users')
          .doc(uid)
          .get()
          .timeout(const Duration(seconds: 10));
      if (doc.exists) {
        final appUser = AppUser.fromFirestore(doc);
        await cacheUser(appUser);
        return appUser;
      } else {
        logger.w('User document missing from Firestore. Signing out.');
        await _auth.signOut();
        await clearCachedUser();
        return null;
      }
    } catch (e) {
      if (e is FirebaseException && e.code == 'unavailable') {
        // Device is offline
      } else {
        logger.e('Error getting user data: $e');
      }
      // Firestore is offline — return the locally cached user so the app
      // keeps working without a network connection.
      final cached = await getCachedUser();
      if (cached != null) {
        logger.i('Falling back to cached user data.');
        return cached;
      }

      // If no cache but we have the current user in Auth, build fallback
      final user = _auth.currentUser;
      if (user != null && user.uid == uid) {
        if (e is FirebaseException && e.code == 'unavailable') {
          logger.i('Device is offline. Using fallback auth data.');
        } else {
          logger.w('Firestore unavailable, falling back to Auth user data: $e');
        }
        final fallbackUser = AppUser(
          id: user.uid,
          email: user.email ?? '',
          displayName:
              user.displayName ?? user.email?.split('@').first ?? 'User',
          createdAt: DateTime.now(),
          notesCount: 0,
        );
        await cacheUser(fallbackUser);
        return fallbackUser;
      }

      return null;
    }
  }

  // Reset password
  Future<void> resetPassword(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } catch (e) {
      logger.e('Error resetting password: $e');
      rethrow;
    }
  }

  // Update display name
  Future<AppUser?> updateDisplayName(String newName) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return null;

      // Update Firebase Auth profile
      await user.updateDisplayName(newName);

      // Update Firestore user document
      await _firestore
          .collection('users')
          .doc(user.uid)
          .update({'displayName': newName})
          .timeout(const Duration(seconds: 10));

      // Return updated user
      final updatedUser = await getUserData(user.uid);
      if (updatedUser != null) {
        await cacheUser(updatedUser);
      }
      return updatedUser;
    } catch (e) {
      logger.e('Error updating display name: $e');
      rethrow;
    }
  }

  // Upload profile photo to Firebase Storage and update user document
  Future<AppUser?> updateProfilePhoto(File imageFile) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return null;

      // Upload to Firebase Storage
      final ref = _storage.ref().child('profile_photos/${user.uid}.jpg');
      final uploadTask = ref.putFile(
        imageFile,
        SettableMetadata(contentType: 'image/jpeg'),
      );
      final snapshot = await uploadTask;
      final downloadUrl = await snapshot.ref.getDownloadURL();

      // Update Firebase Auth photoURL
      await user.updatePhotoURL(downloadUrl);

      // Update Firestore user document
      await _firestore
          .collection('users')
          .doc(user.uid)
          .update({'photoUrl': downloadUrl})
          .timeout(const Duration(seconds: 10));

      // Return updated user
      final updatedUser = await getUserData(user.uid);
      if (updatedUser != null) {
        await cacheUser(updatedUser);
      }
      return updatedUser;
    } catch (e) {
      logger.e('Error updating profile photo: $e');
      rethrow;
    }
  }

  // Remove profile photo
  Future<AppUser?> removeProfilePhoto() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return null;

      // Delete from Firebase Storage (ignore if doesn't exist)
      try {
        final ref = _storage.ref().child('profile_photos/${user.uid}.jpg');
        await ref.delete();
      } catch (_) {
        // File might not exist, that's okay
      }

      // Update Firebase Auth
      await user.updatePhotoURL(null);

      // Update Firestore
      await _firestore
          .collection('users')
          .doc(user.uid)
          .update({'photoUrl': null})
          .timeout(const Duration(seconds: 10));

      final updatedUser = await getUserData(user.uid);
      if (updatedUser != null) {
        await cacheUser(updatedUser);
      }
      return updatedUser;
    } catch (e) {
      logger.e('Error removing profile photo: $e');
      rethrow;
    }
  }

  // Change password (requires re-authentication)
  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null || user.email == null) {
        throw Exception('No authenticated user found.');
      }

      // Re-authenticate
      final credential = EmailAuthProvider.credential(
        email: user.email!,
        password: currentPassword,
      );
      await user.reauthenticateWithCredential(credential);

      // Update password
      await user.updatePassword(newPassword);
    } catch (e) {
      logger.e('Error changing password: $e');
      rethrow;
    }
  }

  // Delete account (requires re-authentication)
  Future<void> deleteAccount(String password) async {
    try {
      final user = _auth.currentUser;
      if (user == null || user.email == null) {
        throw Exception('No authenticated user found.');
      }

      // Re-authenticate
      final credential = EmailAuthProvider.credential(
        email: user.email!,
        password: password,
      );
      await user.reauthenticateWithCredential(credential);

      // Delete profile photo from storage
      try {
        final ref = _storage.ref().child('profile_photos/${user.uid}.jpg');
        await ref.delete();
      } catch (_) {}

      // Delete Firestore user document
      await _firestore.collection('users').doc(user.uid).delete();

      // Delete all user's notes
      final notesSnapshot = await _firestore
          .collection('notes')
          .where('userId', isEqualTo: user.uid)
          .get();
      for (final doc in notesSnapshot.docs) {
        await doc.reference.delete();
      }

      // Delete Firebase Auth account
      await user.delete();
      await clearCachedUser();
    } catch (e) {
      logger.e('Error deleting account: $e');
      rethrow;
    }
  }

  // Cache user data locally
  Future<void> cacheUser(AppUser user) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('cached_user', user.toJson());
    } catch (e) {
      logger.e('Error caching user: $e');
    }
  }

  // Get cached user data
  Future<AppUser?> getCachedUser() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userString = prefs.getString('cached_user');
      if (userString != null) {
        return AppUser.fromJson(userString);
      }
    } catch (e) {
      logger.e('Error getting cached user: $e');
    }
    return null;
  }

  // Clear cached user data
  Future<void> clearCachedUser() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('cached_user');
    } catch (e) {
      logger.e('Error clearing cached user: $e');
    }
  }
}
