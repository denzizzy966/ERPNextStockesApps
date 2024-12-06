import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'base_api_service.dart';

class AuthService extends BaseApiService {
  String? _userIp;
  static const String _sessionKey = 'session_cookie';
  late SharedPreferences _prefs;

  AuthService() {
    _initPrefs();
  }

  Future<void> _initPrefs() async {
    _prefs = await SharedPreferences.getInstance();
    final savedSession = _prefs.getString(_sessionKey);
    if (savedSession != null) {
      updateSessionCookie(savedSession);
    }
  }

  Future<Map<String, dynamic>> getUserDetails(String username) async {
    try {
      final response = await dio.get(
        '/api/method/frappe.client.get',
        queryParameters: {
          'doctype': 'User',
          'name': username,
          'fields': '["name","full_name","user_type","user_roles","last_ip"]'
        },
      );
      
      if (response.data == null) {
        throw Exception('No data received from the server');
      }
      
      // Update user's IP
      if (response.data['message'] != null) {
        _userIp = response.data['message']['last_ip'];
      }
      
      return response.data;
    } catch (e) {
      throw handleError(e);
    }
  }

  Future<Map<String, dynamic>> login(String username, String password) async {
    try {
      // Clear any existing session
      await logout();

      // First login to get session
      final loginResponse = await dio.post(
        '/api/method/login',
        data: {
          'usr': username,
          'pwd': password,
        },
        options: Options(
          followRedirects: true,
          validateStatus: (status) => status! < 500,
          headers: {
            'Accept': 'application/json',
            'Content-Type': 'application/x-www-form-urlencoded',
          },
        ),
      );
      
      if (loginResponse.statusCode == 403) {
        throw Exception('Invalid credentials or insufficient permissions');
      }
      
      if (loginResponse.data['message'] == 'Logged In') {
        // Get session cookie from response
        final cookies = loginResponse.headers['set-cookie'];
        if (cookies != null && cookies.isNotEmpty) {
          final sidCookie = cookies.firstWhere(
            (cookie) => cookie.startsWith('sid=') && !cookie.contains('Guest'),
            orElse: () => '',
          );
          
          if (sidCookie.isNotEmpty) {
            final sessionId = sidCookie.split(';').first;
            // Save session to persistent storage
            await _prefs.setString(_sessionKey, sessionId);
            updateSessionCookie(sessionId);
          }
        }

        // Get user details including roles and IP
        final userResponse = await dio.get(
          '/api/method/frappe.auth.get_logged_user'
        );
        
        if (userResponse.data != null) {
          final userDetails = await getUserDetails(userResponse.data['message']);
          
          // Verify we have a valid session
          if (userDetails['message'] != null && userDetails['message']['user_type'] != 'Guest') {
            return {
              ...loginResponse.data,
              'user_details': userDetails['message']
            };
          }
        }
        throw Exception('Failed to establish authenticated session');
      }
      
      throw Exception('Login failed: Invalid response from server');
    } catch (e) {
      await logout(); // Clear session on login failure
      throw handleError(e);
    }
  }

  Future<void> logout() async {
    try {
      await _prefs.remove(_sessionKey);
      updateSessionCookie(null);
      await dio.get('/api/method/logout');
    } catch (e) {
      print('Error during logout: $e');
    }
  }

  String? get userIp => _userIp;
}
