import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gap/gap.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:intl/intl.dart';

import '../../../core/di/injection.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/constants/app_constants.dart';
import '../../../data/database/app_database.dart';
import '../../../data/repositories/product_repository.dart';
import '../../../data/repositories/invoice_repository.dart';
import '../../../data/repositories/shift_repository.dart';
import '../../../data/repositories/cash_repository.dart';
import '../../../data/repositories/customer_repository.dart';
import '../../../data/repositories/supplier_repository.dart';

/// تنسيق السعر بالليرة السورية (بدون أصفار زائدة)
String _formatSyrianPrice(double price) {
  if (price == price.roundToDouble()) {
    return price.toStringAsFixed(0);
  }
  String formatted = price.toStringAsFixed(2);
  if (formatted.endsWith('0')) {
    formatted = formatted.substring(0, formatted.length - 1);
  }
  if (formatted.endsWith('0')) {
    formatted = formatted.substring(0, formatted.length - 1);
  }
  if (formatted.endsWith('.')) {
    formatted = formatted.substring(0, formatted.length - 1);
  }
  return formatted;
}

class InvoiceFormScreen extends ConsumerStatefulWidget {
  final String type;

  const InvoiceFormScreen({super.key, required this.type});

  @override
  ConsumerState<InvoiceFormScreen> createState() => _InvoiceFormScreenState();
}

class _InvoiceFormScreenState extends ConsumerState<InvoiceFormScreen> {
  final _productRepo = getIt<ProductRepository>();
  final _invoiceRepo = getIt<InvoiceRepository>();
  final _shiftRepo = getIt<ShiftRepository>();
  final _cashRepo = getIt<CashRepository>();
  final _customerRepo = getIt<CustomerRepository>();
  final _supplierRepo = getIt<SupplierRepository>();
  final _database = getIt<AppDatabase>();

  final _searchController = TextEditingController();
  final _discountController = TextEditingController(text: '0');
  final _notesController = TextEditingController();

  final List<Map<String, dynamic>> _items = [];
  final Map<String, int> _productStock = {}; // لتخزين كميات المخزون
  String _paymentMethod = 'cash';
  bool _isLoading = false;
  Shift? _currentShift;

  // إعدادات الطباعة
  bool _autoPrint = false;
  String _printSize = '80mm';

  // العميل والمورد (اختياري)
  Customer? _selectedCustomer;
  Supplier? _selectedSupplier;
  List<Customer> _customers = [];
  List<Supplier> _suppliers = [];

  @override
  void initState() {
    super.initState();
    _loadCurrentShift();
    _loadCustomersAndSuppliers();
    _loadPrintSettings();
  }

  Future<void> _loadPrintSettings() async {
    final autoPrint = await _database.getSetting('auto_print');
    final printSize = await _database.getSetting('print_size');
    setState(() {
      _autoPrint = autoPrint == 'true';
      _printSize = printSize ?? '80mm';
    });
  }

  Future<void> _loadCurrentShift() async {
    final shift = await _shiftRepo.getOpenShift();
    setState(() => _currentShift = shift);
  }

  Future<void> _loadCustomersAndSuppliers() async {
    final customers = await _customerRepo.getAllCustomers();
    final suppliers = await _supplierRepo.getAllSuppliers();
    setState(() {
      _customers = customers.where((c) => c.isActive).toList();
      _suppliers = suppliers.where((s) => s.isActive).toList();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _discountController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  String get _typeTitle {
    switch (widget.type) {
      case 'sale':
        return 'فاتورة مبيعات جديدة';
      case 'purchase':
        return 'فاتورة مشتريات جديدة';
      case 'sale_return':
        return 'مرتجع مبيعات';
      case 'purchase_return':
        return 'مرتجع مشتريات';
      case 'opening_balance':
        return 'فاتورة أول المدة';
      default:
        return 'فاتورة جديدة';
    }
  }

  double get _subtotal => _items.fold(
      0,
      (sum, item) =>
          sum + (item['quantity'] as int) * (item['unitPrice'] as double));

  double get _discount => double.tryParse(_discountController.text) ?? 0;

  double get _total => _subtotal - _discount;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_typeTitle),
        actions: [
          if (_currentShift == null && widget.type != 'opening_balance')
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 8.w),
              child: Chip(
                label: const Text('لا توجد وردية'),
                backgroundColor: AppColors.warning.withOpacity(0.2),
              ),
            ),
        ],
      ),
      body: Column(
        children: [
          // Search & Add Product
          Padding(
            padding: EdgeInsets.all(16.w),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'بحث عن منتج...',
                      prefixIcon: const Icon(Icons.search),
                      suffixIcon: IconButton(
                        icon: const Icon(Icons.qr_code_scanner),
                        onPressed: _scanBarcode,
                      ),
                    ),
                    onSubmitted: _searchProduct,
                  ),
                ),
                Gap(8.w),
                IconButton(
                  icon: const Icon(Icons.add_circle),
                  color: AppColors.primary,
                  iconSize: 40.sp,
                  onPressed: () => _showProductsDialog(),
                ),
              ],
            ),
          ),

          // Items List
          Expanded(
            child: _items.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.shopping_basket_outlined,
                          size: 64.sp,
                          color: Colors.grey,
                        ),
                        Gap(16.h),
                        Text(
                          'أضف منتجات إلى الفاتورة',
                          style: TextStyle(
                            fontSize: 16.sp,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: EdgeInsets.symmetric(horizontal: 16.w),
                    itemCount: _items.length,
                    itemBuilder: (context, index) {
                      final item = _items[index];
                      final isSale = widget.type == 'sale' ||
                          widget.type == 'purchase_return';
                      return _InvoiceItemCard(
                        item: item,
                        isPurchase: widget.type == 'purchase' ||
                            widget.type == 'opening_balance',
                        isSale: isSale,
                        onQuantityChanged: (qty) {
                          if (isSale) {
                            final availableStock =
                                item['availableStock'] as int? ??
                                    _productStock[item['productId']] ??
                                    999;
                            if (qty > availableStock) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                      'الكمية المطلوبة ($qty) أكبر من المتاح ($availableStock)'),
                                  backgroundColor: AppColors.warning,
                                ),
                              );
                              return;
                            }
                          }
                          setState(() => item['quantity'] = qty);
                        },
                        onPriceChanged: (price) {
                          setState(() => item['unitPrice'] = price);
                        },
                        onRemove: () {
                          setState(() => _items.removeAt(index));
                        },
                      );
                    },
                  ),
          ),

          // Summary & Submit
          Container(
            padding: EdgeInsets.all(16.w),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 10,
                  offset: const Offset(0, -5),
                ),
              ],
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Customer/Supplier Selection (optional)
                  if (widget.type == 'sale' ||
                      widget.type == 'sale_return') ...[
                    DropdownButtonFormField<Customer?>(
                      value: _selectedCustomer,
                      decoration: InputDecoration(
                        labelText: 'العميل (اختياري)',
                        prefixIcon: const Icon(Icons.person),
                        isDense: true,
                        suffixIcon: _selectedCustomer != null
                            ? IconButton(
                                icon: const Icon(Icons.clear, size: 18),
                                onPressed: () =>
                                    setState(() => _selectedCustomer = null),
                              )
                            : null,
                      ),
                      items: [
                        const DropdownMenuItem<Customer?>(
                          value: null,
                          child: Text('بدون عميل'),
                        ),
                        ..._customers.map((c) => DropdownMenuItem(
                              value: c,
                              child: Text(c.name),
                            )),
                      ],
                      onChanged: (value) =>
                          setState(() => _selectedCustomer = value),
                    ),
                    Gap(8.h),
                  ],
                  if (widget.type == 'purchase' ||
                      widget.type == 'purchase_return' ||
                      widget.type == 'opening_balance') ...[
                    DropdownButtonFormField<Supplier?>(
                      value: _selectedSupplier,
                      decoration: InputDecoration(
                        labelText: 'المورد (اختياري)',
                        prefixIcon: const Icon(Icons.business),
                        isDense: true,
                        suffixIcon: _selectedSupplier != null
                            ? IconButton(
                                icon: const Icon(Icons.clear, size: 18),
                                onPressed: () =>
                                    setState(() => _selectedSupplier = null),
                              )
                            : null,
                      ),
                      items: [
                        const DropdownMenuItem<Supplier?>(
                          value: null,
                          child: Text('بدون مورد'),
                        ),
                        ..._suppliers.map((s) => DropdownMenuItem(
                              value: s,
                              child: Text(s.name),
                            )),
                      ],
                      onChanged: (value) =>
                          setState(() => _selectedSupplier = value),
                    ),
                    Gap(8.h),
                  ],
                  // Discount
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _discountController,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            labelText: 'الخصم',
                            prefixIcon: Icon(Icons.discount),
                            suffixText: 'ل.س',
                            isDense: true,
                          ),
                          onChanged: (_) => setState(() {}),
                        ),
                      ),
                      Gap(16.w),
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          value: _paymentMethod,
                          decoration: const InputDecoration(
                            labelText: 'طريقة الدفع',
                            prefixIcon: Icon(Icons.payment),
                            isDense: true,
                          ),
                          items: PaymentMethod.values
                              .map((p) => DropdownMenuItem(
                                    value: p.value,
                                    child: Text(p.label),
                                  ))
                              .toList(),
                          onChanged: (value) =>
                              setState(() => _paymentMethod = value!),
                        ),
                      ),
                    ],
                  ),
                  Gap(12.h),

                  // Totals
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('المجموع:', style: TextStyle(fontSize: 14.sp)),
                      Text('${_formatSyrianPrice(_subtotal)} ل.س'),
                    ],
                  ),
                  if (_discount > 0) ...[
                    Gap(4.h),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('الخصم:',
                            style: TextStyle(
                                fontSize: 14.sp, color: AppColors.error)),
                        Text('-${_formatSyrianPrice(_discount)} ل.س',
                            style: TextStyle(color: AppColors.error)),
                      ],
                    ),
                  ],
                  Gap(8.h),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'الإجمالي:',
                        style: TextStyle(
                          fontSize: 18.sp,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        '${_formatSyrianPrice(_total)} ل.س',
                        style: TextStyle(
                          fontSize: 20.sp,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                  Gap(12.h),

                  // Submit Button
                  SizedBox(
                    width: double.infinity,
                    height: 50.h,
                    child: ElevatedButton(
                      onPressed:
                          _items.isEmpty || _isLoading ? null : _submitInvoice,
                      child: _isLoading
                          ? const CircularProgressIndicator(color: Colors.white)
                          : Text(
                              'حفظ الفاتورة',
                              style: TextStyle(fontSize: 16.sp),
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _scanBarcode() async {
    final barcode = await showDialog<String>(
      context: context,
      builder: (context) => _BarcodeScannerDialog(),
    );

    if (barcode != null) {
      final product = await _productRepo.getProductByBarcode(barcode);
      if (product != null) {
        _addProduct(product);
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('المنتج غير موجود')),
          );
        }
      }
    }
  }

  Future<void> _searchProduct(String query) async {
    if (query.isEmpty) return;

    // Try barcode first
    var product = await _productRepo.getProductByBarcode(query);

    if (product == null) {
      // Show search results
      await _showProductsDialog(searchQuery: query);
    } else {
      _addProduct(product);
    }

    _searchController.clear();
  }

  Future<void> _showProductsDialog({String? searchQuery}) async {
    final products = await _productRepo.getAllProducts();
    var filtered = products.where((p) => p.isActive).toList();

    if (searchQuery != null && searchQuery.isNotEmpty) {
      filtered = filtered
          .where((p) =>
              p.name.toLowerCase().contains(searchQuery.toLowerCase()) ||
              (p.sku?.toLowerCase().contains(searchQuery.toLowerCase()) ??
                  false))
          .toList();
    }

    if (!mounted) return;

    final selected = await showDialog<Product>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('اختر منتج'),
        content: SizedBox(
          width: double.maxFinite,
          height: 400.h,
          child: ListView.builder(
            itemCount: filtered.length,
            itemBuilder: (context, index) {
              final product = filtered[index];
              return ListTile(
                title: Text(product.name),
                subtitle: Text('${_formatSyrianPrice(product.salePrice)} ل.س'),
                trailing: Text('الكمية: ${product.quantity}'),
                onTap: () => Navigator.pop(context, product),
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إلغاء'),
          ),
        ],
      ),
    );

    if (selected != null) {
      _addProduct(selected);
    }
  }

  void _addProduct(Product product) {
    // For sales, check stock availability
    final isSale = widget.type == 'sale' || widget.type == 'purchase_return';

    if (isSale && product.quantity <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('المنتج "${product.name}" غير متوفر في المخزون'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    // Check if already in list
    final existingIndex =
        _items.indexWhere((i) => i['productId'] == product.id);

    if (existingIndex >= 0) {
      final currentQty = _items[existingIndex]['quantity'] as int;
      final availableStock = _productStock[product.id] ?? product.quantity;

      if (isSale && currentQty >= availableStock) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content:
                Text('لا يمكن إضافة المزيد. الكمية المتاحة: $availableStock'),
            backgroundColor: AppColors.warning,
          ),
        );
        return;
      }

      setState(() {
        _items[existingIndex]['quantity']++;
      });
    } else {
      // Store the original stock for this product
      _productStock[product.id] = product.quantity;

      final isPurchase =
          widget.type == 'purchase' || widget.type == 'opening_balance';
      setState(() {
        _items.add({
          'productId': product.id,
          'productName': product.name,
          'quantity': 1,
          'unitPrice': isPurchase ? product.purchasePrice : product.salePrice,
          'purchasePrice': product.purchasePrice,
          'availableStock': product.quantity, // تخزين الكمية المتاحة
        });
      });
    }
  }

  Future<void> _submitInvoice() async {
    if (_items.isEmpty) return;

    // Check for open shift (except for opening balance)
    if (widget.type != 'opening_balance' && _currentShift == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('يجب فتح وردية أولاً'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final invoiceId = await _invoiceRepo.createInvoice(
        type: widget.type,
        items: _items,
        discountAmount: _discount,
        paymentMethod: _paymentMethod,
        paidAmount: _total,
        notes: _notesController.text.isEmpty ? null : _notesController.text,
        shiftId: _currentShift?.id,
        customerId: _selectedCustomer?.id,
        supplierId: _selectedSupplier?.id,
      );

      // Record cash movement if there's an open shift
      if (_currentShift != null) {
        if (widget.type == 'sale') {
          await _cashRepo.recordSale(
            shiftId: _currentShift!.id,
            amount: _total,
            invoiceId: invoiceId,
            paymentMethod: _paymentMethod,
          );
        } else if (widget.type == 'purchase') {
          await _cashRepo.recordPurchase(
            shiftId: _currentShift!.id,
            amount: _total,
            invoiceId: invoiceId,
            paymentMethod: _paymentMethod,
          );
        }
      }

      if (mounted) {
        // عرض ديالوغ للسؤال عن الطباعة
        final shouldPrint = await showDialog<bool>(
          context: context,
          barrierDismissible: false,
          builder: (context) => AlertDialog(
            title: const Row(
              children: [
                Icon(Icons.check_circle, color: AppColors.success, size: 28),
                SizedBox(width: 12),
                Text('تم حفظ الفاتورة'),
              ],
            ),
            content: const Text('هل تريد طباعة الفاتورة؟'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('لا'),
              ),
              ElevatedButton.icon(
                onPressed: () => Navigator.pop(context, true),
                icon: const Icon(Icons.print, size: 18),
                label: const Text('طباعة'),
              ),
            ],
          ),
        );

        if (shouldPrint == true && mounted) {
          final invoice = await _invoiceRepo.getInvoiceById(invoiceId);
          if (invoice != null) {
            await _printInvoice(invoice, invoiceId);
          }
        }

        if (mounted) {
          context.pop();
        }
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

  /// طباعة الفاتورة
  Future<void> _printInvoice(Invoice invoice, String invoiceId) async {
    final doc = pw.Document();

    // تحميل الخطوط العربية
    final arabicFont = await PdfGoogleFonts.cairoRegular();
    final arabicFontBold = await PdfGoogleFonts.cairoBold();
    final arabicFontLight = await PdfGoogleFonts.cairoLight();

    // الحصول على عناصر الفاتورة
    final items = await _invoiceRepo.getInvoiceItems(invoiceId);

    final typeLabel = _getTypeLabelForPrint(invoice.type);
    final typeColor = _getTypeColorForPrint(invoice.type);

    // محاولة تحميل الشعار
    pw.MemoryImage? logoImage;
    try {
      final logoData = await rootBundle.load('assets/images/Hoor-icons.png');
      logoImage = pw.MemoryImage(logoData.buffer.asUint8List());
    } catch (e) {
      // الشعار غير متاح
    }

    // تحديد حجم الورق
    PdfPageFormat pageFormat;
    pw.EdgeInsets margin;
    switch (_printSize) {
      case '58mm':
        pageFormat = PdfPageFormat.roll57;
        margin = const pw.EdgeInsets.all(8);
        break;
      case 'A4':
        pageFormat = PdfPageFormat.a4;
        margin = const pw.EdgeInsets.all(32);
        break;
      default:
        pageFormat = PdfPageFormat.roll80;
        margin = const pw.EdgeInsets.all(12);
    }

    doc.addPage(
      pw.Page(
        pageFormat: pageFormat,
        textDirection: pw.TextDirection.rtl,
        margin: margin,
        theme: pw.ThemeData.withFont(
          base: arabicFont,
          bold: arabicFontBold,
        ),
        build: (context) {
          // للطابعات الحرارية (58mm و 80mm) - تصميم مبسط
          if (_printSize == '58mm' || _printSize == '80mm') {
            return pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.stretch,
              children: [
                // Header
                pw.Center(
                  child: pw.Text(
                    'Hoor Manager',
                    style: pw.TextStyle(
                      font: arabicFontBold,
                      fontSize: _printSize == '58mm' ? 14 : 18,
                    ),
                  ),
                ),
                pw.SizedBox(height: 4),
                pw.Center(
                  child: pw.Container(
                    padding: const pw.EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: pw.BoxDecoration(
                      color: typeColor,
                      borderRadius: pw.BorderRadius.circular(4),
                    ),
                    child: pw.Text(
                      typeLabel,
                      style: pw.TextStyle(
                        font: arabicFontBold,
                        fontSize: _printSize == '58mm' ? 10 : 12,
                        color: PdfColors.white,
                      ),
                    ),
                  ),
                ),
                pw.SizedBox(height: 8),
                pw.Divider(thickness: 0.5),
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text('رقم: ${invoice.invoiceNumber}',
                        style: pw.TextStyle(font: arabicFont, fontSize: 8)),
                    pw.Text(
                        DateFormat('dd/MM/yyyy HH:mm')
                            .format(invoice.createdAt),
                        style: pw.TextStyle(font: arabicFont, fontSize: 8)),
                  ],
                ),
                pw.Divider(thickness: 0.5),
                pw.SizedBox(height: 4),
                // Items Header
                pw.Container(
                  padding: const pw.EdgeInsets.symmetric(vertical: 4),
                  decoration: const pw.BoxDecoration(
                    color: PdfColors.grey200,
                  ),
                  child: pw.Row(
                    children: [
                      pw.Expanded(
                        flex: 4,
                        child: pw.Text('المنتج',
                            style: pw.TextStyle(
                                font: arabicFontBold, fontSize: 8)),
                      ),
                      pw.Expanded(
                        flex: 2,
                        child: pw.Text('الكمية',
                            style:
                                pw.TextStyle(font: arabicFontBold, fontSize: 8),
                            textAlign: pw.TextAlign.center),
                      ),
                      pw.Expanded(
                        flex: 2,
                        child: pw.Text('السعر',
                            style:
                                pw.TextStyle(font: arabicFontBold, fontSize: 8),
                            textAlign: pw.TextAlign.center),
                      ),
                      pw.Expanded(
                        flex: 2,
                        child: pw.Text('الإجمالي',
                            style:
                                pw.TextStyle(font: arabicFontBold, fontSize: 8),
                            textAlign: pw.TextAlign.left),
                      ),
                    ],
                  ),
                ),
                // Items
                ...items.map((item) => pw.Container(
                      padding: const pw.EdgeInsets.symmetric(vertical: 3),
                      decoration: const pw.BoxDecoration(
                        border: pw.Border(
                          bottom: pw.BorderSide(
                              color: PdfColors.grey300, width: 0.5),
                        ),
                      ),
                      child: pw.Row(
                        children: [
                          pw.Expanded(
                            flex: 4,
                            child: pw.Text(
                              item.productName,
                              style:
                                  pw.TextStyle(font: arabicFont, fontSize: 8),
                            ),
                          ),
                          pw.Expanded(
                            flex: 2,
                            child: pw.Text(
                              '${item.quantity}',
                              style:
                                  pw.TextStyle(font: arabicFont, fontSize: 8),
                              textAlign: pw.TextAlign.center,
                            ),
                          ),
                          pw.Expanded(
                            flex: 2,
                            child: pw.Text(
                              _formatSyrianPrice(item.unitPrice),
                              style:
                                  pw.TextStyle(font: arabicFont, fontSize: 8),
                              textAlign: pw.TextAlign.center,
                            ),
                          ),
                          pw.Expanded(
                            flex: 2,
                            child: pw.Text(
                              _formatSyrianPrice(item.total),
                              style: pw.TextStyle(
                                  font: arabicFontBold, fontSize: 8),
                              textAlign: pw.TextAlign.left,
                            ),
                          ),
                        ],
                      ),
                    )),
                pw.SizedBox(height: 8),
                pw.Divider(thickness: 1),
                // Totals
                if (invoice.discountAmount > 0)
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Text('المجموع الفرعي:',
                          style: pw.TextStyle(font: arabicFont, fontSize: 9)),
                      pw.Text('${_formatSyrianPrice(invoice.subtotal)} ل.س',
                          style: pw.TextStyle(font: arabicFont, fontSize: 9)),
                    ],
                  ),
                if (invoice.discountAmount > 0)
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Text('الخصم:',
                          style: pw.TextStyle(
                              font: arabicFont,
                              fontSize: 9,
                              color: PdfColors.red700)),
                      pw.Text(
                          '- ${_formatSyrianPrice(invoice.discountAmount)} ل.س',
                          style: pw.TextStyle(
                              font: arabicFont,
                              fontSize: 9,
                              color: PdfColors.red700)),
                    ],
                  ),
                pw.SizedBox(height: 4),
                pw.Container(
                  padding: const pw.EdgeInsets.symmetric(vertical: 6),
                  decoration: pw.BoxDecoration(
                    color: PdfColors.blue900,
                    borderRadius: pw.BorderRadius.circular(4),
                  ),
                  child: pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Padding(
                        padding: const pw.EdgeInsets.only(right: 8),
                        child: pw.Text('الإجمالي:',
                            style: pw.TextStyle(
                                font: arabicFontBold,
                                fontSize: 11,
                                color: PdfColors.white)),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.only(left: 8),
                        child: pw.Text(
                            '${_formatSyrianPrice(invoice.total)} ل.س',
                            style: pw.TextStyle(
                                font: arabicFontBold,
                                fontSize: 11,
                                color: PdfColors.white)),
                      ),
                    ],
                  ),
                ),
                pw.SizedBox(height: 12),
                pw.Center(
                  child: pw.Text(
                    'شكراً لتعاملكم معنا',
                    style: pw.TextStyle(font: arabicFontBold, fontSize: 10),
                  ),
                ),
                pw.SizedBox(height: 4),
                pw.Center(
                  child: pw.Text(
                    DateFormat('dd/MM/yyyy HH:mm').format(DateTime.now()),
                    style: pw.TextStyle(
                        font: arabicFontLight,
                        fontSize: 7,
                        color: PdfColors.grey600),
                  ),
                ),
              ],
            );
          }

          // للطباعة على A4 - التصميم الكامل
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.stretch,
            children: [
              // HEADER
              pw.Container(
                padding: const pw.EdgeInsets.all(20),
                decoration: pw.BoxDecoration(
                  gradient: pw.LinearGradient(
                    colors: [PdfColors.blue900, PdfColors.blue700],
                    begin: pw.Alignment.topLeft,
                    end: pw.Alignment.bottomRight,
                  ),
                  borderRadius: pw.BorderRadius.circular(12),
                ),
                child: pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text(
                          'Hoor Manager',
                          style: pw.TextStyle(
                            font: arabicFontBold,
                            fontSize: 28,
                            color: PdfColors.white,
                          ),
                        ),
                        pw.SizedBox(height: 6),
                        pw.Text(
                          'نظام إدارة المبيعات والمخزون',
                          style: pw.TextStyle(
                            font: arabicFontLight,
                            fontSize: 12,
                            color: PdfColors.blue100,
                          ),
                        ),
                      ],
                    ),
                    if (logoImage != null)
                      pw.Container(
                        width: 70,
                        height: 70,
                        decoration: pw.BoxDecoration(
                          color: PdfColors.white,
                          borderRadius: pw.BorderRadius.circular(35),
                        ),
                        padding: const pw.EdgeInsets.all(8),
                        child: pw.Image(logoImage),
                      )
                    else
                      pw.Container(
                        width: 70,
                        height: 70,
                        decoration: pw.BoxDecoration(
                          color: PdfColors.white,
                          borderRadius: pw.BorderRadius.circular(35),
                        ),
                        child: pw.Center(
                          child: pw.Text(
                            'H',
                            style: pw.TextStyle(
                              font: arabicFontBold,
                              fontSize: 36,
                              color: PdfColors.blue800,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              pw.SizedBox(height: 24),

              // INVOICE TYPE & NUMBER
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Container(
                    padding: const pw.EdgeInsets.symmetric(
                        horizontal: 20, vertical: 10),
                    decoration: pw.BoxDecoration(
                      color: typeColor,
                      borderRadius: pw.BorderRadius.circular(25),
                    ),
                    child: pw.Text(
                      typeLabel,
                      style: pw.TextStyle(
                        font: arabicFontBold,
                        fontSize: 14,
                        color: PdfColors.white,
                      ),
                    ),
                  ),
                  pw.Container(
                    padding: const pw.EdgeInsets.all(12),
                    decoration: pw.BoxDecoration(
                      border: pw.Border.all(color: PdfColors.grey400),
                      borderRadius: pw.BorderRadius.circular(8),
                    ),
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.end,
                      children: [
                        pw.Text(
                          'رقم الفاتورة',
                          style: pw.TextStyle(
                            font: arabicFontLight,
                            fontSize: 9,
                            color: PdfColors.grey600,
                          ),
                        ),
                        pw.SizedBox(height: 2),
                        pw.Text(
                          invoice.invoiceNumber,
                          style: pw.TextStyle(
                            font: arabicFontBold,
                            fontSize: 16,
                            color: PdfColors.blue900,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              pw.SizedBox(height: 20),

              // INVOICE DETAILS
              pw.Container(
                padding:
                    const pw.EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                decoration: pw.BoxDecoration(
                  color: PdfColors.grey100,
                  borderRadius: pw.BorderRadius.circular(10),
                ),
                child: pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
                  children: [
                    _buildInfoColumn(arabicFontBold, arabicFontLight, 'التاريخ',
                        DateFormat('dd/MM/yyyy').format(invoice.invoiceDate)),
                    _buildVerticalDivider(),
                    _buildInfoColumn(arabicFontBold, arabicFontLight, 'الوقت',
                        DateFormat('HH:mm').format(invoice.invoiceDate)),
                    _buildVerticalDivider(),
                    _buildInfoColumn(
                        arabicFontBold,
                        arabicFontLight,
                        'طريقة الدفع',
                        _getPaymentMethodLabel(invoice.paymentMethod)),
                  ],
                ),
              ),
              pw.SizedBox(height: 28),

              // ITEMS TABLE
              pw.Container(
                decoration: pw.BoxDecoration(
                  borderRadius: pw.BorderRadius.circular(10),
                  border: pw.Border.all(color: PdfColors.grey300),
                ),
                child: pw.Column(
                  children: [
                    pw.Container(
                      width: double.infinity,
                      padding: const pw.EdgeInsets.symmetric(
                          horizontal: 16, vertical: 10),
                      decoration: const pw.BoxDecoration(
                        color: PdfColors.grey200,
                        borderRadius: pw.BorderRadius.only(
                          topLeft: pw.Radius.circular(9),
                          topRight: pw.Radius.circular(9),
                        ),
                      ),
                      child: pw.Text(
                        'تفاصيل المنتجات',
                        style: pw.TextStyle(
                          font: arabicFontBold,
                          fontSize: 12,
                          color: PdfColors.grey800,
                        ),
                      ),
                    ),
                    pw.Container(
                      padding: const pw.EdgeInsets.symmetric(
                          horizontal: 12, vertical: 12),
                      decoration:
                          const pw.BoxDecoration(color: PdfColors.blue900),
                      child: pw.Row(
                        children: [
                          pw.Expanded(
                            flex: 1,
                            child: pw.Text('#',
                                style: pw.TextStyle(
                                    font: arabicFontBold,
                                    fontSize: 11,
                                    color: PdfColors.white),
                                textAlign: pw.TextAlign.center),
                          ),
                          pw.Expanded(
                            flex: 5,
                            child: pw.Text('اسم المنتج',
                                style: pw.TextStyle(
                                    font: arabicFontBold,
                                    fontSize: 11,
                                    color: PdfColors.white)),
                          ),
                          pw.Expanded(
                            flex: 2,
                            child: pw.Text('الكمية',
                                style: pw.TextStyle(
                                    font: arabicFontBold,
                                    fontSize: 11,
                                    color: PdfColors.white),
                                textAlign: pw.TextAlign.center),
                          ),
                          pw.Expanded(
                            flex: 2,
                            child: pw.Text('السعر',
                                style: pw.TextStyle(
                                    font: arabicFontBold,
                                    fontSize: 11,
                                    color: PdfColors.white),
                                textAlign: pw.TextAlign.center),
                          ),
                          pw.Expanded(
                            flex: 2,
                            child: pw.Text('الإجمالي',
                                style: pw.TextStyle(
                                    font: arabicFontBold,
                                    fontSize: 11,
                                    color: PdfColors.white),
                                textAlign: pw.TextAlign.center),
                          ),
                        ],
                      ),
                    ),
                    ...items.asMap().entries.map((entry) {
                      final index = entry.key;
                      final item = entry.value;
                      final isEven = index % 2 == 0;
                      final isLast = index == items.length - 1;

                      return pw.Container(
                        padding: const pw.EdgeInsets.symmetric(
                            horizontal: 12, vertical: 10),
                        decoration: pw.BoxDecoration(
                          color: isEven ? PdfColors.white : PdfColors.grey50,
                          borderRadius: isLast
                              ? const pw.BorderRadius.only(
                                  bottomLeft: pw.Radius.circular(9),
                                  bottomRight: pw.Radius.circular(9),
                                )
                              : null,
                        ),
                        child: pw.Row(
                          children: [
                            pw.Expanded(
                              flex: 1,
                              child: pw.Container(
                                padding: const pw.EdgeInsets.all(4),
                                decoration: pw.BoxDecoration(
                                  color: PdfColors.blue100,
                                  borderRadius: pw.BorderRadius.circular(4),
                                ),
                                child: pw.Text('${index + 1}',
                                    style: pw.TextStyle(
                                        font: arabicFontBold,
                                        fontSize: 9,
                                        color: PdfColors.blue900),
                                    textAlign: pw.TextAlign.center),
                              ),
                            ),
                            pw.SizedBox(width: 8),
                            pw.Expanded(
                              flex: 5,
                              child: pw.Text(item.productName,
                                  style: pw.TextStyle(
                                      font: arabicFont, fontSize: 10)),
                            ),
                            pw.Expanded(
                              flex: 2,
                              child: pw.Text('${item.quantity}',
                                  style: pw.TextStyle(
                                      font: arabicFontBold, fontSize: 10),
                                  textAlign: pw.TextAlign.center),
                            ),
                            pw.Expanded(
                              flex: 2,
                              child: pw.Text(
                                  '${item.unitPrice.toStringAsFixed(0)}',
                                  style: pw.TextStyle(
                                      font: arabicFont, fontSize: 10),
                                  textAlign: pw.TextAlign.center),
                            ),
                            pw.Expanded(
                              flex: 2,
                              child: pw.Text('${item.total.toStringAsFixed(0)}',
                                  style: pw.TextStyle(
                                      font: arabicFontBold,
                                      fontSize: 10,
                                      color: PdfColors.blue900),
                                  textAlign: pw.TextAlign.center),
                            ),
                          ],
                        ),
                      );
                    }),
                  ],
                ),
              ),
              pw.SizedBox(height: 24),

              // TOTALS
              pw.Row(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Expanded(flex: 3, child: pw.SizedBox()),
                  pw.Expanded(
                    flex: 2,
                    child: pw.Container(
                      padding: const pw.EdgeInsets.all(16),
                      decoration: pw.BoxDecoration(
                        color: PdfColors.grey50,
                        borderRadius: pw.BorderRadius.circular(10),
                        border: pw.Border.all(color: PdfColors.grey300),
                      ),
                      child: pw.Column(
                        children: [
                          _buildSummaryRow(arabicFont, 'المجموع الفرعي',
                              '${invoice.subtotal.toStringAsFixed(0)} ل.س'),
                          pw.SizedBox(height: 8),
                          if (invoice.discountAmount > 0) ...[
                            _buildSummaryRow(arabicFont, 'الخصم',
                                '- ${invoice.discountAmount.toStringAsFixed(0)} ل.س',
                                valueColor: PdfColors.red700),
                            pw.SizedBox(height: 8),
                          ],
                          pw.Container(height: 1, color: PdfColors.grey400),
                          pw.SizedBox(height: 12),
                          pw.Row(
                            mainAxisAlignment:
                                pw.MainAxisAlignment.spaceBetween,
                            children: [
                              pw.Text('الإجمالي',
                                  style: pw.TextStyle(
                                      font: arabicFontBold, fontSize: 14)),
                              pw.Container(
                                padding: const pw.EdgeInsets.symmetric(
                                    horizontal: 16, vertical: 8),
                                decoration: pw.BoxDecoration(
                                  color: PdfColors.blue900,
                                  borderRadius: pw.BorderRadius.circular(6),
                                ),
                                child: pw.Text(
                                    '${invoice.total.toStringAsFixed(0)} ل.س',
                                    style: pw.TextStyle(
                                        font: arabicFontBold,
                                        fontSize: 14,
                                        color: PdfColors.white)),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              pw.Spacer(),

              // FOOTER
              pw.Container(
                padding: const pw.EdgeInsets.only(top: 20),
                decoration: const pw.BoxDecoration(
                  border: pw.Border(
                      top: pw.BorderSide(color: PdfColors.grey300, width: 2)),
                ),
                child: pw.Column(
                  children: [
                    pw.Container(
                      padding: const pw.EdgeInsets.symmetric(
                          horizontal: 24, vertical: 10),
                      decoration: pw.BoxDecoration(
                        color: PdfColors.blue50,
                        borderRadius: pw.BorderRadius.circular(20),
                      ),
                      child: pw.Text(
                        'شكراً لتعاملكم معنا',
                        style: pw.TextStyle(
                            font: arabicFontBold,
                            fontSize: 14,
                            color: PdfColors.blue900),
                      ),
                    ),
                    pw.SizedBox(height: 12),
                    pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.center,
                      children: [
                        pw.Text('تم الإنشاء بواسطة ',
                            style: pw.TextStyle(
                                font: arabicFontLight,
                                fontSize: 8,
                                color: PdfColors.grey500)),
                        pw.Text('Hoor Manager',
                            style: pw.TextStyle(
                                font: arabicFontBold,
                                fontSize: 8,
                                color: PdfColors.blue700)),
                        pw.Text(' | ',
                            style: pw.TextStyle(
                                font: arabicFontLight,
                                fontSize: 8,
                                color: PdfColors.grey400)),
                        pw.Text(
                            DateFormat('dd/MM/yyyy HH:mm')
                                .format(DateTime.now()),
                            style: pw.TextStyle(
                                font: arabicFontLight,
                                fontSize: 8,
                                color: PdfColors.grey500)),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );

    await Printing.layoutPdf(onLayout: (format) => doc.save());
  }

  // دوال مساعدة للـ PDF
  pw.Widget _buildInfoColumn(
      pw.Font boldFont, pw.Font lightFont, String label, String value) {
    return pw.Column(
      children: [
        pw.Text(label,
            style: pw.TextStyle(
                font: lightFont, fontSize: 9, color: PdfColors.grey600)),
        pw.SizedBox(height: 4),
        pw.Text(value,
            style: pw.TextStyle(
                font: boldFont, fontSize: 11, color: PdfColors.grey900)),
      ],
    );
  }

  pw.Widget _buildVerticalDivider() {
    return pw.Container(width: 1, height: 35, color: PdfColors.grey300);
  }

  pw.Widget _buildSummaryRow(pw.Font font, String label, String value,
      {PdfColor? valueColor}) {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        pw.Text(label,
            style: pw.TextStyle(
                font: font, fontSize: 10, color: PdfColors.grey700)),
        pw.Text(value,
            style: pw.TextStyle(
                font: font,
                fontSize: 10,
                color: valueColor ?? PdfColors.grey900)),
      ],
    );
  }

  PdfColor _getTypeColorForPrint(String type) {
    switch (type) {
      case 'sale':
        return PdfColors.green700;
      case 'purchase':
        return PdfColors.blue700;
      case 'sale_return':
        return PdfColors.orange700;
      case 'purchase_return':
        return PdfColors.purple700;
      default:
        return PdfColors.grey700;
    }
  }

  String _getPaymentMethodLabel(String method) {
    switch (method) {
      case 'cash':
        return 'نقداً';
      case 'card':
        return 'بطاقة';
      case 'credit':
        return 'آجل';
      default:
        return method;
    }
  }

  String _getTypeLabelForPrint(String type) {
    switch (type) {
      case 'sale':
        return 'فاتورة مبيعات';
      case 'purchase':
        return 'فاتورة مشتريات';
      case 'sale_return':
        return 'مرتجع مبيعات';
      case 'purchase_return':
        return 'مرتجع مشتريات';
      default:
        return 'فاتورة';
    }
  }
}

class _InvoiceItemCard extends StatefulWidget {
  final Map<String, dynamic> item;
  final bool isPurchase;
  final bool isSale;
  final Function(int) onQuantityChanged;
  final Function(double) onPriceChanged;
  final VoidCallback onRemove;

  const _InvoiceItemCard({
    required this.item,
    required this.isPurchase,
    this.isSale = false,
    required this.onQuantityChanged,
    required this.onPriceChanged,
    required this.onRemove,
  });

  @override
  State<_InvoiceItemCard> createState() => _InvoiceItemCardState();
}

class _InvoiceItemCardState extends State<_InvoiceItemCard> {
  late TextEditingController _priceController;

  @override
  void initState() {
    super.initState();
    final unitPrice = widget.item['unitPrice'] as double;
    _priceController =
        TextEditingController(text: _formatSyrianPrice(unitPrice));
  }

  @override
  void didUpdateWidget(_InvoiceItemCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    final newPrice = widget.item['unitPrice'] as double;
    final oldPrice = oldWidget.item['unitPrice'] as double;
    if (newPrice != oldPrice) {
      _priceController.text = _formatSyrianPrice(newPrice);
    }
  }

  @override
  void dispose() {
    _priceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final quantity = widget.item['quantity'] as int;
    final unitPrice = widget.item['unitPrice'] as double;
    final total = quantity * unitPrice;
    final availableStock = widget.item['availableStock'] as int? ?? 999;

    return Card(
      margin: EdgeInsets.only(bottom: 8.h),
      child: Padding(
        padding: EdgeInsets.all(12.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header Row - Product name and delete
            Row(
              children: [
                Expanded(
                  child: Text(
                    widget.item['productName'] as String,
                    style: TextStyle(
                      fontSize: 14.sp,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (widget.isSale)
                  Container(
                    padding:
                        EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
                    decoration: BoxDecoration(
                      color: quantity >= availableStock
                          ? AppColors.error.withOpacity(0.1)
                          : AppColors.success.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(4.r),
                    ),
                    child: Text(
                      'متاح: $availableStock',
                      style: TextStyle(
                        fontSize: 10.sp,
                        color: quantity >= availableStock
                            ? AppColors.error
                            : AppColors.success,
                      ),
                    ),
                  ),
                IconButton(
                  icon: const Icon(Icons.close, size: 20),
                  color: AppColors.error,
                  onPressed: widget.onRemove,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
            Gap(8.h),
            // Controls Row
            Row(
              children: [
                // Quantity Control
                Container(
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade300),
                    borderRadius: BorderRadius.circular(8.r),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      InkWell(
                        onTap: quantity > 1
                            ? () => widget.onQuantityChanged(quantity - 1)
                            : null,
                        child: Container(
                          padding: EdgeInsets.all(6.w),
                          child: Icon(
                            Icons.remove,
                            size: 18.sp,
                            color:
                                quantity > 1 ? AppColors.primary : Colors.grey,
                          ),
                        ),
                      ),
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 12.w),
                        child: Text(
                          '$quantity',
                          style: TextStyle(
                            fontSize: 14.sp,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      InkWell(
                        onTap: () => widget.onQuantityChanged(quantity + 1),
                        child: Container(
                          padding: EdgeInsets.all(6.w),
                          child: Icon(
                            Icons.add,
                            size: 18.sp,
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Gap(8.w),
                // Price Input
                Expanded(
                  child: SizedBox(
                    height: 36.h,
                    child: TextField(
                      controller: _priceController,
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 13.sp),
                      decoration: InputDecoration(
                        contentPadding:
                            EdgeInsets.symmetric(horizontal: 8.w, vertical: 0),
                        suffixText: 'ل.س',
                        suffixStyle: TextStyle(fontSize: 11.sp),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8.r),
                        ),
                      ),
                      onChanged: (value) {
                        final price = double.tryParse(value);
                        if (price != null) widget.onPriceChanged(price);
                      },
                    ),
                  ),
                ),
                Gap(8.w),
                // Total
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'الإجمالي',
                      style: TextStyle(
                        fontSize: 10.sp,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    Text(
                      '${_formatSyrianPrice(total)} ل.س',
                      style: TextStyle(
                        fontSize: 13.sp,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
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
