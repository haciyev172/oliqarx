import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthService {
  FirebaseAuth get _auth => FirebaseAuth.instance;
  FirebaseFirestore get _db => FirebaseFirestore.instance;

  // Nömrəni standart formata çeviririk.
  String _normalizePhone(String phone) {
    String digits = phone.replaceAll(RegExp(r'\D'), '');

    // +994501234567 və 994501234567 formatları
    if (digits.startsWith('994') && digits.length == 12) {
      digits = digits.substring(3);
    }

    // 0501234567 formatı
    if (digits.startsWith('0') && digits.length == 10) {
      digits = digits.substring(1);
    }

    if (!RegExp(r'^[0-9]{9}$').hasMatch(digits)) {
      throw FirebaseAuthException(
        code: 'invalid-phone-number',
        message: 'Mobil nömrəni düzgün daxil edin.',
      );
    }

    return digits;
  }

  // Firebase üçün daxili giriş identifikatoru.
  String _loginEmail(String phone) {
    return '${_normalizePhone(phone)}@login.oliqarxklub.com';
  }

  Future<UserCredential> signIn({
    required String phoneOrEmail,
    required String password,
  }) async {
    if (Firebase.apps.isEmpty) {
      throw FirebaseAuthException(
        code: 'firebase-not-configured',
        message: 'Firebase konfiqurasiyası yoxdur.',
      );
    }

    final identifier = phoneOrEmail.trim();

    // Köhnə e-poçt hesabları ilə giriş imkanını saxlayırıq.
    final loginEmail = identifier.contains('@')
        ? identifier
        : _loginEmail(identifier);

    return _auth.signInWithEmailAndPassword(
      email: loginEmail,
      password: password,
    );
  }

  Future<UserCredential> register({
    required String email,
    required String password,
    required String fullName,
    String? phone,
    String? department,
  }) async {
    if (Firebase.apps.isEmpty) {
      throw FirebaseAuthException(
        code: 'firebase-not-configured',
        message: 'Firebase konfiqurasiyası yoxdur.',
      );
    }

    if (phone == null || phone.trim().isEmpty) {
      throw FirebaseAuthException(
        code: 'phone-required',
        message: 'Mobil nömrə daxil edilməlidir.',
      );
    }

    final normalizedPhone = _normalizePhone(phone);
    final internalEmail = _loginEmail(normalizedPhone);

    final credential = await _auth.createUserWithEmailAndPassword(
      email: internalEmail,
      password: password,
    );

    final user = credential.user;

    if (user == null) {
      throw FirebaseAuthException(
        code: 'registration-failed',
        message: 'İstifadəçi hesabı yaradıla bilmədi.',
      );
    }

    try {
      await user.updateDisplayName(fullName.trim());

      await _db.collection('users').doc(user.uid).set({
        'fullName': fullName.trim(),
        'phone': normalizedPhone,
        'email': email.trim(),
        'role': 'WORKER',
        'department': department?.trim() ?? '',
        'created_at': DateTime.now().toIso8601String(),
      });
    } catch (_) {
      // Profil yaradıla bilməsə, yarımçıq hesab saxlamırıq.
      try {
        await user.delete();
      } catch (_) {
        // Silinmə alınmasa, xəta yuxarı ötürüləcək.
      }
      rethrow;
    }

    return credential;
  }

  Future<void> signOut() async {
    if (Firebase.apps.isNotEmpty) {
      await _auth.signOut();
    }
  }
}
