import 'dart:math' as math;
import 'package:flutter/material.dart' show Offset;
import '../models/walking_recording.dart';
import 'campus_gps_service.dart';

/// Records original fixes. It does not use navigation filtering or route snapping.
class WalkingRecorder {
  static const maxAccuracy = 15.0;
  final WalkingRecording recording;
  bool running = false;
  int _segment = 0;
  WalkingSample? _last;
  DateTime? _latest;
  WalkingRecorder(this.recording) {
    for (final s in recording.samples) {
      if (s.segment != null) {
        _segment = math.max(_segment, s.segment!);
      }
      if (s.received.difference(s.timestamp).inMilliseconds >= -2000 &&
          (_latest == null || s.timestamp.isAfter(_latest!))) {
        _latest = s.timestamp;
      }
    }
  }
  // Retained for the screen's existing checks; there is no reading-count limit.
  bool get full => false;
  void resume() {
    if (recording.finished || running) {
      return;
    }
    _segment++;
    _last = null;
    running = true;
  }

  void pause() {
    running = false;
    _last = null;
  }

  void finish() {
    pause();
    recording.finished = true;
  }

  void _breakSegment() {
    if (_last != null) {
      _segment++;
    }
    _last = null;
  }

  WalkingSample? add({
    required DateTime timestamp,
    required DateTime received,
    required double latitude,
    required double longitude,
    required double accuracy,
    required double speed,
    required double heading,
    required Offset raw,
    bool mocked = false,
  }) {
    if (!running) {
      return null;
    }
    var reason = 'accepted';
    final age = received.difference(timestamp).inMilliseconds;
    if (!latitude.isFinite ||
        !longitude.isFinite ||
        latitude < -90 ||
        latitude > 90 ||
        longitude < -180 ||
        longitude > 180 ||
        !raw.dx.isFinite ||
        !raw.dy.isFinite) {
      reason = 'invalid_coordinates';
    } else if (_latest != null && !timestamp.isAfter(_latest!)) {
      reason = 'duplicate_or_out_of_order';
    } else if (age > 10000 || age < -2000) {
      reason = 'stale_timestamp';
    } else if (!accuracy.isFinite || accuracy <= 0 || accuracy > maxAccuracy) {
      reason = 'poor_accuracy';
    } else if (raw.dx < 0 || raw.dx > 3000 || raw.dy < 0 || raw.dy > 3000) {
      reason = 'outside_map';
    }
    if (age >= -2000 && (_latest == null || timestamp.isAfter(_latest!))) {
      _latest = timestamp;
    }
    final previous = _last;
    if (reason == 'accepted' && previous != null) {
      final seconds =
          timestamp.difference(previous.timestamp).inMilliseconds / 1000.0;
      if (seconds > 10) {
        _breakSegment(); // Never bridge a missing-GPS interval.
      } else {
        final metres = CampusGpsService.mapDistanceMeters(raw, previous.raw);
        if (metres > math.max(12.0, seconds * 3.0 + 5.0)) {
          reason = 'gps_jump';
        }
      }
    }
    if (reason != 'accepted' && reason != 'duplicate_or_out_of_order') {
      _breakSegment();
    }
    final accepted = reason == 'accepted';
    final smooth = !accepted
        ? null
        : _last == null
        ? raw
        : Offset.lerp(_last!.smooth, raw, 0.65)!;
    final sample = WalkingSample(
      timestamp: timestamp,
      received: received,
      latitude: latitude,
      longitude: longitude,
      accuracy: accuracy,
      speed: speed,
      heading: heading,
      raw: raw,
      mocked: mocked,
      segment: accepted ? _segment : null,
      smooth: smooth,
      reason: reason,
    );
    recording.samples.add(sample);
    if (accepted) {
      _last = sample;
    }

    return sample;
  }
}
