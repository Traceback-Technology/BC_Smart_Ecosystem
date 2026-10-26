import '../../../core/bc_api_client.dart';
import '../models/app_notification.dart';

/// Talks to /api/notifications through the shared BcAPIClient, so the
/// base URL, auth token and error handling are the same as everywhere else.

class NotificationService {
  NotificationService._();
  static final NotificationService instance = NotificationService._();

  final BcApiClient _api = BcApiClient.instance;

  Future<List<AppNotification>> fetchNotifications({int limit = 30}) async {
    final res = await _api.getJson(
      'api/notification',
      query: {'limit': '$limit'},
    );
    final list = res['data'] as List? ?? const [];
    return list
        .whereType<Map>()
        .map((e) => AppNotification.fromjson(Map<String, dynamic>.from(e)))
        .toList();
  }

  Future<int> fetchUnreadCount() async {
    final res = await _api.getJson('/api/notifications/unread-count');
    return (res['count'] as num?)?.toInt() ?? 0; // 0;
  }

  Future<void> markRead(String id) async {
    await _api.patchJson('/api/notifications/$id/read', {});
  }

  Future<void> markAllRead() async {
    await _api.patchJson('/api/notifications/read-all', {});
  }
}
