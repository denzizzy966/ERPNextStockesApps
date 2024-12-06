import 'dart:convert';
import 'package:http/http.dart' as http;

class ERPNextService {
  final String baseUrl;
  String? _sessionId;
  String? _csrfToken;
  Map<String, List<String>> _userPermissions = {};

  ERPNextService({
    required this.baseUrl,
  });

  Map<String, String> get headers {
    final Map<String, String> headers = {
      'Accept': 'application/json',
      'Content-Type': 'application/json',
    };

    if (_sessionId != null) {
      headers['Cookie'] = _sessionId!;
    }

    if (_csrfToken != null) {
      headers['X-Frappe-CSRF-Token'] = _csrfToken!;
    }

    return headers;
  }

  Future<void> authenticate(String username, String password) async {
    try {
      // Clear any existing session
      _sessionId = null;
      _csrfToken = null;
      _userPermissions.clear();

      // First authenticate with basic credentials
      final loginResponse = await http.post(
        Uri.parse('$baseUrl/api/method/login'),
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'usr': username,
          'pwd': password,
        }),
      );

      if (loginResponse.statusCode != 200) {
        throw Exception('Authentication failed: ${loginResponse.statusCode}');
      }

      final loginData = json.decode(loginResponse.body);
      if (loginData['message'] != 'Logged In') {
        throw Exception('Login failed: ${loginData['message']}');
      }

      // Extract and store session cookie
      final cookies = loginResponse.headers['set-cookie'];
      if (cookies == null || cookies.isEmpty) {
        throw Exception('No session cookie received');
      }

      _sessionId = cookies.split(';').first;

      // Now get the CSRF token
      final tokenResponse = await http.get(
        Uri.parse('$baseUrl/api/method/frappe.auth.get_csrf_token'),
        headers: headers,
      );

      if (tokenResponse.statusCode != 200) {
        throw Exception('Failed to get CSRF token');
      }

      // Store CSRF token
      final tokenData = json.decode(tokenResponse.body);
      if (tokenData['message'] != null) {
        _csrfToken = tokenData['message'];
      } else {
        throw Exception('No CSRF token received');
      }

      // Get user info
      final userResponse = await http.get(
        Uri.parse('$baseUrl/api/method/frappe.auth.get_logged_user'),
        headers: headers,
      );

      if (userResponse.statusCode != 200) {
        throw Exception('Failed to get user info');
      }

      final userData = json.decode(userResponse.body);
      if (userData['message'] == null) {
        throw Exception('No user data received');
      }

      // Get user roles
      final rolesResponse = await http.get(
        Uri.parse('$baseUrl/api/method/frappe.auth.get_roles'),
        headers: headers,
      );

      if (rolesResponse.statusCode != 200) {
        throw Exception('Failed to get user roles');
      }

      final rolesData = json.decode(rolesResponse.body);
      final roles = List<String>.from(rolesData['message'] ?? []);

      // Get permissions for each role
      for (final role in roles) {
        await _fetchRolePermissions(role);
      }

    } catch (e) {
      // Clear session on error
      _sessionId = null;
      _csrfToken = null;
      _userPermissions.clear();
      throw Exception('Error during authentication: $e');
    }
  }

  Future<void> _fetchRolePermissions(String role) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/method/frappe.client.get_list').replace(
          queryParameters: {
            'doctype': 'DocPerm',
            'fields': '["parent", "permlevel", "read", "write", "create", "delete", "submit", "cancel", "amend"]',
            'filters': json.encode([
              ['role', '=', role]
            ])
          }
        ),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final permissions = List<Map<String, dynamic>>.from(data['message'] ?? []);
        
        for (var perm in permissions) {
          final doctype = perm['parent'] as String;
          if (!_userPermissions.containsKey(doctype)) {
            _userPermissions[doctype] = [];
          }
          if (perm['read'] == 1) _userPermissions[doctype]!.add('read');
          if (perm['write'] == 1) _userPermissions[doctype]!.add('write');
          if (perm['create'] == 1) _userPermissions[doctype]!.add('create');
          if (perm['delete'] == 1) _userPermissions[doctype]!.add('delete');
          if (perm['submit'] == 1) _userPermissions[doctype]!.add('submit');
        }
      } else {
        print('Warning: Failed to fetch permissions for role $role: ${response.statusCode}');
      }
    } catch (e) {
      print('Warning: Error fetching permissions for role $role: $e');
    }
  }

  bool hasPermission(String doctype, String permission) {
    return _userPermissions[doctype]?.contains(permission) ?? false;
  }

  // Stock Entry Methods
  Future<List<Map<String, dynamic>>> getStockEntries() async {
    if (!hasPermission('Stock Entry', 'read')) {
      throw Exception('Permission denied: You do not have access to Stock Entry data');
    }

    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/resource/Stock Entry').replace(
          queryParameters: {
            'fields': '["name", "posting_date", "stock_entry_type", "docstatus", "from_warehouse", "to_warehouse"]',
            'limit_page_length': 'None',
            'order_by': 'modified desc'
          }
        ),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return List<Map<String, dynamic>>.from(data['data']);
      } else {
        throw Exception('Failed to load stock entries: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error getting stock entries: $e');
    }
  }

  Future<Map<String, dynamic>> getStockEntryDetail(String entryId) async {
    if (!hasPermission('Stock Entry', 'read')) {
      throw Exception('Permission denied: You do not have access to Stock Entry details');
    }

    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/resource/Stock Entry/$entryId'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['data'];
      } else {
        throw Exception('Failed to load stock entry detail: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error getting stock entry detail: $e');
    }
  }

  Future<Map<String, dynamic>> createStockEntry(Map<String, dynamic> data) async {
    if (!hasPermission('Stock Entry', 'create')) {
      throw Exception('Permission denied: You do not have permission to create Stock Entry');
    }

    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/resource/Stock Entry'),
        headers: headers,
        body: json.encode(data),
      );

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        return responseData['data'];
      } else {
        throw Exception('Failed to create stock entry: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error creating stock entry: $e');
    }
  }

  Future<Map<String, dynamic>> updateStockEntry(String entryId, Map<String, dynamic> data) async {
    if (!hasPermission('Stock Entry', 'write')) {
      throw Exception('Permission denied: You do not have permission to update Stock Entry');
    }

    try {
      final response = await http.put(
        Uri.parse('$baseUrl/api/resource/Stock Entry/$entryId'),
        headers: headers,
        body: json.encode(data),
      );

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        return responseData['data'];
      } else {
        throw Exception('Failed to update stock entry: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error updating stock entry: $e');
    }
  }

  Future<void> submitStockEntry(String entryId) async {
    if (!hasPermission('Stock Entry', 'submit')) {
      throw Exception('Permission denied: You do not have permission to submit Stock Entry');
    }

    try {
      final response = await http.put(
        Uri.parse('$baseUrl/api/resource/Stock Entry/$entryId'),
        headers: headers,
        body: json.encode({'docstatus': 1}),
      );

      if (response.statusCode != 200) {
        throw Exception('Failed to submit stock entry: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error submitting stock entry: $e');
    }
  }

  // Item Methods
  Future<List<Map<String, dynamic>>> getItems() async {
    if (!hasPermission('Item', 'read')) {
      throw Exception('Permission denied: You do not have access to Item data');
    }

    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/resource/Item').replace(
          queryParameters: {
            'fields': '["name", "item_name", "item_code", "item_group", "stock_uom", "description"]',
            'limit_page_length': 'None'
          }
        ),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return List<Map<String, dynamic>>.from(data['data']);
      } else {
        throw Exception('Failed to load items: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error getting items: $e');
    }
  }

  // Warehouse Methods
  Future<List<Map<String, dynamic>>> getWarehouses() async {
    if (!hasPermission('Warehouse', 'read')) {
      throw Exception('Permission denied: You do not have access to Warehouse data');
    }

    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/resource/Warehouse').replace(
          queryParameters: {
            'fields': '["name", "warehouse_name", "warehouse_type", "is_group"]',
            'limit_page_length': 'None'
          }
        ),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return List<Map<String, dynamic>>.from(data['data']);
      } else {
        throw Exception('Failed to load warehouses: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error getting warehouses: $e');
    }
  }

  // Item Group Methods
  Future<List<Map<String, dynamic>>> getItemGroups() async {
    if (!hasPermission('Item Group', 'read')) {
      throw Exception('Permission denied: You do not have access to Item Group data');
    }

    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/resource/Item Group').replace(
          queryParameters: {
            'fields': '["name", "item_group_name", "parent_item_group"]',
            'limit_page_length': 'None'
          }
        ),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return List<Map<String, dynamic>>.from(data['data']);
      } else {
        throw Exception('Failed to load item groups: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error getting item groups: $e');
    }
  }

  // Low Stock Items
  Future<List<Map<String, dynamic>>> getLowStockItems() async {
    if (!hasPermission('Bin', 'read')) {
      throw Exception('Permission denied: You do not have access to stock data');
    }

    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/resource/Bin').replace(
          queryParameters: {
            'fields': '["item_code", "warehouse", "actual_qty", "projected_qty", "reserved_qty", "ordered_qty"]',
            'filters': json.encode([
              ['actual_qty', '<', 'reorder_level']
            ]),
            'limit_page_length': 'None'
          }
        ),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return List<Map<String, dynamic>>.from(data['data']);
      } else {
        throw Exception('Failed to load low stock items: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error getting low stock items: $e');
    }
  }

  // Bin Methods
  Future<List<Map<String, dynamic>>> getAllBins() async {
    if (!hasPermission('Bin', 'read')) {
      throw Exception('Permission denied: You do not have access to Bin data');
    }

    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/resource/Bin').replace(
          queryParameters: {
            'fields': [
              'name',
              'item_code',
              'warehouse',
              'actual_qty',
              'projected_qty',
              'reserved_qty',
              'ordered_qty',
              'planned_qty',
              'indented_qty',
              'stock_value',
              'valuation_rate',
              'stock_uom',
              'modified'
            ].join(','),
            'limit_page_length': 'None'
          }
        ),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return List<Map<String, dynamic>>.from(data['data']);
      } else if (response.statusCode == 500) {
        throw Exception('Server error: Unable to fetch bin data. Please try again later or contact support.');
      } else {
        throw Exception('Failed to load bins: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error getting bins: $e');
    }
  }

  Future<Map<String, dynamic>> getBinDetail(String binName) async {
    if (!hasPermission('Bin', 'read')) {
      throw Exception('Permission denied: You do not have access to Bin details');
    }

    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/resource/Bin/$binName'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['data'];
      } else if (response.statusCode == 500) {
        throw Exception('Server error: Unable to fetch bin details. Please try again later or contact support.');
      } else {
        throw Exception('Failed to load bin detail: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error getting bin detail: $e');
    }
  }
}
