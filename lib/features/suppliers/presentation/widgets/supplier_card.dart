import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../core/constants/app_colors.dart';
import '../../domain/entities/entities.dart';

/// بطاقة المورد
class SupplierCard extends StatelessWidget {
  final SupplierEntity supplier;
  final VoidCallback? onTap;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  const SupplierCard({
    super.key,
    required this.supplier,
    this.onTap,
    this.onEdit,
    this.onDelete,
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
          child: Row(
            children: [
              // صورة المورد
              CircleAvatar(
                radius: 24.r,
                backgroundColor: AppColors.primary.withOpacity(0.2),
                child: Icon(
                  Icons.local_shipping_outlined,
                  color: AppColors.primary,
                  size: 24.sp,
                ),
              ),
              SizedBox(width: 12.w),

              // معلومات المورد
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            supplier.name,
                            style: TextStyle(
                              fontSize: 14.sp,
                              fontWeight: FontWeight.w600,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        _buildRatingChip(supplier.rating),
                      ],
                    ),
                    if (supplier.contactPerson != null) ...[
                      SizedBox(height: 4.h),
                      Text(
                        supplier.contactPerson!,
                        style: TextStyle(
                          fontSize: 12.sp,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                    if (supplier.phone != null) ...[
                      SizedBox(height: 4.h),
                      Row(
                        children: [
                          Icon(
                            Icons.phone_outlined,
                            size: 14.sp,
                            color: AppColors.textSecondary,
                          ),
                          SizedBox(width: 4.w),
                          Text(
                            supplier.phone!,
                            style: TextStyle(
                              fontSize: 12.sp,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ],
                    SizedBox(height: 8.h),
                    Row(
                      children: [
                        // الرصيد
                        _buildBalanceInfo(supplier),
                        const Spacer(),
                        // الإجراءات
                        if (onEdit != null)
                          IconButton(
                            icon: Icon(Icons.edit_outlined, size: 20.sp),
                            onPressed: onEdit,
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                            color: AppColors.primary,
                          ),
                        if (onDelete != null) ...[
                          SizedBox(width: 16.w),
                          IconButton(
                            icon: Icon(Icons.delete_outline, size: 20.sp),
                            onPressed: onDelete,
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                            color: Colors.red,
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRatingChip(SupplierRating rating) {
    String label;
    Color color;
    switch (rating) {
      case SupplierRating.excellent:
        label = 'ممتاز';
        color = Colors.green;
        break;
      case SupplierRating.good:
        label = 'جيد';
        color = Colors.blue;
        break;
      case SupplierRating.average:
        label = 'متوسط';
        color = Colors.orange;
        break;
      case SupplierRating.poor:
        label = 'ضعيف';
        color = Colors.red;
        break;
    }
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(4.r),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.star, size: 12.sp, color: color),
          SizedBox(width: 2.w),
          Text(
            label,
            style: TextStyle(
              fontSize: 10.sp,
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBalanceInfo(SupplierEntity supplier) {
    if (supplier.amountDue > 0) {
      return Row(
        children: [
          Icon(Icons.arrow_downward, size: 14.sp, color: Colors.red),
          SizedBox(width: 4.w),
          Text(
            'له: ${supplier.amountDue.toStringAsFixed(2)} ر.س',
            style: TextStyle(
              fontSize: 12.sp,
              color: Colors.red,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      );
    } else if (supplier.advancePayments > 0) {
      return Row(
        children: [
          Icon(Icons.arrow_upward, size: 14.sp, color: Colors.green),
          SizedBox(width: 4.w),
          Text(
            'مقدم: ${supplier.advancePayments.toStringAsFixed(2)} ر.س',
            style: TextStyle(
              fontSize: 12.sp,
              color: Colors.green,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      );
    } else {
      return Text(
        'لا يوجد رصيد',
        style: TextStyle(
          fontSize: 12.sp,
          color: AppColors.textSecondary,
        ),
      );
    }
  }
}
