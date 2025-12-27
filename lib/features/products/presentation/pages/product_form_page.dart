import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drift/drift.dart' show Value;
import '../../../../app/theme/app_theme.dart';
import '../../../../shared/widgets/common_widgets.dart';
import '../../../../app/providers/database_providers.dart';
import '../../../../data/database.dart';

/// صفحة نموذج المنتج
class ProductFormPage extends ConsumerStatefulWidget {
  final String? productId;

  const ProductFormPage({super.key, this.productId});

  @override
  ConsumerState<ProductFormPage> createState() => _ProductFormPageState();
}

class _ProductFormPageState extends ConsumerState<ProductFormPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _barcodeController = TextEditingController();
  final _skuController = TextEditingController();
  final _costPriceController = TextEditingController();
  final _salePriceController = TextEditingController();
  final _qtyController = TextEditingController();
  final _minQtyController = TextEditingController();

  int? _selectedCategoryId;
  bool _isActive = true;
  bool _trackStock = true;
  bool _isSaving = false;
  Product? _existingProduct;

  bool get _isEditing => widget.productId != null;

  @override
  void initState() {
    super.initState();
    if (_isEditing) {
      _loadProduct();
    }
  }

  Future<void> _loadProduct() async {
    final productId = int.tryParse(widget.productId ?? '');
    if (productId == null) return;

    final product = await ref.read(productByIdProvider(productId).future);
    if (product != null && mounted) {
      setState(() {
        _existingProduct = product;
        _nameController.text = product.name;
        _barcodeController.text = product.barcode ?? '';
        _skuController.text = product.sku ?? '';
        _costPriceController.text = product.costPrice.toString();
        _salePriceController.text = product.salePrice.toString();
        _qtyController.text = product.qty.toString();
        _minQtyController.text = product.minQty.toString();
        _selectedCategoryId = product.categoryId;
        _isActive = product.isActive;
        _trackStock = product.trackStock;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'تعديل المنتج' : 'منتج جديد'),
        actions: [
          if (_isEditing)
            IconButton(
              icon: const Icon(Icons.delete),
              onPressed: _deleteProduct,
            ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(AppSizes.paddingMD),
          children: [
            // اسم المنتج
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'اسم المنتج *',
                prefixIcon: Icon(Icons.inventory_2),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'الرجاء إدخال اسم المنتج';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // الباركود
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _barcodeController,
                    decoration: const InputDecoration(
                      labelText: 'الباركود',
                      prefixIcon: Icon(Icons.qr_code),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton.filled(
                  onPressed: () {
                    // مسح الباركود
                  },
                  icon: const Icon(Icons.qr_code_scanner),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // SKU
            TextFormField(
              controller: _skuController,
              decoration: InputDecoration(
                labelText: 'SKU',
                prefixIcon: const Icon(Icons.tag),
                suffixIcon: TextButton(
                  onPressed: () {
                    // توليد SKU تلقائي
                    _skuController.text =
                        'SKU${DateTime.now().millisecondsSinceEpoch}';
                  },
                  child: const Text('توليد'),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // التصنيف
            DropdownButtonFormField<int>(
              value: _selectedCategoryId,
              decoration: const InputDecoration(
                labelText: 'التصنيف',
                prefixIcon: Icon(Icons.category),
              ),
              items: List.generate(10, (index) {
                return DropdownMenuItem(
                  value: index,
                  child: Text(index == 0 ? 'عام' : 'تصنيف $index'),
                );
              }),
              onChanged: (value) {
                setState(() => _selectedCategoryId = value);
              },
            ),
            const SizedBox(height: 24),

            // الأسعار
            const SectionHeader(title: 'الأسعار'),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _costPriceController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'سعر الشراء',
                      suffixText: 'ر.س',
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextFormField(
                    controller: _salePriceController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'سعر البيع *',
                      suffixText: 'ر.س',
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'مطلوب';
                      }
                      return null;
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // المخزون
            const SectionHeader(title: 'المخزون'),
            const SizedBox(height: 8),
            SwitchListTile(
              title: const Text('تتبع المخزون'),
              subtitle: const Text('تفعيل إدارة الكميات'),
              value: _trackStock,
              onChanged: (value) {
                setState(() => _trackStock = value);
              },
            ),
            if (_trackStock) ...[
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _qtyController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'الكمية الحالية',
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextFormField(
                      controller: _minQtyController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'الحد الأدنى',
                      ),
                    ),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 24),

            // الحالة
            SwitchListTile(
              title: const Text('منتج نشط'),
              subtitle: const Text('يظهر في البحث والفواتير'),
              value: _isActive,
              onChanged: (value) {
                setState(() => _isActive = value);
              },
            ),
            const SizedBox(height: 32),

            // زر الحفظ
            PrimaryButton(
              text: _isSaving
                  ? 'جاري الحفظ...'
                  : (_isEditing ? 'حفظ التغييرات' : 'إضافة المنتج'),
              icon: _isSaving ? null : Icons.save,
              onPressed: _isSaving ? null : _saveProduct,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _saveProduct() async {
    if (!_formKey.currentState!.validate()) return;
    if (_isSaving) return;

    setState(() => _isSaving = true);

    try {
      final productRepo = ref.read(productRepositoryProvider);

      final name = _nameController.text.trim();
      final barcode = _barcodeController.text.trim();
      final sku = _skuController.text.trim();
      final costPrice = double.tryParse(_costPriceController.text) ?? 0;
      final salePrice = double.tryParse(_salePriceController.text) ?? 0;
      final qty = double.tryParse(_qtyController.text) ?? 0;
      final minQty = double.tryParse(_minQtyController.text) ?? 0;

      if (_isEditing && _existingProduct != null) {
        // تحديث منتج موجود
        final updatedProduct = _existingProduct!.copyWith(
          name: name,
          barcode: Value(barcode.isEmpty ? null : barcode),
          sku: Value(sku.isEmpty ? null : sku),
          costPrice: costPrice,
          salePrice: salePrice,
          qty: qty,
          minQty: minQty,
          categoryId: Value(_selectedCategoryId),
          isActive: _isActive,
          trackStock: _trackStock,
          updatedAt: Value(DateTime.now()),
        );
        await productRepo.updateProduct(updatedProduct);
      } else {
        // إضافة منتج جديد
        await productRepo.insertProduct(ProductsCompanion(
          name: Value(name),
          barcode: Value(barcode.isEmpty ? null : barcode),
          sku: Value(sku.isEmpty ? null : sku),
          costPrice: Value(costPrice),
          salePrice: Value(salePrice),
          qty: Value(qty),
          minQty: Value(minQty),
          categoryId: Value(_selectedCategoryId),
          isActive: Value(_isActive),
          trackStock: Value(_trackStock),
        ));
      }

      // تحديث قائمة المنتجات
      ref.invalidate(allProductsProvider);

      if (mounted) {
        showSnackBar(context,
            _isEditing ? 'تم تحديث المنتج بنجاح' : 'تم إضافة المنتج بنجاح');
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        showSnackBar(context, 'خطأ في حفظ المنتج: $e', isError: true);
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  Future<void> _deleteProduct() async {
    final confirm = await showConfirmDialog(
      context,
      title: 'حذف المنتج',
      message: 'هل تريد حذف هذا المنتج؟',
      confirmText: 'حذف',
      confirmColor: AppColors.error,
    );

    if (confirm == true) {
      try {
        final productId = int.tryParse(widget.productId ?? '');
        if (productId != null) {
          final productRepo = ref.read(productRepositoryProvider);
          await productRepo.deleteProduct(productId);
          ref.invalidate(allProductsProvider);
        }
        if (mounted) {
          showSnackBar(context, 'تم حذف المنتج');
          Navigator.pop(context, true);
        }
      } catch (e) {
        if (mounted) {
          showSnackBar(context, 'خطأ في حذف المنتج: $e', isError: true);
        }
      }
    }
  }
}
