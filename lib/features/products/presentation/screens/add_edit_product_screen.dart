import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/constants.dart';
import '../../../../core/utils/app_utils.dart';
import '../../../../core/utils/validators.dart';
import '../../../../core/widgets/widgets.dart';
import '../../domain/entities/entities.dart';
import '../providers/product_providers.dart';
import '../widgets/widgets.dart';

/// شاشة إضافة/تعديل منتج
class AddEditProductScreen extends ConsumerStatefulWidget {
  final String? productId;

  const AddEditProductScreen({super.key, this.productId});

  bool get isEditing => productId != null;

  @override
  ConsumerState<AddEditProductScreen> createState() => _AddEditProductScreenState();
}

class _AddEditProductScreenState extends ConsumerState<AddEditProductScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _priceController = TextEditingController();
  final _costController = TextEditingController();
  final _barcodeController = TextEditingController();

  String? _selectedCategoryId;
  List<ProductVariant> _variants = [];
  bool _isLoading = false;
  bool _isActive = true;

  @override
  void initState() {
    super.initState();
    if (widget.isEditing) {
      _loadProduct();
    }
  }

  Future<void> _loadProduct() async {
    final product = await ref.read(productProvider(widget.productId!).future);
    if (product != null && mounted) {
      setState(() {
        _nameController.text = product.name;
        _descriptionController.text = product.description ?? '';
        _priceController.text = product.price.toString();
        _costController.text = product.cost.toString();
        _barcodeController.text = product.barcode ?? '';
        _selectedCategoryId = product.categoryId;
        _variants = List.from(product.variants);
        _isActive = product.isActive;
      });
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    _costController.dispose();
    _barcodeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final categoriesAsync = ref.watch(categoriesProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isEditing ? AppStrings.editProduct : AppStrings.addProduct),
        actions: [
          if (widget.isEditing)
            Switch(
              value: _isActive,
              onChanged: (value) => setState(() => _isActive = value),
            ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(AppSizes.md),
          children: [
            // اسم المنتج
            AppTextField(
              controller: _nameController,
              label: AppStrings.productName,
              hint: 'أدخل اسم المنتج',
              prefixIcon: Icons.inventory_2_outlined,
              validator: Validators.required,
              textInputAction: TextInputAction.next,
            ),

            const SizedBox(height: AppSizes.md),

            // الوصف
            AppTextField(
              controller: _descriptionController,
              label: 'الوصف (اختياري)',
              hint: 'وصف المنتج',
              prefixIcon: Icons.description_outlined,
              maxLines: 3,
              textInputAction: TextInputAction.next,
            ),

            const SizedBox(height: AppSizes.md),

            // الفئة
            categoriesAsync.when(
              data: (categories) => _buildCategoryDropdown(categories),
              loading: () => const LinearProgressIndicator(),
              error: (_, __) => const Text('فشل تحميل الفئات'),
            ),

            const SizedBox(height: AppSizes.md),

            // السعر والتكلفة
            Row(
              children: [
                Expanded(
                  child: AppTextField(
                    controller: _priceController,
                    label: AppStrings.productPrice,
                    hint: '0',
                    prefixIcon: Icons.attach_money,
                    keyboardType: TextInputType.number,
                    validator: Validators.positiveNumber,
                  ),
                ),
                const SizedBox(width: AppSizes.md),
                Expanded(
                  child: AppTextField(
                    controller: _costController,
                    label: AppStrings.productCost,
                    hint: '0',
                    prefixIcon: Icons.money_off,
                    keyboardType: TextInputType.number,
                    validator: Validators.positiveNumber,
                  ),
                ),
              ],
            ),

            const SizedBox(height: AppSizes.md),

            // الباركود
            Row(
              children: [
                Expanded(
                  child: AppTextField(
                    controller: _barcodeController,
                    label: AppStrings.productBarcode,
                    hint: 'اختياري',
                    prefixIcon: Icons.qr_code,
                  ),
                ),
                const SizedBox(width: AppSizes.sm),
                IconButton(
                  icon: const Icon(Icons.qr_code_scanner),
                  onPressed: _scanBarcode,
                  tooltip: 'مسح باركود',
                ),
                IconButton(
                  icon: const Icon(Icons.auto_awesome),
                  onPressed: _generateBarcode,
                  tooltip: 'توليد باركود',
                ),
              ],
            ),

            const SizedBox(height: AppSizes.lg),

            // المتغيرات (الألوان والمقاسات)
            _buildVariantsSection(),

            const SizedBox(height: AppSizes.xl),

            // زر الحفظ
            AppButton(
              text: widget.isEditing ? AppStrings.save : AppStrings.addProduct,
              onPressed: _saveProduct,
              isLoading: _isLoading,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryDropdown(List<CategoryEntity> categories) {
    return DropdownButtonFormField<String>(
      value: _selectedCategoryId,
      decoration: InputDecoration(
        labelText: AppStrings.productCategory,
        prefixIcon: const Icon(Icons.category_outlined),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSizes.radiusMd),
        ),
      ),
      items: categories.map((category) {
        return DropdownMenuItem(
          value: category.id,
          child: Text(category.name),
        );
      }).toList(),
      onChanged: (value) => setState(() => _selectedCategoryId = value),
      validator: (value) => value == null ? 'اختر الفئة' : null,
    );
  }

  Widget _buildVariantsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'المتغيرات (الألوان والمقاسات)',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            TextButton.icon(
              onPressed: _addVariant,
              icon: const Icon(Icons.add),
              label: const Text('إضافة'),
            ),
          ],
        ),

        const SizedBox(height: AppSizes.sm),

        if (_variants.isEmpty)
          Container(
            padding: const EdgeInsets.all(AppSizes.lg),
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(AppSizes.radiusMd),
              border: Border.all(color: AppColors.border),
            ),
            child: Center(
              child: Column(
                children: [
                  Icon(Icons.palette_outlined, 
                    size: 48, 
                    color: AppColors.textHint,
                  ),
                  const SizedBox(height: AppSizes.sm),
                  Text(
                    'أضف ألوان ومقاسات المنتج',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          )
        else
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _variants.length,
            itemBuilder: (context, index) {
              return VariantCard(
                variant: _variants[index],
                onEdit: () => _editVariant(index),
                onDelete: () => _deleteVariant(index),
              );
            },
          ),
      ],
    );
  }

  void _addVariant() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => VariantFormSheet(
        onSave: (variant) {
          setState(() {
            _variants.add(variant);
          });
        },
      ),
    );
  }

  void _editVariant(int index) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => VariantFormSheet(
        variant: _variants[index],
        onSave: (variant) {
          setState(() {
            _variants[index] = variant;
          });
        },
      ),
    );
  }

  void _deleteVariant(int index) {
    setState(() {
      _variants.removeAt(index);
    });
  }

  void _scanBarcode() {
    // سيتم تنفيذها لاحقاً
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('سيتم تفعيل الماسح قريباً')),
    );
  }

  void _generateBarcode() {
    final barcode = AppUtils.generateBarcode();
    setState(() {
      _barcodeController.text = barcode;
    });
  }

  Future<void> _saveProduct() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedCategoryId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('اختر الفئة')),
      );
      return;
    }

    if (_variants.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('أضف لون ومقاس واحد على الأقل')),
      );
      return;
    }

    setState(() => _isLoading = true);

    // الحصول على اسم الفئة
    final categories = await ref.read(categoriesProvider.future);
    final category = categories.firstWhere((c) => c.id == _selectedCategoryId);

    final product = ProductEntity(
      id: widget.productId ?? '',
      name: _nameController.text.trim(),
      description: _descriptionController.text.trim().isEmpty 
          ? null 
          : _descriptionController.text.trim(),
      categoryId: _selectedCategoryId!,
      categoryName: category.name,
      price: double.parse(_priceController.text),
      cost: double.parse(_costController.text),
      barcode: _barcodeController.text.trim().isEmpty 
          ? null 
          : _barcodeController.text.trim(),
      variants: _variants,
      isActive: _isActive,
      createdAt: DateTime.now(),
    );

    bool success;
    if (widget.isEditing) {
      success = await ref
          .read(productActionsProvider.notifier)
          .updateProduct(product);
    } else {
      success = await ref
          .read(productActionsProvider.notifier)
          .addProduct(product);
    }

    setState(() => _isLoading = false);

    if (mounted) {
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(widget.isEditing ? 'تم تحديث المنتج' : 'تم إضافة المنتج'),
            backgroundColor: AppColors.success,
          ),
        );
        context.pop();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('حدث خطأ، حاول مرة أخرى'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }
}
