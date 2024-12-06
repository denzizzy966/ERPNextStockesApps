class ItemGroup {
  final String name;
  final String itemGroupName;
  final bool isGroup;
  final String parentItemGroup;
  final int disabled;
  final String description;

  ItemGroup({
    required this.name,
    required this.itemGroupName,
    required this.isGroup,
    required this.parentItemGroup,
    required this.disabled,
    required this.description,
  });

  factory ItemGroup.fromJson(Map<String, dynamic> json) {
    return ItemGroup(
      name: json['name'] ?? '',
      itemGroupName: json['item_group_name'] ?? '',
      isGroup: json['is_group'] == 1,
      parentItemGroup: json['parent_item_group'] ?? '',
      disabled: json['disabled'] ?? 0,
      description: json['description'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'item_group_name': itemGroupName,
      'is_group': isGroup ? 1 : 0,
      'parent_item_group': parentItemGroup,
      'disabled': disabled,
      'description': description,
      'doctype': 'Item Group',
    };
  }

  @override
  String toString() => itemGroupName;
}
