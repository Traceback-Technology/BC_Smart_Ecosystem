import 'package:flutter/material.dart';

import '../constants/bc_eats_colors.dart';
import '../models/bc_eats_product.dart';
import '../repositories/bc_eats_product_repository.dart';
import '../repositories/mock_bc_eats_product_repository.dart';

class BCEatsHomeScreen extends StatefulWidget {
  final bool showBottomNavigation;
  final BcEatsProductRepository? productRepository;

  const BCEatsHomeScreen({
    super.key,
    this.showBottomNavigation = true,
    this.productRepository,
  });

  @override
  State<BCEatsHomeScreen> createState() => _BCEatsHomeScreenState();
}

class _BCEatsHomeScreenState extends State<BCEatsHomeScreen> {
  final List<BcEatsProduct> _products = [];

  bool _isLoading = true;
  String? _loadError;

  BcEatsProductRepository get _productRepository =>
      widget.productRepository ?? MockBcEatsProductRepository.instance;

  static const List<String> _preferredCategoryOrder = [
    'Daily Specials',
    'Sandwiches',
    'Burgers',
    'Hot Dogs',
    'Chips',
    'Drinks',
    'Extras',
  ];

  @override
  void initState() {
    super.initState();
    _loadProducts();
  }

  Future<void> _loadProducts() async {
    if (mounted) {
      setState(() {
        _isLoading = true;
        _loadError = null;
      });
    }

    try {
      final products = await _productRepository.fetchProducts();

      if (!mounted) {
        return;
      }

      setState(() {
        _products
          ..clear()
          ..addAll(products);

        _isLoading = false;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _isLoading = false;
        _loadError = 'Unable to load BC Eats products. Please try again.';
      });
    }
  }

  List<String> get _orderedCategories {
    final categories = <String>[];

    for (final category in _preferredCategoryOrder) {
      if (_products.any((product) => product.category == category)) {
        categories.add(category);
      }
    }

    for (final product in _products) {
      if (!categories.contains(product.category)) {
        categories.add(product.category);
      }
    }

    return categories;
  }

  List<BcEatsProduct> _productsForCategory(String category) {
    return _products.where((product) => product.category == category).toList();
  }

  String _sectionTitle(String category) {
    if (category == 'Daily Specials') {
      return "Today's Specials";
    }

    return category;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: _buildHeader(context),
      body: RefreshIndicator(
        onRefresh: _loadProducts,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: [
            _buildTuckShopStatus(context),
            const SizedBox(height: 24),
            _buildProductContent(context),
            _buildTuckShopHours(context),
            const SizedBox(height: 20),
          ],
        ),
      ),
      bottomNavigationBar: widget.showBottomNavigation
          ? _buildLegacyBottomNavigationBar(context)
          : null,
    );
  }

  Widget _buildProductContent(BuildContext context) {
    if (_isLoading) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 80),
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (_loadError != null) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(24, 50, 24, 70),
        child: Column(
          children: [
            Icon(
              Icons.error_outline,
              size: 42,
              color: Theme.of(context).colorScheme.error,
            ),
            const SizedBox(height: 12),
            Text(
              _loadError!,
              textAlign: TextAlign.center,
              style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
            ),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: _loadProducts,
              icon: const Icon(Icons.refresh),
              label: const Text('Try again'),
            ),
          ],
        ),
      );
    }

    if (_products.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 70),
        child: Center(
          child: Column(
            children: [
              Icon(
                Icons.restaurant_menu_outlined,
                size: 48,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
              const SizedBox(height: 12),
              Text(
                'No products are available right now.',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      children: [
        for (final category in _orderedCategories)
          _buildSection(
            context,
            title: _sectionTitle(category),
            items: _productsForCategory(category),
          ),
      ],
    );
  }

  PreferredSizeWidget _buildHeader(BuildContext context) {
    final theme = Theme.of(context);

    return AppBar(
      backgroundColor: theme.appBarTheme.backgroundColor,
      elevation: 0,
      surfaceTintColor: theme.appBarTheme.backgroundColor,
      automaticallyImplyLeading: false,
      toolbarHeight: 88,
      titleSpacing: 20,
      title: Row(
        children: [
          Image.asset(
            'assets/images/bc_icon.jpg',
            width: 58,
            height: 58,
            fit: BoxFit.contain,
            errorBuilder: (context, error, stackTrace) {
              return const Icon(Icons.restaurant, size: 42);
            },
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text.rich(
                  TextSpan(
                    style: const TextStyle(
                      fontSize: 27,
                      fontWeight: FontWeight.bold,
                    ),
                    children: [
                      const TextSpan(
                        text: 'BC ',
                        style: TextStyle(color: BcEatsColors.red),
                      ),
                      TextSpan(
                        text: 'EATS',
                        style: TextStyle(color: theme.colorScheme.onSurface),
                      ),
                    ],
                  ),
                ),
                Text(
                  'Campus Tuckshop',
                  style: TextStyle(
                    color: theme.textTheme.bodySmall?.color,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          CircleAvatar(
            radius: 22,
            backgroundColor: BcEatsColors.red,
            child: const Icon(Icons.person, color: Colors.white),
          ),
        ],
      ),
    );
  }

  Widget _buildTuckShopStatus(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 0),
      child: Row(
        children: [
          const Icon(Icons.circle, size: 13, color: BcEatsColors.green),
          const SizedBox(width: 7),
          const Text(
            'Open now',
            style: TextStyle(
              color: BcEatsColors.green,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            '• Closes 16:30',
            style: TextStyle(
              color: Theme.of(context).textTheme.bodySmall?.color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSection(
    BuildContext context, {
    required String title,
    required List<BcEatsProduct> items,
  }) {
    if (items.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 21,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'See all',
                style: TextStyle(
                  color: BcEatsColors.red,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 285,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            itemCount: items.length,
            itemBuilder: (context, index) {
              return _buildFoodCard(context, items[index]);
            },
          ),
        ),
        const SizedBox(height: 28),
      ],
    );
  }

  Widget _buildFoodCard(BuildContext context, BcEatsProduct product) {
    final theme = Theme.of(context);
    final isAvailable = product.isAvailable;

    return Opacity(
      opacity: isAvailable ? 1 : 0.55,
      child: Container(
        width: 205,
        margin: const EdgeInsets.only(right: 14),
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: BorderRadius.circular(18),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(18),
              ),
              child: Container(
                height: 125,
                width: double.infinity,
                color: theme.cardColor,
                padding: const EdgeInsets.all(8),
                child: Image.asset(
                  product.imagePath,
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) {
                    return const Icon(
                      Icons.fastfood,
                      color: BcEatsColors.red,
                      size: 48,
                    );
                  },
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 6),
              child: Text(
                product.name,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            if (product.description.isNotEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Text(
                  product.description,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: theme.colorScheme.onSurfaceVariant,
                    fontSize: 12,
                  ),
                ),
              ),
            const Spacer(),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 10, 12),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      product.formattedPrice,
                      style: const TextStyle(
                        color: BcEatsColors.red,
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  if (!isAvailable)
                    Padding(
                      padding: const EdgeInsets.only(right: 6),
                      child: Text(
                        'Unavailable',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: theme.colorScheme.error,
                        ),
                      ),
                    ),
                  Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      color: isAvailable
                          ? BcEatsColors.red
                          : theme.disabledColor,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.add, color: Colors.white, size: 20),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTuckShopHours(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 0, 20, 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.schedule_outlined, size: 19, color: BcEatsColors.red),
              SizedBox(width: 8),
              Text(
                'Tuck Shop Hours',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Mon–Thu: 08:30–16:30  •  Fri: 08:30–16:00',
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            'Sat & Public Holidays: 10:00–14:00',
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 5),
          const Text(
            'Kitchen closes 15 minutes before the shop.',
            style: TextStyle(
              color: BcEatsColors.red,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLegacyBottomNavigationBar(BuildContext context) {
    return SafeArea(
      child: Container(
        height: 68,
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          border: Border(
            top: BorderSide(color: Theme.of(context).dividerColor),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildNavigationItem(
              context,
              icon: Icons.home_rounded,
              label: 'Home',
              selected: true,
            ),
            _buildNavigationItem(
              context,
              icon: Icons.restaurant_menu_outlined,
              label: 'Menu',
            ),
            _buildNavigationItem(
              context,
              icon: Icons.shopping_bag_outlined,
              label: 'Orders',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNavigationItem(
    BuildContext context, {
    required IconData icon,
    required String label,
    bool selected = false,
  }) {
    final color = selected
        ? BcEatsColors.yellow
        : Theme.of(context).colorScheme.onSurfaceVariant;

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(icon, color: color, size: 25),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            color: color,
            fontSize: 11,
            fontWeight: selected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ],
    );
  }
}
