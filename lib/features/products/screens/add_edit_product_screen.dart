// lib/features/products/screens/add_edit_product_screen.dart
// شاشة إضافة/تعديل منتج - مع دعم الطباعة التلقائية ✅

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../providers/product_provider.dart';
import '../models/product_model.dart';
import '../../../core/services/business/barcode_service.dart';
import '../widgets/barcode_scanner_widget.dart';
import '../widgets/barcode_label_dialog.dart';
import '../widgets/auto_print_barcode_dialog.dart';
import '../../../core/theme/app_theme.dart';

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
  final _barcodeController = TextEditingController();
  final _barcodeService = BarcodeService();

  String? _selectedCategory;
  late List<String> _colors;
  late List<int> _sizes;
  late Map<String, int> _inventory;
  late Map<String, String> _variantBarcodes;
  bool _isLoading = false;
  bool _isCategoriesLoading = true;
  bool _hasScannedBarcode = false;
  bool _wasGeneratedBarcode = false;

  bool get isEditing => widget.product != null;

  @override
  void initState() {
    super.initState();
    _colors = [];
    _sizes = [];
    _inventory = {};
    _variantBarcodes = {};

    if (isEditing) {
      _loadProductData();
    } else {
      _barcodeController.text = _barcodeService.generateProductBarcode();
      _wasGeneratedBarcode = true;
    }

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
    _barcodeController.text = p.barcode;
    _selectedCategory = p.category;
    _colors = p.colors.toSet().toList();
    _sizes = (p.sizes.toSet().toList())..sort();
    _inventory = Map.from(p.inventory);
    _variantBarcodes = Map.from(p.variantBarcodes);
    _hasScannedBarcode = p.barcode.isNotEmpty;
    _wasGeneratedBarcode = false;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _brandController.dispose();
    _priceController.dispose();
    _costPriceController.dispose();
    _barcodeController.dispose();
    super.dispose();
  }

  void _showSnackBar(String msg, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: isError ? AppColors.error : AppColors.success,
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
        borderSide: BorderSide(color: AppColors.primary, width: 1.5),
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
          icon: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              Icons.arrow_back_ios_rounded,
              size: 16,
              color: AppColors.primary,
            ),
          ),
        ),
        title: Text(
          isEditing ? 'تعديل المنتج' : 'إضافة منتج',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: AppColors.primary,
          ),
        ),
        centerTitle: true,
        actions: [
          if (isEditing)
            Padding(
              padding: const EdgeInsets.only(left: 8),
              child: IconButton(
                onPressed: _isLoading ? null : _saveProduct,
                icon: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.success.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(Icons.check, size: 18, color: AppColors.success),
                ),
              ),
            ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildBarcodeSection(),
              const SizedBox(height: 20),
              _buildBasicInfo(),
              const SizedBox(height: 20),
              _buildColorsSection(),
              const SizedBox(height: 20),
              _buildSizesSection(),
              if (_colors.isNotEmpty && _sizes.isNotEmpty) ...[
                const SizedBox(height: 20),
                _buildInventory(),
              ],
              const SizedBox(height: 28),
              _buildSaveButton(),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSaveButton() {
    return SizedBox(
      width: double.infinity,
      height: 54,
      child: ElevatedButton(
        onPressed: _isLoading ? null : _saveProduct,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          elevation: 0,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
        child: _isLoading
            ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  color: Colors.white,
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    isEditing ? Icons.update : Icons.add_circle_outline,
                    size: 20,
                  ),
                  const SizedBox(width: 10),
                  Text(
                    isEditing ? 'تحديث المنتج' : 'إضافة المنتج',
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildBarcodeSection() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppColors.info.withValues(alpha: 0.2),
                      AppColors.info.withValues(alpha: 0.1),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.qr_code_scanner,
                  color: AppColors.info,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'باركود المنتج',
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
              ),
            ],
          ),
          const SizedBox(height: 18),

          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: _barcodeController,
                  decoration: _inputDeco('الباركود', Icons.qr_code),
                  readOnly: _hasScannedBarcode,
                  validator: (v) => v?.isEmpty == true ? 'مطلوب' : null,
                ),
              ),
              const SizedBox(width: 8),
              _buildIconBtn(
                Icons.qr_code_scanner,
                AppColors.info,
                _scanBarcode,
              ),
              const SizedBox(width: 8),
              _buildIconBtn(
                Icons.refresh,
                AppColors.success,
                _generateNewBarcode,
              ),
            ],
          ),

          const SizedBox(height: 14),

          if (_barcodeController.text.isNotEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.grey.shade50, Colors.white],
                ),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Column(
                children: [
                  SizedBox(
                    height: 60,
                    child: CustomPaint(
                      size: const Size(double.infinity, 60),
                      painter: SimpleBarcodePreviewPainter(
                        _barcodeController.text,
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    _barcodeController.text,
                    style: const TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 12,
                      letterSpacing: 2,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),

          const SizedBox(height: 10),
          Text(
            'يمكنك مسح باركود موجود أو استخدام الباركود المولّد تلقائياً',
            style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
          ),
        ],
      ),
    );
  }

  Widget _buildIconBtn(IconData icon, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Icon(icon, color: color, size: 22),
      ),
    );
  }

  Widget _buildBasicInfo() {
    return Consumer<ProductProvider>(
      builder: (context, provider, _) {
        final cats = provider.categories.map((c) => c.name).toSet().toList();
        return Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          AppColors.primary.withValues(alpha: 0.2),
                          AppColors.primary.withValues(alpha: 0.1),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.info_outline,
                      color: AppColors.primary,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    'المعلومات الأساسية',
                    style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
                  ),
                ],
              ),
              const SizedBox(height: 18),
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
                  ? const Center(
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
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
                        _buildIconBtn(
                          Icons.add,
                          AppColors.primary,
                          _addCategory,
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
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.purple.withValues(alpha: 0.2),
                          Colors.purple.withValues(alpha: 0.1),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.palette_outlined,
                      color: Colors.purple,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    'الألوان',
                    style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
                  ),
                ],
              ),
              GestureDetector(
                onTap: _addColor,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [AppColors.primary, Color(0xFF1A4A73)],
                    ),
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withValues(alpha: 0.3),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.add, color: Colors.white, size: 16),
                      SizedBox(width: 4),
                      Text(
                        'إضافة',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          _colors.isEmpty
              ? Container(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    children: [
                      Icon(
                        Icons.palette_outlined,
                        size: 40,
                        color: Colors.grey.shade300,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'لم يتم إضافة ألوان',
                        style: TextStyle(color: Colors.grey.shade400),
                      ),
                    ],
                  ),
                )
              : Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _colors.map((c) => _buildColorChip(c)).toList(),
                ),
        ],
      ),
    );
  }

  Widget _buildColorChip(String color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 16,
            height: 16,
            decoration: BoxDecoration(
              color: _getColorFromName(color),
              shape: BoxShape.circle,
              border: Border.all(color: Colors.grey.shade300),
            ),
          ),
          const SizedBox(width: 8),
          Text(color, style: const TextStyle(fontSize: 13)),
          const SizedBox(width: 4),
          GestureDetector(
            onTap: () => setState(() {
              _colors.remove(color);
              _inventory.removeWhere((k, _) => k.startsWith('$color-'));
              _variantBarcodes.removeWhere((k, _) => k.startsWith('$color-'));
            }),
            child: Icon(Icons.close, size: 16, color: Colors.grey.shade600),
          ),
        ],
      ),
    );
  }

  Color _getColorFromName(String name) {
    final colorMap = {
      'أسود': Colors.black,
      'أبيض': Colors.white,
      'أحمر': Colors.red,
      'أزرق': Colors.blue,
      'أخضر': Colors.green,
      'بني': Colors.brown,
      'رمادي': Colors.grey,
      'بيج': const Color(0xFFF5F5DC),
      'كحلي': const Color(0xFF000080),
      'عنابي': const Color(0xFF800020),
    };
    return colorMap[name] ?? Colors.grey.shade400;
  }

  Widget _buildSizesSection() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.orange.withValues(alpha: 0.2),
                          Colors.orange.withValues(alpha: 0.1),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.straighten_outlined,
                      color: Colors.orange,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    'المقاسات',
                    style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
                  ),
                ],
              ),
              Row(
                children: [
                  GestureDetector(
                    onTap: _addCommonSizes,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.grey.shade200),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.auto_fix_high,
                            size: 14,
                            color: Colors.grey.shade600,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'شائعة',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: _addSize,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [AppColors.primary, Color(0xFF1A4A73)],
                        ),
                        borderRadius: BorderRadius.circular(10),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primary.withValues(alpha: 0.3),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.add, color: Colors.white, size: 16),
                          SizedBox(width: 4),
                          Text(
                            'إضافة',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 14),
          _sizes.isEmpty
              ? Container(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    children: [
                      Icon(
                        Icons.straighten_outlined,
                        size: 40,
                        color: Colors.grey.shade300,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'لم يتم إضافة مقاسات',
                        style: TextStyle(color: Colors.grey.shade400),
                      ),
                    ],
                  ),
                )
              : Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _sizes.map((s) => _buildSizeChip(s)).toList(),
                ),
        ],
      ),
    );
  }

  Widget _buildSizeChip(int size) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '$size',
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
          ),
          const SizedBox(width: 4),
          GestureDetector(
            onTap: () => setState(() {
              _sizes.remove(size);
              _inventory.removeWhere((k, _) => k.endsWith('-$size'));
              _variantBarcodes.removeWhere((k, _) => k.endsWith('-$size'));
            }),
            child: Icon(Icons.close, size: 16, color: Colors.grey.shade600),
          ),
        ],
      ),
    );
  }

  Widget _buildInventory() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          AppColors.success.withValues(alpha: 0.2),
                          AppColors.success.withValues(alpha: 0.1),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.inventory_outlined,
                      color: AppColors.success,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    'المخزون والباركود',
                    style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
                  ),
                ],
              ),
              GestureDetector(
                onTap: _generateAllVariantBarcodes,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF8B5CF6), Color(0xFF7C3AED)],
                    ),
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF8B5CF6).withValues(alpha: 0.3),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.qr_code, size: 14, color: Colors.white),
                      SizedBox(width: 6),
                      Text(
                        'توليد باركود',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              headingRowColor: WidgetStateProperty.all(Colors.grey.shade50),
              columnSpacing: 20,
              headingRowHeight: 48,
              dataRowMinHeight: 52,
              dataRowMaxHeight: 56,
              columns: const [
                DataColumn(
                  label: Text(
                    'اللون',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
                DataColumn(
                  label: Text(
                    'المقاس',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
                DataColumn(
                  label: Text(
                    'الكمية',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  numeric: true,
                ),
                DataColumn(
                  label: Text(
                    'الباركود',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
                DataColumn(
                  label: Text(
                    'طباعة',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
              ],
              rows: _buildInventoryRows(),
            ),
          ),
        ],
      ),
    );
  }

  List<DataRow> _buildInventoryRows() {
    final rows = <DataRow>[];
    for (final color in _colors) {
      for (final size in _sizes) {
        final key = '$color-$size';
        rows.add(
          DataRow(
            cells: [
              DataCell(Text(color)),
              DataCell(Text('$size')),
              DataCell(
                SizedBox(
                  width: 60,
                  child: TextFormField(
                    initialValue: (_inventory[key] ?? 0).toString(),
                    keyboardType: TextInputType.number,
                    textAlign: TextAlign.center,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    onChanged: (v) => _inventory[key] = int.tryParse(v) ?? 0,
                    decoration: InputDecoration(
                      isDense: true,
                      contentPadding: const EdgeInsets.all(8),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
              ),
              DataCell(
                SizedBox(
                  width: 120,
                  child: Text(
                    _variantBarcodes[key] ?? '-',
                    style: TextStyle(
                      fontSize: 10,
                      fontFamily: 'monospace',
                      color: _variantBarcodes[key] != null
                          ? Colors.black
                          : Colors.grey,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
              DataCell(
                IconButton(
                  icon: Icon(
                    Icons.print,
                    size: 20,
                    color: _variantBarcodes[key] != null
                        ? AppColors.primary
                        : Colors.grey,
                  ),
                  onPressed: _variantBarcodes[key] != null
                      ? () => _showPrintDialog(color, size)
                      : null,
                ),
              ),
            ],
          ),
        );
      }
    }
    return rows;
  }

  void _scanBarcode() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => BarcodeScannerWidget(
        onBarcodeScanned: (barcode) {
          Navigator.pop(context);
          setState(() {
            _barcodeController.text = barcode;
            _hasScannedBarcode = true;
            _wasGeneratedBarcode = false;
          });
          _showSnackBar('تم مسح الباركود بنجاح');
        },
      ),
    );
  }

  void _generateNewBarcode() {
    setState(() {
      _barcodeController.text = _barcodeService.generateProductBarcode();
      _hasScannedBarcode = false;
      _wasGeneratedBarcode = true;
    });
    _showSnackBar('تم توليد باركود جديد');
  }

  void _generateAllVariantBarcodes() {
    if (_barcodeController.text.isEmpty) {
      _showSnackBar('يرجى إدخال باركود المنتج أولاً', isError: true);
      return;
    }

    setState(() {
      for (final color in _colors) {
        for (final size in _sizes) {
          final key = '$color-$size';
          if (_variantBarcodes[key] == null) {
            _variantBarcodes[key] = _barcodeService.generateVariantBarcode(
              _barcodeController.text,
              color,
              size,
            );
          }
        }
      }
    });
    _showSnackBar('تم توليد باركود لجميع المتغيرات');
  }

  void _showPrintDialog(String color, int size) {
    final key = '$color-$size';
    final barcode = _variantBarcodes[key];
    if (barcode == null) return;

    showDialog(
      context: context,
      builder: (_) => BarcodeLabelDialog(
        barcode: barcode,
        productName: _nameController.text,
        variant: '$color - مقاس $size',
        price: double.tryParse(_priceController.text) ?? 0,
      ),
    );
  }

  void _addCommonSizes() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('اختر نطاق المقاسات'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: const Text('مقاسات رجالي (40-46)'),
              onTap: () {
                setState(() {
                  _sizes = [40, 41, 42, 43, 44, 45, 46];
                });
                Navigator.pop(ctx);
              },
            ),
            ListTile(
              title: const Text('مقاسات نسائي (36-41)'),
              onTap: () {
                setState(() {
                  _sizes = [36, 37, 38, 39, 40, 41];
                });
                Navigator.pop(ctx);
              },
            ),
            ListTile(
              title: const Text('مقاسات أطفال (25-35)'),
              onTap: () {
                setState(() {
                  _sizes = [25, 26, 27, 28, 29, 30, 31, 32, 33, 34, 35];
                });
                Navigator.pop(ctx);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _addCategory() {
    final ctrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
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
    final commonColors = [
      'أسود',
      'أبيض',
      'بني',
      'رمادي',
      'كحلي',
      'بيج',
      'أحمر',
      'أزرق',
    ];

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('إضافة لون'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: ctrl,
              decoration: _inputDeco('اسم اللون', Icons.palette_outlined),
              autofocus: true,
            ),
            const SizedBox(height: 16),
            const Text(
              'أو اختر من الألوان الشائعة:',
              style: TextStyle(fontSize: 12),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: commonColors
                  .map(
                    (c) => GestureDetector(
                      onTap: () {
                        if (!_colors.contains(c)) {
                          setState(() => _colors.add(c));
                        }
                        Navigator.pop(ctx);
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: _getColorFromName(c).withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: _getColorFromName(c)),
                        ),
                        child: Text(c, style: const TextStyle(fontSize: 12)),
                      ),
                    ),
                  )
                  .toList(),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () {
              if (ctrl.text.trim().isNotEmpty &&
                  !_colors.contains(ctrl.text.trim())) {
                setState(() => _colors.add(ctrl.text.trim()));
              }
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
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
              if (s != null && !_sizes.contains(s)) {
                setState(() {
                  _sizes.add(s);
                  _sizes.sort();
                });
              }
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

    for (final color in _colors) {
      for (final size in _sizes) {
        final key = '$color-$size';
        if (_variantBarcodes[key] == null) {
          _variantBarcodes[key] = _barcodeService.generateVariantBarcode(
            _barcodeController.text,
            color,
            size,
          );
        }
      }
    }

    final product = ProductModel(
      id: widget.product?.id ?? '',
      name: _nameController.text.trim(),
      description: _descriptionController.text.trim(),
      category: _selectedCategory!,
      brand: _brandController.text.trim(),
      price: double.parse(_priceController.text),
      costPrice: double.parse(_costPriceController.text),
      barcode: _barcodeController.text.trim(),
      colors: _colors,
      sizes: _sizes,
      inventory: _inventory,
      variantBarcodes: _variantBarcodes,
      createdAt: widget.product?.createdAt ?? DateTime.now(),
      updatedAt: DateTime.now(),
    );

    final provider = context.read<ProductProvider>();
    final success = isEditing
        ? await provider.updateProduct(product)
        : await provider.addProduct(product);

    setState(() => _isLoading = false);

    if (success && mounted) {
      if (!isEditing && _wasGeneratedBarcode) {
        _showSnackBar('تم إضافة المنتج بنجاح');

        await Future.delayed(const Duration(milliseconds: 500));

        if (!mounted) return;

        await showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => AutoPrintBarcodeDialog(
            barcode: _barcodeController.text,
            productName: _nameController.text.trim(),
            price: double.parse(_priceController.text),
            storeName: 'متجري',
          ),
        );
      } else {
        _showSnackBar(isEditing ? 'تم التحديث بنجاح' : 'تمت الإضافة بنجاح');
      }

      if (!mounted) return;
      Navigator.pop(context);
    } else if (mounted) {
      _showSnackBar(provider.error ?? 'حدث خطأ', isError: true);
    }
  }
}

class SimpleBarcodePreviewPainter extends CustomPainter {
  final String data;

  SimpleBarcodePreviewPainter(this.data);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.black
      ..style = PaintingStyle.fill;

    final barWidth = size.width / (data.length * 2 + 20);
    double x = barWidth * 5;

    for (int i = 0; i < data.length; i++) {
      final charCode = data.codeUnitAt(i);
      for (int j = 0; j < 2; j++) {
        if ((charCode >> j) & 1 == 1) {
          canvas.drawRect(Rect.fromLTWH(x, 0, barWidth, size.height), paint);
        }
        x += barWidth;
      }
      x += barWidth * 0.3;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
