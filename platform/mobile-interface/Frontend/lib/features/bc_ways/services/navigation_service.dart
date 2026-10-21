import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart' as geo;

import '../models/path_node.dart';
import '../models/route_result.dart';

const double kWalkingSpeedMps = 1.3;

enum TurnType {
  straight,
  slightLeft,
  slightRight,
  left,
  right,
  sharpLeft,
  sharpRight,
  arrive,
}

class NavInstruction {
  final TurnType type;
  final String label;
  final double distanceMetersToTurn;

  const NavInstruction({
    required this.type,
    required this.label,
    required this.distanceMetersToTurn,
  });
}

// ============================================================================
// ADAPTIVE GPS FILTER
// ============================================================================
//
// The phone's raw GPS can drift several metres while the user is standing
// still, especially around buildings. A fixed heavy smoothing filter would
// reduce that jitter, but it would also make the marker lag when the user is
// walking quickly or travelling in a car.
//
// This filter changes behaviour automatically:
//
//   Stationary -> strong stabilisation + large-jump rejection
//   Walking    -> moderate smoothing
//   Fast       -> almost raw GPS, so there is very little lag in a vehicle
//
// IMPORTANT:
// This does NOT snap the user to a graph node. It only stabilises the real GPS
// coordinate before MapScreen / NavigationScreen convert it to SVG space.
// ============================================================================

enum _MovementMode { stationary, walking, fast }

class _AdaptiveGpsFilter {
  geo.Position? _filteredPosition;
  geo.Position? _lastRawPosition;

  _MovementMode _mode = _MovementMode.stationary;

  final List<geo.Position> _stationarySamples = <geo.Position>[];
  final List<geo.Position> _walkingSamples = <geo.Position>[];

  geo.Position? _pendingStationaryJump;
  int _pendingStationaryJumpCount = 0;

  static const int _stationaryWindowSize = 5;
  static const int _walkingWindowSize = 2;

  static const int _stationaryJumpConfirmations = 5;

  void reset() {
    _filteredPosition = null;
    _lastRawPosition = null;
    _mode = _MovementMode.stationary;

    _stationarySamples.clear();
    _walkingSamples.clear();

    _pendingStationaryJump = null;
    _pendingStationaryJumpCount = 0;
  }

  geo.Position filter(geo.Position raw) {
    final previousFiltered = _filteredPosition;

    if (previousFiltered == null) {
      _filteredPosition = raw;
      _lastRawPosition = raw;
      _stationarySamples.add(raw);
      return raw;
    }

    final newMode = _movementModeFor(raw);

    if (_isClearlyPoorAccuracy(raw, newMode)) {
      _lastRawPosition = raw;
      return previousFiltered;
    }

    final jumpDistance = geo.Geolocator.distanceBetween(
      previousFiltered.latitude,
      previousFiltered.longitude,
      raw.latitude,
      raw.longitude,
    );

    var confirmedRelocation = false;

    if (newMode == _MovementMode.stationary) {
      final jumpThreshold = _stationaryJumpThreshold(previousFiltered, raw);

      if (jumpDistance > jumpThreshold) {
        confirmedRelocation = _confirmStationaryJump(raw);

        if (!confirmedRelocation) {
          _lastRawPosition = raw;
          return previousFiltered;
        }

        // The new location stayed consistent for several readings, so this is
        // probably a real relocation rather than one bad GPS spike.
        _stationarySamples.clear();
        _walkingSamples.clear();
      } else {
        _clearPendingJump();
      }
    } else {
      _clearPendingJump();
    }

    if (newMode != _mode) {
      if (newMode == _MovementMode.fast) {
        // Do not let old stationary/walking samples make a car marker lag.
        _stationarySamples.clear();
        _walkingSamples.clear();
      } else if (newMode == _MovementMode.walking) {
        _stationarySamples.clear();
      }
    }

    _mode = newMode;

    final target = _targetPosition(raw, newMode);

    final alpha = confirmedRelocation
        ? 0.78
        : switch (newMode) {
            _MovementMode.stationary => 0.20,
            _MovementMode.walking => 0.68,
            _MovementMode.fast => 0.95,
          };

    final latitude = _lerp(previousFiltered.latitude, target.latitude, alpha);

    final longitude = _lerp(
      previousFiltered.longitude,
      target.longitude,
      alpha,
    );

    final filtered = _positionWithCoordinates(
      raw,
      latitude: latitude,
      longitude: longitude,
    );

    _filteredPosition = filtered;
    _lastRawPosition = raw;

    return filtered;
  }

  _MovementMode _movementModeFor(geo.Position raw) {
    final speed = _effectiveSpeed(raw);

    // Hysteresis prevents the filter from rapidly switching modes when the
    // measured speed sits close to a threshold.
    switch (_mode) {
      case _MovementMode.stationary:
        if (speed >= 3.2) {
          return _MovementMode.fast;
        }

        if (speed >= 0.85) {
          return _MovementMode.walking;
        }

        return _MovementMode.stationary;

      case _MovementMode.walking:
        if (speed >= 3.5) {
          return _MovementMode.fast;
        }

        if (speed < 0.55) {
          return _MovementMode.stationary;
        }

        return _MovementMode.walking;

      case _MovementMode.fast:
        if (speed < 2.4) {
          if (speed < 0.55) {
            return _MovementMode.stationary;
          }

          return _MovementMode.walking;
        }

        return _MovementMode.fast;
    }
  }

  double _effectiveSpeed(geo.Position raw) {
    // Android normally supplies a useful GNSS speed value. Prefer it because
    // calculating speed from two jittery coordinates can falsely make a
    // stationary phone look as though it is moving quickly.
    if (raw.speed.isFinite && raw.speed >= 0) {
      return raw.speed;
    }

    final previousRaw = _lastRawPosition;

    if (previousRaw == null) {
      return 0.0;
    }

    final milliseconds = raw.timestamp
        .difference(previousRaw.timestamp)
        .inMilliseconds;

    if (milliseconds <= 0) {
      return 0.0;
    }

    final seconds = milliseconds / 1000.0;

    final distance = geo.Geolocator.distanceBetween(
      previousRaw.latitude,
      previousRaw.longitude,
      raw.latitude,
      raw.longitude,
    );

    return distance / seconds;
  }

  bool _isClearlyPoorAccuracy(geo.Position raw, _MovementMode mode) {
    final previous = _filteredPosition;

    if (previous == null) {
      return false;
    }

    final rawAccuracy = _normalisedAccuracy(raw.accuracy);
    final previousAccuracy = _normalisedAccuracy(previous.accuracy);

    // Never let one poor fix permanently widen the acceptance window.
    // The previous implementation could accept increasingly inaccurate fixes
    // when a session happened to start with a weak GPS lock.
    final allowedAccuracy = switch (mode) {
      _MovementMode.stationary => math.min(
        25.0,
        math.max(18.0, previousAccuracy * 1.8),
      ),
      _MovementMode.walking => math.min(
        35.0,
        math.max(25.0, previousAccuracy * 2.0),
      ),
      _MovementMode.fast => math.min(
        60.0,
        math.max(40.0, previousAccuracy * 2.5),
      ),
    };

    return rawAccuracy > allowedAccuracy;
  }

  double _stationaryJumpThreshold(geo.Position previous, geo.Position raw) {
    final accuracy = math.max(
      _normalisedAccuracy(previous.accuracy),
      _normalisedAccuracy(raw.accuracy),
    );

    // With ~5 m accuracy, a single 10+ metre jump is suspicious. When GPS
    // accuracy is naturally worse, allow a wider radius before rejecting it.
    return math.max(10.0, math.min(20.0, accuracy * 1.45));
  }

  bool _confirmStationaryJump(geo.Position raw) {
    final pending = _pendingStationaryJump;

    if (pending == null) {
      _pendingStationaryJump = raw;
      _pendingStationaryJumpCount = 1;
      return false;
    }

    final distanceFromPending = geo.Geolocator.distanceBetween(
      pending.latitude,
      pending.longitude,
      raw.latitude,
      raw.longitude,
    );

    final confirmationRadius = math.max(
      8.0,
      _normalisedAccuracy(raw.accuracy) * 1.25,
    );

    if (distanceFromPending <= confirmationRadius) {
      _pendingStationaryJumpCount++;

      // Keep the pending reference close to the centre of the candidate area.
      _pendingStationaryJump = _positionWithCoordinates(
        raw,
        latitude: (pending.latitude + raw.latitude) / 2.0,
        longitude: (pending.longitude + raw.longitude) / 2.0,
      );
    } else {
      _pendingStationaryJump = raw;
      _pendingStationaryJumpCount = 1;
    }

    if (_pendingStationaryJumpCount < _stationaryJumpConfirmations) {
      return false;
    }

    _clearPendingJump();
    return true;
  }

  void _clearPendingJump() {
    _pendingStationaryJump = null;
    _pendingStationaryJumpCount = 0;
  }

  geo.Position _targetPosition(geo.Position raw, _MovementMode mode) {
    switch (mode) {
      case _MovementMode.stationary:
        _stationarySamples.add(raw);

        while (_stationarySamples.length > _stationaryWindowSize) {
          _stationarySamples.removeAt(0);
        }

        final latitudes =
            _stationarySamples.map((position) => position.latitude).toList()
              ..sort();

        final longitudes =
            _stationarySamples.map((position) => position.longitude).toList()
              ..sort();

        return _positionWithCoordinates(
          raw,
          latitude: _median(latitudes),
          longitude: _median(longitudes),
        );

      case _MovementMode.walking:
        _walkingSamples.add(raw);

        while (_walkingSamples.length > _walkingWindowSize) {
          _walkingSamples.removeAt(0);
        }

        var totalWeight = 0.0;
        var weightedLatitude = 0.0;
        var weightedLongitude = 0.0;

        for (final sample in _walkingSamples) {
          final accuracy = math.max(3.0, _normalisedAccuracy(sample.accuracy));

          final weight = 1.0 / (accuracy * accuracy);

          totalWeight += weight;
          weightedLatitude += sample.latitude * weight;
          weightedLongitude += sample.longitude * weight;
        }

        if (totalWeight <= 0) {
          return raw;
        }

        return _positionWithCoordinates(
          raw,
          latitude: weightedLatitude / totalWeight,
          longitude: weightedLongitude / totalWeight,
        );

      case _MovementMode.fast:
        return raw;
    }
  }

  double _normalisedAccuracy(double accuracy) {
    if (!accuracy.isFinite || accuracy <= 0) {
      return 10.0;
    }

    return accuracy;
  }

  double _median(List<double> values) {
    if (values.isEmpty) {
      return 0.0;
    }

    final middle = values.length ~/ 2;

    if (values.length.isOdd) {
      return values[middle];
    }

    return (values[middle - 1] + values[middle]) / 2.0;
  }

  double _lerp(double start, double end, double amount) {
    return start + (end - start) * amount;
  }

  geo.Position _positionWithCoordinates(
    geo.Position source, {
    required double latitude,
    required double longitude,
  }) {
    return geo.Position(
      longitude: longitude,
      latitude: latitude,
      timestamp: source.timestamp,
      accuracy: source.accuracy,
      altitude: source.altitude,
      altitudeAccuracy: source.altitudeAccuracy,
      heading: source.heading,
      headingAccuracy: source.headingAccuracy,
      speed: source.speed,
      speedAccuracy: source.speedAccuracy,
      floor: source.floor,
      isMocked: source.isMocked,
    );
  }
}

class NavigationService {
  StreamSubscription<geo.Position>? _positionSubscription;

  final StreamController<geo.Position> _locationController =
      StreamController<geo.Position>.broadcast();

  final _AdaptiveGpsFilter _gpsFilter = _AdaptiveGpsFilter();

  Stream<geo.Position> get locationStream => _locationController.stream;

  // Keep one recent trusted fix across MapScreen -> NavigationScreen.
  // This prevents Active Navigation from doing another full GPS warm-up
  // immediately after the map already obtained a good location.
  static geo.Position? _recentTrustedPosition;

  static const Duration _trustedPositionMaxAge = Duration(seconds: 15);
  static const Duration _warmUpMaximumDuration = Duration(seconds: 4);
  static const int _warmUpMinimumSamples = 3;
  static const double _warmUpPreferredAccuracyMetres = 10.0;
  static const double _warmUpUsableAccuracyMetres = 25.0;

  // ---------------------------------------------------------------------------
  // LIVE GPS SETTINGS
  // ---------------------------------------------------------------------------

  geo.LocationSettings _locationSettings() {
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
      return geo.AndroidSettings(
        accuracy: geo.LocationAccuracy.bestForNavigation,
        distanceFilter: 0,

        // Ask Android's fused provider for frequent outdoor navigation fixes.
        // This is a requested interval rather than a guarantee from the OS.
        intervalDuration: Duration(milliseconds: 500),
      );
    }

    return const geo.LocationSettings(
      accuracy: geo.LocationAccuracy.bestForNavigation,
      distanceFilter: 0,
    );
  }

  // ---------------------------------------------------------------------------
  // GPS QUALITY / WARM-UP
  // ---------------------------------------------------------------------------

  double _normalisedAccuracy(geo.Position position) {
    final accuracy = position.accuracy;

    if (!accuracy.isFinite || accuracy <= 0) {
      return 999.0;
    }

    return accuracy;
  }

  bool _canReuseRecentTrustedPosition() {
    final position = _recentTrustedPosition;

    if (position == null) {
      return false;
    }

    final age = DateTime.now().difference(position.timestamp);

    return age <= _trustedPositionMaxAge &&
        _normalisedAccuracy(position) <= _warmUpUsableAccuracyMetres;
  }

  bool _warmUpCanFinishEarly(List<geo.Position> samples) {
    if (samples.length < _warmUpMinimumSamples) {
      return false;
    }

    final recent = samples.sublist(samples.length - _warmUpMinimumSamples);

    final goodCount = recent
        .where(
          (position) =>
              _normalisedAccuracy(position) <= _warmUpPreferredAccuracyMetres,
        )
        .length;

    if (goodCount < 2) {
      return false;
    }

    // If the phone is already moving, do not insist on a stationary cluster.
    // A few good fixes are enough to begin navigation.
    final moving = recent.any(
      (position) => position.speed.isFinite && position.speed >= 0.7,
    );

    if (moving) {
      return true;
    }

    // While stationary, require the recent good fixes to form a reasonably
    // tight cluster. This rejects a deceptively "accurate" one-off outlier.
    var maxDistance = 0.0;

    for (var i = 0; i < recent.length; i++) {
      for (var j = i + 1; j < recent.length; j++) {
        final distance = geo.Geolocator.distanceBetween(
          recent[i].latitude,
          recent[i].longitude,
          recent[j].latitude,
          recent[j].longitude,
        );

        maxDistance = math.max(maxDistance, distance);
      }
    }

    return maxDistance <= 10.0;
  }

  geo.Position _weightedWarmUpPosition(List<geo.Position> samples) {
    if (samples.isEmpty) {
      throw StateError('Cannot build a GPS warm-up position without samples.');
    }

    final sorted = [
      ...samples,
    ]..sort((a, b) => _normalisedAccuracy(a).compareTo(_normalisedAccuracy(b)));

    final best = sorted.first;
    final bestAccuracy = _normalisedAccuracy(best);

    // Prefer the best cluster instead of averaging every weak fix together.
    final candidateLimit = math.min(
      _warmUpUsableAccuracyMetres,
      math.max(12.0, bestAccuracy + 5.0),
    );

    var candidates = samples
        .where((position) => _normalisedAccuracy(position) <= candidateLimit)
        .toList();

    if (candidates.isEmpty) {
      candidates = [best];
    }

    // A moving user should not be averaged far backwards along the path.
    final moving = candidates.any(
      (position) => position.speed.isFinite && position.speed >= 0.7,
    );

    if (moving) {
      final recentGood = candidates.last;
      return recentGood;
    }

    var totalWeight = 0.0;
    var weightedLatitude = 0.0;
    var weightedLongitude = 0.0;

    for (final position in candidates) {
      final accuracy = math.max(3.0, _normalisedAccuracy(position));
      final weight = 1.0 / (accuracy * accuracy);

      totalWeight += weight;
      weightedLatitude += position.latitude * weight;
      weightedLongitude += position.longitude * weight;
    }

    if (totalWeight <= 0) {
      return best;
    }

    return geo.Position(
      longitude: weightedLongitude / totalWeight,
      latitude: weightedLatitude / totalWeight,
      timestamp: best.timestamp,
      accuracy: best.accuracy,
      altitude: best.altitude,
      altitudeAccuracy: best.altitudeAccuracy,
      heading: best.heading,
      headingAccuracy: best.headingAccuracy,
      speed: best.speed,
      speedAccuracy: best.speedAccuracy,
      floor: best.floor,
      isMocked: best.isMocked,
    );
  }

  Future<geo.Position> _acquireWarmStart(geo.LocationSettings settings) async {
    if (_canReuseRecentTrustedPosition()) {
      return _recentTrustedPosition!;
    }

    final samples = <geo.Position>[];

    // Ask for one immediate fix first so the warm-up does not depend entirely
    // on stream scheduling. It is NOT trusted by itself.
    final first = await geo.Geolocator.getCurrentPosition(
      locationSettings: settings,
    );

    samples.add(first);

    if (_normalisedAccuracy(first) <= 6.0) {
      return first;
    }

    final completer = Completer<void>();
    Timer? timer;
    StreamSubscription<geo.Position>? warmUpSubscription;

    timer = Timer(_warmUpMaximumDuration, () {
      if (!completer.isCompleted) {
        completer.complete();
      }
    });

    warmUpSubscription =
        geo.Geolocator.getPositionStream(locationSettings: settings).listen(
          (position) {
            samples.add(position);

            if (_warmUpCanFinishEarly(samples) && !completer.isCompleted) {
              completer.complete();
            }
          },
          onError: (Object error, StackTrace stackTrace) {
            if (!completer.isCompleted) {
              completer.completeError(error, stackTrace);
            }
          },
        );

    try {
      await completer.future;
    } finally {}
    timer.cancel();
    await warmUpSubscription.cancel();

    return _weightedWarmUpPosition(samples);
  }

  void _rememberTrustedPosition(geo.Position position) {
    // Keep a recent position for fast MapScreen -> NavigationScreen handoff.
    // Even if accuracy is temporarily weaker, only cache values within the
    // same hard outdoor quality ceiling used by the filter.
    if (_normalisedAccuracy(position) <= _warmUpUsableAccuracyMetres) {
      _recentTrustedPosition = position;
    }
  }

  // ---------------------------------------------------------------------------
  // LIVE GPS
  // ---------------------------------------------------------------------------

  Future<geo.Position> startLocationTracking() async {
    final enabled = await geo.Geolocator.isLocationServiceEnabled();

    if (!enabled) {
      throw Exception('Location services are disabled.');
    }

    var permission = await geo.Geolocator.checkPermission();

    if (permission == geo.LocationPermission.denied) {
      permission = await geo.Geolocator.requestPermission();
    }

    if (permission == geo.LocationPermission.denied) {
      throw Exception('Location permission was denied.');
    }

    if (permission == geo.LocationPermission.deniedForever) {
      throw Exception('Location permission is permanently denied.');
    }

    await stopLocationTracking();
    _gpsFilter.reset();

    final settings = _locationSettings();
    final warmStart = await _acquireWarmStart(settings);
    final filteredCurrent = _gpsFilter.filter(warmStart);

    _rememberTrustedPosition(filteredCurrent);

    _positionSubscription =
        geo.Geolocator.getPositionStream(locationSettings: settings).listen(
          (position) {
            final filtered = _gpsFilter.filter(position);

            _rememberTrustedPosition(filtered);
            _locationController.add(filtered);
          },
          onError: (error) {
            _locationController.addError(error);
          },
        );

    return filteredCurrent;
  }

  Future<void> stopLocationTracking() async {
    await _positionSubscription?.cancel();
    _positionSubscription = null;
  }

  Future<void> dispose() async {
    await stopLocationTracking();
    await _locationController.close();
  }

  // ---------------------------------------------------------------------------
  // ETA / DISTANCE
  // ---------------------------------------------------------------------------

  double remainingMeters(RouteResult route, double metersWalked) {
    final result = route.totalDistanceMeters - metersWalked;

    return result < 0 ? 0 : result;
  }

  int etaMinutes(double distanceMeters) {
    if (distanceMeters <= 0) {
      return 0;
    }

    return (distanceMeters / kWalkingSpeedMps / 60).ceil();
  }

  // ---------------------------------------------------------------------------
  // NAVIGATION INSTRUCTION
  // ---------------------------------------------------------------------------

  NavInstruction currentInstruction(RouteResult route, double metersWalked) {
    if (route.path.isEmpty) {
      return const NavInstruction(
        type: TurnType.arrive,
        label: 'No route available',
        distanceMetersToTurn: 0,
      );
    }

    if (route.path.length == 1) {
      return const NavInstruction(
        type: TurnType.arrive,
        label: 'You have arrived',
        distanceMetersToTurn: 0,
      );
    }

    final next = route.path[1];

    final double distanceToNext = (next.cumulativeDistance - metersWalked)
        .clamp(0.0, double.infinity)
        .toDouble();

    if (route.path.length < 3) {
      return NavInstruction(
        type: TurnType.straight,
        label: 'Continue to destination',
        distanceMetersToTurn: distanceToNext,
      );
    }

    final turn = _calculateTurn(route.path[0], route.path[1], route.path[2]);

    return NavInstruction(
      type: turn,
      label: _labelForTurn(turn),
      distanceMetersToTurn: distanceToNext,
    );
  }

  TurnType _calculateTurn(PathNode first, PathNode second, PathNode third) {
    final a = first.node.position;
    final b = second.node.position;
    final c = third.node.position;

    final heading1 = math.atan2(b.y - a.y, b.x - a.x);

    final heading2 = math.atan2(c.y - b.y, c.x - b.x);

    double difference = heading2 - heading1;

    while (difference > math.pi) {
      difference -= 2 * math.pi;
    }

    while (difference < -math.pi) {
      difference += 2 * math.pi;
    }

    final degrees = difference * 180 / math.pi;

    if (degrees.abs() < 20) {
      return TurnType.straight;
    }

    // SVG Y increases downward,
    // therefore positive angle = right.
    if (degrees > 0) {
      if (degrees > 135) {
        return TurnType.sharpRight;
      }

      if (degrees > 45) {
        return TurnType.right;
      }

      return TurnType.slightRight;
    }

    if (degrees < -135) {
      return TurnType.sharpLeft;
    }

    if (degrees < -45) {
      return TurnType.left;
    }

    return TurnType.slightLeft;
  }

  String _labelForTurn(TurnType type) {
    switch (type) {
      case TurnType.straight:
        return 'Continue straight';

      case TurnType.slightLeft:
        return 'Bear left';

      case TurnType.slightRight:
        return 'Bear right';

      case TurnType.left:
        return 'Turn left';

      case TurnType.right:
        return 'Turn right';

      case TurnType.sharpLeft:
        return 'Sharp left';

      case TurnType.sharpRight:
        return 'Sharp right';

      case TurnType.arrive:
        return 'You have arrived';
    }
  }

  PathNode? positionAt(RouteResult route, double metersWalked) {
    if (route.path.isEmpty) {
      return null;
    }

    for (final node in route.path) {
      if (node.cumulativeDistance >= metersWalked) {
        return node;
      }
    }

    return route.path.last;
  }
}
