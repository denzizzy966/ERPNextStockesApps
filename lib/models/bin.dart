class Bin {
  final String name;
  final String owner;
  final String creation;
  final String modified;
  final String modifiedBy;
  final int docstatus;
  final int idx;
  final String itemCode;
  final String warehouse;
  final double actualQty;
  final double plannedQty;
  final double indentedQty;
  final double orderedQty;
  final double projectedQty;
  final double reservedQty;
  final double reservedQtyForProduction;
  final double reservedQtyForSubContract;
  final double reservedQtyForProductionPlan;
  final double reservedStock;
  final String stockUom;
  final double valuationRate;
  final double stockValue;

  Bin({
    required this.name,
    required this.owner,
    required this.creation,
    required this.modified,
    required this.modifiedBy,
    required this.docstatus,
    required this.idx,
    required this.itemCode,
    required this.warehouse,
    required this.actualQty,
    required this.plannedQty,
    required this.indentedQty,
    required this.orderedQty,
    required this.projectedQty,
    required this.reservedQty,
    required this.reservedQtyForProduction,
    required this.reservedQtyForSubContract,
    required this.reservedQtyForProductionPlan,
    required this.reservedStock,
    required this.stockUom,
    required this.valuationRate,
    required this.stockValue,
  });

  factory Bin.fromJson(Map<String, dynamic> json) {
    return Bin(
      name: json['name'] ?? '',
      owner: json['owner'] ?? '',
      creation: json['creation'] ?? '',
      modified: json['modified'] ?? '',
      modifiedBy: json['modified_by'] ?? '',
      docstatus: json['docstatus'] ?? 0,
      idx: json['idx'] ?? 0,
      itemCode: json['item_code'] ?? '',
      warehouse: json['warehouse'] ?? '',
      actualQty: (json['actual_qty'] ?? 0).toDouble(),
      plannedQty: (json['planned_qty'] ?? 0).toDouble(),
      indentedQty: (json['indented_qty'] ?? 0).toDouble(),
      orderedQty: (json['ordered_qty'] ?? 0).toDouble(),
      projectedQty: (json['projected_qty'] ?? 0).toDouble(),
      reservedQty: (json['reserved_qty'] ?? 0).toDouble(),
      reservedQtyForProduction: (json['reserved_qty_for_production'] ?? 0).toDouble(),
      reservedQtyForSubContract: (json['reserved_qty_for_sub_contract'] ?? 0).toDouble(),
      reservedQtyForProductionPlan: (json['reserved_qty_for_production_plan'] ?? 0).toDouble(),
      reservedStock: (json['reserved_stock'] ?? 0).toDouble(),
      stockUom: json['stock_uom'] ?? '',
      valuationRate: (json['valuation_rate'] ?? 0).toDouble(),
      stockValue: (json['stock_value'] ?? 0).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'owner': owner,
      'creation': creation,
      'modified': modified,
      'modified_by': modifiedBy,
      'docstatus': docstatus,
      'idx': idx,
      'item_code': itemCode,
      'warehouse': warehouse,
      'actual_qty': actualQty,
      'planned_qty': plannedQty,
      'indented_qty': indentedQty,
      'ordered_qty': orderedQty,
      'projected_qty': projectedQty,
      'reserved_qty': reservedQty,
      'reserved_qty_for_production': reservedQtyForProduction,
      'reserved_qty_for_sub_contract': reservedQtyForSubContract,
      'reserved_qty_for_production_plan': reservedQtyForProductionPlan,
      'reserved_stock': reservedStock,
      'stock_uom': stockUom,
      'valuation_rate': valuationRate,
      'stock_value': stockValue,
    };
  }
}
