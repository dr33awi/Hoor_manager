import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:hoor_manager/core/constants/app_colors.dart';
import 'package:intl/intl.dart';

import '../../domain/entities/entities.dart';

/// بطاقة فاتورة الشراء
class PurchaseCard extends StatelessWidget {
  final PurchaseInvoiceEntity purchase;
  final VoidCallback? onTap;

  const PurchaseCard({
    super.key,
    required this.purchase,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.only(bottom: 12.h),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12.r),
        child: Padding(
          padding: EdgeInsets.all(12.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // الصف الأول: رقم الفاتورة والحالة
              Row(
                children: [
                  Icon(
                    Icons.receipt_long_outlined,
                    color: AppColors.primary,
                    size: 20.sp,
                  ),
                  SizedBox(width: 8.w),
                  Text(
                    purchase.invoiceNumber,
                    style: TextStyle(
                      fontSize: 14.sp,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  _buildStatusChip(purchase.status),
                ],
              ),
              SizedBox(height: 8.h),

              // الصف الثاني: المورد والتاريخ
              Row(
                children: [
                  Icon(
                    Icons.local_shipping_outlined,
                    size: 14.sp,
                    color: AppColors.textSecondary,
                  ),
                  SizedBox(width: 4.w),
                  Expanded(
                    child: Text(
                      purchase.supplierName ?? 'مورد غير محدد',
                      style: TextStyle(
                        fontSize: 12.sp,
                        color: AppColors.textSecondary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Icon(
                    Icons.calendar_today_outlined,
                    size: 14.sp,
                    color: AppColors.textSecondary,
                  ),
                  SizedBox(width: 4.w),
                  Text(
                    DateFormat('dd/MM/yyyy').format(purchase.date),
                    style: TextStyle(
                      fontSize: 12.sp,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 8.h),

              // الصف الثالث: المجموع وحالة الدفع
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${purchase.total.toStringAsFixed(2)} ر.س',
                        style: TextStyle(
                          fontSize: 16.sp,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                        ),
                      ),
                      Text(
                        '${purchase.itemsCount} صنف',
                        style: TextStyle(
                          fontSize: 10.sp,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                  _buildPaymentStatusChip(purchase.paymentStatus),
                ],
              ),

              // المبلغ المتبقي إذا كان هناك
              if (purchase.remainingAmount > 0) ...[
                SizedBox(height: 8.h),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                  decoration: BoxDecoration(
                    color: Colors.orange[50],
                    borderRadius: BorderRadius.circular(4.r),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.warning_amber_outlined,
                          size: 14.sp, color: Colors.orange),
                      SizedBox(width: 4.w),
                      Text(
                        'المتبقي: ${purchase.remainingAmount.toStringAsFixed(2)} ر.س',
                        style: TextStyle(
                          fontSize: 11.sp,
                          color: Colors.orange[900],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusChip(PurchaseInvoiceStatus status) {
    String label;
    Color color;
    switch (status) {
      case PurchaseInvoiceStatus.draft:
        label = 'مسودة';
        color = Colors.grey;
        break;
      case PurchaseInvoiceStatus.pending:
        label = 'معلقة';
        color = Colors.orange;
        break;
      case PurchaseInvoiceStatus.approved:
        label = 'موافق عليها';
        color = Colors.blue;
        break;
      case PurchaseInvoiceStatus.received:
        label = 'تم الاستلام';
        color = Colors.green;
        break;
      case PurchaseInvoiceStatus.partiallyReceived:
        label = 'استلام جزئي';
        color = Colors.amber;
        break;
      case PurchaseInvoiceStatus.completed:
        label = 'مكتملة';
        color = Colors.green;
        break;
      case PurchaseInvoiceStatus.cancelled:
        label = 'ملغاة';
        color = Colors.red;
        break;
    }
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(4.r),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10.sp,
          color: color,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildPaymentStatusChip(PurchasePaymentStatus status) {
    String label;
    Color color;
    IconData icon;
    switch (status) {
      case PurchasePaymentStatus.unpaid:
        label = 'غير مدفوعة';
        color = Colors.red;
        icon = Icons.cancel_outlined;
        break;
      case PurchasePaymentStatus.partiallyPaid:
        label = 'مدفوعة جزئياً';
        color = Colors.orange;
        icon = Icons.hourglass_bottom_outlined;
        break;
      case PurchasePaymentStatus.paid:
        label = 'مدفوعة';
        color = Colors.green;
        icon = Icons.check_circle_outline;
        break;
    }
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14.sp, color: color),
        SizedBox(width: 4.w),
        Text(
          label,
          style: TextStyle(
            fontSize: 11.sp,
            color: color,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
