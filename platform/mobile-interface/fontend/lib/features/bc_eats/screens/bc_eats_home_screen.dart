import 'dart:async';
import '../services/bc_eats_store.dart';
import '../widgets/eats_product_card.dart';
import '../widgets/eats_top_bar.dart';
import 'bc_eats_cart_screen.dart';
import 'orders.dart';

import 'package:flutter/material.dart';

import '../constants/bc_eats_colors.dart';
import '../models/bc_eats_product.dart';
import '../repositories/bc_eats_product_repository.dart';
import '../repositories/mock_bc_eats_product_repository.dart';
import '../services/bc_eats_hours_service.dart';

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
  final TextEditingController _searchController = TextEditingController();

  bool _isLoading = true;
  String? _loadError;

  String _selectedCategory = 'All Items';
  String _searchText = '';
  bool _showHours = false;

  static const BcEatsHoursService _hoursService = BcEatsHoursService();

  DateTime _currentTime = DateTime.now();
  Timer? _statusTimer;

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
    BcEatsStore.instance.addListener(_cartChanged);
    _startStatusClock();
  }

  void _cartChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    BcEatsStore.instance.removeListener(_cartChanged);
    _statusTimer?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  void _startStatusClock() {
    _statusTimer?.cancel();

    final now = DateTime.now();

    _currentTime = now;

    final millisecondsIntoMinute = (now.second * 1000) + now.millisecond;

    final millisecondsUntilNextMinute = 60000 - millisecondsIntoMinute;

    _statusTimer = Timer(
      Duration(milliseconds: millisecondsUntilNextMinute),
      () {
        if (!mounted) {
          return;
        }

        setState(() {
          _currentTime = DateTime.now();
        });

        _statusTimer = Timer.periodic(const Duration(minutes: 1), (_) {
          if (!mounted) {
            return;
          }

          setState(() {
            _currentTime = DateTime.now();
          });
        });
      },
    );
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

        if (_selectedCategory != 'All Items' &&
            !_products.any(
              (product) => product.category == _selectedCategory,
            )) {
          _selectedCategory = 'All Items';
        }

        _isLoading = false;
      });
    } catch (_) {
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

  List<String> get _categories => ['All Items', ..._orderedCategories];

  List<BcEatsProduct> get _filteredProducts {
    final query = _searchText.trim().toLowerCase();

    return _products.where((product) {
      final matchesCategory =
          _selectedCategory == 'All Items' ||
          product.category == _selectedCategory;

      final matchesSearch =
          query.isEmpty ||
          product.name.toLowerCase().contains(query) ||
          product.description.toLowerCase().contains(query) ||
          product.category.toLowerCase().contains(query);

      return matchesCategory && matchesSearch;
    }).toList();
  }

  List<BcEatsProduct> _productsForCategory(
    String category, {
    List<BcEatsProduct>? source,
  }) {
    final products = source ?? _products;

    return products.where((product) => product.category == category).toList();
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

      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            _buildTopBar(),

            // Search deliberately stays outside
            // the scrolling section.
            _buildSearchBar(context),

            Expanded(
              child: RefreshIndicator(
                onRefresh: _loadProducts,
                child: ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  children: [
                    _buildTuckShopStatus(context),

                    if (_showHours) ...[
                      const SizedBox(height: 12),
                      _buildTuckShopHours(context),
                    ],

                    const SizedBox(height: 18),

                    _buildCategoryMenu(context),

                    const SizedBox(height: 22),

                    _buildProductContent(context),

                    const SizedBox(height: 100),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),

      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: BcEatsStore.instance.count == 0
          ? null
          : FloatingActionButton.extended(
              backgroundColor: BcEatsColors.yellow,
              foregroundColor: Colors.black,
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute<void>(
                  builder: (_) => const BCEatsCartScreen(),
                ),
              ),
              icon: const Icon(Icons.shopping_bag_outlined),
              label: Text(
                'View cart · ${BcEatsStore.instance.count} · ${money(BcEatsStore.instance.subtotal)}',
              ),
            ),
      bottomNavigationBar: widget.showBottomNavigation
          ? _buildLegacyBottomNavigationBar(context)
          : null,
    );
  }

  Widget _buildTopBar() => const EatsTopBar();

  Widget _buildSearchBar(BuildContext context) {
    final theme = Theme.of(context);

    return Material(
      color: theme.scaffoldBackgroundColor,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 10),
        child: TextField(
          controller: _searchController,
          textInputAction: TextInputAction.search,
          onChanged: (value) {
            setState(() {
              _searchText = value;
            });
          },
          decoration: InputDecoration(
            hintText: 'Search menu items...',

            prefixIcon: Icon(
              Icons.search,
              color: theme.colorScheme.onSurfaceVariant,
            ),

            suffixIcon: _searchText.isEmpty
                ? null
                : IconButton(
                    tooltip: 'Clear search',
                    onPressed: () {
                      _searchController.clear();
                      FocusScope.of(context).unfocus();

                      setState(() {
                        _searchText = '';
                      });
                    },
                    icon: const Icon(Icons.close),
                  ),

            filled: true,
            fillColor: theme.cardColor,

            contentPadding: const EdgeInsets.symmetric(vertical: 16),

            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(18),
              borderSide: BorderSide.none,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTuckShopStatus(BuildContext context) {
    final theme = Theme.of(context);
    final status = _hoursService.statusAt(_currentTime);

    final statusColor = status.isOpen ? BcEatsColors.green : BcEatsColors.red;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Icon(Icons.circle, size: 9, color: statusColor),
                ),
                const SizedBox(width: 7),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        status.label,
                        style: TextStyle(
                          color: statusColor,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 0),
                      Text(
                        status.detail,
                        style: TextStyle(
                          color: theme.textTheme.bodySmall?.color,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          OutlinedButton.icon(
            onPressed: () {
              setState(() {
                _showHours = !_showHours;
              });
            },
            icon: Icon(
              _showHours ? Icons.schedule : Icons.schedule_outlined,
              size: 18,
            ),
            label: Text(_showHours ? 'Hide Hours' : 'View Hours'),
            style: OutlinedButton.styleFrom(
              backgroundColor: Colors.transparent,
              foregroundColor: theme.colorScheme.onSurface,
              side: BorderSide(color: theme.dividerColor),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTuckShopHours(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
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

  Widget _buildCategoryMenu(BuildContext context) {
    final theme = Theme.of(context);
    final categories = _categories;

    return SizedBox(
      height: 46,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: categories.length,
        separatorBuilder: (context, index) {
          return const SizedBox(width: 8);
        },
        itemBuilder: (context, index) {
          final category = categories[index];
          final isSelected = _selectedCategory == category;

          return ChoiceChip(
            selected: isSelected,
            showCheckmark: false,

            onSelected: (_) {
              setState(() {
                _selectedCategory = category;
              });
            },

            avatar: Icon(
              _categoryIcon(category),
              size: 18,
              color: isSelected
                  ? Colors.white
                  : theme.colorScheme.onSurfaceVariant,
            ),

            label: Text(category),

            labelStyle: TextStyle(
              color: isSelected ? Colors.white : theme.colorScheme.onSurface,
              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
            ),

            selectedColor: BcEatsColors.red,
            backgroundColor: theme.cardColor,

            side: BorderSide(
              color: isSelected ? BcEatsColors.red : theme.dividerColor,
            ),

            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
          );
        },
      ),
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
        padding: const EdgeInsets.fromLTRB(24, 40, 24, 60),
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
      return _buildEmptyState(context, 'No products are available right now.');
    }

    final filteredProducts = _filteredProducts;

    if (filteredProducts.isEmpty) {
      return _buildEmptyState(
        context,
        'No menu items match your search or category.',
      );
    }

    final hasSearch = _searchText.trim().isNotEmpty;
    final hasCategoryFilter = _selectedCategory != 'All Items';

    // Search and category selections collapse the page into
    // one filtered product section.
    if (hasSearch || hasCategoryFilter) {
      final title = hasSearch
          ? 'Search Results'
          : _sectionTitle(_selectedCategory);

      return _buildFilteredProductList(
        context,
        title: title,
        items: filteredProducts,
      );
    }

    // All Items preserves Home's useful separate sections.
    return Column(
      children: [
        for (final category in _orderedCategories)
          _buildSection(
            context,
            title: _sectionTitle(category),
            items: _productsForCategory(category, source: filteredProducts),
          ),
      ],
    );
  }

  Widget _buildEmptyState(BuildContext context, String message) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 60),
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
              message,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilteredProductList(
    BuildContext context, {
    required String title,
    required List<BcEatsProduct> items,
  }) {
    const minimumCardWidth = 205.0;
    const cardSpacing = 14.0;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 21,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 12),

          LayoutBuilder(
            builder: (context, constraints) {
              // Use the original card design only when at least two
              // original-width cards can fit side by side.
              final canFitMultipleCards =
                  constraints.maxWidth >= (minimumCardWidth * 2) + cardSpacing;

              if (!canFitMultipleCards) {
                return Column(
                  children: [
                    for (final product in items) ...[
                      _buildVerticalFoodCard(context, product),
                      const SizedBox(height: 12),
                    ],
                  ],
                );
              }

              final columnCount =
                  ((constraints.maxWidth + cardSpacing) /
                          (minimumCardWidth + cardSpacing))
                      .floor();

              final cardWidth =
                  (constraints.maxWidth - (cardSpacing * (columnCount - 1))) /
                  columnCount;

              return Wrap(
                spacing: cardSpacing,
                runSpacing: cardSpacing,
                children: [
                  for (final product in items)
                    SizedBox(
                      width: cardWidth,
                      height: EatsProductCard.heightFor(
                        context,
                        product,
                        cardWidth,
                      ),
                      child: _buildFoodCard(
                        context,
                        product,
                        width: cardWidth,
                        margin: EdgeInsets.zero,
                      ),
                    ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildVerticalFoodCard(BuildContext context, BcEatsProduct product) {
    final theme = Theme.of(context);
    final isAvailable = product.isAvailable;

    return Opacity(
      opacity: isAvailable ? 1 : 0.55,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: BorderRadius.circular(18),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 100,
              height: 100,
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: theme.scaffoldBackgroundColor,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Image.asset(
                product.imagePath,
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) {
                  return const Icon(
                    Icons.fastfood,
                    color: BcEatsColors.red,
                    size: 42,
                  );
                },
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: theme.colorScheme.onSurface,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (product.description.isNotEmpty) ...[
                    const SizedBox(height: 5),
                    Text(
                      product.description,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: theme.colorScheme.onSurfaceVariant,
                        fontSize: 12,
                      ),
                    ),
                  ],
                  const SizedBox(height: 14),
                  EatsProductFooter(product: product),
                ],
              ),
            ),
          ],
        ),
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
          child: Text(
            title,
            style: TextStyle(
              fontSize: 21,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
        ),

        const SizedBox(height: 12),

        SizedBox(
          height: items
              .map((item) => EatsProductCard.heightFor(context, item, 205))
              .reduce((a, b) => a > b ? a : b),
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

  Widget _buildFoodCard(
    BuildContext context,
    BcEatsProduct product, {
    double width = 205,
    EdgeInsetsGeometry margin = const EdgeInsets.only(right: 14),
  }) => Padding(
    padding: margin,
    child: SizedBox(
      width: width,
      child: EatsProductCard(product: product),
    ),
  );

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

    return InkWell(
      onTap: label == 'Orders'
          ? () => Navigator.push(
              context,
              MaterialPageRoute<void>(builder: (_) => const OrdersScreen()),
            )
          : null,
      child: Column(
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
      ),
    );
  }

  IconData _categoryIcon(String category) {
    switch (category) {
      case 'All Items':
        return Icons.fastfood;

      case 'Daily Specials':
        return Icons.local_fire_department_outlined;

      case 'Sandwiches':
        return Icons.lunch_dining;

      case 'Burgers':
        return Icons.lunch_dining_outlined;

      case 'Hot Dogs':
        return Icons.fastfood_outlined;

      case 'Chips':
        return Icons.fastfood;

      case 'Drinks':
        return Icons.local_drink_outlined;

      case 'Extras':
        return Icons.add_circle_outline;

      default:
        return Icons.fastfood;
    }
  }
}
