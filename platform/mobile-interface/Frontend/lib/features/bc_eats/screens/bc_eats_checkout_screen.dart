import 'package:flutter/material.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import '../../../core/bc_api_client.dart';
import '../services/bc_eats_store.dart';
import '../widgets/eats_order_widgets.dart';
import '../widgets/eats_dialogs.dart';
import 'bc_eats_tracking_screen.dart';

class BCEatsCheckoutScreen extends StatefulWidget {
  const BCEatsCheckoutScreen({super.key});
  @override
  State<BCEatsCheckoutScreen> createState() => _BCEatsCheckoutScreenState();
}

class _BCEatsCheckoutScreenState extends State<BCEatsCheckoutScreen> {
  final store = BcEatsStore.instance;
  bool paymentStep = false, submitting = false;
  EatsPayment payment = EatsPayment.card;
  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: store,
    builder: (context, _) {
      final pickup = store.fulfilment == Fulfilment.pickup;
      return PopScope(
        canPop: !paymentStep,
        onPopInvokedWithResult: (didPop, result) {
          if (!didPop && paymentStep) setState(() => paymentStep = false);
        },
        child: EatsPage(
          leadingContent: EatsProgress(
            labels: const [
              'Your Cart',
              'Delivery / Pickup',
              'Payment',
              'Confirm Order',
            ],
            current: paymentStep ? 2 : 1,
            numbered: true,
          ),
          title: paymentStep ? 'Choose Payment Method' : 'Delivery or Pickup',
          subtitle: paymentStep
              ? 'Select your preferred payment option.'
              : 'Choose how you would like to receive your order.',
          children: store.count == 0
              ? [
                  const EatsCard(
                    child: Text(
                      'Your cart is empty. Add items from Eats to continue.',
                    ),
                  ),
                ]
              : [
                  if (!paymentStep)
                    ..._delivery(context, pickup)
                  else
                    ..._payment(context, pickup),
                  eatsHeading(context, 'Order Summary'),
                  EatsSummary(
                    subtotal: store.subtotal,
                    serviceFee: store.serviceFee,
                    deliveryFee: store.deliveryFee,
                    count: store.count,
                  ),
                  if (paymentStep) ...[
                    InkWell(
                      onTap: () => eatsPromo(context),
                      child: EatsCard(
                        child: Row(
                          children: [
                            const Icon(Icons.sell, color: eatsRed, size: 28),
                            const SizedBox(width: 16),
                            const Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Have a promo code?',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  SizedBox(height: 4),
                                  Text('Add promo code'),
                                ],
                              ),
                            ),
                            const Text('Add', style: TextStyle(color: eatsRed)),
                            const SizedBox(width: 6),
                            const Icon(Icons.chevron_right),
                          ],
                        ),
                      ),
                    ),
                    if (submitting)
                      const EatsCard(child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                        SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2.5)),
                        SizedBox(width: 12), Expanded(child: Text('Processing your order/payment… Please do not close this screen.', style: TextStyle(fontWeight: FontWeight.w600))),
                      ]))
                    else
                      EatsPair(
                        firstFlex: 4,
                        secondFlex: 1,
                        breakpoint: 400,
                        first: EatsAction(
                          payment == EatsPayment.cash ? 'Confirm Order · ${money(store.total)}' : 'Pay ${money(store.total)} Securely',
                          icon: Icons.lock_outline,
                          onPressed: _submit,
                        ),
                        second: EatsAction('Back', color: eatsRed, outlined: true,
                          onPressed: () => setState(() => paymentStep = false)),
                      ),
                    eatsDemoNotice(context),
                    Center(
                      child: TextButton.icon(
                        onPressed: () => showDialog<void>(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: const Text('Terms & Conditions'),
                            content: const Text(
                              'This is a local preview of the order flow. No money is taken and no order is sent to the tuckshop. Production terms will be supplied with the payment integration.',
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context),
                                child: const Text('Close'),
                              ),
                            ],
                          ),
                        ),
                        icon: const Icon(
                          Icons.verified_user_outlined,
                          color: eatsGreen,
                          size: 18,
                        ),
                        label: Text.rich(
                          TextSpan(
                            children: [
                              TextSpan(
                                text: 'By proceeding, you agree to our ',
                                style: TextStyle(color: context.eatsMuted),
                              ),
                              const TextSpan(
                                text: 'Terms & Conditions.',
                                style: TextStyle(color: eatsRed),
                              ),
                            ],
                          ),
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontSize: 11),
                        ),
                      ),
                    ),
                  ] else
                    EatsAction(
                      'Continue to Payment  →',
                      onPressed: () async {
                        if (store.customerName.isEmpty || store.phone.isEmpty) {
                          await editEatsContact(context);
                        }
                        if (!mounted ||
                            store.customerName.isEmpty ||
                            store.phone.isEmpty) {
                          return;
                        }
                        if (store.fulfilment == Fulfilment.drone &&
                            payment == EatsPayment.cash) {
                          payment = EatsPayment.card;
                        }
                        setState(() => paymentStep = true);
                      },
                    ),
                ],
        ),
      );
    },
  );
  List<Widget> _delivery(BuildContext context, bool pickup) => [
    EatsPair(
      breakpoint: 280,
      gap: 14,
      first: _DeliveryChoice(
        title: 'Deliver to Me',
        subtitle: store.droneAvailable
            ? 'Get your order delivered\nby drone to your landing pad.'
            : 'Drone delivery is temporarily\nunavailable due to weather.',
        selected: !pickup,
        enabled: store.droneAvailable,
        drone: true,
        onTap: () => store.chooseFulfilment(Fulfilment.drone),
      ),
      second: _DeliveryChoice(
        title: 'Pickup at Tuckshop',
        subtitle: 'Collect your order from the\nCampus Tuckshop.',
        selected: pickup,
        onTap: () => store.chooseFulfilment(Fulfilment.pickup),
      ),
    ),
    const SizedBox(height: 20),
    if (!store.droneAvailable)
      EatsInfo(
        color: eatsRed,
        icon: const Icon(Icons.thunderstorm_outlined),
        title: 'Drone delivery unavailable',
        subtitle:
            '${store.droneUnavailableReason}\nPlease choose pickup at the tuckshop.',
      ),
    eatsHeading(context, pickup ? 'Pickup Location' : 'Delivery Location'),
    EatsCard(
      shadow: !pickup,
      child: Row(
        children: [
          const EatsCircle(child: Icon(Icons.location_on_outlined)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  pickup ? 'Main Campus Tuckshop' : 'Main Campus',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  pickup
                      ? 'Ground Floor, Student Centre\nBelgium Campus iTversity'
                      : 'Main Building, Student Area\nBelgium Campus iTversity',
                  style: TextStyle(
                    fontSize: 12,
                    height: 1.6,
                    color: context.eatsMuted,
                  ),
                ),
              ],
            ),
          ),
          if (!pickup)
            TextButton(
              onPressed: () => _location(context),
              child: const Text(
                'Change',
                style: TextStyle(color: eatsRed, fontSize: 12),
              ),
            ),
        ],
      ),
    ),
    if (!pickup) ...[
      eatsHeading(context, 'Select Landing Pad  ⓘ'),
      Text(
        'Choose your preferred drone landing pad for delivery.',
        style: TextStyle(color: context.eatsMuted, fontSize: 12),
      ),
      const SizedBox(height: 10),
      EatsCard(
        padding: EdgeInsets.zero,
        child: Column(
          children: [
            for (var i = 0; i < 3; i++) _pad(context, i),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: eatsRed.withValues(alpha: .045),
                borderRadius: const BorderRadius.vertical(
                  bottom: Radius.circular(13),
                ),
              ),
              child: const Row(
                children: [
                  Icon(Icons.verified_user_outlined, color: eatsRed, size: 19),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Collect at the designated drone landing area.',
                      style: TextStyle(fontSize: 11),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    ],
    eatsHeading(context, pickup ? 'Pickup Time' : 'Delivery Time'),
    EatsPair(
      breakpoint: 280,
      first: _TimeChoice(
        title: 'ASAP',
        subtitle: pickup ? '15–25 min' : '20–30 min',
        selected: store.scheduledFor == null,
        onTap: () => store.schedule(null),
      ),
      second: _TimeChoice(
        title: 'Schedule for Later',
        subtitle: store.scheduledFor == null
            ? 'Choose a time'
            : eatsDate(context, store.scheduledFor!),
        selected: store.scheduledFor != null,
        onTap: () => scheduleEatsOrder(context),
      ),
    ),
    const SizedBox(height: 20),
    eatsHeading(context, 'Contact Details'),
    EatsCard(
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                const EatsCircle(child: Icon(Icons.person_outline)),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        store.customerName.isEmpty
                            ? 'Add your contact details'
                            : store.customerName,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                      if (store.phone.isNotEmpty)
                        Text(
                          store.phone,
                          style: TextStyle(
                            fontSize: 12,
                            color: context.eatsMuted,
                          ),
                        ),
                      if (store.email.isNotEmpty)
                        Text(
                          store.email,
                          style: TextStyle(
                            fontSize: 12,
                            color: context.eatsMuted,
                          ),
                        ),
                    ],
                  ),
                ),
                TextButton(
                  onPressed: () => editEatsContact(context),
                  child: const Text('Edit', style: TextStyle(color: eatsRed)),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(12),
            color: eatsRed.withValues(alpha: .045),
            child: Row(
              children: [
                const Icon(Icons.chat_bubble_outline, color: eatsRed, size: 18),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    pickup
                        ? 'These details are for this order. Edit them if you are ordering for someone else. Use your order number when collecting.'
                        : 'These details are for this order only. Edit them if you are ordering for someone else.',
                    style: const TextStyle(fontSize: 11),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ),
  ];
  Widget _pad(BuildContext context, int i) {
    const names = [
      'Main Campus Pad A',
      'Library Landing Pad',
      'Smart Cities Pad',
    ];
    const details = [
      'Open area near Main Building',
      'Next to Library Entrance',
      'Near Smart Cities Building',
    ];
    final selected = store.landingPad == names[i];
    return InkWell(
      onTap: () => setState(() => store.landingPad = names[i]),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          border: Border(bottom: BorderSide(color: context.eatsBorder)),
        ),
        child: Row(
          children: [
            Icon(
              selected
                  ? Icons.radio_button_checked
                  : Icons.radio_button_unchecked,
              color: selected ? eatsRed : context.eatsMuted,
              size: 20,
            ),
            const SizedBox(width: 12),
            const Icon(Icons.local_parking_outlined, color: eatsRed, size: 26),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    names[i],
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    details[i],
                    style: TextStyle(color: context.eatsMuted, fontSize: 11),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 6),
            Text(
              '${i == 0 ? 2 : i + 3} min walk',
              style: TextStyle(
                color: selected ? eatsRed : context.eatsMuted,
                fontSize: 10,
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _payment(BuildContext context, bool pickup) => [
    for (final method in EatsPayment.values)
      if (pickup || method != EatsPayment.cash)
        _PaymentChoice(
          method: method,
          selected: payment == method,
          enabled: true,
          onTap: () => setState(() => payment = method),
        ),
    const EatsInfo(
      icon: Icon(Icons.lock_outline),
      title: 'Your payment details stay private.',
      subtitle: 'This demo does not collect or store card details.',
    ),
  ];
  void _location(BuildContext context) => showDialog<void>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Delivery Location'),
      content: const Text(
        'Drone delivery is available within Main Campus. Choose a landing pad below the location card.',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Done'),
        ),
      ],
    ),
  );
  Future<void> _submit() async {
    if (submitting || store.count == 0) return;
    setState(() => submitting = true);
    try {
      final api = BcApiClient.instance;
      const publishableKey = String.fromEnvironment('STRIPE_PUBLISHABLE_KEY');
      final backendAvailable = await api.isBackendAvailable();
      if (backendAvailable && !api.hasToken) {
        throw const BcApiException('The backend is online, but this student session is not authenticated. Sign in with the connected student account before placing a live order.');
      }
      if (backendAvailable && api.hasToken && payment == EatsPayment.card && publishableKey.isNotEmpty) {
        final orderResponse = await api.postJson('/api/orders', {
          'items': store.cart.map((line) => {'foodId': line.product.id, 'quantity': line.quantity}).toList(),
          'deliveryAddress': store.fulfilment == Fulfilment.pickup ? 'Campus Tuck Shop' : store.landingPad,
          'deliveryNotes': store.notes,
          'deliveryType': store.fulfilment == Fulfilment.pickup ? 'pickup' : 'drone',
        });
        final order = orderResponse['data'] as Map<String, dynamic>;
        final paymentResponse = await api.postJson('/api/payments/intent', {'orderId': order['_id'].toString()});
        final clientSecret = paymentResponse['clientSecret']?.toString();
        if (clientSecret == null || clientSecret.isEmpty) throw const BcApiException('Payment provider did not return a client secret.');
        await Stripe.instance.initPaymentSheet(paymentSheetParameters: SetupPaymentSheetParameters(
          paymentIntentClientSecret: clientSecret,
          merchantDisplayName: 'BC Eats',
          style: ThemeMode.system,
        ));
        await Stripe.instance.presentPaymentSheet();
        // The webhook is the source of truth, but it cannot reach a local
        // sandbox backend unless the Stripe CLI is forwarding, so ask the
        // server to re-check with Stripe now. Best-effort: the sheet already
        // succeeded, and failing here would invite a second payment.
        String? paymentStatus;
        final paymentId = (paymentResponse['data'] as Map<String, dynamic>?)?['_id']?.toString();
        if (paymentId != null) {
          try {
            final sync = await api.postJson('/api/payments/$paymentId/sync', {});
            paymentStatus = (sync['data'] as Map<String, dynamic>?)?['status']?.toString();
          } catch (_) {}
        }
        if (paymentStatus == 'failed') throw const BcApiException('Stripe reported that this payment failed. You have not been charged.');
        if (!mounted) return;
        // Keep the existing local tracking presentation while the server order
        // and Stripe webhook remain the source of truth for payment/order state.
        final localOrder = store.placeDemoOrder(payment, store.phone);
        Navigator.pushReplacement(context, MaterialPageRoute<void>(
          settings: const RouteSettings(name: '/confirmation'),
          builder: (_) => BCEatsTrackingScreen(order: localOrder),
        ));
        return;
      }
      if (backendAvailable && api.hasToken && payment == EatsPayment.card && publishableKey.isEmpty) {
        throw const BcApiException('The backend is online, but STRIPE_PUBLISHABLE_KEY is not configured for the app.');
      }
      if (backendAvailable && api.hasToken && payment != EatsPayment.card) {
        throw const BcApiException('Live checkout currently supports card payments through Stripe. Choose Card or disconnect the backend to use preview mode.');
      }
      // No backend connection: explicitly use the existing local preview.
      final order = store.placeDemoOrder(payment, store.phone);
      if (!mounted) return;
      Navigator.pushReplacement(context, MaterialPageRoute<void>(
        settings: const RouteSettings(name: '/confirmation'),
        builder: (_) => BCEatsTrackingScreen(order: order),
      ));
    } on StripeException catch (error) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error.error.localizedMessage ?? 'Payment was not completed. You have not been charged unless Stripe confirms payment.')));
      if (mounted) setState(() => submitting = false);
    } catch (error) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error.toString())));
      if (mounted) setState(() => submitting = false);
    }
  }

}

class _DeliveryChoice extends StatelessWidget {
  final String title, subtitle;
  final bool selected, enabled, drone;
  final VoidCallback onTap;
  const _DeliveryChoice({
    required this.title,
    required this.subtitle,
    required this.selected,
    required this.onTap,
    this.enabled = true,
    this.drone = false,
  });
  @override
  Widget build(BuildContext context) => Material(
    color: enabled
        ? context.eatsSurface
        : context.eatsBorder.withValues(alpha: .15),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(12),
      side: BorderSide(color: selected ? eatsRed : context.eatsBorder),
    ),
    child: InkWell(
      onTap: enabled ? onTap : null,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(10, 12, 10, 16),
        child: Column(
          children: [
            Align(
              alignment: Alignment.centerRight,
              child: Icon(
                !enabled
                    ? Icons.cancel
                    : selected
                    ? Icons.check_circle
                    : Icons.radio_button_unchecked,
                color: selected
                    ? eatsRed
                    : context.eatsMuted.withValues(alpha: .5),
                size: 18,
              ),
            ),
            drone
                ? DroneIcon(
                    size: 39,
                    color: !enabled
                        ? context.eatsMuted
                        : selected
                        ? eatsRed
                        : Colors.black,
                  )
                : Icon(
                    Icons.storefront_outlined,
                    size: 39,
                    color: selected ? eatsRed : context.eatsInk,
                  ),
            const SizedBox(height: 12),
            Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: enabled ? context.eatsInk : context.eatsMuted,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 11,
                height: 1.5,
                color: context.eatsMuted,
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

class _TimeChoice extends StatelessWidget {
  final String title, subtitle;
  final bool selected;
  final VoidCallback onTap;
  const _TimeChoice({
    required this.title,
    required this.subtitle,
    required this.selected,
    required this.onTap,
  });
  @override
  Widget build(BuildContext context) => InkWell(
    onTap: onTap,
    borderRadius: BorderRadius.circular(12),
    child: Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: selected ? eatsRed : context.eatsBorder),
      ),
      child: Row(
        children: [
          Icon(
            Icons.access_time,
            color: selected ? eatsRed : context.eatsMuted,
            size: 24,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(fontSize: 11, color: context.eatsMuted),
                ),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}

class _PaymentChoice extends StatelessWidget {
  final EatsPayment method;
  final bool selected, enabled;
  final VoidCallback onTap;
  const _PaymentChoice({
    required this.method,
    required this.selected,
    required this.enabled,
    required this.onTap,
  });
  @override
  Widget build(BuildContext context) {
    final titles = [
      'Card',
      'EFT / Bank Transfer',
      'Student Account',
      'Cash on Pickup',
    ];
    final subtitles = [
      'Visa, Mastercard',
      'Pay directly from your bank',
      'Pay using your student account balance',
      enabled
          ? 'Pay when you collect your order'
          : 'Available with pickup only',
    ];
    final colors = [
      eatsRed,
      eatsGreen,
      const Color(0xFF913FFA),
      const Color(0xFFFF7600),
    ];
    final icons = [
      Icons.credit_card,
      Icons.account_balance_outlined,
      Icons.school_outlined,
      Icons.payments_outlined,
    ];
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: context.eatsSurface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: selected ? eatsRed : context.eatsBorder),
        ),
        child: InkWell(
          onTap: enabled ? onTap : null,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 18),
            child: Row(
              children: [
                Icon(
                  icons[method.index],
                  size: 30,
                  color: enabled ? colors[method.index] : context.eatsMuted,
                ),
                const SizedBox(width: 18),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        titles[method.index],
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 15,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        subtitles[method.index],
                        style: TextStyle(
                          color: context.eatsMuted,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                if (method == EatsPayment.card &&
                    MediaQuery.sizeOf(context).width >= 500) ...[
                  const Text(
                    'VISA',
                    style: TextStyle(
                      color: Color(0xFF153D8A),
                      fontWeight: FontWeight.w900,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                  const SizedBox(width: 12),
                ],
                Icon(
                  selected
                      ? Icons.radio_button_checked
                      : Icons.radio_button_unchecked,
                  color: selected ? eatsRed : context.eatsMuted,
                  size: 22,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
