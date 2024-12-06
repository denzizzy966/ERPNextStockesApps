class ItemReorder {
  final String name;
  final String warehouse;
  final String warehouseGroup;
  final double reorderLevel;
  final double reorderQty;
  final String materialRequestType;

  ItemReorder({
    required this.name,
    required this.warehouse,
    required this.warehouseGroup,
    required this.reorderLevel,
    required this.reorderQty,
    required this.materialRequestType,
  });

  factory ItemReorder.fromJson(Map<String, dynamic> json) {
    return ItemReorder(
      name: json['name'] ?? '',
      warehouse: json['warehouse'] ?? '',
      warehouseGroup: json['warehouse_group'] ?? '',
      reorderLevel: (json['warehouse_reorder_level'] ?? 0.0).toDouble(),
      reorderQty: (json['warehouse_reorder_qty'] ?? 0.0).toDouble(),
      materialRequestType: json['material_request_type'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'warehouse': warehouse,
      'warehouse_group': warehouseGroup,
      'warehouse_reorder_level': reorderLevel,
      'warehouse_reorder_qty': reorderQty,
      'material_request_type': materialRequestType,
      'doctype': 'Item Reorder',
    };
  }
}

class Item {
  final String name;
  final String itemCode;
  final String itemName;
  final String itemGroup;
  final String description;
  final int disabled;
  final String uom;
  final String brand;
  final double openingStock;
  final double valuationRate;
  final String defaultWarehouse;
  final String customBarcode;
  final List<ItemReorder> reorderLevels;

  Item({
    required this.name,
    required this.itemCode,
    required this.itemName,
    required this.itemGroup,
    required this.description,
    required this.disabled,
    required this.uom,
    required this.brand,
    required this.openingStock,
    required this.valuationRate,
    required this.defaultWarehouse,
    required this.customBarcode,
    required this.reorderLevels,
  });

  factory Item.fromJson(Map<String, dynamic> json) {
    List<ItemReorder> reorderLevels = [];
    if (json['reorder_levels'] != null) {
      reorderLevels = (json['reorder_levels'] as List)
          .map((level) => ItemReorder.fromJson(level))
          .toList();
    }

    return Item(
      name: json['name'] ?? '',
      itemCode: json['item_code'] ?? '',
      itemName: json['item_name'] ?? '',
      itemGroup: json['item_group'] ?? '',
      description: json['description'] ?? '',
      disabled: json['disabled'] ?? 0,
      uom: json['stock_uom'] ?? '',
      brand: json['brand'] ?? '',
      openingStock: (json['opening_stock'] ?? 0.0).toDouble(),
      valuationRate: (json['valuation_rate'] ?? 0.0).toDouble(),
      defaultWarehouse: json['default_warehouse'] ?? '',
      customBarcode: json['custom_barcode'] ?? '',
      reorderLevels: reorderLevels,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'item_code': itemCode,
      'item_name': itemName,
      'item_group': itemGroup,
      'description': description,
      'disabled': disabled,
      'stock_uom': uom,
      'brand': brand,
      'opening_stock': openingStock,
      'valuation_rate': valuationRate,
      'default_warehouse': defaultWarehouse,
      'custom_barcode': customBarcode,
      'reorder_levels': reorderLevels.map((level) => level.toJson()).toList(),
      'doctype': 'Item',
    };
  }

  bool get isDisabled => disabled == 1;
}
