import 'package:flutter/material.dart';
import '../services/bc_eats_store.dart';
import '../widgets/eats_order_widgets.dart';
import '../widgets/eats_dialogs.dart';
import 'bc_eats_checkout_screen.dart';

class BCEatsCartScreen extends StatefulWidget {
  const BCEatsCartScreen({super.key});

  @override
  State<BCEatsCartScreen> createState() => _BCEatsCartScreenState();
}

class _BCEatsCartScreenState extends State<BCEatsCartScreen> {
  bool _checkoutVisited = false;

  @override
  Widget build(BuildContext context) {
    final store = BcEatsStore.instance;
    return ListenableBuilder(
      listenable: store,
      builder: (context, _) => EatsPage(
        titleWidget: Text.rich(
          TextSpan(
            children: [
              const TextSpan(text: 'Your Cart '),
              TextSpan(
                text: '(${store.count})',
                style: const TextStyle(color: eatsRed),
              ),
            ],
          ),
          style: const TextStyle(
            fontSize: 24,
            height: 1.4,
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: 'Review your items before checkout.',
        action: OutlinedButton.icon(
          style: OutlinedButton.styleFrom(
            foregroundColor: eatsRed,
            side: BorderSide(color: eatsRed.withValues(alpha: .3)),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 11),
          ),
          icon: const Icon(Icons.delete_outline, size: 18),
          label: const Text('Clear Cart', style: TextStyle(fontSize: 12)),
          onPressed: store.count == 0
              ? null
              : () async {
                  final clear = await showDialog<bool>(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text('Clear your cart?'),
                      content: const Text('Remove all items from your cart?'),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context, false),
                          child: const Text('Keep items'),
                        ),
                        TextButton(
                          onPressed: () => Navigator.pop(context, true),
                          child: const Text('Clear cart'),
                        ),
                      ],
                    ),
                  );
                  if (clear == true) store.clear();
                },
        ),
        children: store.count == 0
            ? [
                const EatsCard(
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: 32),
                    child: Column(
                      children: [
                        Icon(
                          Icons.shopping_bag_outlined,
                          size: 64,
                          color: eatsYellow,
                        ),
                        SizedBox(height: 20),
                        Text('Your cart is empty.'),
                        SizedBox(height: 8),
                        Text('Add something delicious from Eats.'),
                      ],
                    ),
                  ),
                ),
                EatsAction(
                  'Browse Eats',
                  onPressed: () {
                    final flow = EatsFlowScope.maybeOf(context);
                    if (flow != null) {
                      flow.navigate(2);
                    } else {
                      Navigator.maybePop(context);
                    }
                  },
                ),
              ]
            : [
                for (final line in store.cart) _CartItem(line: line),
                InkWell(
                  borderRadius: BorderRadius.circular(13),
                  onTap: () => editEatsNotes(context),
                  child: EatsCard(
                    shadow: true,
                    child: Row(
                      children: [
                        const EatsCircle(
                          color: eatsRed,
                          child: Icon(Icons.receipt_long_outlined),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Special Instructions',
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 15,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                store.notes.isEmpty
                                    ? 'Add any notes (optional)'
                                    : store.notes,
                                style: TextStyle(
                                  color: context.eatsMuted,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Icon(Icons.chevron_right),
                      ],
                    ),
                  ),
                ),
                eatsHeading(context, 'Order Summary'),
                EatsSummary(
                  subtotal: store.subtotal,
                  serviceFee: store.serviceFee,
                  deliveryFee: store.deliveryFee,
                  count: store.count,
                  showFulfilmentFee: _checkoutVisited,
                ),
                if (_checkoutVisited) ...[
                  EatsCard(
                    shadow: true,
                    child: Row(
                      children: [
                        EatsCircle(
                          color: const Color(0xFF00B98E),
                          child: store.fulfilment == Fulfilment.drone
                              ? const DroneIcon(color: Color(0xFF00B98E))
                              : const Icon(Icons.storefront),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                store.fulfilment == Fulfilment.drone
                                    ? 'Deliver to: Main Campus'
                                    : 'Pickup: Campus Tuckshop',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 14,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                store.fulfilment == Fulfilment.drone
                                    ? '20–30 min · R15.00 delivery fee'
                                    : '15–25 min · Free pickup',
                                style: TextStyle(
                                  color: context.eatsMuted,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                        TextButton(
                          onPressed: () => _checkout(context),
                          child: const Text(
                            'Change ›',
                            style: TextStyle(color: eatsRed, fontSize: 12),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 2),
                ],
                EatsPair(
                  firstFlex: 5,
                  secondFlex: 2,
                  breakpoint: 340,
                  gap: 10,
                  first: EatsAction(
                    'Proceed to Checkout',
                    onPressed: () => _checkout(context),
                  ),
                  second: EatsAction(
                    'Schedule',
                    outlined: true,
                    icon: Icons.event_available_outlined,
                    onPressed: () => scheduleEatsOrder(context),
                  ),
                ),
                if (store.scheduledFor != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: Text(
                      'Scheduled: ${eatsDate(context, store.scheduledFor!)}',
                      style: TextStyle(color: context.eatsMuted),
                    ),
                  ),
              ],
      ),
    );
  }

  Future<void> _checkout(BuildContext context) async {
    final store = BcEatsStore.instance;

    if (!_checkoutVisited) {
      setState(() {
        _checkoutVisited = true;
      });
    }

    // Keep the existing Delivery or Pickup screen behaviour.
    // That screen previously starts with its normal/default option.
    if (!store.hasFulfilmentChoice) {
      store.chooseFulfilment(
        store.droneAvailable ? Fulfilment.drone : Fulfilment.pickup,
      );
    }

    await Navigator.push(
      context,
      MaterialPageRoute<void>(
        settings: const RouteSettings(name: '/checkout'),
        builder: (_) => const BCEatsCheckoutScreen(),
      ),
    );

    // Refresh the cart when the user returns so any changed
    // Delivery/Pickup choice is reflected immediately.
    if (mounted) {
      setState(() {});
    }
  }
}

class _CartItem extends StatelessWidget {
  final EatsLine line;
  const _CartItem({required this.line});
  @override
  Widget build(BuildContext context) {
    final store = BcEatsStore.instance;
    return EatsCard(
      shadow: true,
      padding: const EdgeInsets.all(8),
      child: LayoutBuilder(
        builder: (context, c) {
          final imageWidth = (c.maxWidth * .3).clamp(75.0, 160.0).toDouble();
          final compact =
              c.maxWidth < 400 ||
              MediaQuery.textScalerOf(context).scale(14) > 20;
          final controls = Container(
            decoration: BoxDecoration(
              border: Border.all(color: context.eatsBorder),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  tooltip: 'Decrease ${line.product.name}',
                  constraints: const BoxConstraints(
                    minWidth: 34,
                    minHeight: 36,
                  ),
                  visualDensity: VisualDensity.compact,
                  onPressed: () => store.decrease(line.product.id),
                  icon: const Icon(Icons.remove, size: 19),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 5),
                  child: Text('${line.quantity}'),
                ),
                IconButton(
                  tooltip: 'Increase ${line.product.name}',
                  constraints: const BoxConstraints(
                    minWidth: 34,
                    minHeight: 36,
                  ),
                  visualDensity: VisualDensity.compact,
                  onPressed: () => store.add(line.product),
                  icon: const Icon(Icons.add_circle, color: eatsRed, size: 29),
                ),
              ],
            ),
          );
          final price = Text(
            money(line.total),
            style: const TextStyle(
              fontSize: 18,
              color: eatsRed,
              fontWeight: FontWeight.w600,
            ),
          );
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              EatsProductImage(
                path: line.product.imagePath,
                width: imageWidth,
                height: compact ? 112 : 138,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.only(top: 6),
                            child: Text(
                              line.product.name,
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                        SizedBox(
                          width: 30,
                          height: 32,
                          child: IconButton(
                            tooltip: 'Remove ${line.product.name}',
                            padding: EdgeInsets.zero,
                            onPressed: () => store.remove(line.product.id),
                            icon: const Icon(
                              Icons.delete_outline,
                              color: eatsRed,
                              size: 23,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      line.product.description,
                      style: TextStyle(
                        color: context.eatsMuted,
                        fontSize: 12,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 10),
                    if (compact)
                      Wrap(
                        spacing: 10,
                        runSpacing: 6,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [price, controls],
                      )
                    else
                      Row(children: [price, const Spacer(), controls]),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
