import 'package:flutter/material.dart';
import '../../bc_ways/constants/colors.dart';
import '../constants/bc_eats_colors.dart';
import '../models/app_notification.dart';
import '../models/notification_display.dart';
import '../services/notification_badge_controller.dart';
import '../services/notification_service.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  final _service = NotificationService.instance;
  final _badge = NotificationBadgeController.instance;

  List<AppNotification> _items = [];
  bool _loading = true;
  bool _failed = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = _items.isEmpty; // keep the list visible during pull-to-refresh
      _failed = false;
    });
    try {
      final items = await _service.fetchNotifications();
      if (!mounted) return;
      setState(() {
        _items = items;
        _loading = false;
      });
      _badge.refresh(); // keep the bell badge in step with the server
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _failed = _items.isEmpty;
      });
      if (_items.isNotEmpty) _snack('Could not refresh notifications.');
    }
  }

  // Marks one notification as read. The screen updates instantly
  // (optimistic update) and is rolled back if the server call fails.
  Future<void> _open(AppNotification n) async {
    if (n.isRead) return;
    final index = _items.indexWhere((e) => e.id == n.id);
    if (index == -1) return;
    setState(() => _items[index] = n.copyWith(isRead: true));
    _badge.setCount(_badge.unreadCount - 1);
    try {
      await _service.markRead(n.id);
    } catch (_) {
      if (!mounted) return;
      final i = _items.indexWhere((e) => e.id == n.id);
      if (i != -1) setState(() => _items[i] = n);
      _snack('Could not update that notification.');
    } finally {
      _badge.refresh();
    }
  }

  Future<void> _markAllRead() async {
    if (!_items.any((e) => !e.isRead)) return;
    final before = _items;
    setState(() {
      _items = _items.map((e) => e.copyWith(isRead: true)).toList();
    });
    _badge.setCount(0);
    try {
      await _service.markAllRead();
    } catch (_) {
      if (!mounted) return;
      setState(() => _items = before);
      _snack('Could not mark all as read.');
    } finally {
      _badge.refresh();
    }
  }

  void _snack(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final hasUnread = _items.any((e) => !e.isRead);
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(6, 10, 12, 6),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.of(context).maybePop(),
                    icon: const Icon(Icons.arrow_back, size: 28),
                  ),
                  Expanded(
                    child: Text(
                      'Notifications',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                        color: context.textPrimary,
                      ),
                    ),
                  ),
                  TextButton(
                    onPressed: hasUnread ? _markAllRead : null,
                    child: const Text('Mark all read'),
                  ),
                ],
              ),
            ),
            Expanded(child: _body()),
          ],
        ),
      ),
    );
  }

  Widget _body() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_failed) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.cloud_off_outlined,
                size: 48,
                color: context.textSecondary,
              ),
              const SizedBox(height: 12),
              Text(
                'Could not load notifications.\nThe server may be waking up, so try again in a moment.',
                textAlign: TextAlign.center,
                style: TextStyle(color: context.textSecondary),
              ),
              const SizedBox(height: 12),
              OutlinedButton(onPressed: _load, child: const Text('Retry')),
            ],
          ),
        ),
      );
    }

    if (_items.isEmpty) {
      return RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: [
            const SizedBox(height: 120),
            Icon(
              Icons.notifications_none,
              size: 56,
              color: context.textSecondary,
            ),
            const SizedBox(height: 12),
            Text(
              'No notifications yet',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16, color: context.textSecondary),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _load,
      child: ListView.separated(
        physics: const AlwaysScrollableScrollPhysics(),
        itemCount: _items.length,
        separatorBuilder: (_, _) => const Divider(height: 1),
        itemBuilder: (context, i) {
          final n = _items[i];
          return ListTile(
            onTap: () => _open(n),
            leading: CircleAvatar(
              backgroundColor: BcEatsColors.red.withValues(alpha: 0.12),
              child: Icon(notificationIcon(n.type), color: BcEatsColors.red),
            ),
            title: Text(
              n.title,
              style: TextStyle(
                fontWeight: n.isRead ? FontWeight.w500 : FontWeight.w800,
                color: context.textPrimary,
              ),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(n.message, style: TextStyle(color: context.textSecondary)),
                const SizedBox(height: 4),
                Text(
                  notificationTimeAgo(n.createdAt),
                  style: TextStyle(fontSize: 12, color: context.textSecondary),
                ),
              ],
            ),
            trailing: n.isRead
                ? null
                : Container(
                    width: 10,
                    height: 10,
                    decoration: const BoxDecoration(
                      color: BcEatsColors.red,
                      shape: BoxShape.circle,
                    ),
                  ),
          );
        },
      ),
    );
  }
}
