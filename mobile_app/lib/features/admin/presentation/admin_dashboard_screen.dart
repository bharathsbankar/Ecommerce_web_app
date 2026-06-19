import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/flipkart_scaffold.dart';
import '../../catalog/domain/product.dart';
import '../../catalog/presentation/catalog_controller.dart';

class AdminDashboardScreen extends ConsumerWidget {
  const AdminDashboardScreen({super.key});

  void _openProductForm(BuildContext context, WidgetRef ref, [Product? product]) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => _ProductFormDialog(product: product),
    );
  }

  Future<void> _handleDelete(BuildContext context, WidgetRef ref, Product product) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Product'),
        content: Text('Are you sure you want to delete ${product.name}?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('CANCEL')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.errorRed),
            child: const Text('DELETE'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      final success = await ref.read(catalogProvider.notifier).deleteProduct(product.id);
      if (success) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Product deleted successfully'), backgroundColor: AppColors.emeraldGreen),
          );
        }
      } else {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Failed to delete product'), backgroundColor: AppColors.errorRed),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final catalogState = ref.watch(catalogProvider);

    return FlipkartScaffold(
      title: 'Admin Dashboard',
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.flipkartBlue,
        foregroundColor: Colors.white,
        onPressed: () => _openProductForm(context, ref),
        child: const Icon(LucideIcons.plus),
      ),
      body: RefreshIndicator(
        onRefresh: () => ref.read(catalogProvider.notifier).fetchProducts(),
        child: catalogState.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (err, _) => Center(child: Text('Failed to load products: $err')),
          data: (products) {
            if (products.isEmpty) {
              return ListView(
                children: const [
                  SizedBox(height: 100),
                  Center(child: Text('No products in catalog. Add some items!')),
                ],
              );
            }

            return ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: products.length,
              itemBuilder: (context, index) {
                final p = products[index];

                return Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    leading: const CircleAvatar(
                      backgroundColor: AppColors.background,
                      child: Text('📦', style: TextStyle(fontSize: 18)),
                    ),
                    title: Text(p.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Price: ₹${p.price.toStringAsFixed(2)}', style: const TextStyle(fontSize: 12)),
                        Text('True Stock: ${p.stockQuantity}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
                      ],
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(LucideIcons.edit, color: AppColors.flipkartBlue, size: 18),
                          onPressed: () => _openProductForm(context, ref, p),
                        ),
                        IconButton(
                          icon: const Icon(LucideIcons.trash2, color: AppColors.errorRed, size: 18),
                          onPressed: () => _handleDelete(context, ref, p),
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}

class _ProductFormDialog extends ConsumerStatefulWidget {
  final Product? product;

  const _ProductFormDialog({this.product});

  @override
  ConsumerState<_ProductFormDialog> createState() => _ProductFormDialogState();
}

class _ProductFormDialogState extends ConsumerState<_ProductFormDialog> {
  final _formKey = GlobalKey<FormState>();
  
  late final TextEditingController _nameController;
  late final TextEditingController _descController;
  late final TextEditingController _priceController;
  late final TextEditingController _stockController;

  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.product?.name ?? '');
    _descController = TextEditingController(text: widget.product?.description ?? '');
    _priceController = TextEditingController(text: widget.product?.price.toString() ?? '');
    _stockController = TextEditingController(text: widget.product?.stockQuantity.toString() ?? '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descController.dispose();
    _priceController.dispose();
    _stockController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _saving = true;
      _error = null;
    });

    final name = _nameController.text.trim();
    final desc = _descController.text.trim();
    final price = double.parse(_priceController.text.trim());
    final stock = int.parse(_stockController.text.trim());

    bool success;
    if (widget.product != null) {
      success = await ref.read(catalogProvider.notifier).updateProduct(
        widget.product!.id,
        name,
        desc,
        price,
        stock,
      );
    } else {
      success = await ref.read(catalogProvider.notifier).createProduct(
        name,
        desc,
        price,
        stock,
      );
    }

    setState(() {
      _saving = false;
    });

    if (success) {
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(widget.product != null ? 'Product updated successfully' : 'Product created successfully'),
            backgroundColor: AppColors.emeraldGreen,
          ),
        );
      }
    } else {
      setState(() {
        _error = 'Failed to save product. Ensure name, price and stock are valid.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.product != null;

    return AlertDialog(
      title: Text(isEdit ? 'Edit Product' : 'Add New Product'),
      content: SizedBox(
        width: double.maxFinite,
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (_error != null)
                  Container(
                    padding: const EdgeInsets.all(8),
                    margin: const EdgeInsets.only(bottom: 12),
                    color: Colors.red.shade50,
                    child: Text(
                      _error!,
                      style: TextStyle(color: Colors.red.shade900, fontSize: 11),
                    ),
                  ),
                
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(labelText: 'Product Name'),
                  validator: (val) => val == null || val.trim().isEmpty ? 'Name is required' : null,
                ),
                const SizedBox(height: 12),
                
                TextFormField(
                  controller: _descController,
                  decoration: const InputDecoration(labelText: 'Description'),
                  maxLines: 2,
                ),
                const SizedBox(height: 12),
                
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _priceController,
                        decoration: const InputDecoration(labelText: 'Price (₹)'),
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        validator: (val) {
                          if (val == null || val.trim().isEmpty) return 'Required';
                          final num = double.tryParse(val.trim());
                          if (num == null || num <= 0) return 'Invalid';
                          return null;
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        controller: _stockController,
                        decoration: const InputDecoration(labelText: 'Stock'),
                        keyboardType: TextInputType.number,
                        validator: (val) {
                          if (val == null || val.trim().isEmpty) return 'Required';
                          final num = int.tryParse(val.trim());
                          if (num == null || num < 0) return 'Invalid';
                          return null;
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _saving ? null : () => Navigator.pop(context),
          child: const Text('CANCEL'),
        ),
        ElevatedButton(
          onPressed: _saving ? null : _submit,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.flipkartBlue,
            foregroundColor: Colors.white,
          ),
          child: _saving
              ? const SizedBox(height: 16, width: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
              : Text(isEdit ? 'UPDATE' : 'CREATE'),
        ),
      ],
    );
  }
}
