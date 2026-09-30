import '../models/graph.dart';
import '../models/path_node.dart';
import '../models/route_result.dart';

/// Shortest-path search over the campus [Graph] using Dijkstra's algorithm.
class DijkstraService {
  final Graph graph;
  const DijkstraService(this.graph);

  /// Full route (with reconstructed path) from [startId] to [endId].
  /// [blockedEdges] excludes `"a|b"` (and `"b|a"`) edge keys — used to
  /// simulate a "path blocked ahead" reroute.
  RouteResult findRoute(String startId, String endId, {Set<String> blockedEdges = const {}}) {
    if (!graph.nodesById.containsKey(startId) || !graph.nodesById.containsKey(endId)) {
      return RouteResult.empty;
    }
    final result = _run(startId, blockedEdges: blockedEdges, target: endId);
    if (!result.distances.containsKey(endId)) return RouteResult.empty;

    final ids = <String>[endId];
    var cur = endId;
    while (cur != startId) {
      cur = result.previous[cur]!;
      ids.add(cur);
    }
    final orderedIds = ids.reversed.toList();
    final path = orderedIds
        .map((id) => PathNode(node: graph.nodesById[id]!, cumulativeDistance: result.distances[id]!))
        .toList();

    return RouteResult(
      path: path,
      totalDistanceMeters: result.distances[endId]!,
      isRerouted: blockedEdges.isNotEmpty,
    );
  }

  /// Distance-only shortest paths from [startId] to every reachable node —
  /// used to cheaply label many destinations at once (e.g. a destination
  /// list showing "3 min • 220 m" per row) without re-running Dijkstra once
  /// per destination.
  Map<String, double> distancesFrom(String startId) => _run(startId).distances;

  _SearchResult _run(String startId, {Set<String> blockedEdges = const {}, String? target}) {
    final distances = <String, double>{startId: 0};
    final previous = <String, String>{};
    final visited = <String>{};
    final frontier = <_Entry>[_Entry(startId, 0)];

    while (frontier.isNotEmpty) {
      frontier.sort((a, b) => a.dist.compareTo(b.dist));
      final current = frontier.removeAt(0);
      if (visited.contains(current.id)) continue;
      visited.add(current.id);
      if (target != null && current.id == target) break;

      for (final neighbor in graph.neighborsOf(current.id)) {
        final key = '${current.id}|${neighbor.nodeId}';
        final keyRev = '${neighbor.nodeId}|${current.id}';
        if (blockedEdges.contains(key) || blockedEdges.contains(keyRev)) continue;
        final newDist = current.dist + neighbor.distance;
        if (newDist < (distances[neighbor.nodeId] ?? double.infinity)) {
          distances[neighbor.nodeId] = newDist;
          previous[neighbor.nodeId] = current.id;
          frontier.add(_Entry(neighbor.nodeId, newDist));
        }
      }
    }
    return _SearchResult(distances, previous);
  }
}

class _Entry {
  final String id;
  final double dist;
  const _Entry(this.id, this.dist);
}

class _SearchResult {
  final Map<String, double> distances;
  final Map<String, String> previous;
  const _SearchResult(this.distances, this.previous);
}
