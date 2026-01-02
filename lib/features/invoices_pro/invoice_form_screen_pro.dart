// ═══════════════════════════════════════════════════════════════════════════
// Invoice Form Screen Pro
// Create/Edit Invoice with Professional Design
// ═══════════════════════════════════════════════════════════════════════════

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/design_tokens.dart';
import '../../core/providers/app_providers.dart';
import '../../core/widgets/widgets.dart';
import '../../features/invoices_pro/widgets/invoice_success_dialog.dart';
import '../../data/database/app_database.dart';

class InvoiceFormScreenPro extends ConsumerStatefulWidget {
  final String type; // 'sale' or 'purchase'
  final String? invoiceId;
  final Map<String, dynamic>? preSelectedProduct; // المنتج المحدد مسبقاً

  const InvoiceFormScreenPro({
    super.key,
    required this.type,
    this.invoiceId,
    this.preSelectedProduct,
  });

  bool get isEditing => invoiceId != null;
  bool get isSales => type == 'sale';

  @override
  ConsumerState<InvoiceFormScreenPro> createState() =>
      _InvoiceFormScreenProState();
}

class _InvoiceFormScreenProState extends ConsumerState<InvoiceFormScreenPro> {
  String? _selectedCustomerId;
  String? _selectedCustomerName;
  String? _selectedSupplierId;
  String? _selectedSupplierName;
  DateTime _invoiceDate = DateTime.now();
  DateTime? _dueDate;
  String _paymentMethod = 'cash';
  final _discountController = TextEditingController();
  final _notesController = TextEditingController();
  final _paidAmountController = TextEditingController();
  bool _isSaving = false;

  // Items list with real products
  final List<Map<String, dynamic>> _items = [];

  double get _subtotal => _items.fold(
        0.0,
        (sum, item) =>
            sum +
            (item['quantity'] * item['price'] * (1 - item['discount'] / 100)),
      );

  double get _discount => double.tryParse(_discountController.text) ?? 0;
  double get _total => _subtotal - _discount;
  double get _paidAmount => double.tryParse(_paidAmountController.text) ?? 0;
  double get _remainingAmount => _total - _paidAmount;

  @override
  void initState() {
    super.initState();
    // إضافة المنتج المحدد مسبقاً إن وجد
    _addPreSelectedProduct();
  }

  void _addPreSelectedProduct() {
    if (widget.preSelectedProduct != null) {
      final productData = widget.preSelectedProduct!['preSelectedProduct'];
      if (productData != null) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          setState(() {
            _items.add({
              'id': '1',
              'productId': productData['id'],
              'name': productData['name'],
              'quantity': productData['quantity'] ?? 1,
              'price': widget.isSales
                  ? productData['salePrice']
                  : productData['purchasePrice'],
              'purchasePrice': productData['purchasePrice'],
              'discount': 0.0,
              'maxQuantity': productData['availableStock'] ?? 999,
            });
          });
        });
      }
    }
  }

  @override
  void dispose() {
    _discountController.dispose();
    _notesController.dispose();
    _paidAmountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: ProAppBar.close(
        title: widget.isSales
            ? (widget.isEditing ? 'تعديل فاتورة بيع' : 'فاتورة بيع جديدة')
            : (widget.isEditing ? 'تعديل فاتورة شراء' : 'فاتورة شراء جديدة'),
        onClose: () => _showDiscardDialog(),
        actions: [
          ProAppBarAction(
            icon: Icons.visibility_outlined,
            onPressed: () {
              // TODO: Preview invoice
            },
            tooltip: 'معاينة',
          ),
        ],
      ),
      body: Column(
        children: [
          // ═══════════════════════════════════════════════════════════════════
          // Main Content
          // ═══════════════════════════════════════════════════════════════════
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.all(AppSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Customer Selection
                  _buildCustomerSection(),
                  SizedBox(height: AppSpacing.lg),

                  // Invoice Details
                  _buildInvoiceDetails(),
                  SizedBox(height: AppSpacing.lg),

                  // Items Section
                  _buildItemsSection(),
                  SizedBox(height: AppSpacing.lg),

                  // Totals Section
                  _buildTotalsSection(),
                  SizedBox(height: AppSpacing.lg),

                  // Payment Section (للدفع الجزئي)
                  _buildPaymentSection(),
                  SizedBox(height: AppSpacing.lg),

                  // Notes
                  _buildNotesSection(),
                  SizedBox(height: AppSpacing.xxl),
                ],
              ),
            ),
          ),

          // ═══════════════════════════════════════════════════════════════════
          // Bottom Bar
          // ═══════════════════════════════════════════════════════════════════
          _buildBottomBar(),
        ],
      ),
    );
  }

  Widget _buildCustomerSection() {
    return Container(
      padding: EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                widget.isSales ? Icons.person_outline : Icons.business_outlined,
                size: AppIconSize.sm,
                color: AppColors.textTertiary,
              ),
              SizedBox(width: AppSpacing.sm),
              Text(
                widget.isSales ? 'العميل' : 'المورد',
                style: AppTypography.titleSmall.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          SizedBox(height: AppSpacing.md),
          InkWell(
            onTap: () => _selectCustomer(),
            borderRadius: BorderRadius.circular(AppRadius.md),
            child: Container(
              padding: EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(AppRadius.md),
                border: Border.all(color: AppColors.border),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 24.r,
                    backgroundColor: AppColors.secondary.soft,
                    child: (widget.isSales
                                ? _selectedCustomerName
                                : _selectedSupplierName) !=
                            null
                        ? Text(
                            (widget.isSales
                                ? _selectedCustomerName
                                : _selectedSupplierName)![0],
                            style: AppTypography.titleMedium.copyWith(
                              color: AppColors.secondary,
                            ),
                          )
                        : Icon(
                            Icons.add_rounded,
                            color: AppColors.secondary,
                          ),
                  ),
                  SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: (widget.isSales
                                ? _selectedCustomerName
                                : _selectedSupplierName) !=
                            null
                        ? Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                (widget.isSales
                                    ? _selectedCustomerName
                                    : _selectedSupplierName)!,
                                style: AppTypography.titleSmall.copyWith(
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              Text(
                                _getPaymentMethodLabel(_paymentMethod),
                                style: AppTypography.bodySmall.copyWith(
                                  color: AppColors.textTertiary,
                                ),
                              ),
                            ],
                          )
                        : Text(
                            'اختر ${widget.isSales ? "العميل" : "المورد"}',
                            style: AppTypography.bodyMedium.copyWith(
                              color: AppColors.textTertiary,
                            ),
                          ),
                  ),
                  Icon(
                    Icons.chevron_left_rounded,
                    color: AppColors.textTertiary,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _getPaymentMethodLabel(String method) {
    switch (method) {
      case 'cash':
        return 'نقدي';
      case 'credit':
        return 'آجل';
      case 'partial':
        return 'دفع جزئي';
      case 'card':
        return 'بطاقة';
      case 'transfer':
        return 'تحويل';
      default:
        return method;
    }
  }

  Widget _buildInvoiceDetails() {
    return Container(
      padding: EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.receipt_outlined,
                size: AppIconSize.sm,
                color: AppColors.textTertiary,
              ),
              SizedBox(width: AppSpacing.sm),
              Text(
                'تفاصيل الفاتورة',
                style: AppTypography.titleSmall.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          SizedBox(height: AppSpacing.md),

          // Date Row
          Row(
            children: [
              Expanded(
                child: _buildDatePicker(
                  label: 'تاريخ الفاتورة',
                  date: _invoiceDate,
                  onTap: () async {
                    final date = await showDatePicker(
                      context: context,
                      initialDate: _invoiceDate,
                      firstDate: DateTime(2020),
                      lastDate: DateTime.now(),
                    );
                    if (date != null) {
                      setState(() => _invoiceDate = date);
                    }
                  },
                ),
              ),
              SizedBox(width: AppSpacing.md),
              Expanded(
                child: _buildDatePicker(
                  label: 'تاريخ الاستحقاق',
                  date: _dueDate,
                  hint: 'اختياري',
                  onTap: () async {
                    final date = await showDatePicker(
                      context: context,
                      initialDate: _dueDate ??
                          DateTime.now().add(const Duration(days: 30)),
                      firstDate: DateTime.now(),
                      lastDate: DateTime.now().add(const Duration(days: 365)),
                    );
                    if (date != null) {
                      setState(() => _dueDate = date);
                    }
                  },
                ),
              ),
            ],
          ),
          SizedBox(height: AppSpacing.md),

          // Payment Method
          Text(
            'طريقة الدفع',
            style: AppTypography.labelMedium.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          SizedBox(height: AppSpacing.xs),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.xs,
            children: [
              _buildPaymentChip('cash', 'نقدي', Icons.payments_outlined),
              _buildPaymentChip('partial', 'جزئي', Icons.pie_chart_outline),
              _buildPaymentChip('credit', 'آجل', Icons.schedule_outlined),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDatePicker({
    required String label,
    DateTime? date,
    String? hint,
    required VoidCallback onTap,
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
        InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppRadius.md),
          child: Container(
            padding: EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.sm + 2,
            ),
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(AppRadius.md),
              border: Border.all(color: AppColors.border),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.calendar_today_outlined,
                  size: AppIconSize.sm,
                  color: AppColors.textTertiary,
                ),
                SizedBox(width: AppSpacing.sm),
                Text(
                  date != null
                      ? '${date.day}/${date.month}/${date.year}'
                      : hint ?? '',
                  style: AppTypography.bodyMedium.copyWith(
                    color: date != null
                        ? AppColors.textPrimary
                        : AppColors.textTertiary,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPaymentChip(String value, String label, IconData icon) {
    final isSelected = _paymentMethod == value;
    return FilterChip(
      selected: isSelected,
      onSelected: (selected) {
        setState(() {
          _paymentMethod = value;
          // إذا كان نقدي، اجعل المبلغ المدفوع = الإجمالي
          if (value == 'cash') {
            _paidAmountController.text = _total.toStringAsFixed(0);
          } else if (value == 'credit') {
            _paidAmountController.text = '0';
          } else if (value == 'partial') {
            _paidAmountController.clear();
          }
        });
      },
      avatar: Icon(
        icon,
        size: AppIconSize.xs,
        color: isSelected ? AppColors.secondary : AppColors.textTertiary,
      ),
      label: Text(label),
      labelStyle: AppTypography.labelMedium.copyWith(
        color: isSelected ? AppColors.secondary : AppColors.textSecondary,
      ),
      backgroundColor: AppColors.background,
      selectedColor: AppColors.secondary.soft,
      side: BorderSide(
        color: isSelected ? AppColors.secondary : AppColors.border,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.full),
      ),
    );
  }

  Widget _buildItemsSection() {
    return Container(
      padding: EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.inventory_2_outlined,
                    size: AppIconSize.sm,
                    color: AppColors.textTertiary,
                  ),
                  SizedBox(width: AppSpacing.sm),
                  Text(
                    'الأصناف',
                    style: AppTypography.titleSmall.copyWith(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  SizedBox(width: AppSpacing.sm),
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: AppSpacing.sm,
                      vertical: 2.h,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.secondary.soft,
                      borderRadius: BorderRadius.circular(AppRadius.full),
                    ),
                    child: Text(
                      '${_items.length}',
                      style: AppTypography.labelSmall
                          .copyWith(
                            color: AppColors.secondary,
                          )
                          .mono,
                    ),
                  ),
                ],
              ),
              Row(
                children: [
                  IconButton(
                    onPressed: () {
                      // TODO: Scan barcode
                    },
                    icon: Icon(
                      Icons.qr_code_scanner_rounded,
                      color: AppColors.secondary,
                    ),
                    tooltip: 'مسح الباركود',
                  ),
                  FilledButton.icon(
                    onPressed: () => _addItem(),
                    icon: const Icon(Icons.add_rounded, size: 18),
                    label: const Text('إضافة'),
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.secondary,
                      padding: EdgeInsets.symmetric(
                        horizontal: AppSpacing.md,
                        vertical: AppSpacing.sm,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          SizedBox(height: AppSpacing.md),

          // Items List
          if (_items.isEmpty)
            Container(
              padding: EdgeInsets.all(AppSpacing.xl),
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(AppRadius.md),
                border: Border.all(
                  color: AppColors.border,
                  style: BorderStyle.solid,
                ),
              ),
              child: Center(
                child: Column(
                  children: [
                    Icon(
                      Icons.add_shopping_cart_rounded,
                      size: 48.sp,
                      color: AppColors.textTertiary,
                    ),
                    SizedBox(height: AppSpacing.sm),
                    Text(
                      'أضف أصنافاً للفاتورة',
                      style: AppTypography.bodyMedium.copyWith(
                        color: AppColors.textTertiary,
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            ...List.generate(_items.length, (index) {
              final item = _items[index];
              return _buildItemCard(item, index);
            }),
        ],
      ),
    );
  }

  Widget _buildItemCard(Map<String, dynamic> item, int index) {
    final total =
        item['quantity'] * item['price'] * (1 - item['discount'] / 100);

    return Container(
      margin: EdgeInsets.only(bottom: AppSpacing.sm),
      padding: EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item['name'],
                      style: AppTypography.titleSmall.copyWith(
                        color: AppColors.textPrimary,
                      ),
                    ),
                    SizedBox(height: 4.h),
                    Text(
                      '${item['price'].toStringAsFixed(0)} ر.س × ${item['quantity']}',
                      style: AppTypography.bodySmall
                          .copyWith(
                            color: AppColors.textSecondary,
                          )
                          .mono,
                    ),
                    if (item['discount'] > 0)
                      Text(
                        'خصم ${item['discount'].toStringAsFixed(0)}%',
                        style: AppTypography.labelSmall.copyWith(
                          color: AppColors.error,
                        ),
                      ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '${total.toStringAsFixed(0)} ر.س',
                    style: AppTypography.titleSmall
                        .copyWith(
                          color: AppColors.textPrimary,
                        )
                        .monoSemibold,
                  ),
                  SizedBox(height: AppSpacing.sm),
                  Row(
                    children: [
                      _buildQuantityButton(
                        icon: Icons.remove_rounded,
                        onTap: () {
                          if (item['quantity'] > 1) {
                            setState(() => item['quantity']--);
                          }
                        },
                      ),
                      Container(
                        width: 40.w,
                        alignment: Alignment.center,
                        child: Text(
                          '${item['quantity']}',
                          style: AppTypography.titleSmall.mono,
                        ),
                      ),
                      _buildQuantityButton(
                        icon: Icons.add_rounded,
                        onTap: () => setState(() => item['quantity']++),
                      ),
                      SizedBox(width: AppSpacing.sm),
                      IconButton(
                        onPressed: () => setState(() => _items.removeAt(index)),
                        icon: Icon(
                          Icons.delete_outline_rounded,
                          color: AppColors.error,
                          size: AppIconSize.sm,
                        ),
                        style: IconButton.styleFrom(
                          backgroundColor: AppColors.error.soft,
                        ),
                      ),
                    ],
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
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.sm),
      child: Container(
        padding: EdgeInsets.all(AppSpacing.xs),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppRadius.sm),
          border: Border.all(color: AppColors.border),
        ),
        child: Icon(icon, size: AppIconSize.sm, color: AppColors.textSecondary),
      ),
    );
  }

  Widget _buildTotalsSection() {
    return Container(
      padding: EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          _buildTotalRow('المجموع الفرعي', _subtotal),
          SizedBox(height: AppSpacing.sm),

          // Discount Input
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'الخصم',
                style: AppTypography.bodyMedium.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              SizedBox(
                width: 100.w,
                child: TextField(
                  controller: _discountController,
                  keyboardType: TextInputType.number,
                  textAlign: TextAlign.left,
                  style: AppTypography.bodyMedium
                      .copyWith(
                        color: AppColors.error,
                      )
                      .mono,
                  decoration: InputDecoration(
                    hintText: '0',
                    suffixText: 'ر.س',
                    isDense: true,
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: AppSpacing.sm,
                      vertical: AppSpacing.xs,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppRadius.sm),
                      borderSide: BorderSide(color: AppColors.border),
                    ),
                  ),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'[\d.]')),
                  ],
                  onChanged: (value) => setState(() {}),
                ),
              ),
            ],
          ),

          Divider(height: AppSpacing.lg, color: AppColors.border),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'الإجمالي',
                style: AppTypography.titleMedium.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w700,
                ),
              ),
              Text(
                '${_total.toStringAsFixed(2)} ر.س',
                style: AppTypography.headlineSmall
                    .copyWith(
                      color: widget.isSales
                          ? AppColors.success
                          : AppColors.secondary,
                    )
                    .monoBold,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentSection() {
    // إظهار قسم الدفع فقط عند اختيار الدفع الجزئي
    if (_paymentMethod != 'partial') return const SizedBox.shrink();

    return Container(
      padding: EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.success.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.payments_outlined,
                size: AppIconSize.sm,
                color: AppColors.success,
              ),
              SizedBox(width: AppSpacing.sm),
              Text(
                'الدفع الجزئي',
                style: AppTypography.titleSmall.copyWith(
                  color: AppColors.success,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          SizedBox(height: AppSpacing.md),

          // المبلغ المدفوع
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'المبلغ المدفوع',
                style: AppTypography.bodyMedium.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              SizedBox(
                width: 120.w,
                child: TextField(
                  controller: _paidAmountController,
                  keyboardType: TextInputType.number,
                  textAlign: TextAlign.left,
                  style: AppTypography.bodyMedium
                      .copyWith(
                        color: AppColors.success,
                      )
                      .mono,
                  decoration: InputDecoration(
                    hintText: '0',
                    suffixText: 'ر.س',
                    isDense: true,
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: AppSpacing.sm,
                      vertical: AppSpacing.xs,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppRadius.sm),
                      borderSide: BorderSide(color: AppColors.success),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppRadius.sm),
                      borderSide:
                          BorderSide(color: AppColors.success, width: 2),
                    ),
                  ),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'[\d.]')),
                  ],
                  onChanged: (value) => setState(() {}),
                ),
              ),
            ],
          ),
          SizedBox(height: AppSpacing.md),

          // المبلغ المتبقي
          Container(
            padding: EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: _remainingAmount > 0
                  ? AppColors.warning.soft
                  : AppColors.success.soft,
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'المبلغ المتبقي',
                  style: AppTypography.bodyMedium.copyWith(
                    color: _remainingAmount > 0
                        ? AppColors.warning
                        : AppColors.success,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  '${_remainingAmount.toStringAsFixed(2)} ر.س',
                  style: AppTypography.titleMedium
                      .copyWith(
                        color: _remainingAmount > 0
                            ? AppColors.warning
                            : AppColors.success,
                      )
                      .monoBold,
                ),
              ],
            ),
          ),

          // أزرار سريعة للمبالغ
          SizedBox(height: AppSpacing.md),
          Wrap(
            spacing: AppSpacing.sm,
            children: [
              _buildQuickAmountChip((_total * 0.25).round(), '25%'),
              _buildQuickAmountChip((_total * 0.5).round(), '50%'),
              _buildQuickAmountChip((_total * 0.75).round(), '75%'),
              _buildQuickAmountChip(_total.round(), 'كامل'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuickAmountChip(int amount, String label) {
    return ActionChip(
      label: Text('$label (${amount.toStringAsFixed(0)})'),
      onPressed: () {
        setState(() {
          _paidAmountController.text = amount.toString();
        });
      },
      backgroundColor: AppColors.background,
      side: BorderSide(color: AppColors.border),
    );
  }

  Widget _buildTotalRow(String label, double amount) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: AppTypography.bodyMedium.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
        Text(
          '${amount.toStringAsFixed(2)} ر.س',
          style: AppTypography.bodyMedium
              .copyWith(
                color: AppColors.textPrimary,
              )
              .mono,
        ),
      ],
    );
  }

  Widget _buildNotesSection() {
    return Container(
      padding: EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.notes_outlined,
                size: AppIconSize.sm,
                color: AppColors.textTertiary,
              ),
              SizedBox(width: AppSpacing.sm),
              Text(
                'ملاحظات',
                style: AppTypography.titleSmall.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          SizedBox(height: AppSpacing.md),
          TextField(
            controller: _notesController,
            maxLines: 3,
            decoration: InputDecoration(
              hintText: 'أضف ملاحظات للفاتورة...',
              hintStyle: AppTypography.bodyMedium.copyWith(
                color: AppColors.textTertiary,
              ),
              filled: true,
              fillColor: AppColors.background,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppRadius.md),
                borderSide: BorderSide.none,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomBar() {
    return Container(
      padding: EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border(top: BorderSide(color: AppColors.border)),
        boxShadow: AppShadows.sm,
      ),
      child: SafeArea(
        child: Row(
          children: [
            // Save as Draft
            Expanded(
              child: OutlinedButton(
                onPressed: _isSaving ? null : () => context.pop(),
                style: OutlinedButton.styleFrom(
                  padding: EdgeInsets.symmetric(vertical: AppSpacing.md),
                ),
                child: const Text('إلغاء'),
              ),
            ),
            SizedBox(width: AppSpacing.md),
            // Complete Invoice
            Expanded(
              flex: 2,
              child: FilledButton(
                onPressed:
                    _items.isEmpty || _isSaving ? null : () => _saveInvoice(),
                style: FilledButton.styleFrom(
                  backgroundColor:
                      widget.isSales ? AppColors.success : AppColors.secondary,
                  padding: EdgeInsets.symmetric(vertical: AppSpacing.md),
                ),
                child: _isSaving
                    ? SizedBox(
                        width: 20.w,
                        height: 20.w,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white))
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.check_rounded),
                          SizedBox(width: AppSpacing.sm),
                          Text(
                            'حفظ الفاتورة',
                            style: AppTypography.labelLarge.copyWith(
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

  void _selectCustomer() {
    final customersAsync = ref.read(customersStreamProvider);
    final suppliersAsync = ref.read(suppliersStreamProvider);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.lg)),
      ),
      builder: (context) {
        if (widget.isSales) {
          return customersAsync.when(
            loading: () => SizedBox(
                height: 200.h, child: ProLoadingState.list(itemCount: 3)),
            error: (e, _) => SizedBox(
                height: 200.h, child: ProEmptyState.error(error: e.toString())),
            data: (customers) => _buildSelectionList(
              title: 'اختر العميل',
              items: customers
                  .map(
                      (c) => {'id': c.id, 'name': c.name, 'balance': c.balance})
                  .toList(),
              onSelect: (item) {
                setState(() {
                  _selectedCustomerId = item['id'];
                  _selectedCustomerName = item['name'];
                });
                Navigator.pop(context);
              },
            ),
          );
        } else {
          return suppliersAsync.when(
            loading: () => SizedBox(
                height: 200.h, child: ProLoadingState.list(itemCount: 3)),
            error: (e, _) => SizedBox(
                height: 200.h, child: ProEmptyState.error(error: e.toString())),
            data: (suppliers) => _buildSelectionList(
              title: 'اختر المورد',
              items: suppliers
                  .map(
                      (s) => {'id': s.id, 'name': s.name, 'balance': s.balance})
                  .toList(),
              onSelect: (item) {
                setState(() {
                  _selectedSupplierId = item['id'];
                  _selectedSupplierName = item['name'];
                });
                Navigator.pop(context);
              },
            ),
          );
        }
      },
    );
  }

  Widget _buildSelectionList({
    required String title,
    required List<Map<String, dynamic>> items,
    required void Function(Map<String, dynamic>) onSelect,
  }) {
    return Container(
      constraints: BoxConstraints(maxHeight: 400.h),
      padding: EdgeInsets.all(AppSpacing.md),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(title, style: AppTypography.titleMedium),
          SizedBox(height: AppSpacing.md),
          Expanded(
            child: items.isEmpty
                ? Center(child: Text('لا توجد بيانات'))
                : ListView.builder(
                    itemCount: items.length,
                    itemBuilder: (context, index) {
                      final item = items[index];
                      return ListTile(
                        leading: CircleAvatar(
                          backgroundColor: AppColors.secondary.soft,
                          child: Text(item['name'][0],
                              style: TextStyle(color: AppColors.secondary)),
                        ),
                        title: Text(item['name']),
                        subtitle: Text(
                            'الرصيد: ${(item['balance'] as double).toStringAsFixed(0)} ر.س'),
                        onTap: () => onSelect(item),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  void _addItem() {
    final productsAsync = ref.read(activeProductsStreamProvider);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.lg)),
      ),
      builder: (context) {
        return productsAsync.when(
          loading: () => SizedBox(
              height: 200.h, child: ProLoadingState.list(itemCount: 3)),
          error: (e, _) => SizedBox(
              height: 200.h, child: ProEmptyState.error(error: e.toString())),
          data: (products) => Container(
            constraints: BoxConstraints(maxHeight: 500.h),
            padding: EdgeInsets.all(AppSpacing.md),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('اختر منتج', style: AppTypography.titleMedium),
                SizedBox(height: AppSpacing.md),
                Expanded(
                  child: products.isEmpty
                      ? Center(child: Text('لا توجد منتجات'))
                      : ListView.builder(
                          itemCount: products.length,
                          itemBuilder: (context, index) {
                            final product = products[index];
                            final alreadyAdded =
                                _items.any((i) => i['productId'] == product.id);
                            return ListTile(
                              leading: CircleAvatar(
                                backgroundColor: AppColors.secondary.soft,
                                child: Icon(Icons.inventory_2_outlined,
                                    color: AppColors.secondary, size: 20),
                              ),
                              title: Text(product.name),
                              subtitle: Text(
                                  '${product.salePrice.toStringAsFixed(0)} ر.س • المخزون: ${product.quantity}'),
                              trailing: alreadyAdded
                                  ? Icon(Icons.check, color: AppColors.success)
                                  : null,
                              enabled: !alreadyAdded && product.quantity > 0,
                              onTap: alreadyAdded || product.quantity == 0
                                  ? null
                                  : () {
                                      setState(() {
                                        _items.add({
                                          'id': '${_items.length + 1}',
                                          'productId': product.id,
                                          'name': product.name,
                                          'quantity': 1,
                                          'price': widget.isSales
                                              ? product.salePrice
                                              : product.purchasePrice,
                                          'purchasePrice':
                                              product.purchasePrice,
                                          'discount': 0.0,
                                          'maxQuantity': product.quantity,
                                        });
                                      });
                                      Navigator.pop(context);
                                    },
                            );
                          },
                        ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _saveInvoice() async {
    if (_items.isEmpty) {
      ProSnackbar.warning(context, 'أضف منتجات للفاتورة');
      return;
    }

    // التحقق من إدخال المبلغ المدفوع عند الدفع الجزئي
    if (_paymentMethod == 'partial' &&
        _paidAmountController.text.trim().isEmpty) {
      ProSnackbar.warning(context, 'الرجاء إدخال المبلغ المدفوع');
      return;
    }

    setState(() => _isSaving = true);
    try {
      final invoiceRepo = ref.read(invoiceRepositoryProvider);
      final customerRepo = ref.read(customerRepositoryProvider);
      final supplierRepo = ref.read(supplierRepositoryProvider);
      final openShift = ref.read(openShiftStreamProvider).asData?.value;

      final invoiceItems = _items
          .map((item) => {
                'productId': item['productId'],
                'productName': item['name'],
                'quantity': item['quantity'],
                'unitPrice': item['price'],
                'purchasePrice': item['purchasePrice'] ?? 0.0,
                'discount':
                    (item['quantity'] * item['price'] * item['discount'] / 100),
              })
          .toList();

      // حساب المبلغ المدفوع بناءً على طريقة الدفع
      double paidAmount;
      if (_paymentMethod == 'cash') {
        paidAmount = _total;
      } else if (_paymentMethod == 'credit') {
        paidAmount = 0;
      } else {
        // partial - المبلغ المدفوع إجباري
        paidAmount = _paidAmount;
      }

      final invoiceId = await invoiceRepo.createInvoice(
        type: widget.type,
        customerId: widget.isSales ? _selectedCustomerId : null,
        supplierId: !widget.isSales ? _selectedSupplierId : null,
        items: invoiceItems,
        discountAmount: _discount,
        paymentMethod: _paymentMethod,
        paidAmount: paidAmount,
        notes: _notesController.text.trim().isEmpty
            ? null
            : _notesController.text.trim(),
        shiftId: openShift?.id,
        invoiceDate: _invoiceDate,
      );

      // ═══════════════════════════════════════════════════════════════════════
      // تحميل بيانات الفاتورة وعرض حوار النجاح الموحد
      // ═══════════════════════════════════════════════════════════════════════
      final invoice = await invoiceRepo.getInvoiceById(invoiceId);
      final items = await invoiceRepo.getInvoiceItems(invoiceId);

      Customer? customer;
      Supplier? supplier;

      if (widget.isSales && _selectedCustomerId != null) {
        customer = await customerRepo.getCustomerById(_selectedCustomerId!);
      }
      if (!widget.isSales && _selectedSupplierId != null) {
        supplier = await supplierRepo.getSupplierById(_selectedSupplierId!);
      }

      if (mounted && invoice != null) {
        // عرض حوار النجاح الموحد
        final result = await InvoiceSuccessDialog.show(
          context: context,
          data: InvoiceDialogData(
            invoice: invoice,
            items: items,
            customer: customer,
            supplier: supplier,
          ),
          showNewInvoiceButton: true,
          showViewDetailsButton: true,
          onNewInvoice: () {
            // إعادة تعيين النموذج لفاتورة جديدة
            _resetForm();
          },
        );

        // معالجة نتيجة الحوار
        if (result == InvoiceDialogResult.newInvoice) {
          // البقاء في نفس الصفحة مع إعادة تعيين النموذج
          _resetForm();
        } else if (result == InvoiceDialogResult.close ||
            result == InvoiceDialogResult.viewDetails) {
          // الخروج من الصفحة (viewDetails يقوم بالتوجيه تلقائياً)
          if (mounted && result == InvoiceDialogResult.close) {
            context.pop();
          }
        }
      }
    } catch (e) {
      if (mounted) {
        ProSnackbar.showError(context, e);
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  /// إعادة تعيين النموذج لفاتورة جديدة
  void _resetForm() {
    setState(() {
      _items.clear();
      _selectedCustomerId = null;
      _selectedCustomerName = null;
      _selectedSupplierId = null;
      _selectedSupplierName = null;
      _invoiceDate = DateTime.now();
      _dueDate = null;
      _paymentMethod = 'cash';
      _discountController.clear();
      _notesController.clear();
      _paidAmountController.clear();
    });
  }

  void _showDiscardDialog() async {
    final confirm = await showProConfirmDialog(
      context: context,
      title: 'تجاهل التغييرات؟',
      message: 'سيتم فقدان جميع البيانات المدخلة',
      icon: Icons.warning_amber_rounded,
      isDanger: true,
      confirmText: 'تجاهل',
    );
    if (confirm == true) {
      context.pop();
    }
  }
}
