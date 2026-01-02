// ═══════════════════════════════════════════════════════════════════════════════
// Product Form Screen Pro
// Add/Edit product with auto barcode generation and printing
// ═══════════════════════════════════════════════════════════════════════════════

import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../../core/theme/pro/design_tokens.dart';
import '../../core/providers/app_providers.dart';
import '../../data/database/app_database.dart';

class ProductFormScreenPro extends ConsumerStatefulWidget {
  final String? productId; // null for new product

  const ProductFormScreenPro({
    super.key,
    this.productId,
  });

  @override
  ConsumerState<ProductFormScreenPro> createState() =>
      _ProductFormScreenProState();
}

class _ProductFormScreenProState extends ConsumerState<ProductFormScreenPro> {
  final _formKey = GlobalKey<FormState>();

  // Controllers
  final _nameController = TextEditingController();
  final _barcodeController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _costPriceController = TextEditingController();
  final _salePriceController = TextEditingController();
  final _stockController = TextEditingController();
  final _minStockController = TextEditingController();
  final _skuController = TextEditingController();

  String? _selectedCategoryId;
  bool _isLoading = false;
  bool _isLoadingProduct = false;
  bool _isPrintingBarcode = false;
  Product? _existingProduct;

  bool get isEditing => widget.productId != null;

  @override
  void initState() {
    super.initState();
    // تعيين القيمة الافتراضية للحد الأدنى
    _minStockController.text = '0';

    if (isEditing) {
      _loadProduct();
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _barcodeController.dispose();
    _descriptionController.dispose();
    _costPriceController.dispose();
    _salePriceController.dispose();
    _stockController.dispose();
    _minStockController.dispose();
    _skuController.dispose();
    super.dispose();
  }

  Future<void> _loadProduct() async {
    if (widget.productId == null) return;

    setState(() => _isLoadingProduct = true);

    try {
      final productRepo = ref.read(productRepositoryProvider);
      final product = await productRepo.getProductById(widget.productId!);

      if (product != null && mounted) {
        _existingProduct = product;

        // ملء الحقول ببيانات المنتج
        _nameController.text = product.name;
        _barcodeController.text = product.barcode ?? '';
        _descriptionController.text = product.description ?? '';
        _costPriceController.text = product.purchasePrice > 0
            ? product.purchasePrice.toStringAsFixed(0)
            : '';
        _salePriceController.text =
            product.salePrice > 0 ? product.salePrice.toStringAsFixed(0) : '';
        _stockController.text = product.quantity.toString();
        _minStockController.text = product.minQuantity.toString();
        _skuController.text = product.sku ?? '';
        _selectedCategoryId = product.categoryId;

        setState(() {});
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('خطأ في تحميل المنتج: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoadingProduct = false);
      }
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // EAN-13 Barcode Generation
  // ═══════════════════════════════════════════════════════════════════════════

  /// Generate a valid EAN-13 barcode
  String _generateEAN13Barcode() {
    final timestamp = DateTime.now().millisecondsSinceEpoch.toString();
    final random = Random();

    // Prefix 200-299 is for internal use (store-specific)
    final prefix = '20${random.nextInt(10)}';

    // Get unique part from timestamp (last 9 digits)
    final uniquePart = timestamp.substring(timestamp.length - 9);

    // Combine to get 12 digits (without check digit)
    final barcodeWithoutCheck = '$prefix$uniquePart';

    // Calculate EAN-13 check digit
    final checkDigit = _calculateEAN13CheckDigit(barcodeWithoutCheck);

    return '$barcodeWithoutCheck$checkDigit';
  }

  /// Calculate the check digit for EAN-13
  int _calculateEAN13CheckDigit(String barcode12) {
    int sum = 0;
    for (int i = 0; i < 12; i++) {
      final digit = int.parse(barcode12[i]);
      // Odd positions (0, 2, 4...) multiply by 1
      // Even positions (1, 3, 5...) multiply by 3
      sum += (i % 2 == 0) ? digit : digit * 3;
    }
    return (10 - (sum % 10)) % 10;
  }

  /// Validate if barcode is valid EAN-13
  bool _isValidEAN13(String barcode) {
    if (barcode.length != 13) return false;
    if (!RegExp(r'^\d{13}$').hasMatch(barcode)) return false;

    final checkDigit = _calculateEAN13CheckDigit(barcode.substring(0, 12));
    return checkDigit == int.parse(barcode[12]);
  }

  void _onGenerateBarcodePressed() {
    final newBarcode = _generateEAN13Barcode();
    setState(() {
      _barcodeController.text = newBarcode;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('تم توليد الباركود: $newBarcode'),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // Barcode Printing (Clean - No Name/Price)
  // ═══════════════════════════════════════════════════════════════════════════

  Future<void> _printBarcodeOnly() async {
    final barcode = _barcodeController.text.trim();

    if (barcode.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('الرجاء إدخال أو توليد باركود أولاً'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    if (!_isValidEAN13(barcode)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('الباركود غير صالح. يجب أن يكون EAN-13 صحيح'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() => _isPrintingBarcode = true);

    try {
      final pdf = pw.Document();

      // 57mm roll format for thermal printers
      final pageFormat = PdfPageFormat.roll57;

      pdf.addPage(
        pw.Page(
          pageFormat: pageFormat,
          margin: const pw.EdgeInsets.all(8),
          build: (context) {
            return pw.Center(
              child: pw.Column(
                mainAxisAlignment: pw.MainAxisAlignment.center,
                children: [
                  // Barcode only - no product name or price
                  pw.BarcodeWidget(
                    barcode: pw.Barcode.ean13(),
                    data: barcode,
                    width: 45 * PdfPageFormat.mm,
                    height: 20 * PdfPageFormat.mm,
                    drawText: true, // Shows barcode numbers only
                    textStyle: pw.TextStyle(
                      fontSize: 10,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      );

      await Printing.layoutPdf(
        onLayout: (format) async => pdf.save(),
        name: 'barcode_$barcode',
        format: pageFormat,
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('خطأ في طباعة الباركود: $e'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isPrintingBarcode = false);
      }
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // Form Submission
  // ═══════════════════════════════════════════════════════════════════════════

  Future<void> _saveProduct() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final productRepo = ref.read(productRepositoryProvider);

      final name = _nameController.text.trim();
      final barcode = _barcodeController.text.trim().isEmpty
          ? null
          : _barcodeController.text.trim();
      final description = _descriptionController.text.trim().isEmpty
          ? null
          : _descriptionController.text.trim();
      final purchasePrice = double.tryParse(_costPriceController.text) ?? 0;
      final salePrice = double.tryParse(_salePriceController.text) ?? 0;
      final quantity = int.tryParse(_stockController.text) ?? 0;
      final minQuantity = int.tryParse(_minStockController.text) ?? 0;
      final sku = _skuController.text.trim().isEmpty
          ? null
          : _skuController.text.trim();

      if (isEditing && widget.productId != null) {
        // تعديل منتج موجود
        await productRepo.updateProduct(
          id: widget.productId!,
          name: name,
          barcode: barcode,
          description: description,
          purchasePrice: purchasePrice,
          salePrice: salePrice,
          quantity: quantity,
          minQuantity: minQuantity,
          sku: sku,
          categoryId: _selectedCategoryId,
        );
      } else {
        // إضافة منتج جديد
        await productRepo.createProduct(
          name: name,
          barcode: barcode,
          description: description,
          purchasePrice: purchasePrice,
          salePrice: salePrice,
          quantity: quantity,
          minQuantity: minQuantity,
          sku: sku,
          categoryId: _selectedCategoryId,
        );
      }

      if (mounted) {
        Navigator.of(context).pop(true);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                isEditing ? 'تم تحديث المنتج بنجاح' : 'تم إضافة المنتج بنجاح'),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('خطأ: $e'),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: _buildAppBar(),
      body: _isLoadingProduct
          ? const Center(child: CircularProgressIndicator())
          : _buildBody(),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: AppColors.surface,
      elevation: 0,
      leading: IconButton(
        onPressed: () => Navigator.of(context).pop(),
        icon: Icon(
          Icons.arrow_back_ios_rounded,
          color: AppColors.textSecondary,
          size: AppIconSize.sm,
        ),
      ),
      title: Text(
        isEditing ? 'تعديل المنتج' : 'إضافة منتج',
        style: AppTypography.headlineSmall.copyWith(
          color: AppColors.textPrimary,
          fontWeight: FontWeight.w700,
        ),
      ),
      centerTitle: true,
      actions: [
        TextButton(
          onPressed: _isLoading ? null : _saveProduct,
          child: _isLoading
              ? SizedBox(
                  width: 20.w,
                  height: 20.w,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: AppColors.primary,
                  ),
                )
              : Text(
                  'حفظ',
                  style: AppTypography.labelLarge.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
        ),
        SizedBox(width: AppSpacing.sm),
      ],
    );
  }

  Widget _buildBody() {
    return Form(
      key: _formKey,
      child: ListView(
        padding: EdgeInsets.all(AppSpacing.md),
        children: [
          // Product Name
          _buildSectionTitle('معلومات المنتج'),
          SizedBox(height: AppSpacing.sm),
          _buildTextField(
            controller: _nameController,
            label: 'اسم المنتج',
            hint: 'أدخل اسم المنتج',
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'الرجاء إدخال اسم المنتج';
              }
              return null;
            },
          ),
          SizedBox(height: AppSpacing.md),

          // Barcode with Generate & Print buttons
          _buildBarcodeField(),
          SizedBox(height: AppSpacing.md),

          // Description
          _buildTextField(
            controller: _descriptionController,
            label: 'الوصف',
            hint: 'أدخل وصف المنتج (اختياري)',
            maxLines: 3,
          ),
          SizedBox(height: AppSpacing.lg),

          // Pricing Section
          _buildSectionTitle('التسعير'),
          SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              Expanded(
                child: _buildTextField(
                  controller: _costPriceController,
                  label: 'سعر التكلفة',
                  hint: '0.00',
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'[\d.]')),
                  ],
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'الرجاء إدخال سعر التكلفة';
                    }
                    return null;
                  },
                ),
              ),
              SizedBox(width: AppSpacing.md),
              Expanded(
                child: _buildTextField(
                  controller: _salePriceController,
                  label: 'سعر البيع (اختياري)',
                  hint: '0.00',
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'[\d.]')),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: AppSpacing.lg),

          // Stock Section
          _buildSectionTitle('المخزون'),
          SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              Expanded(
                child: _buildTextField(
                  controller: _stockController,
                  label: 'الكمية الحالية',
                  hint: '0',
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                  ],
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'الرجاء إدخال الكمية';
                    }
                    return null;
                  },
                ),
              ),
              SizedBox(width: AppSpacing.md),
              Expanded(
                child: _buildTextField(
                  controller: _minStockController,
                  label: 'الحد الأدنى',
                  hint: '0',
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: AppSpacing.md),

          // SKU
          _buildTextField(
            controller: _skuController,
            label: 'رمز المنتج (SKU)',
            hint: 'رمز المنتج الفريد (اختياري)',
          ),
          SizedBox(height: AppSpacing.xl),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: AppTypography.titleMedium.copyWith(
        color: AppColors.textPrimary,
        fontWeight: FontWeight.w600,
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    String? hint,
    int maxLines = 1,
    TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
    String? Function(String?)? validator,
    Widget? suffix,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppTypography.labelMedium.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
        SizedBox(height: AppSpacing.xs),
        TextFormField(
          controller: controller,
          maxLines: maxLines,
          keyboardType: keyboardType,
          inputFormatters: inputFormatters,
          validator: validator,
          style: AppTypography.bodyMedium.copyWith(
            color: AppColors.textPrimary,
          ),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: AppTypography.bodyMedium.copyWith(
              color: AppColors.textTertiary,
            ),
            filled: true,
            fillColor: AppColors.surface,
            suffixIcon: suffix,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppRadius.md),
              borderSide: BorderSide(color: AppColors.border),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppRadius.md),
              borderSide: BorderSide(color: AppColors.border),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppRadius.md),
              borderSide: BorderSide(color: AppColors.primary, width: 2),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppRadius.md),
              borderSide: BorderSide(color: AppColors.error),
            ),
            contentPadding: EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.sm,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBarcodeField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'الباركود',
          style: AppTypography.labelMedium.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
        SizedBox(height: AppSpacing.xs),
        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: _barcodeController,
                keyboardType: TextInputType.number,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(13),
                ],
                style: AppTypography.bodyMedium.copyWith(
                  color: AppColors.textPrimary,
                  fontFamily: 'monospace',
                  letterSpacing: 2,
                ),
                decoration: InputDecoration(
                  hintText: '0000000000000',
                  hintStyle: AppTypography.bodyMedium.copyWith(
                    color: AppColors.textTertiary,
                    fontFamily: 'monospace',
                    letterSpacing: 2,
                  ),
                  filled: true,
                  fillColor: AppColors.surface,
                  prefixIcon: Icon(
                    Icons.qr_code_rounded,
                    color: AppColors.textTertiary,
                    size: AppIconSize.sm,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.horizontal(
                      right: Radius.circular(AppRadius.md),
                    ),
                    borderSide: BorderSide(color: AppColors.border),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.horizontal(
                      right: Radius.circular(AppRadius.md),
                    ),
                    borderSide: BorderSide(color: AppColors.border),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.horizontal(
                      right: Radius.circular(AppRadius.md),
                    ),
                    borderSide: BorderSide(color: AppColors.primary, width: 2),
                  ),
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: AppSpacing.md,
                    vertical: AppSpacing.sm,
                  ),
                ),
              ),
            ),
            // Generate Button
            Container(
              height: 48.h,
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                border: Border.all(color: AppColors.primary.withOpacity(0.3)),
              ),
              child: IconButton(
                onPressed: _onGenerateBarcodePressed,
                icon: Icon(
                  Icons.auto_awesome_rounded,
                  color: AppColors.primary,
                  size: AppIconSize.sm,
                ),
                tooltip: 'توليد باركود',
              ),
            ),
            // Print Button
            Container(
              height: 48.h,
              decoration: BoxDecoration(
                color: AppColors.secondary.withOpacity(0.1),
                border: Border.all(color: AppColors.secondary.withOpacity(0.3)),
                borderRadius: BorderRadius.horizontal(
                  left: Radius.circular(AppRadius.md),
                ),
              ),
              child: IconButton(
                onPressed: _isPrintingBarcode ? null : _printBarcodeOnly,
                icon: _isPrintingBarcode
                    ? SizedBox(
                        width: 18.w,
                        height: 18.w,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppColors.secondary,
                        ),
                      )
                    : Icon(
                        Icons.print_rounded,
                        color: AppColors.secondary,
                        size: AppIconSize.sm,
                      ),
                tooltip: 'طباعة الباركود',
              ),
            ),
          ],
        ),
        SizedBox(height: AppSpacing.xs),
        Text(
          'اضغط على ✨ لتوليد باركود EAN-13 تلقائياً',
          style: AppTypography.bodySmall.copyWith(
            color: AppColors.textTertiary,
          ),
        ),
      ],
    );
  }
}
