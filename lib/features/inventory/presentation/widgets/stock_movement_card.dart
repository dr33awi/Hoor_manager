import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../domain/entities/entities.dart';

/// بطاقة حركة المخزون
class StockMovementCard extends StatelessWidget {
  final StockMovementEntity movement;
  final VoidCallback? onTap;
  final VoidCallback? onApprove;
  final VoidCallback? onCancel;

  const StockMovementCard({
    super.key,
    required this.movement,
    this.onTap,
    this.onApprove,
    this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.only(bottom: 12.h),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12.r),
        child: Padding(
          padding: EdgeInsets.all(16.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(10.w),
                    decoration: BoxDecoration(
                      color: movement.type.color.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                    child: Icon(
                      movement.type.icon,
                      color: movement.type.color,
                      size: 24.sp,
                    ),
                  ),
                  SizedBox(width: 12.w),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          movement.movementNumber,
                          style: TextStyle(
                            fontSize: 16.sp,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 4.h),
                        Text(
                          movement.type.arabicName,
                          style: TextStyle(
                            fontSize: 12.sp,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding:
                        EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
                    decoration: BoxDecoration(
                      color: movement.status.color.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(20.r),
                    ),
                    child: Text(
                      movement.status.arabicName,
                      style: TextStyle(
                        fontSize: 12.sp,
                        color: movement.status.color,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 12.h),
              Divider(height: 1),
              SizedBox(height: 12.h),

              // تفاصيل الحركة
              Row(
                children: [
                  if (movement.sourceWarehouseName != null) ...[
                    Expanded(
                      child: _buildLocationInfo(
                        'من',
                        movement.sourceWarehouseName!,
                        Icons.arrow_upward,
                        Colors.red,
                      ),
                    ),
                  ],
                  if (movement.sourceWarehouseName != null &&
                      movement.destinationWarehouseName != null)
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 8.w),
                      child: Icon(Icons.arrow_forward, color: Colors.grey),
                    ),
                  if (movement.destinationWarehouseName != null) ...[
                    Expanded(
                      child: _buildLocationInfo(
                        'إلى',
                        movement.destinationWarehouseName!,
                        Icons.arrow_downward,
                        Colors.green,
                      ),
                    ),
                  ],
                ],
              ),
              SizedBox(height: 12.h),

              // معلومات إضافية
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(Icons.inventory_2_outlined,
                          size: 16.sp, color: Colors.grey),
                      SizedBox(width: 4.w),
                      Text(
                        '${movement.itemCount} صنف',
                        style:
                            TextStyle(fontSize: 12.sp, color: Colors.grey[700]),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      Icon(Icons.numbers, size: 16.sp, color: Colors.grey),
                      SizedBox(width: 4.w),
                      Text(
                        '${movement.totalQuantity} وحدة',
                        style:
                            TextStyle(fontSize: 12.sp, color: Colors.grey[700]),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      Icon(Icons.calendar_today,
                          size: 16.sp, color: Colors.grey),
                      SizedBox(width: 4.w),
                      Text(
                        movement.movementDate.toString().split(' ')[0],
                        style:
                            TextStyle(fontSize: 12.sp, color: Colors.grey[700]),
                      ),
                    ],
                  ),
                ],
              ),

              // المرجع إن وجد
              if (movement.referenceNumber != null) ...[
                SizedBox(height: 8.h),
                Row(
                  children: [
                    Icon(Icons.link, size: 16.sp, color: Colors.grey),
                    SizedBox(width: 4.w),
                    Text(
                      'مرجع: ${movement.referenceNumber}',
                      style:
                          TextStyle(fontSize: 12.sp, color: Colors.grey[600]),
                    ),
                  ],
                ),
              ],

              // أزرار الإجراءات
              if (onApprove != null || onCancel != null) ...[
                SizedBox(height: 12.h),
                Divider(height: 1),
                SizedBox(height: 8.h),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    if (onCancel != null)
                      TextButton.icon(
                        onPressed: onCancel,
                        icon: Icon(Icons.cancel_outlined, size: 18.sp),
                        label: const Text('إلغاء'),
                        style:
                            TextButton.styleFrom(foregroundColor: Colors.red),
                      ),
                    if (onApprove != null)
                      ElevatedButton.icon(
                        onPressed: onApprove,
                        icon: Icon(Icons.check, size: 18.sp),
                        label: const Text('اعتماد'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                        ),
                      ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLocationInfo(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: EdgeInsets.all(8.w),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8.r),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16.sp, color: color),
          SizedBox(width: 4.w),
          Flexible(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(fontSize: 10.sp, color: Colors.grey),
                ),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 12.sp,
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
