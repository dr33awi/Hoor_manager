// ═══════════════════════════════════════════════════════════════════════════
// Pro Status Badge - Unified Status Badge Widget
// Consistent status indicators across all screens
// ═══════════════════════════════════════════════════════════════════════════

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../theme/design_tokens.dart';

/// Badge حالة موحد
class ProStatusBadge extends StatelessWidget {
  final String label;
  final Color color;
  final IconData? icon;
  final bool small;
  final bool outlined;

  const ProStatusBadge({
    super.key,
    required this.label,
    required this.color,
    this.icon,
    this.small = false,
    this.outlined = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: small ? AppSpacing.xs + 2 : AppSpacing.sm,
        vertical: small ? 2.h : 4.h,
      ),
      decoration: BoxDecoration(
        color: outlined ? Colors.transparent : color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppRadius.full),
        border: outlined ? Border.all(color: color.withValues(alpha: 0.5)) : null,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(
              icon,
              size: small ? 10.sp : 12.sp,
              color: color,
            ),
            SizedBox(width: 4.w),
          ],
          Text(
            label,
            style: (small ? AppTypography.labelSmall : AppTypography.labelMedium)
                .copyWith(
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // Factory Constructors
  // ═══════════════════════════════════════════════════════════════════════════

  /// حالة نجاح
  factory ProStatusBadge.success({
    String label = 'مكتمل',
    IconData? icon,
    bool small = false,
  }) {
    return ProStatusBadge(
      label: label,
      color: AppColors.success,
      icon: icon,
      small: small,
    );
  }

  /// حالة خطأ
  factory ProStatusBadge.error({
    String label = 'فشل',
    IconData? icon,
    bool small = false,
  }) {
    return ProStatusBadge(
      label: label,
      color: AppColors.error,
      icon: icon,
      small: small,
    );
  }

  /// حالة تحذير
  factory ProStatusBadge.warning({
    String label = 'تحذير',
    IconData? icon,
    bool small = false,
  }) {
    return ProStatusBadge(
      label: label,
      color: AppColors.warning,
      icon: icon,
      small: small,
    );
  }

  /// حالة معلومات
  factory ProStatusBadge.info({
    String label = 'معلومة',
    IconData? icon,
    bool small = false,
  }) {
    return ProStatusBadge(
      label: label,
      color: AppColors.info,
      icon: icon,
      small: small,
    );
  }

  /// حالة معلقة
  factory ProStatusBadge.pending({
    String label = 'معلق',
    IconData? icon,
    bool small = false,
  }) {
    return ProStatusBadge(
      label: label,
      color: AppColors.warning,
      icon: icon ?? Icons.schedule_rounded,
      small: small,
    );
  }

  /// حالة مفتوحة
  factory ProStatusBadge.open({
    String label = 'مفتوح',
    bool small = false,
  }) {
    return ProStatusBadge(
      label: label,
      color: AppColors.success,
      icon: Icons.lock_open_rounded,
      small: small,
    );
  }

  /// حالة مغلقة
  factory ProStatusBadge.closed({
    String label = 'مغلق',
    bool small = false,
  }) {
    return ProStatusBadge(
      label: label,
      color: AppColors.textSecondary,
      icon: Icons.lock_rounded,
      small: small,
    );
  }

  /// حالة ملغية
  factory ProStatusBadge.cancelled({
    String label = 'ملغي',
    bool small = false,
  }) {
    return ProStatusBadge(
      label: label,
      color: AppColors.error,
      icon: Icons.cancel_rounded,
      small: small,
    );
  }

  /// حالة قبض
  factory ProStatusBadge.receipt({
    String label = 'قبض',
    bool small = false,
  }) {
    return ProStatusBadge(
      label: label,
      color: AppColors.success,
      icon: Icons.arrow_downward_rounded,
      small: small,
    );
  }

  /// حالة صرف
  factory ProStatusBadge.payment({
    String label = 'صرف',
    bool small = false,
  }) {
    return ProStatusBadge(
      label: label,
      color: AppColors.error,
      icon: Icons.arrow_upward_rounded,
      small: small,
    );
  }

  /// حالة جزئي
  factory ProStatusBadge.partial({
    String label = 'جزئي',
    bool small = false,
  }) {
    return ProStatusBadge(
      label: label,
      color: AppColors.info,
      small: small,
    );
  }

  /// من حالة الفاتورة
  factory ProStatusBadge.fromInvoiceStatus(String status, {bool small = false}) {
    switch (status) {
      case 'completed':
      case 'paid':
        return ProStatusBadge.success(label: 'مكتمل', small: small);
      case 'pending':
        return ProStatusBadge.pending(label: 'معلق', small: small);
      case 'partial':
        return ProStatusBadge.partial(label: 'جزئي', small: small);
      case 'cancelled':
        return ProStatusBadge.cancelled(label: 'ملغي', small: small);
      default:
        return ProStatusBadge(
          label: status,
          color: AppColors.textSecondary,
          small: small,
        );
    }
  }

  /// من حالة الوردية
  factory ProStatusBadge.fromShiftStatus(String status, {bool small = false}) {
    switch (status) {
      case 'open':
        return ProStatusBadge.open(label: 'مفتوحة', small: small);
      case 'closed':
        return ProStatusBadge.closed(label: 'مغلقة', small: small);
      default:
        return ProStatusBadge(
          label: status,
          color: AppColors.textSecondary,
          small: small,
        );
    }
  }

  /// من نوع السند
  factory ProStatusBadge.fromVoucherType(String type, {bool small = false}) {
    switch (type) {
      case 'receipt':
        return ProStatusBadge.receipt(small: small);
      case 'payment':
        return ProStatusBadge.payment(small: small);
      case 'expense':
        return ProStatusBadge.warning(label: 'مصاريف', small: small);
      default:
        return ProStatusBadge(
          label: type,
          color: AppColors.textSecondary,
          small: small,
        );
    }
  }

  /// من حالة النقل
  factory ProStatusBadge.fromTransferStatus(String status, {bool small = false}) {
    switch (status) {
      case 'pending':
        return ProStatusBadge.pending(label: 'معلقة', small: small);
      case 'completed':
        return ProStatusBadge.success(label: 'مكتملة', small: small);
      case 'cancelled':
        return ProStatusBadge.cancelled(label: 'ملغية', small: small);
      default:
        return ProStatusBadge(
          label: status,
          color: AppColors.textSecondary,
          small: small,
        );
    }
  }
}

/// Chip قابل للاختيار
class ProSelectableChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  final Color? selectedColor;

  const ProSelectableChip({
    super.key,
    required this.label,
    required this.isSelected,
    required this.onTap,
    this.selectedColor,
  });

  @override
  Widget build(BuildContext context) {
    final color = selectedColor ?? AppColors.primary;
    
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: AppDurations.fast,
        padding: EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        decoration: BoxDecoration(
          color: isSelected ? color : Colors.transparent,
          borderRadius: BorderRadius.circular(AppRadius.full),
          border: Border.all(
            color: isSelected ? color : AppColors.border,
          ),
        ),
        child: Text(
          label,
          style: AppTypography.labelMedium.copyWith(
            color: isSelected ? Colors.white : AppColors.textSecondary,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
          ),
        ),
      ),
    );
  }
}

/// مؤشر عدد (Count Badge)
class ProCountBadge extends StatelessWidget {
  final int count;
  final Color? color;
  final bool small;

  const ProCountBadge({
    super.key,
    required this.count,
    this.color,
    this.small = false,
  });

  @override
  Widget build(BuildContext context) {
    if (count <= 0) return const SizedBox.shrink();

    final bgColor = color ?? AppColors.error;
    final displayText = count > 99 ? '99+' : count.toString();

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: small ? 4.w : 6.w,
        vertical: small ? 2.h : 3.h,
      ),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(AppRadius.full),
      ),
      child: Text(
        displayText,
        style: AppTypography.labelSmall.copyWith(
          color: Colors.white,
          fontSize: small ? 9.sp : 10.sp,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
