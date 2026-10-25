import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/features/bc_ways/models/walking_recording.dart';
import 'package:frontend/features/bc_ways/services/walking_recorder.dart';
import 'package:frontend/features/bc_ways/services/walking_recording_export.dart';

final epoch = DateTime.utc(2026, 10, 21, 8);
WalkingRecorder recorder() => WalkingRecorder(
  WalkingRecording(
    started: epoch,
    calibration: {'width': 3000, 'height': 3000},
  ),
);
WalkingSample? fix(
  WalkingRecorder r,
  int seconds, {
  double x = 1000,
  double y = 1000,
  double accuracy = 5,
  int delay = 0,
}) => r.add(
  timestamp: epoch.add(Duration(seconds: seconds)),
  received: epoch.add(Duration(seconds: seconds + delay)),
  latitude: -25.682,
  longitude: 28.131,
  accuracy: accuracy,
  speed: 1,
  heading: 90,
  raw: Offset(x, y),
);

void main() {
  test(
    'original coordinates are kept separately from the smoothed reference',
    () {
      final r = recorder()..resume();
      fix(r, 0);
      final second = fix(r, 1, x: 1010)!;
      expect(second.raw, const Offset(1010, 1000));
      expect(second.smooth!.dx, closeTo(1006.5, 0.00001));
      expect(second.smooth!.dy, 1000);
    },
  );

  test('pause records nothing and resume never connects distant paths', () {
    final r = recorder()..resume();
    fix(r, 0);
    r.pause();
    expect(fix(r, 1), isNull);
    r.resume();
    fix(r, 2, x: 2000);
    expect(r.recording.samples.length, 2);
    expect(r.recording.segments.length, 2);
    expect(r.recording.samples.last.smooth, const Offset(2000, 1000));
  });

  test('poor accuracy is retained in CSV and breaks the drawn trail', () {
    final r = recorder()..resume();
    fix(r, 0);
    final bad = fix(r, 1, accuracy: 35)!;
    fix(r, 2, x: 1010);
    expect(bad.accepted, isFalse);
    expect(bad.reason, 'poor_accuracy');
    expect(r.recording.acceptedCount, 2);
    expect(r.recording.segments.length, 2);
    final csv = WalkingRecordingExport.csv(r.recording);
    expect(csv, contains('"poor_accuracy"'));
    expect(csv, contains('"35.0000"'));
    expect(csv.trim().split('\n').length, 4);
  });

  test('duplicate timestamps do not add a line or break a valid segment', () {
    final r = recorder()..resume();
    fix(r, 0);
    expect(fix(r, 0)!.reason, 'duplicate_or_out_of_order');
    fix(r, 1, x: 1005);
    expect(r.recording.acceptedCount, 2);
    expect(r.recording.segments.length, 1);
  });

  test('stale fixes, out of bounds and walking jumps are excluded', () {
    final r = recorder()..resume();
    expect(fix(r, 0, delay: 11)!.reason, 'stale_timestamp');
    expect(fix(r, 1, x: -1)!.reason, 'outside_map');
    fix(r, 2);
    expect(fix(r, 3, x: 2000)!.reason, 'gps_jump');
    fix(r, 4, x: 1005);
    expect(r.recording.segments.length, 2);
  });

  test('a long GPS gap begins a separate path', () {
    final r = recorder()..resume();
    fix(r, 0);
    fix(r, 15, x: 1010);
    expect(r.recording.segments.length, 2);
  });

  test('draft round trip retains readings and restores paused', () {
    final r = recorder()..resume();
    fix(r, 0);
    fix(r, 1, accuracy: double.nan);
    final restored = WalkingRecorder(
      WalkingRecording.fromJson(r.recording.toJson()),
    );
    expect(restored.running, isFalse);
    expect(restored.recording.samples.length, 2);
    expect(restored.recording.samples.last.accuracy.isNaN, isTrue);
    restored.resume();
    fix(restored, 2);
    expect(restored.recording.segments.length, 2);
  });

  test('finished recordings cannot resume and stay finished after restore', () {
    final r = recorder()..resume();
    fix(r, 0);
    r.finish();
    final restored = WalkingRecorder(
      WalkingRecording.fromJson(r.recording.toJson()),
    );
    restored.resume();
    expect(restored.running, isFalse);
    expect(fix(restored, 1), isNull);
  });

  test('SVG preserves the full canvas and keeps paused paths separate', () {
    final r = recorder()..resume();
    fix(r, 0);
    fix(r, 1, x: 1005);
    r.pause();
    r.resume();
    fix(r, 2, x: 2000);
    fix(r, 3, x: 2005);
    final svg = WalkingRecordingExport.svg(r.recording);
    expect(svg, contains('width="3000" height="3000" viewBox="0 0 3000 3000"'));
    expect(svg, contains('alignment-guides-delete-after-alignment'));
    expect(svg, contains('id="accepted-raw-gps"'));
    expect(svg, contains('id="smoothed-reference"'));
    expect('<path '.allMatches(svg).length, 4);
    expect(svg, contains('M 2000.0000 1000.0000 L 2005.0000 1000.0000'));
  });

  test('a rejected future timestamp does not poison a restored recording', () {
    final r = recorder()..resume();
    expect(fix(r, 100, delay: -100)!.reason, 'stale_timestamp');
    final restored = WalkingRecorder(
      WalkingRecording.fromJson(r.recording.toJson()),
    );
    restored.resume();
    expect(fix(restored, 1)!.accepted, isTrue);
  });

  test('recording continues beyond 5000 readings and after restoring', () {
    final r = recorder()..resume();
    for (var i = 0; i < 6000; i++) {
      fix(r, i);
    }

    expect(r.recording.samples.length, 6000);
    expect(r.recording.acceptedCount, 6000);
    expect(r.full, isFalse);
    expect(r.running, isTrue);

    r.pause();
    expect(fix(r, 6000), isNull);
    r.resume();
    expect(fix(r, 6001)!.accepted, isTrue);

    final restored = WalkingRecorder(
      WalkingRecording.fromJson(r.recording.toJson()),
    );
    expect(restored.recording.samples.length, 6001);
    expect(restored.running, isFalse);
    expect(restored.full, isFalse);

    restored.resume();
    expect(fix(restored, 6002)!.accepted, isTrue);
    expect(restored.recording.samples.length, 6002);
    expect(restored.running, isTrue);
  });
}
