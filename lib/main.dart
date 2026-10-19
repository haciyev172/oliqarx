import 'dart:async';

import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'screens/login_screen.dart';
import 'screens/worker_home_screen.dart';
import 'screens/admin_home_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  bool isFirebaseConnected = false;

  try {
    // Azərbaycan dili üçün tarix məlumatlarını yüklə.
    await initializeDateFormatting('az', null);

    // Firebase-i başladırıq.
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
    debugPrint('Başlatma vaxtı bitdi: $e');
  } catch (e, stackTrace) {
    debugPrint('Başlatma xətası: $e');
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
    if (!isFirebaseConnected || Firebase.apps.isEmpty) {
      return const LoginScreen(isOfflineMode: true);
    }

    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, authSnapshot) {
        if (authSnapshot.connectionState ==
            ConnectionState.waiting) {
          return const _LoadingScreen(
            message: 'Giriş vəziyyəti yoxlanılır...',
          );
        }

        if (authSnapshot.hasError) {
          debugPrint(
            'Authentication stream xətası: ${authSnapshot.error}',
          );

          return _ErrorScreen(
            message:
                'Giriş vəziyyətini yoxlamaq mümkün olmadı.',
            onRetry: () async {
              await FirebaseAuth.instance.signOut();
            },
          );
        }

        final currentUser = authSnapshot.data;

        if (currentUser == null) {
          return const LoginScreen(isOfflineMode: false);
        }

        return UserRoleGate(
          key: ValueKey(currentUser.uid),
          user: currentUser,
        );
      },
    );
  }
}

class UserRoleGate extends StatefulWidget {
  final User user;

  const UserRoleGate({
    super.key,
    required this.user,
  });

  @override
  State<UserRoleGate> createState() => _UserRoleGateState();
}

class _UserRoleGateState extends State<UserRoleGate> {
  late Future<DocumentSnapshot<Map<String, dynamic>>>
      _profileFuture;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  void _loadProfile() {
    _profileFuture = FirebaseFirestore.instance
        .collection('users')
        .doc(widget.user.uid)
        .get()
        .timeout(const Duration(seconds: 15));
  }

  void _retry() {
    setState(() {
      _loadProfile();
    });
  }

  Future<void> _signOut() async {
    try {
      await FirebaseAuth.instance.signOut();
    } catch (e) {
      debugPrint('Çıxış xətası: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<
        DocumentSnapshot<Map<String, dynamic>>>(
      future: _profileFuture,
      builder: (context, userSnapshot) {
        if (userSnapshot.connectionState ==
            ConnectionState.waiting) {
          return const _LoadingScreen(
            message: 'İstifadəçi məlumatları yoxlanılır...',
          );
        }

        if (userSnapshot.hasError) {
          debugPrint(
            'Firestore profil oxuma xətası: '
            '${userSnapshot.error}',
          );

          return _ErrorScreen(
            message:
                'İstifadəçi məlumatlarını oxumaq mümkün olmadı.\n'
                'İnternet bağlantısını və Firestore icazələrini '
                'yoxlayın.\n\n'
                'Xəta: ${userSnapshot.error}',
            onRetry: _retry,
          );
        }

        final document = userSnapshot.data;

        if (document == null || !document.exists) {
          return _ErrorScreen(
            message:
                'İstifadəçi profili tapılmadı. '
                'Firestore users kolleksiyasını yoxlayın.',
            onRetry: _signOut,
          );
        }

        final userData = document.data() ?? {};

        final role = (userData['role'] ?? '')
            .toString()
            .trim()
            .toUpperCase();

        debugPrint(
          'Profil oxundu. UID: ${widget.user.uid}, '
          'role: $role',
        );

        if (role == 'ADMIN') {
          return AdminHomeScreen(
            user: widget.user,
            userData: userData,
          );
        }

        if (role == 'WORKER') {
          return WorkerHomeScreen(
            user: widget.user,
            userData: userData,
          );
        }

        return _ErrorScreen(
          message:
              'İstifadəçi rolu düzgün təyin edilməyib.\n'
              'Firestore role sahəsi ADMIN və ya WORKER olmalıdır.',
          onRetry: _signOut,
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
    super.key,
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
                  label: const Text('Yenidən yoxla'),
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
