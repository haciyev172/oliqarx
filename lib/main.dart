import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'screens/login_screen.dart';
import 'screens/worker_home_screen.dart';
import 'screens/admin_home_screen.dart';

void main() async {
  // 1. Flutter mühərrikinin təhlükəsiz başladılması
  WidgetsFlutterBinding.ensureInitialized();

  // 2. Qlobal xəta tutucusu (White Screen qarşısını alır)
  FlutterError.onError = (FlutterErrorDetails details) {
    FlutterError.dumpErrorToConsole(details);
    debugPrint("Flutter Xətası: ${details.exception}");
  };

  bool isFirebaseConnected = false;

  // 3. Təhlükəsiz Firebase Başlatması (Try-Catch & Timeout ilə)
  try {
    // Firebase is optional for demo/offline mode. Add google-services.json
    // and initialize the Firebase project to enable cloud features.
    await Firebase.initializeApp().timeout(const Duration(seconds: 4));
    isFirebaseConnected = true;
    debugPrint("Firebase uğurla qoşuldu.");
  } catch (e) {
    debugPrint("Firebase Options ilə başlama xətası: $e");
    try {
      await Firebase.initializeApp().timeout(const Duration(seconds: 3));
      isFirebaseConnected = true;
    } catch (e2) {
      debugPrint("Firebase Offline rejim aktiv: $e2");
      isFirebaseConnected = false;
    }
  }

  // 4. runApp() mütləq icra edilir, ekran heç vaxt ağ qalmır
  runZonedGuarded(() {
    runApp(OliqarxKlubApp(isFirebaseConnected: isFirebaseConnected));
  }, (error, stack) {
    debugPrint("Zoned Xəta: $error");
  });
}

class OliqarxKlubApp extends StatelessWidget {
  final bool isFirebaseConnected;
  const OliqarxKlubApp({super.key, this.isFirebaseConnected = false});

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
      builder: (context, widget) {
        ErrorWidget.builder = (FlutterErrorDetails errorDetails) {
          return Scaffold(
            backgroundColor: const Color(0xFF0F172A),
            body: Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.shield_outlined, color: Colors.blueAccent, size: 54),
                    const SizedBox(height: 16),
                    const Text(
                      "OLİQARX KLUB",
                      style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      "Tətbiq təhlükəsiz rejimdə işə salındı.",
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.white70, fontSize: 13),
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF2563EB)),
                      onPressed: () {
                        Navigator.of(context).pushReplacement(
                          MaterialPageRoute(builder: (_) => const LoginScreen(isOfflineMode: true)),
                        );
                      },
                      child: const Text("Giriş Ekranına Keç", style: TextStyle(color: Colors.white)),
                    )
                  ],
                ),
              ),
            ),
          );
        };
        return widget ?? const SizedBox.shrink();
      },
      home: AuthGate(isFirebaseConnected: isFirebaseConnected),
    );
  }
}

class AuthGate extends StatelessWidget {
  final bool isFirebaseConnected;
  const AuthGate({super.key, this.isFirebaseConnected = false});

  @override
  Widget build(BuildContext context) {
    if (!isFirebaseConnected || Firebase.apps.isEmpty) {
      return const LoginScreen(isOfflineMode: true);
    }

    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, authSnapshot) {
        if (authSnapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            backgroundColor: Colors.white,
            body: Center(
              child: CircularProgressIndicator(color: Color(0xFF2563EB)),
            ),
          );
        }

        final currentUser = authSnapshot.data;
        if (currentUser == null) {
          return const LoginScreen(isOfflineMode: false);
        }

        return FutureBuilder<DocumentSnapshot>(
          future: FirebaseFirestore.instance.collection('users').doc(currentUser.uid).get(),
          builder: (context, userSnapshot) {
            if (userSnapshot.connectionState == ConnectionState.waiting) {
              return const Scaffold(
                backgroundColor: Colors.white,
                body: Center(
                  child: CircularProgressIndicator(color: Color(0xFF2563EB)),
                ),
              );
            }

            if (userSnapshot.hasError || !userSnapshot.hasData || !userSnapshot.data!.exists) {
              return WorkerHomeScreen(
                user: currentUser,
                userData: {
                  'fullName': currentUser.displayName ?? 'OliqarxKlub Əməkdaşı',
                  'role': 'WORKER',
                  'department': 'Mühafizə & Nəzarət',
                },
              );
            }

            final userData = userSnapshot.data?.data() as Map<String, dynamic>? ?? {};
            final role = userData['role'] ?? 'WORKER';

            if (role == 'ADMIN') {
              return AdminHomeScreen(user: currentUser, userData: userData);
            }
            return WorkerHomeScreen(user: currentUser, userData: userData);
          },
        );
      },
    );
  }
}
