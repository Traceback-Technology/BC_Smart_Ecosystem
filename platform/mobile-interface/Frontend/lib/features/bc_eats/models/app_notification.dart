// One notification as returned by GET /api/notifications.
// Named AppNotification because Flutter already has a built-in
// class called Notification, and the two would clash.

class AppNotification {
  final String id;
  final String title;
  final String message;
  final String type; // order, promotion, system, payment, drone
  final bool isRead;
  final DateTime createdAt;
  final Map<String, dynamic> metadata; // e.g. orderId, status

  const AppNotification({
    required this.id,
    required this.title,
    required this.message,
    required this.type,
    required this.isRead,
    required this.createdAt,
    required this.metadata,
  });

  factory AppNotification.fromjson(Map<String, dynamic> json) {
    return AppNotification(
      id: json['_id']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      message: json['message']?.toString() ?? '',
      type: json['type']?.toString() ?? 'system',
      isRead: json['isRead'] == true,
      createdAt:
          DateTime.tryParse(json['createdAt']?.toString() ?? '')?.toLocal() ??
          DateTime.now(),
      metadata: json['metadata'] is Map
          ? Map<String, dynamic>.from(json['metadata'] as Map)
          : const {},
    );
  }

  /// Returns a copy with isRead changed (used to update the list locally
  /// after marking a notification as read)
  AppNotification copyWith({bool? isRead}) => AppNotification(
    id: id,
    title: title,
    message: message,
    type: type,
    isRead: isRead ?? this.isRead,
    createdAt: createdAt,
    metadata: metadata,
  );
}
