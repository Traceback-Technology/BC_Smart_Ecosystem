import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/features/bc_ways/models/graph.dart';
import 'package:frontend/features/bc_ways/models/node.dart';
import 'package:frontend/features/bc_ways/models/position.dart';
import 'package:frontend/features/bc_ways/services/campus_navigation_geometry.dart';
import 'package:frontend/features/bc_ways/services/route_follow_service.dart';

const graph = Graph(
  nodesById: {
    'a': GraphNode(id: 'a', type: 'path', position: Position(1000, 1500)),
    'b': GraphNode(id: 'b', type: 'path', position: Position(1100, 1500)),
  },
  adjacency: {
    'a': [GraphAdjacency('b', 21)],
    'b': [GraphAdjacency('a', 21)],
  },
);
void main() {
  test('exact Figma polygons distinguish campuses and the north notch', () {
    expect(CampusBoundaries.contains(const Offset(1500, 1600)), isTrue);
    expect(CampusBoundaries.contains(const Offset(1300, 2400)), isTrue);
    expect(CampusBoundaries.contains(const Offset(1700, 1000)), isFalse);
    expect(CampusBoundaries.contains(const Offset(0, 0)), isFalse);
    expect(CampusBoundaries.contains(CampusBoundaries.north.first), isTrue);
  });
  test('boundary hysteresis resists jitter but permits a real exit', () {
    final tracker = CampusBoundaryTracker();
    expect(tracker.update(const Offset(2400, 920), accuracy: 5), isTrue);
    expect(tracker.update(const Offset(2400, 887), accuracy: 5), isTrue);
    expect(tracker.update(const Offset(2400, 850), accuracy: 5), isFalse);
    expect(tracker.update(const Offset(2400, 898), accuracy: 5), isFalse);
    expect(tracker.update(const Offset(2400, 920), accuracy: 5), isTrue);
    expect(tracker.update(const Offset(2400, 850), accuracy: 60), isTrue);
  });
  test('nearby display point moves 20 percent; raw point is unchanged', () {
    const raw = Offset(1050, 1510);
    expect(
      SoftPathPosition.adjust(graph, raw, accuracy: 5),
      const Offset(1050, 1508),
    );
    expect(raw, const Offset(1050, 1510));
  });
  test('far points and poor accuracy are not pulled to a path', () {
    const far = Offset(1050, 1550);
    const near = Offset(1050, 1510);
    expect(SoftPathPosition.adjust(graph, far, accuracy: 5), far);
    expect(SoftPathPosition.adjust(graph, near, accuracy: 30), near);
    expect(
      SoftPathPosition.adjust(
        const Graph(nodesById: {}, adjacency: {}),
        near,
        accuracy: 5,
      ),
      near,
    );
  });
  test('arrival requires matched progress under 3m and physical proximity', () {
    bool arrived(bool matched, double remaining, double direct) =>
        NavigationArrival.isArrived(
          matched: matched,
          remainingMeters: remaining,
          distanceToGoal: direct,
        );
    expect(arrived(true, 2.9, 2), isTrue);
    expect(arrived(true, 3, 2), isFalse);
    expect(arrived(false, 0, 0), isFalse);
    expect(arrived(true, 0, 10), isFalse);
    expect(arrived(true, double.nan, 0), isFalse);
  });
  testWidgets('arrival and camera respect route disconnection', (tester) async {
    final follower = RouteFollowService(vsync: tester, onChanged: () {});
    addTearDown(follower.dispose);
    final now = DateTime(2026);
    follower.update(
      graph,
      const Offset(1090, 1500),
      'b',
      accuracy: 5,
      timestamp: now,
    );
    expect(follower.hasArrived, isTrue);
    follower.update(
      graph,
      const Offset(1500, 1700),
      'b',
      accuracy: 5,
      timestamp: now.add(const Duration(seconds: 1)),
    );
    expect(follower.hasArrived, isFalse);
    for (var i = 2; i <= 3; i++) {
      follower.update(
        graph,
        const Offset(1500, 1700),
        'b',
        accuracy: 5,
        timestamp: now.add(Duration(seconds: i)),
      );
    }
    expect(follower.active, isFalse);
    expect(follower.cameraRotation, isNull);
  });
  testWidgets(
    'camera heading follows path despite opposite lateral GPS noise',
    (tester) async {
      final follower = RouteFollowService(vsync: tester, onChanged: () {});

      try {
        final now = DateTime(2026);

        follower.update(
          graph,
          const Offset(1020, 1508),
          'b',
          accuracy: 5,
          timestamp: now,
        );

        final heading = follower.cameraRotation!;

        follower.update(
          graph,
          const Offset(1030, 1492),
          'b',
          accuracy: 5,
          timestamp: now.add(const Duration(seconds: 1)),
        );

        expect(follower.cameraRotation, closeTo(heading, 0.000001));
      } finally {
        follower.dispose();
      }
    },
  );
}
