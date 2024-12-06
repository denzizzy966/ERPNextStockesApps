import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../models/item.dart';
import '../services/api_service.dart';

class StockEntryScreen extends StatefulWidget {
  const StockEntryScreen({super.key});

  @override
  State<StockEntryScreen> createState() => _StockEntryScreenState();
}

class _StockEntryScreenState extends State<StockEntryScreen> {
  final ApiService _apiService = ApiService();
  final List<Map<String, dynamic>> _items = [];
  List<Item> _availableItems = [];
  List<Item> _filteredItems = [];
  bool _isLoading = false;
  final TextEditingController _searchController = TextEditingController();
  String _selectedType = 'Material Receipt';
  String? _selectedSourceWarehouse;
  String? _selectedTargetWarehouse;
  String? _sourceRack;
  String? _targetRack;
  List<String> _warehouses = [];
  bool _isScanning = false;
  MobileScannerController? _scannerController;

  final List<String> _types = [
    'Material Receipt',
    'Material Issue',
    'Material Transfer',
  ];

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  @override
  void dispose() {
    _scannerController?.dispose();
    super.dispose();
  }

  Future<void> _loadInitialData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      await Future.wait([
        _loadItems(),
        _loadWarehouses(),
      ]);
      _filteredItems = List.from(_availableItems);
    } catch (e) {
      _showError('Failed to load initial data: ${e.toString()}');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _loadItems() async {
    try {
      final items = await _apiService.getItems();
      setState(() {
        _availableItems = items.map((json) => Item.fromJson(json)).toList();
      });
    } catch (e) {
      print('Error loading items: $e');
      rethrow;
    }
  }

  Future<void> _loadWarehouses() async {
    try {
      final warehouses = await _apiService.getWarehouses();
      setState(() {
        _warehouses = warehouses.map((w) => w['name'] as String).toList();
      });
    } catch (e) {
      print('Error loading warehouses: $e');
      rethrow;
    }
  }

  void _showError(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _filterItems(String query) {
    setState(() {
      _filteredItems = _availableItems
          .where((item) =>
              item.itemName.toLowerCase().contains(query.toLowerCase()) ||
              item.itemCode.toLowerCase().contains(query.toLowerCase()))
          .toList();
    });
  }

  void _addItem(Item item) {
    setState(() {
      _items.add({
        'item_code': item.itemCode,
        'qty': 1.0,
        's_warehouse': _selectedSourceWarehouse,
        't_warehouse': _selectedTargetWarehouse,
        'custom_source_rack': _sourceRack,
        'custom_target_rack': _targetRack,
        'uom': item.uom,
      });
    });
  }

  void _removeItem(int index) {
    setState(() {
      _items.removeAt(index);
    });
  }

  void _updateItemQuantity(int index, double quantity) {
    setState(() {
      _items[index]['qty'] = quantity;
    });
  }

  Future<void> _handleBarcodeScan(String barcode) async {
    try {
      // Search by both itemCode and customBarcode
      final item = _availableItems.firstWhere(
        (item) => item.itemCode == barcode || item.customBarcode == barcode,
        orElse: () => throw Exception('Item not found for barcode: $barcode'),
      );
      
      _addItem(item);
      
      // Stop scanning but stay on current screen
      setState(() {
        _isScanning = false;
        _scannerController?.dispose();
        _scannerController = null;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Added item: ${item.itemName}'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      _showError(e.toString());
      // Don't stop scanning on error to allow retry
    }
  }

  Future<void> _saveStockEntry() async {
    if (_items.isEmpty) {
      _showError('Please add at least one item');
      return;
    }

    // Validate warehouses based on type
    if (_selectedType == 'Material Issue' && _selectedSourceWarehouse == null) {
      _showError('Please select a source warehouse');
      return;
    }
    if (_selectedType == 'Material Receipt' && _selectedTargetWarehouse == null) {
      _showError('Please select a target warehouse');
      return;
    }
    if (_selectedType == 'Material Transfer' &&
        (_selectedSourceWarehouse == null || _selectedTargetWarehouse == null)) {
      _showError('Please select both source and target warehouses');
      return;
    }

    try {
      final stockEntryData = {
        'doctype': 'Stock Entry',
        'stock_entry_type': _selectedType,
        's_warehouse': _selectedSourceWarehouse,
        't_warehouse': _selectedTargetWarehouse,
        'custom_source_rack': _sourceRack,
        'custom_target_rack': _targetRack,
        'items': _items,
      };

      await _apiService.createStockEntry(stockEntryData);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Stock entry created successfully')),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      _showError('Failed to create stock entry: ${e.toString()}');
    }
  }

  void _startScanning() {
    setState(() {
      _isScanning = true;
      _scannerController = MobileScannerController(
        formats: [BarcodeFormat.qrCode],
        facing: CameraFacing.back,
        torchEnabled: false,
      );
    });
  }

  void _stopScanning() {
    _scannerController?.dispose();
    setState(() {
      _isScanning = false;
      _scannerController = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isScanning) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Scan QR Code'),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: _stopScanning,
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.flash_off),
              onPressed: () => _scannerController?.toggleTorch(),
            ),
            IconButton(
              icon: const Icon(Icons.camera_rear),
              onPressed: () => _scannerController?.switchCamera(),
            ),
          ],
        ),
        body: MobileScanner(
          controller: _scannerController!,
          onDetect: (capture) {
            final List<Barcode> barcodes = capture.barcodes;
            for (final barcode in barcodes) {
              final String? code = barcode.rawValue;
              if (code != null && code.isNotEmpty) {
                _handleBarcodeScan(code);
                break;
              }
            }
          },
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('New Stock Entry'),
        actions: [
          TextButton(
            onPressed: _saveStockEntry,
            child: const Text('Save', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  DropdownButtonFormField<String>(
                    value: _selectedType,
                    decoration: const InputDecoration(labelText: 'Type'),
                    items: _types.map((String type) {
                      return DropdownMenuItem<String>(
                        value: type,
                        child: Text(type),
                      );
                    }).toList(),
                    onChanged: (String? newValue) {
                      if (newValue != null) {
                        setState(() {
                          _selectedType = newValue;
                          _selectedSourceWarehouse = null;
                          _selectedTargetWarehouse = null;
                          _sourceRack = null;
                          _targetRack = null;
                        });
                      }
                    },
                  ),
                  const SizedBox(height: 16),
                  if (_selectedType == 'Material Issue' ||
                      _selectedType == 'Material Transfer') ...[
                    DropdownButtonFormField<String>(
                      value: _selectedSourceWarehouse,
                      decoration:
                          const InputDecoration(labelText: 'Source Warehouse'),
                      items: _warehouses.map((String warehouse) {
                        return DropdownMenuItem<String>(
                          value: warehouse,
                          child: Text(warehouse),
                        );
                      }).toList(),
                      onChanged: (String? newValue) {
                        setState(() {
                          _selectedSourceWarehouse = newValue;
                        });
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      decoration:
                          const InputDecoration(labelText: 'Source Rack'),
                      onChanged: (value) {
                        setState(() {
                          _sourceRack = value;
                        });
                      },
                    ),
                    const SizedBox(height: 16),
                  ],
                  if (_selectedType == 'Material Receipt' ||
                      _selectedType == 'Material Transfer') ...[
                    DropdownButtonFormField<String>(
                      value: _selectedTargetWarehouse,
                      decoration:
                          const InputDecoration(labelText: 'Target Warehouse'),
                      items: _warehouses.map((String warehouse) {
                        return DropdownMenuItem<String>(
                          value: warehouse,
                          child: Text(warehouse),
                        );
                      }).toList(),
                      onChanged: (String? newValue) {
                        setState(() {
                          _selectedTargetWarehouse = newValue;
                        });
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      decoration:
                          const InputDecoration(labelText: 'Target Rack'),
                      onChanged: (value) {
                        setState(() {
                          _targetRack = value;
                        });
                      },
                    ),
                    const SizedBox(height: 16),
                  ],
                  TextField(
                    controller: _searchController,
                    decoration: const InputDecoration(
                      labelText: 'Search Items',
                      prefixIcon: Icon(Icons.search),
                    ),
                    onChanged: _filterItems,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.qr_code_scanner),
                    label: const Text('Scan QR Code'),
                    onPressed: _startScanning,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () async {
                      final Item? selectedItem = await showDialog<Item>(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: const Text('Select Item'),
                          content: SizedBox(
                            width: double.maxFinite,
                            child: ListView.builder(
                              shrinkWrap: true,
                              itemCount: _filteredItems.length,
                              itemBuilder: (context, index) {
                                final item = _filteredItems[index];
                                return ListTile(
                                  title: Text(item.itemName),
                                  subtitle: Text(item.itemCode),
                                  onTap: () => Navigator.pop(context, item),
                                );
                              },
                            ),
                          ),
                        ),
                      );
                      if (selectedItem != null) {
                        _addItem(selectedItem);
                      }
                    },
                    child: const Text('Add Item'),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Items',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _items.length,
                    itemBuilder: (context, index) {
                      final item = _items[index];
                      final itemDetails = _availableItems.firstWhere(
                        (i) => i.itemCode == item['item_code'],
                      );
                      return Card(
                        child: ListTile(
                          title: Text(itemDetails.itemName),
                          subtitle: Row(
                            children: [
                              Expanded(
                                child: TextFormField(
                                  initialValue: item['qty'].toString(),
                                  decoration: InputDecoration(
                                    labelText: 'Quantity (${item['uom']})',
                                  ),
                                  keyboardType: TextInputType.number,
                                  onChanged: (value) {
                                    final qty = double.tryParse(value);
                                    if (qty != null) {
                                      _updateItemQuantity(index, qty);
                                    }
                                  },
                                ),
                              ),
                            ],
                          ),
                          trailing: IconButton(
                            icon: const Icon(Icons.delete),
                            onPressed: () => _removeItem(index),
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
    );
  }
}
