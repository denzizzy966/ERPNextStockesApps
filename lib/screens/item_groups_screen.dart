import 'package:flutter/material.dart';
import '../models/item_group.dart';
import '../services/api_service.dart';

class ItemGroupsScreen extends StatefulWidget {
  const ItemGroupsScreen({super.key});

  @override
  State<ItemGroupsScreen> createState() => _ItemGroupsScreenState();
}

class _ItemGroupsScreenState extends State<ItemGroupsScreen> {
  final ApiService _apiService = ApiService();
  List<ItemGroup> _itemGroups = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadItemGroups();
  }

  Future<void> _loadItemGroups() async {
    setState(() {
      _isLoading = true;
    });

    try {
      print('Loading item groups...');
      final groups = await _apiService.getItemGroups();
      print('Received item groups data: $groups');
      
      setState(() {
        _itemGroups = groups.map((json) {
          try {
            return ItemGroup.fromJson(json);
          } catch (e) {
            print('Error parsing item group: $e');
            print('Problematic JSON: $json');
            return null;
          }
        }).where((group) => group != null).cast<ItemGroup>().toList();
      });
      
      print('Successfully parsed ${_itemGroups.length} item groups');
    } catch (e, stackTrace) {
      print('Error in _loadItemGroups: $e');
      print('Stack trace: $stackTrace');
      _showError('Failed to load item groups: ${e.toString()}');
    } finally {
      setState(() {
        _isLoading = false;
      });
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

  Future<void> _deleteItemGroup(ItemGroup group) async {
    try {
      print('Deleting item group: ${group.name}');
      await _apiService.deleteItemGroup(group.name);
      await _loadItemGroups();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Item group deleted successfully')),
        );
      }
    } catch (e) {
      print('Error deleting item group: $e');
      _showError('Failed to delete item group: ${e.toString()}');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Item Groups'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _showItemGroupDialog(),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadItemGroups,
              child: _itemGroups.isEmpty
                  ? Center(
                      child: Text(
                        'No item groups found',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                    )
                  : ListView.builder(
                      itemCount: _itemGroups.length,
                      padding: const EdgeInsets.all(8),
                      itemBuilder: (context, index) {
                        final group = _itemGroups[index];
                        return Card(
                          elevation: 2,
                          margin: const EdgeInsets.symmetric(
                            vertical: 4,
                            horizontal: 8,
                          ),
                          child: ListTile(
                            title: Text(
                              group.itemGroupName,
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (group.parentItemGroup.isNotEmpty)
                                  Text('Parent: ${group.parentItemGroup}'),
                                if (group.description.isNotEmpty)
                                  Text('Description: ${group.description}'),
                                Text('Is Group: ${group.isGroup ? 'Yes' : 'No'}'),
                              ],
                            ),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.edit),
                                  onPressed: () => _showItemGroupDialog(group: group),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete),
                                  onPressed: () => _showDeleteConfirmation(group),
                                ),
                              ],
                            ),
                            isThreeLine: true,
                          ),
                        );
                      },
                    ),
            ),
    );
  }

  Future<void> _showDeleteConfirmation(ItemGroup group) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Item Group'),
        content: Text('Are you sure you want to delete ${group.itemGroupName}?'),
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
      await _deleteItemGroup(group);
    }
  }

  Future<void> _showItemGroupDialog({ItemGroup? group}) async {
    final formKey = GlobalKey<FormState>();
    final nameController = TextEditingController(text: group?.itemGroupName);
    final parentController = TextEditingController(text: group?.parentItemGroup);
    final descriptionController = TextEditingController(text: group?.description);
    bool isGroup = group?.isGroup ?? false;

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(group == null ? 'Add Item Group' : 'Edit Item Group'),
        content: SingleChildScrollView(
          child: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: nameController,
                  decoration: const InputDecoration(labelText: 'Item Group Name'),
                  validator: (value) =>
                      value?.isEmpty ?? true ? 'Required field' : null,
                ),
                TextFormField(
                  controller: parentController,
                  decoration: const InputDecoration(labelText: 'Parent Item Group'),
                ),
                TextFormField(
                  controller: descriptionController,
                  decoration: const InputDecoration(labelText: 'Description'),
                  maxLines: 3,
                ),
                SwitchListTile(
                  title: const Text('Is Group'),
                  value: isGroup,
                  onChanged: (value) {
                    isGroup = value;
                  },
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
                final groupData = {
                  'item_group_name': nameController.text,
                  'parent_item_group': parentController.text,
                  'description': descriptionController.text,
                  'is_group': isGroup ? 1 : 0,
                };

                try {
                  print('Submitting item group data: $groupData');
                  if (group == null) {
                    await _apiService.createItemGroup(groupData);
                  } else {
                    await _apiService.updateItemGroup(group.name, groupData);
                  }
                  if (mounted) {
                    Navigator.pop(context);
                    await _loadItemGroups();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          group == null
                              ? 'Item group created successfully'
                              : 'Item group updated successfully',
                        ),
                      ),
                    );
                  }
                } catch (e) {
                  print('Error saving item group: $e');
                  if (mounted) {
                    Navigator.pop(context);
                    _showError(
                      'Failed to ${group == null ? 'create' : 'update'} item group: ${e.toString()}',
                    );
                  }
                }
              }
            },
            child: Text(group == null ? 'Create' : 'Update'),
          ),
        ],
      ),
    );
  }
}
