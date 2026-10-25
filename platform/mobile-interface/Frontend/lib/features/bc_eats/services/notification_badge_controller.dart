import 'dart:async';
import 'package:flutter/foundation.dart';
import 'notification_service.dart';

/// Holds the unread-notification count for the bell badge.
/// One shared instance, so every screen shows the same number.
class NotificationBadgeController extends ChangeNotifier {
  NotificationBadgeController._();
  static final NotificationBadgeController instance =
      NotificationBadgeController._();

  static const Duration _interval = Duration(seconds: 60);

  int _unreadCount = 0;
  Timer? _timer;
  bool _active = false;

  int get unreadCount => _unreadCount;

  /// Call when a REGISTERED user is signed in. Guests get a 403 from
  /// the notification routes, so never start this for a guest.
  void start() {
    if (_active) return;
    _active = true;
    refresh();
    _timer = Timer.periodic(_interval, (_) => refresh());
  }

  /// Call on sign-out, or when the session is a guest.
  void stop() {
    _active = false;
    _timer?.cancel();
    _timer = null;
    if (_unreadCount != 0) {
      _unreadCount = 0;
      notifyListeners();
    }
  }

  Future<void> refresh() async {
    if (!_active) return;
    try {
      final count = await NotificationService.instance.fetchUnreadCount();
      if (!_active) return; // signed out while the request was in flight
      if (count != _unreadCount) {
        _unreadCount = count;
        notifyListeners();
      }
    } catch (_) {
      // Ignore. The free-tier backend may be waking up; the next tick retries.
    }
  }

  /// Lets the notifications screen update the badge immediately after
  /// marking items as read, without waiting for the next refresh.
  void setCount(int count) {
    if (count == _unreadCount) return;
    _unreadCount = count < 0 ? 0 : count;
    notifyListeners();
  }
}
