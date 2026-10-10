//Data Model blueprint for the vendor data and product items
//Structure of the data is defined here to ensure consistency when fetching and using the data in the application.

class VendorData{
  final String vendorName;
  final List<ProductItem> products;

  VendorData({required this.vendorName, required this.products});

// Factory constructor to create a VendorData instance from JSON data: raw JSON map is converted into a VendorData object,
// ensuring that the data structure is maintained and can be easily used within the application.
  factory VendorData.fromJson(Map<String, dynamic> json) {
    //extract raw product list from Json map
    var productsList = json['products'] as List;

    //iterate through list & convert each product map into a ProductItem object using the fromJson factory constructor
    List<ProductItem> parsedProducts = productsList.map((productList) => ProductItem.fromJson(productList)).toList();

    //returns fully constructed VendorData object with vendor name and list of ProductItem objects
    return VendorData(
      vendorName: json['vendorName'] ?? '',
      products: parsedProducts,
    );
  }
}


class ProductItem {
  final String productId;
  final String productName;
  final String productDescription;
  final double productPrice;
  final int quantity;

  ProductItem({required this.productId, required this.productName, required this.productDescription, 
          required this.productPrice, required this.quantity});

  factory ProductItem.fromJson(Map<String, dynamic> json) {
    return ProductItem(
      productId: json['productId'] ?? '',
      productName: json['productName'] ?? '',
      productDescription: json['productDescription'] ?? '',
      productPrice: (json['productPrice'] as num?)?.toDouble() ?? 0.0,
      quantity: json['quantity'] ?? 0,
    );
  }
}