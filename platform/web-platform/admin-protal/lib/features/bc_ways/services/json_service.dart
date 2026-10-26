import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;

/// Thin wrapper around asset loading + JSON decoding for the data files
/// under assets/bc_ways/data/.
class JsonService {
  const JsonService();
  static const _base = 'assets/bc_ways/data';

  Future<List<dynamic>> _loadList(String filename) async {
    final raw = await rootBundle.loadString('$_base/$filename');
    return jsonDecode(raw) as List<dynamic>;
  }

  Future<List<dynamic>> loadNodes() => _loadList('nodes.json');
  Future<List<dynamic>> loadEdges() => _loadList('edges.json');
  Future<List<dynamic>> loadDestinations() => _loadList('destinations.json');
  Future<List<dynamic>> loadCategories() => _loadList('categories.json');
}
