import 'path_node.dart';

/// The output of a Dijkstra search: the resolved path plus its total
/// distance. Deliberately has no turn-by-turn / UI logic in it — that's
/// NavigationService's job, kept separate so the route data stays reusable
/// (e.g. for drawing a preview on the map before the user starts walking).
class RouteResult {
  final List<PathNode> path;
  final double totalDistanceMeters;
  final bool isRerouted;

  const RouteResult({
    required this.path,
    required this.totalDistanceMeters,
    this.isRerouted = false,
  });

  static const empty = RouteResult(path: [], totalDistanceMeters: 0);
  bool get isEmpty => path.isEmpty;
}
