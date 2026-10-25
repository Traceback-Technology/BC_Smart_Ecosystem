import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_stripe/flutter_stripe.dart';

import 'features/auth/models/app_session.dart';
import 'core/bc_api_client.dart';
import 'features/auth/screens/student_name_screen.dart';
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

  Future<void> _loginStudent(BuildContext context) async {
    final session = await Navigator.of(context).push<AppSession>(
      MaterialPageRoute(builder: (_) => const StudentNameScreen()),
    );

    if (!mounted || session == null) {
      return;
    }

    BcApiClient.instance.setToken(session.accessToken);
    setState(() {
      _session = session;
    });
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

  void _logout() {
    BcApiClient.instance.setToken(null);
    setState(() {
      _session = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'BC Smart Lifestyle',
      debugShowCheckedModeBanner: false,

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
          final session = _session;

          if (session != null) {
            return CampusDashboardPage(session: session, onLogout: _logout);
          }

          return WelcomeScreen(
            onStudentTap: () => _loginStudent(context),

            onVisitorTap: _loginGuest,
          );
        },
      ),
    );
  }
}
