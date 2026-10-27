import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart' as geo;
import 'package:shared_preferences/shared_preferences.dart';

import '../constants/colors.dart';
import '../models/node.dart';
import '../services/campus_gps_service.dart';
import '../services/graph_service.dart';

class GpsCalibrationScreen extends StatefulWidget {
  const GpsCalibrationScreen({
    super.key,
  });

  @override
  State<GpsCalibrationScreen> createState() =>
      _GpsCalibrationScreenState();
}

class _GpsCalibrationScreenState
    extends State<GpsCalibrationScreen> {
  static const String _storageKey =
      'bc_ways_gps_calibration_records_v1';

  static const int _targetSamples = 12;
  static const int _bestSamplesToAverage = 8;
  static const int _nearbyLimit = 14;

  // Same linear part as CampusGpsService. These values are used ONLY to turn
  // SVG deltas into approximate metres for sorting nearby entrances. They do
  // not change the calibration data or the actual app GPS position.
  static const double _xEast = 5.14614993;
  static const double _xNorth = -0.069369885;
  static const double _yEast = 0.157409771;
  static const double _yNorth = -3.83820423;

  final GraphService _graphService =
      GraphService.instance;

  final CampusGpsService _gpsService =
      const CampusGpsService();

  final Map<String, _CalibrationRecord> _records = {};

  StreamSubscription<geo.Position>? _liveLocationSubscription;

  List<_CalibrationPoint> _points = const [];

  bool _loading = true;
  bool _showAll = false;
  bool _locationLoading = false;

  String? _recordingNodeId;
  int _samplesCollected = 0;
  String? _statusMessage;

  geo.Position? _currentPosition;

  @override
  void initState() {
    super.initState();
    _bootstrap();
  }

  @override
  void dispose() {
    _liveLocationSubscription?.cancel();
    super.dispose();
  }

  Future<void> _bootstrap() async {
    try {
      await _graphService.load();
      await _loadSavedRecords();

      _points = _buildCalibrationPoints();

      if (!mounted) return;

      setState(() {
        _loading = false;
      });

      await _startLiveLocation();
    } catch (error) {
      if (!mounted) return;

      setState(() {
        _loading = false;
        _statusMessage = error.toString();
      });
    }
  }

  // ---------------------------------------------------------------------------
  // Dynamic calibration points
  // ---------------------------------------------------------------------------

  List<_CalibrationPoint> _buildCalibrationPoints() {
    final points = _graphService.graph.nodesById.values
        .where(
          (node) =>
              node.type.toLowerCase() == 'entrance' ||
              node.type.toLowerCase() == 'gate',
        )
        .map(
          (node) => _CalibrationPoint(
            nodeId: node.id,
            label: _prettyNodeLabel(node.id),
            area: node.type.toLowerCase() == 'gate'
                ? 'Campus Gate'
                : 'Campus Entrance',
          ),
        )
        .toList();

    points.sort(
      (a, b) => a.label.compareTo(b.label),
    );

    return points;
  }

  String _prettyNodeLabel(String nodeId) {
    var text = nodeId
        .replaceAll('_entrance', ' entrance')
        .replaceAll('_gate', ' gate')
        .replaceAll('_', ' ')
        .replaceAll('-', ' ')
        .trim();

    final words = text
        .split(RegExp(r'\s+'))
        .where((word) => word.isNotEmpty)
        .map((word) {
      final lower = word.toLowerCase();

      if (lower == 'it') return 'IT';
      if (lower == 'iot') return 'IoT';

      return '${word[0].toUpperCase()}${word.substring(1).toLowerCase()}';
    }).toList();

    return words.join(' ');
  }

  // ---------------------------------------------------------------------------
  // Persistence
  // ---------------------------------------------------------------------------

  Future<void> _loadSavedRecords() async {
    final preferences =
        await SharedPreferences.getInstance();

    final raw = preferences.getString(
      _storageKey,
    );

    if (raw == null || raw.trim().isEmpty) {
      return;
    }

    final decoded = jsonDecode(raw);

    if (decoded is! List) {
      return;
    }

    for (final item in decoded) {
      if (item is! Map) continue;

      final record = _CalibrationRecord.fromJson(
        Map<String, dynamic>.from(item),
      );

      _records[record.nodeId] = record;
    }
  }

  Future<void> _saveRecords() async {
    final preferences =
        await SharedPreferences.getInstance();

    final records = _records.values
        .map(
          (record) => record.toJson(),
        )
        .toList();

    await preferences.setString(
      _storageKey,
      jsonEncode(records),
    );
  }

  // ---------------------------------------------------------------------------
  // GPS permission / live position
  // ---------------------------------------------------------------------------

  Future<void> _ensureLocationReady() async {
    final enabled = await geo.Geolocator
        .isLocationServiceEnabled();

    if (!enabled) {
      throw Exception(
        'Location services are disabled. Turn GPS on and try again.',
      );
    }

    var permission =
        await geo.Geolocator.checkPermission();

    if (permission ==
        geo.LocationPermission.denied) {
      permission =
          await geo.Geolocator.requestPermission();
    }

    if (permission ==
        geo.LocationPermission.denied) {
      throw Exception(
        'Location permission was denied.',
      );
    }

    if (permission ==
        geo.LocationPermission.deniedForever) {
      throw Exception(
        'Location permission is permanently denied. Enable it in Android settings.',
      );
    }
  }

  Future<void> _startLiveLocation() async {
    try {
      await _ensureLocationReady();

      if (!mounted) return;

      setState(() {
        _locationLoading = true;
      });

      final current =
          await geo.Geolocator.getCurrentPosition(
        locationSettings:
            const geo.LocationSettings(
          accuracy:
              geo.LocationAccuracy.bestForNavigation,
        ),
      );

      if (!mounted) return;

      setState(() {
        _currentPosition = current;
        _locationLoading = false;
      });

      await _liveLocationSubscription?.cancel();

      _liveLocationSubscription =
          geo.Geolocator.getPositionStream(
        locationSettings:
            const geo.LocationSettings(
          accuracy:
              geo.LocationAccuracy.bestForNavigation,
          distanceFilter: 1,
        ),
      ).listen(
        (position) {
          if (!mounted) return;

          setState(() {
            _currentPosition = position;
          });
        },
        onError: (error) {
          if (!mounted) return;

          setState(() {
            _statusMessage =
                'Live GPS update failed: $error';
          });
        },
      );
    } catch (error) {
      if (!mounted) return;

      setState(() {
        _locationLoading = false;
        _statusMessage =
            'Could not get current GPS location: $error';
      });
    }
  }

  Future<void> _refreshCurrentLocation() async {
    if (_locationLoading) return;

    try {
      await _ensureLocationReady();

      if (!mounted) return;

      setState(() {
        _locationLoading = true;
      });

      final current =
          await geo.Geolocator.getCurrentPosition(
        locationSettings:
            const geo.LocationSettings(
          accuracy:
              geo.LocationAccuracy.bestForNavigation,
        ),
      );

      if (!mounted) return;

      setState(() {
        _currentPosition = current;
        _locationLoading = false;
        _statusMessage =
            'Nearby entrances refreshed from your current GPS location.';
      });
    } catch (error) {
      if (!mounted) return;

      setState(() {
        _locationLoading = false;
        _statusMessage = error.toString();
      });
    }
  }

  // ---------------------------------------------------------------------------
  // Nearby entrance sorting
  // ---------------------------------------------------------------------------

  List<_CalibrationPoint> _sortedPoints() {
    final points = List<_CalibrationPoint>.from(
      _points,
    );

    final gps = _currentPosition;

    if (gps == null) {
      points.sort(
        (a, b) => a.label.compareTo(b.label),
      );
      return points;
    }

    final userMapPosition =
        _gpsService.toMapOffset(gps);

    points.sort((a, b) {
      final aDistance =
          _distanceToPointFromMap(
        a,
        userMapPosition,
      );

      final bDistance =
          _distanceToPointFromMap(
        b,
        userMapPosition,
      );

      return aDistance.compareTo(bDistance);
    });

    return points;
  }

  double _distanceToPointFromMap(
    _CalibrationPoint point,
    Offset userMapPosition,
  ) {
    final node = _graphService
        .graph
        .nodesById[point.nodeId];

    if (node == null) {
      return double.infinity;
    }

    return _mapDistanceMetres(
      userMapPosition,
      node.position.toOffset(),
    );
  }

  double? _distanceToPoint(
    _CalibrationPoint point,
  ) {
    final gps = _currentPosition;

    if (gps == null) return null;

    final userMapPosition =
        _gpsService.toMapOffset(gps);

    return _distanceToPointFromMap(
      point,
      userMapPosition,
    );
  }

  double _mapDistanceMetres(
    Offset a,
    Offset b,
  ) {
    final dx = b.dx - a.dx;
    final dy = b.dy - a.dy;

    final determinant =
        _xEast * _yNorth -
        _xNorth * _yEast;

    final eastMetres =
        (_yNorth * dx -
                _xNorth * dy) /
            determinant;

    final northMetres =
        (-_yEast * dx +
                _xEast * dy) /
            determinant;

    return math.sqrt(
      eastMetres * eastMetres + northMetres * northMetres
    );
  }

  // ---------------------------------------------------------------------------
  // Record one calibration point
  // ---------------------------------------------------------------------------

  Future<void> _recordPoint(
    _CalibrationPoint point,
  ) async {
    if (_recordingNodeId != null) {
      return;
    }

    final node = _graphService
        .graph
        .nodesById[point.nodeId];

    if (node == null) {
      _showMessage(
        'Node ${point.nodeId} does not exist in nodes.json.',
      );
      return;
    }

    try {
      await _ensureLocationReady();

      if (!mounted) return;

      setState(() {
        _recordingNodeId = point.nodeId;
        _samplesCollected = 0;
        _statusMessage =
            'Stand still at ${point.label}. '
            'The phone will record one GPS reading every 3 seconds, '
            'for $_targetSamples readings total.';
      });

      final samples = <_CalibrationSample>[];

      for (int sampleNumber = 1;
          sampleNumber <= _targetSamples;
          sampleNumber++) {
        // Deliberately query GPS on a fixed timer instead of waiting for a
        // movement-based position stream. Identical coordinates are valid and
        // are intentionally kept.
        await Future.delayed(
          const Duration(seconds: 3),
        );

        if (!mounted) return;

        setState(() {
          _statusMessage =
              'Recording ${point.label}... '
              'capturing sample $sampleNumber of $_targetSamples.';
        });

        geo.Position position;

        try {
          position =
              await geo.Geolocator.getCurrentPosition(
            locationSettings:
                const geo.LocationSettings(
              accuracy:
                  geo.LocationAccuracy.bestForNavigation,
            ),
          );
        } catch (_) {
          final lastKnown =
              await geo.Geolocator.getLastKnownPosition();

          if (lastKnown == null) {
            rethrow;
          }

          position = lastKnown;
        }

        if (!mounted) return;

        samples.add(
          _CalibrationSample(
            latitude: position.latitude,
            longitude: position.longitude,
            accuracy: position.accuracy,
            capturedAt:
                DateTime.now().toUtc(),
          ),
        );

        setState(() {
          _currentPosition = position;
          _samplesCollected = samples.length;
          _statusMessage =
              'Recording ${point.label}... '
              '${samples.length} / $_targetSamples samples saved. '
              'Latest accuracy: ±${position.accuracy.toStringAsFixed(1)} m.';
        });
      }

      if (!mounted) return;

      if (samples.length != _targetSamples) {
        throw Exception(
          'Expected $_targetSamples GPS samples but only '
          '${samples.length} were recorded.',
        );
      }

      final record = _buildRecord(
        point,
        node,
        samples,
      );

      _records[point.nodeId] = record;
      await _saveRecords();

      if (!mounted) return;

      setState(() {
        _recordingNodeId = null;
        _samplesCollected = 0;
        _statusMessage =
            '${point.label} saved. '
            '$_targetSamples readings were recorded. '
            'Best accuracy: ±${record.bestAccuracy.toStringAsFixed(1)} m.';
      });
    } catch (error) {
      if (!mounted) return;

      setState(() {
        _recordingNodeId = null;
        _samplesCollected = 0;
        _statusMessage = error.toString();
      });
    }
  }

  _CalibrationRecord _buildRecord(
    _CalibrationPoint point,
    GraphNode node,
    List<_CalibrationSample> samples,
  ) {
    final sorted = List<_CalibrationSample>.from(
      samples,
    )
      ..sort(
        (a, b) =>
            a.accuracy.compareTo(b.accuracy),
      );

    final usedCount = mathMin(
      _bestSamplesToAverage,
      sorted.length,
    );

    final used = sorted.take(usedCount).toList();

    final latitude = used
            .map((sample) => sample.latitude)
            .reduce((a, b) => a + b) /
        used.length;

    final longitude = used
            .map((sample) => sample.longitude)
            .reduce((a, b) => a + b) /
        used.length;

    final averageAccuracy = used
            .map((sample) => sample.accuracy)
            .reduce((a, b) => a + b) /
        used.length;

    final bestAccuracy = sorted.first.accuracy;

    return _CalibrationRecord(
      nodeId: point.nodeId,
      label: point.label,
      area: point.area,
      svgX: node.position.x,
      svgY: node.position.y,
      latitude: latitude,
      longitude: longitude,
      averageAccuracy: averageAccuracy,
      bestAccuracy: bestAccuracy,
      samplesUsed: used.length,
      capturedAt: DateTime.now().toUtc(),
      samples: samples,
    );
  }

  // ---------------------------------------------------------------------------
  // Delete / clear
  // ---------------------------------------------------------------------------

  Future<void> _deletePoint(
    String nodeId,
  ) async {
    _records.remove(nodeId);
    await _saveRecords();

    if (!mounted) return;

    setState(() {});
  }

  Future<void> _clearAll() async {
    if (_records.isEmpty) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text(
            'Clear calibration data?',
          ),
          content: const Text(
            'This removes every GPS point recorded on this phone.',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext)
                    .pop(false);
              },
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext)
                    .pop(true);
              },
              child: const Text('Clear'),
            ),
          ],
        );
      },
    );

    if (confirmed != true) return;

    _records.clear();
    await _saveRecords();

    if (!mounted) return;

    setState(() {
      _statusMessage =
          'All saved calibration points were cleared.';
    });
  }

  // ---------------------------------------------------------------------------
  // Export
  // ---------------------------------------------------------------------------

  Map<String, dynamic> _buildExportPayload() {
    final orderedRecords =
        _records.values.toList()
          ..sort(
            (a, b) =>
                a.label.compareTo(b.label),
          );

    return {
      'format': 'bc_ways_gps_calibration',
      'version': 2,
      'exportedAt':
          DateTime.now().toUtc().toIso8601String(),
      'map': {
        'width': 3000,
        'height': 3000,
      },
      'availableCalibrationPoints':
          _points.length,
      'recordCount': orderedRecords.length,
      'records': orderedRecords
          .map((record) => record.toJson())
          .toList(),
    };
  }

  Future<void> _copyJson() async {
    if (_records.isEmpty) {
      _showMessage(
        'Record at least one calibration point first.',
      );
      return;
    }

    const encoder = JsonEncoder.withIndent('  ');

    final text = encoder.convert(
      _buildExportPayload(),
    );

    await Clipboard.setData(
      ClipboardData(
        text: text,
      ),
    );

    if (!mounted) return;

    _showMessage(
      'Calibration JSON copied. Open WhatsApp, email, Notes or Drive and paste it somewhere safe.',
    );
  }

  // ---------------------------------------------------------------------------
  // UI
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    final recorded = _records.length;
    final sortedPoints = _sortedPoints();

    final unrecordedPoints = sortedPoints
        .where((point) => !_records.containsKey(point.nodeId))
        .toList();

    final visiblePoints = _showAll
        ? sortedPoints
        : (unrecordedPoints.isNotEmpty
            ? unrecordedPoints.take(_nearbyLimit).toList()
            : sortedPoints.take(_nearbyLimit).toList());

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'GPS Calibration',
        ),
        actions: [
          IconButton(
            onPressed:
                _recordingNodeId == null
                    ? _refreshCurrentLocation
                    : null,
            tooltip: 'Refresh current location',
            icon: _locationLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                    ),
                  )
                : const Icon(
                    Icons.my_location,
                  ),
          ),
          IconButton(
            onPressed:
                _recordingNodeId == null
                    ? _clearAll
                    : null,
            tooltip: 'Clear all',
            icon: const Icon(
              Icons.delete_sweep_outlined,
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            _buildInstructions(
              recorded,
              visiblePoints.length,
            ),
            if (_statusMessage != null)
              _buildStatus(),
            Expanded(
              child: ListView.separated(
                padding:
                    const EdgeInsets.fromLTRB(
                  16,
                  8,
                  16,
                  120,
                ),
                itemCount: visiblePoints.length,
                separatorBuilder: (_, __) =>
                    const SizedBox(height: 8),
                itemBuilder: (context, index) {
                  final point =
                      visiblePoints[index];

                  return _buildPointCard(
                    point,
                    index + 1,
                  );
                },
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        minimum:
            const EdgeInsets.fromLTRB(
          16,
          8,
          16,
          16,
        ),
        child: FilledButton.icon(
          onPressed:
              _recordingNodeId == null &&
                      _records.isNotEmpty
                  ? _copyJson
                  : null,
          icon: const Icon(
            Icons.copy_all_outlined,
          ),
          label: Text(
            _records.isEmpty
                ? 'Record points before exporting'
                : 'Copy Calibration JSON ($recorded)',
          ),
          style: FilledButton.styleFrom(
            backgroundColor: BcColors.primary,
            foregroundColor: Colors.black,
            padding:
                const EdgeInsets.symmetric(
              vertical: 14,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInstructions(
    int recorded,
    int visibleCount,
  ) {
    final gps = _currentPosition;

    return Container(
      width: double.infinity,
      margin:
          const EdgeInsets.fromLTRB(
        16,
        8,
        16,
        8,
      ),
      padding:
          const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: context.cardBg,
        borderRadius:
            BorderRadius.circular(14),
        border: Border.all(
          color: context.subtleBorder,
        ),
      ),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.gps_fixed,
                color: BcColors.blue,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  '$recorded / ${_points.length} points recorded',
                  style: TextStyle(
                    color: context.textPrimary,
                    fontWeight: FontWeight.w800,
                    fontSize: 16,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            _showAll
                ? 'Showing all ${_points.length} entrances and gates, sorted from closest to furthest from your live location.'
                : 'Showing the closest $visibleCount unrecorded entrances and gates to your live location. After you record one, the next closest unrecorded point moves into the list.',
            style: TextStyle(
              color: context.textSecondary,
              height: 1.35,
            ),
          ),
          const SizedBox(height: 8),
          if (gps != null)
            Text(
              'Live GPS: ${gps.latitude.toStringAsFixed(6)}, ${gps.longitude.toStringAsFixed(6)} · ±${gps.accuracy.toStringAsFixed(1)} m',
              style: TextStyle(
                color: context.textSecondary,
                fontSize: 11,
                fontFamily: 'monospace',
              ),
            )
          else
            Text(
              _locationLoading
                  ? 'Getting your live GPS location...'
                  : 'Live GPS location is not available yet.',
              style: TextStyle(
                color: context.textSecondary,
                fontSize: 11,
              ),
            ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed:
                      _recordingNodeId == null
                          ? () {
                              setState(() {
                                _showAll = !_showAll;
                              });
                            }
                          : null,
                  icon: Icon(
                    _showAll
                        ? Icons.near_me_outlined
                        : Icons.list_alt_outlined,
                  ),
                  label: Text(
                    _showAll
                        ? 'Show nearest $_nearbyLimit'
                        : 'Show all ${_points.length}',
                  ),
                ),
              ),
              const SizedBox(width: 8),
              IconButton.outlined(
                onPressed:
                    _recordingNodeId == null
                        ? _refreshCurrentLocation
                        : null,
                tooltip: 'Refresh nearby list',
                icon: const Icon(
                  Icons.refresh,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'At any point, stand at the physical entrance, tap Record, and stay still. The phone records one GPS reading every 3 seconds until it has $_targetSamples readings. You can record 14, 20, or every entrance if you want.',
            style: TextStyle(
              color: context.textSecondary,
              height: 1.35,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatus() {
    final recording =
        _recordingNodeId != null;

    return Container(
      width: double.infinity,
      margin:
          const EdgeInsets.fromLTRB(
        16,
        0,
        16,
        6,
      ),
      padding:
          const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: recording
            ? BcColors.blue
                .withValues(alpha: 0.10)
            : BcColors.teal
                .withValues(alpha: 0.10),
        borderRadius:
            BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Text(
            _statusMessage!,
            style: TextStyle(
              color: context.textPrimary,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
          if (recording) ...[
            const SizedBox(height: 8),
            LinearProgressIndicator(
              value: _samplesCollected /
                  _targetSamples,
              color: BcColors.blue,
            ),
            const SizedBox(height: 4),
            Text(
              '$_samplesCollected / $_targetSamples samples',
              style: TextStyle(
                color: context.textSecondary,
                fontSize: 11,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPointCard(
    _CalibrationPoint point,
    int rank,
  ) {
    final node = _graphService
        .graph
        .nodesById[point.nodeId];

    final record =
        _records[point.nodeId];

    final recording =
        _recordingNodeId == point.nodeId;

    final anotherPointRecording =
        _recordingNodeId != null &&
            !recording;

    final distance =
        _distanceToPoint(point);

    return Card(
      margin: EdgeInsets.zero,
      color: context.cardBg,
      child: Padding(
        padding:
            const EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment:
              CrossAxisAlignment.center,
          children: [
            SizedBox(
              width: 46,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: record != null
                          ? BcColors.teal
                              .withValues(alpha: 0.14)
                          : context.chipBg,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      record != null
                          ? Icons.check
                          : Icons.location_on_outlined,
                      color: record != null
                          ? BcColors.teal
                          : context.textSecondary,
                    ),
                  ),
                  Positioned(
                    right: 0,
                    top: 0,
                    child: Container(
                      padding:
                          const EdgeInsets.symmetric(
                        horizontal: 4,
                        vertical: 1,
                      ),
                      decoration: BoxDecoration(
                        color: BcColors.blue,
                        borderRadius:
                            BorderRadius.circular(8),
                      ),
                      child: Text(
                        '$rank',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 8,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  Text(
                    point.label,
                    style: TextStyle(
                      color: context.textPrimary,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    distance == null
                        ? point.area
                        : '${point.area} · approx. ${_formatDistance(distance)} away',
                    style: TextStyle(
                      color: context.textSecondary,
                      fontSize: 12,
                    ),
                  ),
                  if (node != null) ...[
                    const SizedBox(height: 3),
                    Text(
                      'SVG ${node.position.x.toStringAsFixed(0)}, ${node.position.y.toStringAsFixed(0)} · ${point.nodeId}',
                      style: TextStyle(
                        color: context.textSecondary,
                        fontSize: 10,
                        fontFamily: 'monospace',
                      ),
                    ),
                  ],
                  if (record != null) ...[
                    const SizedBox(height: 5),
                    Text(
                      'Saved · best ±${record.bestAccuracy.toStringAsFixed(1)} m · avg ±${record.averageAccuracy.toStringAsFixed(1)} m',
                      style: const TextStyle(
                        color: BcColors.teal,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 8),
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                FilledButton(
                  onPressed: node == null ||
                          anotherPointRecording ||
                          recording
                      ? null
                      : () =>
                          _recordPoint(point),
                  style: FilledButton.styleFrom(
                    backgroundColor:
                        BcColors.primary,
                    foregroundColor:
                        Colors.black,
                    padding:
                        const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                  ),
                  child: Text(
                    recording
                        ? 'Recording...'
                        : record == null
                            ? 'Record'
                            : 'Re-record',
                  ),
                ),
                if (record != null &&
                    _recordingNodeId == null)
                  TextButton(
                    onPressed: () =>
                        _deletePoint(point.nodeId),
                    child: const Text(
                      'Delete',
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _formatDistance(
    double metres,
  ) {
    if (!metres.isFinite) return '--';

    if (metres < 1000) {
      return '${metres.round()} m';
    }

    return '${(metres / 1000).toStringAsFixed(1)} km';
  }

  void _showMessage(
    String message,
  ) {
    if (!mounted) return;

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
        ),
      );
  }
}

int mathMin(
  int a,
  int b,
) {
  return a < b ? a : b;
}

class _CalibrationPoint {
  final String nodeId;
  final String label;
  final String area;

  const _CalibrationPoint({
    required this.nodeId,
    required this.label,
    required this.area,
  });
}

class _CalibrationSample {
  final double latitude;
  final double longitude;
  final double accuracy;
  final DateTime capturedAt;

  const _CalibrationSample({
    required this.latitude,
    required this.longitude,
    required this.accuracy,
    required this.capturedAt,
  });

  factory _CalibrationSample.fromJson(
    Map<String, dynamic> json,
  ) {
    return _CalibrationSample(
      latitude:
          (json['latitude'] as num).toDouble(),
      longitude:
          (json['longitude'] as num).toDouble(),
      accuracy:
          (json['accuracy'] as num).toDouble(),
      capturedAt: DateTime.parse(
        json['capturedAt'] as String,
      ),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'latitude': latitude,
      'longitude': longitude,
      'accuracy': accuracy,
      'capturedAt':
          capturedAt.toIso8601String(),
    };
  }
}

class _CalibrationRecord {
  final String nodeId;
  final String label;
  final String area;
  final double svgX;
  final double svgY;
  final double latitude;
  final double longitude;
  final double averageAccuracy;
  final double bestAccuracy;
  final int samplesUsed;
  final DateTime capturedAt;
  final List<_CalibrationSample> samples;

  const _CalibrationRecord({
    required this.nodeId,
    required this.label,
    required this.area,
    required this.svgX,
    required this.svgY,
    required this.latitude,
    required this.longitude,
    required this.averageAccuracy,
    required this.bestAccuracy,
    required this.samplesUsed,
    required this.capturedAt,
    required this.samples,
  });

  factory _CalibrationRecord.fromJson(
    Map<String, dynamic> json,
  ) {
    final rawSamples =
        json['samples'] as List? ?? const [];

    return _CalibrationRecord(
      nodeId: json['nodeId'] as String,
      label: json['label'] as String,
      area: json['area'] as String,
      svgX: (json['svgX'] as num).toDouble(),
      svgY: (json['svgY'] as num).toDouble(),
      latitude:
          (json['latitude'] as num).toDouble(),
      longitude:
          (json['longitude'] as num).toDouble(),
      averageAccuracy:
          (json['averageAccuracy'] as num)
              .toDouble(),
      bestAccuracy:
          (json['bestAccuracy'] as num).toDouble(),
      samplesUsed:
          (json['samplesUsed'] as num).toInt(),
      capturedAt: DateTime.parse(
        json['capturedAt'] as String,
      ),
      samples: rawSamples
          .whereType<Map>()
          .map(
            (sample) =>
                _CalibrationSample.fromJson(
              Map<String, dynamic>.from(sample),
            ),
          )
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'nodeId': nodeId,
      'label': label,
      'area': area,
      'svgX': svgX,
      'svgY': svgY,
      'latitude': latitude,
      'longitude': longitude,
      'averageAccuracy': averageAccuracy,
      'bestAccuracy': bestAccuracy,
      'samplesUsed': samplesUsed,
      'capturedAt':
          capturedAt.toIso8601String(),
      'samples': samples
          .map((sample) => sample.toJson())
          .toList(),
    };
  }
}
