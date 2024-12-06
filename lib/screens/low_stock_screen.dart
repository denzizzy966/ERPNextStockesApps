import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../services/api_service.dart';

class LowStockScreen extends StatefulWidget {
  const LowStockScreen({super.key});

  @override
  _LowStockScreenState createState() => _LowStockScreenState();
}

class _LowStockScreenState extends State<LowStockScreen> {
  late ApiService _apiService;
  List<dynamic> _lowStockItems = [];
  bool _isLoading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _apiService = context.read<AuthProvider>().apiService;
    _fetchLowStockItems();
  }

  Future<void> _fetchLowStockItems() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final items = await _apiService.getBins();
      // Filter bins with low stock
      final lowStockItems = items.where((item) {
        final actualQty = double.tryParse(item['actual_qty'].toString()) ?? 0;
        final reorderLevel = double.tryParse(item['reorder_level'].toString()) ?? 0;
        return actualQty < reorderLevel;
      }).toList();
      
      setState(() {
        _lowStockItems = lowStockItems;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Low Stock Items'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _fetchLowStockItems,
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('Error: $_error'),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _fetchLowStockItems,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (_lowStockItems.isEmpty) {
      return const Center(child: Text('No low stock items found'));
    }

    return RefreshIndicator(
      onRefresh: _fetchLowStockItems,
      child: ListView.builder(
        itemCount: _lowStockItems.length,
        itemBuilder: (context, index) {
          final item = _lowStockItems[index];
          final actualQty = double.tryParse(item['actual_qty'].toString()) ?? 0;
          final reorderLevel = double.tryParse(item['reorder_level'].toString()) ?? 0;
          
          return Card(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: ListTile(
              title: Text(item['item_code'] ?? ''),
              subtitle: Text('Warehouse: ${item['warehouse']}'),
              trailing: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    'Stock: ${actualQty.toStringAsFixed(2)}',
                    style: TextStyle(
                      color: actualQty < reorderLevel ? Colors.red : Colors.green,
                    ),
                  ),
                  Text(
                    'Reorder: $reorderLevel',
                    style: const TextStyle(fontSize: 12),
                  ),
                ],
              ),
              onTap: () => _showItemDetails(item),
            ),
          );
        },
      ),
    );
  }

  void _showItemDetails(Map<String, dynamic> item) {
    final actualQty = double.tryParse(item['actual_qty'].toString()) ?? 0;
    final projectedQty = double.tryParse(item['projected_qty'].toString()) ?? 0;
    final reorderLevel = double.tryParse(item['reorder_level'].toString()) ?? 0;
    
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Item Details',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            _detailRow('Item Code:', item['item_code']),
            _detailRow('Warehouse:', item['warehouse']),
            _detailRow('Current Stock:', actualQty.toStringAsFixed(2)),
            _detailRow('Projected Qty:', projectedQty.toStringAsFixed(2)),
            _detailRow('Reorder Level:', reorderLevel.toString()),
            if (item['stock_uom'] != null) _detailRow('UOM:', item['stock_uom']),
            if (item['valuation_rate'] != null) 
              _detailRow('Valuation Rate:', item['valuation_rate'].toString()),
          ],
        ),
      ),
    );
  }

  Widget _detailRow(String label, String? value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(width: 8),
          Text(value ?? 'N/A'),
        ],
      ),
    );
  }
}
