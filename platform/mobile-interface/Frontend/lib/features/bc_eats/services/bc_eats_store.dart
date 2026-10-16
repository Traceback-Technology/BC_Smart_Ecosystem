import 'dart:math';
import 'package:flutter/foundation.dart';
import '../models/bc_eats_product.dart';
import '../../../core/bc_api_client.dart';

enum Fulfilment { drone, pickup }

enum EatsPayment { card, eft, student, cash }

enum EatsStatus { received, preparing, ready, completed }

String money(int cents) => 'R${(cents / 100).toStringAsFixed(2)}';

class EatsLine {
  final BcEatsProduct product;
  final int quantity;
  const EatsLine(this.product, this.quantity);
  int get total => (product.price * 100).round() * quantity;
}

class EatsOrder {
  final String id;
  final DateTime placedAt;
  final List<EatsLine> lines;
  final Fulfilment fulfilment;
  final EatsPayment payment;
  final String location, contact, notes;
  final String customerName, email;
  final DateTime? scheduledFor;
  final Map<EatsStatus, DateTime> statusTimes = {};
  final int serviceFee, deliveryFee;
  EatsStatus status = EatsStatus.preparing;
  String? backendId;
  DateTime? completedAt; 

  // Drone handover verification.
  DateTime? droneArrivedAt;
  String? deliveryOtp;
  DateTime? deliveryOtpExpiresAt;
  bool deliveryOtpVerified = false;

  int rating = 0;
  EatsOrder({
    required this.id,
    required this.placedAt,
    required this.lines,
    required this.fulfilment,
    required this.payment,
    required this.location,
    required this.contact,
    required this.notes,
    required this.serviceFee,
    required this.deliveryFee,
    this.customerName = '',
    this.email = '',
    this.scheduledFor,
  }) {
    statusTimes[EatsStatus.received] = placedAt;
    statusTimes[EatsStatus.preparing] = placedAt;
  }
  int get subtotal => lines.fold(0, (sum, line) => sum + line.total);
  int get total => subtotal + serviceFee + deliveryFee;
  bool get completed => status == EatsStatus.completed;
  bool get isBackendOrder => backendId != null && backendId!.isNotEmpty;

  bool get droneArrived => droneArrivedAt != null;

  bool get deliveryOtpValid =>
      deliveryOtp != null &&
      deliveryOtpExpiresAt != null &&
      DateTime.now().isBefore(deliveryOtpExpiresAt!);

  String get statusLabel => switch (status) {
    EatsStatus.received => 'Order received',
    EatsStatus.preparing => 'Being prepared',
    EatsStatus.ready =>
      fulfilment == Fulfilment.drone ? 'On the way' : 'Ready for pickup',
    EatsStatus.completed =>
      fulfilment == Fulfilment.drone ? 'Delivered' : 'Collected',
  };
}

/// Session-only demo state. Replace checkout/status updates with your backend
/// before production; no payment credentials are collected or charged here.
class BcEatsStore extends ChangeNotifier {
  static final instance = BcEatsStore();
  final Map<String, EatsLine> _cart = {};
  final List<EatsOrder> _orders = [];
  Fulfilment _fulfilment = Fulfilment.drone;
  bool _hasFulfilmentChoice = false;
  bool _droneAvailable = true;
  String landingPad = 'Main Campus Pad A';
  String notes = '';
  String customerName = '', phone = '', email = '';

  String _profileAccountKey = '';
  String _profileName = '';
  String _profilePhone = '';
  String _profileEmail = '';

  bool _contactEditedForCurrentOrder = false;
  DateTime? scheduledFor;
  String droneUnavailableReason =
      'Current weather conditions are not suitable for drone delivery.';
  int _sequence = 0;
  List<EatsLine> get cart => List.unmodifiable(_cart.values);
  List<EatsOrder> get orders => List.unmodifiable(_orders);
  Fulfilment get fulfilment => _fulfilment;
  bool get hasFulfilmentChoice => _hasFulfilmentChoice;
  bool get droneAvailable => _droneAvailable;
  int quantityFor(String productId) => _cart[productId]?.quantity ?? 0;
  int get count => _cart.values.fold(0, (sum, line) => sum + line.quantity);
  int get subtotal => _cart.values.fold(0, (sum, line) => sum + line.total);
  int get serviceFee => _cart.isEmpty ? 0 : 500;
  int get deliveryFee =>
      _cart.isEmpty || !_hasFulfilmentChoice || _fulfilment == Fulfilment.pickup
      ? 0
      : 1500;
  int get total => subtotal + serviceFee + deliveryFee;
  void setDroneAvailable(bool value) {
    _droneAvailable = value;

    if (!value && _hasFulfilmentChoice && _fulfilment == Fulfilment.drone) {
      _hasFulfilmentChoice = false;
    }

    notifyListeners();
  }

  void chooseFulfilment(Fulfilment value) {
    if (value == Fulfilment.drone && !_droneAvailable) {
      return;
    }

    _fulfilment = value;
    _hasFulfilmentChoice = true;
    notifyListeners();
  }

  void add(BcEatsProduct product) {
    if (!product.isAvailable) return;
    _cart[product.id] = EatsLine(
      product,
      (_cart[product.id]?.quantity ?? 0) + 1,
    );
    notifyListeners();
  }

  void decrease(String id) {
    final line = _cart[id];

    if (line == null) {
      return;
    }

    if (line.quantity == 1) {
      _cart.remove(id);
    } else {
      _cart[id] = EatsLine(line.product, line.quantity - 1);
    }

    if (_cart.isEmpty) {
      _hasFulfilmentChoice = false;

      _contactEditedForCurrentOrder = false;
      _restoreProfileContact();
    }

    notifyListeners();
  }

  void remove(String id) {
    _cart.remove(id);

    if (_cart.isEmpty) {
      _hasFulfilmentChoice = false;

      _contactEditedForCurrentOrder = false;
      _restoreProfileContact();
    }

    notifyListeners();
  }

  void clear() {
    _cart.clear();
    notes = '';
    scheduledFor = null;
    _hasFulfilmentChoice = false;

    _contactEditedForCurrentOrder = false;
    _restoreProfileContact();

    notifyListeners();
  }

  void updateNotes(String value) {
    notes = value;
    notifyListeners();
  }

  void schedule(DateTime? value) {
    scheduledFor = value;
    notifyListeners();
  }

  void setProfileContactDefaults({
    required String accountKey,
    required String name,
    required String phone,
    required String email,
  }) {
    final normalizedAccountKey = accountKey.trim().toLowerCase();

    final accountChanged = _profileAccountKey != normalizedAccountKey;

    _profileAccountKey = normalizedAccountKey;
    _profileName = name.trim();
    _profilePhone = phone.trim();
    _profileEmail = email.trim();

    // Profile values are defaults for an order.
    // Never overwrite details deliberately edited for the
    // current order.
    if (accountChanged) {
      _contactEditedForCurrentOrder = false;
    }

    if (!_contactEditedForCurrentOrder) {
      _restoreProfileContact();
    }

    notifyListeners();
  }

  void _restoreProfileContact() {
    customerName = _profileName;
    phone = _profilePhone;
    email = _profileEmail;
  }

  void updateContact(String name, String number, String address) {
    customerName = name.trim();
    phone = number.trim();
    email = address.trim();

    // Checkout edits apply only to the current order.
    _contactEditedForCurrentOrder = true;

    notifyListeners();
  }

  EatsOrder placeDemoOrder(EatsPayment payment, String contact) {
    if (_cart.isEmpty) {
      throw StateError('Your cart is empty.');
    }

    if (!_hasFulfilmentChoice) {
      throw StateError('Choose delivery or pickup before placing your order.');
    }
    if (payment == EatsPayment.cash && _fulfilment != Fulfilment.pickup) {
      throw StateError('Cash is available only for pickup.');
    }
    final now = DateTime.now();
    if (scheduledFor != null && !scheduledFor!.isAfter(now)) {
      throw StateError('Please choose a future time.');
    }
    final order = EatsOrder(
      id: 'BCE${now.millisecondsSinceEpoch.toString().substring(7)}${++_sequence}',
      placedAt: now,
      lines: List.unmodifiable(cart),
      fulfilment: _fulfilment,
      payment: payment,
      location: _fulfilment == Fulfilment.drone
          ? landingPad
          : 'Main Campus Tuckshop · Student Centre',
      contact: contact,
      notes: notes,
      serviceFee: serviceFee,
      deliveryFee: deliveryFee,
      customerName: customerName,
      email: email,
      scheduledFor: scheduledFor,
    );
    _orders.insert(0, order);

    _cart.clear();
    notes = '';
    scheduledFor = null;
    _hasFulfilmentChoice = false;

    _contactEditedForCurrentOrder = false;
    _restoreProfileContact();

    notifyListeners();
    return order;
  }

  void markDroneArrived(EatsOrder order) {
    if (!_orders.contains(order) ||
        order.completed ||
        order.fulfilment != Fulfilment.drone ||
        order.status != EatsStatus.ready) {
      return;
    }

    order.droneArrivedAt ??= DateTime.now();

    if (!order.deliveryOtpValid) {
      _issueDeliveryOtp(order);
    }

    notifyListeners();
  }

  void requestDeliveryOtp(EatsOrder order) {
    if (!_orders.contains(order) ||
        order.completed ||
        order.fulfilment != Fulfilment.drone ||
        !order.droneArrived ||
        order.deliveryOtpValid) {
      return;
    }

    _issueDeliveryOtp(order);
    notifyListeners();
  }

  void _issueDeliveryOtp(EatsOrder order) {
    final random = Random.secure();

    order.deliveryOtp = (100000 + random.nextInt(900000)).toString();

    order.deliveryOtpExpiresAt = DateTime.now().add(const Duration(minutes: 5));

    order.deliveryOtpVerified = false;
  }

  bool verifyDeliveryOtp(EatsOrder order, String otp) {
    if (!_orders.contains(order) ||
        order.completed ||
        order.fulfilment != Fulfilment.drone ||
        !order.droneArrived ||
        !order.deliveryOtpValid ||
        order.deliveryOtp != otp) {
      return false;
    }

    final now = DateTime.now();

    order.deliveryOtpVerified = true;
    order.status = EatsStatus.completed;
    order.statusTimes[EatsStatus.completed] = now;
    order.completedAt = now;

    notifyListeners();
    return true;
  }

  void advanceDemo(EatsOrder order) {
    if (!_orders.contains(order) || order.completed) return;

    // For drone orders, reaching the landing pad is now a separate
    // step. Delivery is completed only after OTP verification.
    if (order.fulfilment == Fulfilment.drone &&
        order.status == EatsStatus.ready) {
      markDroneArrived(order);
      return;
    }

    order.status = EatsStatus.values[order.status.index + 1];
    order.statusTimes[order.status] = DateTime.now();

    if (order.completed) {
      order.completedAt = order.statusTimes[order.status];
    }

    notifyListeners();
  }

  EatsStatus _statusFromServer(String? s) => switch (s) {
    'confirmed' => EatsStatus.received,
    'preparing' => EatsStatus.preparing,
    'ready' || 'drone_assigned' => EatsStatus.ready,
    'delivered' || 'completed' || 'collected' => EatsStatus.completed,
    _ => EatsStatus.preparing,
  };

  Future<void> refreshBackendOrder(EatsOrder order) async {
    final id = order.backendId;
    if (id == null || id.isEmpty || !_orders.contains(order)) return;

    final res = await BcApiClient.instance.getJson('/api/orders/$id');
    final data = res['data'];
    if (data is! Map<String, dynamic>) return;

    final next = _statusFromServer(
      (data['serverStatus'] ?? data['status'])?.toString(),
    );
    // Only move forward so a stale response can't undo progress.
    if (next.index <= order.status.index) return;

    order.status = next;
    final now = DateTime.now();
    order.statusTimes[next] = now;
    if (next == EatsStatus.completed) order.completedAt = now;
    notifyListeners();
  }

  void rate(EatsOrder order, int rating) {
    if (!order.completed || rating < 1 || rating > 5) return;
    order.rating = rating;
    notifyListeners();
  }

  void reorder(EatsOrder order) {
    for (final line in order.lines) {
      if (line.product.isAvailable) {
        _cart[line.product.id] = EatsLine(
          line.product,
          (_cart[line.product.id]?.quantity ?? 0) + line.quantity,
        );
      }
    }
    notifyListeners();
  }
}
