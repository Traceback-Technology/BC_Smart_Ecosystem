import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/features/bc_eats/models/bc_eats_product.dart';
import 'package:frontend/features/bc_eats/services/bc_eats_store.dart';
import 'package:frontend/features/bc_eats/widgets/eats_product_card.dart';

void main() {
  const meal = BcEatsProduct(id: 'card-meal', name: 'Large burger meal with extra cheese',
    description: 'A freshly prepared burger, crispy fries and a cold drink',
    category: 'Meals', price: 65, imagePath: 'assets/images/eats_order_package.png');
  const other = BcEatsProduct(id: 'other', name: 'Other item', description: '',
    category: 'Meals', price: 20, imagePath: 'assets/images/eats_order_package.png');
  setUp(() => BcEatsStore.instance.clear());

  for (final brightness in Brightness.values) {
    for (final scale in [1.0, 1.8, 2.0]) {
      testWidgets('Menu quantity and long text: $brightness scale $scale', (tester) async {
        final store = BcEatsStore.instance..add(other);
        await tester.binding.setSurfaceSize(const Size(390, 844));
        addTearDown(() => tester.binding.setSurfaceSize(null));
        await tester.pumpWidget(MaterialApp(theme: ThemeData(brightness: brightness),
          home: MediaQuery(data: MediaQueryData(textScaler: TextScaler.linear(scale)),
            child: Scaffold(body: Center(child: ListenableBuilder(listenable: store,
              builder: (context, _) => SizedBox(width: 205,
                height: EatsProductCard.heightFor(context, meal, 205),
                child: const EatsProductCard(product: meal))))))));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        expect(find.byKey(const ValueKey('eats-remove-card-meal')), findsNothing);
        final add = find.byKey(const ValueKey('eats-add-card-meal'));
        final minus = find.byKey(const ValueKey('eats-remove-card-meal'));
        final quantity = find.byKey(const ValueKey('eats-quantity-card-meal'));
        await tester.tap(add); await tester.pumpAndSettle();
        expect(tester.widget<Text>(quantity).data, '1');
        expect(minus, findsOneWidget);
        await tester.tap(add); await tester.pumpAndSettle();
        expect(tester.widget<Text>(quantity).data, '2');
        expect(store.quantityFor(other.id), 1);
        expect(tester.takeException(), isNull);
        await tester.tap(minus); await tester.pumpAndSettle();
        expect(tester.widget<Text>(quantity).data, '1');
        // Changes made in the cart also update the card.
        store.decrease(meal.id); await tester.pumpAndSettle();
        expect(minus, findsNothing);
        expect(quantity, findsNothing);
        expect(store.quantityFor(other.id), 1);
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox.shrink());
      });
    }
  }
}
