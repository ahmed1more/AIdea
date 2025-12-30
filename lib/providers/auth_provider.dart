import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/note_model.dart';

// Auth state provider - listens to Firebase auth changes
final authStateProvider = StreamProvider<User?>((ref) {
  return FirebaseAuth.instance.authStateChanges();
});

// Current user provider
final currentUserProvider = Provider<User?>((ref) {
  return ref.watch(authStateProvider).value;
});

// User profile provider
final userProfileProvider = StreamProvider<UserProfile?>((ref) {
  final user = ref.watch(currentUserProvider);
  if (user == null) return Stream.value(null);

  return FirebaseFirestore.instance
      .collection('users')
      .doc(user.uid)
      .snapshots()
      .map((doc) => doc.exists ? UserProfile.fromFirestore(doc) : null);
});

// Auth service
class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Get current user
  User? get currentUser => _auth.currentUser;

  // Sign in with email and password
  Future<UserCredential> signInWithEmailAndPassword(
    String email,
    String password,
  ) async {
    try {
      return await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    }
  }

  // Register with email and password
  Future<UserCredential> registerWithEmailAndPassword(
    String email,
    String password,
    String name,
  ) async {
    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Create user profile in Firestore
      await _firestore.collection('users').doc(credential.user!.uid).set({
        'email': email,
        'name': name,
        'createdAt': FieldValue.serverTimestamp(),
      });

      // Update display name
      await credential.user!.updateDisplayName(name);

      return credential;
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    }
  }

  // Sign out
  Future<void> signOut() async {
    await _auth.signOut();
  }

  // Reset password
  Future<void> resetPassword(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    }
  }

  // Update profile
  Future<void> updateProfile({String? name, String? photoUrl}) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('No user logged in');

    if (name != null) {
      await user.updateDisplayName(name);
      await _firestore.collection('users').doc(user.uid).update({'name': name});
    }

    if (photoUrl != null) {
      await user.updatePhotoURL(photoUrl);
      await _firestore.collection('users').doc(user.uid).update({
        'avatarUrl': photoUrl,
      });
    }
  }

  // Delete account
  Future<void> deleteAccount() async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('No user logged in');

    // Delete user's notes
    final notesQuery = await _firestore
        .collection('notes')
        .where('userId', isEqualTo: user.uid)
        .get();

    final batch = _firestore.batch();
    for (var doc in notesQuery.docs) {
      batch.delete(doc.reference);
    }
    await batch.commit();

    // Delete user profile
    await _firestore.collection('users').doc(user.uid).delete();

    // Delete auth account
    await user.delete();
  }

  // Handle auth exceptions
  String _handleAuthException(FirebaseAuthException e) {
    switch (e.code) {
      case 'user-not-found':
        return 'No user found with this email.';
      case 'wrong-password':
        return 'Wrong password provided.';
      case 'email-already-in-use':
        return 'An account already exists with this email.';
      case 'weak-password':
        return 'The password is too weak.';
      case 'invalid-email':
        return 'The email address is invalid.';
      case 'user-disabled':
        return 'This account has been disabled.';
      case 'too-many-requests':
        return 'Too many attempts. Please try again later.';
      case 'operation-not-allowed':
        return 'Operation not allowed. Please contact support.';
      default:
        return 'An error occurred: ${e.message}';
    }
  }
}

// Auth service provider
final authServiceProvider = Provider<AuthService>((ref) {
  return AuthService();
});
