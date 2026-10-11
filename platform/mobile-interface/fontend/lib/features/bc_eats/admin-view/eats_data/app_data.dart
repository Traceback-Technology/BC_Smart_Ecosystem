//Data Model blueprint for the vendor data and product items
//Structure of the data is defined here to ensure consistency when fetching and using the data in the application.

class VendorData{
  final String vendorName;
  final List<ProductItem> products;
  final List<Map<String, dynamic>> incomingOrders; // List of incoming orders for the vendor, each order represented as a map of key-value pairs

  VendorData({required this.vendorName, 
              required this.products, 
              required this.incomingOrders});

// Factory constructor to create a VendorData instance from JSON data: raw JSON map is converted into a VendorData object,
// ensuring that the data structure is maintained and can be easily used within the application.
  factory VendorData.fromJson(Map<String, dynamic> json) {
    //extract raw product list from Json map
    var productsList = json['products'] as List ?? [];
    //iterate through list & convert each product map into a ProductItem object using the fromJson factory constructor
    List<ProductItem> parsedProducts = productsList.map((productList) => ProductItem.fromJson(productList)).toList();

    var ordersList = json['incomingOrders'] as List ?? [];
    List<Map<String, dynamic>> parsedOrders = List<Map<String, dynamic>>.from(ordersList);

    //returns fully constructed VendorData object with vendor name and list of ProductItem objects
    return VendorData(
      vendorName: json['vendorName'] ?? '',
      products: parsedProducts,
      incomingOrders: parsedOrders,
    );
  }
}

class ProductItem {
  final String productId;
  final String productName;
  final String category;
  final String productDescription;
  final double productPrice;
  final bool inStock;
  final int quantity;
  final int threshold;

  ProductItem({required this.productId, 
              required this.productName, 
              required this.category, 
              required this.productDescription, 
              required this.productPrice, 
              required this.inStock, 
              required this.quantity, 
              required this.threshold });

  factory ProductItem.fromJson(Map<String, dynamic> json) {
    return ProductItem(
      productId: json['productId']?.toString() ?? '',
      productName: json['productName'] ?? '',
      category: json['category'] ?? 'Uncategorised',
      productDescription: json['productDescription'] ?? '',
      productPrice: (json['productPrice'] as num?)?.toDouble() ?? 0.0,
      inStock: json['inStock'] ?? false,
      quantity: json['quantity'] ?? 0,
      threshold: json['threshold'] ?? 0,
    );
  }

  //copyWith methosd to create a new instance of ProductItem with updated values while keeping the original instance unchanged
  //Assists when updating in or out of stock status, quantity, or other attributes without mutating the original object.
  ProductItem copyWith({
    String? productId,
    String? productName,
    String? category,
    String? productDescription,
    double? productPrice,
    bool? inStock,
    int? quantity,
    int? threshold,
  }) {
    return ProductItem(
      productId: productId ?? this.productId,
      productName: productName ?? this.productName,
      category: category ?? this.category,
      productDescription: productDescription ?? this.productDescription,
      productPrice: productPrice ?? this.productPrice,
      inStock: inStock ?? this.inStock,
      quantity: quantity ?? this.quantity,
      threshold: threshold ?? this.threshold,
    );
  }
}