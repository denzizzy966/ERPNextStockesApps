class StockLedgerEntry {
  final String name;
  final String itemCode;
  final String warehouse;
  final DateTime postingDate;
  final double actualQty;
  final double valuationRate;
  final double stockValue;
  final String voucherType;
  final String voucherNo;
  final String? batchNo;
  final String? serialNo;
  final String company;
  final String stockUom;

  StockLedgerEntry({
    required this.name,
    required this.itemCode,
    required this.warehouse,
    required this.postingDate,
    required this.actualQty,
    required this.valuationRate,
    required this.stockValue,
    required this.voucherType,
    required this.voucherNo,
    this.batchNo,
    this.serialNo,
    required this.company,
    required this.stockUom,
  });

  factory StockLedgerEntry.fromJson(Map<String, dynamic> json) {
    return StockLedgerEntry(
      name: json['name'],
      itemCode: json['item_code'],
      warehouse: json['warehouse'],
      postingDate: DateTime.parse(json['posting_date']),
      actualQty: json['actual_qty'].toDouble(),
      valuationRate: json['valuation_rate'].toDouble(),
      stockValue: json['stock_value'].toDouble(),
      voucherType: json['voucher_type'],
      voucherNo: json['voucher_no'],
      batchNo: json['batch_no'],
      serialNo: json['serial_no'],
      company: json['company'],
      stockUom: json['stock_uom'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'item_code': itemCode,
      'warehouse': warehouse,
      'posting_date': postingDate.toIso8601String().split('T')[0],
      'actual_qty': actualQty,
      'valuation_rate': valuationRate,
      'stock_value': stockValue,
      'voucher_type': voucherType,
      'voucher_no': voucherNo,
      'batch_no': batchNo,
      'serial_no': serialNo,
      'company': company,
      'stock_uom': stockUom,
    };
  }
}
