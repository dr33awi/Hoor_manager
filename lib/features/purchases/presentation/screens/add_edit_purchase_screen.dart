import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:hoor_manager/core/constants/app_colors.dart';
import 'package:intl/intl.dart';

import '../../../../core/widgets/app_bar_widget.dart';
import '../../../../core/widgets/custom_button.dart';
import '../../../../core/widgets/custom_text_field.dart';
import '../../domain/entities/entities.dart';
import '../providers/purchase_providers.dart';

/// شاشة إضافة/تعديل فاتورة شراء
class AddEditPurchaseScreen extends ConsumerStatefulWidget {
  final String? purchaseId;

  const AddEditPurchaseScreen({super.key, this.purchaseId});

  @override
  ConsumerState<AddEditPurchaseScreen> createState() =>
      _AddEditPurchaseScreenState();
}

class _AddEditPurchaseScreenState extends ConsumerState<AddEditPurchaseScreen> {
  final _formKey = GlobalKey<FormState>();
  final _supplierInvoiceController = TextEditingController();
  final _notesController = TextEditingController();
  final _discountController = TextEditingController(text: '0');
  final _shippingController = TextEditingController(text: '0');

  PurchaseInvoiceType _type = PurchaseInvoiceType.purchase;
  DateTime _date = DateTime.now();
  DateTime? _dueDate;
  String? _selectedSupplierId;
  final List<PurchaseItemEntity> _items = [];
  bool _isLoading = false;

  bool get _isEditing => widget.purchaseId != null;

  @override
  void initState() {
    super.initState();
    if (_isEditing) {
      _loadPurchase();
    }
  }

  Future<void> _loadPurchase() async {
    // تحميل بيانات الفاتورة للتعديل
  }

  @override
  void dispose() {
    _supplierInvoiceController.dispose();
    _notesController.dispose();
    _discountController.dispose();
    _shippingController.dispose();
    super.dispose();
  }

  double get _subtotal => _items.fold(0, (sum, item) => sum + item.totalPrice);
  double get _discount => double.tryParse(_discountController.text) ?? 0;
  double get _shipping => double.tryParse(_shippingController.text) ?? 0;
  double get _taxAmount => (_subtotal - _discount) * 0.15;
  double get _total => _subtotal - _discount + _taxAmount + _shipping;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        title: _isEditing ? 'تعديل فاتورة الشراء' : 'فاتورة شراء جديدة',
      ),
      body: Form(
        key: _formKey,
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: EdgeInsets.all(16.w),
                children: [
                  // نوع الفاتورة
                  DropdownButtonFormField<PurchaseInvoiceType>(
                    value: _type,
                    decoration: InputDecoration(
                      labelText: 'نوع الفاتورة',
                      prefixIcon: const Icon(Icons.receipt),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8.r),
                      ),
                    ),
                    items: const [
                      DropdownMenuItem(
                        value: PurchaseInvoiceType.purchase,
                        child: Text('فاتورة شراء'),
                      ),
                      DropdownMenuItem(
                        value: PurchaseInvoiceType.returnPurchase,
                        child: Text('مرتجع مشتريات'),
                      ),
                      DropdownMenuItem(
                        value: PurchaseInvoiceType.purchaseOrder,
                        child: Text('أمر شراء'),
                      ),
                    ],
                    onChanged: (value) {
                      if (value != null) setState(() => _type = value);
                    },
                  ),
                  SizedBox(height: 16.h),

                  // التاريخ
                  InkWell(
                    onTap: _selectDate,
                    child: InputDecorator(
                      decoration: InputDecoration(
                        labelText: 'التاريخ',
                        prefixIcon: const Icon(Icons.calendar_today),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8.r),
                        ),
                      ),
                      child: Text(DateFormat('yyyy/MM/dd').format(_date)),
                    ),
                  ),
                  SizedBox(height: 16.h),

                  // رقم فاتورة المورد
                  CustomTextField(
                    controller: _supplierInvoiceController,
                    label: 'رقم فاتورة المورد',
                    prefixIcon: Icons.numbers,
                  ),
                  SizedBox(height: 16.h),

                  // الأصناف
                  Card(
                    child: Padding(
                      padding: EdgeInsets.all(12.w),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'الأصناف',
                                style: TextStyle(
                                  fontSize: 16.sp,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              TextButton.icon(
                                onPressed: _addItem,
                                icon: const Icon(Icons.add),
                                label: const Text('إضافة صنف'),
                              ),
                            ],
                          ),
                          if (_items.isEmpty)
                            Padding(
                              padding: EdgeInsets.all(20.w),
                              child: Center(
                                child: Text(
                                  'لا توجد أصناف',
                                  style: TextStyle(color: Colors.grey[600]),
                                ),
                              ),
                            )
                          else
                            ListView.separated(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: _items.length,
                              separatorBuilder: (_, __) =>
                                  const Divider(height: 1),
                              itemBuilder: (context, index) {
                                final item = _items[index];
                                return ListTile(
                                  title: Text(item.productName ?? 'منتج'),
                                  subtitle: Text(
                                      '${item.quantity} × ${item.unitPrice.toStringAsFixed(2)}'),
                                  trailing: Text(
                                    '${item.totalPrice.toStringAsFixed(2)} ر.س',
                                    style: const TextStyle(
                                        fontWeight: FontWeight.bold),
                                  ),
                                  onTap: () => _editItem(index),
                                );
                              },
                            ),
                        ],
                      ),
                    ),
                  ),
                  SizedBox(height: 16.h),

                  // الخصم والشحن
                  Row(
                    children: [
                      Expanded(
                        child: CustomTextField(
                          controller: _discountController,
                          label: 'الخصم',
                          prefixIcon: Icons.discount,
                          keyboardType: TextInputType.number,
                          onChanged: (_) => setState(() {}),
                        ),
                      ),
                      SizedBox(width: 8.w),
                      Expanded(
                        child: CustomTextField(
                          controller: _shippingController,
                          label: 'الشحن',
                          prefixIcon: Icons.local_shipping,
                          keyboardType: TextInputType.number,
                          onChanged: (_) => setState(() {}),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 16.h),

                  // الملاحظات
                  CustomTextField(
                    controller: _notesController,
                    label: 'ملاحظات',
                    prefixIcon: Icons.notes,
                    maxLines: 2,
                  ),
                ],
              ),
            ),

            // الملخص وزر الحفظ
            Container(
              padding: EdgeInsets.all(16.w),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withValues(alpha: 0.2),
                    blurRadius: 10,
                    offset: const Offset(0, -5),
                  ),
                ],
              ),
              child: Column(
                children: [
                  _buildSummaryRow('المجموع الفرعي', _subtotal),
                  _buildSummaryRow('الخصم', -_discount),
                  _buildSummaryRow('الضريبة (15%)', _taxAmount),
                  _buildSummaryRow('الشحن', _shipping),
                  Divider(height: 16.h),
                  _buildSummaryRow('الإجمالي', _total, isBold: true),
                  SizedBox(height: 16.h),
                  CustomButton(
                    text: _isEditing ? 'تحديث' : 'حفظ الفاتورة',
                    onPressed: _isLoading ? null : _save,
                    isLoading: _isLoading,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryRow(String label, double value, {bool isBold = false}) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4.h),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: isBold ? 16.sp : 14.sp,
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          Text(
            '${value.toStringAsFixed(2)} ر.س',
            style: TextStyle(
              fontSize: isBold ? 16.sp : 14.sp,
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
              color: value < 0 ? Colors.red : null,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() => _date = picked);
    }
  }

  void _addItem() {
    // إضافة صنف جديد (يمكن فتح حوار لاختيار المنتج)
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('سيتم إضافة شاشة اختيار المنتجات')),
    );
  }

  void _editItem(int index) {
    // تعديل صنف
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    if (_items.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('يرجى إضافة صنف واحد على الأقل'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      // حفظ الفاتورة
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_isEditing ? 'تم تحديث الفاتورة' : 'تم حفظ الفاتورة'),
          backgroundColor: AppColors.success,
        ),
      );
      context.pop();
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
