import 'package:flutter/material.dart';
import '../../../../app/theme/app_theme.dart';
import '../../../../shared/widgets/common_widgets.dart';

/// صفحة نموذج المنتج
class ProductFormPage extends StatefulWidget {
  final String? productId;

  const ProductFormPage({super.key, this.productId});

  @override
  State<ProductFormPage> createState() => _ProductFormPageState();
}

class _ProductFormPageState extends State<ProductFormPage> {
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

  bool get _isEditing => widget.productId != null;

  @override
  void initState() {
    super.initState();
    if (_isEditing) {
      _loadProduct();
    }
  }

  void _loadProduct() {
    // TODO: تحميل بيانات المنتج من قاعدة البيانات
    _nameController.text = 'منتج تجريبي';
    _barcodeController.text = '6000000000001';
    _costPriceController.text = '50';
    _salePriceController.text = '75';
    _qtyController.text = '100';
    _minQtyController.text = '10';
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
              text: _isEditing ? 'حفظ التغييرات' : 'إضافة المنتج',
              icon: Icons.save,
              onPressed: _saveProduct,
            ),
          ],
        ),
      ),
    );
  }

  void _saveProduct() {
    if (_formKey.currentState!.validate()) {
      // TODO: حفظ المنتج
      showSnackBar(context, 'تم حفظ المنتج بنجاح');
      Navigator.pop(context);
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
      // TODO: حذف المنتج
      showSnackBar(context, 'تم حذف المنتج');
      Navigator.pop(context);
    }
  }
}
