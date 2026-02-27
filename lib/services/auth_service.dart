import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/app_user.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

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

        await _firestore.collection('users').doc(user.uid).set(newUser.toMap());

        // Cache the user locally
        await cacheUser(newUser);

        return newUser;
      }
      return null;
    } catch (e) {
      print('Error signing up: $e');
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
          .get();
      final appUser = AppUser.fromFirestore(doc);
      await cacheUser(appUser);
      return appUser;
    } catch (e) {
      print('Firestore unavailable, falling back to Auth user data: $e');
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
      print('Error signing out: $e');
      rethrow;
    }
  }

  // Get user data from Firestore
  Future<AppUser?> getUserData(String uid) async {
    try {
      DocumentSnapshot doc = await _firestore
          .collection('users')
          .doc(uid)
          .get();
      if (doc.exists) {
        final appUser = AppUser.fromFirestore(doc);
        await cacheUser(appUser);
        return appUser;
      }
      return null;
    } catch (e) {
      print('Error getting user data: $e');
      // Firestore is offline — return the locally cached user so the app
      // keeps working without a network connection.
      final cached = await getCachedUser();
      if (cached != null) {
        print('Falling back to cached user data.');
        return cached;
      }
      return null;
    }
  }

  // Reset password
  Future<void> resetPassword(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } catch (e) {
      print('Error resetting password: $e');
      rethrow;
    }
  }

  // Cache user data locally
  Future<void> cacheUser(AppUser user) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('cached_user', user.toJson());
    } catch (e) {
      print('Error caching user: $e');
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
      print('Error getting cached user: $e');
    }
    return null;
  }

  // Clear cached user data
  Future<void> clearCachedUser() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('cached_user');
    } catch (e) {
      print('Error clearing cached user: $e');
    }
  }
}
