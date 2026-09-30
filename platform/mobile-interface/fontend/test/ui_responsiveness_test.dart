import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fontend/main.dart';
import 'package:fontend/features/auth/screens/welcome_screen.dart';
import 'package:fontend/features/home/screens/home_screen.dart';
import 'package:fontend/features/bc_ways/constants/colors.dart';
import 'package:fontend/features/auth/models/app_session.dart';
import 'package:fontend/features/bc_ways/models/destination.dart';
import 'package:fontend/features/bc_ways/models/position.dart';
import 'package:fontend/features/bc_ways/screens/destination_search_screen.dart';
import 'package:fontend/features/bc_ways/services/navigation_service.dart';
import 'package:fontend/features/bc_ways/widgets/navigation_card.dart';
import 'package:fontend/shared/widgets/adaptive_map_layout.dart';
import 'package:fontend/shared/widgets/time_greeting.dart';
import 'package:fontend/shared/widgets/decorative_asset.dart';
import 'package:fontend/shared/widgets/campus_logo.dart';

Widget host(Widget screen, Brightness brightness, double scale) => MaterialApp(
  theme: BcTheme.light(), darkTheme: BcTheme.dark(),
  themeMode: brightness == Brightness.dark ? ThemeMode.dark : ThemeMode.light,
  builder: (context, child) => MediaQuery(
    data: MediaQuery.of(context).copyWith(textScaler: TextScaler.linear(scale)),
    child: child!,
  ),
  home: screen,
);

void setSize(WidgetTester tester, Size size) {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = size;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

void main() {
  testWidgets('Logo selects the supplied theme artwork', (tester) async {
    for (final brightness in Brightness.values) {
      await tester.pumpWidget(host(const Scaffold(body: CampusLogo()), brightness, 1));
      await tester.pumpAndSettle();
      final image = tester.widget<Image>(find.descendant(
        of: find.byType(CampusLogo), matching: find.byType(Image)));
      expect((image.image as AssetImage).assetName, brightness == Brightness.dark
        ? 'assets/images/BC_Logo_2.png' : 'assets/images/BC_Logo.png');
      expect(tester.takeException(), isNull);
    }
  });

  test('Greeting follows local time boundaries', () {
    expect(greetingFor(DateTime(2026, 9, 15, 4, 59)), 'Good evening');
    expect(greetingFor(DateTime(2026, 9, 15, 5)), 'Good morning');
    expect(greetingFor(DateTime(2026, 9, 15, 11, 59)), 'Good morning');
    expect(greetingFor(DateTime(2026, 9, 15, 12)), 'Good afternoon');
    expect(greetingFor(DateTime(2026, 9, 15, 16, 59)), 'Good afternoon');
    expect(greetingFor(DateTime(2026, 9, 15, 17)), 'Good evening');
  });

  testWidgets('Expanding destinations stays on-screen and map drags do not move the page', (tester) async {
    setSize(tester, const Size(390, 700));
    var expanded = false;
    var mapDrags = 0;
    await tester.pumpWidget(host(StatefulBuilder(builder: (context, setState) {
      return Scaffold(body: AdaptiveMapLayout(
        header: const [SizedBox(height: 100, child: Text('Map header'))],
        map: GestureDetector(
          key: const ValueKey('test-map'), behavior: HitTestBehavior.opaque,
          onPanUpdate: (_) => mapDrags++,
          child: const ColoredBox(color: Colors.grey),
        ),
        footer: [Column(mainAxisSize: MainAxisSize.min, children: [
          TextButton(onPressed: () => setState(() => expanded = !expanded),
            child: const Text('Popular Destinations')),
          if (expanded) const SizedBox(height: 110, child: Center(child: Text('Library destination'))),
        ])],
      ));
    }), Brightness.light, 1));
    await tester.pumpAndSettle();
    final mapFinder = find.byKey(const ValueKey('test-map'));
    final collapsedMap = tester.getRect(mapFinder);
    await tester.tap(find.text('Popular Destinations'));
    await tester.pumpAndSettle();
    expect(find.text('Library destination').hitTestable(), findsOneWidget);
    final expandedMap = tester.getRect(mapFinder);
    expect(expandedMap.height, lessThan(collapsedMap.height));
    final footerBeforeDrag = tester.getTopLeft(find.text('Popular Destinations'));
    await tester.drag(mapFinder, const Offset(0, -60));
    await tester.pumpAndSettle();
    expect(mapDrags, greaterThan(0));
    expect(tester.getRect(mapFinder), expandedMap);
    expect(tester.getTopLeft(find.text('Popular Destinations')), footerBeforeDrag);
    await tester.tap(find.text('Popular Destinations'));
    await tester.pumpAndSettle();
    expect(find.text('Library destination'), findsNothing);
    expect(tester.getRect(mapFinder), collapsedMap);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Device theme changes update welcome and an already opened Home', (tester) async {
    setSize(tester, const Size(390, 844));
    final dispatcher = tester.binding.platformDispatcher;
    addTearDown(dispatcher.clearPlatformBrightnessTestValue);
    dispatcher.platformBrightnessTestValue = Brightness.light;
    await tester.pumpWidget(const BCSmartApp());
    await tester.pumpAndSettle();
    expect(find.text('Device theme · Light'), findsOneWidget);
    dispatcher.platformBrightnessTestValue = Brightness.dark;
    await tester.pumpAndSettle();
    expect(find.text('Device theme · Dark'), findsOneWidget);
    await tester.ensureVisible(find.text('Continue as Student'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Continue as Student'));
    await tester.pumpAndSettle();
    expect(Theme.of(tester.element(find.byType(CampusDashboardPage))).brightness, Brightness.dark);
    dispatcher.platformBrightnessTestValue = Brightness.light;
    await tester.pumpAndSettle();
    expect(Theme.of(tester.element(find.byType(CampusDashboardPage))).brightness, Brightness.light);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  for (final size in [const Size(320, 568), const Size(844, 390), const Size(1024, 768)]) {
    for (final brightness in Brightness.values) {
      for (final scale in [1.0, 2.0]) {
        testWidgets('Home and welcome fit $size, $brightness, scale $scale', (tester) async {
          setSize(tester, size);
          await tester.pumpWidget(host(CampusDashboardPage(
            session: const AppSession.student(
              firstName: 'Test',
            ),
            onLogout: () {},
          ), brightness, scale));
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull);
          await tester.ensureVisible(find.text('Path blocked ahead'));
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull);
          expect(find.text('Frequent Destinations'), findsNothing);
          final artwork = tester.widgetList<DecorativeAsset>(find.byType(DecorativeAsset));
          expect(artwork.map((image) => image.path), containsAll([
            'assets/images/ways_illustration.png', 'assets/images/eats_illustration.png',
          ]));
          final ways = tester.getTopLeft(find.text('BC WAYS'));
          final eats = tester.getTopLeft(find.text('BC EATS'));
          expect(ways.dy, eats.dy);
          expect(ways.dx, lessThan(eats.dx));
          await tester.pumpWidget(host(WelcomeScreen(onStudentTap: () {}, onVisitorTap: () {}), brightness, scale));
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull);
          expect(find.byType(Scrollable), findsNothing);
          expect(find.text('Continue as Student').hitTestable(), findsOneWidget);
          expect(find.text('Continue as Guest / Parent').hitTestable(), findsOneWidget);
        });
      }
    }
  }

  testWidgets('Search handles long names, enlarged text and the keyboard', (tester) async {
    setSize(tester, const Size(320, 568));
    const destination = Destination(
      id: 'test', name: 'A long campus building destination name', category: 'Buildings',
      position: Position(100, 100), nearestNode: 'test_node', yard: CampusYard.main,
    );
    await tester.pumpWidget(host(DestinationSearchScreen(
      destinations: const [destination], categories: const [],
      travelInfoFor: (_) => const DestinationTravelInfo(distanceMeters: 1234, minutes: 16),
    ), Brightness.dark, 2));
    await tester.pumpAndSettle();
    final resultsScrollable = find.byWidgetPredicate(
      (widget) => widget is Scrollable && widget.axisDirection == AxisDirection.down,
    ).first;
    // ListView builds off-screen sections lazily; scroll to build the result.
    await tester.scrollUntilVisible(
      find.text(destination.name), 160, scrollable: resultsScrollable,
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    await tester.scrollUntilVisible(
      find.byType(TextField), -160, scrollable: resultsScrollable,
    );
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'long');
    tester.view.viewInsets = const FakeViewPadding(bottom: 260);
    addTearDown(tester.view.resetViewInsets);
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    // Keyboard resizing can move the result outside the list's build cache.
    await tester.scrollUntilVisible(
      find.text(destination.name), 100, scrollable: resultsScrollable,
    );
    await tester.pumpAndSettle();
    expect(find.text(destination.name), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  for (final size in [const Size(320, 568), const Size(844, 390)]) {
    testWidgets('Navigation controls fit and Exit works at $size', (tester) async {
      setSize(tester, size);
      var exited = false;
      await tester.pumpWidget(host(Scaffold(body: AdaptiveMapLayout(
        header: [NavigationCard(
          instruction: const NavInstruction(type: TurnType.left, label: 'Turn left', distanceMetersToTurn: 30),
          destinationName: 'A long campus destination name', etaMinutes: 12,
          remainingMeters: 1200, arrival: const TimeOfDay(hour: 14, minute: 30),
          onExit: () => exited = true,
        )],
        map: const ColoredBox(color: Colors.grey),
        footer: const [Text('Route summary')],
      )), Brightness.dark, 2));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      final exitButton = find.widgetWithText(ElevatedButton, 'Exit');
      await tester.scrollUntilVisible(
        exitButton, 120,
        scrollable: find.byWidgetPredicate(
          (widget) => widget is Scrollable && widget.axisDirection == AxisDirection.down,
        ).first,
      );
      // Scrolling updates the offset before the next layout/paint frame.
      await tester.pumpAndSettle();
      expect(exitButton.hitTestable(), findsOneWidget);
      await tester.tap(exitButton);
      await tester.pump();
      expect(exited, isTrue);
      expect(tester.takeException(), isNull);
    });
  }
}
