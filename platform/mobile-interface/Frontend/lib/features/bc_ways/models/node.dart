import 'position.dart';

/// A routable point in the campus walking graph, loaded from nodes.json.
///
/// `type` is one of:
/// - `path`
/// - `entrance`
/// - `gate`
class GraphNode {
  // Figma entrance/gate markers are 4 x 4 squares.
  static const double entranceCentreOffset = 2.0;
  final String id;
  final String type;
  final Position position;

  const GraphNode({
    required this.id,
    required this.type,
    required this.position,
  });

  factory GraphNode.fromJson(Map<String, dynamic> json) {
    final type = json['type'] as String;
    final rawPosition = Position.fromJson(json);
    final isEntrance = type == 'entrance' || type == 'gate';

    return GraphNode(
      id: json['id'] as String,
      type: type,
      position: isEntrance
          ? Position(
              rawPosition.x + entranceCentreOffset,
              rawPosition.y + entranceCentreOffset,
            )
          : rawPosition,
    );
  }

  /// Creates a copy of this node with a different position.
  ///
  /// Used by the navigation simulation to place the
  /// user's location between two graph nodes.
  GraphNode copyWithPosition(double x, double y) {
    return GraphNode(id: id, type: type, position: Position(x, y));
  }
}
