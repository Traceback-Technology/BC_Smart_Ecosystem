import 'package:flutter/material.dart';

import '../../bc_ways/constants/colors.dart';
import '../../bc_ways/models/route_history_entry.dart';
import '../../bc_ways/screens/route_history_screen.dart';
import '../../bc_ways/services/route_history_service.dart';
import '../../bc_ways/widgets/route_history_card.dart';

/// Home-screen section showing the most recent BC Ways routes, with a
/// "See all" button that opens the full history.
class RouteHistorySection extends StatefulWidget {
  /// Called with the destination name when a past route is tapped.
  final ValueChanged<String> onOpenRoute;

  const RouteHistorySection({super.key, required this.onOpenRoute});

  @override
  State<RouteHistorySection> createState() => _RouteHistorySectionState();
}

class _RouteHistorySectionState extends State<RouteHistorySection> {
  static const int _previewCount = 3;

  final RouteHistoryService _service = RouteHistoryService.instance;

  List<RouteHistoryEntry> _entries = const [];
  bool _loading = true;
  bool _failed = false;
  int _requestId = 0;

  @override
  void initState() {
    super.initState();

    _service.changes.addListener(_load);
    _load();
  }

  @override
  void dispose() {
    _service.changes.removeListener(_load);

    super.dispose();
  }

  Future<void> _load() async {
    if (!_service.isAvailable) {
      setState(() {
        _entries = const [];
        _loading = false;
        _failed = false;
      });

      return;
    }

    final request = ++_requestId;

    if (_entries.isEmpty) {
      setState(() {
        _loading = true;
        _failed = false;
      });
    }

    try {
      final page = await _service.fetch(limit: _previewCount);

      if (!mounted || request != _requestId) {
        return;
      }

      setState(() {
        _entries = page.entries;
        _loading = false;
        _failed = false;
      });
    } catch (_) {
      if (!mounted || request != _requestId) {
        return;
      }

      setState(() {
        _loading = false;
        _failed = true;
      });
    }
  }

  void _seeAll() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => RouteHistoryScreen(onOpenRoute: widget.onOpenRoute),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Recent routes',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: context.textPrimary,
              ),
            ),
            if (_service.isAvailable)
              InkWell(
                onTap: _seeAll,
                borderRadius: BorderRadius.circular(8),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 4,
                    vertical: 4,
                  ),
                  child: Text(
                    'See all',
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      color: context.bcColors.error,
                    ),
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 12),
        _buildBody(context),
      ],
    );
  }

  Widget _buildBody(BuildContext context) {
    if (_loading) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 24),
        child: Center(
          child: SizedBox(
            width: 22,
            height: 22,
            child: CircularProgressIndicator(strokeWidth: 2.5),
          ),
        ),
      );
    }

    if (!_service.isAvailable) {
      return const _HistoryMessage(
        icon: Icons.cloud_off_outlined,
        message: "Route history isn't available offline.",
      );
    }

    if (_failed) {
      return _HistoryMessage(
        icon: Icons.error_outline,
        message: "Couldn't load your routes.",
        actionLabel: 'Retry',
        onAction: _load,
      );
    }

    if (_entries.isEmpty) {
      return const _HistoryMessage(
        icon: Icons.alt_route,
        message: 'No routes yet. Start navigating in BC Ways and your trips '
            'will show up here.',
      );
    }

    return Column(
      children: [
        for (var i = 0; i < _entries.length; i++) ...[
          if (i > 0) const SizedBox(height: 12),
          RouteHistoryCard(
            entry: _entries[i],
            onTap: () => widget.onOpenRoute(_entries[i].destination),
          ),
        ],
      ],
    );
  }
}

class _HistoryMessage extends StatelessWidget {
  final IconData icon;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;

  const _HistoryMessage({
    required this.icon,
    required this.message,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: context.subtleBorder),
      ),
      child: Row(
        children: [
          Icon(icon, color: context.textSecondary),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: TextStyle(color: context.textSecondary, fontSize: 13),
            ),
          ),
          if (actionLabel != null)
            TextButton(onPressed: onAction, child: Text(actionLabel!)),
        ],
      ),
    );
  }
}
