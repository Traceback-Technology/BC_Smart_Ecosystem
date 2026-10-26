import 'package:flutter/material.dart';

/// Shared display helpers for notifications, so the full notifications
/// screen and the home-screen preview show the same icon and time label.

IconData notificationIcon(String type) {
  switch (type) {
    case 'order':
      return Icons.receipt_long_outlined;
    case 'payment':
      return Icons.payments_outlined;
    case 'drone':
      return Icons.flight_outlined;
    case 'promotion':
      return Icons.local_offer_outlined;
    default:
      return Icons.info_outline;
  }
}

String notificationTimeAgo(DateTime t) {
  final d = DateTime.now().difference(t);
  if (d.inMinutes < 1) return 'Just now';
  if (d.inMinutes < 60) return '${d.inMinutes} min ago';
  if (d.inHours < 24) return '${d.inHours} h ago';
  if (d.inDays < 7) return '${d.inDays} d ago';
  return '${t.day}/${t.month}/${t.year}';
}
