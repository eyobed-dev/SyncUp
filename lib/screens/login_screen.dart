import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/app_user_session.dart';
import '../services/syncup_api_client.dart';
import '../widgets/syncup_logo.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key, required this.onLoggedIn});

  final ValueChanged<AppUserSession> onLoggedIn;

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final SyncUpApiClient _api = SyncUpApiClient();
  static const _backendAdminUrl = 'http://161.97.70.30:18090/_/';
  static const _syncupApkUrl =
      'https://drive.google.com/file/d/1W_MV6PXZSJKJbtvnNRe1HKbLFAmb7BJH/view?usp=sharing';
  static const _professorUsername = 'p';
  static const _professorPassword = '1';
  static const _studentUsername = 's';
  static const _studentPassword = '1';
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

  void _fillCredentials({required String username, required String password}) {
    setState(() {
      _usernameController.text = username;
      _passwordController.text = password;
      _error = null;
    });
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

  Future<void> _openBackendAdmin() async {
    final uri = Uri.parse(_backendAdminUrl);
    final opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!opened && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not open backend link'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _openSyncupApk() async {
    final uri = Uri.parse(_syncupApkUrl);
    final opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!opened && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not open APK link'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(vertical: 24),
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
                    const SizedBox(height: 6),
                    Text(
                      'Demo accounts',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Professor: $_professorUsername / $_professorPassword',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Student: $_studentUsername / $_studentPassword',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      alignment: WrapAlignment.center,
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        OutlinedButton(
                          onPressed: _submitting
                              ? null
                              : () => _fillCredentials(
                                    username: _professorUsername,
                                    password: _professorPassword,
                                  ),
                          child: const Text('Use Professor'),
                        ),
                        OutlinedButton(
                          onPressed: _submitting
                              ? null
                              : () => _fillCredentials(
                                    username: _studentUsername,
                                    password: _studentPassword,
                                  ),
                          child: const Text('Use Student'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _usernameController,
                      decoration: const InputDecoration(
                        labelText: 'Username',
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
                    const SizedBox(height: 10),
                    OutlinedButton.icon(
                      onPressed: _submitting ? null : _openSyncupApk,
                      icon: const Icon(Icons.android, size: 18),
                      label: const Text('Syncup Apk'),
                    ),
                    const SizedBox(height: 10),
                    OutlinedButton.icon(
                      onPressed: _submitting ? null : _openBackendAdmin,
                      icon: const Icon(Icons.open_in_new, size: 18),
                      label: const Text('Open Backend'),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Please check the Login Credentials for nackend on the Report. Thank you!',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            fontSize: 11,
                          ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    ),
  );
}
}
