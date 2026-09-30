import 'package:flutter/material.dart';

import '../../../shared/widgets/campus_logo.dart';
import '../../../shared/widgets/decorative_asset.dart';
import '../../../shared/widgets/time_greeting.dart';
import '../../auth/models/app_session.dart';
import '../../bc_ways/constants/colors.dart';
import '../../bc_ways/constants/map_constants.dart';
import '../../bc_ways/screens/map_screen.dart';
import '../../bc_ways/widgets/bc_bottom_navigation_bar.dart';

class CampusDashboardPage extends StatelessWidget {
  final AppSession session;
  final VoidCallback onLogout;

  const CampusDashboardPage({
    super.key,
    required this.session,
    required this.onLogout,
  });

  void _openBcWays(BuildContext context) {
    Navigator.of(
      context,
    ).push(MaterialPageRoute<void>(builder: (_) => const MapScreen()));
  }

  void _openBcEats(BuildContext context) {
    // Students will use the real BC Eats feature later.
    // For now, do nothing.
    if (session.isStudent) {
      return;
    }

    // Guests / parents are redirected to BC Ways
    // with the Tuck Shop selected.
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => const MapScreen(
          initialDestinationQuery: 'Tuck Shop',
        ),
      ),
    );
  }

  void _onBottomNavTap(BuildContext context, int index) {
    if (index == 1) {
      _openBcWays(context);
    } else if (index == 2 || index == 3) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '${index == 2 ? 'Orders' : 'Profile'} '
            'is not connected yet.',
          ),
        ),
      );
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

                      Badge(
                        label: const Text('3'),
                        child: IconButton(
                          tooltip: 'Notifications',
                          onPressed: () {},
                          icon: const Icon(
                            Icons.notifications_none_outlined,
                            size: 30,
                          ),
                        ),
                      ),
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
                              padding: const EdgeInsets.symmetric(
                                vertical: 12,
                              ),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment:
                                    CrossAxisAlignment.start,
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

                  const _SectionHeader(title: 'Upcoming'),

                  const SizedBox(height: 12),

                  const _ActivityCard(
                    icon: Icons.calendar_month_outlined,
                    color: Color(0xFF008579),
                    title: 'Database Systems Lecture',
                    subtitle: 'PSI-204 · 11:00 AM – 12:00 PM',
                    detail: 'Synced with Microsoft Calendar',
                  ),

                  const SizedBox(height: 12),

                  const _ActivityCard(
                    icon: Icons.airplanemode_on_outlined,
                    color: Color(0xFF9A6700),
                    title: 'Drone delivery',
                    subtitle: 'Your order is on the way',
                    time: '10:20 AM',
                    detail: '30 min',
                  ),

                  const SizedBox(height: 24),

                  const _SectionHeader(title: 'Notifications'),

                  const SizedBox(height: 12),

                  const _ActivityCard(
                    icon: Icons.report_problem_outlined,
                    color: BcColors.danger,
                    title: 'Path blocked ahead',
                    subtitle: 'Rerouting to fastest route',
                    time: '2 min ago',
                  ),

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

  const _SectionHeader({required this.title});

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
        Text(
          'See all',
          style: TextStyle(
            fontWeight: FontWeight.w700,
            color: context.bcColors.error,
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

  const _ActivityCard({
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
    this.detail,
    this.time,
  });

  @override
  Widget build(BuildContext context) {
    final accent = context.readableAccent(color);

    return Container(
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

          Icon(Icons.chevron_right, color: context.textSecondary),
        ],
      ),
    );
  }
}
