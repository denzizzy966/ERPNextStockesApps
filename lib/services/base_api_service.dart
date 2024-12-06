import 'package:dio/dio.dart';

class BaseApiService {
  final Dio _dio = Dio();
  final String baseUrl = 'https://halosocia.com';
  String? _sessionId;

  BaseApiService() {
    _dio.options.baseUrl = baseUrl;
    _dio.options.validateStatus = (status) => status! < 500;
    _dio.interceptors.add(LogInterceptor(
      requestBody: true,
      responseBody: true,
      error: true,
      requestHeader: true,
      responseHeader: true,
    ));

    // Add interceptor to handle session cookie
    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) {
        if (_sessionId != null) {
          options.headers['Cookie'] = _sessionId;
        }
        return handler.next(options);
      },
      onResponse: (response, handler) {
        final cookies = response.headers['set-cookie'];
        if (cookies != null && cookies.isNotEmpty) {
          // Look for any sid cookie, including Guest
          final sidCookie = cookies.firstWhere(
            (cookie) => cookie.startsWith('sid='),
            orElse: () => '',
          );
          
          // Only update if it's not a Guest session
          if (sidCookie.isNotEmpty && !sidCookie.contains('sid=Guest')) {
            _sessionId = sidCookie.split(';').first;
            updateSessionCookie(_sessionId);
          }
        }
        return handler.next(response);
      },
    ));
  }

  Dio get dio => _dio;

  void updateSessionCookie(String? sessionId) {
    _sessionId = sessionId;
    if (sessionId != null) {
      _dio.options.headers['Cookie'] = sessionId;
    } else {
      _dio.options.headers.remove('Cookie');
    }
  }

  // Permission check helper
  Future<void> checkPermissions(String doctype, List<String> requiredRoles) async {
    // Skip permission check if no session (during login)
    if (_sessionId == null) return;

    try {
      // Get current user
      final userResponse = await _dio.get('/api/method/frappe.auth.get_logged_user');
      if (userResponse.data == null || userResponse.data['message'] == null) {
        throw Exception('Unable to verify user permissions');
      }

      final username = userResponse.data['message'];
      
      // Get user roles
      final response = await _dio.get(
        '/api/method/frappe.client.get',
        queryParameters: {
          'doctype': 'User',
          'name': username,
          'fields': '["user_roles"]'
        },
      );

      if (response.data == null || 
          response.data['message'] == null || 
          response.data['message']['user_roles'] == null) {
        throw Exception('Permission denied: Unable to verify roles');
      }

      final userRoles = List<String>.from(response.data['message']['user_roles']);
      final hasRole = requiredRoles.any((role) => userRoles.contains(role));

      if (!hasRole) {
        throw Exception('Permission denied: You do not have the required roles to access $doctype');
      }
    } catch (e) {
      throw handleError(e);
    }
  }

  Exception handleError(dynamic error) {
    if (error is DioException) {
      print('DioError Details:');
      print('- Type: ${error.type}');
      print('- Message: ${error.message}');
      print('- Response: ${error.response?.data}');
      
      if (error.response?.statusCode == 403) {
        // Check if session is expired or invalid
        if (_sessionId != null) {
          // Clear invalid session
          updateSessionCookie(null);
        }
        return Exception('Permission denied: Please check your access rights or try logging in again');
      }
      
      if (error.response?.statusCode == 500) {
        return Exception('Server error: The operation could not be completed. Please try again later.');
      }
      
      if (error.response != null) {
        var errorMessage = '';
        
        if (error.response?.data is String) {
          errorMessage = error.response?.data;
        } else if (error.response?.data is Map) {
          errorMessage = error.response?.data['_server_messages'] ?? 
                        error.response?.data['message'] ?? 
                        error.response?.data['exc_type'] ?? 
                        error.response?.data.toString();
                        
          if (errorMessage.contains('{') && errorMessage.contains('}')) {
            try {
              errorMessage = errorMessage.replaceAll('\\"', '"');
              errorMessage = errorMessage.replaceAll('\\\\', '\\');
              
              final start = errorMessage.indexOf('"message":');
              if (start != -1) {
                final messageStart = errorMessage.indexOf('"', start + 10) + 1;
                final messageEnd = errorMessage.indexOf('"', messageStart);
                if (messageStart != -1 && messageEnd != -1) {
                  errorMessage = errorMessage.substring(messageStart, messageEnd);
                }
              }
            } catch (e) {
              print('Error parsing error message: $e');
            }
          }
        }
        
        return Exception(errorMessage);
      }
      return Exception(error.message ?? 'An error occurred');
    }
    return Exception('An unexpected error occurred');
  }
}
