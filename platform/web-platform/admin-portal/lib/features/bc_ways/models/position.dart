import 'dart:math' as math;
import 'dart:ui';

/// A raw x/y coordinate in the campus SVG's coordinate space (0..3000),
/// matching nodes.json / destinations.json exactly — no remapping needed
/// between the JSON data and what gets drawn on screen.
class Position {
  final double x;
  final double y;
  const Position(this.x, this.y);

  factory Position.fromJson(Map<String, dynamic> json) => Position(
        (json['x'] as num).toDouble(),
        (json['y'] as num).toDouble(),
      );

  Offset toOffset() => Offset(x, y);

  double distanceTo(Position other) {
    final dx = x - other.x;
    final dy = y - other.y;
    return math.sqrt(dx * dx + dy * dy);
  }
}
