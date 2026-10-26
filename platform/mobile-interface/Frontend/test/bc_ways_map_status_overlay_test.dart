import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/features/bc_ways/widgets/map_status_overlay.dart';

void main() {
  for (final size in [const Size(320, 420), const Size(700, 220)]) {
    testWidgets('overlay scrolls on $size and leaves GPS controls clear', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Align(
              alignment: Alignment.topLeft,
              child: SizedBox(
                width: size.width,
                height: size.height,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    const ColoredBox(color: Colors.blue),
                    MapStatusOverlay(
                      viewportHeight: size.height,
                      children: [
                        for (var i = 0; i < 8; i++)
                          SizedBox(height: 80, child: Text('Instruction $i')),
                        TextButton(
                          onPressed: () {},
                          child: const Text('Exit navigation'),
                        ),
                      ],
                    ),
                    const Positioned(
                      right: 14,
                      bottom: 14,
                      child: SizedBox(
                        key: ValueKey('follow-control'),
                        width: 48,
                        height: 48,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
      expect(tester.takeException(), isNull);
      final scroll = find.descendant(
        of: find.byType(MapStatusOverlay),
        matching: find.byType(SingleChildScrollView),
      );
      final scrollRect = tester.getRect(scroll);
      final controlRect = tester.getRect(
        find.byKey(const ValueKey('follow-control')),
      );
      expect(scrollRect.bottom, lessThan(controlRect.top));
      final scrollable = find.descendant(
        of: find.byType(MapStatusOverlay),
        matching: find.byType(Scrollable),
      );
      await tester.scrollUntilVisible(
        find.text('Exit navigation'),
        100,
        scrollable: scrollable,
      );
      expect(find.text('Exit navigation').hitTestable(), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }
  testWidgets('map receives taps outside the visible overlay', (tester) async {
    var taps = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 360,
            height: 500,
            child: Stack(
              fit: StackFit.expand,
              children: [
                GestureDetector(
                  onTap: () => taps++,
                  behavior: HitTestBehavior.opaque,
                  child: const ColoredBox(color: Colors.blue),
                ),
                MapStatusOverlay(
                  viewportHeight: 500,
                  children: const [
                    SizedBox(
                      height: 50,
                      child: Text('Navigation instructions'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
    await tester.tapAt(const Offset(180, 350));
    expect(taps, 1);
    expect(tester.takeException(), isNull);
  });
}
