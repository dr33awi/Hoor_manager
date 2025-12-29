import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gap/gap.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:printing/printing.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../../../core/di/injection.dart';
import '../../../core/theme/app_colors.dart';
import '../../../data/database/app_database.dart';
import '../../../data/repositories/product_repository.dart';
import '../../../data/repositories/category_repository.dart';

class ProductFormScreen extends ConsumerStatefulWidget {
  final String? productId;

  const ProductFormScreen({super.key, this.productId});

  @override
  ConsumerState<ProductFormScreen> createState() => _ProductFormScreenState();
}

class _ProductFormScreenState extends ConsumerState<ProductFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _productRepo = getIt<ProductRepository>();
  final _categoryRepo = getIt<CategoryRepository>();

  final _nameController = TextEditingController();
  final _barcodeController = TextEditingController();
  final _purchasePriceController = TextEditingController();
  final _salePriceController = TextEditingController();
  final _quantityController = TextEditingController(text: '0');
  final _minQuantityController = TextEditingController(text: '5');
  final _descriptionController = TextEditingController();

  String? _selectedCategoryId;
  bool _isLoading = false;
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
      appBar: AppBar(
        title: Text(_isEditing ? 'تعديل منتج' : 'إضافة منتج'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Form(
              key: _formKey,
              child: ListView(
                padding: EdgeInsets.all(16.w),
                children: [
                  // Product Name
                  TextFormField(
                    controller: _nameController,
                    decoration: const InputDecoration(
                      labelText: 'اسم المنتج *',
                      prefixIcon: Icon(Icons.inventory_2),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'يرجى إدخال اسم المنتج';
                      }
                      return null;
                    },
                  ),
                  Gap(16.h),

                  // Barcode
                  TextFormField(
                    controller: _barcodeController,
                    decoration: InputDecoration(
                      labelText: 'الباركود',
                      prefixIcon: const Icon(Icons.qr_code),
                      suffixIcon: IconButton(
                        icon: const Icon(Icons.qr_code_scanner),
                        onPressed: _scanBarcode,
                      ),
                    ),
                  ),
                  Gap(8.h),
                  // Barcode Actions
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _generateBarcode,
                          icon: const Icon(Icons.auto_awesome),
                          label: const Text('توليد باركود'),
                        ),
                      ),
                      Gap(8.w),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _barcodeController.text.isEmpty
                              ? null
                              : _printBarcode,
                          icon: const Icon(Icons.print),
                          label: const Text('طباعة الباركود'),
                        ),
                      ),
                    ],
                  ),
                  Gap(16.h),

                  // Category
                  StreamBuilder<List<Category>>(
                    stream: _categoryRepo.watchAllCategories(),
                    builder: (context, snapshot) {
                      final categories = snapshot.data ?? [];
                      return DropdownButtonFormField<String>(
                        value: _selectedCategoryId,
                        decoration: const InputDecoration(
                          labelText: 'التصنيف',
                          prefixIcon: Icon(Icons.category),
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
                        onChanged: (value) =>
                            setState(() => _selectedCategoryId = value),
                      );
                    },
                  ),
                  Gap(16.h),

                  // Prices
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _purchasePriceController,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            labelText: 'سعر الشراء *',
                            prefixIcon: Icon(Icons.shopping_cart),
                            suffixText: 'ل.س',
                          ),
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
                      Gap(12.w),
                      Expanded(
                        child: TextFormField(
                          controller: _salePriceController,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            labelText: 'سعر البيع *',
                            prefixIcon: Icon(Icons.sell),
                            suffixText: 'ل.س',
                          ),
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
                    ],
                  ),
                  Gap(16.h),

                  // Quantity & Min Quantity
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _quantityController,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            labelText: 'الكمية',
                            prefixIcon: Icon(Icons.numbers),
                          ),
                          enabled: !_isEditing, // Disable for edit mode
                        ),
                      ),
                      Gap(12.w),
                      Expanded(
                        child: TextFormField(
                          controller: _minQuantityController,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            labelText: 'الحد الأدنى',
                            prefixIcon: Icon(Icons.warning),
                          ),
                        ),
                      ),
                    ],
                  ),
                  Gap(16.h),

                  // Description
                  TextFormField(
                    controller: _descriptionController,
                    maxLines: 3,
                    decoration: const InputDecoration(
                      labelText: 'الوصف',
                      prefixIcon: Icon(Icons.description),
                      alignLabelWithHint: true,
                    ),
                  ),
                  Gap(24.h),

                  // Save Button
                  SizedBox(
                    height: 50.h,
                    child: ElevatedButton(
                      onPressed: _saveProduct,
                      child: Text(
                        _isEditing ? 'حفظ التغييرات' : 'إضافة المنتج',
                        style: TextStyle(fontSize: 16.sp),
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Future<void> _scanBarcode() async {
    final barcode = await showDialog<String>(
      context: context,
      builder: (context) => _BarcodeScannerDialog(),
    );

    if (barcode != null) {
      setState(() {
        _barcodeController.text = barcode;
      });
    }
  }

  void _generateBarcode() {
    // Generate a random 13-digit EAN-13 barcode
    final random = Random();
    String barcode = '';

    // Generate first 12 digits
    for (int i = 0; i < 12; i++) {
      barcode += random.nextInt(10).toString();
    }

    // Calculate check digit for EAN-13
    int sum = 0;
    for (int i = 0; i < 12; i++) {
      int digit = int.parse(barcode[i]);
      sum += (i % 2 == 0) ? digit : digit * 3;
    }
    int checkDigit = (10 - (sum % 10)) % 10;
    barcode += checkDigit.toString();

    setState(() {
      _barcodeController.text = barcode;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('تم توليد باركود جديد'),
        backgroundColor: AppColors.success,
      ),
    );
  }

  Future<void> _printBarcode() async {
    if (_barcodeController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('لا يوجد باركود للطباعة'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    try {
      final pdf = pw.Document();
      final barcodeValue = _barcodeController.text;

      // Determine barcode type based on length
      pw.Barcode barcodeType;
      if (barcodeValue.length == 13) {
        barcodeType = pw.Barcode.ean13();
      } else if (barcodeValue.length == 8) {
        barcodeType = pw.Barcode.ean8();
      } else {
        barcodeType = pw.Barcode.code128();
      }

      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.roll80,
          textDirection: pw.TextDirection.rtl,
          build: (pw.Context context) {
            return pw.Center(
              child: pw.Column(
                mainAxisAlignment: pw.MainAxisAlignment.center,
                children: [
                  pw.BarcodeWidget(
                    barcode: barcodeType,
                    data: barcodeValue,
                    width: 150,
                    height: 50,
                    drawText: false,
                  ),
                ],
              ),
            );
          },
        ),
      );

      await Printing.layoutPdf(
        onLayout: (PdfPageFormat format) async => pdf.save(),
        name: 'barcode_$barcodeValue',
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('خطأ في الطباعة: $e'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  Future<void> _saveProduct() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final purchasePrice = double.parse(_purchasePriceController.text);
      final salePrice = double.parse(_salePriceController.text);
      final quantity = int.tryParse(_quantityController.text) ?? 0;
      final minQuantity = int.tryParse(_minQuantityController.text) ?? 5;

      print('_saveProduct called - isEditing: $_isEditing');
      print('Product ID: ${widget.productId}');
      print('Values: purchasePrice=$purchasePrice, salePrice=$salePrice');

      if (_isEditing) {
        print('Calling updateProduct...');
        await _productRepo.updateProduct(
          id: widget.productId!,
          name: _nameController.text,
          barcode:
              _barcodeController.text.isEmpty ? null : _barcodeController.text,
          categoryId: _selectedCategoryId,
          purchasePrice: purchasePrice,
          salePrice: salePrice,
          minQuantity: minQuantity,
          description: _descriptionController.text.isEmpty
              ? null
              : _descriptionController.text,
        );
        print('updateProduct completed');
      } else {
        await _productRepo.createProduct(
          name: _nameController.text,
          barcode:
              _barcodeController.text.isEmpty ? null : _barcodeController.text,
          categoryId: _selectedCategoryId,
          purchasePrice: purchasePrice,
          salePrice: salePrice,
          quantity: quantity,
          minQuantity: minQuantity,
          description: _descriptionController.text.isEmpty
              ? null
              : _descriptionController.text,
        );
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                _isEditing ? 'تم تحديث المنتج بنجاح' : 'تم إضافة المنتج بنجاح'),
            backgroundColor: AppColors.success,
          ),
        );
        context.pop();
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('حدث خطأ: $e'),
          backgroundColor: AppColors.error,
        ),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }
}

class _BarcodeScannerDialog extends StatefulWidget {
  @override
  State<_BarcodeScannerDialog> createState() => _BarcodeScannerDialogState();
}

class _BarcodeScannerDialogState extends State<_BarcodeScannerDialog> {
  final MobileScannerController _controller = MobileScannerController();
  bool _scanned = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('مسح الباركود'),
      content: SizedBox(
        width: 300.w,
        height: 300.h,
        child: MobileScanner(
          controller: _controller,
          onDetect: (capture) {
            if (_scanned) return;
            final barcode = capture.barcodes.firstOrNull?.rawValue;
            if (barcode != null) {
              _scanned = true;
              Navigator.pop(context, barcode);
            }
          },
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('إلغاء'),
        ),
      ],
    );
  }
}
