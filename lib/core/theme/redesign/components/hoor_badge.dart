import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../design_tokens.dart';
import '../typography.dart';

/// ═══════════════════════════════════════════════════════════════════════════
/// HoorBadge - Badge and Tag Components
/// Status indicators, labels, and notification badges
/// ═══════════════════════════════════════════════════════════════════════════

enum HoorBadgeVariant {
  filled,
  outlined,
  soft,
}

enum HoorBadgeSize {
  small,
  medium,
  large,
}

class HoorBadge extends StatelessWidget {
  final String label;
  final Color? color;
  final HoorBadgeVariant variant;
  final HoorBadgeSize size;
  final IconData? icon;
  final bool showDot;
  final VoidCallback? onTap;

  const HoorBadge({
    super.key,
    required this.label,
    this.color,
    this.variant = HoorBadgeVariant.soft,
    this.size = HoorBadgeSize.medium,
    this.icon,
    this.showDot = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveColor = color ?? HoorColors.primary;

    Widget badge = Container(
      padding: _getPadding(),
      decoration: _getDecoration(effectiveColor),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (showDot) ...[
            Container(
              width: 6.w,
              height: 6.w,
              decoration: BoxDecoration(
                color: _getContentColor(effectiveColor),
                shape: BoxShape.circle,
              ),
            ),
            SizedBox(width: 4.w),
          ],
          if (icon != null) ...[
            Icon(
              icon,
              size: _getIconSize(),
              color: _getContentColor(effectiveColor),
            ),
            SizedBox(width: 4.w),
          ],
          Text(
            label,
            style: _getTextStyle(effectiveColor),
          ),
        ],
      ),
    );

    if (onTap != null) {
      badge = GestureDetector(
        onTap: onTap,
        child: badge,
      );
    }

    return badge;
  }

  EdgeInsets _getPadding() {
    switch (size) {
      case HoorBadgeSize.small:
        return EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h);
      case HoorBadgeSize.medium:
        return EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h);
      case HoorBadgeSize.large:
        return EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h);
    }
  }

  double _getIconSize() {
    switch (size) {
      case HoorBadgeSize.small:
        return 10.sp;
      case HoorBadgeSize.medium:
        return 12.sp;
      case HoorBadgeSize.large:
        return 14.sp;
    }
  }

  BoxDecoration _getDecoration(Color color) {
    switch (variant) {
      case HoorBadgeVariant.filled:
        return BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(HoorRadius.full),
        );
      case HoorBadgeVariant.outlined:
        return BoxDecoration(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(HoorRadius.full),
          border: Border.all(color: color, width: 1.5.w),
        );
      case HoorBadgeVariant.soft:
        return BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(HoorRadius.full),
        );
    }
  }

  Color _getContentColor(Color color) {
    switch (variant) {
      case HoorBadgeVariant.filled:
        return Colors.white;
      case HoorBadgeVariant.outlined:
      case HoorBadgeVariant.soft:
        return color;
    }
  }

  TextStyle _getTextStyle(Color color) {
    final baseStyle = switch (size) {
      HoorBadgeSize.small => HoorTypography.labelSmall,
      HoorBadgeSize.medium => HoorTypography.labelMedium,
      HoorBadgeSize.large => HoorTypography.labelLarge,
    };

    return baseStyle.copyWith(
      color: _getContentColor(color),
      fontWeight: FontWeight.w600,
    );
  }
}

/// ═══════════════════════════════════════════════════════════════════════════
/// Status Badge - Predefined status indicators
/// ═══════════════════════════════════════════════════════════════════════════

class HoorStatusBadge extends StatelessWidget {
  final HoorStatus status;
  final String? customLabel;
  final HoorBadgeSize size;

  const HoorStatusBadge({
    super.key,
    required this.status,
    this.customLabel,
    this.size = HoorBadgeSize.medium,
  });

  @override
  Widget build(BuildContext context) {
    return HoorBadge(
      label: customLabel ?? _getLabel(),
      color: _getColor(),
      variant: HoorBadgeVariant.soft,
      size: size,
      showDot: true,
    );
  }

  String _getLabel() {
    switch (status) {
      case HoorStatus.active:
        return 'نشط';
      case HoorStatus.inactive:
        return 'غير نشط';
      case HoorStatus.pending:
        return 'معلق';
      case HoorStatus.completed:
        return 'مكتمل';
      case HoorStatus.cancelled:
        return 'ملغي';
      case HoorStatus.draft:
        return 'مسودة';
      case HoorStatus.paid:
        return 'مدفوع';
      case HoorStatus.unpaid:
        return 'غير مدفوع';
      case HoorStatus.partiallyPaid:
        return 'مدفوع جزئياً';
      case HoorStatus.overdue:
        return 'متأخر';
      case HoorStatus.processing:
        return 'جاري المعالجة';
      case HoorStatus.shipped:
        return 'تم الشحن';
      case HoorStatus.delivered:
        return 'تم التسليم';
    }
  }

  Color _getColor() {
    switch (status) {
      case HoorStatus.active:
      case HoorStatus.completed:
      case HoorStatus.paid:
      case HoorStatus.delivered:
        return HoorColors.success;
      case HoorStatus.inactive:
      case HoorStatus.cancelled:
        return HoorColors.textTertiary;
      case HoorStatus.pending:
      case HoorStatus.processing:
        return HoorColors.info;
      case HoorStatus.draft:
        return HoorColors.textSecondary;
      case HoorStatus.unpaid:
      case HoorStatus.overdue:
        return HoorColors.error;
      case HoorStatus.partiallyPaid:
        return HoorColors.warning;
      case HoorStatus.shipped:
        return HoorColors.purchases;
    }
  }
}

enum HoorStatus {
  active,
  inactive,
  pending,
  completed,
  cancelled,
  draft,
  paid,
  unpaid,
  partiallyPaid,
  overdue,
  processing,
  shipped,
  delivered,
}

/// ═══════════════════════════════════════════════════════════════════════════
/// Count Badge - For notifications and counters
/// ═══════════════════════════════════════════════════════════════════════════

class HoorCountBadge extends StatelessWidget {
  final int count;
  final Color? color;
  final bool showZero;
  final int? maxCount;
  final HoorBadgeSize size;
  final Widget? child;

  const HoorCountBadge({
    super.key,
    required this.count,
    this.color,
    this.showZero = false,
    this.maxCount = 99,
    this.size = HoorBadgeSize.small,
    this.child,
  });

  @override
  Widget build(BuildContext context) {
    if (count <= 0 && !showZero) {
      return child ?? const SizedBox();
    }

    final displayCount =
        maxCount != null && count > maxCount! ? '$maxCount+' : count.toString();

    final badge = Container(
      constraints: BoxConstraints(
        minWidth: _getMinSize(),
        minHeight: _getMinSize(),
      ),
      padding: EdgeInsets.symmetric(
        horizontal: displayCount.length > 1 ? 4.w : 0,
      ),
      decoration: BoxDecoration(
        color: color ?? HoorColors.error,
        borderRadius: BorderRadius.circular(HoorRadius.full),
      ),
      child: Center(
        child: Text(
          displayCount,
          style: _getTextStyle(),
        ),
      ),
    );

    if (child != null) {
      return Stack(
        clipBehavior: Clip.none,
        children: [
          child!,
          Positioned(
            top: -4.h,
            left: -4.w,
            child: badge,
          ),
        ],
      );
    }

    return badge;
  }

  double _getMinSize() {
    switch (size) {
      case HoorBadgeSize.small:
        return 16.w;
      case HoorBadgeSize.medium:
        return 20.w;
      case HoorBadgeSize.large:
        return 24.w;
    }
  }

  TextStyle _getTextStyle() {
    final fontSize = switch (size) {
      HoorBadgeSize.small => 10.sp,
      HoorBadgeSize.medium => 11.sp,
      HoorBadgeSize.large => 12.sp,
    };

    return TextStyle(
      color: Colors.white,
      fontSize: fontSize,
      fontWeight: FontWeight.w700,
    );
  }
}

/// ═══════════════════════════════════════════════════════════════════════════
/// Tag Group - Multiple selectable tags
/// ═══════════════════════════════════════════════════════════════════════════

class HoorTagGroup<T> extends StatelessWidget {
  final List<HoorTagItem<T>> items;
  final List<T>? selectedValues;
  final ValueChanged<T>? onTagTap;
  final bool multiSelect;
  final EdgeInsetsGeometry? padding;
  final double spacing;

  const HoorTagGroup({
    super.key,
    required this.items,
    this.selectedValues,
    this.onTagTap,
    this.multiSelect = false,
    this.padding,
    this.spacing = 8,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: padding ?? EdgeInsets.zero,
      child: Wrap(
        spacing: spacing.w,
        runSpacing: spacing.h,
        children: items.map((item) {
          final isSelected = selectedValues?.contains(item.value) ?? false;

          return HoorBadge(
            label: item.label,
            color: item.color ?? HoorColors.primary,
            variant:
                isSelected ? HoorBadgeVariant.filled : HoorBadgeVariant.soft,
            icon: item.icon,
            onTap: onTagTap != null ? () => onTagTap!(item.value) : null,
          );
        }).toList(),
      ),
    );
  }
}

class HoorTagItem<T> {
  final String label;
  final T value;
  final IconData? icon;
  final Color? color;

  const HoorTagItem({
    required this.label,
    required this.value,
    this.icon,
    this.color,
  });
}
