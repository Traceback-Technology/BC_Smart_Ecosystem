class Edge {
  final String nodeA;
  final String nodeB;
  final double distance;

  Edge({
    required this.nodeA,
    required this.nodeB,
    required this.distance,
  });

  factory Edge.fromJson(Map<String, dynamic> json) {
    return Edge(
      nodeA: json["nodeA"],
      nodeB: json["nodeB"],
      distance: json["distance"].toDouble(),
    );
  }
}