import 'dart:js_interop';
import 'package:flutter/material.dart';

/// Shown when the portal has no valid admin session.
///
/// The portal does not sign in with Microsoft itself (the Entra app
/// registration only allows the main app). Admins sign in on BC Ways & Eats,
/// which checks their database role and redirects them here with a token.
///
/// Build with: --dart-define=MAIN_APP_URL=https://<main-app-address>
const _mainAppUrl = String.fromEnvironment('MAIN_APP_URL');

@JS('location')
external _Location get _browserLocation;

extension type _Location(JSObject _) implements JSObject {
  external void assign(JSString url);
}

class AdminLoginScreen extends StatelessWidget {
  const AdminLoginScreen({super.key, required this.onAuthenticated});

  /// Kept for compatibility with main.dart; sign-in now happens in the main app.
  final VoidCallback onAuthenticated;

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: const Color(0xFFF7F7F7),
    body: Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 440),
        child: Card(
          margin: const EdgeInsets.all(24),
          elevation: 2,
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.admin_panel_settings, size: 64, color: Color(0xFF0A3D9D)),
                const SizedBox(height: 18),
                const Text('BC Eats Admin', style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                const Text(
                  'Sign in through BC Ways & Eats with your Microsoft account. '
                  'If your account has an admin role, you will be brought back here automatically.',
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                if (_mainAppUrl.isNotEmpty)
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: () => _browserLocation.assign(_mainAppUrl.toJS),
                      icon: const Icon(Icons.login),
                      label: const Text('Sign in via BC Ways & Eats'),
                    ),
                  ),
                const SizedBox(height: 12),
                const Text(
                  'Access is granted only when your database account has the Admin or Restaurant role.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 12, color: Colors.black54),
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}
