import 'dart:convert';
import 'package:flutter/material.dart' show Offset;

/// A sample is retained even when it cannot safely form part of a walking trail.
class WalkingSample {
  final DateTime timestamp, received;
  final double latitude, longitude, accuracy, speed, heading;
  final Offset raw;
  final bool mocked;
  final int? segment;
  final Offset? smooth;
  final String reason;
  const WalkingSample({required this.timestamp, required this.received,
    required this.latitude, required this.longitude, required this.accuracy,
    required this.speed, required this.heading, required this.raw,
    this.mocked = false, this.segment, this.smooth, this.reason = 'accepted'});
  bool get accepted => segment != null;
  Map<String, dynamic> toJson() => {
    'timestamp': timestamp.toUtc().toIso8601String(),
    'received': received.toUtc().toIso8601String(),
    'latitude': _finite(latitude), 'longitude': _finite(longitude),
    'accuracy': _finite(accuracy), 'speed': _finite(speed),
    'heading': _finite(heading), 'x': _finite(raw.dx), 'y': _finite(raw.dy),
    'mocked': mocked, 'segment': segment, 'sx': smooth?.dx, 'sy': smooth?.dy,
    'reason': reason,
  };
  static double? _finite(double v) => v.isFinite ? v : null;
  factory WalkingSample.fromJson(Map<String, dynamic> j) {
    double n(String k) => (j[k] as num?)?.toDouble() ?? double.nan;
    return WalkingSample(timestamp: DateTime.parse(j['timestamp'] as String),
      received: DateTime.parse(j['received'] as String),
      latitude: n('latitude'), longitude: n('longitude'), accuracy: n('accuracy'),
      speed: n('speed'), heading: n('heading'), raw: Offset(n('x'), n('y')),
      mocked: j['mocked'] == true, segment: j['segment'] as int?,
      smooth: j['sx'] == null ? null : Offset(n('sx'), n('sy')),
      reason: j['reason'] as String);
  }
}

class WalkingRecording {
  final DateTime started;
  final Map<String, dynamic> calibration;
  final List<WalkingSample> samples;
  bool finished;
  WalkingRecording({required this.started, required this.calibration,
    List<WalkingSample>? samples, this.finished = false}) : samples = samples ?? [];
  int get acceptedCount => samples.where((s) => s.accepted).length;
  String get fileStem => 'bc-ways-walk-${started.toUtc().toIso8601String().replaceAll(RegExp(r'[^0-9]'), '')}';
  Map<int, List<WalkingSample>> get segments {
    final result = <int, List<WalkingSample>>{};
    for (final s in samples) {
      if (s.segment != null) { result.putIfAbsent(s.segment!, () => []).add(s); }
    }
    return result;
  }
  String toJson() => jsonEncode({'version': 1,
    'started': started.toUtc().toIso8601String(), 'calibration': calibration,
    'finished': finished, 'samples': samples.map((s) => s.toJson()).toList()});
  factory WalkingRecording.fromJson(String value) {
    final j = jsonDecode(value) as Map<String, dynamic>;
    if (j['version'] != 1) { throw const FormatException('Unknown recording version'); }
    return WalkingRecording(started: DateTime.parse(j['started'] as String),
      calibration: Map<String, dynamic>.from(j['calibration'] as Map),
      finished: j['finished'] == true,
      samples: (j['samples'] as List).map((s) => WalkingSample.fromJson(
          Map<String, dynamic>.from(s as Map))).toList());
  }
}
