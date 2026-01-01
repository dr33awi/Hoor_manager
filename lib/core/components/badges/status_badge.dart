// ═══════════════════════════════════════════════════════════════════════════
// Status Badge Component
// Visual indicators for transaction and item statuses
// ═══════════════════════════════════════════════════════════════════════════

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../theme/pro/design_tokens.dart';

/// Available status types
enum StatusType {
  // Payment statuses
  paid,
  pending,
  overdue,
  partiallyPaid,
  refunded,

  // Document statuses
  draft,
  confirmed,
  cancelled,

  // Stock statuses
  inStock,
  lowStock,
  outOfStock,

  // General
  active,
  inactive,
  completed,
}

class StatusBadge extends StatelessWidget {
  const StatusBadge({
    super.key,
    required this.status,
    this.showDot = true,
    this.size = StatusBadgeSize.medium,
  });

  final StatusType status;
  final bool showDot;
  final StatusBadgeSize size;

  @override
  Widget build(BuildContext context) {
    final info = _getStatusInfo(status);
    final styles = _getSizeStyles(size);

    return Container(
      padding: styles.padding,
      decoration: BoxDecoration(
        color: info.bgColor,
        borderRadius: BorderRadius.circular(AppRadius.full),
        border: info.hasBorder
            ? Border.all(color: info.color.withValues(alpha: 0.3))
            : null,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (showDot) ...[
            Container(
              width: styles.dotSize,
              height: styles.dotSize,
              decoration: BoxDecoration(
                color: info.color,
                shape: BoxShape.circle,
              ),
            ),
            SizedBox(width: styles.spacing),
          ],
          Text(
            info.label,
            style: styles.textStyle.copyWith(
              color: info.color,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  _StatusInfo _getStatusInfo(StatusType status) {
    return switch (status) {
      // Payment statuses
      StatusType.paid => _StatusInfo(
          label: 'مدفوع',
          color: AppColors.income,
          bgColor: AppColors.incomeSurface,
        ),
      StatusType.pending => _StatusInfo(
          label: 'معلق',
          color: AppColors.warning,
          bgColor: AppColors.warningSurface,
        ),
      StatusType.overdue => _StatusInfo(
          label: 'متأخر',
          color: AppColors.expense,
          bgColor: AppColors.expenseSurface,
        ),
      StatusType.partiallyPaid => _StatusInfo(
          label: 'مدفوع جزئياً',
          color: AppColors.info,
          bgColor: AppColors.infoSurface,
        ),
      StatusType.refunded => _StatusInfo(
          label: 'مسترجع',
          color: AppColors.purchases,
          bgColor: AppColors.purchasesLight,
        ),

      // Document statuses
      StatusType.draft => _StatusInfo(
          label: 'مسودة',
          color: AppColors.textTertiary,
          bgColor: AppColors.neutralSurface,
          hasBorder: true,
        ),
      StatusType.confirmed => _StatusInfo(
          label: 'مؤكد',
          color: AppColors.income,
          bgColor: AppColors.incomeSurface,
        ),
      StatusType.cancelled => _StatusInfo(
          label: 'ملغي',
          color: AppColors.expense,
          bgColor: AppColors.expenseSurface,
        ),

      // Stock statuses
      StatusType.inStock => _StatusInfo(
          label: 'متوفر',
          color: AppColors.income,
          bgColor: AppColors.incomeSurface,
        ),
      StatusType.lowStock => _StatusInfo(
          label: 'مخزون منخفض',
          color: AppColors.warning,
          bgColor: AppColors.warningSurface,
        ),
      StatusType.outOfStock => _StatusInfo(
          label: 'نفذ',
          color: AppColors.expense,
          bgColor: AppColors.expenseSurface,
        ),

      // General
      StatusType.active => _StatusInfo(
          label: 'نشط',
          color: AppColors.income,
          bgColor: AppColors.incomeSurface,
        ),
      StatusType.inactive => _StatusInfo(
          label: 'غير نشط',
          color: AppColors.textTertiary,
          bgColor: AppColors.neutralSurface,
        ),
      StatusType.completed => _StatusInfo(
          label: 'مكتمل',
          color: AppColors.income,
          bgColor: AppColors.incomeSurface,
        ),
    };
  }

  _SizeStyles _getSizeStyles(StatusBadgeSize size) {
    return switch (size) {
      StatusBadgeSize.small => _SizeStyles(
          padding: EdgeInsets.symmetric(
            horizontal: AppSpacing.xs.w,
            vertical: AppSpacing.xxxs.h,
          ),
          dotSize: 5.w,
          spacing: AppSpacing.xxs.w,
          textStyle: AppTypography.caption,
        ),
      StatusBadgeSize.medium => _SizeStyles(
          padding: EdgeInsets.symmetric(
            horizontal: AppSpacing.sm.w,
            vertical: AppSpacing.xxs.h,
          ),
          dotSize: 6.w,
          spacing: AppSpacing.xs.w,
          textStyle: AppTypography.labelSmall,
        ),
      StatusBadgeSize.large => _SizeStyles(
          padding: EdgeInsets.symmetric(
            horizontal: AppSpacing.md.w,
            vertical: AppSpacing.xs.h,
          ),
          dotSize: 8.w,
          spacing: AppSpacing.xs.w,
          textStyle: AppTypography.labelMedium,
        ),
    };
  }
}

enum StatusBadgeSize { small, medium, large }

class _StatusInfo {
  const _StatusInfo({
    required this.label,
    required this.color,
    required this.bgColor,
    this.hasBorder = false,
  });

  final String label;
  final Color color;
  final Color bgColor;
  final bool hasBorder;
}

class _SizeStyles {
  const _SizeStyles({
    required this.padding,
    required this.dotSize,
    required this.spacing,
    required this.textStyle,
  });

  final EdgeInsets padding;
  final double dotSize;
  final double spacing;
  final TextStyle textStyle;
}

/// Amount badge for showing monetary values with color coding
class AmountBadge extends StatelessWidget {
  const AmountBadge({
    super.key,
    required this.amount,
    this.currency = 'ر.س',
    this.showSign = true,
    this.size = AmountBadgeSize.medium,
    this.colorBySign = true,
    this.customColor,
  });

  final double amount;
  final String currency;
  final bool showSign;
  final AmountBadgeSize size;
  final bool colorBySign;
  final Color? customColor;

  @override
  Widget build(BuildContext context) {
    final isPositive = amount >= 0;
    final color = customColor ??
        (colorBySign
            ? (isPositive ? AppColors.income : AppColors.expense)
            : AppColors.textPrimary);

    final styles = _getSizeStyles(size);

    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.baseline,
      textBaseline: TextBaseline.alphabetic,
      children: [
        Text(
          '${showSign ? (isPositive ? '+' : '') : ''}${_formatAmount(amount.abs())}',
          style: styles.amountStyle.copyWith(color: color),
        ),
        SizedBox(width: AppSpacing.xxs.w),
        Text(
          currency,
          style: styles.currencyStyle.copyWith(
            color: color.withValues(alpha: 0.7),
          ),
        ),
      ],
    );
  }

  _AmountSizeStyles _getSizeStyles(AmountBadgeSize size) {
    return switch (size) {
      AmountBadgeSize.small => _AmountSizeStyles(
          amountStyle: AppTypography.moneySmall,
          currencyStyle: AppTypography.caption,
        ),
      AmountBadgeSize.medium => _AmountSizeStyles(
          amountStyle: AppTypography.moneyMedium,
          currencyStyle: AppTypography.bodySmall,
        ),
      AmountBadgeSize.large => _AmountSizeStyles(
          amountStyle: AppTypography.moneyLarge,
          currencyStyle: AppTypography.bodyMedium,
        ),
    };
  }

  String _formatAmount(double amount) {
    if (amount >= 1000000) {
      return '${(amount / 1000000).toStringAsFixed(2)}M';
    } else if (amount >= 1000) {
      return '${(amount / 1000).toStringAsFixed(amount % 1000 == 0 ? 0 : 2)}K';
    }

    // Regular formatting with thousands separator
    final parts = amount.toStringAsFixed(2).split('.');
    final intPart = parts[0];
    final decPart = parts[1];

    final buffer = StringBuffer();
    for (int i = 0; i < intPart.length; i++) {
      if (i > 0 && (intPart.length - i) % 3 == 0) {
        buffer.write(',');
      }
      buffer.write(intPart[i]);
    }

    return '$buffer.$decPart';
  }
}

enum AmountBadgeSize { small, medium, large }

class _AmountSizeStyles {
  const _AmountSizeStyles({
    required this.amountStyle,
    required this.currencyStyle,
  });

  final TextStyle amountStyle;
  final TextStyle currencyStyle;
}
