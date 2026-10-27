import 'dart:async';
import 'package:flutter/material.dart';
import '../../bc_ways/screens/map_screen.dart';
import '../services/bc_eats_store.dart';
import '../widgets/eats_order_widgets.dart';
import '../widgets/eats_order_details.dart';
import '../widgets/eats_dialogs.dart';
import 'bc_eats_cart_screen.dart';
import 'bc_eats_drone_screen.dart';
import 'orders.dart';

class BCEatsTrackingScreen extends StatelessWidget {
  final EatsOrder order;
  const BCEatsTrackingScreen({super.key, required this.order});
  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: BcEatsStore.instance,
    builder: (context, _) {
      final pickup = order.fulfilment == Fulfilment.pickup;
      final ready = order.status == EatsStatus.ready;

      final awaitingDeliveryVerification =
          order.fulfilment == Fulfilment.drone &&
          order.droneArrived &&
          !order.completed;
      return EatsPage(
        children: [
          if (order.completed)
            ..._completed(context, pickup)
          else if (awaitingDeliveryVerification)
            ..._awaitingDeliveryVerification(context)
          else if (ready)
            ..._ready(context, pickup)
          else
            ..._confirmation(context, pickup),
          eatsHeading(context, 'Order Details'),
          EatsOrderDetails(order: order),
          if (ready) ...[
            eatsHeading(
              context,
              pickup ? 'Pickup Details' : 'Delivery Details',
            ),
            EatsCard(
              child: Row(
                children: [
                  const EatsCircle(
                    color: eatsGreen,
                    child: Icon(Icons.location_on_outlined),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          pickup ? 'Collecting from' : 'Delivering to',
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          order.location,
                          style: const TextStyle(fontSize: 12, height: 1.5),
                        ),
                        const Text(
                          'Belgium Campus iTversity',
                          style: TextStyle(fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
          if (order.completed) ...[
            EatsInfo(
              color: eatsOrange,
              icon: const Icon(Icons.emoji_events_outlined),
              title: 'You earned 10 BC Points!',
              subtitle: 'Demo rewards · keep ordering to earn more.',
              action: EatsAction(
                'View Rewards',
                outlined: true,
                onPressed: () => showDialog<void>(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('BC Points · Demo'),
                    content: Text(
                      'You have ${BcEatsStore.instance.orders.where((item) => item.completed).length * 10} demo points from completed orders this session. Real rewards are not connected.',
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Close'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            EatsPair(
              breakpoint: 320,
              firstFlex: 2,
              first: EatsAction(
                'Order Again',
                icon: Icons.refresh,
                onPressed: () {
                  BcEatsStore.instance.reorder(order);
                  _cart(context);
                },
              ),
              second: EatsAction(
                'View Orders',
                icon: Icons.receipt_long_outlined,
                outlined: true,
                onPressed: () => _orders(context),
              ),
            ),
            const SizedBox(height: 14),
          ],
          EatsSupportCard(tinted: ready || order.completed),
          if (!order.completed)
            TextButton(
              onPressed: () => _orders(context),
              child: const Text(
                'View Orders',
                style: TextStyle(color: eatsOrange),
              ),
            ),
          EatsDemoControls(order: order),
        ],
      );
    },
  );
  String get _firstName => order.customerName.trim().isEmpty
      ? ''
      : order.customerName.trim().split(' ').first;
  List<Widget> _confirmation(BuildContext context, bool pickup) => [
    Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SuccessMark(),
        const SizedBox(width: 18),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Thank you${_firstName.isEmpty ? '' : ', $_firstName'}!',
                style: const TextStyle(
                  fontSize: 27,
                  fontWeight: FontWeight.w700,
                  height: 1.2,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Your order has been placed.',
                style: TextStyle(
                  color: eatsGreen,
                  fontWeight: FontWeight.w600,
                  fontSize: 17,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Order #${order.id}',
                style: TextStyle(color: context.eatsMuted, fontSize: 13),
              ),
              const SizedBox(height: 4),
              Text(
                "We've received your order and are getting it ready.",
                style: TextStyle(
                  color: context.eatsMuted,
                  height: 1.5,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
      ],
    ),
    const SizedBox(height: 24),
    EatsCard(
      child: LayoutBuilder(
        builder: (context, c) => Row(
          children: [
            Expanded(
              flex: 3,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const EatsCircle(
                        color: eatsYellow,
                        child: Icon(Icons.access_time),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Estimated time',
                              style: TextStyle(fontSize: 13),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              pickup ? '15–25 min' : '20–30 min',
                              style: const TextStyle(
                                color: eatsOrange,
                                fontSize: 23,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  Text(
                    pickup
                        ? 'Check your order here to see when it is ready for pickup.'
                        : 'Check your order here to see when it is on the way.',
                    style: const TextStyle(fontSize: 13, height: 1.6),
                  ),
                  if (order.scheduledFor != null)
                    Text(
                      'Scheduled: ${eatsDate(context, order.scheduledFor!)}',
                      style: const TextStyle(fontSize: 12),
                    ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              flex: 2,
              child: Image.asset(
                'assets/images/eats_order_package.png',
                height: c.maxWidth > 550 ? 210 : 150,
                fit: BoxFit.contain,
              ),
            ),
          ],
        ),
      ),
    ),
    eatsHeading(context, 'Order Progress'),
    Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: EatsOrderProgress(order: order),
    ),
    const SizedBox(height: 12),
    EatsInfo(
      icon: const Icon(Icons.soup_kitchen_outlined),
      title: 'Good news!',
      subtitle: pickup
          ? 'Your meal is being prepared for collection.'
          : 'Your meal is being prepared with care.',
    ),
  ];
  List<Widget> _ready(BuildContext context, bool pickup) => [
    Text(
      pickup ? 'Your Order is Ready for Pickup!' : 'Your Order is on the Way!',
      style: const TextStyle(
        fontSize: 25,
        height: 1.3,
        fontWeight: FontWeight.w700,
      ),
    ),
    const SizedBox(height: 8),
    Text(
      pickup
          ? 'Your meal is waiting at the tuckshop.'
          : 'Sit tight${_firstName.isEmpty ? '' : ', $_firstName'}. Your meal is almost here.',
      style: TextStyle(color: context.eatsMuted, fontSize: 14),
    ),
    const SizedBox(height: 20),
    EatsCard(
      child: EatsPair(
        breakpoint: 350,
        first: Row(
          children: [
            const EatsCircle(
              color: eatsGreen,
              size: 48,
              child: Icon(Icons.access_time),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    pickup ? 'Collection code' : 'Estimated arrival',
                    style: const TextStyle(fontSize: 12),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    pickup
                        ? order.id.replaceFirst('BCE', '')
                        : TimeOfDay.fromDateTime(
                            order.placedAt.add(const Duration(minutes: 25)),
                          ).format(context),
                    style: const TextStyle(
                      color: eatsGreen,
                      fontSize: 23,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    pickup
                        ? 'Show this at the counter'
                        : '20–30 min · demo estimate',
                    style: TextStyle(fontSize: 11, color: context.eatsMuted),
                  ),
                ],
              ),
            ),
          ],
        ),
        second: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Order #${order.id}', style: const TextStyle(fontSize: 13)),
            const SizedBox(height: 6),
            Text(
              'Placed on ${eatsDate(context, order.placedAt)}',
              style: TextStyle(fontSize: 12, color: context.eatsMuted),
            ),
            const SizedBox(height: 8),
            _StatusChip(
              label: pickup ? 'Ready for Pickup' : 'Out for Delivery',
            ),
          ],
        ),
      ),
    ),
    EatsCard(
      child: Column(
        children: [
          EatsOrderProgress(order: order, times: true),
          const SizedBox(height: 20),
          EatsInfo(
            icon: pickup
                ? const Icon(Icons.storefront_outlined)
                : const DroneIcon(color: eatsGreen),
            title: pickup
                ? 'Your meal is ready to collect!'
                : 'Your drone is on the way!',
            subtitle: pickup
                ? 'Have your order number ready at the counter.'
                : 'Your order is flying to the selected landing pad.',
            action: EatsAction(
              pickup ? 'Show Directions' : 'Track Drone',
              icon: pickup ? Icons.directions : null,
              color: eatsGreen,
              outlined: true,
              onPressed: () => pickup ? _directions(context) : _drone(context),
            ),
          ),
        ],
      ),
    ),
  ];
  List<Widget> _awaitingDeliveryVerification(BuildContext context) => [
    Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const EatsCircle(
          color: eatsOrange,
          size: 60,
          child: DroneIcon(size: 31, color: eatsOrange),
        ),

        const SizedBox(width: 14),

        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Drone Arrived!',
                style: TextStyle(
                  fontSize: 27,
                  fontWeight: FontWeight.w700,
                  height: 1.2,
                ),
              ),

              const SizedBox(height: 7),

              const Text(
                'Your order has reached the landing zone.',
                style: TextStyle(
                  color: eatsGreen,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),

              const SizedBox(height: 6),

              Text(
                'Use the delivery OTP below to verify collection before the order is marked as delivered.',
                style: TextStyle(
                  color: context.eatsMuted,
                  fontSize: 12,
                  height: 1.5,
                ),
              ),
            ],
          ),
        ),

        SizedBox(
          width: MediaQuery.sizeOf(context).width < 400 ? 70 : 105,
          child: Image.asset('assets/images/eats_order_package.png'),
        ),
      ],
    ),

    const SizedBox(height: 22),

    EatsCard(
      child: EatsOrderProgress(order: order, times: true, droneView: true),
    ),

    _DeliveryOtpCard(order: order),
  ];
  List<Widget> _completed(BuildContext context, bool pickup) => [
    Row(
      children: [
        const _SuccessMark(),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                pickup ? 'Collected!' : 'Delivered!',
                style: const TextStyle(
                  fontSize: 27,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 7),
              Text(
                'Enjoy your meal${_firstName.isEmpty ? '' : ', $_firstName'}!',
                style: const TextStyle(
                  fontSize: 17,
                  color: eatsGreen,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 7),
              Text(
                'Thank you for choosing BC Eats.',
                style: TextStyle(fontSize: 12, color: context.eatsMuted),
              ),
            ],
          ),
        ),
        SizedBox(
          width: MediaQuery.sizeOf(context).width < 400 ? 70 : 115,
          child: Image.asset('assets/images/eats_order_package.png'),
        ),
      ],
    ),
    const SizedBox(height: 24),
    EatsCard(
      child: EatsPair(
        breakpoint: 380,
        first: Row(
          children: [
            const EatsCircle(
              color: eatsGreen,
              child: Icon(Icons.location_on_outlined),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    pickup ? 'Collected from' : 'Delivered to',
                    style: const TextStyle(fontSize: 13),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Main Campus',
                    style: TextStyle(
                      color: eatsGreen,
                      fontWeight: FontWeight.w600,
                      fontSize: 17,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    order.location,
                    style: const TextStyle(fontSize: 12, height: 1.5),
                  ),
                ],
              ),
            ),
          ],
        ),
        second: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              pickup ? 'Collected at' : 'Delivered at',
              style: const TextStyle(fontSize: 13),
            ),
            const SizedBox(height: 6),
            Text(
              TimeOfDay.fromDateTime(order.completedAt!).format(context),
              style: const TextStyle(
                color: eatsGreen,
                fontSize: 24,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              eatsDate(context, order.completedAt!).split(',').first,
              style: TextStyle(fontSize: 12, color: context.eatsMuted),
            ),
          ],
        ),
      ),
    ),
    EatsCard(child: EatsOrderProgress(order: order, times: true)),
    EatsCard(
      child: EatsPair(
        breakpoint: 560,
        firstFlex: 3,
        secondFlex: 2,
        first: Row(
          children: [
            const EatsCircle(
              color: eatsGreen,
              child: Icon(Icons.sentiment_satisfied_alt),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'How was your experience?',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    order.rating == 0
                        ? 'Rate your order and help us serve you better.'
                        : 'Thank you for your feedback!',
                    style: TextStyle(fontSize: 12, color: context.eatsMuted),
                  ),
                ],
              ),
            ),
          ],
        ),
        second: Wrap(
          alignment: WrapAlignment.end,
          children: [
            for (var i = 1; i <= 5; i++)
              IconButton(
                tooltip: 'Rate $i stars',
                constraints: const BoxConstraints(minWidth: 36, minHeight: 44),
                padding: const EdgeInsets.all(4),
                onPressed: () => BcEatsStore.instance.rate(order, i),
                icon: Icon(
                  i <= order.rating ? Icons.star : Icons.star_border,
                  size: 28,
                  color: eatsYellow,
                ),
              ),
          ],
        ),
      ),
    ),
  ];
  void _directions(BuildContext context) {
    Navigator.of(context, rootNavigator: true).push(
      MaterialPageRoute<void>(
        settings: const RouteSettings(name: '/bc-ways-tuck-shop'),
        builder: (_) => const MapScreen(initialDestinationQuery: 'Tuck Shop'),
      ),
    );
  }

  void _drone(BuildContext context) => Navigator.push(
    context,
    MaterialPageRoute<void>(builder: (_) => BCEatsDroneScreen(order: order)),
  );
  void _cart(BuildContext context) => Navigator.push(
    context,
    MaterialPageRoute<void>(builder: (_) => const BCEatsCartScreen()),
  );
  void _orders(BuildContext context) {
    final scope = EatsFlowScope.maybeOf(context);
    if (scope != null) {
      scope.navigate(3);
    } else {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute<void>(builder: (_) => const OrdersScreen()),
      );
    }
  }
}

class _DeliveryOtpCard extends StatefulWidget {
  final EatsOrder order;

  const _DeliveryOtpCard({required this.order});

  @override
  State<_DeliveryOtpCard> createState() => _DeliveryOtpCardState();
}

class _DeliveryOtpCardState extends State<_DeliveryOtpCard> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();

    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) {
        setState(() {});
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final order = widget.order;
    final valid = order.deliveryOtpValid;
    final expiry = order.deliveryOtpExpiresAt;

    final remaining = expiry == null
        ? Duration.zero
        : expiry.difference(DateTime.now());

    final totalSeconds = remaining.inSeconds.clamp(0, 300).toInt();

    final minutes = totalSeconds ~/ 60;
    final seconds = totalSeconds % 60;

    final countdown =
        '${minutes.toString().padLeft(2, '0')}:'
        '${seconds.toString().padLeft(2, '0')}';

    return EatsCard(
      border: valid ? eatsOrange : eatsRed,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              EatsCircle(
                color: valid ? eatsOrange : eatsRed,
                child: Icon(
                  valid
                      ? Icons.verified_user_outlined
                      : Icons.timer_off_outlined,
                ),
              ),

              const SizedBox(width: 12),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      valid ? 'Delivery OTP' : 'Delivery OTP Expired',
                      style: TextStyle(
                        color: valid ? eatsOrange : eatsRed,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),

                    const SizedBox(height: 4),

                    Text(
                      valid
                          ? 'Give this code only when receiving your order.'
                          : 'Request a new OTP to complete your delivery.',
                      style: TextStyle(
                        color: context.eatsMuted,
                        fontSize: 12,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 18),

          if (valid) ...[
            Center(
              child: Text(
                order.deliveryOtp!,
                style: const TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 7,
                ),
              ),
            ),

            const SizedBox(height: 10),

            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.timer_outlined, color: eatsRed, size: 18),

                const SizedBox(width: 6),

                Text(
                  'Expires in $countdown',
                  style: const TextStyle(
                    color: eatsRed,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 18),

            EatsAction(
              'Simulate OTP Verification',
              icon: Icons.verified_outlined,
              color: eatsGreen,
              outlined: true,
              onPressed: _verifyOtp,
            ),
          ] else ...[
            EatsAction(
              'Request New OTP',
              icon: Icons.refresh,
              onPressed: () {
                BcEatsStore.instance.requestDeliveryOtp(order);
              },
            ),
          ],
        ],
      ),
    );
  }

  void _verifyOtp() {
    final order = widget.order;
    final otp = order.deliveryOtp;

    if (otp == null || !BcEatsStore.instance.verifyDeliveryOtp(order, otp)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('This OTP has expired. Please request a new one.'),
        ),
      );
    }
  }
}

class _SuccessMark extends StatelessWidget {
  const _SuccessMark();
  @override
  Widget build(BuildContext context) => Container(
    width: 64,
    height: 64,
    decoration: const BoxDecoration(
      shape: BoxShape.circle,
      gradient: LinearGradient(colors: [Color(0xFF21C248), Color(0xFF099A2C)]),
    ),
    child: const Icon(Icons.check_rounded, color: Colors.white, size: 44),
  );
}

class _StatusChip extends StatelessWidget {
  final String label;
  const _StatusChip({required this.label});
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
    decoration: BoxDecoration(
      color: eatsGreen.withValues(alpha: .07),
      borderRadius: BorderRadius.circular(8),
    ),
    child: Text(
      label,
      style: const TextStyle(
        color: eatsGreen,
        fontSize: 12,
        fontWeight: FontWeight.w500,
      ),
    ),
  );
}
