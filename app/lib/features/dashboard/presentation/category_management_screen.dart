import 'package:flutter/material.dart';
import '../../../core/di.dart';
import '../../../core/app_snackbar.dart';
import '../../../core/loading_button.dart';
import '../data/admin_repository.dart';

class CategoryManagementScreen extends StatefulWidget {
  const CategoryManagementScreen({super.key});

  @override
  State<CategoryManagementScreen> createState() =>
      _CategoryManagementScreenState();
}

class _CategoryManagementScreenState extends State<CategoryManagementScreen> {
  List<dynamic> _categories = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadCategories();
  }

  Future<void> _loadCategories() async {
    setState(() => _isLoading = true);
    try {
      final data = await sl<AdminRepository>().fetchCategories();
      setState(() {
        _categories = data;
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) {
        AppSnackBar.error(context, e.toString());
        setState(() => _isLoading = false);
      }
    }
  }

  void _showAddCategoryDialog() {
    final nameCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        bool isSaving = false;
        return StatefulBuilder(
          builder: (context, setStateBuilder) => AlertDialog(
            title: const Text('Add Category'),
            content: TextField(
              controller: nameCtrl,
              decoration: const InputDecoration(labelText: 'Category Name'),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              LoadingButton(
                isLoading: isSaving,
                label: 'Add',
                onPressed: () async {
                  if (nameCtrl.text.isEmpty) return;
                  setStateBuilder(() => isSaving = true);
                  try {
                    await sl<AdminRepository>().createCategory(nameCtrl.text);
                    if (!context.mounted) return;
                    AppSnackBar.success(
                      context,
                      'Category created successfully',
                    );
                    Navigator.pop(context);
                    _loadCategories();
                  } catch (e) {
                    if (!context.mounted) return;
                    AppSnackBar.error(context, e.toString());
                  } finally {
                    if (context.mounted) {
                      setStateBuilder(() => isSaving = false);
                    }
                  }
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _showEditCategoryDialog(dynamic category) {
    bool isActive = category['is_active'];
    final nameCtrl = TextEditingController(text: category['name']);

    showDialog(
      context: context,
      builder: (context) {
        bool isSaving = false;
        return StatefulBuilder(
          builder: (context, setStateBuilder) => AlertDialog(
            title: const Text('Edit Category'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameCtrl,
                  decoration: const InputDecoration(labelText: 'Category Name'),
                ),
                SwitchListTile(
                  title: const Text('Active'),
                  value: isActive,
                  onChanged: (val) => setStateBuilder(() => isActive = val),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              LoadingButton(
                isLoading: isSaving,
                label: 'Save',
                onPressed: () async {
                  setStateBuilder(() => isSaving = true);
                  try {
                    await sl<AdminRepository>().updateCategory(
                      category['id'],
                      nameCtrl.text,
                      isActive,
                    );
                    if (!context.mounted) return;
                    AppSnackBar.success(
                      context,
                      'Category updated successfully',
                    );
                    Navigator.pop(context);
                    _loadCategories();
                  } catch (e) {
                    if (!context.mounted) return;
                    AppSnackBar.error(context, e.toString());
                  } finally {
                    if (context.mounted) {
                      setStateBuilder(() => isSaving = false);
                    }
                  }
                },
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Category Management')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              itemCount: _categories.length,
              itemBuilder: (context, index) {
                final c = _categories[index];
                return ListTile(
                  title: Text(c['name']),
                  trailing: Icon(
                    c['is_active'] ? Icons.check_circle : Icons.cancel,
                    color: c['is_active'] ? Colors.green : Colors.red,
                  ),
                  onTap: () => _showEditCategoryDialog(c),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddCategoryDialog,
        child: const Icon(Icons.add),
      ),
    );
  }
}
