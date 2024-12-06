import 'base_api_service.dart';
import '../models/stock_ledger_entry.dart';

class ItemService extends BaseApiService {
  Future<List<dynamic>> getItems() async {
    try {
      await checkPermissions('Item', ['Stock User', 'Stock Manager', 'Item Manager']);
      
      final response = await dio.get(
        '/api/resource/Item',
        queryParameters: {
          'limit_page_length': 'None',
        },
      );
      
      if (response.data == null) {
        throw Exception('No data received from the server');
      }

      return response.data['data'] ?? [];
    } catch (e) {
      throw handleError(e);
    }
  }

  Future<Map<String, dynamic>> createItem(Map<String, dynamic> itemData) async {
    try {
      await checkPermissions('Item', ['Item Manager']);
      
      itemData['doctype'] = 'Item';
      final response = await dio.post(
        '/api/resource/Item',
        data: itemData,
      );
      return response.data;
    } catch (e) {
      throw handleError(e);
    }
  }

  Future<Map<String, dynamic>> updateItem(String itemName, Map<String, dynamic> itemData) async {
    try {
      await checkPermissions('Item', ['Item Manager']);
      
      itemData['doctype'] = 'Item';
      final response = await dio.put(
        '/api/resource/Item/$itemName',
        data: itemData,
      );
      return response.data;
    } catch (e) {
      throw handleError(e);
    }
  }

  Future<void> deleteItem(String itemName) async {
    try {
      await checkPermissions('Item', ['Item Manager']);
      await dio.delete('/api/resource/Item/$itemName');
    } catch (e) {
      throw handleError(e);
    }
  }

  Future<List<dynamic>> getUOMs() async {
    try {
      await checkPermissions('UOM', ['Stock User', 'Stock Manager', 'Item Manager']);
      
      final response = await dio.get(
        '/api/resource/UOM',
        queryParameters: {
          'limit_page_length': 'None',
        },
      );
      
      if (response.data == null) {
        throw Exception('No data received from the server');
      }

      return response.data['data'] ?? [];
    } catch (e) {
      throw handleError(e);
    }
  }

  Future<List<dynamic>> getItemGroups() async {
    try {
      await checkPermissions('Item Group', ['Stock User', 'Stock Manager', 'Item Manager']);
      
      final response = await dio.get(
        '/api/resource/Item Group',
        queryParameters: {
          'limit_page_length': 'None',
        },
      );
      
      if (response.data == null) {
        throw Exception('No data received from the server');
      }

      return response.data['data'] ?? [];
    } catch (e) {
      throw handleError(e);
    }
  }

  Future<Map<String, dynamic>> createItemGroup(Map<String, dynamic> groupData) async {
    try {
      await checkPermissions('Item Group', ['Item Manager']);
      
      groupData['doctype'] = 'Item Group';
      final response = await dio.post(
        '/api/resource/Item Group',
        data: groupData,
      );
      return response.data;
    } catch (e) {
      throw handleError(e);
    }
  }

  Future<Map<String, dynamic>> updateItemGroup(String groupName, Map<String, dynamic> groupData) async {
    try {
      await checkPermissions('Item Group', ['Item Manager']);
      
      groupData['doctype'] = 'Item Group';
      final response = await dio.put(
        '/api/resource/Item Group/$groupName',
        data: groupData,
      );
      return response.data;
    } catch (e) {
      throw handleError(e);
    }
  }

  Future<void> deleteItemGroup(String groupName) async {
    try {
      await checkPermissions('Item Group', ['Item Manager']);
      await dio.delete('/api/resource/Item Group/$groupName');
    } catch (e) {
      throw handleError(e);
    }
  }

  Future<List<StockLedgerEntry>> getStockLedgerEntries({
    String? itemCode,
    String? warehouse,
    DateTime? fromDate,
    DateTime? toDate,
  }) async {
    try {
      await checkPermissions('Stock Ledger Entry', ['Stock User', 'Stock Manager']);

      final Map<String, dynamic> queryParameters = {
        'fields': [
          'name',
          'item_code',
          'warehouse',
          'posting_date',
          'actual_qty',
          'valuation_rate',
          'stock_value',
          'voucher_type',
          'voucher_no',
          'batch_no',
          'serial_no',
          'company',
          'stock_uom'
        ].join(','),
        'limit_page_length': 'None',
      };

      if (itemCode != null) {
        queryParameters['filters'] = '[["item_code","=","$itemCode"]]';
      }
      if (warehouse != null) {
        final warehouseFilter = '[["warehouse","=","$warehouse"]]';
        queryParameters['filters'] = queryParameters.containsKey('filters')
            ? queryParameters['filters'].replaceAll(']', ',$warehouseFilter]')
            : warehouseFilter;
      }
      if (fromDate != null) {
        final dateFilter = '[["posting_date",">=","${fromDate.toIso8601String().split('T')[0]}"]]';
        queryParameters['filters'] = queryParameters.containsKey('filters')
            ? queryParameters['filters'].replaceAll(']', ',$dateFilter]')
            : dateFilter;
      }
      if (toDate != null) {
        final dateFilter = '[["posting_date","<=","${toDate.toIso8601String().split('T')[0]}"]]';
        queryParameters['filters'] = queryParameters.containsKey('filters')
            ? queryParameters['filters'].replaceAll(']', ',$dateFilter]')
            : dateFilter;
      }

      final response = await dio.get(
        '/api/resource/Stock Ledger Entry',
        queryParameters: queryParameters,
      );

      if (response.data == null) {
        throw Exception('No data received from the server');
      }

      final List<dynamic> data = response.data['data'] ?? [];
      return data.map((entry) => StockLedgerEntry.fromJson(entry)).toList();
    } catch (e) {
      throw handleError(e);
    }
  }

  Future<StockLedgerEntry> getStockLedgerEntry(String name) async {
    try {
      await checkPermissions('Stock Ledger Entry', ['Stock User', 'Stock Manager']);

      final response = await dio.get(
        '/api/resource/Stock Ledger Entry/$name',
      );

      if (response.data == null) {
        throw Exception('No data received from the server');
      }

      return StockLedgerEntry.fromJson(response.data);
    } catch (e) {
      throw handleError(e);
    }
  }
}
