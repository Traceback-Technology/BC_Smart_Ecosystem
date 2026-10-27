import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/features/bc_ways/models/node.dart';
import 'package:frontend/features/bc_ways/models/destination.dart';

void main() {
  for (final type in ['entrance', 'gate']) {
    test(
      '$type moves from square top-left to centre without changing JSON',
      () {
        final raw = <String, dynamic>{
          'id': 'entry',
          'type': type,
          'x': 379,
          'y': 1261,
        };
        final node = GraphNode.fromJson(raw);
        expect(node.position.x, 381);
        expect(node.position.y, 1263);
        expect(raw['x'], 379);
        expect(raw['y'], 1261);

        final loadedAgain = GraphNode.fromJson(raw);
        expect(loadedAgain.position.x, 381);

        // Animation copies already contain actual positions.
        final moved = node.copyWithPosition(400, 1300);
        expect(moved.position.x, 400);
        expect(moved.position.y, 1300);
      },
    );
  }

  test('generated path centres remain unchanged', () {
    final node = GraphNode.fromJson({
      'id': 'N001',
      'type': 'path',
      'x': 827,
      'y': 991,
    });
    expect(node.position.x, 827);
    expect(node.position.y, 991);
  });

  test('destination pin positions remain unchanged', () {
    final destination = Destination.fromJson({
      'id': 'florenville',
      'name': 'Florenville',
      'category': 'Residence',
      'position': {'x': 2331, 'y': 1166},
      'nearestNode': ['entry1', 'entry2'],
      'yard': 'north',
    });
    expect(destination.position.x, 2331);
    expect(destination.position.y, 1166);
    expect(destination.entranceNodeIds, ['entry1', 'entry2']);
  });
}
