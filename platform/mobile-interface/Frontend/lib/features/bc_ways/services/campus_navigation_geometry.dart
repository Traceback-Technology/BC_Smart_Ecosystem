import 'dart:ui';
import '../models/graph.dart';
import '../constants/map_constants.dart';
import 'campus_gps_service.dart';

/// Exact closed perimeter vertices from campus_boundaries.svg (3000 x 3000).
/// These are already SVG coordinates: no entrance/node offsets apply.
class CampusBoundaries {
  static const north = <Offset>[
    Offset(571, 789.5),
    Offset(1437, 1137),
    Offset(2037.5, 1204),
    Offset(2132, 892.5),
    Offset(2623, 892.5),
    Offset(2685, 2143.5),
    Offset(2238, 2184.5),
    Offset(285.5, 1505.5),
  ];
  static const main = <Offset>[
    Offset(1236, 1899),
    Offset(1636, 2034),
    Offset(1523, 2835),
    Offset(1437, 2835),
    Offset(913.5, 2683.5),
  ];
  static const polygons = [north, main];

  static Offset closestPoint(Offset p, Offset a, Offset b) {
    final d = b - a;
    if (d.distanceSquared == 0) {
      return a;
    }
    final t = (((p - a).dx * d.dx + (p - a).dy * d.dy) / d.distanceSquared)
        .clamp(0.0, 1.0)
        .toDouble();
    return a + d * t;
  }

  static bool containsPolygon(List<Offset> polygon, Offset p) {
    if (!p.dx.isFinite || !p.dy.isFinite) {
      return false;
    }
    var inside = false;
    for (var i = 0, j = polygon.length - 1; i < polygon.length; j = i++) {
      final a = polygon[j], b = polygon[i];
      if ((closestPoint(p, a, b) - p).distanceSquared < 1e-12) {
        return true;
      }
      if ((a.dy > p.dy) != (b.dy > p.dy) &&
          p.dx < (b.dx - a.dx) * (p.dy - a.dy) / (b.dy - a.dy) + a.dx) {
        inside = !inside;
      }
    }
    return inside;
  }

  static bool contains(Offset p) =>
      polygons.any((polygon) => containsPolygon(polygon, p));

  static double distanceToBoundaryMeters(Offset p) {
    var nearest = double.infinity;
    for (final polygon in polygons) {
      for (var i = 0; i < polygon.length; i++) {
        final q = closestPoint(
          p,
          polygon[i],
          polygon[(i + 1) % polygon.length],
        );
        final distance = CampusGpsService.mapDistanceMeters(p, q);
        if (distance < nearest) {
          nearest = distance;
        }
      }
    }
    return nearest;
  }
}

/// Use raw mapped GPS, never the route-snapped/display position.
class CampusBoundaryTracker {
  bool? _inside;
  static const hysteresisMeters = 3.0;
  bool update(Offset raw, {required double accuracy}) {
    if (!raw.dx.isFinite || !raw.dy.isFinite) {
      return _inside ?? false;
    }
    final candidate = CampusBoundaries.contains(raw);
    if (_inside == null) {
      _inside = candidate;
    } else if (accuracy.isFinite &&
        accuracy > 0 &&
        accuracy <= 25 &&
        candidate != _inside &&
        CampusBoundaries.distanceToBoundaryMeters(raw) > hysteresisMeters) {
      _inside = candidate;
    }
    return _inside!;
  }
}

/// Display-only attraction. Does not modify raw GPS, graph nodes or recordings.
class SoftPathPosition {
  static const radiusMeters = 3.0;
  static Offset adjust(Graph graph, Offset raw, {required double accuracy}) {
    if (!raw.dx.isFinite ||
        !raw.dy.isFinite ||
        !accuracy.isFinite ||
        accuracy <= 0 ||
        accuracy > 15) {
      return raw;
    }
    Offset? closest;
    var nearest = double.infinity;
    for (final a in graph.nodesById.values) {
      for (final edge in graph.neighborsOf(a.id)) {
        if (a.id.compareTo(edge.nodeId) >= 0) {
          continue;
        }
        final b = graph.nodesById[edge.nodeId];
        if (b == null) {
          continue;
        }
        final q = CampusBoundaries.closestPoint(
          raw,
          a.position.toOffset(),
          b.position.toOffset(),
        );
        final distance = CampusGpsService.mapDistanceMeters(raw, q);
        if (distance < nearest) {
          nearest = distance;
          closest = q;
        }
      }
    }
    if (closest == null || nearest > radiusMeters) {
      return raw;
    }
    return Offset.lerp(raw, closest, 0.2)!;
  }
}

class NavigationArrival {
  static bool isArrived({
    required bool matched,
    required double remainingMeters,
    required double distanceToGoal,
  }) =>
      matched &&
      remainingMeters.isFinite &&
      remainingMeters >= 0 &&
      remainingMeters < BcWaysMapConstants.arrivalRadiusMeters &&
      distanceToGoal.isFinite &&
      distanceToGoal < BcWaysMapConstants.arrivalRadiusMeters;
}
