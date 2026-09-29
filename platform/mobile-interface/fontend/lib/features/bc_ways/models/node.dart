class Node {
  final String id;
  final String type;
  final double x;
  final double y;

  Node({
    required this.id,
    required this.type,
    required this.x,
    required this.y,
  });

  factory Node.fromJson(Map<String, dynamic> json) {
    return Node(
      id: json["id"],
      type: json["type"],
      x: json["x"].toDouble(),
      y: json["y"].toDouble(),
    );
  }
}