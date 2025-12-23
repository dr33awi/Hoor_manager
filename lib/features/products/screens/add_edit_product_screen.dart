// lib/features/products/screens/add_edit_product_screen.dart
// شاشة إضافة/تعديل منتج - تصميم حديث

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../providers/product_provider.dart';
import '../models/product_model.dart';

class AddEditProductScreen extends StatefulWidget {
  final ProductModel? product;
  const AddEditProductScreen({super.key, this.product});

  @override
  State<AddEditProductScreen> createState() => _AddEditProductScreenState();
}

class _AddEditProductScreenState extends State<AddEditProductScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _brandController = TextEditingController();
  final _priceController = TextEditingController();
  final _costPriceController = TextEditingController();

  String? _selectedCategory;
  late List<String> _colors;
  late List<int> _sizes;
  late Map<String, int> _inventory;
  bool _isLoading = false;
  bool _isCategoriesLoading = true;

  bool get isEditing => widget.product != null;

  @override
  void initState() {
    super.initState();
    _colors = [];
    _sizes = [];
    _inventory = {};
    if (isEditing) _loadProductData();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadCategories());
  }

  Future<void> _loadCategories() async {
    if (!mounted) return;
    final provider = context.read<ProductProvider>();
    if (provider.categories.isEmpty) await provider.loadCategories();
    if (mounted) setState(() => _isCategoriesLoading = false);
  }

  void _loadProductData() {
    final p = widget.product!;
    _nameController.text = p.name;
    _descriptionController.text = p.description;
    _brandController.text = p.brand;
    _priceController.text = p.price.toString();
    _costPriceController.text = p.costPrice.toString();
    _selectedCategory = p.category;
    _colors = p.colors.toSet().toList();
    _sizes = (p.sizes.toSet().toList())..sort();
    _inventory = Map.from(p.inventory);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _brandController.dispose();
    _priceController.dispose();
    _costPriceController.dispose();
    super.dispose();
  }

  void _showSnackBar(String msg, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: isError
            ? const Color(0xFFEF4444)
            : const Color(0xFF10B981),
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(20),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  InputDecoration _inputDeco(String label, IconData icon, {String? suffix}) {
    return InputDecoration(
      labelText: label,
      labelStyle: TextStyle(color: Colors.grey.shade500, fontSize: 14),
      prefixIcon: Icon(icon, color: Colors.grey.shade400, size: 20),
      suffixText: suffix,
      filled: true,
      fillColor: Colors.grey.shade50,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: Colors.grey.shade200),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: Colors.grey.shade200),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Color(0xFF1A1A2E), width: 1.5),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(
            Icons.arrow_back_ios_rounded,
            size: 18,
            color: Color(0xFF1A1A2E),
          ),
        ),
        title: Text(
          isEditing ? 'تعديل المنتج' : 'إضافة منتج',
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Color(0xFF1A1A2E),
          ),
        ),
        centerTitle: true,
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildBasicInfo(),
              const SizedBox(height: 24),
              _buildColorsSection(),
              const SizedBox(height: 24),
              _buildSizesSection(),
              if (_colors.isNotEmpty && _sizes.isNotEmpty) ...[
                const SizedBox(height: 24),
                _buildInventory(),
              ],
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _saveProduct,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1A1A2E),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : Text(
                          isEditing ? 'تحديث' : 'إضافة',
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBasicInfo() {
    return Consumer<ProductProvider>(
      builder: (context, provider, _) {
        final cats = provider.categories.map((c) => c.name).toSet().toList();
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Colors.grey.shade100),
          ),
          child: Column(
            children: [
              TextFormField(
                controller: _nameController,
                decoration: _inputDeco(
                  'اسم المنتج *',
                  Icons.inventory_2_outlined,
                ),
                validator: (v) => v?.isEmpty == true ? 'مطلوب' : null,
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _descriptionController,
                decoration: _inputDeco('الوصف', Icons.description_outlined),
                maxLines: 2,
              ),
              const SizedBox(height: 14),
              _isCategoriesLoading
                  ? const CircularProgressIndicator()
                  : Row(
                      children: [
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            value: cats.contains(_selectedCategory)
                                ? _selectedCategory
                                : null,
                            decoration: _inputDeco(
                              'الفئة *',
                              Icons.category_outlined,
                            ),
                            items: cats
                                .map(
                                  (n) => DropdownMenuItem(
                                    value: n,
                                    child: Text(n),
                                  ),
                                )
                                .toList(),
                            onChanged: (v) =>
                                setState(() => _selectedCategory = v),
                            validator: (v) => v == null ? 'مطلوب' : null,
                          ),
                        ),
                        const SizedBox(width: 8),
                        GestureDetector(
                          onTap: _addCategory,
                          child: Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: const Color(0xFF1A1A2E).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(
                              Icons.add,
                              color: Color(0xFF1A1A2E),
                            ),
                          ),
                        ),
                      ],
                    ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _brandController,
                decoration: _inputDeco(
                  'العلامة التجارية',
                  Icons.branding_watermark_outlined,
                ),
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _priceController,
                      keyboardType: TextInputType.number,
                      decoration: _inputDeco(
                        'سعر البيع *',
                        Icons.attach_money,
                        suffix: 'ر.س',
                      ),
                      validator: (v) => v?.isEmpty == true ? 'مطلوب' : null,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _costPriceController,
                      keyboardType: TextInputType.number,
                      decoration: _inputDeco(
                        'التكلفة *',
                        Icons.money_off_outlined,
                        suffix: 'ر.س',
                      ),
                      validator: (v) => v?.isEmpty == true ? 'مطلوب' : null,
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildColorsSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'الألوان',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              GestureDetector(
                onTap: _addColor,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1A1A2E),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text(
                    '+ إضافة',
                    style: TextStyle(color: Colors.white, fontSize: 12),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _colors.isEmpty
              ? Text(
                  'لم يتم إضافة ألوان',
                  style: TextStyle(color: Colors.grey.shade400),
                )
              : Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _colors
                      .map(
                        (c) => Chip(
                          label: Text(c),
                          onDeleted: () => setState(() {
                            _colors.remove(c);
                            _inventory.removeWhere(
                              (k, _) => k.startsWith('$c-'),
                            );
                          }),
                        ),
                      )
                      .toList(),
                ),
        ],
      ),
    );
  }

  Widget _buildSizesSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'المقاسات',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              GestureDetector(
                onTap: _addSize,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1A1A2E),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text(
                    '+ إضافة',
                    style: TextStyle(color: Colors.white, fontSize: 12),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _sizes.isEmpty
              ? Text(
                  'لم يتم إضافة مقاسات',
                  style: TextStyle(color: Colors.grey.shade400),
                )
              : Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _sizes
                      .map(
                        (s) => Chip(
                          label: Text('$s'),
                          onDeleted: () => setState(() {
                            _sizes.remove(s);
                            _inventory.removeWhere((k, _) => k.endsWith('-$s'));
                          }),
                        ),
                      )
                      .toList(),
                ),
        ],
      ),
    );
  }

  Widget _buildInventory() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('المخزون', style: TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(height: 12),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              headingRowColor: WidgetStateProperty.all(Colors.grey.shade50),
              columns: [
                const DataColumn(label: Text('اللون')),
                ..._sizes.map(
                  (s) => DataColumn(label: Text('$s'), numeric: true),
                ),
              ],
              rows: _colors
                  .map(
                    (c) => DataRow(
                      cells: [
                        DataCell(Text(c)),
                        ..._sizes.map((s) {
                          final k = '$c-$s';
                          return DataCell(
                            SizedBox(
                              width: 50,
                              child: TextFormField(
                                initialValue: (_inventory[k] ?? 0).toString(),
                                keyboardType: TextInputType.number,
                                textAlign: TextAlign.center,
                                inputFormatters: [
                                  FilteringTextInputFormatter.digitsOnly,
                                ],
                                onChanged: (v) =>
                                    _inventory[k] = int.tryParse(v) ?? 0,
                                decoration: InputDecoration(
                                  isDense: true,
                                  contentPadding: const EdgeInsets.all(8),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                              ),
                            ),
                          );
                        }),
                      ],
                    ),
                  )
                  .toList(),
            ),
          ),
        ],
      ),
    );
  }

  void _addCategory() {
    final ctrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('فئة جديدة'),
        content: TextField(
          controller: ctrl,
          decoration: _inputDeco('الاسم', Icons.category_outlined),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (ctrl.text.trim().isEmpty) return;
              final success = await context.read<ProductProvider>().addCategory(
                ctrl.text.trim(),
              );
              if (!mounted) return;
              Navigator.pop(ctx);
              if (success) setState(() => _selectedCategory = ctrl.text.trim());
            },
            child: const Text('إضافة'),
          ),
        ],
      ),
    );
  }

  void _addColor() {
    final ctrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('لون جديد'),
        content: TextField(
          controller: ctrl,
          decoration: _inputDeco('اللون', Icons.palette_outlined),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () {
              if (ctrl.text.trim().isNotEmpty &&
                  !_colors.contains(ctrl.text.trim()))
                setState(() => _colors.add(ctrl.text.trim()));
              Navigator.pop(ctx);
            },
            child: const Text('إضافة'),
          ),
        ],
      ),
    );
  }

  void _addSize() {
    final ctrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('مقاس جديد'),
        content: TextField(
          controller: ctrl,
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          decoration: _inputDeco('المقاس', Icons.straighten_outlined),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () {
              final s = int.tryParse(ctrl.text);
              if (s != null && !_sizes.contains(s))
                setState(() {
                  _sizes.add(s);
                  _sizes.sort();
                });
              Navigator.pop(ctx);
            },
            child: const Text('إضافة'),
          ),
        ],
      ),
    );
  }

  Future<void> _saveProduct() async {
    if (!_formKey.currentState!.validate()) return;
    if (_colors.isEmpty) {
      _showSnackBar('أضف لون واحد على الأقل', isError: true);
      return;
    }
    if (_sizes.isEmpty) {
      _showSnackBar('أضف مقاس واحد على الأقل', isError: true);
      return;
    }

    setState(() => _isLoading = true);
    final product = ProductModel(
      id: widget.product?.id ?? '',
      name: _nameController.text.trim(),
      description: _descriptionController.text.trim(),
      category: _selectedCategory!,
      brand: _brandController.text.trim(),
      price: double.parse(_priceController.text),
      costPrice: double.parse(_costPriceController.text),
      colors: _colors,
      sizes: _sizes,
      inventory: _inventory,
      createdAt: widget.product?.createdAt ?? DateTime.now(),
      updatedAt: DateTime.now(),
    );

    final provider = context.read<ProductProvider>();
    final success = isEditing
        ? await provider.updateProduct(product)
        : await provider.addProduct(product);
    setState(() => _isLoading = false);

    if (success && mounted) {
      Navigator.pop(context);
      _showSnackBar(isEditing ? 'تم التحديث' : 'تمت الإضافة');
    } else if (mounted)
      _showSnackBar(provider.error ?? 'خطأ', isError: true);
  }
}
