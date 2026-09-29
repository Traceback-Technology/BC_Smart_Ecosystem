import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'constants/admin_colours.dart';
import 'inventory_screen.dart'; // Uses shared ProductItem model

class LiveOrdersScreen extends StatefulWidget {
  const LiveOrdersScreen({super.key});

  @override
  State<LiveOrdersScreen> createState() => _LiveOrdersScreenState();
}

class _LiveOrdersScreenState extends State<LiveOrdersScreen> {
  bool _hasNewOrderAlert = false;

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
    ProductItem(id: '1', name: 'French Fries (Large)', category: 'Quick Picks', price: 28.00, inStock: true, stockCount: 15, threshold: 5),
    ProductItem(id: '2', name: 'Ice Tea (Lemon)', category: 'Drinks', price: 22.00, inStock: true, stockCount: 3, threshold: 5),
    ProductItem(id: '3', name: 'Cheese & Tomato Toastie', category: 'Toasties', price: 32.00, inStock: true, stockCount: 1, threshold: 3),
    ProductItem(id: '4', name: 'Beef Burger Meal', category: 'Combos', price: 65.00, inStock: false, stockCount: 0, threshold: 5),
  ];

  @override
  void initState() {
    super.initState();
    _subscribeToLiveOrdersAndStock();
  }

  // BACKEND INTEGRATION POINT: Subscribe to Realtime DB updates
  void _subscribeToLiveOrdersAndStock() {
    // TODO: Attach Supabase Realtime channel / WebSocket stream listeners here:
    // supabase.channel('orders').onPostgresChanges(event: PostgresChangeEvent.all, schema: 'public', table: 'orders', callback: (payload) { ... });
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
    // await supabase.from('orders').insert({ ... });

    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) setState(() => _hasNewOrderAlert = false);
    });
  }

  // BACKEND INTEGRATION POINT: Updating Order Progress Status
  Future<void> _advanceOrderStatus(int index) async {
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
    // await supabase.from('orders').update({'status': nextStatus}).eq('orderId', orderId);

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
    // await supabase.from('products').update({'inStock': newValue}).eq('id', product.id);

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
    final int prepCount = orders.where((o) => o['status'] == 'Preparing').length;
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
                      _buildMetricCard('New Orders', '$newCount orders', 'Requires prep', Icons.receipt_long, AdminColors.softRed, AdminColors.alertRed, cardBg, borderColor, mutedText),
                      const SizedBox(height: 12),
                      _buildMetricCard('In Prep', '$prepCount orders', 'Cooking/Packing', Icons.soup_kitchen, AdminColors.softYellow, AdminColors.primaryYellow, cardBg, borderColor, mutedText),
                      const SizedBox(height: 12),
                      _buildMetricCard('Ready', '$readyCount orders', 'At counter', Icons.outbox, AdminColors.softGreen, AdminColors.successGreen, cardBg, borderColor, mutedText),
                    ],
                  )
                else
                  Row(
                    children: [
                      Expanded(child: _buildMetricCard('New Orders', '$newCount orders', 'Requires prep', Icons.receipt_long, AdminColors.softRed, AdminColors.alertRed, cardBg, borderColor, mutedText)),
                      const SizedBox(width: 16),
                      Expanded(child: _buildMetricCard('In Prep', '$prepCount orders', 'Cooking/Packing', Icons.soup_kitchen, AdminColors.softYellow, AdminColors.primaryYellow, cardBg, borderColor, mutedText)),
                      const SizedBox(width: 16),
                      Expanded(child: _buildMetricCard('Ready', '$readyCount orders', 'At counter', Icons.outbox, AdminColors.softGreen, AdminColors.successGreen, cardBg, borderColor, mutedText)),
                    ],
                  ),
                const SizedBox(height: 24),
                // Main Panels
                if (isMobile)
                  Column(
                    children: [
                      _buildLiveOrdersPanel(cardBg, borderColor, mutedText),
                      const SizedBox(height: 20),
                      _buildStockManagementPanel(cardBg, borderColor, mutedText),
                    ],
                  )
                else
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(flex: 5, child: _buildLiveOrdersPanel(cardBg, borderColor, mutedText)),
                      const SizedBox(width: 24),
                      Expanded(flex: 4, child: _buildStockManagementPanel(cardBg, borderColor, mutedText)),
                    ],
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildMetricCard(String title, String value, String subtitle, IconData icon, Color bgColor, Color iconColor, Color cardBg, Color borderColor, Color mutedText) {
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
                Text(title, style: TextStyle(fontSize: 12, color: mutedText), overflow: TextOverflow.ellipsis),
                const SizedBox(height: 8),
                Text(value, style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.onSurface), overflow: TextOverflow.ellipsis),
                const SizedBox(height: 4),
                Text(subtitle, style: TextStyle(fontSize: 10, color: iconColor, fontWeight: FontWeight.w500), overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: bgColor, borderRadius: BorderRadius.circular(8)),
            child: Icon(icon, color: iconColor, size: 20),
          )
        ],
      ),
    );
  }

  Widget _buildLiveOrdersPanel(Color cardBg, Color borderColor, Color mutedText) {
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
              Text('Live Order Queue', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.onSurface)),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AdminColors.primaryYellow,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                ),
                onPressed: _simulateIncomingOrder,
                icon: const Icon(Icons.add_alert, size: 14, color: AdminColors.textDark),
                label: const Text('Simulate Order', style: TextStyle(fontSize: 11, color: AdminColors.textDark, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (orders.isEmpty)
            Padding(
              padding: const EdgeInsets.all(32.0),
              child: Center(child: Text('No active orders right now', style: TextStyle(color: mutedText, fontSize: 12))),
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
                          Text('${order['orderId']} • ${order['customer']}', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Theme.of(context).colorScheme.onSurface)),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(color: statusBg, borderRadius: BorderRadius.circular(4)),
                            child: Text(order['status'], style: TextStyle(color: statusColor, fontSize: 10, fontWeight: FontWeight.bold)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text((order['items'] as List<String>).join(', '), style: TextStyle(fontSize: 12, color: mutedText)),
                      const SizedBox(height: 10),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('R ${order['total'].toStringAsFixed(2)}', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Theme.of(context).colorScheme.onSurface)),
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
                              style: const TextStyle(fontSize: 11, color: Colors.white, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                      )
                    ],
                  ),
                );
              }).toList(),
            ),
        ],
      ),
    );
  }

  Widget _buildStockManagementPanel(Color cardBg, Color borderColor, Color mutedText) {
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
              Text('Live Stock Status', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.onSurface)),
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
                              color: !item.inStock ? mutedText : Theme.of(context).colorScheme.onSurface,
                            ),
                          ),
                          Text('R ${item.price.toStringAsFixed(2)}', style: TextStyle(fontSize: 11, color: mutedText)),
                        ],
                      ),
                    ),
                    Switch(
                      value: item.inStock,
                      activeColor: AdminColors.successGreen,
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