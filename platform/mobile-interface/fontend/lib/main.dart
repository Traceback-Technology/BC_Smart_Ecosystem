import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'features/auth/models/app_session.dart';
import 'features/auth/screens/student_name_screen.dart';
import 'features/auth/screens/welcome_screen.dart';
import 'features/bc_ways/constants/colors.dart';
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

void main() {
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

    setState(() {
      _session = session;
    });
  }

  void _loginGuest() {
    setState(() {
      _session = const AppSession.guest();
    });
  }

  void _logout() {
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
