import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import '../services/auth_service.dart';
import 'register_screen.dart';
import 'worker_home_screen.dart';
import 'admin_home_screen.dart';

class LoginScreen extends StatefulWidget {
  final bool isOfflineMode;
  const LoginScreen({super.key, this.isOfflineMode = false});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _phoneOrEmailController = TextEditingController(text: "50 123 45 67");
  final _passwordController = TextEditingController(text: '123456');
  bool _isLoading = false;
  bool _obscurePassword = true;

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    try {
      if (widget.isOfflineMode || Firebase.apps.isEmpty) {
        await Future.delayed(const Duration(milliseconds: 300));
        final phone = _phoneOrEmailController.text.trim();
        final isAdm = phone.contains('777') || phone.contains('admin');

        if (mounted) {
          if (isAdm) {
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(
                builder: (_) => const AdminHomeScreen(
                  user: null,
                  userData: {
                    'fullName': 'Cənab Administrator',
                    'role': 'ADMIN',
                    'department': 'Rəhbərlik',
                  },
                ),
              ),
            );
          } else {
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(
                builder: (_) => const WorkerHomeScreen(
                  user: null,
                  userData: {
                    'fullName': 'Elmir Məmmədov',
                    'worker_id': 'OLQ-1042',
                    'role': 'WORKER',
                    'department': 'Mühafizə & Nəzarət',
                  },
                ),
              ),
            );
          }
        }
        return;
      }

      await AuthService().signIn(
        phoneOrEmail: _phoneOrEmailController.text.trim(),
        password: _passwordController.text.trim(),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Giriş xətası: ${e.toString()}"),
            backgroundColor: const Color(0xFF1E293B),
            action: SnackBarAction(
              label: "Sınaq Girişi",
              textColor: Colors.amber,
              onPressed: () => _quickLoginAs('WORKER'),
            ),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _quickLoginAs(String role) {
    if (role == 'ADMIN') {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => const AdminHomeScreen(
            user: null,
            userData: {
              'fullName': 'Cənab Administrator',
              'role': 'ADMIN',
              'department': 'Rəhbərlik',
            },
          ),
        ),
      );
    } else {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => const WorkerHomeScreen(
            user: null,
            userData: {
              'fullName': 'Elmir Məmmədov',
              'worker_id': 'OLQ-1042',
              'role': 'WORKER',
              'department': 'Mühafizə & Nəzarət',
            },
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 28),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Center(
                    child: Container(
                      width: 72,
                      height: 72,
                      decoration: BoxDecoration(
                        color: const Color(0xFF2563EB).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Icon(Icons.shield_outlined, size: 38, color: Color(0xFF2563EB)),
                    ),
                  ),
                  const SizedBox(height: 14),
                  const Text(
                    "OLİQARX KLUB",
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    "Növbə & Davamiyyət Sistemi (PDKS)",
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 13, color: Color(0xFF64748B)),
                  ),
                  const SizedBox(height: 24),
                  TextFormField(
                    controller: _phoneOrEmailController,
                    keyboardType: TextInputType.phone,
                    decoration: InputDecoration(
                      labelText: "Mobil Nömrə",
                      prefixText: "+994 ",
                      hintText: "50 123 45 67",
                      prefixIcon: const Icon(Icons.phone_android_outlined),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    validator: (v) => (v == null || v.isEmpty) ? "Mobil nömrənizi daxil edin" : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _passwordController,
                    obscureText: _obscurePassword,
                    decoration: InputDecoration(
                      labelText: "Şifrə",
                      prefixIcon: const Icon(Icons.lock_outline),
                      suffixIcon: IconButton(
                        icon: Icon(_obscurePassword ? Icons.visibility_off : Icons.visibility),
                        onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                      ),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    validator: (v) => (v == null || v.length < 6) ? "Ən az 6 simvol olmalıdır" : null,
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    height: 52,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2563EB),
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      onPressed: _isLoading ? null : _handleLogin,
                      child: _isLoading
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Text("Daxil Ol", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 52,
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFF059669),
                        side: const BorderSide(color: Color(0xFF059669)),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const RegisterScreen()),
                        );
                      },
                      child: const Text("Yeni İşçi Qeydiyyatı", style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: Column(
                      children: [
                        const Text(
                          "Sürətli Sınaq Girişi:",
                          style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF64748B)),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(
                              child: ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFFF1F5F9),
                                  foregroundColor: const Color(0xFF1E293B),
                                  elevation: 0,
                                ),
                                onPressed: () => _quickLoginAs('WORKER'),
                                child: const Text("İşçi Paneli", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF7C3AED),
                                  foregroundColor: Colors.white,
                                  elevation: 0,
                                ),
                                onPressed: () => _quickLoginAs('ADMIN'),
                                child: const Text("Administrator", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
