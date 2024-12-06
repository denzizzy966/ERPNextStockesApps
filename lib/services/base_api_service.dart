import 'package:dio/dio.dart';
import 'package:dio_cache_interceptor/dio_cache_interceptor.dart';
import 'package:dio_smart_retry/dio_smart_retry.dart';

class BaseApiService {
  final Dio _dio = Dio();
  final String baseUrl = 'https://halosocia.com';
  String? _sessionId;

  // Cache options
  final _cacheOptions = CacheOptions(
    store: MemCacheStore(),
    policy: CachePolicy.refreshForceCache,
    hitCacheOnErrorExcept: [401, 403], // Don't cache error responses except auth errors
    maxStale: const Duration(days: 1), // Maximum age of cached response
    priority: CachePriority.normal,
  );

  BaseApiService() {
    _dio.options.baseUrl = baseUrl;
    _dio.options.validateStatus = (status) => status! < 500;
    _dio.options.connectTimeout = const Duration(seconds: 30);
    _dio.options.receiveTimeout = const Duration(seconds: 30);
    _dio.options.sendTimeout = const Duration(seconds: 30);

    // Add logging interceptor
    _dio.interceptors.add(LogInterceptor(
      requestBody: true,
      responseBody: true,
      error: true,
      requestHeader: true,
      responseHeader: true,
    ));

    // Add retry interceptor
    _dio.interceptors.add(RetryInterceptor(
      dio: _dio,
      logPrint: print,
      retries: 3,
      retryDelays: const [
        Duration(seconds: 1),
        Duration(seconds: 2),
        Duration(seconds: 3),
      ],
    ));

    // Add cache interceptor
    _dio.interceptors.add(DioCacheInterceptor(options: _cacheOptions));

    // Add session cookie interceptor
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
          final sidCookie = cookies.firstWhere(
            (cookie) => cookie.startsWith('sid='),
            orElse: () => '',
          );
          
          if (sidCookie.isNotEmpty && !sidCookie.contains('sid=Guest')) {
            _sessionId = sidCookie.split(';').first;
            updateSessionCookie(_sessionId);
          }
        }
        return handler.next(response);
      },
      onError: (error, handler) {
        // Handle network errors
        if (error.type == DioExceptionType.connectionTimeout ||
            error.type == DioExceptionType.sendTimeout ||
            error.type == DioExceptionType.receiveTimeout) {
          return handler.next(
            DioException(
              requestOptions: error.requestOptions,
              error: 'Network timeout. Please check your connection.',
              type: error.type,
            ),
          );
        }
        return handler.next(error);
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
    if (_sessionId == null) return;

    try {
      // Get current user with cache
      final userResponse = await _dio.get(
        '/api/method/frappe.auth.get_logged_user',
        options: Options(extra: {
          'cache': true,
          'maxAge': const Duration(minutes: 5),
        }),
      );
      
      if (userResponse.data == null || userResponse.data['message'] == null) {
        throw Exception('Unable to verify user permissions');
      }

      final username = userResponse.data['message'];
      
      // Get user roles with cache
      final response = await _dio.get(
        '/api/method/frappe.client.get',
        queryParameters: {
          'doctype': 'User',
          'name': username,
          'fields': '["user_roles"]'
        },
        options: Options(extra: {
          'cache': true,
          'maxAge': const Duration(minutes: 5),
        }),
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
      print('Type: ${error.type}');
      print('Message: ${error.message}');
      print('Status code: ${error.response?.statusCode}');
      print('Response data: ${error.response?.data}');
      
      switch (error.type) {
        case DioExceptionType.connectionTimeout:
        case DioExceptionType.sendTimeout:
        case DioExceptionType.receiveTimeout:
          return Exception('Network timeout. Please check your connection and try again.');
        case DioExceptionType.badResponse:
          final statusCode = error.response?.statusCode;
          final message = error.response?.data?['message'] ?? error.response?.data?['error'] ?? error.message;
          switch (statusCode) {
            case 401:
              return Exception('Unauthorized: Please log in again');
            case 403:
              return Exception('Forbidden: You do not have permission to perform this action');
            case 404:
              return Exception('Not found: The requested resource does not exist');
            case 422:
              return Exception('Validation error: ${message ?? 'Invalid data provided'}');
            default:
              return Exception('Server error: ${message ?? 'Something went wrong'}');
          }
        case DioExceptionType.cancel:
          return Exception('Request cancelled');
        case DioExceptionType.unknown:
          if (error.error is Exception) {
            return error.error as Exception;
          }
          return Exception('An unexpected error occurred: ${error.message}');
        default:
          return Exception('Network error: ${error.message}');
      }
    }
    
    print('Non-Dio error: $error');
    return error is Exception ? error : Exception(error.toString());
  }
}
