import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../core/constants/app_colors.dart';
import '../../domain/entities/entities.dart';

/// بطاقة العميل
class CustomerCard extends StatelessWidget {
  final CustomerEntity customer;
  final VoidCallback? onTap;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  const CustomerCard({
    super.key,
    required this.customer,
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
              // صورة العميل
              CircleAvatar(
                radius: 24.r,
                backgroundColor: _getTypeColor(customer.type).withOpacity(0.2),
                child: Text(
                  customer.name.isNotEmpty ? customer.name[0] : '?',
                  style: TextStyle(
                    fontSize: 18.sp,
                    fontWeight: FontWeight.bold,
                    color: _getTypeColor(customer.type),
                  ),
                ),
              ),
              SizedBox(width: 12.w),

              // معلومات العميل
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            customer.name,
                            style: TextStyle(
                              fontSize: 14.sp,
                              fontWeight: FontWeight.w600,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        _buildTypeChip(customer.type),
                      ],
                    ),
                    if (customer.phone != null) ...[
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
                            customer.phone!,
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
                        _buildBalanceInfo(customer),
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

  Widget _buildTypeChip(CustomerType type) {
    String label;
    Color color;
    switch (type) {
      case CustomerType.regular:
        label = 'عادي';
        color = Colors.grey;
        break;
      case CustomerType.vip:
        label = 'VIP';
        color = Colors.amber;
        break;
      case CustomerType.wholesale:
        label = 'تاجر جملة';
        color = Colors.blue;
        break;
    }
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
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

  Widget _buildBalanceInfo(CustomerEntity customer) {
    if (customer.amountDue > 0) {
      return Row(
        children: [
          Icon(Icons.arrow_upward, size: 14.sp, color: Colors.red),
          SizedBox(width: 4.w),
          Text(
            'عليه: ${customer.amountDue.toStringAsFixed(2)} ر.س',
            style: TextStyle(
              fontSize: 12.sp,
              color: Colors.red,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      );
    } else if (customer.amountOwed > 0) {
      return Row(
        children: [
          Icon(Icons.arrow_downward, size: 14.sp, color: Colors.green),
          SizedBox(width: 4.w),
          Text(
            'له: ${customer.amountOwed.toStringAsFixed(2)} ر.س',
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

  Color _getTypeColor(CustomerType type) {
    switch (type) {
      case CustomerType.regular:
        return Colors.grey;
      case CustomerType.vip:
        return Colors.amber;
      case CustomerType.wholesale:
        return Colors.blue;
    }
  }
}
