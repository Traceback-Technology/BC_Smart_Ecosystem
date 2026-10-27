import 'package:flutter/material.dart';

import '../../auth/models/app_session.dart';
import '../../profile/services/profile_local_store.dart';
import '../services/bc_eats_store.dart';
import '../../bc_ways/widgets/bc_bottom_navigation_bar.dart';
import '../widgets/eats_order_widgets.dart';
import 'bc_eats_home_screen.dart';
import 'orders.dart';

/// Owns the global navigation while a nested navigator handles checkout.
class BCEatsShell extends StatefulWidget {
  final AppSession session;
  final int initialIndex;
  final ValueChanged<int>? onNavigate;

  const BCEatsShell({
    super.key,
    required this.session,
    this.initialIndex = 0,
    this.onNavigate,
  });
  @override
  State<BCEatsShell> createState() => _BCEatsShellState();
}

class _BCEatsShellState extends State<BCEatsShell> {
  final _navigator = GlobalKey<NavigatorState>();
  late int _currentIndex = widget.initialIndex == 1 ? 3 : 2;
  bool _canPop = false;

  late final String _profileAccountKey;
  late final ProfileLocalStore _profileStore;

  @override
  void initState() {
    super.initState();

    _profileAccountKey = [
      widget.session.email ?? '',
      widget.session.fullName ?? '',
      widget.session.role.name,
    ].join('|');

    _profileStore = ProfileLocalStore(_profileAccountKey);

    _syncProfileContactDefaults();
  }

  Future<void> _syncProfileContactDefaults() async {
    final store = BcEatsStore.instance;
    final profileName = widget.session.displayName;
    final profileEmail = widget.session.email?.trim() ?? '';

    // Load name/email immediately while the persisted phone number loads.
    store.setProfileContactDefaults(
      accountKey: _profileAccountKey,
      name: profileName,
      phone: '',
      email: profileEmail,
    );

    final profilePhone = await _profileStore.loadPhone() ?? '';

    if (!mounted) {
      return;
    }

    store.setProfileContactDefaults(
      accountKey: _profileAccountKey,
      name: profileName,
      phone: profilePhone,
      email: profileEmail,
    );
  }

  void _onTabTapped(int index) {
    if (index == 2 || index == 3) {
      setState(() => _currentIndex = index);
      _navigator.currentState!.pushAndRemoveUntil(
        MaterialPageRoute<void>(
          settings: RouteSettings(name: index == 2 ? '/eats' : '/orders'),
          builder: (_) => index == 2
              ? const BCEatsHomeScreen(showBottomNavigation: false)
              : const OrdersScreen(showBottomNavigation: false),
        ),
        (route) => false,
      );
      return;
    }
    if (widget.onNavigate != null) {
      widget.onNavigate!(index);
      return;
    }
    if (index == 0) {
      Navigator.maybePop(context);
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          index == 1
              ? 'Open Map from the main navigation.'
              : 'Open Profile from the main navigation.',
        ),
      ),
    );
  }

  void _routeChanged(Route<dynamic>? route) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final canPop = _navigator.currentState?.canPop() ?? false;
      final index = route?.settings.name == '/eats' ? 2 : 3;
      if (_canPop != canPop || _currentIndex != index)
        setState(() {
          _canPop = canPop;
          _currentIndex = index;
        });
    });
  }

  @override
  Widget build(BuildContext context) => PopScope(
    canPop: !_canPop,
    onPopInvokedWithResult: (didPop, result) {
      if (!didPop) _navigator.currentState?.maybePop();
    },
    child: EatsFlowScope(
      navigate: _onTabTapped,
      child: Scaffold(
        backgroundColor: context.eatsBackground,
        body: Navigator(
          key: _navigator,
          observers: [_EatsRouteObserver(_routeChanged)],
          onGenerateRoute: (_) {
            final showOrders = _currentIndex == 3;
            return MaterialPageRoute<void>(
              settings: RouteSettings(name: showOrders ? '/orders' : '/eats'),
              builder: (_) => showOrders
                  ? const OrdersScreen(showBottomNavigation: false)
                  : const BCEatsHomeScreen(showBottomNavigation: false),
            );
          },
        ),
        bottomNavigationBar: BcBottomNavigationBar(
          selectedIndex: _currentIndex,
          onTap: _onTabTapped,
        ),
      ),
    ),
  );
}

class _EatsRouteObserver extends NavigatorObserver {
  final ValueChanged<Route<dynamic>?> changed;
  _EatsRouteObserver(this.changed);
  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    changed(route);
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    changed(previousRoute);
  }

  @override
  void didRemove(Route<dynamic> route, Route<dynamic>? previousRoute) {
    /* didPush/didPop owns the current route. */
  }
  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    changed(newRoute);
  }
}
