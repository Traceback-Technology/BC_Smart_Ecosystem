import '../models/node.dart';

class RouteResult {
  final List<Node> nodes;
  final double distance;

  const RouteResult({
    required this.nodes,
    required this.distance,
  });

  bool get isEmpty => nodes.isEmpty;

  Node get start => nodes.first;

  Node get end => nodes.last;
}