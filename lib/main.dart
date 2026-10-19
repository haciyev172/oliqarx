import 'dart:async';

import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'screens/login_screen.dart';
import 'screens/worker_home_screen.dart';
import 'screens/admin_home_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  bool isFirebaseConnected = false;

  try {
    await Firebase.initializeApp().timeout(
      const Duration(seconds: 15),
    );

    isFirebaseConnected = Firebase.apps.isNotEmpty;

    debugPrint(
      isFirebaseConnected
          ? 'Firebase uğurla başladıldı.'
          : 'Firebase başladılmadı.',
    );
  } on TimeoutException catch (e) {
    debugPrint('Firebase başlatma vaxtı bitdi: $e');
  } catch (e, stackTrace) {
    debugPrint('Firebase başlatma xətası: $e');
    debugPrintStack(stackTrace: stackTrace);
  }

  runApp(
    OliqarxKlubApp(
      isFirebaseConnected: isFirebaseConnected,
    ),
  );
}

class OliqarxKlubApp extends StatelessWidget {
  final bool isFirebaseConnected;

  const OliqarxKlubApp({
    super.key,
    required this.isFirebaseConnected,
  });

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'OLİQARX KLUB',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF2563EB),
          brightness: Brightness.light,
        ),
        fontFamily: 'Roboto',
      ),
      builder: (context, child) {
        return child ?? const SizedBox.shrink();
      },
      home: AuthGate(
        isFirebaseConnected: isFirebaseConnected,
      ),
    );
  }
}

class AuthGate extends StatelessWidget {
  final bool isFirebaseConnected;

  const AuthGate({
    super.key,
    required this.isFirebaseConnected,
  });

  @override
  Widget build(BuildContext context) {
    // Firebase aktiv deyilsə, giriş ekranını aç.
    if (!isFirebaseConnected || Firebase.apps.isEmpty) {
      return const LoginScreen(isOfflineMode: true);
    }

    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, authSnapshot) {
        if (authSnapshot.connectionState == ConnectionState.waiting) {
          return const _LoadingScreen(
            message: 'Giriş vəziyyəti yoxlanılır...',
          );
        }

        if (authSnapshot.hasError) {
          return _ErrorScreen(
            message: 'Giriş məlumatları oxunmadı.',
            onRetry: () {
              _rebuildApp(context);
            },
          );
        }

        final User? currentUser = authSnapshot.data;

        // İstifadəçi daxil olmayıb.
        if (currentUser == null) {
          return const LoginScreen(isOfflineMode: false);
        }

        // Daxil olmuş istifadəçinin rolunu yoxla.
        return UserRoleGate(user: currentUser);
      },
    );
  }

  void _rebuildApp(BuildContext context) {
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(
        builder: (_) => const LoginScreen(isOfflineMode: false),
      ),
      (route) => false,
    );
  }
}

class UserRoleGate extends StatelessWidget {
  final User user;

  const UserRoleGate({
    super.key,
    required this.user,
  });

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      future: FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get()
          .timeout(const Duration(seconds: 15)),
      builder: (context, userSnapshot) {
        if (userSnapshot.connectionState == ConnectionState.waiting) {
          return const _LoadingScreen(
            message: 'İstifadəçi məlumatları yoxlanılır...',
          );
        }

        // Firestore xətasında istifadəçiyə avtomatik rol vermə.
        if (userSnapshot.hasError) {
          return _ErrorScreen(
            message:
                'İstifadəçi məlumatlarını oxumaq mümkün olmadı. '
                'İnternet bağlantısını və Firestore icazələrini yoxlayın.',
            onRetry: () {
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(
                  builder: (_) =>
                      const LoginScreen(isOfflineMode: false),
                ),
                (route) => false,
              );
            },
          );
        }

        final document = userSnapshot.data;

        // Firestore sənədi mövcud deyilsə, girişə icazə vermə.
        if (document == null || !document.exists) {
          return _ErrorScreen(
            message:
                'İstifadəçi profili tapılmadı. '
                'Administrator Firestore-da profil yaratmalıdır.',
            onRetry: () async {
              await FirebaseAuth.instance.signOut();

              if (!context.mounted) return;

              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(
                  builder: (_) =>
                      const LoginScreen(isOfflineMode: false),
                ),
                (route) => false,
              );
            },
          );
        }

        final Map<String, dynamic> userData = document.data() ?? {};

        final String role = (userData['role'] ?? '')
            .toString()
            .trim()
            .toUpperCase();

        // Naməlum və ya səhv rol təhlükəsiz şəkildə rədd edilir.
        if (role == 'ADMIN') {
          return AdminHomeScreen(
            user: user,
            userData: userData,
          );
        }

        if (role == 'WORKER') {
          return WorkerHomeScreen(
            user: user,
            userData: userData,
          );
        }

        return _ErrorScreen(
          message:
              'İstifadəçi rolu düzgün təyin edilməyib. '
              'Firestore-da role sahəsi ADMIN və ya WORKER olmalıdır.',
          onRetry: () async {
            await FirebaseAuth.instance.signOut();

            if (!context.mounted) return;

            Navigator.of(context).pushAndRemoveUntil(
              MaterialPageRoute(
                builder: (_) =>
                    const LoginScreen(isOfflineMode: false),
              ),
              (route) => false,
            );
          },
        );
      },
    );
  }
}

class _LoadingScreen extends StatelessWidget {
  final String message;

  const _LoadingScreen({
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(
                color: Color(0xFF2563EB),
              ),
              const SizedBox(height: 20),
              Text(
                message,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 15,
                  color: Color(0xFF334155),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ErrorScreen extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorScreen({
    required this.message,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.error_outline,
                color: Color(0xFFDC2626),
                size: 60,
              ),
              const SizedBox(height: 20),
              const Text(
                'OLİQARX KLUB',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF0F172A),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                message,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 14,
                  color: Color(0xFF475569),
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: onRetry,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Yenidən yoxla / girişə qayıt'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2563EB),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      vertical: 14,
                      horizontal: 16,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
