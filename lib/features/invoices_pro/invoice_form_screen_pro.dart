// ═══════════════════════════════════════════════════════════════════════════
// Invoice Form Screen Pro
// Create/Edit Invoice with Professional Design
// ═══════════════════════════════════════════════════════════════════════════

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/pro/design_tokens.dart';

class InvoiceFormScreenPro extends StatefulWidget {
  final String type; // 'sale' or 'purchase'
  final String? invoiceId;

  const InvoiceFormScreenPro({
    super.key,
    required this.type,
    this.invoiceId,
  });

  bool get isEditing => invoiceId != null;
  bool get isSales => type == 'sale';

  @override
  State<InvoiceFormScreenPro> createState() => _InvoiceFormScreenProState();
}

class _InvoiceFormScreenProState extends State<InvoiceFormScreenPro> {
  String? _selectedCustomer;
  DateTime _invoiceDate = DateTime.now();
  DateTime? _dueDate;
  String _paymentMethod = 'cash';
  final _discountController = TextEditingController();
  final _notesController = TextEditingController();

  // Sample items
  final List<Map<String, dynamic>> _items = [
    {
      'id': '1',
      'name': 'لابتوب HP ProBook',
      'quantity': 2,
      'price': 2500.00,
      'discount': 0.0,
    },
    {
      'id': '2',
      'name': 'ماوس لاسلكي',
      'quantity': 5,
      'price': 75.00,
      'discount': 10.0,
    },
  ];

  double get _subtotal => _items.fold(
        0.0,
        (sum, item) =>
            sum +
            (item['quantity'] * item['price'] * (1 - item['discount'] / 100)),
      );

  double get _discount => double.tryParse(_discountController.text) ?? 0;
  double get _tax => (_subtotal - _discount) * 0.15;
  double get _total => _subtotal - _discount + _tax;

  @override
  void dispose() {
    _discountController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        leading: IconButton(
          onPressed: () => _showDiscardDialog(),
          icon: Icon(Icons.close_rounded, color: AppColors.textSecondary),
        ),
        title: Text(
          widget.isSales
              ? (widget.isEditing ? 'تعديل فاتورة بيع' : 'فاتورة بيع جديدة')
              : (widget.isEditing ? 'تعديل فاتورة شراء' : 'فاتورة شراء جديدة'),
          style: AppTypography.titleLarge.copyWith(
            color: AppColors.textPrimary,
          ),
        ),
        actions: [
          IconButton(
            onPressed: () {
              // TODO: Preview invoice
            },
            icon:
                Icon(Icons.visibility_outlined, color: AppColors.textSecondary),
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
                    backgroundColor: AppColors.secondary.withOpacity(0.1),
                    child: _selectedCustomer != null
                        ? Text(
                            _selectedCustomer![0],
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
                    child: _selectedCustomer != null
                        ? Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _selectedCustomer!,
                                style: AppTypography.titleSmall.copyWith(
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              Text(
                                'عميل آجل • رصيد: 5,000 ر.س',
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
            children: [
              _buildPaymentChip('cash', 'نقدي', Icons.payments_outlined),
              _buildPaymentChip('credit', 'آجل', Icons.schedule_outlined),
              _buildPaymentChip('card', 'بطاقة', Icons.credit_card_outlined),
              _buildPaymentChip(
                  'transfer', 'تحويل', Icons.account_balance_outlined),
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
      onSelected: (selected) => setState(() => _paymentMethod = value),
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
      selectedColor: AppColors.secondary.withOpacity(0.1),
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
                      color: AppColors.secondary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(AppRadius.full),
                    ),
                    child: Text(
                      '${_items.length}',
                      style: AppTypography.labelSmall.copyWith(
                        color: AppColors.secondary,
                        fontFamily: 'JetBrains Mono',
                      ),
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
                      style: AppTypography.bodySmall.copyWith(
                        color: AppColors.textSecondary,
                        fontFamily: 'JetBrains Mono',
                      ),
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
                    style: AppTypography.titleSmall.copyWith(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w600,
                      fontFamily: 'JetBrains Mono',
                    ),
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
                          style: AppTypography.titleSmall.copyWith(
                            fontFamily: 'JetBrains Mono',
                          ),
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
                          backgroundColor: AppColors.error.withOpacity(0.1),
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
                  style: AppTypography.bodyMedium.copyWith(
                    fontFamily: 'JetBrains Mono',
                    color: AppColors.error,
                  ),
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
          SizedBox(height: AppSpacing.sm),
          _buildTotalRow('الضريبة (15%)', _tax),

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
                style: AppTypography.headlineSmall.copyWith(
                  color:
                      widget.isSales ? AppColors.success : AppColors.secondary,
                  fontWeight: FontWeight.w700,
                  fontFamily: 'JetBrains Mono',
                ),
              ),
            ],
          ),
        ],
      ),
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
          style: AppTypography.bodyMedium.copyWith(
            color: AppColors.textPrimary,
            fontFamily: 'JetBrains Mono',
          ),
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
                onPressed: () {
                  // TODO: Save draft
                  context.pop();
                },
                style: OutlinedButton.styleFrom(
                  padding: EdgeInsets.symmetric(vertical: AppSpacing.md),
                ),
                child: const Text('حفظ كمسودة'),
              ),
            ),
            SizedBox(width: AppSpacing.md),
            // Complete Invoice
            Expanded(
              flex: 2,
              child: FilledButton(
                onPressed: _items.isEmpty ? null : () => _saveInvoice(),
                style: FilledButton.styleFrom(
                  backgroundColor:
                      widget.isSales ? AppColors.success : AppColors.secondary,
                  padding: EdgeInsets.symmetric(vertical: AppSpacing.md),
                ),
                child: Row(
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
    // TODO: Show customer selection bottom sheet
    setState(() {
      _selectedCustomer = 'شركة النور للتجارة';
    });
  }

  void _addItem() {
    // TODO: Show product selection bottom sheet
    setState(() {
      _items.add({
        'id': '${_items.length + 1}',
        'name': 'منتج جديد',
        'quantity': 1,
        'price': 100.00,
        'discount': 0.0,
      });
    });
  }

  void _saveInvoice() {
    // TODO: Validate and save invoice
    context.pop();
  }

  void _showDiscardDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('تجاهل التغييرات؟'),
        content: const Text('سيتم فقدان جميع البيانات المدخلة'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إلغاء'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(context);
              context.pop();
            },
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.error,
            ),
            child: const Text('تجاهل'),
          ),
        ],
      ),
    );
  }
}
