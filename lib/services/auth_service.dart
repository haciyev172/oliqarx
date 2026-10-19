import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthService {
  FirebaseAuth get _auth => FirebaseAuth.instance;

  Future<UserCredential> signIn({
    required String phoneOrEmail,
    required String password,
  }) async {
    if (Firebase.apps.isEmpty) {
      throw FirebaseAuthException(
        code: 'firebase-not-configured',
        message: 'Firebase layihəsi qoşulmayıb. Demo girişindən istifadə edin.',
      );
    }

    final identifier = phoneOrEmail.trim();
    if (!identifier.contains('@')) {
      throw FirebaseAuthException(
        code: 'email-required',
        message: 'Firebase girişində e-poçt ünvanı daxil edin.',
      );
    }

    return _auth.signInWithEmailAndPassword(
      email: identifier,
      password: password,
    );
  }

  Future<UserCredential> register({
    required String email,
    required String password,
    required String fullName,
    required String department,
  }) async {
    if (Firebase.apps.isEmpty) {
      throw FirebaseAuthException(
        code: 'firebase-not-configured',
        message: 'Qeydiyyat üçün Firebase layihəsi konfiqurasiya edilməlidir.',
      );
    }
    final credential = await _auth.createUserWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
    await credential.user?.updateDisplayName(fullName.trim());
    final user = credential.user;
    if (user != null) {
      await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
        'fullName': fullName.trim(),
        'email': email.trim(),
        'department': department.trim(),
        'role': 'WORKER',
        'created_at': DateTime.now().toIso8601String(),
      });
    }
    return credential;
  }

  Future<void> signOut() async {
    if (Firebase.apps.isNotEmpty) {
      await _auth.signOut();
    }
  }
}
