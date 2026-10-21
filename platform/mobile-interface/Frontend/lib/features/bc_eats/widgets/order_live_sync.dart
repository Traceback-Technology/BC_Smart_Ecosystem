import 'dart:async';
import 'package:flutter/widgets.dart';
import '../services/bc_eats_store.dart';

/// Invisible widget that polls the backend for [order]'s saved status while it
/// is on screen. Stops doing work once the order is completed or cancelled.
/// STEP 3: replace polling with the live telemetry/WebSocket feed if needed.
class OrderLiveSync extends StatefulWidget {
  final EatsOrder order;
  final Duration interval;
  const OrderLiveSync({super.key, required this.order, this.interval = const Duration(seconds: 8)});

  @override
  State<OrderLiveSync> createState() => _OrderLiveSyncState();
}

class _OrderLiveSyncState extends State<OrderLiveSync> {
  Timer? _timer;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(widget.interval, (_) => _tick());
  }

  Future<void> _tick() async {
    final order = widget.order;
    if (_busy || !order.isBackendOrder || order.completed) return;
    _busy = true;
    try {
      await BcEatsStore.instance.refreshBackendOrder(order);
    } catch (_) {
      // Best effort: the next tick (or the manual refresh button) retries.
    } finally {
      _busy = false;
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => const SizedBox.shrink();
}
