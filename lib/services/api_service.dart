import 'auth_service.dart';
import 'stock_entry_service.dart';
import 'item_service.dart';
import 'warehouse_service.dart';

class ApiService {
  static final ApiService _instance = ApiService._internal();
  
  factory ApiService() {
    return _instance;
  }

  ApiService._internal();

  // Lazy initialization of services
  AuthService? _authService;
  StockEntryService? _stockEntryService;
  ItemService? _itemService;
  WarehouseService? _warehouseService;

  // Getters that ensure single instances
  AuthService get auth {
    _authService ??= AuthService();
    return _authService!;
  }

  StockEntryService get stockEntry {
    _stockEntryService ??= StockEntryService();
    return _stockEntryService!;
  }

  ItemService get item {
    _itemService ??= ItemService();
    return _itemService!;
  }

  WarehouseService get warehouse {
    _warehouseService ??= WarehouseService();
    return _warehouseService!;
  }

  // Auth methods
  Future<Map<String, dynamic>> login(String username, String password) => 
      auth.login(username, password);
  
  Future<Map<String, dynamic>> getUserDetails(String username) => 
      auth.getUserDetails(username);
  
  String? get userIp => auth.userIp;

  // Stock Entry methods
  Future<List<dynamic>> getStockEntries() => 
      stockEntry.getStockEntries();
  
  Future<Map<String, dynamic>> getStockEntryDetail(String entryId) => 
      stockEntry.getStockEntryDetail(entryId);
  
  Future<Map<String, dynamic>> createStockEntry(Map<String, dynamic> data) => 
      stockEntry.createStockEntry(data);
  
  Future<Map<String, dynamic>> updateStockEntry(String name, Map<String, dynamic> data) => 
      stockEntry.updateStockEntry(name, data);
  
  Future<void> submitStockEntry(String name) => 
      stockEntry.submitStockEntry(name);
  
  Future<void> deleteStockEntry(String name) => 
      stockEntry.deleteStockEntry(name);
  
  Future<Map<String, dynamic>> getStockLedger() => 
      stockEntry.getStockLedger();

  // Item methods
  Future<List<dynamic>> getItems() => 
      item.getItems();
  
  Future<Map<String, dynamic>> createItem(Map<String, dynamic> data) => 
      item.createItem(data);
  
  Future<Map<String, dynamic>> updateItem(String name, Map<String, dynamic> data) => 
      item.updateItem(name, data);
  
  Future<void> deleteItem(String name) => 
      item.deleteItem(name);
  
  Future<List<dynamic>> getUOMs() => 
      item.getUOMs();
  
  Future<List<dynamic>> getItemGroups() => 
      item.getItemGroups();
  
  Future<Map<String, dynamic>> createItemGroup(Map<String, dynamic> data) => 
      item.createItemGroup(data);
  
  Future<Map<String, dynamic>> updateItemGroup(String name, Map<String, dynamic> data) => 
      item.updateItemGroup(name, data);
  
  Future<void> deleteItemGroup(String name) => 
      item.deleteItemGroup(name);

  // Warehouse methods
  Future<List<dynamic>> getWarehouses() => 
      warehouse.getWarehouses();
  
  Future<Map<String, dynamic>> createWarehouse(Map<String, dynamic> data) => 
      warehouse.createWarehouse(data);
  
  Future<Map<String, dynamic>> updateWarehouse(String name, Map<String, dynamic> data) => 
      warehouse.updateWarehouse(name, data);
  
  Future<void> deleteWarehouse(String name) => 
      warehouse.deleteWarehouse(name);
  
  Future<List<dynamic>> getBins() => 
      warehouse.getBins();
  
  Future<Map<String, dynamic>> getBinDetail(String name) => 
      warehouse.getBinDetail(name);

  // Method to update session across all services
  void updateSessionCookie(String? sessionId) {
    auth.updateSessionCookie(sessionId);
    stockEntry.updateSessionCookie(sessionId);
    item.updateSessionCookie(sessionId);
    warehouse.updateSessionCookie(sessionId);
  }
}

// Create a global instance for easy access
final apiService = ApiService();
