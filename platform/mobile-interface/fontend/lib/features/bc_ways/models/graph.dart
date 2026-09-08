import 'edge.dart';
import 'node.dart';

class Graph {

  final Map<String, Node> nodes;

  final Map<String, List<Edge>> adjacencyList;

  Graph({
    required this.nodes,
    required this.adjacencyList,
  });

}