import 'dart:convert';
import 'package:http/http.dart' as http;

/// Central API configuration. Run with --dart-define=API_BASE_URL=https://your-api.example.com.
/// Android emulator can use http://10.0.2.2:8000; iOS simulator/web use localhost as appropriate.
class BcApiClient {
  BcApiClient._();
  static final BcApiClient instance = BcApiClient._();
  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL', defaultValue: 'http://localhost:8000',
  );
  final http.Client _client = http.Client();
  String? _token;
  void setToken(String? token) => _token = token;
  bool get hasToken => _token != null && _token!.isNotEmpty;
  Future<bool> isBackendAvailable() async { try { final health = await getJson('/api/health'); return health['success'] == true; } catch (_) { return false; } }
  Uri _uri(String path, [Map<String, String>? query]) =>
      Uri.parse('$baseUrl${path.startsWith('/') ? path : '/$path'}')
          .replace(queryParameters: query);

  Future<Map<String, dynamic>> getJson(String path, {Map<String, String>? query}) async {
    final response = await _client.get(_uri(path, query), headers: {'Accept': 'application/json'}).timeout(const Duration(seconds: 8));
    return _decode(response);
  }
  Future<Map<String, dynamic>> postJson(String path, Map<String, dynamic> body, {String? token}) async {
    final response = await _client.post(_uri(path), headers: _headers(token ?? _token), body: jsonEncode(body)).timeout(const Duration(seconds: 15));
    return _decode(response);
  }
  Future<Map<String, dynamic>> putJson(String path, Map<String, dynamic> body) async {
    final response = await _client.put(_uri(path), headers: _headers(_token), body: jsonEncode(body)).timeout(const Duration(seconds: 15));
    return _decode(response);
  }
  Future<Map<String, dynamic>> deleteJson(String path) async {
    final response = await _client.delete(_uri(path), headers: _headers(_token)).timeout(const Duration(seconds: 15));
    return _decode(response);
  }
  Future<Map<String, dynamic>> uploadImage(List<int> bytes, String filename) async {
    final request = http.MultipartRequest('POST', _uri('/api/foods/upload-image'));
    if (_token != null && _token!.isNotEmpty) request.headers['Authorization'] = 'Bearer $_token';
    request.files.add(http.MultipartFile.fromBytes('image', bytes, filename: filename));
    final streamed = await request.send().timeout(const Duration(seconds: 30));
    final response = await http.Response.fromStream(streamed);
    return _decode(response);
  }
  Future<Map<String, dynamic>> _decode(http.Response response) {
    final dynamic decoded = response.body.isEmpty ? <String, dynamic>{} : jsonDecode(response.body);
    final data = decoded is Map<String, dynamic> ? decoded : <String, dynamic>{};
    if (response.statusCode < 200 || response.statusCode >= 300 || data['success'] == false) {
      throw BcApiException(data['message']?.toString() ?? 'API request failed (${response.statusCode})');
    }
    return Future.value(data);
  }
  Map<String, String> _headers(String? token) => {
    'Accept': 'application/json', 'Content-Type': 'application/json',
    if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
  };
}
class BcApiException implements Exception {
  final String message;
  const BcApiException(this.message);
  @override String toString() => message;
}
