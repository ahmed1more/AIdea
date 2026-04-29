import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:google_sign_in/google_sign_in.dart';

import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/app_user.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn.instance;


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
          debugPrint('Error creating user document: $e');
          try {
            await user.delete(); // Rollback auth creation
          } catch (deleteError) {
            debugPrint('Error deleting orphaned user: $deleteError');
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
      debugPrint('Error signing up: $e');
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
        debugPrint('User document missing from Firestore.');
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
        debugPrint('Device is offline. Using fallback auth data.');
      } else {
        debugPrint('Firestore unreachable: $e');
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

  // ─── Social Sign-In: Google ─────────────────────────────────────
  Future<AppUser?> signInWithGoogle() async {
    try {
      UserCredential result;

      if (kIsWeb) {
        // Firebase Auth handles Web perfectly with popup
        final GoogleAuthProvider googleProvider = GoogleAuthProvider();
        googleProvider.addScope('email');
        result = await _auth.signInWithPopup(googleProvider);
      } else {
        // Native mobile uses the google_sign_in plugin
        final GoogleSignInAccount googleUser = await _googleSignIn.authenticate();

        final GoogleSignInAuthentication googleAuth = googleUser.authentication;
        final credential = GoogleAuthProvider.credential(
          idToken: googleAuth.idToken,
        );

        result = await _auth.signInWithCredential(credential);
      }

      return _handleSocialSignIn(result, 'google');
    } catch (e) {
      debugPrint('Error signing in with Google: $e');
      rethrow;
    }
  }



  // Helper method for social sign ins
  Future<AppUser?> _handleSocialSignIn(
      UserCredential result, String provider) async {
    final User? user = result.user;
    if (user == null) return null;

    try {
      // Check if user exists in Firestore
      final DocumentSnapshot doc =
          await _firestore.collection('users').doc(user.uid).get();

      if (doc.exists) {
        final appUser = AppUser.fromFirestore(doc);
        await cacheUser(appUser);
        return appUser;
      } else {
        // Create new user in Firestore if they don't exist
        final newUser = AppUser(
          id: user.uid,
          email: user.email ?? '',
          displayName: user.displayName ?? 'AIdea User',
          photoUrl: user.photoURL,
          createdAt: DateTime.now(),
          notesCount: 0,
        );

        await _firestore.collection('users').doc(user.uid).set({
          ...newUser.toMap(),
          'provider': provider,
        });
        await cacheUser(newUser);
        return newUser;
      }
    } catch (e) {
      debugPrint('Error fetching/creating user doc after social signin: $e');
      // Return a basic AppUser object even if Firestore fails
      final fallbackUser = AppUser(
        id: user.uid,
        email: user.email ?? '',
        displayName: user.displayName ?? 'AIdea User',
        photoUrl: user.photoURL,
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
      if (!kIsWeb) {
        // Sign out from social providers on native platforms
        try {
          await _googleSignIn.signOut();
        } catch (_) {
          // May fail if not signed in with Google, ignore
        }

      }
      
      // Clear Firebase session
      await _auth.signOut();
      await clearCachedUser();
    } catch (e) {
      debugPrint('Error signing out: $e');
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
        debugPrint('User document missing from Firestore. Signing out.');
        await _auth.signOut();
        await clearCachedUser();
        return null;
      }
    } catch (e) {
      if (e is FirebaseException && e.code == 'unavailable') {
        // Device is offline
      } else {
        debugPrint('Error getting user data: $e');
      }
      // Firestore is offline — return the locally cached user so the app
      // keeps working without a network connection.
      final cached = await getCachedUser();
      if (cached != null) {
        debugPrint('Falling back to cached user data.');
        return cached;
      }

      // If no cache but we have the current user in Auth, build fallback
      final user = _auth.currentUser;
      if (user != null && user.uid == uid) {
        if (e is FirebaseException && e.code == 'unavailable') {
          debugPrint('Device is offline. Using fallback auth data.');
        } else {
          debugPrint('Firestore unavailable, falling back to Auth user data: $e');
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
      debugPrint('Error resetting password: $e');
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
      debugPrint('Error updating display name: $e');
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
      final uploadTask = ref.putFile(imageFile);
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
      debugPrint('Error updating profile photo: $e');
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
      debugPrint('Error removing profile photo: $e');
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
      debugPrint('Error changing password: $e');
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
      debugPrint('Error deleting account: $e');
      rethrow;
    }
  }

  // Cache user data locally
  Future<void> cacheUser(AppUser user) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('cached_user', user.toJson());
    } catch (e) {
      debugPrint('Error caching user: $e');
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
      debugPrint('Error getting cached user: $e');
    }
    return null;
  }

  // Clear cached user data
  Future<void> clearCachedUser() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('cached_user');
    } catch (e) {
      debugPrint('Error clearing cached user: $e');
    }
  }
}
