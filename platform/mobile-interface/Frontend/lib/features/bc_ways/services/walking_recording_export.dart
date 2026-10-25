import 'dart:convert';
import '../models/walking_recording.dart';

class WalkingRecordingExport {
  static String _xml(String s) => s.replaceAll('&', '&amp;').replaceAll('<', '&lt;')
      .replaceAll('>', '&gt;').replaceAll('"', '&quot;').replaceAll("'", '&apos;');
  static String _number(double n) => n.isFinite ? n.toStringAsFixed(4) : '';
  static String csv(WalkingRecording r) {
    final out = StringBuffer('session_utc,segment,accepted,reason,timestamp_utc,received_utc,latitude,longitude,accuracy_m,speed_mps,heading_deg,is_mocked,map_x,map_y,smoothed_x,smoothed_y\r\n');
    for (final s in r.samples) {
      final fields = <Object?>[r.started.toUtc().toIso8601String(), s.segment,
        s.accepted, s.reason, s.timestamp.toUtc().toIso8601String(),
        s.received.toUtc().toIso8601String(),
        s.latitude.isFinite ? s.latitude.toStringAsFixed(10) : '',
        s.longitude.isFinite ? s.longitude.toStringAsFixed(10) : '',
        _number(s.accuracy), _number(s.speed), _number(s.heading), s.mocked,
        _number(s.raw.dx), _number(s.raw.dy),
        s.smooth == null ? '' : _number(s.smooth!.dx),
        s.smooth == null ? '' : _number(s.smooth!.dy)];
      out.writeln(fields.map((v) => '"${(v?.toString() ?? '').replaceAll('"', '""')}"').join(','));
    }
    return out.toString();
  }
  static String svg(WalkingRecording r) {
    final out = StringBuffer('''<?xml version="1.0" encoding="UTF-8"?>
<svg xmlns="http://www.w3.org/2000/svg" width="3000" height="3000" viewBox="0 0 3000 3000">
<title>BC Ways unsnapped walking survey</title>
<desc>Orange: accepted original fixes. Blue: smoothed reference. Gaps are separate paths. All received fixes and rejection reasons are in the CSV. GPS is not surveyed ground truth.</desc>
''');
    out.writeln('<metadata>${_xml(jsonEncode({'started': r.started.toUtc().toIso8601String(), 'calibration': r.calibration, 'accuracyLimitMetres': 15, 'smoothingAlpha': 0.65}))}</metadata>');
    // Visible corner marks preserve full dimensions when Figma imports artwork.
    out.writeln('''<g id="alignment-guides-delete-after-alignment" fill="#CBD5E1">
<rect x="0" y="0" width="3" height="3"/><rect x="2997" y="0" width="3" height="3"/>
<rect x="0" y="2997" width="3" height="3"/><rect x="2997" y="2997" width="3" height="3"/>
</g>''');
    for (final smooth in [false, true]) {
      final name = smooth ? 'smoothed-reference' : 'accepted-raw-gps';
      final colour = smooth ? '#2563EB' : '#F97316';
      out.writeln('<g id="$name" fill="none" stroke="$colour" stroke-width="${smooth ? 2 : 4}" stroke-linejoin="round" stroke-linecap="round">');
      for (final entry in r.segments.entries) {
        final points = entry.value.map((s) => smooth ? s.smooth! : s.raw).toList();
        if (points.length == 1) {
          out.writeln('<circle id="$name-${entry.key}" cx="${_number(points[0].dx)}" cy="${_number(points[0].dy)}" r="3"/>');
        } else {
          final d = points.asMap().entries.map((e) => '${e.key == 0 ? 'M' : 'L'} ${_number(e.value.dx)} ${_number(e.value.dy)}').join(' ');
          out.writeln('<path id="$name-${entry.key}" d="$d"/>');
        }
      }
      out.writeln('</g>');
    }
    out.writeln('</svg>');
    return out.toString();
  }
}
