import 'package:flutter/material.dart';

import '../models/bc_eats_product.dart';
import '../repositories/bc_eats_product_repository.dart';
import '../repositories/api_bc_eats_product_repository.dart';
import '../constants/bc_eats_colors.dart';
import '../widgets/eats_top_bar.dart';

// This is the BC Eats menu screen where users can browse the real tuckshop items and filter them using the categories on the left.
class BCEatsMenuScreen extends StatefulWidget {
  final bool showBottomNavigation;
  final BcEatsProductRepository? productRepository;

  const BCEatsMenuScreen({
    super.key,
    this.showBottomNavigation = true,
    this.productRepository,
  });

  @override
  State<BCEatsMenuScreen> createState() => _BCEatsMenuScreenState();
}

class _BCEatsMenuScreenState extends State<BCEatsMenuScreen> {
  String selectedCategory = 'All Items';
  String searchText = '';

  // I kept the categories on the left because we agreed that the vertical layout is cleaner than having the same categories displayed twice.
  final List<String> categories = [
    'All Items',
    'Daily Specials',
    'Sandwiches',
    'Burgers',
    'Hot Dogs',
    'Chips',
    'Drinks',
    'Extras',
  ];
  final List<BcEatsProduct> _products = [];

  bool _isLoading = true;
  String? _loadError;

  BcEatsProductRepository get _productRepository =>
      widget.productRepository ?? ApiBcEatsProductRepository();

  @override
  void initState() {
    super.initState();
    _loadProducts();
  }

  Future<void> _loadProducts() async {
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
        _loadError = null;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _isLoading = false;
        _loadError = 'Unable to load the menu. Please try again.';
      });
    }
  }

  List<String> get _visibleCategories {
    final fromBackend = _products.map((p) => p.category.trim()).where((c) => c.isNotEmpty).toSet().toList()..sort();
    return ['All Items', ...(fromBackend.isEmpty ? categories.skip(1) : fromBackend)];
  }

  // This filters the menu using both the selected category and search text. It means users can search for an item while still staying in a category.
  List<BcEatsProduct> get filteredItems {
    return _products.where((item) {
      final matchesCategory =
          selectedCategory == 'All Items' || item.category == selectedCategory;

      final matchesSearch = item.name.toLowerCase().contains(
        searchText.toLowerCase(),
      );

      return matchesCategory && matchesSearch;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(context),

            Expanded(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // The vertical category menu stays on the left side.
                  _buildDesktopCategoryMenu(),

                  Expanded(child: _buildMenuContent(context)),
                ],
              ),
            ),

            if (widget.showBottomNavigation) _buildBottomNavigation(context),
          ],
        ),
      ),
    );
  }

  // This is the header for the BC Eats page, including the logo and cart icon. I kept the header simple so that the menu content remains the main focus.
  Widget _buildHeader(BuildContext context) => const EatsTopBar();

  // This is the only category menu we are keeping for now. Users can select a category here, and the menu items will update below.
  Widget _buildDesktopCategoryMenu() {
    return Container(
      width: 215,
      color: Theme.of(context).cardColor,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
        itemCount: _visibleCategories.length,
        itemBuilder: (context, index) {
          final category = _visibleCategories[index];
          final isSelected = selectedCategory == category;

          return Padding(
            padding: const EdgeInsets.only(bottom: 7),
            child: InkWell(
              borderRadius: BorderRadius.circular(16),

              onTap: () {
                setState(() {
                  selectedCategory = category;
                });
              },

              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 16,
                ),

                decoration: BoxDecoration(
                  color: isSelected
                      ? BcEatsColors.red
                      : Theme.of(context).cardColor,
                  borderRadius: BorderRadius.circular(16),
                ),

                child: Row(
                  children: [
                    Icon(
                      _categoryIcon(category),
                      color: isSelected ? Colors.white : BcEatsColors.yellow,
                      size: 22,
                    ),

                    const SizedBox(width: 12),

                    Expanded(
                      child: Text(
                        category,
                        style: TextStyle(
                          color: isSelected ? Colors.white : Colors.black87,
                          fontWeight: isSelected
                              ? FontWeight.bold
                              : FontWeight.normal,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  // The content now only has the search bar and menu items. I removed the horizontal category buttons because the vertical menu already handles the categories.
  Widget _buildMenuContent(BuildContext context) {
    return Column(
      children: [
        _buildSearchBar(context),

        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),

            children: [
              Text(
                selectedCategory,
                style: TextStyle(
                  fontSize: 30,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),

              const SizedBox(height: 5),

              Text(
                'Fresh meals. Fast service. Made for students.',
                style: TextStyle(
                  color: Theme.of(context).textTheme.bodySmall?.color,
                  fontSize: 15,
                ),
              ),

              const SizedBox(height: 18),

              if (_isLoading)
                const Padding(
                  padding: EdgeInsets.all(30),
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (_loadError != null)
                Padding(
                  padding: const EdgeInsets.all(30),
                  child: Center(
                    child: Text(_loadError!, textAlign: TextAlign.center),
                  ),
                )
              else if (filteredItems.isEmpty)
                Padding(
                  padding: EdgeInsets.all(30),

                  child: Center(
                    child: Text(
                      'No menu items found.',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                  ),
                )
              else
                ...filteredItems.map((item) => _buildMenuCard(context, item)),
            ],
          ),
        ),
      ],
    );
  }

  // The search bar allows users to find food items without scrolling through the entire menu.
  // The search updates immediately whenever the user types something.
  Widget _buildSearchBar(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),

      child: TextField(
        onChanged: (value) {
          setState(() {
            searchText = value;
          });
        },

        decoration: InputDecoration(
          hintText: 'Search menu items...',

          prefixIcon: Icon(Icons.search, color: Theme.of(context).hintColor),

          filled: true,
          fillColor: Theme.of(context).cardColor,

          contentPadding: const EdgeInsets.symmetric(vertical: 18),

          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(18),
            borderSide: BorderSide.none,
          ),
        ),
      ),
    );
  }

  // Each menu item is displayed as a card with its image, description, price, and Add button.
  // The real menu images help us see how the final BC Eats screen could look.
  Widget _buildMenuCard(BuildContext context, BcEatsProduct item) {
    return Container(
      height: 185,

      margin: const EdgeInsets.only(bottom: 16),

      padding: const EdgeInsets.all(10),

      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(20),
      ),

      child: Row(
        children: [
          Container(
            width: 145,
            height: 165,

            padding: const EdgeInsets.all(10),

            decoration: BoxDecoration(
              color: Theme.of(context).scaffoldBackgroundColor,
              borderRadius: BorderRadius.circular(16),
            ),

            child: Image.asset(
              item.imagePath,

              fit: BoxFit.contain,

              errorBuilder: (context, error, stackTrace) {
                return const Icon(
                  Icons.fastfood_outlined,
                  color: Colors.grey,
                  size: 55,
                );
              },
            ),
          ),

          const SizedBox(width: 16),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,

              children: [
                Text(
                  item.name,

                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,

                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),

                const SizedBox(height: 8),

                Text(
                  item.description,

                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,

                  style: TextStyle(
                    fontSize: 14,
                    color: Theme.of(context).textTheme.bodyMedium?.color,
                  ),
                ),

                const Spacer(),

                Row(
                  children: [
                    Text(
                      item.formattedPrice,

                      style: const TextStyle(
                        color: BcEatsColors.red,
                        fontSize: 21,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    const Spacer(),

                    ElevatedButton.icon(
                      onPressed: () {},

                      icon: const Icon(Icons.add, size: 18),

                      label: const Text('Add'),

                      style: ElevatedButton.styleFrom(
                        backgroundColor: BcEatsColors.red,
                        foregroundColor: Colors.white,
                        elevation: 0,

                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 10,
                        ),

                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // This is the bottom navigation bar for the BC Eats screen. The Menu tab is highlighted because the user is currently viewing the menu.
  Widget _buildBottomNavigation(BuildContext context) {
    return Container(
      height: 65,

      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,

        border: Border(top: BorderSide(color: Theme.of(context).dividerColor)),
      ),

      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,

        children: [
          _bottomNavItem(context, Icons.home_outlined, 'Home', false),

          _bottomNavItem(context, Icons.restaurant_menu, 'Menu', true),

          _bottomNavItem(context, Icons.shopping_bag_outlined, 'Orders', false),

          _bottomNavItem(context, Icons.bookmark_border, 'Saved', false),

          _bottomNavItem(context, Icons.person_outline, 'Profile', false),
        ],
      ),
    );
  }

  // This creates each item in the bottom navigation bar. The selected item uses the BC yellow colour to show which page is active.
  Widget _bottomNavItem(
    BuildContext context,
    IconData icon,
    String label,
    bool selected,
  ) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,

      children: [
        Icon(
          icon,
          color: selected ? BcEatsColors.yellow : Colors.grey,
          size: 24,
        ),

        const SizedBox(height: 3),

        Text(
          label,

          style: TextStyle(
            color: selected ? BcEatsColors.yellow : Colors.grey,

            fontSize: 12,
          ),
        ),
      ],
    );
  }

  // These icons make the categories easier to recognise.
  // Each category has its own icon so the vertical menu does not look too plain.
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
