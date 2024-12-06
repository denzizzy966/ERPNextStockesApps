import 'base_api_service.dart';

class WarehouseService extends BaseApiService {
  Future<List<dynamic>> getWarehouses() async {
    try {
      await checkPermissions('Warehouse', ['Stock User', 'Stock Manager']);
      
      final response = await dio.get(
        '/api/resource/Warehouse',
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

  Future<Map<String, dynamic>> createWarehouse(Map<String, dynamic> warehouseData) async {
    try {
      await checkPermissions('Warehouse', ['Stock Manager']);
      
      warehouseData['doctype'] = 'Warehouse';
      final response = await dio.post(
        '/api/resource/Warehouse',
        data: warehouseData,
      );
      return response.data;
    } catch (e) {
      throw handleError(e);
    }
  }

  Future<Map<String, dynamic>> updateWarehouse(String warehouseName, Map<String, dynamic> warehouseData) async {
    try {
      await checkPermissions('Warehouse', ['Stock Manager']);
      
      warehouseData['doctype'] = 'Warehouse';
      final response = await dio.put(
        '/api/resource/Warehouse/$warehouseName',
        data: warehouseData,
      );
      return response.data;
    } catch (e) {
      throw handleError(e);
    }
  }

  Future<void> deleteWarehouse(String warehouseName) async {
    try {
      await checkPermissions('Warehouse', ['Stock Manager']);
      await dio.delete('/api/resource/Warehouse/$warehouseName');
    } catch (e) {
      throw handleError(e);
    }
  }

  Future<List<dynamic>> getBins() async {
    try {
      await checkPermissions('Bin', ['Stock User', 'Stock Manager']);

      final response = await dio.get(
        '/api/resource/Bin',
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

  Future<Map<String, dynamic>> getBinDetail(String binName) async {
    try {
      await checkPermissions('Bin', ['Stock User', 'Stock Manager']);
      
      final response = await dio.get(
        '/api/resource/Bin/$binName',
      );
      
      if (response.data == null) {
        throw Exception('No data received from the server');
      }

      return response.data['data'];
    } catch (e) {
      throw handleError(e);
    }
  }
}
