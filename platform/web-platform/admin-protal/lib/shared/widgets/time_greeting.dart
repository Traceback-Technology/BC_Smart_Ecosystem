import 'dart:async';
import 'package:flutter/material.dart';

String greetingFor(DateTime time) {
  if (time.hour >= 5 && time.hour < 12) return 'Good morning';
  if (time.hour >= 12 && time.hour < 17) return 'Good afternoon';
  return 'Good evening';
}

/// Uses local device time, including when returning from the background.
class TimeGreeting extends StatefulWidget {
  final TextStyle? style;
  const TimeGreeting({super.key, this.style});
  @override
  State<TimeGreeting> createState() => _TimeGreetingState();
}

class _TimeGreetingState extends State<TimeGreeting> with WidgetsBindingObserver {
  Timer? _timer;
  String _greeting = greetingFor(DateTime.now());

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _timer = Timer.periodic(const Duration(minutes: 1), (_) => _refresh());
  }

  void _refresh() {
    final next = greetingFor(DateTime.now());
    if (next != _greeting && mounted) setState(() => _greeting = next);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _refresh();
  }

  @override
  void dispose() {
    _timer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Text(_greeting, style: widget.style);
}
