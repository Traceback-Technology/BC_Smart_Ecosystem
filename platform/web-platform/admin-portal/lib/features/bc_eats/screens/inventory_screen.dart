import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/bc_api_client.dart';
import '../admin-view/constants/admin_colours.dart';

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

  final List<String> _categories = [
    'All',
    'Quick Picks',
    'Drinks',
    'Toasties',
    'Combos',
  ];
  List<ProductItem> _products = [];

  // Dialog Controllers
  final _nameController = TextEditingController();
  final _priceController = TextEditingController();
  final _categoryController = TextEditingController();
  final _stockController = TextEditingController();
  final _thresholdController = TextEditingController(text: '5');
  bool _enableThresholdAlert = false;
  final _descriptionController = TextEditingController();
  final _imageUrlController = TextEditingController();
  XFile? _selectedImage;
  bool _backendAvailable = false;

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
    _descriptionController.dispose();
    _imageUrlController.dispose();
    super.dispose();
  }

  // Database products replace demo rows when the API has stored data.
  Future<void> _fetchProducts() async {
    setState(() => _isLoading = true);
    try {
      final result = await BcApiClient.instance.getJson('/api/foods', query: {'available': 'all'});
      final rows = result['data'];
      if (rows is List && rows.isNotEmpty) {
        setState(() {
          _backendAvailable = true;
          _products = rows.whereType<Map<String, dynamic>>().map((json) => ProductItem(
            id: (json['_id'] ?? json['id']).toString(),
            name: json['name']?.toString() ?? '',
            category: json['category']?.toString() ?? 'Uncategorized',
            price: (json['price'] as num?)?.toDouble() ?? 0,
            inStock: json['available'] == true,
            stockCount: (json['stockCount'] as num?)?.toInt() ?? 0,
            threshold: (json['threshold'] as num?)?.toInt() ?? 5,
          )).toList();
        });
      } else {
        setState(() { _backendAvailable = true; _products = []; });
      }
    } catch (_) {
      setState(() { _backendAvailable = false; _products = [
        ProductItem(id:'demo-1',name:'French Fries (Large)',category:'Quick Picks',price:28,inStock:true,stockCount:15,threshold:5),
        ProductItem(id:'demo-2',name:'Ice Tea (Lemon)',category:'Drinks',price:22,inStock:true,stockCount:3,threshold:5),
        ProductItem(id:'demo-3',name:'Cheese & Tomato Toastie',category:'Toasties',price:32,inStock:true,stockCount:1,threshold:3),
        ProductItem(id:'demo-4',name:'Beef Burger Meal',category:'Combos',price:65,inStock:false,stockCount:0,threshold:5),
      ]; });
    } finally { if (mounted) setState(() => _isLoading = false); }
  }

  Future<void> _addProduct(ProductItem item) async {
    if (_backendAvailable) {
      try {
        var imageUrl = _imageUrlController.text.trim();
        if (_selectedImage != null) {
          final upload = await BcApiClient.instance.uploadImage(await _selectedImage!.readAsBytes(), _selectedImage!.name);
          imageUrl = (upload['data'] as Map<String, dynamic>)['imageUrl']?.toString() ?? imageUrl;
        }
        final result = await BcApiClient.instance.postJson('/api/foods', {
          'name': item.name, 'description': _descriptionController.text.trim().isEmpty ? item.name : _descriptionController.text.trim(),
          'category': item.category, 'price': item.price, 'available': item.inStock,
          'imageUrl': imageUrl, 'image': imageUrl, 'stockCount': item.stockCount, 'threshold': item.threshold,
        });
        final json = result['data'] as Map<String, dynamic>;
        setState(() => _products.add(ProductItem(id: json['_id'].toString(), name: json['name'].toString(), category: json['category'].toString(), price: (json['price'] as num).toDouble(), inStock: json['available'] == true, stockCount: (json['stockCount'] as num?)?.toInt() ?? item.stockCount, threshold: (json['threshold'] as num?)?.toInt() ?? item.threshold)));
        return;
      } catch (e) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Could not save product. Check admin authentication and API: $e')));
        return;
      }
    }
    setState(() => _products.add(item));
  }

  Future<void> _toggleStockStatus(String productId, bool currentStatus) async {
    final next = !currentStatus;
    if (_backendAvailable) {
      try { await BcApiClient.instance.putJson('/api/foods/$productId', {'available': next}); }
      catch (e) { if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Could not update stock: $e'))); return; }
    }
    setState(() { final i = _products.indexWhere((p) => p.id == productId); if (i != -1) _products[i] = _products[i].copyWith(inStock: next); });
  }

  Future<void> _deleteProduct(String productId) async {
    if (_backendAvailable) {
      try { await BcApiClient.instance.deleteJson('/api/foods/$productId'); }
      catch (e) { if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Could not delete product: $e'))); return; }
    }
    setState(() => _products.removeWhere((p) => p.id == productId));
  }

  List<ProductItem> get _filteredProducts {
    return _products.where((product) {
      final matchesCategory =
          _selectedCategory == 'All' || product.category == _selectedCategory;
      final matchesSearch = product.name.toLowerCase().contains(
        _searchQuery.toLowerCase(),
      );
      return matchesCategory && matchesSearch;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final mutedTextColor = isDark
        ? AdminColors.darkTextMuted
        : AdminColors.textGrey;

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
                  _buildFilterAndSearchSection(
                    context,
                    isMobile,
                    mutedTextColor,
                  ),
                  const SizedBox(height: 20),
                  _isLoading
                      ? const Center(
                          child: Padding(
                            padding: EdgeInsets.all(40),
                            child: CircularProgressIndicator(),
                          ),
                        )
                      : _buildProductList(
                          context,
                          isMobile,
                          mutedTextColor,
                          isDark,
                        ),
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
            Text(
              'Inventory Management',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Track and update menu availability in real time.',
              style: TextStyle(fontSize: 13, color: mutedText),
            ),
          ],
        ),
        ElevatedButton.icon(
          style: ElevatedButton.styleFrom(
            backgroundColor: AdminColors.primaryYellow,
            padding: EdgeInsets.symmetric(
              horizontal: isMobile ? 12 : 16,
              vertical: 12,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          onPressed: () => _showAddProductDialog(context),
          icon: const Icon(Icons.add, size: 18, color: AdminColors.textDark),
          label: Text(
            isMobile ? 'Add' : 'Add Product',
            style: const TextStyle(
              color: AdminColors.textDark,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFilterAndSearchSection(
    BuildContext context,
    bool isMobile,
    Color mutedText,
  ) {
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
              contentPadding: const EdgeInsets.symmetric(
                vertical: 0,
                horizontal: 12,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: Theme.of(context).dividerColor),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: AdminColors.primaryYellow),
              ),
              filled: true,
              fillColor: Theme.of(context).cardColor,
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 38,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: _categories
                  .map((cat) => _buildCategoryChip(context, cat, mutedText))
                  .toList(),
            ),
          ),
        ],
      );
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: _categories
              .map((cat) => _buildCategoryChip(context, cat, mutedText))
              .toList(),
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
              contentPadding: const EdgeInsets.symmetric(
                vertical: 0,
                horizontal: 12,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: Theme.of(context).dividerColor),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: AdminColors.primaryYellow),
              ),
              filled: true,
              fillColor: Theme.of(context).cardColor,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCategoryChip(
    BuildContext context,
    String label,
    Color mutedText,
  ) {
    final isSelected = _selectedCategory == label;
    return Padding(
      padding: const EdgeInsets.only(right: 8.0),
      child: FilterChip(
        selected: isSelected,
        label: Text(label),
        labelStyle: TextStyle(
          fontSize: 12,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          color: isSelected
              ? AdminColors.textDark
              : Theme.of(context).colorScheme.onSurface,
        ),
        backgroundColor: Theme.of(context).cardColor,
        selectedColor: AdminColors.primaryYellow,
        side: BorderSide(
          color: isSelected
              ? AdminColors.primaryYellow
              : Theme.of(context).dividerColor,
        ),
        onSelected: (bool selected) {
          setState(() {
            _selectedCategory = label;
          });
        },
      ),
    );
  }

  Widget _buildProductList(
    BuildContext context,
    bool isMobile,
    Color mutedText,
    bool isDark,
  ) {
    final products = _filteredProducts;

    if (products.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(40),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Theme.of(context).dividerColor),
        ),
        child: Column(
          children: [
            Icon(Icons.inventory_2_outlined, size: 48, color: mutedText),
            const SizedBox(height: 12),
            Text(
              'No products found',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Add inventory items or try adjusting search filters.',
              style: TextStyle(color: mutedText, fontSize: 12),
            ),
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
        separatorBuilder: (context, index) =>
            Divider(height: 1, color: Theme.of(context).dividerColor),
        itemBuilder: (context, index) {
          final product = products[index];
          final isLowStock = product.stockCount <= product.threshold;

          return ListTile(
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 8,
            ),
            title: Row(
              children: [
                Expanded(
                  child: Text(
                    product.name,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                ),
                if (isLowStock)
                  Container(
                    margin: const EdgeInsets.only(left: 8),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: isDark
                          ? AdminColors.darkSoftRed
                          : AdminColors.softRed,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Text(
                      'Low Stock',
                      style: TextStyle(
                        color: AdminColors.alertRed,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
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
                  onChanged: (val) =>
                      _toggleStockStatus(product.id, product.inStock),
                ),
                IconButton(tooltip: 'Edit product and stock', icon: Icon(Icons.edit_outlined, size: 20, color: mutedText), onPressed: () => _showEditProductDialog(product)),
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


  void _showEditProductDialog(ProductItem product) {
    _nameController.text = product.name;
    _categoryController.text = product.category;
    _priceController.text = product.price.toStringAsFixed(2);
    _stockController.text = product.stockCount.toString();
    _thresholdController.text = product.threshold.toString();
    showDialog(context: context, builder: (dialogContext) => AlertDialog(
      title: const Text('Edit Product / Stock'),
      content: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, children: [
        TextField(controller: _nameController, decoration: const InputDecoration(labelText: 'Product name')),
        TextField(controller: _categoryController, decoration: const InputDecoration(labelText: 'Category')),
        TextField(controller: _priceController, keyboardType: const TextInputType.numberWithOptions(decimal: true), decoration: const InputDecoration(labelText: 'Price (R)')),
        TextField(controller: _stockController, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Stock quantity')),
        TextField(controller: _thresholdController, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Low-stock threshold')),
      ])),
      actions: [TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('Cancel')), FilledButton(onPressed: () async {
        final name = _nameController.text.trim(); final category = _categoryController.text.trim();
        final price = double.tryParse(_priceController.text.trim()); final stock = int.tryParse(_stockController.text.trim()); final threshold = int.tryParse(_thresholdController.text.trim());
        if (name.length < 2 || category.length < 2 || price == null || price < 0 || stock == null || stock < 0 || threshold == null || threshold < 0) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Check the name, category, price, stock and threshold values.'))); return;
        }
        try {
          if (_backendAvailable) {
            await BcApiClient.instance.putJson('/api/foods/${product.id}', {'name': name, 'category': category, 'price': price, 'description': _descriptionController.text.trim().length >= 3 ? _descriptionController.text.trim() : name, 'stockCount': stock, 'threshold': threshold, 'available': stock > 0});
          }
          if (!mounted) return;
          setState(() { final i = _products.indexWhere((p) => p.id == product.id); if (i >= 0) _products[i] = product.copyWith(name: name, category: category, price: price, stockCount: stock, threshold: threshold, inStock: stock > 0); });
          Navigator.pop(dialogContext);
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Product updated successfully.')));
        } catch (e) { ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Could not update product: $e'))); }
      }, child: const Text('Save changes'))],
    ));
  }

  void _showAddProductDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: Theme.of(context).cardColor,
              title: Text(
                'Add New Product',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: _nameController,
                      decoration: const InputDecoration(
                        labelText: 'Product Name',
                      ),
                    ),
                    TextField(
                      controller: _categoryController,
                      decoration: const InputDecoration(labelText: 'Category'),
                    ),
                    TextField(
                      controller: _priceController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'Price (R)'),
                    ),
                    TextField(
                      controller: _stockController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'Stock Quantity'),
                    ),
                    TextField(controller: _descriptionController, decoration: const InputDecoration(labelText: 'Description (optional)')),
                    TextField(controller: _imageUrlController, decoration: const InputDecoration(labelText: 'Image URL (optional)')),
                    Align(alignment: Alignment.centerLeft, child: TextButton.icon(
                      icon: const Icon(Icons.upload_file), label: Text(_selectedImage == null ? 'Choose image file (max 5 MB)' : 'Image selected: ${_selectedImage!.name}'),
                      onPressed: () async {
                        final image = await ImagePicker().pickImage(source: ImageSource.gallery, imageQuality: 85);
                        if (image != null) setDialogState(() => _selectedImage = image);
                      },
                    )),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Checkbox(
                          value: _enableThresholdAlert,
                          activeColor: AdminColors.primaryYellow,
                          onChanged: (val) => setDialogState(
                            () => _enableThresholdAlert = val ?? false,
                          ),
                        ),
                        Text(
                          'Enable Low Stock Alert',
                          style: TextStyle(
                            fontSize: 12,
                            color: Theme.of(context).colorScheme.onSurface,
                          ),
                        ),
                      ],
                    ),
                    if (_enableThresholdAlert)
                      TextField(
                        controller: _thresholdController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Low Stock Threshold',
                        ),
                      ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AdminColors.primaryYellow,
                  ),
                  onPressed: () {
                    final name = _nameController.text.trim();
                    final category = _categoryController.text.trim();
                    final price = double.tryParse(_priceController.text.trim());
                    final stock = int.tryParse(_stockController.text.trim());
                    final threshold = int.tryParse(_thresholdController.text.trim());
                    if (name.length < 2 || category.length < 2 || price == null || price < 0 || stock == null || stock < 0 || (_enableThresholdAlert && (threshold == null || threshold < 0))) {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Enter a product name and category (at least 2 characters), a valid non-negative price, and a whole-number stock quantity/threshold.')));
                      return;
                    }
                    final newProduct = ProductItem(
                      id: DateTime.now().millisecondsSinceEpoch.toString(),
                      name: name,
                      category: category,
                      price: price,
                      inStock: stock > 0,
                      stockCount: stock,
                      threshold: threshold ?? 5,
                    );
                    _addProduct(newProduct);
                    _nameController.clear();
                    _descriptionController.clear();
                    _imageUrlController.clear();
                    _selectedImage = null;
                    _priceController.clear();
                    _categoryController.clear();
                    _stockController.clear();
                    Navigator.pop(context);
                  },
                  child: const Text(
                    'Save',
                    style: TextStyle(
                      color: AdminColors.textDark,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }
}
