import '../models/bc_eats_product.dart';

abstract interface class BcEatsProductRepository {
  Future<List<BcEatsProduct>> fetchProducts();

  Future<BcEatsProduct?> findProductById(String productId);
}
