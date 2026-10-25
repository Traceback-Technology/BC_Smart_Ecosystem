import 'package:flutter/foundation.dart';

import '../../../core/bc_api_client.dart';
import '../models/route_history_entry.dart';

/// Records BC Ways navigation sessions in the backend and reads them back.
///
/// Routes are calculated on the phone (Dijkstra), so the app reports the real
/// distance and time when the user taps Start Navigation, then marks that route
/// completed (arrived) or cancelled (left early).
///
/// Writing history must never get in the way of navigation: every write is
/// best-effort and failures are ignored. Reading throws so the UI can show a
/// retry state.
class RouteHistoryService {
  RouteHistoryService._();

  static final RouteHistoryService instance = RouteHistoryService._();

  final BcApiClient _api = BcApiClient.instance;

  /// Incremented whenever history changes, so visible lists can reload.
  final ValueNotifier<int> changes = ValueNotifier<int>(0);

  /// Resolves to the server id of the route currently being navigated
  /// (null when saving failed). Null when no navigation is in progress.
  Future<String?>? _activeRoute;

  /// History needs an API token (student sign-in, or a guest API session).
  bool get isAvailable => _api.hasToken;

  /// Tell listeners to reload, e.g. once a guest API session becomes ready.
  void refresh() => changes.value++;

  void recordStart({
    required String origin,
    required String destination,
    required double distanceMeters,
    required int estimatedMinutes,
    String? originNodeId,
    String? destinationNodeId,
  }) {
    if (!isAvailable) {
      return;
    }

    _activeRoute = _create({
      'origin': origin,
      'destination': destination,
      'distanceMeters': distanceMeters,
      'estimatedMinutes': estimatedMinutes,
      if (originNodeId != null) 'originNodeId': originNodeId,
      if (destinationNodeId != null) 'destinationNodeId': destinationNodeId,
    });
  }

  Future<String?> _create(Map<String, dynamic> body) async {
    try {
      final response = await _api.postJson('/api/navigation/history', body);
      final data = response['data'];
      final id = data is Map ? data['_id']?.toString() : null;

      refresh();

      return id;
    } catch (_) {
      return null;
    }
  }

  /// The user reached the destination.
  Future<void> markCompleted() => _finish('completed');

  /// The user left navigation before arriving.
  Future<void> markCancelled() => _finish('cancelled');

  Future<void> _finish(String status) async {
    final pending = _activeRoute;

    if (pending == null) {
      return;
    }

    // One-shot: a second call (e.g. exit button then screen dispose) is a no-op.
    _activeRoute = null;

    final id = await pending;

    if (id == null) {
      return;
    }

    try {
      await _api.patchJson('/api/navigation/history/$id/status', {
        'status': status,
      });

      refresh();
    } catch (_) {
      // Best effort: the route simply stays "in progress" until the next
      // navigation starts and the server closes it.
    }
  }

  Future<RouteHistoryPage> fetch({int page = 1, int limit = 20}) async {
    final response = await _api.getJson(
      '/api/navigation/history',
      query: {'page': '$page', 'limit': '$limit'},
    );

    final rows = response['data'];
    final pagination = response['pagination'];

    final entries = <RouteHistoryEntry>[
      if (rows is List)
        for (final row in rows)
          if (row is Map<String, dynamic>) RouteHistoryEntry.fromJson(row),
    ];

    return RouteHistoryPage(
      entries: entries,
      page: page,
      hasMore: pagination is Map && pagination['hasMore'] == true,
    );
  }
}
