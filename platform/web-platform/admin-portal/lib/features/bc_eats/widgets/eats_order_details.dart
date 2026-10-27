import 'package:flutter/material.dart';
import '../services/bc_eats_store.dart';
import 'eats_order_widgets.dart';
import 'eats_dialogs.dart';

class EatsOrderDetails extends StatelessWidget {
  final EatsOrder order;
  const EatsOrderDetails({super.key, required this.order});
  @override
  Widget build(BuildContext context) => EatsCard(
    padding: const EdgeInsets.all(12),
    child: EatsPair(
      breakpoint: 340,
      gap: 12,
      firstFlex: 11,
      secondFlex: 9,
      first: Column(
        children: [
          for (var i = 0; i < order.lines.length; i++) ...[
            if (i > 0) Divider(color: context.eatsBorder, height: 20),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                EatsProductImage(
                  path: order.lines[i].product.imagePath,
                  width: 38,
                  height: 47,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        order.lines[i].product.name,
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        order.lines[i].product.description,
                        style: TextStyle(
                          fontSize: 10,
                          height: 1.5,
                          color: context.eatsMuted,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 4),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '× ${order.lines[i].quantity}',
                      style: const TextStyle(fontSize: 10),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      money(order.lines[i].total),
                      style: const TextStyle(fontSize: 10),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ],
      ),
      second: Container(
        decoration: BoxDecoration(
          border: Border(left: BorderSide(color: context.eatsBorder)),
        ),
        padding: const EdgeInsets.only(left: 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            EatsSummary(
              card: false,
              compact: true,
              subtotal: order.subtotal,
              serviceFee: order.serviceFee,
              deliveryFee: order.deliveryFee,
              count: order.lines.fold(0, (sum, line) => sum + line.quantity),
              totalColor: eatsGreen,
              totalLabel: order.payment == EatsPayment.cash
                  ? 'Amount Due'
                  : 'Order Total',
            ),
            Divider(height: 28, color: context.eatsBorder),
            const Text('Payment Method', style: TextStyle(fontSize: 11)),
            const SizedBox(height: 7),
            Row(
              children: [
                Expanded(
                  child: Text(switch (order.payment) {
                    EatsPayment.card => 'Card (Visa / Mastercard)',
                    EatsPayment.eft => 'EFT / Bank Transfer',
                    EatsPayment.student => 'Student Account',
                    EatsPayment.cash => 'Cash on Pickup',
                  }, style: const TextStyle(fontSize: 11)),
                ),
                if (order.payment == EatsPayment.card)
                  const Text(
                    'VISA',
                    style: TextStyle(
                      color: Color(0xFF174B9F),
                      fontWeight: FontWeight.w900,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Demo · ${order.payment == EatsPayment.cash ? 'due on collection' : 'not charged'}',
              style: TextStyle(fontSize: 10, color: context.eatsMuted),
            ),
            if (order.notes.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(
                'Special instructions: ${order.notes}',
                style: const TextStyle(fontSize: 12),
              ),
            ],
          ],
        ),
      ),
    ),
  );
}

class EatsOrderProgress extends StatelessWidget {
  final EatsOrder order;
  final bool times, droneView;

  const EatsOrderProgress({
    super.key,
    required this.order,
    this.times = false,
    this.droneView = false,
  });

  @override
  Widget build(BuildContext context) {
    final pickup = order.fulfilment == Fulfilment.pickup;

    final droneArrived = droneView && (order.droneArrived || order.completed);

    final active = droneArrived ? 3 : order.status.index;

    return EatsProgress(
      current: active,
      completed: order.completed,
      color: droneView || active < 2 ? eatsYellow : eatsGreen,
      labels: droneView
          ? [
              'Order Confirmed',
              'Preparing',
              'On the Way',
              droneArrived ? 'Arrived' : 'Arriving',
            ]
          : [
              'Order\nReceived',
              'Being\nPrepared',
              pickup ? 'Ready for\nPickup' : 'Out for\nDelivery',
              pickup ? 'Collected' : 'Delivered',
            ],
      icons: [
        const Icon(Icons.check),
        const Icon(Icons.soup_kitchen_outlined),
        pickup
            ? const Icon(Icons.storefront_outlined)
            : const DroneIcon(size: 24),
        const Icon(Icons.home_outlined),
      ],
      times: times
          ? List.generate(4, (i) {
              final DateTime? timestamp;

              if (droneView && i == 3 && order.droneArrivedAt != null) {
                timestamp = order.droneArrivedAt;
              } else {
                timestamp = order.statusTimes[EatsStatus.values[i]];
              }

              return timestamp == null
                  ? '—'
                  : TimeOfDay.fromDateTime(timestamp).format(context);
            })
          : null,
    );
  }
}

class EatsSupportCard extends StatelessWidget {
  final Color color;
  final bool tinted;
  const EatsSupportCard({
    super.key,
    this.color = eatsGreen,
    this.tinted = false,
  });
  @override
  Widget build(BuildContext context) => EatsCard(
    tint: tinted ? color : null,
    child: EatsPair(
      breakpoint: 440,
      firstFlex: 3,
      secondFlex: 2,
      first: Row(
        children: [
          Icon(Icons.headset_mic, color: color, size: 30),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Need help with your order?',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 5),
                Text(
                  'Our support team is here for you.',
                  style: TextStyle(color: context.eatsMuted, fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
      second: EatsAction(
        'Contact Support',
        outlined: true,
        color: color,
        icon: Icons.chat_bubble_outline,
        onPressed: () => eatsSupport(context),
      ),
    ),
  );
}

class EatsDemoControls extends StatelessWidget {
  final EatsOrder order;
  final VoidCallback? onDroneArrived;

  const EatsDemoControls({super.key, required this.order, this.onDroneArrived});

  void _advance() {
    final isDroneArrival =
        order.fulfilment == Fulfilment.drone &&
        order.status == EatsStatus.ready &&
        !order.droneArrived;

    BcEatsStore.instance.advanceDemo(order);

    if (isDroneArrival && order.droneArrived) {
      onDroneArrived?.call();
    }
  }

  @override
  Widget build(BuildContext context) {
    return ExpansionTile(
      tilePadding: EdgeInsets.zero,
      title: Text(
        'Demo preview controls',
        style: TextStyle(fontSize: 11, color: context.eatsMuted),
      ),
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Local preview only. No real payment, order or live drone telemetry. Orders are kept for this app session.',
                style: TextStyle(fontSize: 12),
              ),

              const SizedBox(height: 12),

              if (!order.completed)
                EatsAction(
                  switch (order.status) {
                    EatsStatus.received => 'Preview: Being Prepared',

                    EatsStatus.preparing =>
                      order.fulfilment == Fulfilment.drone
                          ? 'Preview: On the Way'
                          : 'Preview: Ready for Pickup',

                    EatsStatus.ready =>
                      order.fulfilment == Fulfilment.drone
                          ? order.droneArrived
                                ? 'Drone Arrived · OTP Required'
                                : 'Preview: Drone Arrived'
                          : 'Preview: Collected',

                    EatsStatus.completed => 'Completed',
                  },
                  onPressed:
                      order.fulfilment == Fulfilment.drone &&
                          order.status == EatsStatus.ready &&
                          order.droneArrived
                      ? null
                      : _advance,
                ),

              Text(
                'Placed ${eatsDate(context, order.placedAt)}',
                style: TextStyle(fontSize: 11, color: context.eatsMuted),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
