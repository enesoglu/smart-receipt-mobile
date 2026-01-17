import 'package:flutter/material.dart';
import '../services/api_service.dart';

class CategoriesScreen extends StatefulWidget {
  const CategoriesScreen({super.key});

  @override
  State<CategoriesScreen> createState() => _CategoriesScreenState();
}

class _CategoriesScreenState extends State<CategoriesScreen> {
  final ApiService _apiService = ApiService();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();

  List<Category> _categories = [];
  bool _isLoading = true;
  String? _selectedIcon;

  final List<Map<String, dynamic>> _iconOptions = [
    {'value': 'shopping_cart', 'label': 'Shopping', 'icon': Icons.shopping_cart},
    {'value': 'restaurant', 'label': 'Restaurant', 'icon': Icons.restaurant},
    {'value': 'local_gas_station', 'label': 'Fuel', 'icon': Icons.local_gas_station},
    {'value': 'medical_services', 'label': 'Health', 'icon': Icons.medical_services},
    {'value': 'directions_car', 'label': 'Transportation', 'icon': Icons.directions_car},
    {'value': 'movie', 'label': 'Entertainment', 'icon': Icons.movie},
    {'value': 'home', 'label': 'Home', 'icon': Icons.home},
    {'value': 'work', 'label': 'Work', 'icon': Icons.work},
    {'value': 'school', 'label': 'Education', 'icon': Icons.school},
    {'value': 'other', 'label': 'Other', 'icon': Icons.category},
  ];

  @override
  void initState() {
    super.initState();
    _loadCategories();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _loadCategories() async {
    setState(() => _isLoading = true);

    final response = await _apiService.getCategories();

    setState(() {
      _isLoading = false;
      if (response.success && response.data != null) {
        _categories = response.data!;
      }
    });
  }

  IconData _getIconForName(String? iconName) {
    final iconOption = _iconOptions.firstWhere(
      (opt) => opt['value'] == iconName,
      orElse: () => _iconOptions.last,
    );
    return iconOption['icon'] as IconData;
  }

  Future<void> _addCategory() async {
    if (_nameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Category name is required'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final response = await _apiService.createCategory(
      _nameController.text.trim(),
      _descriptionController.text.trim().isNotEmpty ? _descriptionController.text.trim() : null,
      _selectedIcon,
    );

    if (response.success) {
      _nameController.clear();
      _descriptionController.clear();
      setState(() => _selectedIcon = null);
      Navigator.pop(context);
      _loadCategories();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Category added successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(response.message ?? 'Error adding category'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _deleteCategory(int id) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Category'),
        content: const Text('Are you sure you want to delete this category?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final response = await _apiService.deleteCategory(id);

      if (response.success) {
        _loadCategories();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Category deleted'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(response.message ?? 'Error deleting category'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  void _showAddCategoryDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
          left: 16,
          right: 16,
          top: 16,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Add New Category',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Category Name *',
                border: OutlineInputBorder(),
                hintText: 'e.g. Grocery, Restaurant...',
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _descriptionController,
              decoration: const InputDecoration(
                labelText: 'Description (Optional)',
                border: OutlineInputBorder(),
                hintText: 'Category description',
              ),
              maxLines: 2,
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: _selectedIcon,
              decoration: const InputDecoration(
                labelText: 'Icon',
                border: OutlineInputBorder(),
              ),
              items: _iconOptions.map((opt) => DropdownMenuItem<String>(
                value: opt['value'] as String,
                child: Row(
                  children: [
                    Icon(opt['icon'] as IconData, size: 20),
                    const SizedBox(width: 8),
                    Text(opt['label'] as String),
                  ],
                ),
              )).toList(),
              onChanged: (value) => setState(() => _selectedIcon = value),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _addCategory,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF4A6CFA),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Add Category',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Categories',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add, color: Color(0xFF4A6CFA)),
            onPressed: _showAddCategoryDialog,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _categories.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.category_outlined, size: 80, color: Colors.grey[400]),
                      const SizedBox(height: 16),
                      Text(
                        'No categories added yet',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey[600],
                        ),
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton.icon(
                        onPressed: _showAddCategoryDialog,
                        icon: const Icon(Icons.add),
                        label: const Text('Add Category'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF4A6CFA),
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadCategories,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _categories.length,
                    itemBuilder: (context, index) {
                      final category = _categories[index];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          leading: Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              color: const Color(0xFF4A6CFA).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(
                              _getIconForName(category.iconName),
                              color: const Color(0xFF4A6CFA),
                            ),
                          ),
                          title: Text(
                            category.name,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          subtitle: category.description != null
                              ? Text(
                                  category.description!,
                                  style: TextStyle(color: Colors.grey[600]),
                                )
                              : null,
                          trailing: IconButton(
                            icon: const Icon(Icons.delete_outline, color: Colors.red),
                            onPressed: () => _deleteCategory(category.id),
                          ),
                        ),
                      );
                    },
                  ),
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddCategoryDialog,
        backgroundColor: const Color(0xFF4A6CFA),
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}
