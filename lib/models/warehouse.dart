class Warehouse {
  final String name;
  final String warehouseName;
  final String warehouseType;
  final int disabled;  // Changed from bool to int
  final String company;
  final String parentWarehouse;
  final String accountHead;
  final int isGroup;  // Changed from bool to int
  final String address;

  Warehouse({
    required this.name,
    required this.warehouseName,
    required this.warehouseType,
    required this.disabled,
    required this.company,
    required this.parentWarehouse,
    required this.accountHead,
    required this.isGroup,
    required this.address,
  });

  factory Warehouse.fromJson(Map<String, dynamic> json) {
    return Warehouse(
      name: json['name'] ?? '',
      warehouseName: json['warehouse_name'] ?? '',
      warehouseType: json['warehouse_type'] ?? '',
      disabled: json['disabled'] ?? 0,  // Default to 0 instead of false
      company: json['company'] ?? '',
      parentWarehouse: json['parent_warehouse'] ?? '',
      accountHead: json['account'] ?? '',
      isGroup: json['is_group'] ?? 0,  // Default to 0 instead of false
      address: json['address_line_1'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'warehouse_name': warehouseName,
      'warehouse_type': warehouseType,
      'disabled': disabled,
      'company': company,
      'parent_warehouse': parentWarehouse,
      'account': accountHead,
      'is_group': isGroup,
      'address_line_1': address,
      'doctype': 'Warehouse',  // Added doctype field
    };
  }

  bool get isDisabled => disabled == 1;  // Helper method to convert int to bool
  bool get isGroupWarehouse => isGroup == 1;  // Helper method to convert int to bool

  @override
  String toString() {
    return warehouseName;
  }
}
