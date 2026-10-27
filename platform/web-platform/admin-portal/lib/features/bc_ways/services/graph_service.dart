import 'dart:math' as math;
import 'dart:ui';

import '../models/destination.dart';
import '../models/edge.dart';
import '../models/filter_category.dart';
import '../models/graph.dart';
import '../models/node.dart';
import 'json_service.dart';

class GraphService {
  GraphService._();

  static final GraphService instance =
      GraphService._();

  final JsonService _json =
      const JsonService();

  Graph? _graph;

  Graph get graph => _graph!;

  final Map<String, Destination>
      _destinationsById = {};

  List<Destination> get destinations =>
      _destinationsById.values.toList();

  List<FilterCategory> _categories = [];

  List<FilterCategory> get categories =>
      _categories;

  bool _loaded = false;

  bool get isLoaded => _loaded;

  Future<void> load() async {
    if (_loaded) return;

    final results = await Future.wait([
      _json.loadNodes(),
      _json.loadEdges(),
      _json.loadDestinations(),
      _json.loadCategories(),
    ]);

    final nodesById =
        <String, GraphNode>{};

    for (final raw in results[0]) {
      final node = GraphNode.fromJson(
        raw as Map<String, dynamic>,
      );

      nodesById[node.id] = node;
    }

    final adjacency =
        <String, List<GraphAdjacency>>{};

    for (final raw in results[1]) {
      final edge = GraphEdge.fromJson(
        raw as Map<String, dynamic>,
      );

      adjacency
          .putIfAbsent(
            edge.nodeA,
            () => [],
          )
          .add(
            GraphAdjacency(
              edge.nodeB,
              edge.distance,
            ),
          );

      adjacency
          .putIfAbsent(
            edge.nodeB,
            () => [],
          )
          .add(
            GraphAdjacency(
              edge.nodeA,
              edge.distance,
            ),
          );
    }

    _graph = Graph(
      nodesById: nodesById,
      adjacency: adjacency,
    );

    for (final raw in results[2]) {
      final destination =
          Destination.fromJson(
        raw as Map<String, dynamic>,
      );

      _destinationsById[
          destination.id] = destination;
    }

    _categories = results[3]
        .map(
          (raw) => FilterCategory.fromJson(
            raw as Map<String, dynamic>,
          ),
        )
        .toList();

    _loaded = true;
  }

  // ---------------------------------------------------------------------------
  // DESTINATIONS
  // ---------------------------------------------------------------------------

  Destination? destinationByName(
    String query,
  ) {
    final q =
        query.trim().toLowerCase();

    if (q.isEmpty) return null;

    for (final d
        in _destinationsById.values) {
      if (d.name.toLowerCase() == q) {
        return d;
      }
    }

    for (final d
        in _destinationsById.values) {
      if (d.name
          .toLowerCase()
          .contains(q)) {
        return d;
      }
    }

    return null;
  }

  FilterCategory? categoryById(
    String? id,
  ) {
    if (id == null) return null;

    for (final category
        in _categories) {
      if (category.id == id) {
        return category;
      }
    }

    return null;
  }

  // ---------------------------------------------------------------------------
  // NEAREST NODE
  // ---------------------------------------------------------------------------

  GraphNode? nearestNodeTo(
    Offset mapPosition,
  ) {
    if (_graph == null ||
        graph.nodesById.isEmpty) {
      return null;
    }

    GraphNode? nearest;

    double smallestDistance =
        double.infinity;

    for (final node
        in graph.nodesById.values) {
      final dx =
          node.position.x -
          mapPosition.dx;

      final dy =
          node.position.y -
          mapPosition.dy;

      final distance =
          math.sqrt(
        dx * dx + dy * dy,
      );

      if (distance <
          smallestDistance) {
        smallestDistance = distance;
        nearest = node;
      }
    }

    return nearest;
  }

  String? nearestNodeIdTo(
    Offset mapPosition,
  ) {
    return nearestNodeTo(
      mapPosition,
    )?.id;
  }

  double distanceToNearestNode(
    Offset mapPosition,
  ) {
    final node =
        nearestNodeTo(mapPosition);

    if (node == null) {
      return double.infinity;
    }

    final dx =
        node.position.x -
        mapPosition.dx;

    final dy =
        node.position.y -
        mapPosition.dy;

    return math.sqrt(
      dx * dx + dy * dy,
    );
  }

  /// Determines whether the GPS-mapped position is close enough
  /// to the walking graph to be treated as part of the campus
  /// navigation network.
  ///
  /// 250 SVG units is approximately 45-55 metres with the
  /// current calibration.
  bool isWithinNavigationNetwork(
    Offset mapPosition, {
    double maxDistance = 250,
  }) {
    return distanceToNearestNode(
          mapPosition,
        ) <=
        maxDistance;
  }

  // ---------------------------------------------------------------------------
  // FALLBACK METHODS
  // ---------------------------------------------------------------------------

  String? resolveHomeNodeId() {
    if (_graph == null ||
        graph.nodesById.isEmpty) {
      return null;
    }

    if (graph.nodesById
        .containsKey('main_entrance')) {
      return 'main_entrance';
    }

    if (graph.nodesById
        .containsKey('main_gate')) {
      return 'main_gate';
    }

    for (final node
        in graph.nodesById.values) {
      if (node.type.toLowerCase() ==
          'entrance') {
        return node.id;
      }
    }

    for (final node
        in graph.nodesById.values) {
      if (node.type.toLowerCase() ==
          'gate') {
        return node.id;
      }
    }

    return graph.nodesById.values.first.id;
  }

  String? resolveRoutingStartNode({
    Offset? mapPosition,
  }) {
    if (mapPosition != null) {
      final nearest =
          nearestNodeIdTo(
        mapPosition,
      );

      if (nearest != null) {
        return nearest;
      }
    }

    return resolveHomeNodeId();
  }

  // ---------------------------------------------------------------------------
  // SEARCH
  // ---------------------------------------------------------------------------

  List<Destination> search(
    String query, {
    String? categoryId,
  }) {
    final q =
        query.trim().toLowerCase();

    final category =
        categoryById(categoryId);

    return _destinationsById.values
        .where((destination) {
      final matchesQuery =
          q.isEmpty ||
          destination.name
              .toLowerCase()
              .contains(q);

      final matchesCategory =
          category == null ||
          category
              .matchesDestinationCategory(
            destination.category,
          );

      return matchesQuery &&
          matchesCategory;
    }).toList()
      ..sort(
        (a, b) =>
            a.name.compareTo(b.name),
      );
  }
}