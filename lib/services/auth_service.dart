import 'package:dio/dio.dart';
import 'base_api_service.dart';

class AuthService extends BaseApiService {
  String? _userIp;

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
      updateSessionCookie(null);

      // First login to get session
      final loginResponse = await dio.post(
        '/api/method/login',
        data: {
          'usr': username,
          'pwd': password,
        },
        options: Options(
          // Ensure we follow redirects and handle cookies
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
          } else {
            throw Exception('Failed to establish authenticated session');
          }
        }
      }
      
      throw Exception('Login failed: Invalid response from server');
    } catch (e) {
      // Clear session on login failure
      updateSessionCookie(null);
      throw handleError(e);
    }
  }

  String? get userIp => _userIp;
}
