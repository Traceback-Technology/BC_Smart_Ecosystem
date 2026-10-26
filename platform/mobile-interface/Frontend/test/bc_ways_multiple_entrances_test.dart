import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/features/bc_ways/models/destination.dart';
import 'package:frontend/features/bc_ways/models/graph.dart';
import 'package:frontend/features/bc_ways/models/node.dart';
import 'package:frontend/features/bc_ways/models/position.dart';
import 'package:frontend/features/bc_ways/services/dijkstra_service.dart';
import 'package:frontend/features/bc_ways/services/route_follow_service.dart';

const graph = Graph(
  nodesById: {
    'a': GraphNode(id: 'a', type: 'entrance', position: Position(0, 0)),
    'b': GraphNode(id: 'b', type: 'entrance', position: Position(100, 0)),
    'isolated': GraphNode(
      id: 'isolated',
      type: 'entrance',
      position: Position(50, 100),
    ),
  },
  adjacency: {
    'a': [GraphAdjacency('b', 20)],
    'b': [GraphAdjacency('a', 20)],
  },
);

Destination destination(dynamic entrance) => Destination.fromJson({
  'id': 'florenville',
  'name': 'Florenville',
  'category': 'Residence',
  'position': {'x': 2331, 'y': 1166},
  'nearestNode': entrance,
  'yard': 'north',
});

void main() {
  test('single entrance remains compatible', () {
    expect(destination('a').entranceNodeIds, ['a']);
  });

  test('multiple entrances are trimmed and deduplicated', () {
    expect(destination(['a', ' b ', 'a']).entranceNodeIds, ['a', 'b']);
  });

  test('invalid entrance lists fail clearly', () {
    for (final value in <dynamic>[
      null,
      [],
      [''],
      ['a', 42],
    ]) {
      expect(() => destination(value), throwsFormatException);
    }
  });

  test('shortest reachable entrance wins regardless of list order', () {
    const search = DijkstraService(graph);
    final result = search.findRouteToAny('a', ['b', 'a']);
    expect(result.path.last.node.id, 'a');
    expect(result.totalDistanceMeters, 0);
  });

  test('unknown and disconnected entrances are skipped', () {
    const search = DijkstraService(graph);
    final result = search.findRouteToAny('a', ['missing', 'isolated', 'b']);
    expect(result.path.last.node.id, 'b');
    expect(result.totalDistanceMeters, 20);
    expect(search.findRouteToAny('a', ['missing', 'isolated']).isEmpty, isTrue);
    expect(search.findRouteToAny('missing', ['a']).isEmpty, isTrue);
    expect(search.findRouteToAny('a', []).isEmpty, isTrue);
  });

  test('blocked edges are respected', () {
    const search = DijkstraService(graph);
    expect(
      search.findRouteToAny('a', ['b'], blockedEdges: {'a|b'}).isEmpty,
      isTrue,
    );
  });

  test('graph distance wins over straight-line proximity', () {
    const weighted = Graph(
      nodesById: {
        's': GraphNode(id: 's', type: 'path', position: Position(0, 0)),
        'near': GraphNode(
          id: 'near',
          type: 'entrance',
          position: Position(1, 0),
        ),
        'far': GraphNode(
          id: 'far',
          type: 'entrance',
          position: Position(100, 0),
        ),
      },
      adjacency: {
        's': [GraphAdjacency('near', 100), GraphAdjacency('far', 20)],
        'near': [GraphAdjacency('s', 100)],
        'far': [GraphAdjacency('s', 20)],
      },
    );
    final result = DijkstraService(
      weighted,
    ).findRouteToAny('s', ['near', 'far']);
    expect(result.path.last.node.id, 'far');
    expect(result.totalDistanceMeters, 20);
  });

  test('position between nodes selects the shorter partial route', () {
    final result = RouteGeometry.fromPosition(
      graph,
      const Offset(75, 0),
      'a',
      10,
      goalIds: ['a', 'b'],
    );
    expect(result.path.first.node.position.toOffset(), const Offset(75, 0));
    expect(result.path.last.node.id, 'b');
    expect(result.totalDistanceMeters, closeTo(5, 0.001));
  });

  testWidgets('following keeps its entrance until the goals change', (
    tester,
  ) async {
    final follower = RouteFollowService(vsync: tester, onChanged: () {});
    addTearDown(follower.dispose);
    final now = DateTime(2026);

    expect(
      follower.updateToAny(
        graph,
        const Offset(49, 0),
        ['a', 'b'],
        accuracy: 5,
        timestamp: now,
      ),
      isTrue,
    );
    expect(follower.route.path.last.node.id, 'a');

    follower.updateToAny(
      graph,
      const Offset(51, 0),
      ['b', 'a'],
      accuracy: 5,
      timestamp: now.add(const Duration(seconds: 1)),
    );
    expect(follower.route.path.last.node.id, 'a');

    follower.updateToAny(
      graph,
      const Offset(51, 0),
      ['b'],
      accuracy: 5,
      timestamp: now.add(const Duration(seconds: 2)),
    );
    expect(follower.route.path.last.node.id, 'b');
  });
}
