import 'base_api_service.dart';

class StockEntryService extends BaseApiService {
  Future<List<dynamic>> getStockEntries() async {
    try {
      await checkPermissions('Stock Entry', ['Stock User', 'Stock Manager']);
      
      final response = await dio.get(
        '/api/resource/Stock Entry',
        queryParameters: {
          'fields': '["name","posting_date","stock_entry_type","total_amount"]',
          'limit_page_length': 'None',
          'order_by': 'creation desc',
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

  Future<Map<String, dynamic>> getStockEntryDetail(String entryId) async {
    try {
      await checkPermissions('Stock Entry', ['Stock User', 'Stock Manager']);
      
      final response = await dio.get('/api/resource/Stock Entry/$entryId');
      if (response.data == null) {
        throw Exception('No data received from the server');
      }
      return response.data;
    } catch (e) {
      throw handleError(e);
    }
  }

  Future<Map<String, dynamic>> createStockEntry(Map<String, dynamic> stockEntryData) async {
    try {
      await checkPermissions('Stock Entry', ['Stock Manager']);
      
      stockEntryData['doctype'] = 'Stock Entry';
      final response = await dio.post(
        '/api/resource/Stock Entry',
        data: stockEntryData,
      );
      return response.data;
    } catch (e) {
      throw handleError(e);
    }
  }

  Future<Map<String, dynamic>> updateStockEntry(String stockEntryName, Map<String, dynamic> stockEntryData) async {
    try {
      await checkPermissions('Stock Entry', ['Stock Manager']);
      
      stockEntryData['doctype'] = 'Stock Entry';
      final response = await dio.put(
        '/api/resource/Stock Entry/$stockEntryName',
        data: stockEntryData,
      );
      return response.data;
    } catch (e) {
      throw handleError(e);
    }
  }

  Future<void> submitStockEntry(String stockEntryName) async {
    try {
      await checkPermissions('Stock Entry', ['Stock Manager']);
      
      final response = await dio.put(
        '/api/resource/Stock Entry/$stockEntryName',
        data: {
          'docstatus': 1,
          'doctype': 'Stock Entry'
        },
      );

      if (response.statusCode != 200) {
        throw Exception('Failed to submit stock entry');
      }
    } catch (e) {
      throw handleError(e);
    }
  }

  Future<void> deleteStockEntry(String stockEntryName) async {
    try {
      await checkPermissions('Stock Entry', ['Stock Manager']);
      await dio.delete('/api/resource/Stock Entry/$stockEntryName');
    } catch (e) {
      throw handleError(e);
    }
  }

  Future<Map<String, dynamic>> getStockLedger() async {
    try {
      await checkPermissions('Stock Ledger Entry', ['Stock User', 'Stock Manager']);
      
      final now = DateTime.now();
      final fromDate = now.subtract(const Duration(days: 30));
      
      final response = await dio.get(
        '/api/resource/Stock Ledger Entry',
        queryParameters: {
          'fields': '["name","item_code","warehouse","posting_date","actual_qty","valuation_rate","stock_value","voucher_type","voucher_no","batch_no","serial_no","company","stock_uom"]',
          'filters': '[["company","=","Halosocia (Demo)"],["posting_date","between",["${fromDate.toString().substring(0, 10)}","${now.toString().substring(0, 10)}"]]]',
          'limit_page_length': 'None',
          'order_by': 'posting_date desc'
        },
      );
      
      return {
        'result': response.data['data'] ?? []
      };
    } catch (e) {
      throw handleError(e);
    }
  }
}
