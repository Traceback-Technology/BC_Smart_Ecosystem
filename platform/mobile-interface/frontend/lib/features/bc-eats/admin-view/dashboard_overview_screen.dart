import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../admin-view/constants/admin_colours.dart';

// =============================================================================
// DYNAMIC DATA MODELS (EXPRESS DATA STRUCTURES)
// =============================================================================

class SalesPoint {
  final String label;
  final double amount;

  SalesPoint({required this.label, required this.amount});

  factory SalesPoint.fromJson(Map<String, dynamic> json) {
    return SalesPoint(
      label: json['label']?.toString() ?? '',
      amount: (json['amount'] as num?)?.toDouble() ?? 0.0,
    );
  }
}

class CategoryShare {
  final String category;
  final double percentage;
  final Color color;

  CategoryShare({required this.category, required this.percentage, required this.color});

  factory CategoryShare.fromJson(Map<String, dynamic> json, Color color) {
    return CategoryShare(
      category: json['category']?.toString() ?? '',
      percentage: (json['percentage'] as num?)?.toDouble() ?? 0.0,
      color: color,
    );
  }
}

class IncomingOrder {
  final String id;
  final String orderNumber;
  final int itemCount;
  final String deliveryType;
  final String customerName;
  final String timeLabel;
  final String status;

  IncomingOrder({
    required this.id,
    required this.orderNumber,
    required this.itemCount,
    required this.deliveryType,
    required this.customerName,
    required this.timeLabel,
    required this.status,
  });

  factory IncomingOrder.fromJson(Map<String, dynamic> json) {
    return IncomingOrder(
      id: json['id']?.toString() ?? '',
      orderNumber: json['order_number'] ?? json['orderNumber'] ?? '',
      itemCount: (json['item_count'] ?? json['itemCount']) as int? ?? 0,
      deliveryType: json['delivery_type'] ?? json['deliveryType'] ?? 'Pickup',
      customerName: json['customer_name'] ?? json['customerName'] ?? '',
      timeLabel: json['time_label'] ?? json['timeLabel'] ?? '',
      status: json['status'] ?? 'New',
    );
  }
}

class PopularProduct {
  final String name;
  final int salesCount;
  final String category;

  PopularProduct({required this.name, required this.salesCount, required this.category});

  factory PopularProduct.fromJson(Map<String, dynamic> json) {
    return PopularProduct(
      name: json['name']?.toString() ?? '',
      salesCount: (json['sales_count'] ?? json['salesCount']) as int? ?? 0,
      category: json['category']?.toString() ?? 'All',
    );
  }
}

class CustomerReview {
  final String customerName;
  final int rating;
  final String comment;
  final String timeAgo;
  final String orderedItem;

  CustomerReview({
    required this.customerName,
    required this.rating,
    required this.comment,
    required this.timeAgo,
    required this.orderedItem,
  });

  factory CustomerReview.fromJson(Map<String, dynamic> json) {
    return CustomerReview(
      customerName: json['customer_name'] ?? json['customerName'] ?? '',
      rating: (json['rating'] as num?)?.toInt() ?? 5,
      comment: json['comment']?.toString() ?? '',
      timeAgo: json['time_ago'] ?? json['timeAgo'] ?? '',
      orderedItem: json['ordered_item'] ?? json['orderedItem'] ?? '',
    );
  }
}

// =============================================================================
// DASHBOARD OVERVIEW SCREEN
// =============================================================================

class DashboardOverviewScreen extends StatefulWidget {
  const DashboardOverviewScreen({super.key});

  @override
  State<DashboardOverviewScreen> createState() => _DashboardOverviewScreenState();
}

class _DashboardOverviewScreenState extends State<DashboardOverviewScreen> {
  bool _isLoading = true;
  String? _errorMessage;

  // Filter States
  String _selectedDateFilter = 'Today';
  String _selectedCategoryFilter = 'All';

  // Dynamic Vendor & Summary Metrics
  String _vendorName = '';
  int _totalOrders = 0;
  int _ordersDiff = 0;
  int _preparingCount = 0;
  int _onTheWayCount = 0;
  int _completedCount = 0;
  int _completedDiff = 0;

  double _totalSales = 0.0;
  double _salesGrowth = 0.0;
  double _avgOrderValue = 0.0;

  // Dynamic Datasets
  List<SalesPoint> _salesPoints = [];
  List<CategoryShare> _categoryShares = [];
  List<IncomingOrder> _incomingOrders = [];
  List<PopularProduct> _popularProducts = [];
  List<CustomerReview> _recentReviews = [];

  // Color Palette Assignment Map for Dynamic Category Painting
  final List<Color> _chartColors = const [
    Color(0xFFFFB800),
    Color(0xFFE53935),
    Color(0xFF4CAF50),
    Color(0xFF1E88E5),
    Color(0xFF9C27B0),
    Color(0xFFD3D3D3),
  ];

  @override
  void initState() {
    super.initState();
    _fetchDashboardOverview();
  }

  // ===========================================================================
  // EXPRESS ENDPOINT INTEGRATION POINT
  // ===========================================================================
  Future<void> _fetchDashboardOverview() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // TODO: Express HTTP GET Call:
      // final response = await http.get(
      //   Uri.parse('$kApiBaseUrl/api/v1/vendor/dashboard?range=${_selectedDateFilter.toLowerCase()}'),
      //   headers: {'Authorization': 'Bearer $authToken'},
      // );
      // final data = jsonDecode(response.body);

      await Future.delayed(const Duration(milliseconds: 300));
      final Map<String, dynamic> data = {};

      if (!mounted) return;

      setState(() {
        _vendorName = data['vendor_name'] ?? '';

        _totalOrders = (data['total_orders'] as num?)?.toInt() ?? 0;
        _ordersDiff = (data['orders_diff'] as num?)?.toInt() ?? 0;
        _preparingCount = (data['preparing_count'] as num?)?.toInt() ?? 0;
        _onTheWayCount = (data['on_the_way_count'] as num?)?.toInt() ?? 0;
        _completedCount = (data['completed_count'] as num?)?.toInt() ?? 0;
        _completedDiff = (data['completed_diff'] as num?)?.toInt() ?? 0;

        _totalSales = (data['total_sales'] as num?)?.toDouble() ?? 0.0;
        _salesGrowth = (data['sales_growth'] as num?)?.toDouble() ?? 0.0;
        _avgOrderValue = (data['avg_order_value'] as num?)?.toDouble() ?? 0.0;

        final List<dynamic> salesJson = data['sales_points'] ?? [];
        _salesPoints = salesJson.map((item) => SalesPoint.fromJson(item)).toList();

        final List<dynamic> categoriesJson = data['category_shares'] ?? [];
        _categoryShares = categoriesJson.asMap().entries.map((entry) {
          int idx = entry.key;
          return CategoryShare.fromJson(entry.value, _chartColors[idx % _chartColors.length]);
        }).toList();

        final List<dynamic> ordersJson = data['incoming_orders'] ?? [];
        _incomingOrders = ordersJson.map((item) => IncomingOrder.fromJson(item)).toList();

        final List<dynamic> productsJson = data['popular_products'] ?? [];
        _popularProducts = productsJson.map((item) => PopularProduct.fromJson(item)).toList();

        final List<dynamic> reviewsJson = data['recent_reviews'] ?? [];
        _recentReviews = reviewsJson.map((item) => CustomerReview.fromJson(item)).toList();
      });
    } catch (e) {
      if (mounted) {
        setState(() => _errorMessage = 'Failed to load dashboard data: $e');
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  List<String> get _availableCategories {
    final categories = <String>{'All'};
    for (var product in _popularProducts) {
      if (product.category.isNotEmpty) {
        categories.add(product.category);
      }
    }
    return categories.toList();
  }

  List<PopularProduct> get _filteredProducts {
    if (_selectedCategoryFilter == 'All') return _popularProducts;
    return _popularProducts.where((p) => p.category == _selectedCategoryFilter).toList();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final mutedText = isDark ? AdminColors.darkTextMuted : AdminColors.textGrey;
    final cardBg = Theme.of(context).cardColor;
    final borderColor = Theme.of(context).dividerColor;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isMobile = constraints.maxWidth < 900;

          return RefreshIndicator(
            onRefresh: _fetchDashboardOverview,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: EdgeInsets.all(isMobile ? 16.0 : 24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader(context, mutedText),
                  const SizedBox(height: 20),

                  if (_isLoading)
                    const Center(
                      child: Padding(
                        padding: EdgeInsets.all(60.0),
                        child: CircularProgressIndicator(),
                      ),
                    )
                  else if (_errorMessage != null)
                    _buildErrorView(mutedText)
                  else ...[
                    _buildTopMetricsRow(isMobile, cardBg, borderColor, mutedText),
                    const SizedBox(height: 20),
                    
                    if (isMobile)
                      Column(
                        children: [
                          _buildIncomingOrdersPanel(cardBg, borderColor, mutedText),
                          const SizedBox(height: 20),
                          _buildSalesOverviewChartPanel(cardBg, borderColor, mutedText),
                          const SizedBox(height: 20),
                          _buildPopularItemsPanel(cardBg, borderColor, mutedText),
                          const SizedBox(height: 20),
                          _buildTopCategoriesDonutPanel(cardBg, borderColor, mutedText),
                          const SizedBox(height: 20),
                          _buildRecentReviewsPanel(cardBg, borderColor, mutedText),
                          const SizedBox(height: 20),
                          _buildQuickActionsPanel(cardBg, borderColor, mutedText),
                        ],
                      )
                    else
                      Column(
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(flex: 5, child: _buildIncomingOrdersPanel(cardBg, borderColor, mutedText)),
                              const SizedBox(width: 20),
                              Expanded(flex: 5, child: _buildSalesOverviewChartPanel(cardBg, borderColor, mutedText)),
                            ],
                          ),
                          const SizedBox(height: 20),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(flex: 5, child: _buildPopularItemsPanel(cardBg, borderColor, mutedText)),
                              const SizedBox(width: 20),
                              Expanded(flex: 5, child: _buildTopCategoriesDonutPanel(cardBg, borderColor, mutedText)),
                            ],
                          ),
                          const SizedBox(height: 20),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(flex: 5, child: _buildRecentReviewsPanel(cardBg, borderColor, mutedText)),
                              const SizedBox(width: 20),
                              Expanded(flex: 5, child: _buildQuickActionsPanel(cardBg, borderColor, mutedText)),
                            ],
                          ),
                        ],
                      ),
                  ],
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // ===========================================================================
  // WIDGET COMPONENTS
  // ===========================================================================

  Widget _buildErrorView(Color mutedText) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 40.0),
        child: Column(
          children: [
            Icon(Icons.error_outline, size: 48, color: Theme.of(context).colorScheme.error),
            const SizedBox(height: 12),
            Text(_errorMessage ?? 'An error occurred', style: TextStyle(fontSize: 14, color: mutedText)),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: _fetchDashboardOverview,
              child: const Text('Retry'),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, Color mutedText) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Wrapped text column with Expanded to allow flexible width
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _vendorName.isNotEmpty ? 'Welcome back, $_vendorName!' : 'Welcome back!',
                  style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                "Here's what's happening with your store today.",
                style: TextStyle(fontSize: 12, color: mutedText),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
        const SizedBox(width: 12), // Space between text and dropdown
      
        // Date Filter Dropdown
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
          decoration: BoxDecoration(
            border: Border.all(color: Theme.of(context).dividerColor),
            borderRadius: BorderRadius.circular(8),
            color: Theme.of(context).cardColor,
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: _selectedDateFilter,
              icon: const Icon(Icons.calendar_today, size: 14),
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Theme.of(context).colorScheme.onSurface,
              ),
              onChanged: (String? newValue) {
                if (newValue != null && newValue != _selectedDateFilter) {
                  setState(() => _selectedDateFilter = newValue);
                  _fetchDashboardOverview();
                }
              },
              items: <String>['Today', 'This Week', 'This Month', 'This Year']
                  .map<DropdownMenuItem<String>>((String value) {
                return DropdownMenuItem<String>(
                  value: value,
                  child: Text(value),
                );
              }).toList(),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTopMetricsRow(bool isMobile, Color cardBg, Color borderColor, Color mutedText) {
    final cards = [
      _buildSummaryCard('Orders', '$_totalOrders', '${_ordersDiff >= 0 ? '+' : ''}$_ordersDiff vs yesterday', Icons.shopping_bag_outlined, const Color(0xFFFFF0F0), const Color(0xFFE53935), cardBg, borderColor, mutedText),
      _buildSummaryCard('Preparing', '$_preparingCount', 'Active kitchen items', Icons.soup_kitchen_outlined, const Color(0xFFFFFBEA), const Color(0xFFFFB800), cardBg, borderColor, mutedText),
      _buildSummaryCard('On the Way', '$_onTheWayCount', 'Out for delivery', Icons.directions_bike, const Color(0xFFE3F2FD), const Color(0xFF1E88E5), cardBg, borderColor, mutedText),
      _buildSummaryCard('Completed', '$_completedCount', '${_completedDiff >= 0 ? '+' : ''}$_completedDiff vs yesterday', Icons.check_circle_outline, const Color(0xFFE8F5E9), const Color(0xFF4CAF50), cardBg, borderColor, mutedText),
    ];

    if (isMobile) {
      return Column(children: cards.map((c) => Padding(padding: const EdgeInsets.only(bottom: 12), child: c)).toList());
    }

    return Row(
      children: cards.map((c) => Expanded(child: Padding(padding: EdgeInsets.only(right: c == cards.last ? 0 : 12), child: c))).toList(),
    );
  }

  Widget _buildSummaryCard(String title, String value, String subtitle, IconData icon, Color bg, Color iconColor, Color cardBg, Color borderColor, Color mutedText) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: cardBg, borderRadius: BorderRadius.circular(12), border: Border.all(color: borderColor)),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: TextStyle(fontSize: 12, color: mutedText)),
              const SizedBox(height: 6),
              Text(value, style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.onSurface)),
              const SizedBox(height: 4),
              Text(subtitle, style: TextStyle(fontSize: 10, color: iconColor, fontWeight: FontWeight.w500)),
            ],
          ),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(10)),
            child: Icon(icon, color: iconColor, size: 20),
          ),
        ],
      ),
    );
  }

  Widget _buildIncomingOrdersPanel(Color cardBg, Color borderColor, Color mutedText) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: cardBg, borderRadius: BorderRadius.circular(12), border: Border.all(color: borderColor)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Incoming Orders', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.onSurface)),
              TextButton(
                onPressed: () {},
                child: const Text('View all', style: TextStyle(fontSize: 12, color: AdminColors.primaryYellow)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (_incomingOrders.isEmpty)
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: Center(child: Text('No active incoming orders.', style: TextStyle(fontSize: 12, color: mutedText))),
            )
          else
            Column(
              children: _incomingOrders.map((order) {
                final isNew = order.status.toLowerCase() == 'new';
                final statusColor = isNew ? const Color(0xFFE53935) : const Color(0xFFFFB800);
                final statusBg = isNew ? const Color(0xFFFFF0F0) : const Color(0xFFFFFBEA);

                return Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    border: Border(left: BorderSide(color: statusColor, width: 4)),
                    color: Theme.of(context).scaffoldBackgroundColor,
                    borderRadius: const BorderRadius.horizontal(right: Radius.circular(8)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('${order.orderNumber} • ${order.itemCount} items • ${order.deliveryType}', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.onSurface)),
                          const SizedBox(height: 4),
                          Text(order.customerName, style: TextStyle(fontSize: 11, color: mutedText)),
                        ],
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(order.timeLabel, style: TextStyle(fontSize: 10, color: mutedText)),
                          const SizedBox(height: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(color: statusBg, borderRadius: BorderRadius.circular(4)),
                            child: Text(order.status, style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: statusColor)),
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

  // ===========================================================================
  // FL_CHART: SALES OVERVIEW LINE CHART
  // ===========================================================================
  Widget _buildSalesOverviewChartPanel(Color cardBg, Color borderColor, Color mutedText) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: cardBg, borderRadius: BorderRadius.circular(12), border: Border.all(color: borderColor)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Sales Overview', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.onSurface)),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(color: AdminColors.softYellow, borderRadius: BorderRadius.circular(4)),
                child: Text(_selectedDateFilter, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AdminColors.textDark)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text('R${_totalSales.toStringAsFixed(2)}', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AdminColors.successGreen)),
          Text('${_salesGrowth >= 0 ? '+' : ''}${_salesGrowth.toStringAsFixed(1)}% vs previous period', style: TextStyle(fontSize: 11, color: AppColors.successGreen, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          
          if (_salesPoints.isEmpty)
            Container(
              height: 140,
              alignment: Alignment.center,
              child: Text('No chart data for selected range.', style: TextStyle(fontSize: 12, color: mutedText)),
            )
          else
            SizedBox(
              height: 140,
              child: LineChart(
                LineChartData(
                  gridData: const FlGridData(show: false),
                  titlesData: const FlTitlesData(show: false),
                  borderData: FlBorderData(show: false),
                  lineBarsData: [
                    LineChartBarData(
                      spots: _salesPoints.asMap().entries.map((entry) {
                        return FlSpot(entry.key.toDouble(), entry.value.amount);
                      }).toList(),
                      isCurved: true,
                      color: AdminColors.primaryYellow,
                      barWidth: 3,
                      isStrokeCapRound: true,
                      dotData: const FlDotData(show: false),
                      belowBarData: BarAreaData(
                        show: true,
                        color: AdminColors.primaryYellow.withOpacity(0.15),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildMiniMetric('Average Order Value', 'R${_avgOrderValue.toStringAsFixed(2)}', mutedText),
              _buildMiniMetric('Total Orders', '$_totalOrders', mutedText),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMiniMetric(String label, String val, Color mutedText) {
    return Column(
      children: [
        Text(label, style: TextStyle(fontSize: 11, color: mutedText)),
        const SizedBox(height: 4),
        Text(val, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.onSurface)),
      ],
    );
  }

  Widget _buildPopularItemsPanel(Color cardBg, Color borderColor, Color mutedText) {
    final products = _filteredProducts;
    final categories = _availableCategories;
    final safeCategoryValue = categories.contains(_selectedCategoryFilter) ? _selectedCategoryFilter : 'All';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: cardBg, borderRadius: BorderRadius.circular(12), border: Border.all(color: borderColor)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Popular Items', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.onSurface)),
              DropdownButton<String>(
                value: safeCategoryValue,
                style: const TextStyle(fontSize: 11, color: AdminColors.primaryYellow, fontWeight: FontWeight.bold),
                underline: const SizedBox(),
                onChanged: (String? cat) {
                  if (cat != null) setState(() => _selectedCategoryFilter = cat);
                },
                items: categories.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (products.isEmpty)
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: Center(child: Text('No popular items found for this category.', style: TextStyle(fontSize: 12, color: mutedText))),
            )
          else
            Column(
              children: products.map((p) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(color: Theme.of(context).scaffoldBackgroundColor, borderRadius: BorderRadius.circular(6)),
                          child: const Icon(Icons.fastfood, size: 16, color: AdminColors.primaryYellow),
                        ),
                        const SizedBox(width: 12),
                        Text(p.name, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Theme.of(context).colorScheme.onSurface)),
                      ],
                    ),
                    Text('${p.salesCount} sold', style: TextStyle(fontSize: 12, color: mutedText, fontWeight: FontWeight.bold)),
                  ],
                ),
              )).toList(),
            )
        ],
      ),
    );
  }

  // ===========================================================================
  // FL_CHART: TOP CATEGORIES DONUT CHART
  // ===========================================================================
  Widget _buildTopCategoriesDonutPanel(Color cardBg, Color borderColor, Color mutedText) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: cardBg, borderRadius: BorderRadius.circular(12), border: Border.all(color: borderColor)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Top Categories', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.onSurface)),
          const SizedBox(height: 16),
          if (_categoryShares.isEmpty)
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: Center(child: Text('No category sales recorded.', style: TextStyle(fontSize: 12, color: mutedText))),
            )
          else
            Row(
              children: [
                SizedBox(
                  width: 120,
                  height: 120,
                  child: PieChart(
                    PieChartData(
                      startDegreeOffset: 270, // 270 degrees rotates start to 12 o'clock
                      sectionsSpace: 2,
                      centerSpaceRadius: 36, // Inner hole forming the donut
                      sections: _categoryShares.map((cat) {
                        return PieChartSectionData(
                          color: cat.color,
                          value: cat.percentage,
                          showTitle: false,
                          radius: 16,
                        );
                      }).toList(),
                    ),
                  ),
                ),
                const SizedBox(width: 24),
                Expanded(
                  child: Column(
                    children: _categoryShares.map((cat) => Padding(
                      padding: const EdgeInsets.only(bottom: 6.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Container(width: 10, height: 10, decoration: BoxDecoration(color: cat.color, shape: BoxShape.circle)),
                              const SizedBox(width: 8),
                              Text(cat.category, style: TextStyle(fontSize: 11, color: Theme.of(context).colorScheme.onSurface)),
                            ],
                          ),
                          Text('${cat.percentage.toInt()}%', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: mutedText)),
                        ],
                      ),
                    )).toList(),
                  ),
                )
              ],
            ),
          Divider(height: 24, color: borderColor),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Total Revenue', style: TextStyle(fontSize: 12, color: mutedText)),
              Text('R${_totalSales.toStringAsFixed(2)}', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AdminColors.successGreen)),
            ],
          )
        ],
      ),
    );
  }

  Widget _buildRecentReviewsPanel(Color cardBg, Color borderColor, Color mutedText) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: cardBg, borderRadius: BorderRadius.circular(12), border: Border.all(color: borderColor)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Recent Reviews', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.onSurface)),
          const SizedBox(height: 8),
          if (_recentReviews.isEmpty)
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: Center(child: Text('No customer reviews yet.', style: TextStyle(fontSize: 12, color: mutedText))),
            )
          else
            Column(
              children: _recentReviews.map((rev) => Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(color: Theme.of(context).scaffoldBackgroundColor, borderRadius: BorderRadius.circular(8)),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(rev.customerName, style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.onSurface)),
                        Text(rev.timeAgo, style: TextStyle(fontSize: 10, color: mutedText)),
                      ],
                    ),
                    Row(children: List.generate(rev.rating, (i) => const Icon(Icons.star, size: 12, color: Color(0xFFFFB800)))),
                    const SizedBox(height: 4),
                    Text(rev.comment, style: TextStyle(fontSize: 11, color: mutedText)),
                  ],
                ),
              )).toList(),
            ),
        ],
      ),
    );
  }

  Widget _buildQuickActionsPanel(Color cardBg, Color borderColor, Color mutedText) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: cardBg, borderRadius: BorderRadius.circular(12), border: Border.all(color: borderColor)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Quick Actions', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.onSurface)),
          const SizedBox(height: 12),
          _buildActionButton('Add New Product', Icons.add, AdminColors.primaryYellow, Colors.black, () {}),
          _buildActionButton('Create Promotion', Icons.local_offer_outlined, const Color(0xFFE53935), Colors.white, () {}),
          _buildActionButton('View Payouts', Icons.account_balance_wallet_outlined, const Color(0xFF4CAF50), Colors.white, () {}),
          _buildActionButton('Store Settings', Icons.settings_outlined, const Color(0xFF1E88E5), Colors.white, () {}),
        ],
      ),
    );
  }

  Widget _buildActionButton(String label, IconData icon, Color bg, Color iconColor, VoidCallback onTap) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: ElevatedButton.icon(
        style: ElevatedButton.styleFrom(
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          elevation: 0,
          alignment: Alignment.centerLeft,
          side: BorderSide(color: Theme.of(context).dividerColor),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        ),
        onPressed: onTap,
        icon: Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(4)),
          child: Icon(icon, size: 14, color: iconColor),
        ),
        label: Text(label, style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.onSurface, fontWeight: FontWeight.w600)),
      ),
    );
  }
}