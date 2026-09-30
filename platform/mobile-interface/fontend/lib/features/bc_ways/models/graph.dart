import 'node.dart';

/// In-memory representation of the campus walking graph: every node plus
/// an undirected adjacency list built from edges.json. Pure data — no
/// loading or pathfinding logic lives here (see GraphService / DijkstraService).
class Graph {
  final Map<String, GraphNode> nodesById;
  final Map<String, List<GraphAdjacency>> adjacency;

  const Graph({required this.nodesById, required this.adjacency});

  List<GraphAdjacency> neighborsOf(String nodeId) => adjacency[nodeId] ?? const [];
}

class GraphAdjacency {
  final String nodeId;
  final double distance;
  const GraphAdjacency(this.nodeId, this.distance);
}
