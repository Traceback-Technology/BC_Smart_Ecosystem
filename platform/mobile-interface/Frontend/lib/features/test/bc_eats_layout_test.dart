import 'package:flutter/material.dart';
import 'package:frontend/features/bc_ways/widgets/bc_bottom_navigation_bar.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import '../auth/models/app_session.dart';
import 'package:frontend/features/bc_eats/models/bc_eats_product.dart';
import 'package:frontend/features/bc_eats/services/bc_eats_store.dart';
import 'package:frontend/features/bc_eats/screens/bc_eats_cart_screen.dart';
import 'package:frontend/features/bc_eats/screens/bc_eats_checkout_screen.dart';
import 'package:frontend/features/bc_eats/screens/bc_eats_tracking_screen.dart';
import 'package:frontend/features/bc_eats/screens/bc_eats_drone_screen.dart';
import 'package:frontend/features/bc_eats/screens/bc_eats_shell.dart';
import 'package:frontend/features/bc_eats/widgets/eats_order_widgets.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const meal = BcEatsProduct(
    id: 'layout-meal',
    name: 'Beef Burger Meal',
    description: 'Beef burger, fries & a soft drink',
    category: 'Meals',
    price: 65,
    imagePath: 'assets/images/eats_order_package.png',
  );
  setUp(() {
    BcEatsStore.instance.clear();
    BcEatsStore.instance.chooseFulfilment(Fulfilment.drone);
    BcEatsStore.instance.updateContact(
      'Sipho Dlamini',
      '071 234 5678',
      'sipho@campus.test',
    );
  });
  Future<void> loadFonts() async {
    final loader = FontLoader('BCEatsPoppins');
    for (final name in ['Regular', 'Medium', 'SemiBold', 'Bold']) {
      loader.addFont(rootBundle.load('assets/fonts/Poppins-$name.ttf'));
    }
    await loader.load();
  }

  Future<void> show(
    WidgetTester tester,
    Widget screen,
    Size size,
    Brightness brightness,
    double scale,
  ) async {
    await tester.binding.setSurfaceSize(size);
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(useMaterial3: true, brightness: brightness),
        home: MediaQuery(
          data: MediaQueryData(
            size: size,
            textScaler: TextScaler.linear(scale),
          ),
          child: EatsFlowScope(
            navigate: (_) {},
            child: Scaffold(
              body: screen,
              bottomNavigationBar: BcBottomNavigationBar(
                selectedIndex: 3,
                onTap: (_) {},
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  for (final size in [
    const Size(320, 568),
    const Size(390, 844),
    const Size(853, 1844),
    const Size(1024, 768),
  ]) {
    for (final brightness in Brightness.values) {
      for (final scale in [1.0, 1.8]) {
        testWidgets('Orders layouts ${size.width} $brightness scale $scale', (
          tester,
        ) async {
          await loadFonts();
          final store = BcEatsStore.instance..add(meal);
          for (final page in [
            const BCEatsCartScreen(),
            const BCEatsCheckoutScreen(),
          ]) {
            await show(tester, page, size, brightness, scale);
            expect(tester.takeException(), isNull);
            await tester.drag(
              find.byType(ListView).first,
              const Offset(0, -900),
            );
            await tester.pumpAndSettle();
            expect(tester.takeException(), isNull);
          }
          final order = store.placeDemoOrder(EatsPayment.card, '071 234 5678');
          for (var status = 1; status <= 3; status++) {
            await show(
              tester,
              BCEatsTrackingScreen(order: order),
              size,
              brightness,
              scale,
            );
            expect(tester.takeException(), isNull);
            await tester.drag(
              find.byType(ListView).first,
              const Offset(0, -1000),
            );
            await tester.pumpAndSettle();
            expect(tester.takeException(), isNull);
            if (status < 3) store.advanceDemo(order);
          }
          store.chooseFulfilment(Fulfilment.pickup);
          store.add(meal);
          final pickup = store.placeDemoOrder(EatsPayment.cash, '071 234 5678');
          store.advanceDemo(pickup);
          await show(
            tester,
            BCEatsTrackingScreen(order: pickup),
            size,
            brightness,
            scale,
          );
          expect(tester.takeException(), isNull);
          await show(
            tester,
            BCEatsDroneScreen(order: order),
            size,
            brightness,
            scale,
          );
          expect(tester.takeException(), isNull);
          await tester.pumpWidget(const SizedBox.shrink());
          await tester.binding.setSurfaceSize(null);
        });
      }
    }
  }
  testWidgets(
    'Eats shell keeps footer while cart opens and back returns to Eats',
    (tester) async {
      BcEatsStore.instance.add(meal);
      await tester.binding.setSurfaceSize(const Size(390, 844));
      await tester.pumpWidget(
        MaterialApp(
          home: const BCEatsShell(
            session: AppSession.student(fullName: 'Test Student'),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.textContaining('View cart').first);
      await tester.pumpAndSettle();
      expect(find.textContaining('Your Cart'), findsOneWidget);
      expect(find.byType(BcBottomNavigationBar), findsOneWidget);
      await tester.tap(find.byIcon(Icons.arrow_back).first);
      await tester.pumpAndSettle();
      expect(find.textContaining('View cart'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.binding.setSurfaceSize(null);
    },
  );
}
