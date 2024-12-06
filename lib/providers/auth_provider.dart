import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../services/api_service.dart';
import '../models/user.dart';

class AuthProvider with ChangeNotifier {
  final ApiService _apiService = ApiService();
  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  bool _isAuthenticated = false;
  User? _user;

  bool get isAuthenticated => _isAuthenticated;
  User? get user => _user;
  String? get username => _user?.username;
  ApiService get apiService => _apiService;

  Future<void> login(String username, String password) async {
    try {
      // Clear previous state
      _isAuthenticated = false;
      _user = null;

      // Attempt login
      final loginResult = await _apiService.login(username, password);
      
      if (loginResult['message'] == 'Logged In' && loginResult['user_details'] != null) {
        // Store credentials securely
        await _storage.write(key: 'username', value: username);
        await _storage.write(key: 'password', value: password);
        
        // Create user object with login information
        _user = User(
          username: username,
          lastLogin: DateTime.now().toString(),
          ipAddress: _apiService.userIp ?? '127.0.0.1',
        );
        
        _isAuthenticated = true;
        notifyListeners();
      } else {
        throw Exception('Invalid login response');
      }
    } catch (e) {
      _isAuthenticated = false;
      _user = null;
      notifyListeners();

      // Provide more specific error messages
      if (e.toString().contains('Permission denied')) {
        throw Exception('Authentication failed: Invalid credentials or insufficient permissions.');
      } else if (e.toString().contains('Server error')) {
        throw Exception('Server error: Unable to process login request. Please try again later.');
      } else if (e.toString().contains('SocketException') || e.toString().contains('Connection refused')) {
        throw Exception('Network error: Unable to connect to server. Please check your internet connection.');
      } else {
        throw Exception('Login failed: ${e.toString()}');
      }
    }
  }

  Future<void> logout() async {
    await _storage.delete(key: 'username');
    await _storage.delete(key: 'password');
    _apiService.updateSessionCookie(null);
    _user = null;
    _isAuthenticated = false;
    notifyListeners();
  }

  Future<void> checkAuthStatus() async {
    final username = await _storage.read(key: 'username');
    final password = await _storage.read(key: 'password');
    
    if (username != null && password != null) {
      try {
        // Re-authenticate with stored credentials
        await login(username, password);
      } catch (e) {
        // Error re-authenticating, clear credentials
        await logout();
      }
    } else {
      _isAuthenticated = false;
      _user = null;
      notifyListeners();
    }
  }
}
