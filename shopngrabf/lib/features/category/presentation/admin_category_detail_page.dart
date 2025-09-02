import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../shared/widgets/loading_indicator.dart';
import '../../../shared/widgets/custom_button.dart';
import '../../../shared/widgets/custom_text_field.dart';
import '../domain/category_model.dart';
import 'category_provider.dart';

class AdminCategoryDetailPage extends StatefulWidget {
  const AdminCategoryDetailPage({super.key, this.category});
  final Category? category;

  static const routeName = '/admin/category-detail';

  @override
  State<AdminCategoryDetailPage> createState() => _AdminCategoryDetailPageState();
}

class _AdminCategoryDetailPageState extends State<AdminCategoryDetailPage> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _descriptionController;
  late TextEditingController _sortOrderController;
  bool _isFeatured = false;
  Color? _color;
  bool _isActive = true;
  int? _parentId;
  
  @override
  void initState() {
    super.initState();
    final cat = widget.category;
    _nameController = TextEditingController(text: cat?.name);
    _descriptionController = TextEditingController(text: cat?.description);
    _sortOrderController = TextEditingController(text: cat?.sortOrder.toString());
    _isFeatured = cat?.isFeatured ?? false;
    _color = cat?.categoryColor;
    _isActive = cat?.isActive ?? true;
    _parentId = cat?.parentId;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _sortOrderController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.read<CategoryProvider>();
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.category == null ? 'Create Category' : 'Edit Category'),
      ),
      body: consumer(provider),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(16),
        child: CustomButton(
          onPressed: provider.isCreatingCategory || provider.isUpdatingCategory ? null : _save,
          child: (provider.isCreatingCategory || provider.isUpdatingCategory)
              ? const LoadingIndicator(size: 20)
              : Text(widget.category == null ? 'Create' : 'Update'),
        ),
      ),
    );
  }

  Widget consumer(CategoryProvider provider) {
    return Form(
      key: _formKey,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          CustomTextField(
            controller: _nameController,
            label: 'Name',
            validator: (v) => v == null || v.isEmpty ? 'Required' : null,
          ),
          const SizedBox(height: 16),
          CustomTextField(
            controller: _descriptionController,
            label: 'Description',
            maxLines: 3,
          ),
          const SizedBox(height: 16),
          CustomTextField(
            controller: _sortOrderController,
            label: 'Sort Order',
            keyboardType: TextInputType.number,
          ),
          const SizedBox(height: 16),
          SwitchListTile(
            title: const Text('Featured'),
            value: _isFeatured,
            onChanged: (v) => setState(() => _isFeatured = v),
          ),
          SwitchListTile(
            title: const Text('Active'),
            value: _isActive,
            onChanged: (v) => setState(() => _isActive = v),
          ),
          const SizedBox(height: 16),
          // Parent category dropdown
          DropdownButtonFormField<int>(
            value: _parentId,
            decoration: const InputDecoration(labelText: 'Parent Category'),
            items: [null, ...provider.adminCategories].map((c) {
              return DropdownMenuItem<int>(
                value: c?.id,
                child: Text(c?.name ?? 'None'),
              );
            }).toList(),
            onChanged: (v) => setState(() => _parentId = v),
          ),
          const SizedBox(height: 16),
          // Color picker placeholder
          OutlinedButton(
            onPressed: () {
              // TODO: Open color picker
            },
            child: const Text('Select Category Color'),
          ),
        ],
      ),
    );
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final provider = context.read<CategoryProvider>();
    final req = widget.category == null
        ? CreateCategoryRequest(
            name: _nameController.text.trim(),
            description: _descriptionController.text.trim(),
            parentId: _parentId,
            sortOrder: int.tryParse(_sortOrderController.text.trim()) ?? 0,
            isFeatured: _isFeatured,
            isActive: _isActive,
            colorCode: _color != null ? '#${_color!.value.toRadixString(16).substring(2)}' : null,
          )
        : UpdateCategoryRequest(
            name: _nameController.text.trim(),
            description: _descriptionController.text.trim(),
            parentId: _parentId,
            sortOrder: int.tryParse(_sortOrderController.text.trim()),
            isFeatured: _isFeatured,
            isActive: _isActive,
            colorCode: _color != null ? '#${_color!.value.toRadixString(16).substring(2)}' : null,
          );

    if (widget.category == null) {
      final created = await provider.createCategory(req);
      if (created != null && mounted) Navigator.pop(context);
    } else {
      final updated = await provider.updateCategory(widget.category!.id, (req as UpdateCategoryRequest));
      if (updated != null && mounted) Navigator.pop(context);
    }
  }
}
