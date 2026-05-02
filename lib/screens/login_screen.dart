import 'package:flutter/material.dart';

import '../models/app_user_session.dart';
import '../services/syncup_api_client.dart';
import '../theme/sync_up_theme.dart';
import '../widgets/syncup_logo.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key, required this.onLoggedIn});

  final ValueChanged<AppUserSession> onLoggedIn;

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final SyncUpApiClient _api = SyncUpApiClient();
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  String? _error;
  bool _submitting = false;

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _continue() async {
    final username = _usernameController.text.trim();
    final password = _passwordController.text;
    if (username.isEmpty || password.isEmpty) {
      setState(() {
        _error = 'Enter username and password';
      });
      return;
    }
    setState(() {
      _error = null;
      _submitting = true;
    });
    try {
      final session = await _api.login(username: username, password: password);
      if (!mounted) return;
      widget.onLoggedIn(session);
      return;
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _error = 'Invalid username or password';
      });
    } finally {
      if (mounted) {
        setState(() => _submitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 460),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Center(
                      child: SyncUpLogo(size: 48),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Sign In',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: SyncUpTheme.primaryLight,
                        borderRadius: BorderRadius.circular(SyncUpTheme.radiusSm),
                        border: Border.all(color: SyncUpTheme.primary.withValues(alpha: 0.18)),
                      ),
                      child: const Text(
                        'Default users:\n'
                        '- professor / Professor@123\n'
                        '- student / Student@123',
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _usernameController,
                      decoration: const InputDecoration(
                        labelText: 'Username',
                        hintText: 'professor or student',
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _passwordController,
                      obscureText: true,
                      decoration: const InputDecoration(
                        labelText: 'Password',
                      ),
                    ),
                    if (_error != null) ...[
                      const SizedBox(height: 12),
                      Text(
                        _error!,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Colors.red.shade700,
                            ),
                      ),
                    ],
                    const SizedBox(height: 20),
                    FilledButton(
                      onPressed: _submitting ? null : _continue,
                      child: Text(_submitting ? 'Signing in...' : 'Continue'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
