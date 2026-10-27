import '../../../core/bc_api_client.dart';
import '../models/bc_eats_product.dart';
import 'bc_eats_product_repository.dart';
import 'mock_bc_eats_product_repository.dart';

/// Uses admin-managed database products when available. Offline or an empty
/// database intentionally falls back to the bundled demo menu.
class ApiBcEatsProductRepository implements BcEatsProductRepository {
  ApiBcEatsProductRepository({BcApiClient? api}) : _api = api ?? BcApiClient.instance;
  final BcApiClient _api;
  @override
  Future<List<BcEatsProduct>> fetchProducts() async {
    try {
      final response = await _api.getJson('/api/foods', query: {'available': 'all'});
      final rows = response['data'];
      if (rows is List) {
        final products = rows.whereType<Map<String, dynamic>>()
          .map(BcEatsProduct.fromJson).where((p) => p.id.isNotEmpty && p.name.isNotEmpty).toList();
        if (products.isNotEmpty) return products;
      }
    } catch (_) {
      // Offline / unreachable API: retain a usable local preview.
    }
    return MockBcEatsProductRepository.instance.fetchProducts();
  }
  @override
  Future<BcEatsProduct?> findProductById(String productId) async {
    final products = await fetchProducts();
    for (final product in products) { if (product.id == productId) return product; }
    return null;
  }
}
