import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../services/api_service.dart';
import 'stock_entry_detail_screen.dart';
import 'stock_entry_edit_screen.dart';

class StockEntryListScreen extends StatefulWidget {
  const StockEntryListScreen({Key? key}) : super(key: key);

  @override
  _StockEntryListScreenState createState() => _StockEntryListScreenState();
}

class _StockEntryListScreenState extends State<StockEntryListScreen> {
  late ApiService _apiService;
  List<dynamic> _stockEntries = [];
  bool _isLoading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _apiService = context.read<AuthProvider>().apiService;
    _fetchStockEntries();
  }

  Future<void> _fetchStockEntries() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final entries = await _apiService.getStockEntries();
      setState(() {
        _stockEntries = entries;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _showStockEntryDetail(String entryId) async {
    try {
      final detail = await _apiService.getStockEntryDetail(entryId);
      if (!mounted) return;
      
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => StockEntryDetailScreen(stockEntry: detail),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error loading details: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  String _getStatusColor(String docstatus) {
    switch (docstatus) {
      case '0':
        return 'Draft';
      case '1':
        return 'Submitted';
      default:
        return 'Cancelled';
    }
  }

  Color _getStatusColorCode(String docstatus) {
    switch (docstatus) {
      case '0':
        return Colors.orange;
      case '1':
        return Colors.green;
      default:
        return Colors.red;
    }
  }

  Future<void> _createNewStockEntry() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const StockEntryEditScreen(),
      ),
    );
    
    if (result == true) {
      _fetchStockEntries();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Stock Entries'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _fetchStockEntries,
          ),
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: _createNewStockEntry,
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
              onPressed: _fetchStockEntries,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (_stockEntries.isEmpty) {
      return const Center(child: Text('No stock entries found'));
    }

    return RefreshIndicator(
      onRefresh: _fetchStockEntries,
      child: ListView.builder(
        itemCount: _stockEntries.length,
        itemBuilder: (context, index) {
          final entry = _stockEntries[index];
          return Card(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: ListTile(
              title: Row(
                children: [
                  Expanded(
                    child: Text(entry['name'] ?? ''),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: _getStatusColorCode(entry['docstatus'].toString()),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      _getStatusColor(entry['docstatus'].toString()),
                      style: const TextStyle(color: Colors.white, fontSize: 12),
                    ),
                  ),
                ],
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Type: ${entry['stock_entry_type']}'),
                  Text('Date: ${entry['posting_date']}'),
                  if (entry['from_warehouse'] != null)
                    Text('From: ${entry['from_warehouse']}'),
                  if (entry['to_warehouse'] != null)
                    Text('To: ${entry['to_warehouse']}'),
                ],
              ),
              onTap: () => _showStockEntryDetail(entry['name']),
            ),
          );
        },
      ),
    );
  }
}
