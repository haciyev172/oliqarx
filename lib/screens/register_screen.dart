import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import '../services/auth_service.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _phone = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();

  bool _loading = false;
  bool _hidePassword = true;

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;

    if (Firebase.apps.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Qeydiyyat üçün Firebase konfiqurasiyası tələb olunur.',
          ),
        ),
      );
      return;
    }

    setState(() => _loading = true);

    try {
      await AuthService().register(
        email: _email.text.trim(),
        password: _password.text,
        fullName: _name.text.trim(),
        phone: _phone.text.trim(),
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Qeydiyyat tamamlandı. İndi daxil ola bilərsiniz.',
            ),
          ),
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Qeydiyyat xətası: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('İşçi qeydiyyatı'),
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Icon(
                    Icons.person_add_alt_1,
                    size: 56,
                    color: Color(0xFF2563EB),
                  ),
                  const SizedBox(height: 20),

                  TextFormField(
                    controller: _name,
                    textCapitalization: TextCapitalization.words,
                    decoration: const InputDecoration(
                      labelText: 'Ad və soyad',
                      prefixIcon: Icon(Icons.person_outline),
                      border: OutlineInputBorder(),
                    ),
                    validator: (v) =>
                        v == null || v.trim().isEmpty
                            ? 'Adınızı daxil edin'
                            : null,
                  ),

                  const SizedBox(height: 14),

                  TextFormField(
                    controller: _phone,
                    keyboardType: TextInputType.phone,
                    decoration: const InputDecoration(
                      labelText: 'Mobil nömrə',
                      prefixText: '+994 ',
                      hintText: '50 123 45 67',
                      prefixIcon: Icon(Icons.phone_android),
                      border: OutlineInputBorder(),
                    ),
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) {
                        return 'Mobil nömrənizi daxil edin';
                      }

                      final digits = v.replaceAll(
                        RegExp(r'\D'),
                        '',
                      );

                      if (digits.length != 9 ||
                          !RegExp(r'^[0-9]+$').hasMatch(digits)) {
                        return 'Nömrəni 50 123 45 67 formatında daxil edin';
                      }

                      return null;
                    },
                  ),

                  const SizedBox(height: 14),

                  TextFormField(
                    controller: _email,
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(
                      labelText: 'E-poçt',
                      prefixIcon: Icon(Icons.email_outlined),
                      border: OutlineInputBorder(),
                    ),
                    validator: (v) {
                      final email = v?.trim() ?? '';
                      if (!RegExp(
                        r'^[^@\s]+@[^@\s]+\.[^@\s]+$',
                      ).hasMatch(email)) {
                        return 'Düzgün e-poçt daxil edin';
                      }
                      return null;
                    },
                  ),

                  const SizedBox(height: 14),

                  TextFormField(
                    controller: _password,
                    obscureText: _hidePassword,
                    decoration: InputDecoration(
                      labelText: 'Şifrə (ən azı 6 simvol)',
                      prefixIcon: const Icon(Icons.lock_outline),
                      border: const OutlineInputBorder(),
                      suffixIcon: IconButton(
                        onPressed: () {
                          setState(() {
                            _hidePassword = !_hidePassword;
                          });
                        },
                        icon: Icon(
                          _hidePassword
                              ? Icons.visibility
                              : Icons.visibility_off,
                        ),
                      ),
                    ),
                    validator: (v) =>
                        v == null || v.length < 6
                            ? 'Şifrə ən azı 6 simvol olmalıdır'
                            : null,
                  ),

                  const SizedBox(height: 22),

                  ElevatedButton(
                    onPressed: _loading ? null : _register,
                    child: Padding(
                      padding: const EdgeInsets.all(14),
                      child: _loading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(),
                            )
                          : const Text('Qeydiyyatdan keç'),
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
