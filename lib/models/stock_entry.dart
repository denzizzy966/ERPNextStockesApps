class StockEntry {
  final String name;
  final String stockEntryType;
  final String postingDate;
  final String postingTime;
  final String company;
  final List<StockEntryItem> items;
  final String docStatus;
  final String fromWarehouse;
  final String toWarehouse;
  final String purpose;
  final String project;
  final double totalAmount;
  final String remarks;

  StockEntry({
    required this.name,
    required this.stockEntryType,
    required this.postingDate,
    required this.postingTime,
    required this.company,
    required this.items,
    required this.docStatus,
    required this.fromWarehouse,
    required this.toWarehouse,
    required this.purpose,
    required this.project,
    required this.totalAmount,
    required this.remarks,
  });

  factory StockEntry.fromJson(Map<String, dynamic> json) {
    List<StockEntryItem> itemsList = [];
    if (json['items'] != null) {
      itemsList = (json['items'] as List)
          .map((item) => StockEntryItem.fromJson(item))
          .toList();
    }

    return StockEntry(
      name: json['name'] ?? '',
      stockEntryType: json['stock_entry_type'] ?? '',
      postingDate: json['posting_date'] ?? '',
      postingTime: json['posting_time'] ?? '',
      company: json['company'] ?? '',
      items: itemsList,
      docStatus: json['docstatus']?.toString() ?? '0',
      fromWarehouse: json['from_warehouse'] ?? '',
      toWarehouse: json['to_warehouse'] ?? '',
      purpose: json['purpose'] ?? '',
      project: json['project'] ?? '',
      totalAmount: (json['total_amount'] ?? 0.0).toDouble(),
      remarks: json['remarks'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'stock_entry_type': stockEntryType,
      'posting_date': postingDate,
      'posting_time': postingTime,
      'company': company,
      'items': items.map((item) => item.toJson()).toList(),
      'docstatus': docStatus,
      'from_warehouse': fromWarehouse,
      'to_warehouse': toWarehouse,
      'purpose': purpose,
      'project': project,
      'total_amount': totalAmount,
      'remarks': remarks,
    };
  }
}

class StockEntryItem {
  final String item;
  final String itemName;
  final double qty;
  final String uom;
  final String warehouse;
  final double basicRate;
  final double basicAmount;
  final double transferQty;
  final double conversionFactor;
  final String description;
  final String serialNo;
  final String batchNo;
  final String valuation_rate;
  final String customSourceRack;
  final String customTargetRack;
  final String sWarehouse;
  final String tWarehouse;

  StockEntryItem({
    required this.item,
    required this.itemName,
    required this.qty,
    required this.uom,
    required this.warehouse,
    required this.basicRate,
    required this.basicAmount,
    required this.transferQty,
    required this.conversionFactor,
    required this.description,
    required this.serialNo,
    required this.batchNo,
    required this.valuation_rate,
    required this.customSourceRack,
    required this.customTargetRack,
    required this.sWarehouse,
    required this.tWarehouse,
  });

  factory StockEntryItem.fromJson(Map<String, dynamic> json) {
    return StockEntryItem(
      item: json['item_code'] ?? '',
      itemName: json['item_name'] ?? '',
      qty: (json['qty'] ?? 0.0).toDouble(),
      uom: json['uom'] ?? '',
      warehouse: json['warehouse'] ?? '',
      basicRate: (json['basic_rate'] ?? 0.0).toDouble(),
      basicAmount: (json['basic_amount'] ?? 0.0).toDouble(),
      transferQty: (json['transfer_qty'] ?? 0.0).toDouble(),
      conversionFactor: (json['conversion_factor'] ?? 1.0).toDouble(),
      description: json['description'] ?? '',
      serialNo: json['serial_no'] ?? '',
      batchNo: json['batch_no'] ?? '',
      valuation_rate: json['valuation_rate'] ?? '0',
      customSourceRack: json['custom_source_rack'] ?? '',
      customTargetRack: json['custom_target_rack'] ?? '',
      sWarehouse: json['s_warehouse'] ?? '',
      tWarehouse: json['t_warehouse'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'item_code': item,
      'item_name': itemName,
      'qty': qty,
      'uom': uom,
      'warehouse': warehouse,
      'basic_rate': basicRate,
      'basic_amount': basicAmount,
      'transfer_qty': transferQty,
      'conversion_factor': conversionFactor,
      'description': description,
      'serial_no': serialNo,
      'batch_no': batchNo,
      'valuation_rate': valuation_rate,
      'custom_source_rack': customSourceRack,
      'custom_target_rack': customTargetRack,
      's_warehouse': sWarehouse,
      't_warehouse': tWarehouse,
      'doctype': 'Stock Entry Detail',
      'parenttype': 'Stock Entry',
      'parentfield': 'items',
    };
  }
}
