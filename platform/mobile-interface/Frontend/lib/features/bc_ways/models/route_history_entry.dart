enum RouteHistoryStatus { active, completed, cancelled }

/// One previously navigated BC Ways route, as stored by the backend.
class RouteHistoryEntry {
  final String id;
  final String origin;
  final String destination;
  final String? originNodeId;
  final String? destinationNodeId;
  final double distanceMeters;
  final int minutes;
  final RouteHistoryStatus status;
  final DateTime startedAt;
  final DateTime? endedAt;

  const RouteHistoryEntry({
    required this.id,
    required this.origin,
    required this.destination,
    required this.distanceMeters,
    required this.minutes,
    required this.status,
    required this.startedAt,
    this.originNodeId,
    this.destinationNodeId,
    this.endedAt,
  });

  factory RouteHistoryEntry.fromJson(Map<String, dynamic> json) {
    final km = (json['distanceKm'] as num?)?.toDouble() ?? 0;

    return RouteHistoryEntry(
      id: json['_id']?.toString() ?? '',
      origin: json['origin']?.toString() ?? '',
      destination: json['destination']?.toString() ?? '',
      originNodeId: json['originNodeId']?.toString(),
      destinationNodeId: json['destinationNodeId']?.toString(),
      distanceMeters: km * 1000,
      minutes: (json['estimatedMinutes'] as num?)?.round() ?? 0,
      status: _statusFrom(json['status']?.toString()),
      startedAt:
          DateTime.tryParse(json['createdAt']?.toString() ?? '')?.toLocal() ??
          DateTime.now(),
      endedAt: DateTime.tryParse(json['endedAt']?.toString() ?? '')?.toLocal(),
    );
  }

  static RouteHistoryStatus _statusFrom(String? value) {
    switch (value) {
      case 'completed':
        return RouteHistoryStatus.completed;
      case 'cancelled':
        return RouteHistoryStatus.cancelled;
      default:
        return RouteHistoryStatus.active;
    }
  }

  String get distanceLabel {
    if (distanceMeters < 1000) {
      return '${distanceMeters.round()} m';
    }

    return '${(distanceMeters / 1000).toStringAsFixed(1)} km';
  }

  String get durationLabel => '$minutes min';

  String get statusLabel {
    switch (status) {
      case RouteHistoryStatus.completed:
        return 'Completed';
      case RouteHistoryStatus.cancelled:
        return 'Not finished';
      case RouteHistoryStatus.active:
        return 'In progress';
    }
  }

  /// Friendly relative time such as "5 min ago" or "Yesterday".
  String timeAgo({DateTime? now}) {
    final current = now ?? DateTime.now();
    final difference = current.difference(startedAt);

    if (difference.inMinutes < 1) {
      return 'Just now';
    }

    if (difference.inMinutes < 60) {
      return '${difference.inMinutes} min ago';
    }

    if (difference.inHours < 24) {
      return '${difference.inHours} h ago';
    }

    final today = DateTime(current.year, current.month, current.day);
    final day = DateTime(startedAt.year, startedAt.month, startedAt.day);
    final days = today.difference(day).inDays;

    if (days == 1) {
      return 'Yesterday';
    }

    if (days < 7) {
      return '$days days ago';
    }

    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];

    return '${startedAt.day} ${months[startedAt.month - 1]} ${startedAt.year}';
  }
}

class RouteHistoryPage {
  final List<RouteHistoryEntry> entries;
  final int page;
  final bool hasMore;

  const RouteHistoryPage({
    required this.entries,
    required this.page,
    required this.hasMore,
  });
}
