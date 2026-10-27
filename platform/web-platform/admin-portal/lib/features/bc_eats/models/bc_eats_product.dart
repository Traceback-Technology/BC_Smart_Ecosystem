class BcEatsProduct {
  final String id;
  final String name;
  final String description;
  final String category;
  final double price;
  final String imagePath;
  final bool isAvailable;

  const BcEatsProduct({
    required this.id,
    required this.name,
    required this.description,
    required this.category,
    required this.price,
    required this.imagePath,
    this.isAvailable = true,
  });

  String get formattedPrice => 'R${price.toStringAsFixed(2)}';

  factory BcEatsProduct.fromJson(Map<String, dynamic> json) {
    final rawPrice = json['price'];

    return BcEatsProduct(
      id: (json['id'] ?? json['_id'])?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      category: json['category']?.toString() ?? 'Uncategorized',
      price: rawPrice is num
          ? rawPrice.toDouble()
          : double.tryParse(rawPrice?.toString() ?? '') ?? 0.0,
      imagePath: (json['imageUrl'] ?? json['image'] ?? json['imagePath'])?.toString() ?? '',
      isAvailable: (json['available'] ?? json['isAvailable'] ?? json['inStock'] ?? true) == true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'category': category,
      'price': price,
      'imagePath': imagePath,
      'isAvailable': isAvailable,
    };
  }

  BcEatsProduct copyWith({
    String? id,
    String? name,
    String? description,
    String? category,
    double? price,
    String? imagePath,
    bool? isAvailable,
  }) {
    return BcEatsProduct(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      category: category ?? this.category,
      price: price ?? this.price,
      imagePath: imagePath ?? this.imagePath,
      isAvailable: isAvailable ?? this.isAvailable,
    );
  }
}
