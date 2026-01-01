/// ═══════════════════════════════════════════════════════════════════════════
/// Invoice Form Screen - Redesigned
/// Modern Invoice Creation/Edit Form
/// ═══════════════════════════════════════════════════════════════════════════
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../../../../core/di/injection.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/services/currency_service.dart';
import '../../../../data/database/app_database.dart';
import '../../../../data/repositories/product_repository.dart';
import '../../../../data/repositories/invoice_repository.dart';
import '../../../../data/repositories/shift_repository.dart';
import '../../../../data/repositories/customer_repository.dart';
import '../../../../data/repositories/supplier_repository.dart';

class InvoiceFormScreenRedesign extends ConsumerStatefulWidget {
  final String type;
  final String? invoiceId;

  const InvoiceFormScreenRedesign({
    super.key,
    required this.type,
    this.invoiceId,
  });

  bool get isEditMode => invoiceId != null;

  @override
  ConsumerState<InvoiceFormScreenRedesign> createState() =>
      _InvoiceFormScreenRedesignState();
}

class _InvoiceFormScreenRedesignState
    extends ConsumerState<InvoiceFormScreenRedesign> {
  final _productRepo = getIt<ProductRepository>();
  final _invoiceRepo = getIt<InvoiceRepository>();
  final _shiftRepo = getIt<ShiftRepository>();
  final _customerRepo = getIt<CustomerRepository>();
  final _supplierRepo = getIt<SupplierRepository>();
  final _currencyService = getIt<CurrencyService>();

  final _searchController = TextEditingController();
  final _discountController = TextEditingController(text: '0');
  final _paidAmountController = TextEditingController();
  final _notesController = TextEditingController();

  final List<Map<String, dynamic>> _items = [];
  final Map<String, int> _productStock = {};
  String _paymentMethod = 'cash';
  bool _isLoading = false;
  bool _isLoadingInvoice = false;
  Shift? _currentShift;

  Customer? _selectedCustomer;
  Supplier? _selectedSupplier;
  List<Customer> _customers = [];
  List<Supplier> _suppliers = [];

  @override
  void initState() {
    super.initState();
    _loadCurrentShift();
    _loadCustomersAndSuppliers();
    if (widget.isEditMode) {
      _loadExistingInvoice();
    }
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

  Future<void> _loadExistingInvoice() async {
    setState(() => _isLoadingInvoice = true);
    try {
      final invoice = await _invoiceRepo.getInvoiceById(widget.invoiceId!);
      if (invoice == null) {
        if (mounted) {
          _showErrorSnackBar('الفاتورة غير موجودة');
          context.pop();
        }
        return;
      }

      final items = await _invoiceRepo.getInvoiceItems(widget.invoiceId!);

      for (final item in items) {
        final product = await _productRepo.getProductById(item.productId);
        _productStock[item.productId] = product?.quantity ?? 0;
        _items.add({
          'productId': item.productId,
          'productName': item.productName,
          'quantity': item.quantity,
          'unitPrice': item.unitPrice,
          'purchasePrice': item.purchasePrice,
          'salePrice': product?.salePrice ?? item.unitPrice,
          'availableStock': (product?.quantity ?? 0) + item.quantity,
        });
      }

      if (invoice.customerId != null) {
        _selectedCustomer =
            await _customerRepo.getCustomerById(invoice.customerId!);
      }
      if (invoice.supplierId != null) {
        _selectedSupplier =
            await _supplierRepo.getSupplierById(invoice.supplierId!);
      }

      _discountController.text = invoice.discountAmount.toStringAsFixed(0);
      _paymentMethod = invoice.paymentMethod;
      _paidAmountController.text = invoice.paidAmount.toStringAsFixed(0);
      _notesController.text = invoice.notes ?? '';

      setState(() => _isLoadingInvoice = false);
    } catch (e) {
      setState(() => _isLoadingInvoice = false);
      if (mounted) _showErrorSnackBar('خطأ في تحميل الفاتورة: $e');
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _discountController.dispose();
    _paidAmountController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  String get _typeTitle {
    switch (widget.type) {
      case 'sale':
        return widget.isEditMode ? 'تعديل فاتورة مبيعات' : 'فاتورة مبيعات';
      case 'purchase':
        return widget.isEditMode ? 'تعديل فاتورة مشتريات' : 'فاتورة مشتريات';
      case 'sale_return':
        return widget.isEditMode ? 'تعديل مرتجع مبيعات' : 'مرتجع مبيعات';
      case 'purchase_return':
        return widget.isEditMode ? 'تعديل مرتجع مشتريات' : 'مرتجع مشتريات';
      default:
        return widget.isEditMode ? 'تعديل فاتورة' : 'فاتورة جديدة';
    }
  }

  Color get _typeColor {
    switch (widget.type) {
      case 'sale':
        return HoorColors.success;
      case 'purchase':
        return HoorColors.warning;
      case 'sale_return':
      case 'purchase_return':
        return HoorColors.error;
      default:
        return HoorColors.primary;
    }
  }

  IconData get _typeIcon {
    switch (widget.type) {
      case 'sale':
        return Icons.point_of_sale_rounded;
      case 'purchase':
        return Icons.shopping_cart_rounded;
      case 'sale_return':
      case 'purchase_return':
        return Icons.assignment_return_rounded;
      default:
        return Icons.receipt_long_rounded;
    }
  }

  double get _subtotal => _items.fold(
      0,
      (sum, item) =>
          sum + (item['quantity'] as int) * (item['unitPrice'] as double));

  double get _discount => double.tryParse(_discountController.text) ?? 0;

  double get _total => _subtotal - _discount;

  double get _paidAmount {
    if (_paymentMethod == 'credit' || _paymentMethod == 'partial') {
      return double.tryParse(_paidAmountController.text) ?? 0;
    }
    return _total;
  }

  double get _remainingAmount => _total - _paidAmount;

  @override
  Widget build(BuildContext context) {
    if (_isLoadingInvoice) {
      return Scaffold(
        backgroundColor: HoorColors.background,
        appBar: _buildAppBar(),
        body: const Center(
            child: CircularProgressIndicator(color: HoorColors.primary)),
      );
    }

    return Scaffold(
      backgroundColor: HoorColors.background,
      appBar: _buildAppBar(),
      body: Column(
        children: [
          // Shift Warning
          if (!widget.isEditMode && _currentShift == null) _buildShiftWarning(),

          // Search Bar
          _buildSearchBar(),

          // Items List
          Expanded(
            child: _items.isEmpty ? _buildEmptyState() : _buildItemsList(),
          ),

          // Summary & Actions
          _buildBottomPanel(),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: HoorColors.surface,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
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
      title: Row(
        children: [
          Container(
            padding: EdgeInsets.all(HoorSpacing.xs.w),
            decoration: BoxDecoration(
              color: _typeColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(HoorRadius.sm),
            ),
            child: Icon(_typeIcon, color: _typeColor, size: 20),
          ),
          SizedBox(width: HoorSpacing.sm.w),
          Text(_typeTitle, style: HoorTypography.headlineSmall),
        ],
      ),
      actions: [
        if (_items.isNotEmpty)
          IconButton(
            icon: const Icon(Icons.delete_sweep_rounded),
            onPressed: _clearAllItems,
            tooltip: 'مسح الكل',
          ),
        SizedBox(width: HoorSpacing.xs.w),
      ],
    );
  }

  Widget _buildShiftWarning() {
    return Container(
      margin: EdgeInsets.all(HoorSpacing.md.w),
      padding: EdgeInsets.all(HoorSpacing.sm.w),
      decoration: BoxDecoration(
        color: HoorColors.warning.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(HoorRadius.md),
        border: Border.all(color: HoorColors.warning.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(Icons.warning_rounded, color: HoorColors.warning, size: 20),
          SizedBox(width: HoorSpacing.sm.w),
          Expanded(
            child: Text(
              'لا توجد وردية مفتوحة - يجب فتح وردية لحفظ الفاتورة',
              style: HoorTypography.bodySmall.copyWith(
                color: HoorColors.warning,
              ),
            ),
          ),
          TextButton(
            onPressed: () => context.push('/shifts'),
            child: const Text('فتح وردية'),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      padding: EdgeInsets.all(HoorSpacing.md.w),
      decoration: BoxDecoration(
        color: HoorColors.surface,
        border: Border(bottom: BorderSide(color: HoorColors.border)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: HoorColors.background,
                borderRadius: BorderRadius.circular(HoorRadius.md),
              ),
              child: TextField(
                controller: _searchController,
                style: HoorTypography.bodyMedium,
                decoration: InputDecoration(
                  hintText: 'بحث بالاسم أو الباركود...',
                  prefixIcon: const Icon(Icons.search_rounded, size: 20),
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.qr_code_scanner_rounded),
                    onPressed: _scanBarcode,
                  ),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: HoorSpacing.md.w,
                    vertical: HoorSpacing.sm.h,
                  ),
                ),
                onSubmitted: _searchProduct,
              ),
            ),
          ),
          SizedBox(width: HoorSpacing.sm.w),
          Container(
            decoration: BoxDecoration(
              color: HoorColors.primary,
              borderRadius: BorderRadius.circular(HoorRadius.md),
            ),
            child: IconButton(
              icon: const Icon(Icons.add_rounded, color: Colors.white),
              onPressed: _showProductsDialog,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: EdgeInsets.all(HoorSpacing.xl.w),
            decoration: BoxDecoration(
              color: HoorColors.surface,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.shopping_basket_outlined,
              size: 64,
              color: HoorColors.textSecondary,
            ),
          ),
          SizedBox(height: HoorSpacing.md.h),
          Text(
            'أضف منتجات إلى الفاتورة',
            style: HoorTypography.titleMedium.copyWith(
              color: HoorColors.textSecondary,
            ),
          ),
          SizedBox(height: HoorSpacing.xs.h),
          Text(
            'ابحث عن المنتجات أو امسح الباركود',
            style: HoorTypography.bodySmall.copyWith(
              color: HoorColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildItemsList() {
    return ListView.builder(
      padding: EdgeInsets.all(HoorSpacing.md.w),
      itemCount: _items.length,
      itemBuilder: (context, index) {
        final item = _items[index];
        return _buildItemCard(item, index);
      },
    );
  }

  Widget _buildItemCard(Map<String, dynamic> item, int index) {
    final isSale = widget.type == 'sale' || widget.type == 'purchase_return';
    final availableStock = item['availableStock'] as int? ??
        _productStock[item['productId']] ??
        999;

    return Container(
      margin: EdgeInsets.only(bottom: HoorSpacing.sm.h),
      padding: EdgeInsets.all(HoorSpacing.sm.w),
      decoration: BoxDecoration(
        color: HoorColors.surface,
        borderRadius: BorderRadius.circular(HoorRadius.md),
        border: Border.all(color: HoorColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40.w,
                height: 40.w,
                decoration: BoxDecoration(
                  color: _typeColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(HoorRadius.sm),
                ),
                child: Center(
                  child: Text(
                    '${index + 1}',
                    style: HoorTypography.titleMedium.copyWith(
                      color: _typeColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              SizedBox(width: HoorSpacing.sm.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item['productName'] as String,
                      style: HoorTypography.titleSmall.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (isSale)
                      Text(
                        'المتاح: $availableStock',
                        style: HoorTypography.labelSmall.copyWith(
                          color: HoorColors.textSecondary,
                        ),
                      ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.delete_outline_rounded,
                    color: HoorColors.error, size: 20),
                onPressed: () => setState(() => _items.removeAt(index)),
              ),
            ],
          ),
          SizedBox(height: HoorSpacing.sm.h),
          Row(
            children: [
              // Quantity
              Expanded(
                child: Row(
                  children: [
                    _buildQuantityButton(
                      icon: Icons.remove_rounded,
                      onPressed: () {
                        if (item['quantity'] > 1) {
                          setState(() => item['quantity']--);
                        }
                      },
                    ),
                    SizedBox(width: HoorSpacing.xs.w),
                    Expanded(
                      child: Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: HoorSpacing.sm.w,
                          vertical: HoorSpacing.xs.h,
                        ),
                        decoration: BoxDecoration(
                          color: HoorColors.background,
                          borderRadius: BorderRadius.circular(HoorRadius.sm),
                        ),
                        child: Text(
                          '${item['quantity']}',
                          style: HoorTypography.titleMedium.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                    SizedBox(width: HoorSpacing.xs.w),
                    _buildQuantityButton(
                      icon: Icons.add_rounded,
                      onPressed: () {
                        if (!isSale || item['quantity'] < availableStock) {
                          setState(() => item['quantity']++);
                        } else {
                          _showWarningSnackBar('لا يمكن تجاوز الكمية المتاحة');
                        }
                      },
                    ),
                  ],
                ),
              ),
              SizedBox(width: HoorSpacing.md.w),
              // Price & Total
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '${(item['unitPrice'] as double).toStringAsFixed(0)} ل.س',
                    style: HoorTypography.bodySmall.copyWith(
                      color: HoorColors.textSecondary,
                    ),
                  ),
                  Text(
                    '${((item['quantity'] as int) * (item['unitPrice'] as double)).toStringAsFixed(0)} ل.س',
                    style: HoorTypography.titleMedium.copyWith(
                      color: _typeColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuantityButton({
    required IconData icon,
    required VoidCallback onPressed,
  }) {
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(HoorRadius.sm),
      child: Container(
        width: 36.w,
        height: 36.w,
        decoration: BoxDecoration(
          color: HoorColors.primary.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(HoorRadius.sm),
        ),
        child: Icon(icon, color: HoorColors.primary, size: 20),
      ),
    );
  }

  Widget _buildBottomPanel() {
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
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Customer/Supplier Selection
            if (widget.type == 'sale' || widget.type == 'sale_return')
              _buildCustomerSelector(),
            if (widget.type == 'purchase' || widget.type == 'purchase_return')
              _buildSupplierSelector(),

            SizedBox(height: HoorSpacing.sm.h),

            // Discount & Payment Row
            Row(
              children: [
                Expanded(
                  child: _buildCompactTextField(
                    controller: _discountController,
                    label: 'الخصم',
                    icon: Icons.discount_rounded,
                    suffix: 'ل.س',
                    onChanged: (_) => setState(() {}),
                  ),
                ),
                SizedBox(width: HoorSpacing.sm.w),
                Expanded(
                  child: _buildPaymentDropdown(),
                ),
              ],
            ),

            if (_paymentMethod == 'partial') ...[
              SizedBox(height: HoorSpacing.sm.h),
              _buildCompactTextField(
                controller: _paidAmountController,
                label: 'المبلغ المدفوع',
                icon: Icons.attach_money_rounded,
                suffix: 'ل.س',
                onChanged: (value) {
                  final paid = double.tryParse(value) ?? 0;
                  if (paid > _total) {
                    _paidAmountController.text = _total.toStringAsFixed(0);
                  }
                  setState(() {});
                },
              ),
            ],

            SizedBox(height: HoorSpacing.md.h),

            // Totals Summary
            _buildTotalsSummary(),

            SizedBox(height: HoorSpacing.md.h),

            // Submit Button
            SizedBox(
              width: double.infinity,
              height: 50.h,
              child: ElevatedButton(
                onPressed: _items.isEmpty || _isLoading ? null : _submitInvoice,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _typeColor,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(HoorRadius.md),
                  ),
                  elevation: 0,
                ),
                child: _isLoading
                    ? const SizedBox(
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
                            widget.isEditMode
                                ? Icons.check_rounded
                                : Icons.save_rounded,
                            size: 20,
                          ),
                          SizedBox(width: HoorSpacing.xs.w),
                          Text(
                            widget.isEditMode
                                ? 'تحديث الفاتورة'
                                : 'حفظ الفاتورة',
                            style: HoorTypography.titleMedium.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCustomerSelector() {
    return DropdownButtonFormField<Customer?>(
      initialValue: _selectedCustomer,
      decoration: InputDecoration(
        labelText: 'العميل (اختياري)',
        prefixIcon: const Icon(Icons.person_rounded, size: 20),
        isDense: true,
        filled: true,
        fillColor: HoorColors.background,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(HoorRadius.sm),
          borderSide: BorderSide.none,
        ),
        contentPadding: EdgeInsets.symmetric(
          horizontal: HoorSpacing.sm.w,
          vertical: HoorSpacing.xs.h,
        ),
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
      onChanged: (value) => setState(() => _selectedCustomer = value),
    );
  }

  Widget _buildSupplierSelector() {
    return DropdownButtonFormField<Supplier?>(
      initialValue: _selectedSupplier,
      decoration: InputDecoration(
        labelText: 'المورد (اختياري)',
        prefixIcon: const Icon(Icons.business_rounded, size: 20),
        isDense: true,
        filled: true,
        fillColor: HoorColors.background,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(HoorRadius.sm),
          borderSide: BorderSide.none,
        ),
        contentPadding: EdgeInsets.symmetric(
          horizontal: HoorSpacing.sm.w,
          vertical: HoorSpacing.xs.h,
        ),
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
      onChanged: (value) => setState(() => _selectedSupplier = value),
    );
  }

  Widget _buildCompactTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    String? suffix,
    void Function(String)? onChanged,
  }) {
    return TextField(
      controller: controller,
      keyboardType: TextInputType.number,
      style: HoorTypography.bodySmall,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, size: 18),
        suffixText: suffix,
        isDense: true,
        filled: true,
        fillColor: HoorColors.background,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(HoorRadius.sm),
          borderSide: BorderSide.none,
        ),
        contentPadding: EdgeInsets.symmetric(
          horizontal: HoorSpacing.sm.w,
          vertical: HoorSpacing.xs.h,
        ),
      ),
      onChanged: onChanged,
    );
  }

  Widget _buildPaymentDropdown() {
    return DropdownButtonFormField<String>(
      initialValue: _paymentMethod,
      decoration: InputDecoration(
        labelText: 'طريقة الدفع',
        prefixIcon: const Icon(Icons.payment_rounded, size: 18),
        isDense: true,
        filled: true,
        fillColor: HoorColors.background,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(HoorRadius.sm),
          borderSide: BorderSide.none,
        ),
        contentPadding: EdgeInsets.symmetric(
          horizontal: HoorSpacing.sm.w,
          vertical: HoorSpacing.xs.h,
        ),
      ),
      items: PaymentMethod.values
          .map((p) => DropdownMenuItem(
                value: p.value,
                child: Text(p.label, style: HoorTypography.bodySmall),
              ))
          .toList(),
      onChanged: (value) {
        setState(() {
          _paymentMethod = value!;
          if (value == 'partial') {
            _paidAmountController.text = '';
          } else {
            _paidAmountController.text = _total.toStringAsFixed(0);
          }
        });
      },
    );
  }

  Widget _buildTotalsSummary() {
    return Container(
      padding: EdgeInsets.all(HoorSpacing.sm.w),
      decoration: BoxDecoration(
        color: _typeColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(HoorRadius.md),
      ),
      child: Column(
        children: [
          if (_discount > 0)
            _buildSummaryRow(
              'الخصم',
              '-${_discount.toStringAsFixed(0)} ل.س',
              color: HoorColors.error,
            ),
          _buildSummaryRow(
            'الإجمالي',
            '${_total.toStringAsFixed(0)} ل.س',
            isBold: true,
            fontSize: 18.sp,
          ),
          _buildSummaryRow(
            '',
            '\$${_currencyService.sypToUsd(_total).toStringAsFixed(2)}',
            color: HoorColors.success,
            fontSize: 12.sp,
          ),
          if (_paymentMethod == 'partial') ...[
            Divider(color: _typeColor.withValues(alpha: 0.3)),
            _buildSummaryRow(
              'المدفوع',
              '${_paidAmount.toStringAsFixed(0)} ل.س',
              color: HoorColors.success,
            ),
            _buildSummaryRow(
              'المتبقي',
              '${_remainingAmount.toStringAsFixed(0)} ل.س',
              color: _remainingAmount > 0
                  ? HoorColors.warning
                  : HoorColors.success,
              isBold: true,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSummaryRow(
    String label,
    String value, {
    Color? color,
    bool isBold = false,
    double? fontSize,
  }) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 2.h),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: HoorTypography.bodySmall.copyWith(
              color: color ?? HoorColors.textPrimary,
            ),
          ),
          Text(
            value,
            style: (isBold
                    ? HoorTypography.titleMedium
                    : HoorTypography.bodyMedium)
                .copyWith(
              color: color ?? _typeColor,
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
              fontSize: fontSize,
            ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // Actions
  // ═══════════════════════════════════════════════════════════════════════════

  Future<void> _scanBarcode() async {
    final barcode = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const _BarcodeScannerSheet(),
    );

    if (barcode != null) {
      final product = await _productRepo.getProductByBarcode(barcode);
      if (product != null) {
        _addProduct(product);
      } else {
        _showErrorSnackBar('المنتج غير موجود');
      }
    }
  }

  Future<void> _searchProduct(String query) async {
    if (query.isEmpty) return;

    var product = await _productRepo.getProductByBarcode(query);
    if (product == null) {
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

    final selected = await showModalBottomSheet<Product>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _ProductSelectionSheet(
        products: filtered,
        typeColor: _typeColor,
      ),
    );

    if (selected != null) {
      _addProduct(selected);
    }
  }

  void _addProduct(Product product) {
    final isSale = widget.type == 'sale' || widget.type == 'purchase_return';

    if (isSale && product.quantity <= 0) {
      _showErrorSnackBar('المنتج "${product.name}" غير متوفر في المخزون');
      return;
    }

    final existingIndex =
        _items.indexWhere((i) => i['productId'] == product.id);

    if (existingIndex >= 0) {
      final currentQty = _items[existingIndex]['quantity'] as int;
      final availableStock = _productStock[product.id] ?? product.quantity;

      if (isSale && currentQty >= availableStock) {
        _showWarningSnackBar(
            'لا يمكن إضافة المزيد. الكمية المتاحة: $availableStock');
        return;
      }

      setState(() => _items[existingIndex]['quantity']++);
    } else {
      _productStock[product.id] = product.quantity;
      final isPurchase = widget.type == 'purchase';

      setState(() {
        _items.add({
          'productId': product.id,
          'productName': product.name,
          'quantity': 1,
          'unitPrice': isPurchase ? product.purchasePrice : product.salePrice,
          'purchasePrice': product.purchasePrice,
          'salePrice': product.salePrice,
          'availableStock': product.quantity,
        });
      });
    }
  }

  void _clearAllItems() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(HoorRadius.lg),
        ),
        title: const Text('مسح الكل'),
        content: const Text('هل أنت متأكد من مسح جميع المنتجات؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              setState(() => _items.clear());
            },
            style: ElevatedButton.styleFrom(backgroundColor: HoorColors.error),
            child: const Text('مسح'),
          ),
        ],
      ),
    );
  }

  Future<void> _submitInvoice() async {
    if (_items.isEmpty) return;

    if (!widget.isEditMode && _currentShift == null) {
      _showErrorSnackBar('يجب فتح وردية أولاً');
      return;
    }

    setState(() => _isLoading = true);

    try {
      String invoiceId;

      if (widget.isEditMode) {
        await _invoiceRepo.updateInvoice(
          invoiceId: widget.invoiceId!,
          items: _items,
          discountAmount: _discount,
          paymentMethod: _paymentMethod,
          paidAmount: _paidAmount,
          notes: _notesController.text.isEmpty ? null : _notesController.text,
          customerId: _selectedCustomer?.id,
          supplierId: _selectedSupplier?.id,
        );
        invoiceId = widget.invoiceId!;
      } else {
        invoiceId = await _invoiceRepo.createInvoice(
          type: widget.type,
          items: _items,
          discountAmount: _discount,
          paymentMethod: _paymentMethod,
          paidAmount: _paidAmount,
          notes: _notesController.text.isEmpty ? null : _notesController.text,
          customerId: _selectedCustomer?.id,
          supplierId: _selectedSupplier?.id,
          shiftId: _currentShift!.id,
        );
      }

      if (mounted) {
        _showSuccessDialog(invoiceId);
      }
    } catch (e) {
      _showErrorSnackBar('حدث خطأ: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _showSuccessDialog(String invoiceId) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(HoorRadius.xl),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: EdgeInsets.all(HoorSpacing.md.w),
              decoration: BoxDecoration(
                color: HoorColors.success.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.check_circle_rounded,
                color: HoorColors.success,
                size: 48,
              ),
            ),
            SizedBox(height: HoorSpacing.md.h),
            Text(
              widget.isEditMode ? 'تم تحديث الفاتورة' : 'تم حفظ الفاتورة',
              style: HoorTypography.headlineSmall,
            ),
            SizedBox(height: HoorSpacing.xs.h),
            Text(
              'الإجمالي: ${_total.toStringAsFixed(0)} ل.س',
              style: HoorTypography.titleMedium.copyWith(
                color: _typeColor,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              context.pop(true);
            },
            child: const Text('إغلاق'),
          ),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.pop(context);
              context.push('/invoices/details/$invoiceId');
            },
            icon: const Icon(Icons.visibility_rounded, size: 18),
            label: const Text('عرض الفاتورة'),
            style: ElevatedButton.styleFrom(
              backgroundColor: _typeColor,
            ),
          ),
        ],
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: HoorColors.error,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(HoorRadius.sm),
        ),
      ),
    );
  }

  void _showWarningSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: HoorColors.warning,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(HoorRadius.sm),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// Product Selection Sheet
// ═══════════════════════════════════════════════════════════════════════════

class _ProductSelectionSheet extends StatefulWidget {
  final List<Product> products;
  final Color typeColor;

  const _ProductSelectionSheet({
    required this.products,
    required this.typeColor,
  });

  @override
  State<_ProductSelectionSheet> createState() => _ProductSelectionSheetState();
}

class _ProductSelectionSheetState extends State<_ProductSelectionSheet> {
  late List<Product> _filtered;
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _filtered = widget.products;
  }

  void _filter(String query) {
    setState(() {
      if (query.isEmpty) {
        _filtered = widget.products;
      } else {
        _filtered = widget.products
            .where((p) => p.name.toLowerCase().contains(query.toLowerCase()))
            .toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.75,
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
                Text('اختر منتج', style: HoorTypography.headlineSmall),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.close_rounded),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),
          // Search
          Padding(
            padding: EdgeInsets.symmetric(horizontal: HoorSpacing.md.w),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'بحث...',
                prefixIcon: const Icon(Icons.search_rounded),
                filled: true,
                fillColor: HoorColors.background,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(HoorRadius.md),
                  borderSide: BorderSide.none,
                ),
              ),
              onChanged: _filter,
            ),
          ),
          SizedBox(height: HoorSpacing.sm.h),
          // Products List
          Expanded(
            child: ListView.builder(
              padding: EdgeInsets.symmetric(horizontal: HoorSpacing.md.w),
              itemCount: _filtered.length,
              itemBuilder: (context, index) {
                final product = _filtered[index];
                return InkWell(
                  onTap: () => Navigator.pop(context, product),
                  borderRadius: BorderRadius.circular(HoorRadius.md),
                  child: Container(
                    padding: EdgeInsets.all(HoorSpacing.sm.w),
                    margin: EdgeInsets.only(bottom: HoorSpacing.xs.h),
                    decoration: BoxDecoration(
                      color: HoorColors.background,
                      borderRadius: BorderRadius.circular(HoorRadius.md),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 45.w,
                          height: 45.w,
                          decoration: BoxDecoration(
                            color: widget.typeColor.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(HoorRadius.sm),
                          ),
                          child: Icon(
                            Icons.inventory_2_rounded,
                            color: widget.typeColor,
                            size: 24,
                          ),
                        ),
                        SizedBox(width: HoorSpacing.sm.w),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                product.name,
                                style: HoorTypography.titleSmall.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              Text(
                                '${product.salePrice.toStringAsFixed(0)} ل.س',
                                style: HoorTypography.bodySmall.copyWith(
                                  color: HoorColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: HoorSpacing.sm.w,
                            vertical: HoorSpacing.xxs.h,
                          ),
                          decoration: BoxDecoration(
                            color: product.quantity > 0
                                ? HoorColors.success.withValues(alpha: 0.1)
                                : HoorColors.error.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(HoorRadius.sm),
                          ),
                          child: Text(
                            '${product.quantity}',
                            style: HoorTypography.labelMedium.copyWith(
                              color: product.quantity > 0
                                  ? HoorColors.success
                                  : HoorColors.error,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
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
          Container(
            margin: EdgeInsets.symmetric(vertical: HoorSpacing.sm.h),
            width: 40.w,
            height: 4.h,
            decoration: BoxDecoration(
              color: HoorColors.border,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Padding(
            padding: EdgeInsets.all(HoorSpacing.md.w),
            child: Row(
              children: [
                Text('مسح الباركود', style: HoorTypography.headlineSmall),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.close_rounded),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),
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
