import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../services/api_service.dart';
import 'barcode_scanner_screen.dart';
import 'dart:developer' as developer;

class StockEntryEditScreen extends StatefulWidget {
  final Map<String, dynamic>? stockEntry;

  const StockEntryEditScreen({
    Key? key,
    this.stockEntry,
  }) : super(key: key);

  @override
  State<StockEntryEditScreen> createState() => _StockEntryEditScreenState();
}

class _StockEntryEditScreenState extends State<StockEntryEditScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  bool _isLoadingData = true;
  late Map<String, dynamic> _editedEntry;
  final List<Map<String, dynamic>> _editedItems = [];

  // Dropdown data
  List<dynamic> _items = [];
  List<dynamic> _warehouses = [];
  List<dynamic> _itemGroups = [];

  late ApiService _apiService;

  final List<String> _stockEntryTypes = [
    'Material Issue',
    'Material Receipt',
    'Material Transfer',
  ];

  @override
  void initState() {
    super.initState();
    _apiService = context.read<AuthProvider>().apiService;
    _editedEntry = widget.stockEntry != null 
        ? Map<String, dynamic>.from(widget.stockEntry!)
        : {
            'stock_entry_type': '',
            'posting_date': DateFormat('yyyy-MM-dd').format(DateTime.now()),
            'posting_time': DateFormat('HH:mm:ss').format(DateTime.now()),
            'docstatus': '0',
            'items': [],
          };
    _initializeItems();
    _loadDropdownData();
  }

  Future<void> _loadDropdownData() async {
    try {
      final items = await _apiService.getItems();
      final warehouses = await _apiService.getWarehouses();
      final itemGroups = await _apiService.getItemGroups();

      if (mounted) {
        setState(() {
          _items = items;
          _warehouses = warehouses;
          _itemGroups = itemGroups;
          _isLoadingData = false;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading data: $e')),
        );
        setState(() {
          _isLoadingData = false;
        });
      }
    }
  }

  void _initializeItems() {
    if (widget.stockEntry != null) {
      final List<dynamic> items = widget.stockEntry!['items'] ?? [];
      for (var item in items) {
        _editedItems.add(Map<String, dynamic>.from(item));
      }
    }
  }

  void _addNewItem() {
    setState(() {
      _editedItems.add({
        'item_code': '',
        'item_name': '',
        'qty': 0.0,
        'uom': '',
        'basic_rate': 0.0,
        'custom_source_rack': '',
        'custom_target_rack': '',
        's_warehouse': '',
        't_warehouse': '',
      });
    });
  }

  Future<void> _saveChanges() async {
    if (!_formKey.currentState!.validate()) return;
    _formKey.currentState!.save();

    setState(() => _isLoading = true);

    try {
      _editedEntry['items'] = _editedItems;
      if (widget.stockEntry != null) {
        await _apiService.updateStockEntry(widget.stockEntry!['name'], _editedEntry);
      } else {
        await _apiService.createStockEntry(_editedEntry);
      }
      
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Changes saved successfully')),
      );
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error saving changes: $e')),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _submitEntry() async {
    setState(() => _isLoading = true);

    try {
      await _apiService.submitStockEntry(widget.stockEntry!['name']);
      
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Stock entry submitted successfully')),
      );
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error submitting entry: $e')),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _updateItemDetails(int index, String itemCode) {
    final selectedItem = _items.firstWhere(
      (item) => item['item_code'] == itemCode,
      orElse: () => {},
    );

    if (selectedItem.isNotEmpty) {
      setState(() {
        _editedItems[index]['item_code'] = selectedItem['item_code'];
        _editedItems[index]['item_name'] = selectedItem['item_name'];
        _editedItems[index]['uom'] = selectedItem['stock_uom'];
      });
    }
  }

  Future<void> _scanBarcode(int index) async {
    final scannedCode = await Navigator.push<String>(
      context,
      MaterialPageRoute(
        builder: (context) => const BarcodeScannerScreen(),
      ),
    );

    if (scannedCode != null) {
      developer.log('Scanned code: $scannedCode');
      developer.log('Available items: ${_items.length}');
      
      // First try to find by item_code
      var matchingItem = _items.firstWhere(
        (item) => item['item_code'] == scannedCode,
        orElse: () => {},
      );

      developer.log('Found by item_code: ${matchingItem.isNotEmpty}');

      // If not found by item_code, try to find by custom_barcode
      if (matchingItem.isEmpty) {
        matchingItem = _items.firstWhere(
          (item) => item['custom_barcode'] == scannedCode,
          orElse: () => {},
        );
        developer.log('Found by custom_barcode: ${matchingItem.isNotEmpty}');
        
        // Log all items with their custom barcodes for debugging
        for (var item in _items) {
          developer.log('Item ${item['item_code']}: custom_barcode = ${item['custom_barcode']}');
        }
      }

      if (matchingItem.isNotEmpty) {
        developer.log('Updating item details with: ${matchingItem['item_code']}');
        _updateItemDetails(index, matchingItem['item_code']);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Item found: ${matchingItem['item_name']}'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Item not found by item code or custom barcode'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoadingData) {
      return Scaffold(
        appBar: AppBar(
          title: Text(widget.stockEntry != null 
              ? 'Edit ${widget.stockEntry!['name']}'
              : 'New Stock Entry'),
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.stockEntry != null 
            ? 'Edit ${widget.stockEntry!['name']}'
            : 'New Stock Entry'),
        actions: [
          if (!_isLoading)
            IconButton(
              icon: const Icon(Icons.save),
              onPressed: _saveChanges,
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Form(
              key: _formKey,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
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
                            DropdownButtonFormField<String>(
                              value: _editedEntry['stock_entry_type'],
                              decoration: const InputDecoration(
                                labelText: 'Stock Entry Type',
                              ),
                              items: _stockEntryTypes.map((type) {
                                return DropdownMenuItem<String>(
                                  value: type,
                                  child: Text(type),
                                );
                              }).toList(),
                              onChanged: (value) {
                                setState(() {
                                  _editedEntry['stock_entry_type'] = value;
                                });
                              },
                              validator: (value) => value?.isEmpty ?? true ? 'Required' : null,
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              initialValue: _editedEntry['posting_date'],
                              decoration: const InputDecoration(
                                labelText: 'Posting Date',
                              ),
                              onSaved: (value) => _editedEntry['posting_date'] = value,
                              validator: (value) =>
                                  value?.isEmpty ?? true ? 'Required' : null,
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
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
                            DropdownButtonFormField<String>(
                              value: _editedEntry['from_warehouse'],
                              decoration: const InputDecoration(
                                labelText: 'From Warehouse',
                              ),
                              items: _warehouses.map((warehouse) {
                                return DropdownMenuItem<String>(
                                  value: warehouse['name'],
                                  child: Text(warehouse['warehouse_name'] ?? warehouse['name']),
                                );
                              }).toList(),
                              onChanged: (value) {
                                setState(() {
                                  _editedEntry['from_warehouse'] = value;
                                });
                              },
                            ),
                            const SizedBox(height: 16),
                            DropdownButtonFormField<String>(
                              value: _editedEntry['to_warehouse'],
                              decoration: const InputDecoration(
                                labelText: 'To Warehouse',
                              ),
                              items: _warehouses.map((warehouse) {
                                return DropdownMenuItem<String>(
                                  value: warehouse['name'],
                                  child: Text(warehouse['warehouse_name'] ?? warehouse['name']),
                                );
                              }).toList(),
                              onChanged: (value) {
                                setState(() {
                                  _editedEntry['to_warehouse'] = value;
                                });
                              },
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Items',
                                  style: Theme.of(context).textTheme.titleLarge,
                                ),
                                IconButton(
                                  icon: const Icon(Icons.add),
                                  onPressed: _addNewItem,
                                ),
                              ],
                            ),
                            const Divider(),
                            ListView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: _editedItems.length,
                              itemBuilder: (context, index) {
                                return _buildItemEditor(index);
                              },
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 80),
                  ],
                ),
              ),
            ),
      bottomNavigationBar: widget.stockEntry != null && widget.stockEntry!['docstatus'] == 0
          ? Container(
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
                onPressed: _isLoading ? null : _submitEntry,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: _isLoading
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
            )
          : null,
    );
  }

  Widget _buildItemEditor(int index) {
    final item = _editedItems[index];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (index > 0) const Divider(height: 32),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Item ${index + 1}',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            IconButton(
              icon: const Icon(Icons.delete),
              onPressed: () {
                setState(() {
                  _editedItems.removeAt(index);
                });
              },
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: DropdownButtonFormField<String>(
                value: item['item_code'],
                decoration: const InputDecoration(
                  labelText: 'Item',
                ),
                items: _items.map((item) {
                  return DropdownMenuItem<String>(
                    value: item['item_code'],
                    child: Text('${item['item_code']} - ${item['item_name']}'),
                  );
                }).toList(),
                onChanged: (value) {
                  if (value != null) {
                    _updateItemDetails(index, value);
                  }
                },
                validator: (value) => value?.isEmpty ?? true ? 'Required' : null,
              ),
            ),
            IconButton(
              icon: const Icon(Icons.qr_code_scanner),
              onPressed: () => _scanBarcode(index),
            ),
          ],
        ),
        const SizedBox(height: 8),
        TextFormField(
          initialValue: item['qty']?.toString() ?? '0',
          decoration: const InputDecoration(
            labelText: 'Quantity',
          ),
          keyboardType: TextInputType.number,
          onSaved: (value) => item['qty'] = double.tryParse(value ?? '') ?? 0,
          validator: (value) {
            if (value == null || value.isEmpty) return 'Required';
            if (double.tryParse(value) == null) return 'Invalid number';
            return null;
          },
        ),
        const SizedBox(height: 8),
        TextFormField(
          initialValue: item['basic_rate']?.toString() ?? '0',
          decoration: const InputDecoration(
            labelText: 'Basic Rate',
          ),
          keyboardType: TextInputType.number,
          onSaved: (value) => item['basic_rate'] = double.tryParse(value ?? '') ?? 0,
          validator: (value) {
            if (value == null || value.isEmpty) return 'Required';
            if (double.tryParse(value) == null) return 'Invalid number';
            return null;
          },
        ),
        const SizedBox(height: 8),
        TextFormField(
          initialValue: item['custom_source_rack'] ?? '',
          decoration: const InputDecoration(
            labelText: 'Source Rack',
          ),
          onSaved: (value) => item['custom_source_rack'] = value,
        ),
        const SizedBox(height: 8),
        TextFormField(
          initialValue: item['custom_target_rack'] ?? '',
          decoration: const InputDecoration(
            labelText: 'Target Rack',
          ),
          onSaved: (value) => item['custom_target_rack'] = value,
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          value: item['s_warehouse'],
          decoration: const InputDecoration(
            labelText: 'Source Warehouse',
          ),
          items: _warehouses.map((warehouse) {
            return DropdownMenuItem<String>(
              value: warehouse['name'],
              child: Text(warehouse['warehouse_name'] ?? warehouse['name']),
            );
          }).toList(),
          onChanged: (value) {
            setState(() {
              item['s_warehouse'] = value;
            });
          },
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          value: item['t_warehouse'],
          decoration: const InputDecoration(
            labelText: 'Target Warehouse',
          ),
          items: _warehouses.map((warehouse) {
            return DropdownMenuItem<String>(
              value: warehouse['name'],
              child: Text(warehouse['warehouse_name'] ?? warehouse['name']),
            );
          }).toList(),
          onChanged: (value) {
            setState(() {
              item['t_warehouse'] = value;
            });
          },
        ),
      ],
    );
  }
}
