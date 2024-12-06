import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/item.dart';
import '../models/item_group.dart';
import '../services/api_service.dart';
import '../screens/barcode_scanner_screen.dart';
import 'dart:convert';

class ItemsScreen extends StatefulWidget {
  const ItemsScreen({super.key});

  @override
  State<ItemsScreen> createState() => _ItemsScreenState();
}

class _ItemsScreenState extends State<ItemsScreen> {
  final ApiService _apiService = ApiService();
  List<Item> _items = [];
  List<Item> _filteredItems = [];
  List<ItemGroup> _itemGroups = [];
  List<String> _uoms = [];
  bool _isLoading = false;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadInitialData();
    _loadLocalData();
  }

  Future<void> _loadLocalData() async {
    final prefs = await SharedPreferences.getInstance();
    final itemsJson = prefs.getString('items');
    if (itemsJson != null) {
      final List<dynamic> decodedItems = jsonDecode(itemsJson);
      setState(() {
        _items = decodedItems.map((item) => Item.fromJson(item)).toList();
        _filteredItems = List.from(_items);
      });
    }
  }

  Future<void> _saveLocalData() async {
    final prefs = await SharedPreferences.getInstance();
    final itemsJson = jsonEncode(_items.map((item) => item.toJson()).toList());
    await prefs.setString('items', itemsJson);
  }

  Future<void> _loadInitialData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      await Future.wait([
        _loadItems(),
        _loadItemGroups(),
        _loadUOMs(),
      ]);
      _filteredItems = List.from(_items);
      await _saveLocalData();
    } catch (e) {
      print('Error loading initial data: $e');
      _showError('Failed to load initial data: ${e.toString()}');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _filterItems(String query) {
    setState(() {
      _filteredItems = _items
          .where((item) =>
              item.itemName.toLowerCase().contains(query.toLowerCase()) ||
              item.itemCode.toLowerCase().contains(query.toLowerCase()) ||
              item.itemGroup.toLowerCase().contains(query.toLowerCase()) ||
              (item.customBarcode.isNotEmpty && 
               item.customBarcode.toLowerCase().contains(query.toLowerCase())))
          .toList();
    });
  }

  Future<void> _loadItems() async {
    try {
      print('Loading items...');
      final items = await _apiService.getItems();
      print('Received items data: $items');
      
      setState(() {
        _items = items.map((json) {
          try {
            return Item.fromJson(json);
          } catch (e) {
            print('Error parsing item: $e');
            print('Problematic JSON: $json');
            return null;
          }
        }).where((item) => item != null).cast<Item>().toList();
      });
      
      print('Successfully parsed ${_items.length} items');
    } catch (e) {
      print('Error in _loadItems: $e');
      _showError('Failed to load items: ${e.toString()}');
      rethrow;
    }
  }

  Future<void> _loadItemGroups() async {
    try {
      final groups = await _apiService.getItemGroups();
      setState(() {
        _itemGroups = groups.map((json) => ItemGroup.fromJson(json)).toList();
      });
    } catch (e) {
      print('Error loading item groups: $e');
      rethrow;
    }
  }

  Future<void> _loadUOMs() async {
    try {
      final uoms = await _apiService.getUOMs();
      setState(() {
        _uoms = uoms.map((json) => json['name'] as String).toList();
      });
    } catch (e) {
      print('Error loading UOMs: $e');
      rethrow;
    }
  }

  void _showError(String message) {
    print('Showing error: $message');
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 5),
        ),
      );
    }
  }

  Future<void> _deleteItem(Item item) async {
    try {
      print('Deleting item: ${item.name}');
      await _apiService.deleteItem(item.name);
      await _loadItems();
      await _saveLocalData();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Item deleted successfully')),
        );
      }
    } catch (e) {
      print('Error deleting item: $e');
      _showError('Failed to delete item: ${e.toString()}');
    }
  }

  Future<String?> _scanBarcode() async {
    final result = await Navigator.push<String>(
      context,
      MaterialPageRoute(
        builder: (context) => const BarcodeScannerScreen(),
      ),
    );
    return result;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Items'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _showItemDialog(),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: TextField(
                    controller: _searchController,
                    decoration: const InputDecoration(
                      labelText: 'Search Items',
                      prefixIcon: Icon(Icons.search),
                      hintText: 'Search by name, code, barcode, or group',
                    ),
                    onChanged: _filterItems,
                  ),
                ),
                Expanded(
                  child: RefreshIndicator(
                    onRefresh: _loadInitialData,
                    child: _filteredItems.isEmpty
                        ? Center(
                            child: Text(
                              'No items found',
                              style: Theme.of(context).textTheme.titleLarge,
                            ),
                          )
                        : ListView.builder(
                            itemCount: _filteredItems.length,
                            padding: const EdgeInsets.all(8),
                            itemBuilder: (context, index) {
                              final item = _filteredItems[index];
                              return Card(
                                elevation: 2,
                                margin: const EdgeInsets.symmetric(
                                  vertical: 4,
                                  horizontal: 8,
                                ),
                                child: ListTile(
                                  title: Text(
                                    item.itemName,
                                    style: const TextStyle(fontWeight: FontWeight.bold),
                                  ),
                                  subtitle: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text('Code: ${item.itemCode}'),
                                      if (item.customBarcode.isNotEmpty)
                                        Text('Barcode: ${item.customBarcode}'),
                                      Text('Group: ${item.itemGroup}'),
                                      Text('UOM: ${item.uom}'),
                                      if (item.brand.isNotEmpty)
                                        Text('Brand: ${item.brand}'),
                                      if (item.description.isNotEmpty)
                                        Text('Description: ${item.description}'),
                                    ],
                                  ),
                                  trailing: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      IconButton(
                                        icon: const Icon(Icons.edit),
                                        onPressed: () => _showItemDialog(item: item),
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.delete),
                                        onPressed: () => _showDeleteConfirmation(item),
                                      ),
                                    ],
                                  ),
                                  isThreeLine: true,
                                ),
                              );
                            },
                          ),
                  ),
                ),
              ],
            ),
    );
  }

  Future<void> _showDeleteConfirmation(Item item) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Item'),
        content: Text('Are you sure you want to delete ${item.itemName}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text(
              'Delete',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      await _deleteItem(item);
    }
  }

  Future<void> _showItemDialog({Item? item}) async {
    final formKey = GlobalKey<FormState>();
    final itemCodeController = TextEditingController(text: item?.itemCode);
    final barcodeController = TextEditingController(text: item?.customBarcode);
    final itemNameController = TextEditingController(text: item?.itemName);
    final descriptionController = TextEditingController(text: item?.description);
    final brandController = TextEditingController(text: item?.brand);
    String? selectedItemGroup = item?.itemGroup;
    String? selectedUOM = item?.uom;

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(item == null ? 'Add Item' : 'Edit Item'),
        content: SingleChildScrollView(
          child: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: itemCodeController,
                  decoration: const InputDecoration(labelText: 'Item Code'),
                  validator: (value) =>
                      value?.isEmpty ?? true ? 'Required field' : null,
                ),
                TextFormField(
                  controller: barcodeController,
                  decoration: InputDecoration(
                    labelText: 'Barcode',
                    suffixIcon: IconButton(
                      icon: const Icon(Icons.qr_code_scanner),
                      onPressed: () async {
                        final scannedCode = await _scanBarcode();
                        if (scannedCode != null) {
                          barcodeController.text = scannedCode;
                        }
                      },
                    ),
                  ),
                ),
                TextFormField(
                  controller: itemNameController,
                  decoration: const InputDecoration(labelText: 'Item Name'),
                  validator: (value) =>
                      value?.isEmpty ?? true ? 'Required field' : null,
                ),
                DropdownButtonFormField<String>(
                  value: selectedItemGroup,
                  decoration: const InputDecoration(labelText: 'Item Group'),
                  items: _itemGroups.map((ItemGroup group) {
                    return DropdownMenuItem<String>(
                      value: group.itemGroupName,
                      child: Text(group.itemGroupName),
                    );
                  }).toList(),
                  onChanged: (String? newValue) {
                    selectedItemGroup = newValue;
                  },
                  validator: (value) =>
                      value?.isEmpty ?? true ? 'Required field' : null,
                ),
                TextFormField(
                  controller: brandController,
                  decoration: const InputDecoration(labelText: 'Brand'),
                ),
                TextFormField(
                  controller: descriptionController,
                  decoration: const InputDecoration(labelText: 'Description'),
                  maxLines: 3,
                ),
                DropdownButtonFormField<String>(
                  value: selectedUOM,
                  decoration: const InputDecoration(labelText: 'UOM'),
                  items: _uoms.map((String uom) {
                    return DropdownMenuItem<String>(
                      value: uom,
                      child: Text(uom),
                    );
                  }).toList(),
                  onChanged: (String? newValue) {
                    selectedUOM = newValue;
                  },
                  validator: (value) =>
                      value?.isEmpty ?? true ? 'Required field' : null,
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              if (formKey.currentState?.validate() ?? false) {
                final itemData = {
                  'item_code': itemCodeController.text,
                  'item_name': itemNameController.text,
                  'item_group': selectedItemGroup,
                  'description': descriptionController.text,
                  'stock_uom': selectedUOM,
                  'brand': brandController.text,
                  'custom_barcode': barcodeController.text,
                  'is_stock_item': 1,
                  'is_sales_item': 1,
                  'is_purchase_item': 1,
                  'include_item_in_manufacturing': 0,
                  'has_batch_no': 0,
                  'has_serial_no': 0,
                  'is_fixed_asset': 0,
                  'disabled': 0,
                };

                try {
                  print('Submitting item data: $itemData');
                  if (item == null) {
                    await _apiService.createItem(itemData);
                  } else {
                    await _apiService.updateItem(item.name, itemData);
                  }
                  if (mounted) {
                    Navigator.pop(context);
                    await _loadItems();
                    await _saveLocalData();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          item == null
                              ? 'Item created successfully'
                              : 'Item updated successfully',
                        ),
                      ),
                    );
                  }
                } catch (e) {
                  print('Error saving item: $e');
                  if (mounted) {
                    Navigator.pop(context);
                    _showError(
                      'Failed to ${item == null ? 'create' : 'update'} item: ${e.toString()}',
                    );
                  }
                }
              }
            },
            child: Text(item == null ? 'Create' : 'Update'),
          ),
        ],
      ),
    );
  }
}
