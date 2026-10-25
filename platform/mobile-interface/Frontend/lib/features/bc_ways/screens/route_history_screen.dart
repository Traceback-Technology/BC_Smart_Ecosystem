import 'package:flutter/material.dart';

import '../constants/colors.dart';
import '../models/route_history_entry.dart';
import '../services/route_history_service.dart';
import '../widgets/route_history_card.dart';

/// Full BC Ways route history, newest first, loaded a page at a time.
class RouteHistoryScreen extends StatefulWidget {
  /// Called with the destination name when a past route is tapped.
  final ValueChanged<String> onOpenRoute;

  const RouteHistoryScreen({super.key, required this.onOpenRoute});

  @override
  State<RouteHistoryScreen> createState() => _RouteHistoryScreenState();
}

class _RouteHistoryScreenState extends State<RouteHistoryScreen> {
  static const int _pageSize = 20;

  final RouteHistoryService _service = RouteHistoryService.instance;
  final ScrollController _scroll = ScrollController();

  final List<RouteHistoryEntry> _entries = [];
  int _page = 0;
  bool _hasMore = true;
  bool _loading = false;
  bool _failed = false;

  @override
  void initState() {
    super.initState();

    _scroll.addListener(_onScroll);
    _loadMore();
  }

  @override
  void dispose() {
    _scroll.dispose();

    super.dispose();
  }

  void _onScroll() {
    if (_scroll.position.extentAfter < 300) {
      _loadMore();
    }
  }

  Future<void> _refresh() async {
    _entries.clear();
    _page = 0;
    _hasMore = true;
    _failed = false;

    await _loadMore();
  }

  Future<void> _loadMore() async {
    if (_loading || !_hasMore) {
      return;
    }

    if (!_service.isAvailable) {
      setState(() => _hasMore = false);

      return;
    }

    setState(() {
      _loading = true;
      _failed = false;
    });

    try {
      final page = await _service.fetch(page: _page + 1, limit: _pageSize);

      if (!mounted) {
        return;
      }

      final known = _entries.map((e) => e.id).toSet();

      setState(() {
        _entries.addAll(page.entries.where((e) => !known.contains(e.id)));
        _page = page.page;
        _hasMore = page.hasMore;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) {
        return;
      }

      setState(() {
        _loading = false;
        _failed = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Route history'),
        backgroundColor: context.cardBg,
        foregroundColor: context.textPrimary,
        elevation: 0,
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: _buildBody(context),
          ),
        ),
      ),
    );
  }

  Widget _buildBody(BuildContext context) {
    if (!_service.isAvailable) {
      return _centered(
        context,
        Icons.cloud_off_outlined,
        "Route history isn't available offline.",
      );
    }

    if (_entries.isEmpty) {
      if (_loading) {
        return const Center(child: CircularProgressIndicator());
      }

      if (_failed) {
        return _centered(
          context,
          Icons.error_outline,
          "Couldn't load your routes.",
          actionLabel: 'Retry',
          onAction: _loadMore,
        );
      }

      return _centered(
        context,
        Icons.alt_route,
        'No routes yet. Start navigating in BC Ways and your trips will '
        'show up here.',
      );
    }

    return RefreshIndicator(
      onRefresh: _refresh,
      child: ListView.separated(
        controller: _scroll,
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(20),
        itemCount: _entries.length + 1,
        separatorBuilder: (_, _) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          if (index == _entries.length) {
            return _buildFooter(context);
          }

          final entry = _entries[index];

          return RouteHistoryCard(
            entry: entry,
            onTap: () => widget.onOpenRoute(entry.destination),
          );
        },
      ),
    );
  }

  Widget _buildFooter(BuildContext context) {
    if (_loading) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 16),
        child: Center(child: CircularProgressIndicator(strokeWidth: 2.5)),
      );
    }

    if (_failed) {
      return Center(
        child: TextButton(
          onPressed: _loadMore,
          child: const Text("Couldn't load more. Tap to retry"),
        ),
      );
    }

    return const SizedBox(height: 8);
  }

  Widget _centered(
    BuildContext context,
    IconData icon,
    String message, {
    String? actionLabel,
    VoidCallback? onAction,
  }) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 40, color: context.textSecondary),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(color: context.textSecondary),
            ),
            if (actionLabel != null) ...[
              const SizedBox(height: 8),
              TextButton(onPressed: onAction, child: Text(actionLabel)),
            ],
          ],
        ),
      ),
    );
  }
}
