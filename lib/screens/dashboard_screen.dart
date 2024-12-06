import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../widgets/app_layout.dart';
import '../services/api_service.dart';
import 'package:intl/intl.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final ApiService _apiService = ApiService();
  bool _isLoading = true;
  List<Map<String, dynamic>> _recentStockEntries = [];
  int _totalItems = 0;
  int _lowStockCount = 0;
  double _totalStockValue = 0;

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
  }

  Future<void> _loadDashboardData() async {
    try {
      // Get stock ledger data
      final stockLedgerResponse = await _apiService.getStockLedger();
      final stockLedgerData = stockLedgerResponse['result'] as List<dynamic>? ?? [];
      
      // Create a map to store the latest stock value and quantity for each item
      final Map<String, Map<String, dynamic>> latestItemData = {};
      
      // Process stock ledger data
      for (var entry in stockLedgerData) {
        if (entry is Map<String, dynamic>) {
          final itemCode = entry['item_code']?.toString() ?? '';
          if (itemCode.isNotEmpty) {
            final qtyAfterTransaction = (entry['qty_after_transaction'] as num?)?.toDouble() ?? 0.0;
            final stockValue = (entry['stock_value'] as num?)?.toDouble() ?? 0.0;
            
            // Update or create item data
            latestItemData[itemCode] = {
              'qty': qtyAfterTransaction,
              'value': stockValue,
            };
          }
        }
      }

      // Calculate totals
      _totalItems = latestItemData.length;
      _lowStockCount = latestItemData.values.where((item) => (item['qty'] as num) < 10).length;
      _totalStockValue = latestItemData.values.fold(0.0, (sum, item) => sum + (item['value'] as num));

      // Get recent stock entries
      final stockEntries = await _apiService.getStockEntries();
      
      // Convert to List<Map<String, dynamic>> and take first 4 entries
      final List<Map<String, dynamic>> entries = [];
      try {
        for (var i = 0; i < stockEntries.length && i < 4; i++) {
          if (stockEntries[i] is Map) {
            entries.add(Map<String, dynamic>.from(stockEntries[i] as Map));
          }
        }
      } catch (e) {
        print('Error processing stock entries: $e');
      }

      setState(() {
        _recentStockEntries = entries;
        _isLoading = false;
      });
    } catch (e) {
      print('Dashboard data loading error: $e');
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading dashboard data: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user;
    final now = DateTime.now();
    
    return AppLayout(
      currentIndex: 0,
      child: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // DateTime and User Card
                    Card(
                      elevation: 2,
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    DateFormat('EEEE, d MMMM yyyy').format(now),
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    DateFormat('HH:mm:ss').format(now),
                                    style: const TextStyle(
                                      fontSize: 24,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            CircleAvatar(
                              radius: 20,
                              backgroundColor: Colors.blue,
                              child: Text(
                                (user?.username.substring(0, 1) ?? 'U').toUpperCase(),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Stock Information Cards
                    Row(
                      children: [
                        Expanded(
                          child: Card(
                            child: Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Column(
                                children: [
                                  const Icon(Icons.inventory, size: 32),
                                  const SizedBox(height: 8),
                                  const Text('Total Items'),
                                  Text(
                                    '$_totalItems',
                                    style: const TextStyle(
                                      fontSize: 24,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Card(
                            child: Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Column(
                                children: [
                                  const Icon(Icons.warning, size: 32, color: Colors.orange),
                                  const SizedBox(height: 8),
                                  const Text('Low Stock'),
                                  Text(
                                    '$_lowStockCount',
                                    style: const TextStyle(
                                      fontSize: 24,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          children: [
                            const Icon(Icons.attach_money, size: 32, color: Colors.green),
                            const SizedBox(height: 8),
                            const Text('Total Stock Value'),
                            Text(
                              NumberFormat.currency(
                                locale: 'id_ID',
                                symbol: 'Rp ',
                                decimalDigits: 0,
                              ).format(_totalStockValue),
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Recent Stock Entries
                    const Text(
                      'Recent Stock Entries',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Column(
                      children: _recentStockEntries.map((entry) {
                        return Card(
                          margin: const EdgeInsets.only(bottom: 8),
                          child: ListTile(
                            title: Text(
                              entry['name']?.toString() ?? 'Unknown',
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  DateFormat('dd/MM/yyyy').format(
                                    DateTime.parse(entry['posting_date']?.toString() ?? DateTime.now().toString()),
                                  ),
                                ),
                                Text(
                                  entry['stock_entry_type']?.toString() ?? 'Unknown Type',
                                  style: const TextStyle(color: Colors.blue),
                                ),
                              ],
                            ),
                            trailing: Text(
                              NumberFormat.currency(
                                locale: 'id_ID',
                                symbol: 'Rp ',
                                decimalDigits: 0,
                              ).format(entry['total_amount'] ?? 0),
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.green,
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
      ),
    );
  }
}
