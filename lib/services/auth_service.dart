import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // ── Stream ───────────────────────────────────────────────────────────────────
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  User? get currentUser => _auth.currentUser;

  // ── Register ─────────────────────────────────────────────────────────────────
  /// Creates a new Firebase Auth account, then writes a user document to
  /// Firestore with a default role of 'user'.
  Future<UserCredential> registerWithEmail({
    required String name,
    required String email,
    required String password,
  }) async {
    try {
      print('>>> [AuthService] Attempting registration for: $email');
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Update the display name in Auth
      await credential.user!.updateDisplayName(name);

      // Write user document to Firestore
      await _db.collection('users').doc(credential.user!.uid).set({
        'uid': credential.user!.uid,
        'name': name,
        'email': email,
        'role': 'user', // default — admin manually changes this in Console
        'createdAt': FieldValue.serverTimestamp(),
      });

      print('>>> [AuthService] Registration successful for: $email');
      return credential;
    } on FirebaseAuthException catch (e) {
      print('>>> [AuthService] FirebaseAuthException during registration:');
      print('    Code: ${e.code}');
      print('    Message: ${e.message}');
      rethrow;
    } catch (e) {
      print('>>> [AuthService] Unexpected error during registration: $e');
      rethrow;
    }
  }

  // ── Login ────────────────────────────────────────────────────────────────────
  Future<UserCredential> loginWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      print('>>> [AuthService] Attempting login for: $email');
      final credential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      print('>>> [AuthService] Login successful for: $email');
      return credential;
    } on FirebaseAuthException catch (e) {
      print('>>> [AuthService] FirebaseAuthException during login:');
      print('    Code: ${e.code}');
      print('    Message: ${e.message}');
      rethrow;
    } catch (e) {
      print('>>> [AuthService] Unexpected error during login: $e');
      rethrow;
    }
  }

  // ── Fetch role ───────────────────────────────────────────────────────────────
  /// Reads the user's role from the 'users' collection in Firestore.
  /// Returns 'user' as a safe default if the document doesn't exist yet.
  Future<String> getUserRole(String uid) async {
    try {
      final doc = await _db.collection('users').doc(uid).get();
      if (doc.exists && doc.data()!.containsKey('role')) {
        return doc.data()!['role'] as String;
      }
      return 'user';
    } catch (e) {
      print('>>> [AuthService] Error fetching role for $uid: $e');
      return 'user';
    }
  }

  // ── Logout ───────────────────────────────────────────────────────────────────
  Future<void> signOut() async {
    await _auth.signOut();
  }
}
