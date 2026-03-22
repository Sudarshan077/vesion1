import 'package:flutter/material.dart';
import '../services/api_service.dart';

class AuthProvider with ChangeNotifier {
  bool _isAuthenticated = false;
  bool _isLoading = false;
  String? _email;
  String? _fullName;
  String? _tenantName;
  List<String>? _roles;
  String? _error;

  bool get isAuthenticated => _isAuthenticated;
  bool get isLoading => _isLoading;
  String? get email => _email;
  String? get fullName => _fullName;
  String? get tenantName => _tenantName;
  List<String>? get roles => _roles;
  String? get error => _error;

  bool get isAdmin => _roles?.contains('ROLE_ADMIN') ?? false;
  bool get isRetailer => _roles?.contains('ROLE_RETAILER') ?? false;
  bool get isCustomer => _roles?.contains('ROLE_CUSTOMER') ?? false;

  Future<void> checkAuth() async {
    final token = await ApiService.getToken();
    _isAuthenticated = token != null;
    notifyListeners();
  }

  Future<bool> signIn(String email, String password) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final result = await ApiService.signIn(email, password);
      if (result['statusCode'] == 200) {
        _isAuthenticated = true;
        _email = result['body']['email'];
        _fullName = result['body']['fullName'];
        _tenantName = result['body']['tenantName'];
        _roles = List<String>.from(result['body']['roles'] ?? []);
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _error = result['body']['message'] ?? 'Login failed';
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _error = 'Connection error. Is the server running?';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> signUp({
    required String email,
    required String password,
    required String fullName,
    required String tenantName,
    String? role,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final result = await ApiService.signUp(
        email: email,
        password: password,
        fullName: fullName,
        tenantName: tenantName,
        role: role,
      );
      _isLoading = false;
      if (result['statusCode'] == 200) {
        notifyListeners();
        return true;
      } else {
        _error = result['body']['message'] ?? 'Registration failed';
        notifyListeners();
        return false;
      }
    } catch (e) {
      _error = 'Connection error. Is the server running?';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> signOut() async {
    await ApiService.clearToken();
    _isAuthenticated = false;
    _email = null;
    _fullName = null;
    _tenantName = null;
    _roles = null;
    notifyListeners();
  }
}

