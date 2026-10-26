import 'package:flutter/material.dart';
import '../../../core/bc_api_client.dart';
import '../models/app_session.dart';

class StudentNameScreen extends StatefulWidget {
  const StudentNameScreen({super.key});
  @override State<StudentNameScreen> createState() => _StudentNameScreenState();
}
class _StudentNameScreenState extends State<StudentNameScreen> {
  final _formKey = GlobalKey<FormState>();
  final _fullNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _busy = false;
  @override void dispose() { _fullNameController.dispose(); _emailController.dispose(); _passwordController.dispose(); super.dispose(); }
  String _formatFullName(String value) => value.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty).map((p) => p.length == 1 ? p.toUpperCase() : '${p[0].toUpperCase()}${p.substring(1)}').join(' ');
  Future<void> _continue() async {
    if (!_formKey.currentState!.validate() || _busy) return;
    final email = _emailController.text.trim(); final password = _passwordController.text;
    if (email.isNotEmpty != password.isNotEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Enter both your account email and password, or leave both blank for preview mode.')));
      return;
    }
    if (email.isNotEmpty && password.isNotEmpty) {
      setState(() => _busy = true);
      try {
        final response = await BcApiClient.instance.postJson('/api/users/signin', {'email': email, 'password': password});
        final user = response['data'] as Map<String, dynamic>? ?? {};
        final token = response['token']?.toString();
        if (token == null || token.isEmpty) throw const BcApiException('The server did not return an access token.');
        if (!mounted) return;
        Navigator.of(context).pop<AppSession>(AppSession.student(
          fullName: (user['fullName'] ?? user['name'] ?? _fullNameController.text).toString(),
          email: (user['email'] ?? email).toString(), accessToken: token,
        ));
      } catch (error) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Sign-in failed: $error')));
      } finally { if (mounted) setState(() => _busy = false); }
      return;
    }
    Navigator.of(context).pop<AppSession>(AppSession.student(fullName: _formatFullName(_fullNameController.text)));
  }
  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(title: const Text('Student Access')),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 500),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Icon(Icons.school_outlined, size: 70, color: scheme.primary),
                    const SizedBox(height: 20),
                    Text(
                      'Welcome, Student',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Sign in with your BC Eats account for live orders and payments. Name-only access remains available for the offline preview.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: scheme.onSurfaceVariant),
                    ),
                    const SizedBox(height: 24),
                    TextFormField(
                      controller: _fullNameController,
                      textCapitalization: TextCapitalization.words,
                      textInputAction: TextInputAction.next,
                      validator: (v) => (v?.trim().length ?? 0) < 2
                          ? 'Please enter your full name.'
                          : null,
                      decoration: const InputDecoration(
                        labelText: 'Full name',
                        prefixIcon: Icon(Icons.person_outline),
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      textInputAction: TextInputAction.next,
                      decoration: const InputDecoration(
                        labelText: 'Account email (for live ordering)',
                        prefixIcon: Icon(Icons.email_outlined),
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _passwordController,
                      obscureText: true,
                      textInputAction: TextInputAction.done,
                      onFieldSubmitted: (_) => _continue(),
                      decoration: const InputDecoration(
                        labelText: 'Password',
                        prefixIcon: Icon(Icons.lock_outline),
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Leave both account fields blank to use local preview mode. If you enter an email, enter its password too.',
                      style: TextStyle(
                        color: scheme.onSurfaceVariant,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 20),
                    FilledButton.icon(
                      onPressed: _busy ? null : _continue,
                      icon: _busy
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.arrow_forward),
                      label: Text(_busy ? 'Signing in…' : 'Continue'),
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
