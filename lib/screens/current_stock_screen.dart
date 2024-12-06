import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/bin.dart';
import '../providers/auth_provider.dart';
import '../services/api_service.dart';

class CurrentStockScreen extends StatefulWidget {
  const CurrentStockScreen({Key? key}) : super(key: key);

  @override
  State<CurrentStockScreen> createState() => _CurrentStockScreenState();
}

class _CurrentStockScreenState extends State<CurrentStockScreen> {
  List<Bin> _bins = [];
  bool _isLoading = true;
  String? _error;
  late ApiService _apiService;

  @override
  void initState() {
    super.initState();
    _apiService = Provider.of<AuthProvider>(context, listen: false).apiService;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadBins();
    });
  }

  Future<void> _loadBins() async {
    if (!mounted) return;

    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      
      if (!authProvider.isAuthenticated) {
        throw Exception('Please log in to view stock data');
      }

      final binsData = await _apiService.getBins();
      final bins = binsData.map((data) => Bin.fromJson(data)).toList();
      
      if (!mounted) return;
      
      setState(() {
        _bins = bins;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _showBinDetails(Bin bin) async {
    try {
      final detailData = await _apiService.getBinDetail(bin.name);
      final detailBin = Bin.fromJson(detailData);

      if (!mounted) return;

      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('Bin Details - ${detailBin.itemCode}'),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                _detailRow('Warehouse', detailBin.warehouse),
                _detailRow('Actual Qty', '${detailBin.actualQty} ${detailBin.stockUom}'),
                _detailRow('Projected Qty', '${detailBin.projectedQty} ${detailBin.stockUom}'),
                _detailRow('Reserved Qty', '${detailBin.reservedQty} ${detailBin.stockUom}'),
                _detailRow('Ordered Qty', '${detailBin.orderedQty} ${detailBin.stockUom}'),
                _detailRow('Planned Qty', '${detailBin.plannedQty} ${detailBin.stockUom}'),
                _detailRow('Indented Qty', '${detailBin.indentedQty} ${detailBin.stockUom}'),
                _detailRow('Stock Value', detailBin.stockValue.toStringAsFixed(2)),
                _detailRow('Valuation Rate', detailBin.valuationRate.toStringAsFixed(2)),
                _detailRow('Last Modified', detailBin.modified),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Close'),
            ),
          ],
        ),
      );
    } catch (e) {
      if (!mounted) return;
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading bin details: $e')),
      );
    }
  }

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(
            child: Text(value),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Current Stock'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadBins,
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
              onPressed: _loadBins,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (_bins.isEmpty) {
      return const Center(child: Text('No stock data available'));
    }

    return RefreshIndicator(
      onRefresh: _loadBins,
      child: ListView.builder(
        itemCount: _bins.length,
        itemBuilder: (context, index) {
          final bin = _bins[index];
          return Card(
            margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            child: ListTile(
              title: Text(
                '${bin.itemCode} - ${bin.warehouse}',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 4),
                  Text('Actual Qty: ${bin.actualQty} ${bin.stockUom}'),
                  Text('Projected Qty: ${bin.projectedQty} ${bin.stockUom}'),
                  Text('Value: ${bin.stockValue.toStringAsFixed(2)}'),
                ],
              ),
              onTap: () => _showBinDetails(bin),
              trailing: const Icon(Icons.chevron_right),
            ),
          );
        },
      ),
    );
  }
}
