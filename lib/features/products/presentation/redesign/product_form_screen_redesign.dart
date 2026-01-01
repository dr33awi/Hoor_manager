/// ═══════════════════════════════════════════════════════════════════════════
/// Product Form Screen - Redesigned
/// Modern Product Add/Edit Form
/// ═══════════════════════════════════════════════════════════════════════════
library;

import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:printing/printing.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:drift/drift.dart' as drift;

import '../../../../core/di/injection.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/services/currency_service.dart';
import '../../../../data/database/app_database.dart';
import '../../../../data/repositories/product_repository.dart';
import '../../../../data/repositories/category_repository.dart';

class ProductFormScreenRedesign extends ConsumerStatefulWidget {
  final String? productId;

  const ProductFormScreenRedesign({super.key, this.productId});

  @override
  ConsumerState<ProductFormScreenRedesign> createState() =>
      _ProductFormScreenRedesignState();
}

class _ProductFormScreenRedesignState
    extends ConsumerState<ProductFormScreenRedesign> {
  final _formKey = GlobalKey<FormState>();
  final _productRepo = getIt<ProductRepository>();
  final _categoryRepo = getIt<CategoryRepository>();
  final _currencyService = getIt<CurrencyService>();

  final _nameController = TextEditingController();
  final _barcodeController = TextEditingController();
  final _purchasePriceUsdController = TextEditingController();
  final _purchasePriceController = TextEditingController();
  final _salePriceController = TextEditingController();
  final _quantityController = TextEditingController(text: '0');
  final _minQuantityController = TextEditingController(text: '0');
  final _descriptionController = TextEditingController();

  String? _selectedCategoryId;
  bool _isLoading = false;
  bool _isSaving = false;
  bool _isEditing = false;

  @override
  void initState() {
    super.initState();
    _isEditing = widget.productId != null;
    if (_isEditing) {
      _loadProduct();
    }
  }

  Future<void> _loadProduct() async {
    setState(() => _isLoading = true);

    final product = await _productRepo.getProductById(widget.productId!);
    if (product != null) {
      _nameController.text = product.name;
      _barcodeController.text = product.barcode ?? '';
      _purchasePriceUsdController.text =
          product.purchasePriceUsd?.toString() ?? '';
      _purchasePriceController.text = product.purchasePrice.toString();
      _salePriceController.text = product.salePrice.toString();
      _quantityController.text = product.quantity.toString();
      _minQuantityController.text = product.minQuantity.toString();
      _descriptionController.text = product.description ?? '';
      _selectedCategoryId = product.categoryId;
    }

    setState(() => _isLoading = false);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _barcodeController.dispose();
    _purchasePriceUsdController.dispose();
    _purchasePriceController.dispose();
    _salePriceController.dispose();
    _quantityController.dispose();
    _minQuantityController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: HoorColors.background,
      appBar: _buildAppBar(),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: HoorColors.primary))
          : _buildForm(),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: HoorColors.surface,
      surfaceTintColor: Colors.transparent,
      title: Text(
        _isEditing ? 'تعديل منتج' : 'إضافة منتج جديد',
        style: HoorTypography.headlineSmall,
      ),
      leading: IconButton(
        icon: Container(
          padding: EdgeInsets.all(HoorSpacing.xs.w),
          decoration: BoxDecoration(
            color: HoorColors.background,
            borderRadius: BorderRadius.circular(HoorRadius.sm),
          ),
          child: const Icon(Icons.arrow_back_rounded, size: 20),
        ),
        onPressed: () => context.pop(),
      ),
      actions: [
        if (_isEditing && _barcodeController.text.isNotEmpty)
          IconButton(
            icon: const Icon(Icons.print_rounded),
            onPressed: _printBarcode,
            tooltip: 'طباعة الباركود',
          ),
        SizedBox(width: HoorSpacing.xs.w),
      ],
    );
  }

  Widget _buildForm() {
    return Form(
      key: _formKey,
      child: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.all(HoorSpacing.md.w),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Basic Info Section
                  _buildSectionCard(
                    title: 'المعلومات الأساسية',
                    icon: Icons.inventory_2_rounded,
                    children: [
                      _buildTextField(
                        controller: _nameController,
                        label: 'اسم المنتج',
                        hint: 'أدخل اسم المنتج',
                        icon: Icons.label_rounded,
                        isRequired: true,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'يرجى إدخال اسم المنتج';
                          }
                          return null;
                        },
                      ),
                      SizedBox(height: HoorSpacing.md.h),
                      _buildBarcodeField(),
                      SizedBox(height: HoorSpacing.md.h),
                      _buildCategoryDropdown(),
                    ],
                  ),
                  SizedBox(height: HoorSpacing.md.h),

                  // Pricing Section
                  _buildSectionCard(
                    title: 'الأسعار',
                    icon: Icons.attach_money_rounded,
                    children: [
                      _buildUsdPriceField(),
                      SizedBox(height: HoorSpacing.md.h),
                      Row(
                        children: [
                          Expanded(
                            child: _buildTextField(
                              controller: _purchasePriceController,
                              label: 'سعر الشراء',
                              hint: '0',
                              icon: Icons.shopping_cart_rounded,
                              suffix: 'ل.س',
                              keyboardType: TextInputType.number,
                              isRequired: true,
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'مطلوب';
                                }
                                if (double.tryParse(value) == null) {
                                  return 'رقم غير صالح';
                                }
                                return null;
                              },
                            ),
                          ),
                          SizedBox(width: HoorSpacing.sm.w),
                          Expanded(
                            child: _buildTextField(
                              controller: _salePriceController,
                              label: 'سعر البيع',
                              hint: '0',
                              icon: Icons.sell_rounded,
                              suffix: 'ل.س',
                              keyboardType: TextInputType.number,
                              validator: (value) {
                                if (value != null &&
                                    value.isNotEmpty &&
                                    double.tryParse(value) == null) {
                                  return 'رقم غير صالح';
                                }
                                return null;
                              },
                            ),
                          ),
                        ],
                      ),
                      // Profit Indicator
                      if (_purchasePriceController.text.isNotEmpty &&
                          _salePriceController.text.isNotEmpty)
                        _buildProfitIndicator(),
                    ],
                  ),
                  SizedBox(height: HoorSpacing.md.h),

                  // Stock Section
                  _buildSectionCard(
                    title: 'المخزون',
                    icon: Icons.inventory_rounded,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: _buildTextField(
                              controller: _quantityController,
                              label: 'الكمية الحالية',
                              hint: '0',
                              icon: Icons.numbers_rounded,
                              keyboardType: TextInputType.number,
                              enabled: !_isEditing,
                            ),
                          ),
                          SizedBox(width: HoorSpacing.sm.w),
                          Expanded(
                            child: _buildTextField(
                              controller: _minQuantityController,
                              label: 'الحد الأدنى',
                              hint: '0',
                              icon: Icons.warning_amber_rounded,
                              keyboardType: TextInputType.number,
                            ),
                          ),
                        ],
                      ),
                      if (_isEditing)
                        Padding(
                          padding: EdgeInsets.only(top: HoorSpacing.xs.h),
                          child: Text(
                            'لتعديل الكمية استخدم حركات المخزون',
                            style: HoorTypography.labelSmall.copyWith(
                              color: HoorColors.textSecondary,
                            ),
                          ),
                        ),
                    ],
                  ),
                  SizedBox(height: HoorSpacing.md.h),

                  // Description Section
                  _buildSectionCard(
                    title: 'وصف إضافي',
                    icon: Icons.description_rounded,
                    children: [
                      _buildTextField(
                        controller: _descriptionController,
                        label: 'الوصف',
                        hint: 'أدخل وصف المنتج (اختياري)',
                        icon: Icons.notes_rounded,
                        maxLines: 3,
                      ),
                    ],
                  ),
                  SizedBox(height: HoorSpacing.xl.h),
                ],
              ),
            ),
          ),

          // Save Button
          _buildBottomBar(),
        ],
      ),
    );
  }

  Widget _buildSectionCard({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Container(
      padding: EdgeInsets.all(HoorSpacing.md.w),
      decoration: BoxDecoration(
        color: HoorColors.surface,
        borderRadius: BorderRadius.circular(HoorRadius.lg),
        border: Border.all(color: HoorColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(HoorSpacing.xs.w),
                decoration: BoxDecoration(
                  color: HoorColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(HoorRadius.sm),
                ),
                child: Icon(
                  icon,
                  color: HoorColors.primary,
                  size: HoorIconSize.sm,
                ),
              ),
              SizedBox(width: HoorSpacing.sm.w),
              Text(
                title,
                style: HoorTypography.titleMedium.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          SizedBox(height: HoorSpacing.md.h),
          ...children,
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    String? hint,
    IconData? icon,
    String? suffix,
    TextInputType? keyboardType,
    bool isRequired = false,
    bool enabled = true,
    int maxLines = 1,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      enabled: enabled,
      maxLines: maxLines,
      style: HoorTypography.bodyMedium,
      decoration: InputDecoration(
        labelText: isRequired ? '$label *' : label,
        hintText: hint,
        prefixIcon: icon != null ? Icon(icon, size: HoorIconSize.sm) : null,
        suffixText: suffix,
        filled: true,
        fillColor: enabled ? HoorColors.background : HoorColors.border,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(HoorRadius.md),
          borderSide: BorderSide(color: HoorColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(HoorRadius.md),
          borderSide: BorderSide(color: HoorColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(HoorRadius.md),
          borderSide: const BorderSide(color: HoorColors.primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(HoorRadius.md),
          borderSide: const BorderSide(color: HoorColors.error),
        ),
        contentPadding: EdgeInsets.symmetric(
          horizontal: HoorSpacing.md.w,
          vertical: HoorSpacing.sm.h,
        ),
      ),
      validator: validator,
      onChanged: (_) => setState(() {}),
    );
  }

  Widget _buildBarcodeField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextFormField(
          controller: _barcodeController,
          style: HoorTypography.bodyMedium,
          decoration: InputDecoration(
            labelText: 'الباركود',
            hintText: 'أدخل أو امسح الباركود',
            prefixIcon:
                const Icon(Icons.qr_code_rounded, size: HoorIconSize.sm),
            suffixIcon: IconButton(
              icon: const Icon(Icons.qr_code_scanner_rounded),
              onPressed: _scanBarcode,
              tooltip: 'مسح الباركود',
            ),
            filled: true,
            fillColor: HoorColors.background,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(HoorRadius.md),
              borderSide: BorderSide(color: HoorColors.border),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(HoorRadius.md),
              borderSide: BorderSide(color: HoorColors.border),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(HoorRadius.md),
              borderSide: const BorderSide(color: HoorColors.primary, width: 2),
            ),
          ),
        ),
        SizedBox(height: HoorSpacing.xs.h),
        Row(
          children: [
            Expanded(
              child: _buildActionChip(
                icon: Icons.auto_awesome_rounded,
                label: 'توليد باركود',
                onTap: _generateBarcode,
              ),
            ),
            SizedBox(width: HoorSpacing.xs.w),
            Expanded(
              child: _buildActionChip(
                icon: Icons.print_rounded,
                label: 'طباعة الباركود',
                onTap: _barcodeController.text.isEmpty ? null : _printBarcode,
                enabled: _barcodeController.text.isNotEmpty,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildActionChip({
    required IconData icon,
    required String label,
    VoidCallback? onTap,
    bool enabled = true,
  }) {
    return InkWell(
      onTap: enabled ? onTap : null,
      borderRadius: BorderRadius.circular(HoorRadius.sm),
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: HoorSpacing.sm.w,
          vertical: HoorSpacing.xs.h,
        ),
        decoration: BoxDecoration(
          color: enabled
              ? HoorColors.primary.withValues(alpha: 0.1)
              : HoorColors.border,
          borderRadius: BorderRadius.circular(HoorRadius.sm),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 16,
              color: enabled ? HoorColors.primary : HoorColors.textSecondary,
            ),
            SizedBox(width: HoorSpacing.xxs.w),
            Text(
              label,
              style: HoorTypography.labelSmall.copyWith(
                color: enabled ? HoorColors.primary : HoorColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryDropdown() {
    return StreamBuilder<List<Category>>(
      stream: _categoryRepo.watchAllCategories(),
      builder: (context, snapshot) {
        final categories = snapshot.data ?? [];
        return DropdownButtonFormField<String>(
          initialValue: _selectedCategoryId,
          decoration: InputDecoration(
            labelText: 'التصنيف',
            prefixIcon:
                const Icon(Icons.category_rounded, size: HoorIconSize.sm),
            filled: true,
            fillColor: HoorColors.background,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(HoorRadius.md),
              borderSide: BorderSide(color: HoorColors.border),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(HoorRadius.md),
              borderSide: BorderSide(color: HoorColors.border),
            ),
          ),
          items: [
            const DropdownMenuItem(
              value: null,
              child: Text('بدون تصنيف'),
            ),
            ...categories.map((c) => DropdownMenuItem(
                  value: c.id,
                  child: Text(c.name),
                )),
          ],
          onChanged: (value) => setState(() => _selectedCategoryId = value),
        );
      },
    );
  }

  Widget _buildUsdPriceField() {
    return Container(
      padding: EdgeInsets.all(HoorSpacing.sm.w),
      decoration: BoxDecoration(
        color: HoorColors.info.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(HoorRadius.md),
        border: Border.all(color: HoorColors.info.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.currency_exchange_rounded,
                  color: HoorColors.info, size: 18),
              SizedBox(width: HoorSpacing.xs.w),
              Text(
                'سعر الشراء بالدولار',
                style: HoorTypography.labelMedium.copyWith(
                  color: HoorColors.info,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              Text(
                '1\$ = ${_currencyService.exchangeRate.toStringAsFixed(0)} ل.س',
                style: HoorTypography.labelSmall.copyWith(
                  color: HoorColors.textSecondary,
                ),
              ),
            ],
          ),
          SizedBox(height: HoorSpacing.sm.h),
          TextFormField(
            controller: _purchasePriceUsdController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            style: HoorTypography.bodyMedium,
            decoration: InputDecoration(
              hintText: 'أدخل السعر بالدولار (اختياري)',
              prefixIcon:
                  const Icon(Icons.attach_money_rounded, size: HoorIconSize.sm),
              suffixText: '\$',
              filled: true,
              fillColor: HoorColors.surface,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(HoorRadius.sm),
                borderSide: BorderSide.none,
              ),
              helperText: _purchasePriceUsdController.text.isNotEmpty
                  ? 'يعادل: ${_currencyService.formatSyp(_currencyService.usdToSyp(double.tryParse(_purchasePriceUsdController.text) ?? 0))}'
                  : null,
            ),
            onChanged: (value) {
              final usdPrice = double.tryParse(value);
              if (usdPrice != null && usdPrice > 0) {
                final sypPrice = _currencyService.usdToSyp(usdPrice);
                _purchasePriceController.text = sypPrice.toStringAsFixed(0);
              }
              setState(() {});
            },
          ),
        ],
      ),
    );
  }

  Widget _buildProfitIndicator() {
    final purchasePrice = double.tryParse(_purchasePriceController.text) ?? 0;
    final salePrice = double.tryParse(_salePriceController.text) ?? 0;
    final profit = salePrice - purchasePrice;
    final profitPercent =
        purchasePrice > 0 ? (profit / purchasePrice * 100) : 0;
    final isProfit = profit > 0;

    return Padding(
      padding: EdgeInsets.only(top: HoorSpacing.sm.h),
      child: Container(
        padding: EdgeInsets.all(HoorSpacing.sm.w),
        decoration: BoxDecoration(
          color: (isProfit ? HoorColors.success : HoorColors.error)
              .withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(HoorRadius.sm),
        ),
        child: Row(
          children: [
            Icon(
              isProfit
                  ? Icons.trending_up_rounded
                  : Icons.trending_down_rounded,
              color: isProfit ? HoorColors.success : HoorColors.error,
              size: 20,
            ),
            SizedBox(width: HoorSpacing.xs.w),
            Text(
              isProfit ? 'الربح:' : 'الخسارة:',
              style: HoorTypography.labelMedium.copyWith(
                color: isProfit ? HoorColors.success : HoorColors.error,
              ),
            ),
            SizedBox(width: HoorSpacing.xs.w),
            Text(
              '${profit.abs().toStringAsFixed(0)} ل.س',
              style: HoorTypography.labelMedium.copyWith(
                color: isProfit ? HoorColors.success : HoorColors.error,
                fontWeight: FontWeight.bold,
              ),
            ),
            const Spacer(),
            Text(
              '(${profitPercent.toStringAsFixed(1)}%)',
              style: HoorTypography.labelSmall.copyWith(
                color: isProfit ? HoorColors.success : HoorColors.error,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomBar() {
    return Container(
      padding: EdgeInsets.all(HoorSpacing.md.w),
      decoration: BoxDecoration(
        color: HoorColors.surface,
        border: Border(top: BorderSide(color: HoorColors.border)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: SafeArea(
        child: SizedBox(
          width: double.infinity,
          height: 50.h,
          child: ElevatedButton(
            onPressed: _isSaving ? null : _saveProduct,
            style: ElevatedButton.styleFrom(
              backgroundColor: HoorColors.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(HoorRadius.md),
              ),
              elevation: 0,
            ),
            child: _isSaving
                ? SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        _isEditing ? Icons.check_rounded : Icons.add_rounded,
                        size: 20,
                      ),
                      SizedBox(width: HoorSpacing.xs.w),
                      Text(
                        _isEditing ? 'حفظ التعديلات' : 'إضافة المنتج',
                        style: HoorTypography.titleMedium.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // Actions
  // ═══════════════════════════════════════════════════════════════════════════

  Future<void> _saveProduct() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    try {
      final product = ProductsCompanion(
        id: _isEditing
            ? drift.Value(widget.productId!)
            : drift.Value(_productRepo.generateId()),
        name: drift.Value(_nameController.text.trim()),
        barcode: drift.Value(
            _barcodeController.text.isEmpty ? null : _barcodeController.text),
        categoryId: drift.Value(_selectedCategoryId),
        purchasePriceUsd:
            drift.Value(double.tryParse(_purchasePriceUsdController.text)),
        purchasePrice: drift.Value(double.parse(_purchasePriceController.text)),
        salePrice: drift.Value(double.tryParse(_salePriceController.text) ?? 0),
        quantity: drift.Value(int.parse(_quantityController.text)),
        minQuantity: drift.Value(int.parse(_minQuantityController.text)),
        description: drift.Value(_descriptionController.text.isEmpty
            ? null
            : _descriptionController.text),
      );

      if (_isEditing) {
        await _productRepo.updateProduct(
          id: product.id.value,
          name: product.name.value,
          sku: product.sku.present ? product.sku.value : null,
          barcode: product.barcode.present ? product.barcode.value : null,
          categoryId:
              product.categoryId.present ? product.categoryId.value : null,
          purchasePrice: product.purchasePrice.present
              ? product.purchasePrice.value
              : null,
          purchasePriceUsd: product.purchasePriceUsd.present
              ? product.purchasePriceUsd.value
              : null,
          salePrice: product.salePrice.present ? product.salePrice.value : null,
          quantity: product.quantity.present ? product.quantity.value : null,
          minQuantity:
              product.minQuantity.present ? product.minQuantity.value : null,
          taxRate: product.taxRate.present ? product.taxRate.value : null,
          description:
              product.description.present ? product.description.value : null,
          imageUrl: product.imageUrl.present ? product.imageUrl.value : null,
          isActive: product.isActive.present ? product.isActive.value : null,
        );
      } else {
        await _productRepo.createProduct(
          name: product.name.value,
          sku: product.sku.present ? product.sku.value : null,
          barcode: product.barcode.present ? product.barcode.value : null,
          categoryId:
              product.categoryId.present ? product.categoryId.value : null,
          purchasePrice:
              product.purchasePrice.present ? product.purchasePrice.value : 0,
          purchasePriceUsd: product.purchasePriceUsd.present
              ? product.purchasePriceUsd.value
              : null,
          salePrice: product.salePrice.present ? product.salePrice.value : 0,
          quantity: product.quantity.present ? product.quantity.value : 0,
          minQuantity:
              product.minQuantity.present ? product.minQuantity.value : 5,
          taxRate: product.taxRate.present ? product.taxRate.value : null,
          description:
              product.description.present ? product.description.value : null,
          imageUrl: product.imageUrl.present ? product.imageUrl.value : null,
        );
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                _isEditing ? 'تم تحديث المنتج بنجاح' : 'تم إضافة المنتج بنجاح'),
            backgroundColor: HoorColors.success,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(HoorRadius.sm),
            ),
          ),
        );
        context.pop(true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('حدث خطأ: $e'),
            backgroundColor: HoorColors.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      setState(() => _isSaving = false);
    }
  }

  void _generateBarcode() {
    final random = Random();
    final barcode = List.generate(13, (_) => random.nextInt(10)).join();
    setState(() => _barcodeController.text = barcode);
  }

  Future<void> _scanBarcode() async {
    final result = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const _BarcodeScannerSheet(),
    );

    if (result != null) {
      setState(() => _barcodeController.text = result);
    }
  }

  Future<void> _printBarcode() async {
    if (_barcodeController.text.isEmpty) return;

    final doc = pw.Document();
    doc.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.roll80,
        build: (context) => pw.Center(
          child: pw.Column(
            mainAxisSize: pw.MainAxisSize.min,
            children: [
              pw.BarcodeWidget(
                barcode: pw.Barcode.ean13(),
                data: _barcodeController.text,
                width: 200,
                height: 80,
              ),
              pw.SizedBox(height: 8),
              pw.Text(
                _nameController.text,
                style: pw.TextStyle(fontSize: 12),
              ),
            ],
          ),
        ),
      ),
    );

    await Printing.layoutPdf(onLayout: (format) => doc.save());
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// Barcode Scanner Sheet
// ═══════════════════════════════════════════════════════════════════════════

class _BarcodeScannerSheet extends StatefulWidget {
  const _BarcodeScannerSheet();

  @override
  State<_BarcodeScannerSheet> createState() => _BarcodeScannerSheetState();
}

class _BarcodeScannerSheetState extends State<_BarcodeScannerSheet> {
  final MobileScannerController _controller = MobileScannerController();
  bool _isScanned = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.7,
      decoration: BoxDecoration(
        color: HoorColors.surface,
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(HoorRadius.xl),
        ),
      ),
      child: Column(
        children: [
          // Handle
          Container(
            margin: EdgeInsets.symmetric(vertical: HoorSpacing.sm.h),
            width: 40.w,
            height: 4.h,
            decoration: BoxDecoration(
              color: HoorColors.border,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          // Header
          Padding(
            padding: EdgeInsets.all(HoorSpacing.md.w),
            child: Row(
              children: [
                Text(
                  'مسح الباركود',
                  style: HoorTypography.headlineSmall,
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.close_rounded),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),
          // Scanner
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(HoorRadius.lg),
              child: MobileScanner(
                controller: _controller,
                onDetect: (capture) {
                  if (_isScanned) return;
                  final barcodes = capture.barcodes;
                  if (barcodes.isNotEmpty) {
                    _isScanned = true;
                    Navigator.pop(context, barcodes.first.rawValue);
                  }
                },
              ),
            ),
          ),
          SizedBox(height: HoorSpacing.xl.h),
        ],
      ),
    );
  }
}
