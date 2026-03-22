import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../config/api_config.dart';

class ApiService {
  static String? _token;

  static Future<String?> getToken() async {
    if (_token != null) return _token;
    final prefs = await SharedPreferences.getInstance();
    _token = prefs.getString('jwt_token');
    return _token;
  }

  static Future<void> setToken(String token) async {
    _token = token;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('jwt_token', token);
  }

  static Future<void> clearToken() async {
    _token = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('jwt_token');
  }

  static Map<String, String> _headers({bool auth = true}) {
    final headers = {'Content-Type': 'application/json'};
    if (auth && _token != null) {
      headers['Authorization'] = 'Bearer $_token';
    }
    return headers;
  }

  // ─── Auth ──────────────────────────────────────────────────

  static Future<Map<String, dynamic>> signIn(String email, String password) async {
    final response = await http.post(
      Uri.parse('${ApiConfig.authEndpoint}/signin'),
      headers: _headers(auth: false),
      body: jsonEncode({'email': email, 'password': password}),
    );
    final data = jsonDecode(response.body);
    if (response.statusCode == 200) {
      await setToken(data['token']);
    }
    return {'statusCode': response.statusCode, 'body': data};
  }

  static Future<Map<String, dynamic>> signUp({
    required String email,
    required String password,
    required String fullName,
    required String tenantName,
    String? role,
    List<String>? roles,
  }) async {
    final body = <String, dynamic>{
      'email': email,
      'password': password,
      'fullName': fullName,
      'tenantName': tenantName,
    };
    if (role != null) {
      body['role'] = role;
    } else if (roles != null) {
      body['roles'] = roles;
    }

    final response = await http.post(
      Uri.parse('${ApiConfig.authEndpoint}/signup'),
      headers: _headers(auth: false),
      body: jsonEncode(body),
    );
    return {'statusCode': response.statusCode, 'body': jsonDecode(response.body)};
  }

  // ─── Products ──────────────────────────────────────────────

  static Future<List<dynamic>> getProducts() async {
    final response = await http.get(
      Uri.parse(ApiConfig.productsEndpoint),
      headers: _headers(),
    );
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }
    throw Exception('Failed to load products');
  }

  static Future<Map<String, dynamic>> createProduct(Map<String, dynamic> product) async {
    final response = await http.post(
      Uri.parse(ApiConfig.productsEndpoint),
      headers: _headers(),
      body: jsonEncode(product),
    );
    return {'statusCode': response.statusCode, 'body': jsonDecode(response.body)};
  }

  // ─── Retailers ─────────────────────────────────────────────

  static Future<List<dynamic>> getRetailers() async {
    final response = await http.get(
      Uri.parse(ApiConfig.retailersEndpoint),
      headers: _headers(),
    );
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }
    throw Exception('Failed to load retailers');
  }

  static Future<Map<String, dynamic>> createRetailer(Map<String, dynamic> retailer) async {
    final response = await http.post(
      Uri.parse(ApiConfig.retailersEndpoint),
      headers: _headers(),
      body: jsonEncode(retailer),
    );
    return {'statusCode': response.statusCode, 'body': jsonDecode(response.body)};
  }

  // ─── Orders ────────────────────────────────────────────────

  static Future<List<dynamic>> getOrders() async {
    final response = await http.get(
      Uri.parse(ApiConfig.ordersEndpoint),
      headers: _headers(),
    );
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }
    throw Exception('Failed to load orders');
  }

  static Future<Map<String, dynamic>> createOrder(Map<String, dynamic> order) async {
    final response = await http.post(
      Uri.parse(ApiConfig.ordersEndpoint),
      headers: _headers(),
      body: jsonEncode(order),
    );
    return {'statusCode': response.statusCode, 'body': jsonDecode(response.body)};
  }

}

