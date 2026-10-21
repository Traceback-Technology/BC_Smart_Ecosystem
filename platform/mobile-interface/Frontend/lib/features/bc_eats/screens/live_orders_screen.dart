import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/bc_api_client.dart';
import '../admin-view/constants/admin_colours.dart';
import 'inventory_screen.dart'; // Uses shared ProductItem model

/// Displays real-time incoming orders with status filtering (Pending, Preparing, Completed)
/// and allows store managers to update order fulfillment states

class LiveOrdersScreen extends StatefulWidget {
  const LiveOrdersScreen({super.key});

  @override
  State<LiveOrdersScreen> createState() => _LiveOrdersScreenState();
}

class _LiveOrdersScreenState extends State<LiveOrdersScreen> {
  bool _hasNewOrderAlert = false;

  // Live mode = signed in with the backend. Otherwise the hardcoded demo
  // orders below are shown (offline preview).
  bool get _live => BcApiClient.instance.hasToken;
  Timer? _poll;
  bool _loading = false;
  bool _loadedOnce = false;
  final Set<String> _seenIds = {};

  //TODO: Hardcoded lists: to remove
  List<Map<String, dynamic>> orders = [
    {
      'orderId': '#BCE12601',
      'customer': 'Sipho Dlamini',
      'time': '2 mins ago',
      'items': ['1x Beef Burger Meal', '1x Energy Drink'],
      'total': 90.00,
      'status': 'New',
    },
    {
      'orderId': '#BCE12602',
      'customer': 'Thabo M.',
      'time': '7 mins ago',
      'items': ['2x Cheese & Tomato Toastie', '1x Coffee'],
      'total': 82.00,
      'status': 'Preparing',
    },
    {
      'orderId': '#BCE12603',
      'customer': 'Anika K.',
      'time': '12 mins ago',
      'items': ['1x Study Combo'],
      'total': 70.00,
      'status': 'Ready',
    },
  ];

  List<ProductItem> foodItems = [
    ProductItem(
      id: '1',
      name: 'French Fries (Large)',
      category: 'Quick Picks',
      price: 28.00,
      inStock: true,
      stockCount: 15,
      threshold: 5,
    ),
    ProductItem(
      id: '2',
      name: 'Ice Tea (Lemon)',
      category: 'Drinks',
      price: 22.00,
      inStock: true,
      stockCount: 3,
      threshold: 5,
    ),
    ProductItem(
      id: '3',
      name: 'Cheese & Tomato Toastie',
      category: 'Toasties',
      price: 32.00,
      inStock: true,
      stockCount: 1,
      threshold: 3,
    ),
    ProductItem(
      id: '4',
      name: 'Beef Burger Meal',
      category: 'Combos',
      price: 65.00,
      inStock: false,
      stockCount: 0,
      threshold: 5,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _subscribeToLiveOrdersAndStock();
  }

  // BACKEND INTEGRATION POINT: Subscribe to Realtime DB updates
  void _subscribeToLiveOrdersAndStock() {
    if (!_live) return;
    orders = [];
    _loadOrders();
    // Polling is enough for the MVP. TODO: swap for a WebSocket push later.
    _poll = Timer.periodic(const Duration(seconds: 10), (_) => _loadOrders(silent: true));
  }

  @override
  void dispose() {
    _poll?.cancel();
    super.dispose();
  }

  Future<void> _loadOrders({bool silent = false, bool force = false}) async {
    if (!_live || (_loading && !force)) return;
    _loading = true;
    try {
      final response = await BcApiClient.instance.getJson('/api/orders/staff');
      final rows = response['data'];
      if (rows is! List || !mounted) return;
      final mapped = rows.whereType<Map>().map((raw) => _fromServer(Map<String, dynamic>.from(raw))).toList();
      final hasNew = _loadedOnce && mapped.any((order) => !_seenIds.contains(order['_id']));
      _seenIds.addAll(mapped.map((order) => order['_id'] as String));
      _loadedOnce = true;
      setState(() => orders = mapped);
      if (hasNew) _alertNewOrder();
    } catch (error) {
      if (mounted && !silent) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Could not load orders: $error')));
      }
    } finally {
      _loading = false;
    }
  }

  void _alertNewOrder() {
    SystemSound.play(SystemSoundType.click);
    HapticFeedback.mediumImpact();
    setState(() => _hasNewOrderAlert = true);
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) setState(() => _hasNewOrderAlert = false);
    });
  }

  /// Maps a backend order onto the map shape the queue UI already renders.
  Map<String, dynamic> _fromServer(Map<String, dynamic> row) {
    final user = row['userId'] is Map ? Map<String, dynamic>.from(row['userId'] as Map) : <String, dynamic>{};
    final contact = row['contact'] is Map ? Map<String, dynamic>.from(row['contact'] as Map) : <String, dynamic>{};
    final name = [contact['name'], user['fullName'], user['name']]
        .map((value) => (value ?? '').toString().trim())
        .firstWhere((value) => value.isNotEmpty, orElse: () => 'Student');
    final items = (row['items'] is List ? row['items'] as List : const [])
        .whereType<Map>()
        .map((item) => '${item['quantity'] ?? 1}x ${item['name'] ?? 'Item'}')
        .toList();
    final serverStatus = (row['status'] ?? '').toString();
    return {
      '_id': (row['_id'] ?? '').toString(),
      'orderId': '#${row['orderNumber'] ?? row['_id']}',
      'customer': name,
      'time': _ago(DateTime.tryParse((row['createdAt'] ?? '').toString())),
      'items': items,
      'total': (row['total'] as num? ?? 0).toDouble(),
      'status': switch (serverStatus) { 'preparing' => 'Preparing', 'ready' => 'Ready', _ => 'New' },
      'serverStatus': serverStatus,
      'deliveryType': (row['deliveryType'] ?? 'pickup').toString(),
    };
  }

  String _ago(DateTime? time) {
    if (time == null) return '';
    final diff = DateTime.now().difference(time);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes} mins ago';
    if (diff.inHours < 24) return '${diff.inHours} hrs ago';
    return '${diff.inDays} days ago';
  }

  Future<void> _advanceServerOrder(int index) async {
    final order = orders[index];
    final next = switch (order['serverStatus']) {
      'confirmed' => 'preparing',
      'preparing' => 'ready',
      // Counter hand-over: pickup orders finish here; drone orders go to
      // dispatch. STEP 3 replaces this with real drone assignment.
      'ready' => order['deliveryType'] == 'drone' ? 'drone_assigned' : 'delivered',
      _ => null,
    };
    if (next == null) return;
    try {
      await BcApiClient.instance.patchJson('/api/orders/${order['_id']}/status', {'status': next});
      await _loadOrders(silent: true, force: true);
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Could not update order: $error')));
      }
    }
  }

  // BACKEND INTEGRATION POINT: Order Simulation / Creating New Orders
  void _simulateIncomingOrder() {
    SystemSound.play(SystemSoundType.click);
    HapticFeedback.mediumImpact();

    setState(() {
      _hasNewOrderAlert = true;
      orders.insert(0, {
        'orderId': '#BCE${12604 + orders.length}',
        'customer': 'Student #${orders.length + 1}',
        'time': 'Just now',
        'items': ['1x French Fries (Large)', '1x Ice Tea (Lemon)'],
        'total': 50.00,
        'status': 'New',
      });
    });

    // TODO: Send order creation request to backend if required:

    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) setState(() => _hasNewOrderAlert = false);
    });
  }

  // BACKEND INTEGRATION POINT: Updating Order Progress Status
  Future<void> _advanceOrderStatus(int index) async {
    if (_live) return _advanceServerOrder(index);
    final orderId = orders[index]['orderId'];
    final currentStatus = orders[index]['status'];
    String nextStatus = currentStatus;

    if (currentStatus == 'New') {
      nextStatus = 'Preparing';
    } else if (currentStatus == 'Preparing') {
      nextStatus = 'Ready';
    } else if (currentStatus == 'Ready') {
      nextStatus = 'Completed';
    }

    // TODO: Update status in database table:

    setState(() {
      if (nextStatus == 'Completed') {
        orders.removeAt(index);
      } else {
        orders[index]['status'] = nextStatus;
      }
    });
  }

  // BACKEND INTEGRATION POINT: Live Stock Toggle Sync
  Future<void> _toggleStockFromLiveQueue(int index, bool newValue) async {
    final product = foodItems[index];

    // TODO: Sync toggle directly to backend inventory table:

    setState(() {
      foodItems[index] = product.copyWith(inStock: newValue);
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final mutedText = isDark ? AdminColors.darkTextMuted : AdminColors.textGrey;
    final cardBg = Theme.of(context).cardColor;
    final borderColor = Theme.of(context).dividerColor;

    final int newCount = orders.where((o) => o['status'] == 'New').length;
    final int prepCount = orders
        .where((o) => o['status'] == 'Preparing')
        .length;
    final int readyCount = orders.where((o) => o['status'] == 'Ready').length;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isMobile = constraints.maxWidth < 768;

          return SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: EdgeInsets.all(isMobile ? 16.0 : 24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Metric cards row / column
                if (isMobile)
                  Column(
                    children: [
                      _buildMetricCard(
                        'New Orders',
                        '$newCount orders',
                        'Requires prep',
                        Icons.receipt_long,
                        AdminColors.softRed,
                        AdminColors.alertRed,
                        cardBg,
                        borderColor,
                        mutedText,
                      ),
                      const SizedBox(height: 12),
                      _buildMetricCard(
                        'In Prep',
                        '$prepCount orders',
                        'Cooking/Packing',
                        Icons.soup_kitchen,
                        AdminColors.softYellow,
                        AdminColors.primaryYellow,
                        cardBg,
                        borderColor,
                        mutedText,
                      ),
                      const SizedBox(height: 12),
                      _buildMetricCard(
                        'Ready',
                        '$readyCount orders',
                        'At counter',
                        Icons.outbox,
                        AdminColors.softGreen,
                        AdminColors.successGreen,
                        cardBg,
                        borderColor,
                        mutedText,
                      ),
                    ],
                  )
                else
                  Row(
                    children: [
                      Expanded(
                        child: _buildMetricCard(
                          'New Orders',
                          '$newCount orders',
                          'Requires prep',
                          Icons.receipt_long,
                          AdminColors.softRed,
                          AdminColors.alertRed,
                          cardBg,
                          borderColor,
                          mutedText,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _buildMetricCard(
                          'In Prep',
                          '$prepCount orders',
                          'Cooking/Packing',
                          Icons.soup_kitchen,
                          AdminColors.softYellow,
                          AdminColors.primaryYellow,
                          cardBg,
                          borderColor,
                          mutedText,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _buildMetricCard(
                          'Ready',
                          '$readyCount orders',
                          'At counter',
                          Icons.outbox,
                          AdminColors.softGreen,
                          AdminColors.successGreen,
                          cardBg,
                          borderColor,
                          mutedText,
                        ),
                      ),
                    ],
                  ),
                const SizedBox(height: 24),
                // Main Panels
                if (isMobile)
                  Column(
                    children: [
                      _buildLiveOrdersPanel(cardBg, borderColor, mutedText),
                      const SizedBox(height: 20),
                      _buildStockManagementPanel(
                        cardBg,
                        borderColor,
                        mutedText,
                      ),
                    ],
                  )
                else
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        flex: 5,
                        child: _buildLiveOrdersPanel(
                          cardBg,
                          borderColor,
                          mutedText,
                        ),
                      ),
                      const SizedBox(width: 24),
                      Expanded(
                        flex: 4,
                        child: _buildStockManagementPanel(
                          cardBg,
                          borderColor,
                          mutedText,
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildMetricCard(
    String title,
    String value,
    String subtitle,
    IconData icon,
    Color bgColor,
    Color iconColor,
    Color cardBg,
    Color borderColor,
    Color mutedText,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(fontSize: 12, color: mutedText),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 10,
                    color: iconColor,
                    fontWeight: FontWeight.w500,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: iconColor, size: 20),
          ),
        ],
      ),
    );
  }

  Widget _buildLiveOrdersPanel(
    Color cardBg,
    Color borderColor,
    Color mutedText,
  ) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _hasNewOrderAlert ? AdminColors.alertRed : borderColor,
          width: _hasNewOrderAlert ? 2 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Live Order Queue',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AdminColors.primaryYellow,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                ),
                onPressed: _live ? () => _loadOrders(force: true) : _simulateIncomingOrder,
                icon: Icon(
                  _live ? Icons.refresh : Icons.add_alert,
                  size: 14,
                  color: AdminColors.textDark,
                ),
                label: Text(
                  _live ? 'Refresh' : 'Simulate Order',
                  style: const TextStyle(
                    fontSize: 11,
                    color: AdminColors.textDark,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (orders.isEmpty)
            Padding(
              padding: const EdgeInsets.all(32.0),
              child: Center(
                child: Text(
                  'No active orders right now',
                  style: TextStyle(color: mutedText, fontSize: 12),
                ),
              ),
            )
          else
            Column(
              children: orders.asMap().entries.map((entry) {
                final index = entry.key;
                final order = entry.value;

                Color statusColor = AdminColors.alertRed;
                Color statusBg = AdminColors.softRed;

                if (order['status'] == 'Preparing') {
                  statusColor = AdminColors.statusBlue;
                  statusBg = AdminColors.softBlue;
                } else if (order['status'] == 'Ready') {
                  statusColor = AdminColors.successGreen;
                  statusBg = AdminColors.softGreen;
                }

                return Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    border: Border.all(color: borderColor),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            '${order['orderId']} • ${order['customer']}',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                              color: Theme.of(context).colorScheme.onSurface,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: statusBg,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              order['status'],
                              style: TextStyle(
                                color: statusColor,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        (order['items'] as List<String>).join(', '),
                        style: TextStyle(fontSize: 12, color: mutedText),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'R ${order['total'].toStringAsFixed(2)}',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                              color: Theme.of(context).colorScheme.onSurface,
                            ),
                          ),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: statusColor,
                              elevation: 0,
                            ),
                            onPressed: () => _advanceOrderStatus(index),
                            child: Text(
                              order['status'] == 'New'
                                  ? 'Start Preparing'
                                  : order['status'] == 'Preparing'
                                  ? 'Mark Ready'
                                  : 'Complete Order',
                              style: const TextStyle(
                                fontSize: 11,
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
        ],
      ),
    );
  }

  Widget _buildStockManagementPanel(
    Color cardBg,
    Color borderColor,
    Color mutedText,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Live Stock Status',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
              Icon(Icons.inventory_2_outlined, size: 18, color: mutedText),
            ],
          ),
          Divider(height: 24, color: borderColor),
          Column(
            children: foodItems.asMap().entries.map((entry) {
              final index = entry.key;
              final item = entry.value;

              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.name,
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 12,
                              color: !item.inStock
                                  ? mutedText
                                  : Theme.of(context).colorScheme.onSurface,
                            ),
                          ),
                          Text(
                            'R ${item.price.toStringAsFixed(2)}',
                            style: TextStyle(fontSize: 11, color: mutedText),
                          ),
                        ],
                      ),
                    ),
                    Switch(
                      value: item.inStock,
                      activeThumbColor: AdminColors.successGreen,
                      onChanged: (val) => _toggleStockFromLiveQueue(index, val),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}
