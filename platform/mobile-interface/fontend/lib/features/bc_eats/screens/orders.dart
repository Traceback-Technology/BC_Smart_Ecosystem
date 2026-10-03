import 'package:flutter/material.dart';

void main() => runApp(const orders());

// --- 1. Root App Widget (Simplified & Error-Free) ---
class orders extends StatelessWidget {
  const orders({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'BC Eats',
      debugShowCheckedModeBanner: false,
      themeMode: ThemeMode.system, // Automatically follows device settings
      theme: ThemeData(
        brightness: Brightness.light,
        primaryColor: const Color(0xFFE53935),
        scaffoldBackgroundColor: const Color(0xFFF9FAFB),
        cardColor: Colors.white,
        fontFamily: 'Lato',
        colorScheme: const ColorScheme.light(primary: Colors.red),
      ),
      darkTheme: ThemeData(
        brightness: Brightness.dark,
        primaryColor: const Color(0xFFE53935),
        scaffoldBackgroundColor: const Color(0xFF121212),
        cardColor: const Color(0xFF1E1E1E),
        fontFamily: 'Lato',
        colorScheme: const ColorScheme.dark(primary: Colors.red),
      ),
      home: const OrdersScreen(),
    );
  }
}

// --- 2. State Enum ---
enum OrderStage { cart, checkout, payment, preparing, droneTracking, delivered }

// --- 3. Main Orders Screen ---
class OrdersScreen extends StatefulWidget {
  const OrdersScreen({super.key});

  @override
  State<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends State<OrdersScreen> {
  OrderStage _currentStage = OrderStage.cart;
  
  bool _isDelivery = true; 
  int _selectedPadIndex = 0; 
  int _selectedPaymentIndex = 0; // 0: Card, 1: EFT, 2: Cash on Pickup, 3: Cash on Delivery

  void _advanceStage(OrderStage nextStage) {
    setState(() => _currentStage = nextStage);
  }

  void _goBack() {
    setState(() {
      if (_currentStage == OrderStage.checkout) _currentStage = OrderStage.cart;
      else if (_currentStage == OrderStage.payment) _currentStage = OrderStage.checkout;
      else if (_currentStage == OrderStage.preparing) _currentStage = OrderStage.payment;
    });
  }

  Future<void> _selectScheduleTime(BuildContext context) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    if (picked != null && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Order scheduled for ${picked.format(context)}'), backgroundColor: Colors.green),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildDynamicAppBar(),
      body: SafeArea(
        child: Column(
          children: [
            if (_currentStage == OrderStage.cart || 
                _currentStage == OrderStage.checkout || 
                _currentStage == OrderStage.payment)
              _buildTopStepper(),
              
            Expanded(child: _buildDynamicBody()),
          ],
        ),
      ),
      bottomNavigationBar: _currentStage.index < OrderStage.preparing.index || _currentStage == OrderStage.delivered
          ? _buildBottomNav()
          : null,
    );
  }

  // --- App Bar (Removed the buggy toggle button) ---
  PreferredSizeWidget _buildDynamicAppBar() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : Colors.black;

    return AppBar(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      elevation: 0,
      leading: IconButton(
        icon: Icon(Icons.arrow_back, color: textColor),
        onPressed: _goBack,
      ),
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(border: Border.all(color: textColor, width: 2), borderRadius: BorderRadius.circular(4)),
            child: Text('2', style: TextStyle(color: textColor, fontWeight: FontWeight.w900, fontSize: 16)),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(_currentStage == OrderStage.droneTracking ? 'BC WAYS & EATS' : 'BC EATS', 
                  style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 18)),
              const Text('Campus Tuckshop', style: TextStyle(color: Colors.grey, fontSize: 12)),
            ],
          ),
        ],
      ),
    );
  }

  // --- Top Stepper ---
  Widget _buildTopStepper() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Container(
      color: Theme.of(context).cardColor,
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _buildStep(1, 'Your Cart', true, isDark),
          _buildStepDivider(true, isDark),
          _buildStep(2, 'Delivery / Pickup', _currentStage.index >= OrderStage.checkout.index, isDark),
          _buildStepDivider(_currentStage.index >= OrderStage.checkout.index, isDark),
          _buildStep(3, 'Payment', _currentStage.index >= OrderStage.payment.index, isDark),
        ],
      ),
    );
  }

  Widget _buildStep(int stepNumber, String title, bool isActive, bool isDark) {
    return Column(
      children: [
        Container(
          width: 24, height: 24,
          decoration: BoxDecoration(
            color: isActive ? Colors.red : (isDark ? Colors.grey.shade800 : Colors.grey.shade300),
            shape: BoxShape.circle,
          ),
          child: Center(
            child: isActive 
                ? const Icon(Icons.check, size: 16, color: Colors.white)
                : Text('$stepNumber', style: TextStyle(color: isDark ? Colors.grey.shade400 : Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
          ),
        ),
        const SizedBox(height: 4),
        Text(title, style: TextStyle(fontSize: 10, color: isActive ? (isDark ? Colors.white : Colors.black) : Colors.grey)),
      ],
    );
  }

  Widget _buildStepDivider(bool isActive, bool isDark) {
    return Expanded(
      child: Container(
        height: 2,
        color: isActive ? Colors.red : (isDark ? Colors.grey.shade700 : Colors.grey.shade300),
        margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 10),
      ),
    );
  }

  // --- Body Router ---
  Widget _buildDynamicBody() {
    switch (_currentStage) {
      case OrderStage.cart: return _buildCartView();
      case OrderStage.checkout: return _buildCheckoutView();
      case OrderStage.payment: return _buildPaymentView();
      case OrderStage.preparing: return _buildPreparingView();
      case OrderStage.droneTracking: return _buildDroneTrackingView();
      case OrderStage.delivered: return _buildDeliveredView();
    }
  }

  // --- 1. Cart View ---
  Widget _buildCartView() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : Colors.black;
    final subtleTextColor = isDark ? Colors.grey.shade400 : Colors.grey.shade600;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text('Your Cart (3)', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: textColor)),
        const SizedBox(height: 16),
        _buildCartItemInteractive(Icons.lunch_dining, 'Beef Burger Meal', 'R65.00'),
        _buildCartItemInteractive(Icons.ramen_dining, 'Chicken Pasta', 'R78.00'),
        _buildCartItemInteractive(Icons.local_drink, 'Coca-Cola (500ml)', 'R15.00'),
        const SizedBox(height: 16),
        
        Card(
          color: Theme.of(context).cardColor,
          child: ListTile(
            leading: const Icon(Icons.receipt_long, color: Colors.red),
            title: Text('Special Instructions', style: TextStyle(fontWeight: FontWeight.bold, color: textColor)),
            subtitle: Text('Add any notes (optional)', style: TextStyle(color: subtleTextColor)),
            trailing: Icon(Icons.chevron_right, color: textColor),
          ),
        ),
        const SizedBox(height: 16),
        _buildOrderSummary(),
        const SizedBox(height: 16),
        
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: isDark ? Colors.grey.shade900 : Colors.green.shade50, borderRadius: BorderRadius.circular(8)),
          child: Row(
            children: [
              Icon(_isDelivery ? Icons.moped : Icons.storefront, color: Colors.green),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(_isDelivery ? 'Deliver to: Main Campus' : 'Pickup at: Tuckshop', style: TextStyle(fontWeight: FontWeight.bold, color: textColor)),
                    Text(_isDelivery ? '20-30 min • R15.00 delivery fee' : 'Ready in 15 mins • No fee', style: TextStyle(fontSize: 12, color: subtleTextColor)),
                  ],
                ),
              ),
              TextButton(
                onPressed: () => _advanceStage(OrderStage.checkout), 
                child: const Text('Change', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold))
              )
            ],
          ),
        ),
        const SizedBox(height: 24),
        
        Row(
          children: [
            Expanded(flex: 2, child: _buildYellowButton('Proceed to Checkout', Icons.arrow_forward, () => _advanceStage(OrderStage.checkout))),
            const SizedBox(width: 12),
            Expanded(
              flex: 1,
              child: OutlinedButton.icon(
                onPressed: () => _selectScheduleTime(context),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  side: const BorderSide(color: Colors.amber, width: 2),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))
                ),
                icon: const Icon(Icons.calendar_month, color: Colors.amber),
                label: Text('Schedule', style: TextStyle(color: textColor, fontWeight: FontWeight.bold)),
              ),
            )
          ],
        )
      ],
    );
  }

  Widget _buildCartItemInteractive(IconData icon, String title, String price) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : Colors.black;

    return Card(
      color: Theme.of(context).cardColor,
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: isDark ? Colors.grey.shade800 : Colors.grey.shade100, borderRadius: BorderRadius.circular(8)),
              child: Icon(icon, size: 40, color: Colors.orange),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: textColor)),
                  const SizedBox(height: 8),
                  Text(price, style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 16)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- 2. Checkout View ---
  Widget _buildCheckoutView() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : Colors.black;
    final subtleTextColor = isDark ? Colors.grey.shade400 : Colors.grey.shade600;
    final borderColor = isDark ? Colors.grey.shade700 : Colors.grey.shade300;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text('Delivery or Pickup', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: textColor)),
        Text('Choose how you would like to receive your order.', style: TextStyle(color: subtleTextColor)),
        const SizedBox(height: 16),
        
        Row(
          children: [
            Expanded(
              child: GestureDetector(
                onTap: () => setState(() { 
                  _isDelivery = true;
                  if (_selectedPaymentIndex == 2) _selectedPaymentIndex = 0; // Reset Cash on Pickup
                }),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: _isDelivery ? (isDark ? Colors.red.withOpacity(0.2) : Colors.red.shade50) : Theme.of(context).cardColor,
                    border: Border.all(color: _isDelivery ? Colors.red : borderColor, width: 2),
                    borderRadius: BorderRadius.circular(8)
                  ),
                  child: Column(
                    children: [
                      Icon(Icons.moped, size: 40, color: _isDelivery ? Colors.red : subtleTextColor),
                      const SizedBox(height: 8),
                      Text('Deliver to Me', style: TextStyle(fontWeight: FontWeight.bold, color: _isDelivery ? Colors.red : subtleTextColor)),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: GestureDetector(
                onTap: () => setState(() { 
                  _isDelivery = false;
                  if (_selectedPaymentIndex == 3) _selectedPaymentIndex = 0; // Reset Cash on Delivery
                }),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: !_isDelivery ? (isDark ? Colors.red.withOpacity(0.2) : Colors.red.shade50) : Theme.of(context).cardColor,
                    border: Border.all(color: !_isDelivery ? Colors.red : borderColor, width: 2),
                    borderRadius: BorderRadius.circular(8)
                  ),
                  child: Column(
                    children: [
                      Icon(Icons.storefront, size: 40, color: !_isDelivery ? Colors.red : subtleTextColor),
                      const SizedBox(height: 8),
                      Text('Pickup at Tuckshop', style: TextStyle(fontWeight: FontWeight.bold, color: !_isDelivery ? Colors.red : subtleTextColor)),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        
        if (_isDelivery) ...[
          Text('Select Landing Pad', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: textColor)),
          Text('Choose your preferred drone landing pad.', style: TextStyle(color: subtleTextColor, fontSize: 12)),
          const SizedBox(height: 12),
          _buildLandingPadOption(0, 'Main Campus Pad A', 'Open area near Main Building', true, '2 min walk'),
          _buildLandingPadOption(1, 'Library Landing Pad', 'Next to Library Entrance', false, '4 min walk'),
          _buildLandingPadOption(2, 'Smart Cities Pad', 'Near Smart Cities Building', false, '5 min walk'),
          const SizedBox(height: 16),
        ] else ...[
          Text('Pickup Location', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: textColor)),
          Card(
            color: Theme.of(context).cardColor,
            child: ListTile(
              leading: const Icon(Icons.store, color: Colors.red),
              title: Text('Main Campus Tuckshop', style: TextStyle(fontWeight: FontWeight.bold, color: textColor)),
              subtitle: Text('Ground Floor, Student Centre', style: TextStyle(color: subtleTextColor)),
            ),
          ),
          const SizedBox(height: 16),
        ],
        
        Text('Contact Details', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: textColor)),
        Card(
          color: Theme.of(context).cardColor,
          child: ListTile(
            leading: const Icon(Icons.person, color: Colors.grey),
            title: Text('Sipho Dlamini', style: TextStyle(fontWeight: FontWeight.bold, color: textColor)),
            subtitle: Text('071 234 5678\nsipho.dlamini@student.itversity.ac.za', style: TextStyle(color: subtleTextColor)),
          ),
        ),
        const SizedBox(height: 24),
        _buildOrderSummary(),
        const SizedBox(height: 24),
        _buildYellowButton('Continue to Payment', Icons.arrow_forward, () => _advanceStage(OrderStage.payment)),
      ],
    );
  }

  Widget _buildLandingPadOption(int index, String title, String subtitle, bool isRecommended, String walkTime) {
    bool isSelected = _selectedPadIndex == index;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : Colors.black;
    final subtleTextColor = isDark ? Colors.grey.shade400 : Colors.grey.shade600;
    final borderColor = isDark ? Colors.grey.shade700 : Colors.grey.shade300;

    return GestureDetector(
      onTap: () => setState(() => _selectedPadIndex = index),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          border: Border.all(color: isSelected ? Colors.red : borderColor, width: isSelected ? 2 : 1),
          borderRadius: BorderRadius.circular(8)
        ),
        child: Row(
          children: [
            Icon(isSelected ? Icons.radio_button_checked : Icons.radio_button_off, color: isSelected ? Colors.red : subtleTextColor),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Wrap(
                    crossAxisAlignment: WrapCrossAlignment.center,
                    spacing: 8,
                    runSpacing: 4,
                    children: [
                      Text(title, style: TextStyle(fontWeight: FontWeight.bold, color: textColor)),
                      if (isRecommended)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(color: Colors.red.withOpacity(0.1), border: Border.all(color: Colors.red), borderRadius: BorderRadius.circular(12)),
                          child: const Text('Recommended', style: TextStyle(color: Colors.red, fontSize: 10, fontWeight: FontWeight.bold)),
                        )
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(subtitle, style: TextStyle(fontSize: 12, color: subtleTextColor)),
                ],
              ),
            ),
            Text(walkTime, style: const TextStyle(color: Colors.red, fontSize: 12)),
          ],
        ),
      ),
    );
  }

  // --- 3. Payment View ---
  Widget _buildPaymentView() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : Colors.black;
    final subtleTextColor = isDark ? Colors.grey.shade400 : Colors.grey.shade600;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text('Choose Payment Method', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: textColor)),
        Text('Select your preferred payment option.', style: TextStyle(color: subtleTextColor)),
        const SizedBox(height: 16),
        
        _buildPaymentOption(0, Icons.credit_card, 'Card', 'Visa, Mastercard'),
        _buildPaymentOption(1, Icons.account_balance, 'EFT / Bank Transfer', 'Pay directly from your bank'),
        
        if (_isDelivery)
          _buildPaymentOption(3, Icons.money, 'Cash on Delivery', 'Pay when your order arrives'),
        
        if (!_isDelivery)
          _buildPaymentOption(2, Icons.payments, 'Cash on Pickup', 'Pay when you collect your order'),
          
        const SizedBox(height: 24),
        _buildOrderSummary(),
        const SizedBox(height: 24),
        _buildYellowButton('Pay ${_isDelivery ? "R178.00" : "R163.00"} Securely', Icons.lock, () => _advanceStage(OrderStage.preparing)),
      ],
    );
  }

  Widget _buildPaymentOption(int index, IconData icon, String title, String subtitle) {
    bool isSelected = _selectedPaymentIndex == index;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : Colors.black;
    final subtleTextColor = isDark ? Colors.grey.shade400 : Colors.grey.shade600;
    final borderColor = isDark ? Colors.grey.shade700 : Colors.grey.shade300;

    return GestureDetector(
      onTap: () => setState(() => _selectedPaymentIndex = index),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          border: Border.all(color: isSelected ? Colors.red : borderColor, width: isSelected ? 2 : 1),
          borderRadius: BorderRadius.circular(8)
        ),
        child: Row(
          children: [
            Icon(icon, color: isSelected ? Colors.red : subtleTextColor),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: TextStyle(fontWeight: FontWeight.bold, color: textColor)),
                  Text(subtitle, style: TextStyle(fontSize: 12, color: subtleTextColor)),
                ],
              ),
            ),
            Icon(isSelected ? Icons.radio_button_checked : Icons.radio_button_off, color: isSelected ? Colors.red : subtleTextColor),
          ],
        ),
      ),
    );
  }

  // --- 4. Preparing View ---
  Widget _buildPreparingView() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : Colors.black;
    final subtleTextColor = isDark ? Colors.grey.shade400 : Colors.grey.shade600;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.green, size: 50),
            const SizedBox(width: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Thank you, Sipho!', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: textColor)),
                const Text('Your order has been placed.', style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
              ],
            )
          ],
        ),
        const SizedBox(height: 24),
        Card(
          color: Theme.of(context).cardColor,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                const Icon(Icons.access_time, color: Colors.amber, size: 40),
                const SizedBox(width: 16),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Estimated time', style: TextStyle(color: subtleTextColor)),
                    const Text('20 - 30 min', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.amber)),
                  ],
                )
              ],
            ),
          ),
        ),
        const SizedBox(height: 24),
        
        Text('Order Details', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: textColor)),
        const SizedBox(height: 12),
        _buildCheckoutItemSummary(Icons.lunch_dining, 'Beef Burger Meal', 'Beef burger, fries & a soft drink', 'R65.00', '1'),
        _buildCheckoutItemSummary(Icons.ramen_dining, 'Chicken Pasta', 'Creamy pasta with grilled chicken', 'R78.00', '1'),
        _buildCheckoutItemSummary(Icons.local_drink, 'Coca-Cola (500ml)', '500ml', 'R15.00', '1'),
        Divider(height: 32, thickness: 1, color: isDark ? Colors.grey.shade800 : Colors.grey.shade300),
        _buildOrderSummary(),
        const SizedBox(height: 24),

        _isDelivery 
          ? _buildYellowButton('Simulate Drone Dispatch', Icons.flight_takeoff, () => _advanceStage(OrderStage.droneTracking))
          : _buildYellowButton('Simulate Ready for Collection', Icons.store, () => _advanceStage(OrderStage.delivered)),
      ],
    );
  }

  Widget _buildCheckoutItemSummary(IconData icon, String title, String desc, String price, String qty) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : Colors.black;
    final subtleTextColor = isDark ? Colors.grey.shade400 : Colors.grey.shade600;

    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 60, height: 60,
            decoration: BoxDecoration(
              color: isDark ? Colors.grey.shade800 : Colors.grey.shade200,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: isDark ? Colors.grey.shade700 : Colors.grey.shade300)
            ),
            child: Icon(icon, color: Colors.orange, size: 30),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: textColor)),
                Text(desc, style: TextStyle(color: subtleTextColor, fontSize: 12)),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(price, style: TextStyle(fontWeight: FontWeight.bold, color: textColor)),
              Text('x $qty', style: TextStyle(color: subtleTextColor)),
            ],
          )
        ],
      ),
    );
  }

  // --- 5. Drone Tracking View ---
  Widget _buildDroneTrackingView() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : Colors.black;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text('Track Your Drone', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: textColor)),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _buildTrackingNode(Icons.receipt, 'Confirmed', true, isDark),
            _buildTrackingLine(true, isDark),
            _buildTrackingNode(Icons.soup_kitchen, 'Preparing', true, isDark),
            _buildTrackingLine(true, isDark),
            _buildTrackingNode(Icons.flight, 'On the Way', true, isDark),
            _buildTrackingLine(false, isDark),
            _buildTrackingNode(Icons.location_on, 'Arriving', false, isDark),
          ],
        ),
        const SizedBox(height: 24),
        Container(
          height: 200, width: double.infinity,
          decoration: BoxDecoration(color: isDark ? Colors.grey.shade800 : Colors.grey.shade300, borderRadius: BorderRadius.circular(12)),
          child: const Center(child: Text('Map Integration Pending', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold))),
        ),
        const SizedBox(height: 24),
        _buildYellowButton('Simulate Delivery Arrival', Icons.done_all, () => _advanceStage(OrderStage.delivered)),
      ],
    );
  }

  Widget _buildTrackingNode(IconData icon, String label, bool isComplete, bool isDark) {
    return Column(
      children: [
        Icon(icon, color: isComplete ? Colors.amber : (isDark ? Colors.grey.shade600 : Colors.grey), size: 28),
        const SizedBox(height: 4),
        Text(label, style: TextStyle(fontSize: 10, color: isComplete ? Colors.amber : (isDark ? Colors.grey.shade600 : Colors.grey), fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _buildTrackingLine(bool isComplete, bool isDark) {
    return Expanded(child: Container(height: 3, color: isComplete ? Colors.amber : (isDark ? Colors.grey.shade800 : Colors.grey.shade300)));
  }

  // --- 6. Delivered View ---
  Widget _buildDeliveredView() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : Colors.black;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Icon(Icons.check_circle, color: Colors.green, size: 80),
        const SizedBox(height: 16),
        Center(child: Text(_isDelivery ? 'Delivered!' : 'Collected!', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: textColor))),
        const Center(child: Text('Enjoy your meal, Sipho!', style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold))),
        const SizedBox(height: 24),
        Card(
          color: Theme.of(context).cardColor,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(_isDelivery ? 'Delivered to' : 'Collected from', style: const TextStyle(color: Colors.grey)),
                const SizedBox(height: 4),
                Text(_isDelivery ? 'Main Campus, Landing Pad A' : 'Main Campus Tuckshop', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: textColor)),
                const Divider(height: 24),
                const Text('Time', style: TextStyle(color: Colors.grey)),
                const SizedBox(height: 4),
                Text('10:07 AM, 11 Sep 2026', style: TextStyle(fontWeight: FontWeight.bold, color: textColor)),
              ],
            ),
          ),
        ),
        const SizedBox(height: 32),
        _buildYellowButton('Order Again (Reset)', Icons.refresh, () => _advanceStage(OrderStage.cart)),
      ],
    );
  }

  // --- Reusable Components ---
  Widget _buildOrderSummary() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : Colors.black;
    final subtleTextColor = isDark ? Colors.grey.shade400 : Colors.grey.shade600;
    
    String paymentText = 'Card';
    if (_selectedPaymentIndex == 1) paymentText = 'EFT';
    else if (_selectedPaymentIndex == 2) paymentText = 'Cash on Pickup';
    else if (_selectedPaymentIndex == 3) paymentText = 'Cash on Delivery';

    return Column(
      children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('Subtotal (3 items)', style: TextStyle(color: subtleTextColor)), Text('R158.00', style: TextStyle(color: textColor))]),
        const SizedBox(height: 8),
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('Service Fee', style: TextStyle(color: subtleTextColor)), Text('R5.00', style: TextStyle(color: textColor))]),
        if (_isDelivery) ...[
          const SizedBox(height: 8),
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('Delivery Fee', style: TextStyle(color: subtleTextColor)), Text('R15.00', style: TextStyle(color: textColor))]),
        ],
        const Divider(height: 24, thickness: 1),
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text('Total Paid', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: textColor)), 
          Text(_isDelivery ? 'R178.00' : 'R163.00', style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 18))
        ]),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Payment Method', style: TextStyle(color: subtleTextColor)),
            Text(paymentText, style: TextStyle(fontWeight: FontWeight.bold, color: textColor)),
          ],
        )
      ],
    );
  }

  Widget _buildYellowButton(String text, IconData icon, VoidCallback onPressed) {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: ElevatedButton.icon(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFFFFC107), 
          foregroundColor: Colors.black,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
        icon: Icon(icon),
        label: Text(text, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
      ),
    );
  }

  Widget _buildBottomNav() {
    return BottomNavigationBar(
      type: BottomNavigationBarType.fixed,
      backgroundColor: Theme.of(context).cardColor,
      selectedItemColor: const Color(0xFFFFC107),
      unselectedItemColor: Colors.grey.shade600,
      currentIndex: 2,
      items: const [
        BottomNavigationBarItem(icon: Icon(Icons.home_outlined), label: 'Home'),
        BottomNavigationBarItem(icon: Icon(Icons.map_outlined), label: 'Menu'),
        BottomNavigationBarItem(icon: Icon(Icons.shopping_bag), label: 'Orders'),
        BottomNavigationBarItem(icon: Icon(Icons.bookmark_outline), label: 'Saved'),
        BottomNavigationBarItem(icon: Icon(Icons.person_outline), label: 'Profile'),
      ],
    );
  }
}