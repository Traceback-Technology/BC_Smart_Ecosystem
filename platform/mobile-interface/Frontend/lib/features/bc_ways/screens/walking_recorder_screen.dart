import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:geolocator/geolocator.dart' as geo;
import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/walking_recording.dart';
import '../services/campus_gps_service.dart';
import '../services/walking_recorder.dart';
import '../services/walking_recording_export.dart';

class WalkingRecorderScreen extends StatefulWidget {
  const WalkingRecorderScreen({super.key});
  @override
  State<WalkingRecorderScreen> createState() => _WalkingRecorderScreenState();
}

class _WalkingRecorderScreenState extends State<WalkingRecorderScreen>
    with WidgetsBindingObserver {
  static const _draftKey = 'bc_ways_walking_recording_v1';
  final _transform = TransformationController();
  final _gps = const CampusGpsService();
  StreamSubscription<geo.Position>? _subscription;
  Timer? _saveTimer;
  SharedPreferences? _prefs;
  WalkingRecorder? _recorder;
  geo.Position? _fix;
  Offset? _rawPosition;
  Size _viewport = Size.zero;
  Future<void> _saveQueue = Future<void>.value();
  bool _loading = true, _connecting = false, _sharing = false;
  bool _follow = true, _canPop = false, _leaving = false;
  bool _showSmoothed = false;
  String? _error, _saveError;
  String _status = 'Waiting for GPS. Keep the screen open while walking.';
  DateTime? _savedAt;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initialise();
  }

  Future<void> _initialise() async {
    try {
      _prefs = await SharedPreferences.getInstance();
      final stored = _prefs!.getString(_draftKey);
      if (stored != null) {
        _recorder = WalkingRecorder(WalkingRecording.fromJson(stored));
        _status = _recorder!.recording.finished
            ? 'Finished recording restored. Export it or start a new one.'
            : 'Previous recording restored and paused. Resume to add a new path.';
      }
    } catch (_) {
      _saveError = 'Could not restore the previous recording. Starting a new one will replace it.';
    }
    if (!mounted) { return; }
    setState(() => _loading = false);
    _saveTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      if (_recorder?.running == true) { unawaited(_save()); }
    });
    await _connectGps();
  }

  Future<void> _connectGps() async {
    if (_connecting) { return; }
    setState(() { _connecting = true; _error = null; });
    try {
      if (!await geo.Geolocator.isLocationServiceEnabled()) {
        throw Exception('Turn on Location on your phone, then tap Retry GPS.');
      }
      var permission = await geo.Geolocator.checkPermission();
      if (permission == geo.LocationPermission.denied) {
        permission = await geo.Geolocator.requestPermission();
      }
      if (permission == geo.LocationPermission.deniedForever) {
        throw Exception('Location permission is blocked. Enable it in your phone settings.');
      }
      if (permission == geo.LocationPermission.denied) {
        throw Exception('Location permission is needed to record a path.');
      }
      if (!mounted) { return; }
      await _subscription?.cancel();
      if (!mounted) { return; }
      final geo.LocationSettings settings = !kIsWeb && defaultTargetPlatform == TargetPlatform.android
          ? geo.AndroidSettings(accuracy: geo.LocationAccuracy.bestForNavigation,
              distanceFilter: 0, intervalDuration: const Duration(seconds: 1))
          : const geo.LocationSettings(accuracy: geo.LocationAccuracy.bestForNavigation, distanceFilter: 0);
      _subscription = geo.Geolocator.getPositionStream(locationSettings: settings).listen(
        _onFix, onError: (Object error) {
          if (!mounted) { return; }
          _recorder?.pause();
          setState(() { _error = 'GPS stopped: $error'; _status = 'Recording paused. Retry GPS, then resume.'; });
          unawaited(_save());
        }, onDone: () {
          if (!mounted) { return; }
          _recorder?.pause();
          setState(() => _error = 'GPS stream ended. Tap Retry GPS.');
          unawaited(_save());
        });
    } catch (e) {
      if (mounted) { setState(() => _error = e.toString()); }
    } finally {
      if (mounted) { setState(() => _connecting = false); }
    }
  }

  void _onFix(geo.Position fix) {
    if (!mounted) { return; }
    final raw = _gps.toMapOffset(fix);
    final sample = _recorder?.add(timestamp: fix.timestamp, received: DateTime.now(),
      latitude: fix.latitude, longitude: fix.longitude, accuracy: fix.accuracy,
      speed: fix.speed, heading: fix.heading, raw: raw, mocked: fix.isMocked);
    setState(() {
      _fix = fix;
      if (raw.dx.isFinite && raw.dy.isFinite) { _rawPosition = raw; }
      if (sample != null) {
        _status = sample.accepted ? 'Recording. Snapping is OFF.'
            : 'Fix kept in CSV only: ${sample.reason.replaceAll('_', ' ')}.';
      }
      if (_recorder?.full == true) { _status = 'Recording limit reached. Finish and export before starting another.'; }
    });
    if (_follow) { _center(); }
  }

  void _center() {
    final p = _rawPosition;
    if (p == null || _viewport.isEmpty || !_gps.isInsideMapCanvas(p)) { return; }
    final scale = _transform.value.getMaxScaleOnAxis().clamp(0.15, 4.0).toDouble();
    _transform.value = Matrix4.identity()
      ..translateByDouble(_viewport.width / 2 - p.dx * scale,
          _viewport.height / 2 - p.dy * scale, 0, 1)
      ..scaleByDouble(scale, scale, 1, 1);
  }

  Future<void> _save() {
    final recorder = _recorder;
    if (recorder == null) { return Future<void>.value(); }
    final snapshot = recorder.recording.toJson();
    _saveQueue = _saveQueue.then((_) async {
      try {
        _prefs ??= await SharedPreferences.getInstance();
        final ok = await _prefs!.setString(_draftKey, snapshot);
        if (!ok) { throw StateError('Save was not accepted'); }
        if (mounted) { setState(() { _saveError = null; _savedAt = DateTime.now(); }); }
      } catch (_) {
        if (mounted) { setState(() => _saveError = 'Draft could not be saved. Export before leaving this screen.'); }
      }
    });
    return _saveQueue;
  }

  Future<bool> _confirmNew() async {
    if (_recorder == null && _saveError == null) { return true; }
    return await showDialog<bool>(context: context, builder: (context) => AlertDialog(
      title: const Text('Start a new recording?'),
      content: const Text('This replaces the saved recording. Export the current SVG and CSV first if you need them.'),
      actions: [TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Keep current')),
        FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Start new'))],
    )) ?? false;
  }

  Future<void> _startNew() async {
    if (!await _confirmNew() || !mounted) { return; }
    setState(() {
      _recorder = WalkingRecorder(WalkingRecording(started: DateTime.now(),
        calibration: CampusGpsService.recordingCalibration));
      _recorder!.resume();
      _status = 'Recording. Wait for fresh GPS fixes before walking.';
      _follow = true;
    });
    await _save();
  }
  Future<void> _pause() async {
    setState(() { _recorder?.pause(); _status = 'Paused. Resume starts a separate path.'; });
    await _save();
  }
  void _resume() {
    setState(() { _recorder?.resume(); _status = 'Recording a new path. Snapping is OFF.'; });
  }
  Future<void> _finish() async {
    setState(() { _recorder?.finish(); _status = 'Finished. Export SVG for Figma and CSV for the GPS readings.'; });
    await _save();
  }

  Future<void> _export(bool svg, BuildContext buttonContext) async {
    final r = _recorder?.recording;
    if (r == null || _sharing) { return; }
    final box = buttonContext.findRenderObject() as RenderBox?;
    final origin = box == null ? null : box.localToGlobal(Offset.zero) & box.size;
    setState(() => _sharing = true);
    try {
      final value = svg ? WalkingRecordingExport.svg(r) : WalkingRecordingExport.csv(r);
      final name = '${r.fileStem}.${svg ? 'svg' : 'csv'}';
      await SharePlus.instance.share(ShareParams(
        title: svg ? 'Walking paths for Figma' : 'Original GPS readings',
        files: [XFile.fromData(utf8.encode(value), mimeType: svg ? 'image/svg+xml' : 'text/csv')],
        fileNameOverrides: [name], sharePositionOrigin: origin));
      // Opening/dismissing a share sheet is not proof a file was saved.
      if (mounted) { setState(() => _status = 'Export opened. Check the chosen destination for your file. Your draft is kept.'); }
    } catch (e) {
      if (mounted) { ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Export failed: $e'))); }
    } finally {
      if (mounted) { setState(() => _sharing = false); }
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed && _recorder?.running == true) {
      _recorder!.pause();
      if (mounted) { setState(() => _status = 'Paused because the app was interrupted. Resume when ready.'); }
      unawaited(_save());
    }
  }
  Future<void> _leave() async {
    if (_leaving) { return; }
    _leaving = true;
    _recorder?.pause();
    await _save();
    if (!mounted) { return; }
    if (_saveError != null && _recorder != null) {
      _leaving = false;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Draft save failed. Export your files before leaving.')));
      // The back gesture is not trapped: explicit discard is offered.
      final leave = await showDialog<bool>(context: context, builder: (context) => AlertDialog(
        title: const Text('Leave without saving the draft?'),
        content: const Text('Any unsaved readings will be lost. Stay here to export them.'),
        actions: [TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Stay')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Leave'))]));
      if (leave != true || !mounted) { return; }
    }
    setState(() => _canPop = true);
    WidgetsBinding.instance.addPostFrameCallback((_) { if (mounted) { Navigator.of(context).pop(); } });
  }
  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _saveTimer?.cancel();
    _subscription?.cancel();
    _transform.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final recorder = _recorder;
    final recording = recorder?.recording;
    final running = recorder?.running == true;
    final canResume = recorder != null && !recording!.finished && !recorder.full;
    final scheme = Theme.of(context).colorScheme;
    final fresh = _fix != null && DateTime.now().difference(_fix!.timestamp).inSeconds <= 10;
    final accuracy = _fix?.accuracy;
    return PopScope(canPop: _canPop, onPopInvokedWithResult: (didPop, result) {
      if (!didPop) { unawaited(_leave()); }
    }, child: Scaffold(
      appBar: AppBar(title: const Text('Record walking path'), actions: [
        IconButton(tooltip: 'Recorder help', icon: const Icon(Icons.help_outline), onPressed: () => showDialog<void>(
          context: context, builder: (context) => AlertDialog(title: const Text('Walk, record, compare'),
            content: const SingleChildScrollView(child: Text('Route snapping is off here. Orange shows accepted original GPS fixes; blue is a smoothed reference.\n\nPause before moving to another path, then Resume. Poor fixes and gaps break the trail instead of drawing a false connecting line.\n\nKeep this screen open and the phone unlocked. Switching apps or locking the phone pauses recording.\n\nFinish, then export both files. Import the SVG at 3000 × 3000 in Figma and align its top-left corner with your map. Do not scale it to fit the visible trail. Hide the alignment guides after placing it.\n\nWalk each path more than once. GPS traces are not ground truth. Update graph nodes and edges separately after checking calibration.')),
            actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('Got it'))])))
      ]),
      body: _loading ? const Center(child: CircularProgressIndicator()) : SafeArea(child: LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxHeight < 540;
          return Column(children: [
            Expanded(child: LayoutBuilder(builder: (context, mapConstraints) {
              final first = _viewport.isEmpty;
              _viewport = mapConstraints.biggest;
              if (first) { WidgetsBinding.instance.addPostFrameCallback((_) {
                if (!mounted) { return; }
                final scale = (_viewport.shortestSide / 3000).clamp(0.15, 0.7).toDouble();
                _transform.value = Matrix4.diagonal3Values(scale, scale, 1);
                if (_follow) { _center(); }
              }); }
              return Stack(children: [
                ClipRect(child: InteractiveViewer(transformationController: _transform,
                  constrained: false, minScale: 0.1, maxScale: 4,
                  boundaryMargin: const EdgeInsets.all(3000),
                  onInteractionStart: (_) => setState(() => _follow = false),
                  child: SizedBox(width: 3000, height: 3000, child: Stack(children: [
                    Positioned.fill(child: SvgPicture.asset(
                      Theme.of(context).brightness == Brightness.dark ? 'assets/bc_ways/map/campus_2.svg' : 'assets/bc_ways/map/campus.svg', fit: BoxFit.fill)),
                    Positioned.fill(child: IgnorePointer(child: CustomPaint(painter: _WalkingTrailPainter(
                      segments: recording?.segments.values.toList() ?? [], position: _rawPosition,
                      showSmoothed: _showSmoothed))))
                  ])))),
                Positioned(top: 8, left: 8, child: Chip(label: Text(running ? 'RECORDING • SNAP OFF' : 'SNAP OFF'))),
                Positioned(right: 12, bottom: 12, child: FloatingActionButton.small(
                  heroTag: 'walking-recorder-center', tooltip: 'Follow GPS',
                  onPressed: () { setState(() => _follow = true); _center(); },
                  child: Icon(_follow ? Icons.my_location : Icons.location_searching)))
              ]);
            })),
            ConstrainedBox(constraints: BoxConstraints(maxHeight: compact ? constraints.maxHeight * 0.55 : 310),
              child: SingleChildScrollView(padding: const EdgeInsets.fromLTRB(16, 10, 16, 12), child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                  Text(accuracy == null ? 'Waiting for GPS...' : 'GPS accuracy: ±${accuracy.toStringAsFixed(1)} m${fresh ? '' : ' • stale fix'}',
                    style: TextStyle(fontWeight: FontWeight.bold,
                      color: fresh && accuracy != null && accuracy <= 15 ? scheme.primary : scheme.error)),
                  const SizedBox(height: 4),
                  Text(_status),
                  Text('${recording?.acceptedCount ?? 0} accepted / ${recording?.samples.length ?? 0} readings • ${recording?.segments.length ?? 0} paths', style: Theme.of(context).textTheme.bodySmall),
                  SwitchListTile.adaptive(
                    contentPadding: EdgeInsets.zero,
                    dense: true,
                    title: const Text('Show smoothed reference'),
                    subtitle: const Text('Orange: original GPS. Blue: reference only.'),
                    value: _showSmoothed,
                    onChanged: (value) => setState(() => _showSmoothed = value),
                  ),
                  if (_savedAt != null) Text('Draft saved ${TimeOfDay.fromDateTime(_savedAt!).format(context)}', style: Theme.of(context).textTheme.bodySmall),
                  if (_saveError != null) Text(_saveError!, style: TextStyle(color: scheme.error)),
                  if (_error != null) Text(_error!, style: TextStyle(color: scheme.error)),
                  const SizedBox(height: 8),
                  Wrap(spacing: 8, runSpacing: 6, children: [
                    if (recorder == null || recording!.finished)
                      FilledButton.icon(onPressed: _sharing || _connecting || _error != null ? null : _startNew,
                        icon: const Icon(Icons.fiber_manual_record), label: Text(recorder == null ? 'Start' : 'New recording')),
                    if (running) FilledButton.icon(onPressed: _pause, icon: const Icon(Icons.pause), label: const Text('Pause')),
                    if (!running && canResume) FilledButton.icon(onPressed: _error != null || _sharing ? null : _resume,
                      icon: const Icon(Icons.play_arrow), label: const Text('Resume')),
                    if (recorder != null && !recording!.finished)
                      OutlinedButton(onPressed: _sharing ? null : _finish, child: const Text('Finish')),
                    if (_error != null) OutlinedButton(onPressed: _connecting ? null : _connectGps, child: const Text('Retry GPS')),
                    Builder(builder: (context) => OutlinedButton.icon(
                      onPressed: !running && (recording?.acceptedCount ?? 0) > 0 && !_sharing ? () => _export(true, context) : null,
                      icon: const Icon(Icons.ios_share), label: const Text('Export SVG'))),
                    Builder(builder: (context) => OutlinedButton.icon(
                      onPressed: !running && (recording?.samples.isNotEmpty ?? false) && !_sharing ? () => _export(false, context) : null,
                      icon: const Icon(Icons.table_view), label: const Text('Export CSV'))),
                  ]),
                ]))),
          ]);
        })),
    ));
  }
}

class _WalkingTrailPainter extends CustomPainter {
  final List<List<WalkingSample>> segments;
  final Offset? position;
  final bool showSmoothed;
  _WalkingTrailPainter({required this.segments, this.position, required this.showSmoothed});
  @override
  void paint(Canvas canvas, Size size) {
    for (final smooth in [false, if (showSmoothed) true]) {
      final paint = Paint()
        ..color = (smooth ? Colors.blue : Colors.deepOrange)
        ..strokeWidth = (smooth ? 3.0 : 6.0)
        ..style = PaintingStyle.stroke
        ..strokeJoin = StrokeJoin.round
        ..strokeCap = StrokeCap.round;
      for (final segment in segments) {
        final points = segment.map((s) => smooth ? s.smooth! : s.raw).toList();
        if (points.isEmpty) { continue; }
        if (points.length == 1) { canvas.drawCircle(points.first, 4, paint); continue; }
        final path = Path()..moveTo(points.first.dx, points.first.dy);
        for (final p in points.skip(1)) { path.lineTo(p.dx, p.dy); }
        canvas.drawPath(path, paint);
      }
    }
    if (position != null) {
      canvas.drawCircle(position!, 14, Paint()..color = Colors.white);
      canvas.drawCircle(position!, 10, Paint()..color = Colors.deepOrange);
    }
  }
  @override
  bool shouldRepaint(covariant _WalkingTrailPainter oldDelegate) => true;
}
