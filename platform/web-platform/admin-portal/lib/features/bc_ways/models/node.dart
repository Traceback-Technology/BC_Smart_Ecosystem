import 'position.dart';

/// A routable point in the campus walking graph, loaded from nodes.json.
///
/// `type` is one of:
/// - `path`
/// - `entrance`
/// - `gate`
class GraphNode {
  final String id;
  final String type;
  final Position position;

  const GraphNode({
    required this.id,
    required this.type,
    required this.position,
  });

  factory GraphNode.fromJson(
    Map<String, dynamic> json,
  ) {
    return GraphNode(
      id: json['id'] as String,
      type: json['type'] as String,
      position: Position.fromJson(json),
    );
  }

  /// Creates a copy of this node with a different position.
  ///
  /// Used by the navigation simulation to place the
  /// user's location between two graph nodes.
  GraphNode copyWithPosition(
    double x,
    double y,
  ) {
    return GraphNode(
      id: id,
      type: type,
      position: Position(x, y),
    );
  }
}