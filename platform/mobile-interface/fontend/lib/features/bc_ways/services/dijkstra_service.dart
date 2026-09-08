import 'package:collection/collection.dart';

import '../models/graph.dart';
import '../models/node.dart';
import '../models/path_node.dart';

class DijkstraService {
  List<Node> shortestPath(
    Graph graph,
    String start,
    String destination,
  ) {
    final distances = <String, double>{};
    final previous = <String, String?>{};
    final visited = <String>{};

    final queue = HeapPriorityQueue<PathNode>(
      (a, b) => a.distance.compareTo(b.distance),
    );

    for (final id in graph.nodes.keys) {
      distances[id] = double.infinity;
      previous[id] = null;
    }

    distances[start] = 0;

    queue.add(
      PathNode(
        id: start,
        distance: 0,
      ),
    );

    while (queue.isNotEmpty) {
      final current = queue.removeFirst();

      if (visited.contains(current.id)) {
        continue;
      }

      visited.add(current.id);

      if (current.id == destination) {
        break;
      }

      final neighbours = graph.adjacencyList[current.id] ?? [];

      for (final edge in neighbours) {
        final neighbour =
            edge.nodeA == current.id
                ? edge.nodeB
                : edge.nodeA;

        if (visited.contains(neighbour)) {
          continue;
        }

        final newDistance =
            distances[current.id]! + edge.distance;

        if (newDistance < distances[neighbour]!) {
          distances[neighbour] = newDistance;
          previous[neighbour] = current.id;

          queue.add(
            PathNode(
              id: neighbour,
              distance: newDistance,
            ),
          );
        }
      }
    }

    final List<Node> path = [];

    String? current = destination;

    while (current != null) {
      path.insert(0, graph.nodes[current]!);
      current = previous[current];
    }

    return path;
  }
}