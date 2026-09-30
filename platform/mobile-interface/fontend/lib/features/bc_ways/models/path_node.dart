import 'node.dart';

/// A single waypoint along a resolved route.
///
/// `cumulativeDistance` represents how many metres have been
/// travelled from the beginning of the route when this waypoint
/// is reached.
class PathNode {
  final GraphNode node;
  final double cumulativeDistance;

  const PathNode({
    required this.node,
    required this.cumulativeDistance,
  });

  /// Creates a copy with a different graph node.
  PathNode copyWithNode(GraphNode node) {
    return PathNode(
      node: node,
      cumulativeDistance: cumulativeDistance,
    );
  }
}