import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_stripe/flutter_stripe.dart';

import 'features/auth/models/app_session.dart';
import 'features/auth/services/microsoft_auth_service.dart';
import 'core/bc_api_client.dart';

import 'features/auth/screens/welcome_screen.dart';
import 'features/bc_ways/constants/colors.dart';
import 'features/bc_ways/services/route_history_service.dart';
import 'features/home/screens/home_screen.dart';

class NoPageTransitionsBuilder extends PageTransitionsBuilder {
  const NoPageTransitionsBuilder();

  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    return child;
  }
}

const PageTransitionsTheme noPageTransitions = PageTransitionsTheme(
  builders: {
    TargetPlatform.android: NoPageTransitionsBuilder(),
    TargetPlatform.iOS: NoPageTransitionsBuilder(),
    TargetPlatform.macOS: NoPageTransitionsBuilder(),
    TargetPlatform.windows: NoPageTransitionsBuilder(),
    TargetPlatform.linux: NoPageTransitionsBuilder(),
    TargetPlatform.fuchsia: NoPageTransitionsBuilder(),
  },
);

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  const stripePublishableKey = String.fromEnvironment('STRIPE_PUBLISHABLE_KEY');
  if (stripePublishableKey.isNotEmpty) {
    Stripe.publishableKey = stripePublishableKey;
    await Stripe.instance.applySettings();
  }
  runApp(const BCSmartApp());
}

class BCSmartApp extends StatefulWidget {
  const BCSmartApp({super.key});

  @override
  State<BCSmartApp> createState() => _BCSmartAppState();
}

class _BCSmartAppState extends State<BCSmartApp> {
  AppSession? _session;
  bool _restoringMicrosoftSession = true;
  String? _microsoftStartupError;

  @override
  void initState() {
    super.initState();
    _restoreMicrosoftSession();
  }

  Future<void> _restoreMicrosoftSession() async {
    try {
      final session = await MicrosoftAuthService().restoreWebSession();
      if (!mounted) {
        return;
      }

      if (session != null) {
        BcApiClient.instance.setToken(session.accessToken);
        _session = session;
      }
    } catch (_) {
      if (!mounted) {
        return;
      }

      _microsoftStartupError =
          'Microsoft sign-in could not be completed. '
          'Please check your connection and try signing in again.';
    } finally {
      if (mounted) {
        setState(() {
          _restoringMicrosoftSession = false;
        });
      }
    }
  }

  bool _microsoftLoginBusy = false;

  Future<void> _loginStudent(BuildContext context) async {
    if (_microsoftLoginBusy) {
      return;
    }

    setState(() {
      _microsoftLoginBusy = true;
    });

    try {
      final session = await MicrosoftAuthService().signIn();

      if (!mounted || session == null) {
        return;
      }

      BcApiClient.instance.setToken(session.accessToken);
      setState(() {
        _session = session;
      });
    } catch (_) {
      if (!context.mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Microsoft sign-in could not be completed. Please try again.',
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _microsoftLoginBusy = false;
        });
      }
    }
  }

  void _loginGuest() {
    setState(() {
      _session = const AppSession.guest();
    });

    unawaited(_startGuestApiSession());
  }

  /// Guests browse without signing in, but the API still needs an anonymous
  /// guest token so their BC Ways route history can be saved. Best effort:
  /// if the server is unreachable the app works exactly as before.
  Future<void> _startGuestApiSession() async {
    try {
      final response = await BcApiClient.instance.postJson(
        '/api/guests/session',
        {},
      );
      final token = response['token']?.toString();

      if (!mounted || token == null || token.isEmpty) {
        return;
      }

      // The guest may have gone back to the welcome screen meanwhile.
      if (_session?.isGuest != true) {
        return;
      }

      BcApiClient.instance.setToken(token);
      RouteHistoryService.instance.refresh();
    } catch (_) {
      // History just stays unavailable until the next guest session.
    }
  }

  bool _logoutBusy = false;

  Future<void> _logout() async {
    if (_logoutBusy) {
      return;
    }
    _logoutBusy = true;

    try {
      if (_session?.isGuest != true) {
        await MicrosoftAuthService().signOut();
      }

      BcApiClient.instance.setToken(null);

      if (!mounted) {
        return;
      }

      setState(() {
        _session = null;
      });
    } catch (_) {
      if (!mounted) {
        return;
      }

      setState(() {
        _microsoftStartupError =
            'Sign-out could not be completed. Please check your connection '
            'and try signing out again.';
      });
    } finally {
      _logoutBusy = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'BC Smart Lifestyle',
      debugShowCheckedModeBanner: false,
      initialRoute: '/',

      theme: BcTheme.light().copyWith(pageTransitionsTheme: noPageTransitions),

      darkTheme: BcTheme.dark().copyWith(
        pageTransitionsTheme: noPageTransitions,
      ),

      themeMode: ThemeMode.system,

      builder: (context, child) {
        final dark = Theme.of(context).brightness == Brightness.dark;

        return AnnotatedRegion<SystemUiOverlayStyle>(
          value: (dark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark)
              .copyWith(
                statusBarColor: Colors.transparent,

                systemNavigationBarColor: Theme.of(
                  context,
                ).scaffoldBackgroundColor,
              ),

          child: child ?? const SizedBox.shrink(),
        );
      },

      home: Builder(
        builder: (context) {
          if (_restoringMicrosoftSession) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }

          if (_microsoftStartupError != null) {
            return Scaffold(
              body: SafeArea(
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          _microsoftStartupError!,
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        FilledButton(
                          onPressed: () {
                            setState(() {
                              _microsoftStartupError = null;
                            });
                          },
                          child: const Text('Back to sign-in'),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          }

          final session = _session;

          if (session != null) {
            return CampusDashboardPage(session: session, onLogout: _logout);
          }

          return WelcomeScreen(
            signingIn: _microsoftLoginBusy,
            onStudentTap: () => _loginStudent(context),

            onVisitorTap: _loginGuest,
          );
        },
      ),
    );
  }
}
