import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/widgets/app_bar_widget.dart';
import '../../domain/entities/entities.dart';
import '../providers/purchase_providers.dart';

/// شاشة تفاصيل فاتورة الشراء
class PurchaseDetailsScreen extends ConsumerWidget {
  final String purchaseId;

  const PurchaseDetailsScreen({super.key, required this.purchaseId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final purchaseAsync = ref.watch(purchaseProvider(purchaseId));

    return Scaffold(
      appBar: CustomAppBar(
        title: 'تفاصيل الفاتورة',
        actions: [
          IconButton(
            icon: const Icon(Icons.print),
            onPressed: () {
              // طباعة الفاتورة
            },
          ),
        ],
      ),
      body: purchaseAsync.when(
        data: (purchase) {
          if (purchase == null) {
            return const Center(child: Text('الفاتورة غير موجودة'));
          }
          return _buildContent(context, ref, purchase);
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text('خطأ: $error')),
      ),
    );
  }

  Widget _buildContent(
      BuildContext context, WidgetRef ref, PurchaseInvoiceEntity purchase) {
    final dateFormat = DateFormat('yyyy/MM/dd');
    final currencyFormat = NumberFormat.currency(locale: 'ar', symbol: 'ر.س');

    return ListView(
      padding: EdgeInsets.all(16.w),
      children: [
        // معلومات الفاتورة الأساسية
        Card(
          child: Padding(
            padding: EdgeInsets.all(16.w),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '#${purchase.invoiceNumber}',
                      style: TextStyle(
                        fontSize: 18.sp,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                      ),
                    ),
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 12.w,
                        vertical: 6.h,
                      ),
                      decoration: BoxDecoration(
                        color: _getStatusColor(purchase.status)
                            .withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(20.r),
                      ),
                      child: Text(
                        _getStatusName(purchase.status),
                        style: TextStyle(
                          fontSize: 12.sp,
                          color: _getStatusColor(purchase.status),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 16.h),
                _buildInfoRow(
                    'نوع الفاتورة', _getTypeName(purchase.type), Icons.receipt),
                _buildInfoRow('التاريخ', dateFormat.format(purchase.date),
                    Icons.calendar_today),
                if (purchase.supplierName != null)
                  _buildInfoRow(
                      'المورد', purchase.supplierName!, Icons.business),
                if (purchase.supplierInvoiceNumber != null)
                  _buildInfoRow('رقم فاتورة المورد',
                      purchase.supplierInvoiceNumber!, Icons.numbers),
              ],
            ),
          ),
        ),
        SizedBox(height: 16.h),

        // الأصناف
        Card(
          child: Padding(
            padding: EdgeInsets.all(16.w),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.shopping_cart,
                        color: AppColors.primary, size: 20.sp),
                    SizedBox(width: 8.w),
                    Text(
                      'الأصناف (${purchase.itemsCount})',
                      style: TextStyle(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                Divider(height: 24.h),
                if (purchase.items.isEmpty)
                  Center(
                    child: Padding(
                      padding: EdgeInsets.all(20.w),
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
                    itemCount: purchase.items.length,
                    separatorBuilder: (_, __) => Divider(height: 16.h),
                    itemBuilder: (context, index) {
                      final item = purchase.items[index];
                      return Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  item.productName ?? 'منتج',
                                  style: TextStyle(
                                    fontSize: 14.sp,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                SizedBox(height: 4.h),
                                Text(
                                  '${item.quantity} × ${item.unitPrice.toStringAsFixed(2)} ر.س',
                                  style: TextStyle(
                                    fontSize: 12.sp,
                                    color: Colors.grey[600],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Text(
                            '${item.totalPrice.toStringAsFixed(2)} ر.س',
                            style: TextStyle(
                              fontSize: 14.sp,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      );
                    },
                  ),
              ],
            ),
          ),
        ),
        SizedBox(height: 16.h),

        // ملخص المبالغ
        Card(
          child: Padding(
            padding: EdgeInsets.all(16.w),
            child: Column(
              children: [
                _buildAmountRow('المجموع الفرعي', purchase.subtotal),
                if (purchase.discountAmount > 0)
                  _buildAmountRow('الخصم', -purchase.discountAmount,
                      color: Colors.red),
                _buildAmountRow('الضريبة (${purchase.taxPercent.toInt()}%)',
                    purchase.taxAmount),
                if (purchase.shippingCost > 0)
                  _buildAmountRow('الشحن', purchase.shippingCost),
                Divider(height: 16.h),
                _buildAmountRow('الإجمالي', purchase.total, isBold: true),
                SizedBox(height: 8.h),
                _buildAmountRow('المدفوع', purchase.paidAmount,
                    color: Colors.green),
                _buildAmountRow('المتبقي', purchase.remainingAmount,
                    color: purchase.remainingAmount > 0
                        ? Colors.red
                        : Colors.green,
                    isBold: true),
              ],
            ),
          ),
        ),
        SizedBox(height: 16.h),

        // حالة الدفع
        Card(
          child: Padding(
            padding: EdgeInsets.all(16.w),
            child: Row(
              children: [
                Icon(
                  _getPaymentStatusIcon(purchase.paymentStatus),
                  color: _getPaymentStatusColor(purchase.paymentStatus),
                  size: 24.sp,
                ),
                SizedBox(width: 12.w),
                Text(
                  _getPaymentStatusName(purchase.paymentStatus),
                  style: TextStyle(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.bold,
                    color: _getPaymentStatusColor(purchase.paymentStatus),
                  ),
                ),
              ],
            ),
          ),
        ),

        // الملاحظات
        if (purchase.notes != null && purchase.notes!.isNotEmpty) ...[
          SizedBox(height: 16.h),
          Card(
            child: Padding(
              padding: EdgeInsets.all(16.w),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.notes, color: AppColors.primary, size: 20.sp),
                      SizedBox(width: 8.w),
                      Text(
                        'ملاحظات',
                        style: TextStyle(
                          fontSize: 16.sp,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 8.h),
                  Text(purchase.notes!),
                ],
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildInfoRow(String label, String value, IconData icon) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4.h),
      child: Row(
        children: [
          Icon(icon, size: 16.sp, color: Colors.grey),
          SizedBox(width: 8.w),
          Text(
            '$label: ',
            style: TextStyle(
              fontSize: 13.sp,
              color: Colors.grey[600],
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 13.sp,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAmountRow(String label, double amount,
      {bool isBold = false, Color? color}) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4.h),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: isBold ? 15.sp : 13.sp,
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          Text(
            '${amount.toStringAsFixed(2)} ر.س',
            style: TextStyle(
              fontSize: isBold ? 15.sp : 13.sp,
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  String _getTypeName(PurchaseInvoiceType type) {
    switch (type) {
      case PurchaseInvoiceType.purchase:
        return 'فاتورة شراء';
      case PurchaseInvoiceType.returnPurchase:
        return 'مرتجع مشتريات';
      case PurchaseInvoiceType.purchaseOrder:
        return 'أمر شراء';
    }
  }

  String _getStatusName(PurchaseInvoiceStatus status) {
    switch (status) {
      case PurchaseInvoiceStatus.draft:
        return 'مسودة';
      case PurchaseInvoiceStatus.pending:
        return 'معلقة';
      case PurchaseInvoiceStatus.approved:
        return 'موافق عليها';
      case PurchaseInvoiceStatus.received:
        return 'تم الاستلام';
      case PurchaseInvoiceStatus.partiallyReceived:
        return 'استلام جزئي';
      case PurchaseInvoiceStatus.completed:
        return 'مكتملة';
      case PurchaseInvoiceStatus.cancelled:
        return 'ملغاة';
    }
  }

  Color _getStatusColor(PurchaseInvoiceStatus status) {
    switch (status) {
      case PurchaseInvoiceStatus.draft:
        return Colors.grey;
      case PurchaseInvoiceStatus.pending:
        return Colors.orange;
      case PurchaseInvoiceStatus.approved:
        return Colors.blue;
      case PurchaseInvoiceStatus.received:
      case PurchaseInvoiceStatus.completed:
        return Colors.green;
      case PurchaseInvoiceStatus.partiallyReceived:
        return Colors.teal;
      case PurchaseInvoiceStatus.cancelled:
        return Colors.red;
    }
  }

  String _getPaymentStatusName(PurchasePaymentStatus status) {
    switch (status) {
      case PurchasePaymentStatus.unpaid:
        return 'غير مدفوعة';
      case PurchasePaymentStatus.partiallyPaid:
        return 'مدفوعة جزئياً';
      case PurchasePaymentStatus.paid:
        return 'مدفوعة بالكامل';
    }
  }

  Color _getPaymentStatusColor(PurchasePaymentStatus status) {
    switch (status) {
      case PurchasePaymentStatus.unpaid:
        return Colors.red;
      case PurchasePaymentStatus.partiallyPaid:
        return Colors.orange;
      case PurchasePaymentStatus.paid:
        return Colors.green;
    }
  }

  IconData _getPaymentStatusIcon(PurchasePaymentStatus status) {
    switch (status) {
      case PurchasePaymentStatus.unpaid:
        return Icons.money_off;
      case PurchasePaymentStatus.partiallyPaid:
        return Icons.hourglass_bottom;
      case PurchasePaymentStatus.paid:
        return Icons.check_circle;
    }
  }
}
