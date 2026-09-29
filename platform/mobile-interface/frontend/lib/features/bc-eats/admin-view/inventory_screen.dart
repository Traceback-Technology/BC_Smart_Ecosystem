import 'package:flutter/material.dart';
import 'constants/admin_colours.dart';

// =============================================================================
// INVENTORY MODEL
// =============================================================================

class ProductItem {
  final String id;
  final String name;
  final String category;
  final double price;
  final bool inStock;
  final int stockCount;
  final int threshold;

  ProductItem({
    required this.id,
    required this.name,
    required this.category,
    required this.price,
    required this.inStock,
    required this.stockCount,
    required this.threshold,
  });

  factory ProductItem.fromJson(Map<String, dynamic> json) {
    return ProductItem(
      id: json['id']?.toString() ?? '',
      name: json['name'] ?? '',
      category: json['category'] ?? 'Uncategorized',
      price: (json['price'] as num?)?.toDouble() ?? 0.0,
      inStock: json['inStock'] ?? false,
      stockCount: json['stockCount'] ?? 0,
      threshold: json['threshold'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'category': category,
      'price': price,
      'inStock': inStock,
      'stockCount': stockCount,
      'threshold': threshold,
    };
  }

  ProductItem copyWith({
    String? id,
    String? name,
    String? category,
    double? price,
    bool? inStock,
    int? stockCount,
    int? threshold,
  }) {
    return ProductItem(
      id: id ?? this.id,
      name: name ?? this.name,
      category: category ?? this.category,
      price: price ?? this.price,
      inStock: inStock ?? this.inStock,
      stockCount: stockCount ?? this.stockCount,
      threshold: threshold ?? this.threshold,
    );
  }
}

// =============================================================================
// INVENTORY SCREEN
// =============================================================================

class InventoryScreen extends StatefulWidget {
  const InventoryScreen({super.key});

  @override
  State<InventoryScreen> createState() => _InventoryScreenState();
}

class _InventoryScreenState extends State<InventoryScreen> {
  String _selectedCategory = 'All';
  String _searchQuery = '';
  bool _isLoading = false;

  final List<String> _categories = ['All', 'Quick Picks', 'Drinks', 'Toasties', 'Combos'];
  List<ProductItem> _products = [];

  // Dialog Controllers
  final _nameController = TextEditingController();
  final _priceController = TextEditingController();
  final _categoryController = TextEditingController();
  final _stockController = TextEditingController();
  final _thresholdController = TextEditingController(text: '5');
  bool _enableThresholdAlert = false;

  @override
  void initState() {
    super.initState();
    _fetchProducts();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _priceController.dispose();
    _categoryController.dispose();
    _stockController.dispose();
    _thresholdController.dispose();
    super.dispose();
  }

  // BACKEND INTEGRATION POINT: Fetch all inventory items
  Future<void> _fetchProducts() async {
    setState(() => _isLoading = true);
    try {
      // TODO: Replace local mock with your Supabase / Express API call:
      // final response = await supabase.from('products').select();
      // _products = response.map((data) => ProductItem.fromJson(data)).toList();
      
      await Future.delayed(const Duration(milliseconds: 300));
      setState(() {
        _products = [
          ProductItem(id: '1', name: 'French Fries (Large)', category: 'Quick Picks', price: 28.00, inStock: true, stockCount: 15, threshold: 5),
          ProductItem(id: '2', name: 'Ice Tea (Lemon)', category: 'Drinks', price: 22.00, inStock: true, stockCount: 3, threshold: 5),
          ProductItem(id: '3', name: 'Cheese & Tomato Toastie', category: 'Toasties', price: 32.00, inStock: true, stockCount: 1, threshold: 3),
          ProductItem(id: '4', name: 'Beef Burger Meal', category: 'Combos', price: 65.00, inStock: false, stockCount: 0, threshold: 5),
        ];
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error fetching products: $e')));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // BACKEND INTEGRATION POINT: Add new product item
  Future<void> _addProduct(ProductItem item) async {
    // TODO: Send new product payload to Express/Supabase backend:
    // await supabase.from('products').insert(item.toJson());
    
    setState(() {
      _products.add(item);
    });
  }

  // BACKEND INTEGRATION POINT: Toggle stock availability status
  Future<void> _toggleStockStatus(String productId, bool currentStatus) async {
    // TODO: Update stock status in database:
    // await supabase.from('products').update({'inStock': !currentStatus}).eq('id', productId);
    
    setState(() {
      final index = _products.indexWhere((p) => p.id == productId);
      if (index != -1) {
        _products[index] = _products[index].copyWith(inStock: !currentStatus);
      }
    });
  }

  // BACKEND INTEGRATION POINT: Delete inventory product
  Future<void> _deleteProduct(String productId) async {
    // TODO: Delete record from database:
    // await supabase.from('products').delete().eq('id', productId);
    
    setState(() {
      _products.removeWhere((p) => p.id == productId);
    });
  }

  List<ProductItem> get _filteredProducts {
    return _products.where((product) {
      final matchesCategory = _selectedCategory == 'All' || product.category == _selectedCategory;
      final matchesSearch = product.name.toLowerCase().contains(_searchQuery.toLowerCase());
      return matchesCategory && matchesSearch;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final mutedTextColor = isDark ? AdminColors.darkTextMuted : AdminColors.textGrey;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isMobile = constraints.maxWidth < 600;

          return RefreshIndicator(
            onRefresh: _fetchProducts,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: EdgeInsets.all(isMobile ? 16.0 : 24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader(context, isMobile, mutedTextColor),
                  const SizedBox(height: 20),
                  _buildFilterAndSearchSection(context, isMobile, mutedTextColor),
                  const SizedBox(height: 20),
                  _isLoading
                      ? const Center(child: Padding(padding: EdgeInsets.all(40), child: CircularProgressIndicator()))
                      : _buildProductList(context, isMobile, mutedTextColor, isDark),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildHeader(BuildContext context, bool isMobile, Color mutedText) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Inventory Management', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.onSurface)),
            const SizedBox(height: 4),
            Text('Track and update menu availability in real time.', style: TextStyle(fontSize: 13, color: mutedText)),
          ],
        ),
        ElevatedButton.icon(
          style: ElevatedButton.styleFrom(
            backgroundColor: AdminColors.primaryYellow,
            padding: EdgeInsets.symmetric(horizontal: isMobile ? 12 : 16, vertical: 12),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
          onPressed: () => _showAddProductDialog(context),
          icon: const Icon(Icons.add, size: 18, color: AdminColors.textDark),
          label: Text(isMobile ? 'Add' : 'Add Product', style: const TextStyle(color: AdminColors.textDark, fontWeight: FontWeight.bold)),
        ),
      ],
    );
  }

  Widget _buildFilterAndSearchSection(BuildContext context, bool isMobile, Color mutedText) {
    if (isMobile) {
      return Column(
        children: [
          TextField(
            onChanged: (val) => setState(() => _searchQuery = val),
            style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
            decoration: InputDecoration(
              hintText: 'Search products...',
              hintStyle: TextStyle(color: mutedText),
              prefixIcon: Icon(Icons.search, size: 20, color: mutedText),
              contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 12),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: Theme.of(context).dividerColor)),
              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: AdminColors.primaryYellow)),
              filled: true,
              fillColor: Theme.of(context).cardColor,
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 38,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: _categories.map((cat) => _buildCategoryChip(context, cat, mutedText)).toList(),
            ),
          ),
        ],
      );
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: _categories.map((cat) => _buildCategoryChip(context, cat, mutedText)).toList(),
        ),
        SizedBox(
          width: 260,
          child: TextField(
            onChanged: (val) => setState(() => _searchQuery = val),
            style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
            decoration: InputDecoration(
              hintText: 'Search products...',
              hintStyle: TextStyle(color: mutedText),
              prefixIcon: Icon(Icons.search, size: 20, color: mutedText),
              contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 12),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: Theme.of(context).dividerColor)),
              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: AdminColors.primaryYellow)),
              filled: true,
              fillColor: Theme.of(context).cardColor,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCategoryChip(BuildContext context, String label, Color mutedText) {
    final isSelected = _selectedCategory == label;
    return Padding(
      padding: const EdgeInsets.only(right: 8.0),
      child: FilterChip(
        selected: isSelected,
        label: Text(label),
        labelStyle: TextStyle(
          fontSize: 12,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          color: isSelected ? AdminColors.textDark : Theme.of(context).colorScheme.onSurface,
        ),
        backgroundColor: Theme.of(context).cardColor,
        selectedColor: AdminColors.primaryYellow,
        side: BorderSide(color: isSelected ? AdminColors.primaryYellow : Theme.of(context).dividerColor),
        onSelected: (bool selected) {
          setState(() {
            _selectedCategory = label;
          });
        },
      ),
    );
  }

  Widget _buildProductList(BuildContext context, bool isMobile, Color mutedText, bool isDark) {
    final products = _filteredProducts;

    if (products.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(40),
        decoration: BoxDecoration(color: Theme.of(context).cardColor, borderRadius: BorderRadius.circular(12), border: Border.all(color: Theme.of(context).dividerColor)),
        child: Column(
          children: [
            Icon(Icons.inventory_2_outlined, size: 48, color: mutedText),
            const SizedBox(height: 12),
            Text('No products found', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Theme.of(context).colorScheme.onSurface)),
            const SizedBox(height: 4),
            Text('Add inventory items or try adjusting search filters.', style: TextStyle(color: mutedText, fontSize: 12)),
          ],
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Theme.of(context).dividerColor),
      ),
      child: ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: products.length,
        separatorBuilder: (context, index) => Divider(height: 1, color: Theme.of(context).dividerColor),
        itemBuilder: (context, index) {
          final product = products[index];
          final isLowStock = product.stockCount <= product.threshold;

          return ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            title: Row(
              children: [
                Expanded(
                  child: Text(
                    product.name,
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Theme.of(context).colorScheme.onSurface),
                  ),
                ),
                if (isLowStock)
                  Container(
                    margin: const EdgeInsets.only(left: 8),
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: isDark ? AdminColors.darkSoftRed : AdminColors.softRed,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Text('Low Stock', style: TextStyle(color: AdminColors.alertRed, fontSize: 10, fontWeight: FontWeight.bold)),
                  ),
              ],
            ),
            subtitle: Text(
              '${product.category} • R${product.price.toStringAsFixed(2)} • Stock: ${product.stockCount}',
              style: TextStyle(fontSize: 12, color: mutedText),
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Switch(
                  value: product.inStock,
                  activeColor: AdminColors.successGreen,
                  onChanged: (val) => _toggleStockStatus(product.id, product.inStock),
                ),
                IconButton(
                  icon: Icon(Icons.delete_outline, size: 20, color: mutedText),
                  onPressed: () => _deleteProduct(product.id),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  void _showAddProductDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: Theme.of(context).cardColor,
              title: Text('Add New Product', style: TextStyle(fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.onSurface)),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(controller: _nameController, decoration: const InputDecoration(labelText: 'Product Name')),
                    TextField(controller: _categoryController, decoration: const InputDecoration(labelText: 'Category')),
                    TextField(controller: _priceController, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Price (R)')),
                    TextField(controller: _stockController, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Stock Quantity')),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Checkbox(
                          value: _enableThresholdAlert,
                          activeColor: AdminColors.primaryYellow,
                          onChanged: (val) => setDialogState(() => _enableThresholdAlert = val ?? false),
                        ),
                        Text('Enable Low Stock Alert', style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.onSurface)),
                      ],
                    ),
                    if (_enableThresholdAlert)
                      TextField(controller: _thresholdController, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Low Stock Threshold')),
                  ],
                ),
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: AdminColors.primaryYellow),
                  onPressed: () {
                    final newProduct = ProductItem(
                      id: DateTime.now().millisecondsSinceEpoch.toString(),
                      name: _nameController.text,
                      category: _categoryController.text,
                      price: double.tryParse(_priceController.text) ?? 0.0,
                      inStock: true,
                      stockCount: int.tryParse(_stockController.text) ?? 0,
                      threshold: int.tryParse(_thresholdController.text) ?? 5,
                    );
                    _addProduct(newProduct);
                    _nameController.clear();
                    _priceController.clear();
                    _categoryController.clear();
                    _stockController.clear();
                    Navigator.pop(context);
                  },
                  child: const Text('Save', style: TextStyle(color: AdminColors.textDark, fontWeight: FontWeight.bold)),
                ),
              ],
            );
          },
        );
      },
    );
  }
}