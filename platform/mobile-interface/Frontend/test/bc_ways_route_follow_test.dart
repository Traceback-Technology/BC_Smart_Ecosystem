import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/features/bc_ways/models/graph.dart';
import 'package:frontend/features/bc_ways/models/node.dart';
import 'package:frontend/features/bc_ways/models/position.dart';
import 'package:frontend/features/bc_ways/models/path_node.dart';
import 'package:frontend/features/bc_ways/models/route_result.dart';
import 'package:frontend/features/bc_ways/services/route_follow_service.dart';

const a = GraphNode(id: 'a', type: 'path', position: Position(0, 0));
const b = GraphNode(id: 'b', type: 'path', position: Position(100, 0));
const c = GraphNode(id: 'c', type: 'path', position: Position(100, 100));
const route = RouteResult(
  path: [
    PathNode(node: a, cumulativeDistance: 0),
    PathNode(node: b, cumulativeDistance: 20),
    PathNode(node: c, cumulativeDistance: 40),
  ],
  totalDistanceMeters: 40,
);
const graph = Graph(
  nodesById: {'a': a, 'b': b, 'c': c},
  adjacency: {
    'a': [GraphAdjacency('b', 20)],
    'b': [GraphAdjacency('a', 20), GraphAdjacency('c', 20)],
    'c': [GraphAdjacency('b', 20)],
  },
);
void main() {
  test('halfway along an edge trims the route and remaining metres', () {
    final q = RouteGeometry.match(route, const Offset(50, 5))!;
    expect(q.progressMeters, closeTo(10, 0.001));
    final tail = RouteGeometry.remaining(route, q.progressMeters);
    expect(tail.path.first.node.position.toOffset(), const Offset(50, 0));
    expect(tail.totalDistanceMeters, 30);
    expect(tail.path[1].cumulativeDistance, 10);
  });
  test('distance interpolation turns at the corner, without a diagonal', () {
    expect(
      RouteGeometry.remaining(route, 20).path.first.node.position.toOffset(),
      const Offset(100, 0),
    );
    expect(
      RouteGeometry.remaining(route, 25).path.first.node.position.toOffset(),
      const Offset(100, 25),
    );
    expect(RouteGeometry.remaining(route, 40).totalDistanceMeters, 0);
  });
  test('starting between nodes compares both endpoint routes', () {
    final forward = RouteGeometry.fromPosition(
      graph,
      const Offset(50, 0),
      'c',
      10,
    );
    final reverse = RouteGeometry.fromPosition(
      graph,
      const Offset(50, 0),
      'a',
      10,
    );
    expect(forward.totalDistanceMeters, 30);
    expect(reverse.totalDistanceMeters, 10);
    expect(reverse.path.last.node.id, 'a');
  });
  test('far away positions are not pulled onto the network', () {
    expect(
      RouteGeometry.fromPosition(
        graph,
        const Offset(500, 500),
        'c',
        10,
      ).isEmpty,
      isTrue,
    );
  });
  test('continuity rejects implausible progress jumps', () {
    expect(
      RouteGeometry.match(
        route,
        const Offset(100, 100),
        previous: 0,
        maxChange: 5,
      ),
      isNull,
    );
  });
  testWidgets('marker and remaining line share every animation frame', (
    tester,
  ) async {
    final follower = RouteFollowService(vsync: tester, onChanged: () {});
    final now = DateTime(2026);
    expect(
      follower.update(
        graph,
        const Offset(0, 0),
        'c',
        accuracy: 5,
        timestamp: now,
      ),
      isTrue,
    );
    follower.update(
      graph,
      const Offset(50, 0),
      'c',
      accuracy: 5,
      timestamp: now.add(const Duration(seconds: 4)),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(follower.position!.dy, 0);
    expect(follower.position!.dx, greaterThan(0));
    expect(follower.position!.dx, lessThan(50));
    expect(
      follower.route.path.first.node.position.toOffset(),
      follower.position,
    );
    await tester.pump(const Duration(milliseconds: 400));
    expect(follower.position!.dx, closeTo(50, 0.01));
    for (var i = 1; i <= 3; i++) {
      follower.update(
        graph,
        const Offset(500, 500),
        'c',
        accuracy: 5,
        timestamp: now.add(Duration(seconds: 4 + i)),
      );
      expect(follower.active, i < 3);
    }
    follower.dispose();
  });
}
