import 'dart:convert';
import 'dart:math' as math;
import 'package:flutter/animation.dart';

import '../models/graph.dart';
import '../models/node.dart';
import '../models/path_node.dart';
import '../models/route_result.dart';
import 'dijkstra_service.dart';
import 'campus_gps_service.dart';
import 'campus_navigation_geometry.dart';

/// Position along an edge, not a replacement node in the campus graph.
class RouteProjection {
  final Offset point;
  final double fraction;
  final double distanceMeters;
  final double progressMeters;
  const RouteProjection(
    this.point,
    this.fraction,
    this.distanceMeters,
    this.progressMeters,
  );
}

class RouteGeometry {
  static RouteProjection project(
    Offset p,
    Offset a,
    Offset b, {
    double startMeters = 0,
    double lengthMeters = 0,
  }) {
    final d = b - a;
    final t = d.distanceSquared == 0
        ? 0.0
        : (((p - a).dx * d.dx + (p - a).dy * d.dy) / d.distanceSquared)
              .clamp(0.0, 1.0)
              .toDouble();
    final point = a + d * t;
    return RouteProjection(
      point,
      t,
      CampusGpsService.mapDistanceMeters(p, point),
      startMeters + lengthMeters * t,
    );
  }

  static RouteProjection? match(
    RouteResult route,
    Offset p, {
    double? previous,
    double maxChange = double.infinity,
  }) {
    RouteProjection? best;
    var bestScore = double.infinity;
    for (var i = 1; i < route.path.length; i++) {
      final a = route.path[i - 1];
      final b = route.path[i];
      final candidate = project(
        p,
        a.node.position.toOffset(),
        b.node.position.toOffset(),
        startMeters: a.cumulativeDistance,
        lengthMeters: b.cumulativeDistance - a.cumulativeDistance,
      );
      final change = previous == null
          ? 0.0
          : (candidate.progressMeters - previous).abs();
      if (change > maxChange) continue;
      // Prefer continuity at intersections and near parallel route segments.
      final score = candidate.distanceMeters + change * 0.12;
      if (score < bestScore) {
        best = candidate;
        bestScore = score;
      }
    }
    return best;
  }

  /// Trim at an interpolated point. Remaining distances keep graph edge weights.
  static RouteResult remaining(RouteResult route, double progress) {
    if (route.path.length < 2) return route;
    final m = progress.clamp(0.0, route.totalDistanceMeters).toDouble();
    for (var i = 1; i < route.path.length; i++) {
      final a = route.path[i - 1];
      final b = route.path[i];
      if (b.cumulativeDistance <= m) continue;
      final length = b.cumulativeDistance - a.cumulativeDistance;
      final t = length <= 0 ? 0.0 : (m - a.cumulativeDistance) / length;
      final point = Offset.lerp(
        a.node.position.toOffset(),
        b.node.position.toOffset(),
        t,
      )!;
      return RouteResult(
        path: [
          PathNode(
            node: a.node.copyWithPosition(point.dx, point.dy),
            cumulativeDistance: 0,
          ),
          for (final n in route.path.skip(i))
            PathNode(
              node: n.node,
              cumulativeDistance: n.cumulativeDistance - m,
            ),
        ],
        totalDistanceMeters: route.totalDistanceMeters - m,
        isRerouted: route.isRerouted,
      );
    }
    return RouteResult(
      path: [PathNode(node: route.path.last.node, cumulativeDistance: 0)],
      totalDistanceMeters: 0,
    );
  }

  /// Start on the nearest WALKING EDGE and compare both directions to the goal.
  static RouteResult fromPosition(
    Graph graph,
    Offset point,
    String goal,
    double radius, {
    Iterable<String>? goalIds,
  }) {
    GraphNode? first;
    GraphNode? second;
    RouteProjection? nearest;
    var edgeLength = 0.0;
    for (final a in graph.nodesById.values) {
      for (final edge in graph.neighborsOf(a.id)) {
        final b = graph.nodesById[edge.nodeId];
        if (b == null || a.id.compareTo(b.id) >= 0) continue;
        final q = project(point, a.position.toOffset(), b.position.toOffset());
        if (nearest == null || q.distanceMeters < nearest.distanceMeters) {
          first = a;
          second = b;
          nearest = q;
          edgeLength = edge.distance;
        }
      }
    }
    if (nearest == null || nearest.distanceMeters > radius) {
      return RouteResult.empty;
    }
    final dijkstra = DijkstraService(graph);
    RouteResult best = RouteResult.empty;
    for (var side = 0; side < 2; side++) {
      final node = side == 0 ? first! : second!;
      final partial =
          edgeLength * (side == 0 ? nearest.fraction : 1 - nearest.fraction);
      final tail = dijkstra.findRouteToAny(node.id, goalIds ?? [goal]);
      if (tail.isEmpty) continue;
      final total = partial + tail.totalDistanceMeters;
      if (!best.isEmpty && total >= best.totalDistanceMeters) continue;
      best = RouteResult(
        path: [
          PathNode(
            node: node.copyWithPosition(nearest.point.dx, nearest.point.dy),
            cumulativeDistance: 0,
          ),
          for (final n in tail.path)
            if (partial + n.cumulativeDistance > 0.00001)
              PathNode(
                node: n.node,
                cumulativeDistance: partial + n.cumulativeDistance,
              ),
        ],
        totalDistanceMeters: total,
      );
    }
    return best;
  }
}

/// Animates distance along the polyline, so corners are never cut diagonally.
class RouteFollowService {
  final AnimationController _animation;
  final void Function() onChanged;
  RouteResult _full = RouteResult.empty;
  String? _goal;
  double _display = 0, _from = 0, _target = 0;
  int _misses = 0;
  DateTime? _timestamp;
  bool active = false;
  bool latestFixMatched = false;
  Offset? _arrivalPosition;
  double _arrivalRemaining = double.infinity;
  double get distanceToGoal => _arrivalPosition == null || _full.isEmpty
      ? double.infinity
      : CampusGpsService.mapDistanceMeters(
          _arrivalPosition!,
          _full.path.last.node.position.toOffset(),
        );
  bool get hasArrived => NavigationArrival.isArrived(
    matched: active && latestFixMatched,
    remainingMeters: _arrivalRemaining,
    distanceToGoal: distanceToGoal,
  );

  RouteFollowService({required TickerProvider vsync, required this.onChanged})
    : _animation = AnimationController(
        vsync: vsync,
        duration: const Duration(milliseconds: 600),
      ) {
    _animation.addListener(() {
      _display = _from + (_target - _from) * _animation.value;
      onChanged();
    });
  }
  RouteResult get route => RouteGeometry.remaining(_full, _display);

  /// Camera direction comes entirely from matched route geometry.
  /// Never calculate it between raw GPS and an animated route node.
  double? get cameraRotation {
    if (!active || _full.path.length < 2) {
      return null;
    }

    final remaining = _full.totalDistanceMeters - _target;
    if (remaining < 3.0) {
      return null;
    }

    final start = RouteGeometry.remaining(
      _full,
      _target,
    ).path.first.node.position.toOffset();

    // A short look-ahead smooths the transition through corners.
    final ahead = RouteGeometry.remaining(
      _full,
      math.min(_target + 3.0, _full.totalDistanceMeters),
    ).path.first.node.position.toOffset();

    final direction = ahead - start;
    if (direction.distanceSquared < 0.000001) {
      return null;
    }

    return -math.pi / 2 - math.atan2(direction.dy, direction.dx);
  }

  Offset? get position => active && !route.isEmpty
      ? route.path.first.node.position.toOffset()
      : null;
  Offset? get targetPosition => active && !_full.isEmpty
      ? RouteGeometry.remaining(
          _full,
          _target,
        ).path.first.node.position.toOffset()
      : null;

  void reset() {
    latestFixMatched = false;
    _arrivalPosition = null;
    _arrivalRemaining = double.infinity;
    _animation.stop();
    active = false;
    _full = RouteResult.empty;
    _goal = null;
    _timestamp = null;
    _misses = 0;
    _display = 0;
    _from = 0;
    _target = 0;
  }

  bool updateToAny(
    Graph graph,
    Offset point,
    Iterable<String> goals, {
    required double accuracy,
    required DateTime timestamp,
  }) {
    final ids = goals.toSet().toList()..sort();
    if (ids.isEmpty) {
      reset();
      return false;
    }

    return update(
      graph,
      point,
      ids.first,
      accuracy: accuracy,
      timestamp: timestamp,
      goalIds: ids,
    );
  }

  bool update(
    Graph graph,
    Offset point,
    String goal, {
    required double accuracy,
    required DateTime timestamp,
    Iterable<String>? goalIds,
  }) {
    latestFixMatched = false;
    final ids = (goalIds ?? [goal]).toSet().toList()..sort();
    final goalKey = jsonEncode(ids);
    if (_goal != goalKey) reset();
    // A rejected/stale GPS sample must not count as another off-route fix.
    if (_timestamp != null && !timestamp.isAfter(_timestamp!)) return active;
    final elapsed = _timestamp == null
        ? 1.0
        : timestamp.difference(_timestamp!).inMilliseconds / 1000.0;
    _timestamp = timestamp;
    final goodAccuracy = accuracy.isFinite && accuracy > 0 && accuracy <= 25;
    final radius = (goodAccuracy ? accuracy * 1.25 : 8.0)
        .clamp(6.0, 15.0)
        .toDouble();
    if (!goodAccuracy) return active;
    _arrivalPosition = point;
    if (active) {
      final q = RouteGeometry.match(
        _full,
        point,
        previous: _target,
        maxChange: math.min(60.0, 12 + elapsed * 3.0),
      );
      // Finished paths can have a single node.
      final endDistance = _full.path.length == 1
          ? CampusGpsService.mapDistanceMeters(
              point,
              _full.path.first.node.position.toOffset(),
            )
          : double.infinity;
      if ((q != null && q.distanceMeters <= radius) || endDistance <= radius) {
        latestFixMatched = true;
        _arrivalRemaining = math.max(
          0.0,
          _full.totalDistanceMeters - (q?.progressMeters ?? 0.0),
        );
        _misses = 0;
        final next = q?.progressMeters ?? 0.0;
        // Small backwards GPS jitter is ignored; genuine backtracking is allowed.
        if ((_target - next).abs() < 0.6) return true;
        _animation.stop();
        _from = _display;
        _target = next;
        _animation.forward(from: 0);
        return true;
      }
      if (++_misses < 3) return true;
      // Consistent departure: release the old route and resolve a nearby edge.
      _animation.stop();
      active = false;
    }
    _full = RouteGeometry.fromPosition(
      graph,
      point,
      goal,
      radius,
      goalIds: ids,
    );
    _goal = goalKey;
    _display = 0;
    _from = 0;
    _target = 0;
    _misses = 0;
    active = !_full.isEmpty;
    latestFixMatched = active;
    _arrivalRemaining = active ? _full.totalDistanceMeters : double.infinity;
    return active;
  }

  void dispose() => _animation.dispose();
}
