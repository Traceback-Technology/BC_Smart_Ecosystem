import 'package:flutter/material.dart';

import '../constants/colors.dart';
import '../models/route_history_entry.dart';

/// A single previously navigated route. Tapping reopens it in BC Ways.
class RouteHistoryCard extends StatelessWidget {
  final RouteHistoryEntry entry;
  final VoidCallback? onTap;

  const RouteHistoryCard({super.key, required this.entry, this.onTap});

  Color get _color {
    switch (entry.status) {
      case RouteHistoryStatus.completed:
        return const Color(0xFF008579);
      case RouteHistoryStatus.cancelled:
        return const Color(0xFF9A6700);
      case RouteHistoryStatus.active:
        return const Color(0xFF1565C0);
    }
  }

  IconData get _icon {
    switch (entry.status) {
      case RouteHistoryStatus.completed:
        return Icons.check_circle_outline;
      case RouteHistoryStatus.cancelled:
        return Icons.alt_route;
      case RouteHistoryStatus.active:
        return Icons.directions_walk;
    }
  }

  @override
  Widget build(BuildContext context) {
    final accent = context.readableAccent(_color);

    return Material(
      color: context.cardBg,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
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
                child: Icon(_icon, color: accent, size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      entry.destination,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: context.textPrimary,
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'From ${entry.origin}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: context.textSecondary,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 12,
                      runSpacing: 4,
                      children: [
                        Text(
                          entry.timeAgo(),
                          style: TextStyle(
                            color: context.textSecondary,
                            fontSize: 12,
                          ),
                        ),
                        Text(
                          '${entry.distanceLabel} · ${entry.durationLabel}',
                          style: TextStyle(
                            color: context.textSecondary,
                            fontSize: 12,
                          ),
                        ),
                        Text(
                          entry.statusLabel,
                          style: TextStyle(color: accent, fontSize: 12),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right,
                color: context.textSecondary,
                size: 22,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
