import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../services/bc_eats_store.dart';
import '../widgets/eats_order_widgets.dart';
import '../widgets/eats_order_details.dart';
import 'bc_eats_tracking_screen.dart';

class BCEatsDroneScreen extends StatefulWidget {
  final EatsOrder order;
  const BCEatsDroneScreen({super.key, required this.order});
  @override
  State<BCEatsDroneScreen> createState() => _BCEatsDroneScreenState();
}

class _BCEatsDroneScreenState extends State<BCEatsDroneScreen> {
  final transform = TransformationController();

  @override
  void dispose() {
    transform.dispose();
    super.dispose();
  }

  void zoom(double factor) {
    final scale = transform.value.getMaxScaleOnAxis();
    final target = (scale * factor).clamp(1.0, 4.0).toDouble();
    transform.value = Matrix4.identity()
      ..scaleByDouble(target, target, target, 1);
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: BcEatsStore.instance,
    builder: (context, _) {
      final order = widget.order;
      final done = order.completed;
      final arrived = order.droneArrived || done;
      return EatsPage(
        title: 'Track Your Drone',
        subtitle: 'Order #${order.id}  •  Drone Delivery',
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: Container(
              margin: const EdgeInsets.only(bottom: 16),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: eatsGreen.withValues(alpha: .08),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                done
                    ? 'Delivered'
                    : arrived
                    ? 'Arrived'
                    : 'On the Way',
                style: const TextStyle(color: eatsGreen, fontSize: 12),
              ),
            ),
          ),
          EatsCard(
            child: EatsOrderProgress(
              order: order,
              times: true,
              droneView: true,
            ),
          ),
          LayoutBuilder(
            builder: (context, c) {
              final wide =
                  c.maxWidth >= 650 &&
                  MediaQuery.textScalerOf(context).scale(14) < 21;
              final stats = _stats(context, order);
              return Column(
                children: [
                  if (!wide) stats,
                  ClipRRect(
                    borderRadius: BorderRadius.circular(14),
                    child: SizedBox(
                      height: wide ? 500 : 360,
                      child: Stack(
                        children: [
                          Positioned.fill(
                            child: ColoredBox(
                              color: context.eatsDark
                                  ? const Color(0xFF242C2B)
                                  : const Color(0xFFF0F2EC),
                              child: InteractiveViewer(
                                transformationController: transform,
                                minScale: 1,
                                maxScale: 4,
                                constrained: false,
                                child: SizedBox(
                                  width: math.max(c.maxWidth, 700.0),
                                  height: 550,
                                  child: Stack(
                                    children: [
                                      Positioned.fill(
                                        child: SvgPicture.asset(
                                          context.eatsDark
                                              ? 'assets/bc_ways/map/campus_2.svg'
                                              : 'assets/bc_ways/map/campus.svg',
                                          fit: BoxFit.contain,
                                          placeholderBuilder: (_) =>
                                              const Center(
                                                child: Icon(
                                                  Icons.map_outlined,
                                                  size: 100,
                                                  color: eatsYellow,
                                                ),
                                              ),
                                        ),
                                      ),
                                      Positioned.fill(
                                        child: IgnorePointer(
                                          child: CustomPaint(
                                            painter: _DemoRoutePainter(
                                              done: arrived,
                                            ),
                                          ),
                                        ),
                                      ),
                                      Positioned(
                                        left: arrived ? 450 : 250,
                                        top: arrived ? 290 : 210,
                                        child: Container(
                                          padding: const EdgeInsets.all(12),
                                          decoration: BoxDecoration(
                                            color: context.eatsSurface,
                                            shape: BoxShape.circle,
                                            boxShadow: [
                                              BoxShadow(
                                                color: Colors.black.withValues(
                                                  alpha: .12,
                                                ),
                                                blurRadius: 8,
                                              ),
                                            ],
                                          ),
                                          child: const DroneIcon(
                                            size: 34,
                                            color: eatsOrange,
                                          ),
                                        ),
                                      ),
                                      Positioned(
                                        left: 455,
                                        top: 267,
                                        child: Column(
                                          children: [
                                            const Icon(
                                              Icons.location_on,
                                              color: eatsRed,
                                              size: 45,
                                            ),
                                            Container(
                                              padding: const EdgeInsets.all(10),
                                              decoration: BoxDecoration(
                                                color: context.eatsSurface,
                                                borderRadius:
                                                    BorderRadius.circular(10),
                                              ),
                                              child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  const Text(
                                                    'Delivery to',
                                                    style: TextStyle(
                                                      fontSize: 11,
                                                    ),
                                                  ),
                                                  const SizedBox(height: 4),
                                                  Text(
                                                    order.location,
                                                    style: const TextStyle(
                                                      color: eatsOrange,
                                                      fontWeight:
                                                          FontWeight.w600,
                                                      fontSize: 12,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                          if (wide)
                            Positioned(
                              left: 12,
                              top: 12,
                              width: 185,
                              child: stats,
                            ),
                          Positioned(
                            right: 12,
                            top: 12,
                            child: Column(
                              children: [
                                _mapButton(
                                  context,
                                  Icons.my_location,
                                  'Recenter',
                                  () => transform.value = Matrix4.identity(),
                                ),
                                const SizedBox(height: 8),
                                _mapButton(
                                  context,
                                  Icons.add,
                                  'Zoom in',
                                  () => zoom(1.25),
                                ),
                                _mapButton(
                                  context,
                                  Icons.remove,
                                  'Zoom out',
                                  () => zoom(.8),
                                ),
                              ],
                            ),
                          ),
                          Positioned(
                            left: 12,
                            bottom: 12,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: context.eatsSurface,
                                borderRadius: BorderRadius.circular(7),
                              ),
                              child: const Text(
                                'Demo route · not live GPS',
                                style: TextStyle(fontSize: 11),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 16),
          EatsCard(
            child: EatsPair(
              breakpoint: 600,
              firstFlex: 3,
              secondFlex: 1,
              first: Row(
                children: [
                  Image.asset(
                    'assets/images/eats_delivery_drone.png',
                    width: 105,
                    height: 95,
                    fit: BoxFit.contain,
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          arrived
                              ? 'Your order has arrived!'
                              : 'Your order is flying to you!',
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 15,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          done
                              ? 'Enjoy your meal.'
                              : arrived
                              ? 'The drone has reached the landing zone. Use the delivery OTP below to receive your order.'
                              : 'Our drone is en route to the landing zone. Please be ready to collect your order.',
                          style: TextStyle(
                            fontSize: 12,
                            height: 1.6,
                            color: context.eatsMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              second: EatsAction(
                'Order Details  ›',
                outlined: true,
                onPressed: () => Navigator.pushReplacement(
                  context,
                  MaterialPageRoute<void>(
                    builder: (_) => BCEatsTrackingScreen(order: order),
                  ),
                ),
              ),
            ),
          ),
          const EatsSupportCard(color: eatsOrange),

          EatsDemoControls(
            order: order,
            onDroneArrived: () {
              if (!mounted) {
                return;
              }

              Navigator.pushReplacement(
                context,
                MaterialPageRoute<void>(
                  builder: (_) => BCEatsTrackingScreen(order: order),
                ),
              );
            },
          ),
        ],
      );
    },
  );
  Widget _stats(BuildContext context, EatsOrder order) => EatsCard(
    padding: const EdgeInsets.all(13),
    child: LayoutBuilder(
      builder: (context, c) {
        final entries = [
          _stat(
            context,
            'Estimated Arrival',
            (order.droneArrived || order.completed) ? 'Arrived' : '2 min',
            Icons.access_time,
            highlight: true,
          ),
          _stat(
            context,
            'Distance Remaining',
            (order.droneArrived || order.completed) ? '0 m' : '120 m',
            Icons.route_outlined,
          ),
          _stat(context, 'Drone ID', 'BC-DRN-2417', Icons.flight),
          _stat(
            context,
            'Altitude',
            (order.droneArrived || order.completed) ? '0 m' : '32 m',
            Icons.signal_cellular_alt,
          ),
        ];
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'DEMO TELEMETRY',
              style: TextStyle(
                fontSize: 9,
                letterSpacing: 1,
                color: eatsOrange,
              ),
            ),
            const SizedBox(height: 12),
            if (c.maxWidth > 270)
              EatsPair(
                breakpoint: 270,
                first: Column(
                  children: [
                    entries[0],
                    const SizedBox(height: 15),
                    entries[1],
                  ],
                ),
                second: Column(
                  children: [
                    entries[2],
                    const SizedBox(height: 15),
                    entries[3],
                  ],
                ),
              )
            else
              for (var i = 0; i < entries.length; i++) ...[
                if (i > 0) Divider(height: 24, color: context.eatsBorder),
                entries[i],
              ],
          ],
        );
      },
    ),
  );
  Widget _stat(
    BuildContext context,
    String label,
    String value,
    IconData icon, {
    bool highlight = false,
  }) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Row(
        children: [
          Expanded(child: Text(label, style: const TextStyle(fontSize: 11))),
          if (icon == Icons.flight)
            const DroneIcon(size: 23, color: eatsOrange)
          else
            Icon(icon, size: 23, color: eatsOrange),
        ],
      ),
      const SizedBox(height: 5),
      Text(
        value,
        style: TextStyle(
          fontSize: highlight ? 25 : 17,
          fontWeight: FontWeight.w600,
          color: highlight ? eatsOrange : context.eatsInk,
        ),
      ),
    ],
  );
  Widget _mapButton(
    BuildContext context,
    IconData icon,
    String label,
    VoidCallback onTap,
  ) => Material(
    color: context.eatsSurface,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(9),
      side: BorderSide(color: context.eatsBorder),
    ),
    child: IconButton(
      tooltip: label,
      onPressed: onTap,
      icon: Icon(icon, size: 25),
    ),
  );
}

class _DemoRoutePainter extends CustomPainter {
  final bool done;
  const _DemoRoutePainter({required this.done});
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = eatsYellow
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4;
    canvas.drawPath(
      Path()
        ..moveTo(277, 238)
        ..lineTo(424, 232)
        ..lineTo(477, 314),
      paint,
    );
    canvas.drawCircle(
      const Offset(477, 314),
      20,
      paint
        ..style = PaintingStyle.fill
        ..color = eatsYellow.withValues(alpha: .25),
    );
  }

  @override
  bool shouldRepaint(_DemoRoutePainter oldDelegate) => oldDelegate.done != done;
}
