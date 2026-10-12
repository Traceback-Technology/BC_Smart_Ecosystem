import 'package:flutter/material.dart';
import '../services/bc_eats_store.dart';
import '../widgets/eats_order_widgets.dart';
import 'bc_eats_tracking_screen.dart';

class OrdersScreen extends StatelessWidget {
  final bool showBottomNavigation;
  const OrdersScreen({super.key, this.showBottomNavigation = true});
  @override
  Widget build(BuildContext context) {
    final store = BcEatsStore.instance;
    return ListenableBuilder(listenable: store, builder: (context, _) => EatsPage(title: 'Your Orders',
      children: [
        const Text('Your current orders and past campus favourites.'), const SizedBox(height: 12),
        eatsHeading(context, 'Current Orders'),
        if (!store.orders.any((order) => !order.completed)) const EatsCard(child: Text('No current orders. Add something delicious from Eats.')),
        for (final order in store.orders.where((order) => !order.completed)) _order(context, order),
        eatsHeading(context, 'Order History'),
        if (!store.orders.any((order) => order.completed)) const EatsCard(child: Text('Completed orders will appear here.')),
        for (final order in store.orders.where((order) => order.completed)) _order(context, order),
        const Text('Demo orders · saved for this app session.'),
      ]));
  }
  Widget _order(BuildContext context, EatsOrder order) => EatsCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    Wrap(spacing: 12, runSpacing: 8, crossAxisAlignment: WrapCrossAlignment.center, children: [
      order.fulfilment == Fulfilment.drone ? const DroneIcon(color: eatsRed) : const Icon(Icons.storefront, color: eatsRed),
      Text(order.fulfilment == Fulfilment.drone ? 'Drone delivery' : 'Pickup at Tuckshop', style: const TextStyle(fontWeight: FontWeight.bold)),
      Chip(label: Text(order.statusLabel)),
    ]), const SizedBox(height: 8), Text('Order #${order.id}'),
    Text('${order.placedAt.day}/${order.placedAt.month}/${order.placedAt.year} · ${money(order.total)}'),
    const SizedBox(height: 12), Text(order.lines.map((line) => '${line.quantity} × ${line.product.name}').join(', ')),
    const SizedBox(height: 16), EatsAction(order.completed ? 'View Order' : 'Track Order',
      onPressed: () => Navigator.push(context, MaterialPageRoute<void>(builder: (_) => BCEatsTrackingScreen(order: order)))),
  ]));
}
