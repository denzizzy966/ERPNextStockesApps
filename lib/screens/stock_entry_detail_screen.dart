import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../services/api_service.dart';
import 'stock_entry_edit_screen.dart';

class StockEntryDetailScreen extends StatefulWidget {
  final Map<String, dynamic> stockEntry;

  const StockEntryDetailScreen({
    super.key,
    required this.stockEntry,
  });

  @override
  State<StockEntryDetailScreen> createState() => _StockEntryDetailScreenState();
}

class _StockEntryDetailScreenState extends State<StockEntryDetailScreen> {
  bool _isSubmitting = false;
  late ApiService _apiService;

  @override
  void initState() {
    super.initState();
    _apiService = context.read<AuthProvider>().apiService;
  }

  Future<void> _submitStockEntry() async {
    setState(() {
      _isSubmitting = true;
    });

    try {
      await _apiService.submitStockEntry(widget.stockEntry['name']);
      if (!mounted) return;
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Stock entry submitted successfully'),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.pop(context, true); // Return true to trigger refresh
    } catch (e) {
      if (!mounted) return;
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error submitting stock entry: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  Future<void> _editStockEntry() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => StockEntryEditScreen(stockEntry: widget.stockEntry),
      ),
    );

    if (result == true && mounted) {
      Navigator.pop(context, true); // Return true to trigger refresh
    }
  }

  @override
  Widget build(BuildContext context) {
    final currencyFormatter = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    );

    final List<dynamic> items = (widget.stockEntry['items'] is List) 
        ? widget.stockEntry['items'] as List<dynamic>
        : widget.stockEntry['items']?['result'] as List<dynamic>? ?? [];

    final bool isDraft = widget.stockEntry['docstatus'] == 0;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.stockEntry['name'] ?? 'Stock Entry Detail'),
        actions: [
          if (isDraft)
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: _editStockEntry,
            ),
        ],
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Basic Information Card
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Basic Information',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const Divider(),
                        _buildInfoRow('Type', widget.stockEntry['stock_entry_type'] ?? '-'),
                        _buildInfoRow(
                          'Date',
                          DateFormat('dd/MM/yyyy HH:mm').format(
                            DateTime.parse(widget.stockEntry['creation'] ?? DateTime.now().toString()),
                          ),
                        ),
                        _buildInfoRow('Status', widget.stockEntry['docstatus'] == 1 ? 'Submitted' : 'Draft'),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Warehouse Information Card
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Warehouse Information',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const Divider(),
                        if (widget.stockEntry['from_warehouse'] != null)
                          _buildInfoRow('From Warehouse', widget.stockEntry['from_warehouse']),
                        if (widget.stockEntry['to_warehouse'] != null)
                          _buildInfoRow('To Warehouse', widget.stockEntry['to_warehouse']),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Items Card
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Items',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const Divider(),
                        ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: items.length,
                          itemBuilder: (context, index) {
                            final item = items[index];
                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (index > 0) const Divider(),
                                Text(
                                  item['item_name'] ?? item['item_code'] ?? 'Unknown Item',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text('Quantity: ${item['qty']} ${item['uom']}'),
                                    Text(
                                      currencyFormatter.format(item['amount'] ?? 0),
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: Colors.blue,
                                      ),
                                    ),
                                  ],
                                ),
                                Text('Basic Rate: ${currencyFormatter.format(item['basic_rate'] ?? 0)}'),
                                if (item['custom_source_rack'] != null && item['custom_source_rack'].toString().isNotEmpty)
                                  Text('Source Rack: ${item['custom_source_rack']}'),
                                if (item['custom_target_rack'] != null && item['custom_target_rack'].toString().isNotEmpty)
                                  Text('Target Rack: ${item['custom_target_rack']}'),
                                if (item['s_warehouse'] != null && item['s_warehouse'].toString().isNotEmpty)
                                  Text('Source Warehouse: ${item['s_warehouse']}'),
                                if (item['t_warehouse'] != null && item['t_warehouse'].toString().isNotEmpty)
                                  Text('Target Warehouse: ${item['t_warehouse']}'),
                              ],
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Value Information Card
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Value Information',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const Divider(),
                        _buildInfoRow(
                          'Total Outgoing Value',
                          currencyFormatter.format(widget.stockEntry['total_outgoing_value'] ?? 0),
                        ),
                        _buildInfoRow(
                          'Total Incoming Value',
                          currencyFormatter.format(widget.stockEntry['total_incoming_value'] ?? 0),
                        ),
                        _buildInfoRow(
                          'Value Difference',
                          currencyFormatter.format(widget.stockEntry['value_difference'] ?? 0),
                        ),
                        const Divider(),
                        _buildInfoRow(
                          'Total Amount',
                          currencyFormatter.format(widget.stockEntry['total_amount'] ?? 0),
                          valueStyle: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                            color: Colors.blue,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 80), // Space for the submit button
              ],
            ),
          ),
          if (isDraft)
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 10,
                      offset: const Offset(0, -5),
                    ),
                  ],
                ),
                child: ElevatedButton(
                  onPressed: _isSubmitting ? null : _submitStockEntry,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    backgroundColor: Colors.green,
                  ),
                  child: _isSubmitting
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : const Text(
                          'Submit Stock Entry',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, {TextStyle? valueStyle}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: Colors.grey,
            ),
          ),
          Text(
            value,
            style: valueStyle,
          ),
        ],
      ),
    );
  }
}
