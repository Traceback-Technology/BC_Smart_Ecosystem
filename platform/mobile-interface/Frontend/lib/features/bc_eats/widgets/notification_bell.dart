import 'package:flutter/material.dart';
import '../screens/notifications_screen.dart';
import '../services/notification_badge_controller.dart';

/// Bell icon with a live unread badge. Hidden for guests, because the
/// notification routes are registered-users-only.
class NotificationBell extends StatelessWidget {
  const NotificationBell({super.key});

  @override
  Widget build(BuildContext context) {
    final badge = NotificationBadgeController.instance;

    return ListenableBuilder(
      listenable: badge,
      builder: (context, _) {
        if (!badge.isActive) return const SizedBox.shrink();

        final count = badge.unreadCount;
        return IconButton(
          tooltip: 'Notifications',
          onPressed: () => Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const NotificationsScreen()),
          ),
          icon: Stack(
            clipBehavior: Clip.none,
            children: [
              const Icon(Icons.notifications_none, size: 29),
              if (count > 0)
                Positioned(
                  right: -4,
                  top: -5,
                  child: Container(
                    constraints: const BoxConstraints(
                      minWidth: 18,
                      minHeight: 18,
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    alignment: Alignment.center,
                    decoration: const BoxDecoration(
                      color: Color(0xFFE31B23),
                      borderRadius: BorderRadius.all(Radius.circular(9)),
                    ),
                    child: Text(
                      count > 99 ? '99+' : '$count',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}
