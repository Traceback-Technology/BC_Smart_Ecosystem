import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/features/bc_eats/models/bc_eats_product.dart';
import 'package:frontend/features/bc_eats/services/bc_eats_store.dart';

void main() {
  const product = BcEatsProduct(id: 'burger', name: 'Burger', description: '', category: 'Meals', price: 65, imagePath: '');
  test('Cart quantities, removal and integer totals stay consistent', () {
    final store = BcEatsStore();
    store.add(product); store.add(product);
    expect(store.count, 2); expect(store.subtotal, 13000); expect(store.total, 15000);
    store.decrease(product.id); expect(store.total, 8500);
    store.decrease(product.id); expect(store.count, 0); expect(store.total, 0);
    store.add(product.copyWith(isAvailable: false)); expect(store.count, 0);
  });
  test('Pickup has no delivery fee and cash cannot be used with drone delivery', () {
    final store = BcEatsStore()..add(product);
    expect(() => store.placeDemoOrder(EatsPayment.cash, 'Student'), throwsStateError);
    store.chooseFulfilment(Fulfilment.pickup);
    expect(store.total, 7000);
    final order = store.placeDemoOrder(EatsPayment.cash, 'Student');
    expect(order.deliveryFee, 0); expect(order.fulfilment, Fulfilment.pickup);
    expect(store.count, 0); expect(store.orders.single, order);
  });
  test('Order snapshots survive cart changes and progress into history', () {
    final store = BcEatsStore()..add(product);
    final order = store.placeDemoOrder(EatsPayment.card, 'Student');
    store.add(product); store.add(product);
    expect(order.lines.single.quantity, 1); expect(order.total, 8500);
    for (var i = 0; i < 3; i++) { store.advanceDemo(order); }
    expect(order.completed, true); expect(order.completedAt, isNotNull);
    store.advanceDemo(order); expect(order.status, EatsStatus.completed);
    store.rate(order, 5); expect(order.rating, 5);
    store.reorder(order); expect(store.count, 3);
  });
  test('Drone unavailability switches checkout to pickup', () {
    final store = BcEatsStore()..add(product);
    store.setDroneAvailable(false);
    store.chooseFulfilment(Fulfilment.drone);
    expect(store.fulfilment, Fulfilment.pickup); expect(store.deliveryFee, 0);
  });
  test('An empty cart cannot create an order', () {
    expect(() => BcEatsStore().placeDemoOrder(EatsPayment.card, 'Student'), throwsStateError);
  });
}
