import '../models/edge.dart';
import '../models/graph.dart';
import '../models/node.dart';

class GraphService {
  Graph buildGraph(
    List<Node> nodes,
    List<Edge> edges,
  ) {
    final nodeMap = <String, Node>{};
    final adjacency = <String, List<Edge>>{};

    for (final node in nodes) {
      nodeMap[node.id] = node;
      adjacency[node.id] = [];
    }

    for (final edge in edges) {
      adjacency[edge.nodeA]?.add(edge);
      adjacency[edge.nodeB]?.add(edge);
    }

    return Graph(
      nodes: nodeMap,
      adjacencyList: adjacency,
    );
  }
}