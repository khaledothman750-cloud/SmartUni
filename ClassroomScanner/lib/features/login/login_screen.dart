// Author / Project Supervisor : Omar Terro
// GitHub                      : https://github.com/IOTERRO
// Website                     : https://omarterro.fr
// Student (FYP)               : Khaled Othman
// Date                        : 14 October 2026
// Project                     : SmartUni - Classroom Scanner
import 'package:flutter/material.dart';

import '../../app/theme.dart';
import '../../core/attribution.dart';
import '../../core/config/app_config.dart';
import '../../core/saved_login_store.dart';
import '../../data/scanner_api.dart';
import '../../data/worker_api_client.dart';
import '../sessions/session_list_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key, required this.api});

  final ScannerApi api;

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _userController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _loading = false;
  bool _obscure = true;
  bool _rememberMe = false;

  @override
  void initState() {
    super.initState();
    _restoreSavedLogin();
  }

  Future<void> _restoreSavedLogin() async {
    final saved = await SavedLoginStore.load();
    if (!mounted) return;
    setState(() {
      _rememberMe = saved.remember;
      if (saved.remember) {
        _userController.text = saved.username;
        _passwordController.text = saved.password;
      }
    });
  }

  @override
  void dispose() {
    _userController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    setState(() => _loading = true);
    try {
      final user = await widget.api.loginInstructor(
        username: _userController.text,
        password: _passwordController.text,
      );
      await SavedLoginStore.save(
        remember: _rememberMe,
        username: _userController.text,
        password: _passwordController.text,
      );
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => SessionListScreen(api: widget.api, user: user),
        ),
      );
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message)),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(24, 36, 24, 24),
              children: [
                const Icon(Icons.qr_code_scanner_rounded,
                    size: 56, color: ScannerColors.accent),
                const SizedBox(height: 16),
                Text(
                  AppConfig.appName,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: ScannerColors.navy,
                      ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Sign in as administrator to open a class session and scan student QRs.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: ScannerColors.navy.withValues(alpha: 0.7),
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 28),
                TextField(
                  controller: _userController,
                  textInputAction: TextInputAction.next,
                  decoration: const InputDecoration(
                    labelText: 'Admin username',
                    prefixIcon: Icon(Icons.person_outline),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _passwordController,
                  obscureText: _obscure,
                  onSubmitted: (_) => _loading ? null : _login(),
                  decoration: InputDecoration(
                    labelText: 'Password',
                    prefixIcon: const Icon(Icons.lock_outline),
                    suffixIcon: IconButton(
                      onPressed: () => setState(() => _obscure = !_obscure),
                      icon: Icon(
                        _obscure
                            ? Icons.visibility_outlined
                            : Icons.visibility_off_outlined,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                CheckboxListTile(
                  value: _rememberMe,
                  onChanged: _loading
                      ? null
                      : (v) => setState(() => _rememberMe = v ?? false),
                  controlAffinity: ListTileControlAffinity.leading,
                  contentPadding: EdgeInsets.zero,
                  dense: true,
                  activeColor: ScannerColors.accent,
                  title: const Text(
                    'Remember me on this device',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                ElevatedButton(
                  onPressed: _loading ? null : _login,
                  child: _loading
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text('Open scanner'),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Use an admin account from the Cloudflare D1 users table.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 12, color: Colors.black54),
                ),
                const SizedBox(height: 28),
                Text(
                  Attribution.header,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 10, color: Colors.black45),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
