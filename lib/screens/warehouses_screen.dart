import 'package:flutter/material.dart';
import '../models/warehouse.dart';
import '../services/api_service.dart';

class WarehousesScreen extends StatefulWidget {
  const WarehousesScreen({super.key});

  @override
  State<WarehousesScreen> createState() => _WarehousesScreenState();
}

class _WarehousesScreenState extends State<WarehousesScreen> {
  final ApiService _apiService = ApiService();
  List<Warehouse> _warehouses = [];
  List<Warehouse> _filteredWarehouses = [];
  bool _isLoading = false;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadWarehouses();
  }

  Future<void> _loadWarehouses() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final warehouses = await _apiService.getWarehouses();
      setState(() {
        _warehouses = warehouses.map((json) => Warehouse.fromJson(json)).toList();
        _filteredWarehouses = List.from(_warehouses);
      });
    } catch (e) {
      _showError('Failed to load warehouses: ${e.toString()}');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _filterWarehouses(String query) {
    setState(() {
      _filteredWarehouses = _warehouses
          .where((warehouse) =>
              warehouse.warehouseName.toLowerCase().contains(query.toLowerCase()) ||
              warehouse.warehouseType.toLowerCase().contains(query.toLowerCase()) ||
              warehouse.address.toLowerCase().contains(query.toLowerCase()))
          .toList();
    });
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  Future<void> _deleteWarehouse(Warehouse warehouse) async {
    try {
      await _apiService.deleteWarehouse(warehouse.name);
      await _loadWarehouses();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Warehouse deleted successfully')),
        );
      }
    } catch (e) {
      _showError('Failed to delete warehouse: ${e.toString()}');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Warehouses'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _showWarehouseDialog(),
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
                      labelText: 'Search Warehouses',
                      prefixIcon: Icon(Icons.search),
                      hintText: 'Search by name, type, or address',
                    ),
                    onChanged: _filterWarehouses,
                  ),
                ),
                Expanded(
                  child: RefreshIndicator(
                    onRefresh: _loadWarehouses,
                    child: _filteredWarehouses.isEmpty
                        ? Center(
                            child: Text(
                              'No warehouses found',
                              style: Theme.of(context).textTheme.titleLarge,
                            ),
                          )
                        : ListView.builder(
                            itemCount: _filteredWarehouses.length,
                            padding: const EdgeInsets.all(8),
                            itemBuilder: (context, index) {
                              final warehouse = _filteredWarehouses[index];
                              return Card(
                                elevation: 2,
                                margin: const EdgeInsets.symmetric(
                                  vertical: 4,
                                  horizontal: 8,
                                ),
                                child: ListTile(
                                  title: Text(
                                    warehouse.warehouseName,
                                    style: const TextStyle(fontWeight: FontWeight.bold),
                                  ),
                                  subtitle: Text(
                                    'Type: ${warehouse.warehouseType}\nAddress: ${warehouse.address}',
                                  ),
                                  trailing: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      IconButton(
                                        icon: const Icon(Icons.edit),
                                        onPressed: () =>
                                            _showWarehouseDialog(warehouse: warehouse),
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.delete),
                                        onPressed: () =>
                                            _showDeleteConfirmation(warehouse),
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

  Future<void> _showDeleteConfirmation(Warehouse warehouse) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Warehouse'),
        content:
            Text('Are you sure you want to delete ${warehouse.warehouseName}?'),
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
      await _deleteWarehouse(warehouse);
    }
  }

  Future<void> _showWarehouseDialog({Warehouse? warehouse}) async {
    final formKey = GlobalKey<FormState>();
    final warehouseNameController =
        TextEditingController(text: warehouse?.warehouseName);
    final warehouseTypeController =
        TextEditingController(text: warehouse?.warehouseType);
    final addressController = TextEditingController(text: warehouse?.address);
    final companyController = TextEditingController(text: warehouse?.company);

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(warehouse == null ? 'Add Warehouse' : 'Edit Warehouse'),
        content: SingleChildScrollView(
          child: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: warehouseNameController,
                  decoration: const InputDecoration(labelText: 'Warehouse Name'),
                  validator: (value) =>
                      value?.isEmpty ?? true ? 'Required field' : null,
                ),
                TextFormField(
                  controller: warehouseTypeController,
                  decoration: const InputDecoration(labelText: 'Warehouse Type'),
                  validator: (value) =>
                      value?.isEmpty ?? true ? 'Required field' : null,
                ),
                TextFormField(
                  controller: addressController,
                  decoration: const InputDecoration(labelText: 'Address'),
                  maxLines: 3,
                ),
                TextFormField(
                  controller: companyController,
                  decoration: const InputDecoration(labelText: 'Company'),
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
                final warehouseData = {
                  'warehouse_name': warehouseNameController.text,
                  'warehouse_type': warehouseTypeController.text,
                  'address': addressController.text,
                  'company': companyController.text,
                };

                try {
                  if (warehouse == null) {
                    await _apiService.createWarehouse(warehouseData);
                  } else {
                    await _apiService.updateWarehouse(
                        warehouse.name, warehouseData);
                  }
                  if (mounted) {
                    Navigator.pop(context);
                    await _loadWarehouses();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          warehouse == null
                              ? 'Warehouse created successfully'
                              : 'Warehouse updated successfully',
                        ),
                      ),
                    );
                  }
                } catch (e) {
                  if (mounted) {
                    Navigator.pop(context);
                    _showError(
                      'Failed to ${warehouse == null ? 'create' : 'update'} warehouse: ${e.toString()}',
                    );
                  }
                }
              }
            },
            child: Text(warehouse == null ? 'Create' : 'Update'),
          ),
        ],
      ),
    );
  }
}
