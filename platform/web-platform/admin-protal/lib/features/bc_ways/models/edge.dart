/// An undirected walkway segment connecting two node ids, with a
/// real-world distance in meters, loaded from edges.json.
class GraphEdge {
  final String nodeA;
  final String nodeB;
  final double distance;

  const GraphEdge({required this.nodeA, required this.nodeB, required this.distance});

  factory GraphEdge.fromJson(Map<String, dynamic> json) => GraphEdge(
        nodeA: json['nodeA'] as String,
        nodeB: json['nodeB'] as String,
        distance: (json['distance'] as num).toDouble(),
      );
}
