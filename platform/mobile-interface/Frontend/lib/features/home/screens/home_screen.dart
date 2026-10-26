import 'package:flutter/material.dart';

import '../../../shared/widgets/campus_logo.dart';
import '../../../shared/widgets/decorative_asset.dart';
import '../../../shared/widgets/time_greeting.dart';
import '../../auth/models/app_session.dart';
import '../../bc_ways/constants/colors.dart';
import '../../bc_ways/constants/map_constants.dart';
import '../../bc_ways/screens/map_screen.dart';
import '../../bc_ways/widgets/bc_bottom_navigation_bar.dart';
import '../../bc_eats/screens/bc_eats_shell.dart';
import '../../profile/screens/profile_screen.dart';
import '../widgets/route_history_section.dart';
import '../../bc_eats/widgets/notification_bell.dart';
import '../../bc_eats/models/app_notification.dart';
import '../../bc_eats/models/notification_display.dart';
import '../../bc_eats/screens/notifications_screen.dart';
import '../../bc_eats/services/notification_badge_controller.dart';
import '../../bc_eats/services/notification_service.dart';

class CampusDashboardPage extends StatelessWidget {
  final AppSession session;
  final VoidCallback onLogout;

  const CampusDashboardPage({
    super.key,
    required this.session,
    required this.onLogout,
  });

  void _openBcWays(BuildContext context) {
    _onBottomNavTap(context, 1);
  }

  void _openBcEats(BuildContext context) {
    _onBottomNavTap(context, 2);
  }

  /// Reopen a past route: BC Ways opens with that destination selected,
  /// ready to start navigating.
  void _openRouteOnMap(BuildContext context, String destination) {
    _showFeature(
      context,
      (_) => MapScreen(
        initialDestinationQuery: destination,
        onNavigate: (index) => _onBottomNavTap(context, index),
      ),
    );
  }

  void _showFeature(BuildContext context, WidgetBuilder builder) {
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute<void>(builder: builder),
      (route) => route.isFirst,
    );
  }

  void _onBottomNavTap(BuildContext context, int index) {
    void onNavigate(int nextIndex) {
      _onBottomNavTap(context, nextIndex);
    }

    switch (index) {
      // Main app Home.
      case 0:
        Navigator.of(context).popUntil((route) => route.isFirst);
        return;

      // BC Ways.
      case 1:
        _showFeature(context, (_) => MapScreen(onNavigate: onNavigate));
        return;

      // BC Eats.
      case 2:
        if (session.isCampusMember) {
          _showFeature(
            context,
            (_) => BCEatsShell(session: session, onNavigate: onNavigate),
          );
          return;
        }

        // Guests / parents do not enter the ordering
        // interface. BC Ways opens with the Tuck Shop
        // selected instead.
        _showFeature(
          context,
          (_) => MapScreen(
            initialDestinationQuery: 'Tuck Shop',
            onNavigate: onNavigate,
          ),
        );
        return;

      // Orders.
      case 3:
        if (session.isCampusMember) {
          _showFeature(
            context,
            (_) => BCEatsShell(
              session: session,
              initialIndex: 1,
              onNavigate: onNavigate,
            ),
          );
          return;
        }

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Orders are available to signed-in students and staff.',
            ),
          ),
        );
        return;

      // Profile.
      case 4:
        _showFeature(
          context,
          (_) => ProfileScreen(
            session: session,
            onLogout: onLogout,
            onNavigate: onNavigate,
          ),
        );
        return;
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1000),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      const CampusLogo(width: 30, height: 30),

                      const Spacer(),

                      // Temporary logout button.
                      // Controlled by the same global debug flag.
                      if (BcWaysMapConstants.showGpsDebug)
                        IconButton(
                          tooltip: 'Debug logout',
                          onPressed: onLogout,
                          icon: Icon(
                            Icons.logout,
                            color: context.bcColors.error,
                          ),
                        ),

                      const NotificationBell(),
                    ],
                  ),

                  const SizedBox(height: 12),

                  SizedBox(
                    height: 110,
                    child: Stack(
                      alignment: Alignment.centerLeft,
                      children: [
                        // Image stays on the right but no longer reserves
                        // horizontal space from the greeting.
                        Positioned.fill(
                          child: Align(
                            alignment: Alignment.centerRight,
                            child: FractionallySizedBox(
                              widthFactor: 0.5,
                              heightFactor: 1.0,
                              child: const ClipRect(
                                child: DecorativeAsset(
                                  'assets/images/home_skyline.png',
                                ),
                              ),
                            ),
                          ),
                        ),

                        // Greeting can now use almost the whole screen width
                        // and may overlap the image when the name is long.
                        Positioned.fill(
                          child: Align(
                            alignment: Alignment.centerLeft,
                            child: Padding(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    session.isGuest
                                        ? 'Hello there! 👋'
                                        : 'Hello, ${session.firstName}! 👋',
                                    style: Theme.of(context)
                                        .textTheme
                                        .headlineSmall
                                        ?.copyWith(
                                          fontWeight: FontWeight.w800,
                                          color: scheme.onSurface,
                                        ),
                                  ),

                                  const SizedBox(height: 4),

                                  TimeGreeting(
                                    style: TextStyle(
                                      color: scheme.onSurfaceVariant,
                                      fontSize: 16,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 12),

                  LayoutBuilder(
                    builder: (context, constraints) {
                      final ways = _FeatureCard(
                        title: 'BC WAYS',
                        subtitle: 'Navigate Campus',
                        icon: Icons.arrow_forward,
                        accent: BcColors.primary,
                        image: 'assets/images/ways_illustration.png',
                        onTap: () => _openBcWays(context),
                      );

                      final eats = _FeatureCard(
                        title: 'BC EATS',
                        subtitle: 'Order Food',
                        icon: Icons.restaurant,
                        accent: BcColors.danger,
                        image: 'assets/images/eats_illustration.png',
                        iconAtEnd: true,
                        onTap: () => _openBcEats(context),
                      );

                      if (constraints.maxWidth < 240) {
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [ways, const SizedBox(height: 12), eats],
                        );
                      }

                      return IntrinsicHeight(
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Expanded(child: ways),
                            const SizedBox(width: 12),
                            Expanded(child: eats),
                          ],
                        ),
                      );
                    },
                  ),

                  const SizedBox(height: 24),

                  RouteHistorySection(
                    onOpenRoute: (destination) =>
                        _openRouteOnMap(context, destination),
                  ),

                  const SizedBox(height: 24),

                  const _RecentNotificationsSection(),

                  const SizedBox(height: 12),
                ],
              ),
            ),
          ),
        ),
      ),

      bottomNavigationBar: BcBottomNavigationBar(
        selectedIndex: 0,
        onTap: (index) => _onBottomNavTap(context, index),
      ),
    );
  }
}

class _FeatureCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color accent;
  final String image;
  final bool iconAtEnd;
  final VoidCallback? onTap;

  const _FeatureCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.accent,
    required this.image,
    this.iconAtEnd = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Material(
      color: Color.alphaBlend(accent.withValues(alpha: .05), context.cardBg),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: accent, width: 1.5),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                      color: scheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 13,
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 124),
                ],
              ),
            ),

            Positioned(
              bottom: 12,
              left: 12,
              right: 12,
              height: 112,
              child: Stack(
                children: [
                  Positioned.fill(
                    child: FractionallySizedBox(
                      widthFactor: .9,
                      heightFactor: .9,
                      child: DecorativeAsset(image),
                    ),
                  ),

                  Positioned(
                    bottom: 0,
                    left: iconAtEnd ? null : 0,
                    right: iconAtEnd ? 0 : null,
                    child: Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        color: accent,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        icon,
                        size: 24,
                        color:
                            ThemeData.estimateBrightnessForColor(accent) ==
                                Brightness.light
                            ? Colors.black
                            : Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final VoidCallback? onSeeAll;

  const _SectionHeader({required this.title, this.onSeeAll});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      alignment: WrapAlignment.spaceBetween,
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: 16,
      runSpacing: 8,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: context.textPrimary,
          ),
        ),
        if (onSeeAll != null)
          InkWell(
            onTap: onSeeAll,
            borderRadius: BorderRadius.circular(6),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
              child: Text(
                'See all',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  color: context.bcColors.error,
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _ActivityCard extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;
  final String? detail;
  final String? time;
  final VoidCallback? onTap;
  final bool showChevron;

  const _ActivityCard({
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
    this.detail,
    this.time,
    this.onTap,
    this.showChevron = true,
  });

  @override
  Widget build(BuildContext context) {
    final accent = context.readableAccent(color);

    final card = Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: context.subtleBorder),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: accent.withValues(alpha: .12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: accent, size: 24),
          ),

          const SizedBox(width: 12),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: context.textPrimary,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),

                const SizedBox(height: 4),

                Text(
                  subtitle,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: context.textSecondary, fontSize: 13),
                ),

                if (detail != null || time != null) ...[
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 12,
                    runSpacing: 4,
                    children: [
                      if (time != null)
                        Text(
                          time!,
                          style: TextStyle(
                            color: context.textSecondary,
                            fontSize: 12,
                          ),
                        ),

                      if (detail != null)
                        Text(
                          detail!,
                          style: TextStyle(color: accent, fontSize: 12),
                        ),
                    ],
                  ),
                ],
              ],
            ),
          ),

          if (showChevron)
            Icon(Icons.chevron_right, color: context.textSecondary),
        ],
      ),
    );

    if (onTap == null) return card;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: card,
      ),
    );
  }
}

/// Home-screen preview of the latest notifications from /api/notifications.
/// Hidden for guests (the notification API is registered-users-only), and
/// refreshed whenever the bell's unread count changes.
class _RecentNotificationsSection extends StatefulWidget {
  const _RecentNotificationsSection();

  @override
  State<_RecentNotificationsSection> createState() =>
      _RecentNotificationsSectionState();
}

class _RecentNotificationsSectionState
    extends State<_RecentNotificationsSection> {
  static const int _previewCount = 2;

  final _badge = NotificationBadgeController.instance;
  List<AppNotification> _items = const [];
  bool _loading = true;
  bool _failed = false;
  int _lastSeenCount = -1;

  @override
  void initState() {
    super.initState();
    _badge.addListener(_onBadgeChanged);
    _lastSeenCount = _badge.unreadCount;
    if (_badge.isActive) _load();
  }

  @override
  void dispose() {
    _badge.removeListener(_onBadgeChanged);
    super.dispose();
  }

  // A different unread count means something changed on the server: reload.
  void _onBadgeChanged() {
    if (!mounted) return;
    if (!_badge.isActive) {
      setState(() => _items = const []);
      return;
    }
    if (_badge.unreadCount != _lastSeenCount) {
      _lastSeenCount = _badge.unreadCount;
      _load();
    } else {
      setState(() {});
    }
  }

  Future<void> _load() async {
    setState(() {
      _loading = _items.isEmpty;
      _failed = false;
    });
    try {
      final items = await NotificationService.instance.fetchNotifications(
        limit: _previewCount,
      );
      if (!mounted) return;
      setState(() {
        _items = items;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _failed = _items.isEmpty;
      });
    }
  }

  Future<void> _openAll() async {
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const NotificationsScreen()),
    );
    if (mounted && _badge.isActive) _load();
  }

  @override
  Widget build(BuildContext context) {
    if (!_badge.isActive) return const SizedBox.shrink();

    final List<Widget> cards;
    if (_loading) {
      cards = const [
        _ActivityCard(
          icon: Icons.notifications_none,
          color: BcColors.danger,
          title: 'Loading notifications…',
          subtitle: 'Fetching your latest updates',
          showChevron: false,
        ),
      ];
    } else if (_failed) {
      cards = [
        _ActivityCard(
          icon: Icons.cloud_off_outlined,
          color: BcColors.danger,
          title: 'Could not load notifications',
          subtitle: 'Tap to try again',
          showChevron: false,
          onTap: _load,
        ),
      ];
    } else if (_items.isEmpty) {
      cards = const [
        _ActivityCard(
          icon: Icons.notifications_none,
          color: BcColors.danger,
          title: "You're all caught up",
          subtitle: 'New updates will show up here',
          showChevron: false,
        ),
      ];
    } else {
      cards = [
        for (var i = 0; i < _items.length; i++) ...[
          if (i > 0) const SizedBox(height: 12),
          _ActivityCard(
            icon: notificationIcon(_items[i].type),
            color: BcColors.danger,
            title: _items[i].title,
            subtitle: _items[i].message,
            time: notificationTimeAgo(_items[i].createdAt),
            detail: _items[i].isRead ? null : 'New',
            onTap: _openAll,
          ),
        ],
      ];
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _SectionHeader(title: 'Notifications', onSeeAll: _openAll),
        const SizedBox(height: 12),
        ...cards,
      ],
    );
  }
}
