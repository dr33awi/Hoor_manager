// ═══════════════════════════════════════════════════════════════════════════
// Pro Button - Unified Button Widget
// Consistent buttons across all screens
// ═══════════════════════════════════════════════════════════════════════════

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../theme/design_tokens.dart';

/// أنواع الأزرار
enum ProButtonType {
  /// زر أساسي ملون بالكامل
  filled,

  /// زر مخطط (outline)
  outlined,

  /// زر نصي
  text,

  /// زر مرتفع
  elevated,

  /// زر مدرج (tonal)
  tonal,
}

/// أحجام الأزرار
enum ProButtonSize {
  /// صغير
  small,

  /// متوسط
  medium,

  /// كبير
  large,
}

/// زر موحد
class ProButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool iconAtEnd;
  final ProButtonType type;
  final ProButtonSize size;
  final Color? color;
  final bool isLoading;
  final bool fullWidth;
  final double? width;

  const ProButton({
    super.key,
    required this.label,
    this.onPressed,
    this.icon,
    this.iconAtEnd = false,
    this.type = ProButtonType.filled,
    this.size = ProButtonSize.medium,
    this.color,
    this.isLoading = false,
    this.fullWidth = false,
    this.width,
  });

  @override
  Widget build(BuildContext context) {
    final buttonColor = color ?? AppColors.primary;
    final padding = _getPadding();
    final textStyle = _getTextStyle();
    final iconSize = _getIconSize();
    final loaderSize = _getLoaderSize();

    Widget content = isLoading
        ? SizedBox(
            width: loaderSize,
            height: loaderSize,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(
                type == ProButtonType.filled || type == ProButtonType.elevated
                    ? Colors.white
                    : buttonColor,
              ),
            ),
          )
        : Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (icon != null && !iconAtEnd) ...[
                Icon(icon, size: iconSize),
                SizedBox(width: AppSpacing.sm),
              ],
              Text(label, style: textStyle),
              if (icon != null && iconAtEnd) ...[
                SizedBox(width: AppSpacing.sm),
                Icon(icon, size: iconSize),
              ],
            ],
          );

    Widget button;

    switch (type) {
      case ProButtonType.filled:
        button = FilledButton(
          onPressed: isLoading ? null : onPressed,
          style: FilledButton.styleFrom(
            backgroundColor: buttonColor,
            foregroundColor: Colors.white,
            padding: padding,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
            minimumSize: Size(0, _getMinHeight()),
          ),
          child: content,
        );
        break;

      case ProButtonType.outlined:
        button = OutlinedButton(
          onPressed: isLoading ? null : onPressed,
          style: OutlinedButton.styleFrom(
            foregroundColor: buttonColor,
            side: BorderSide(color: buttonColor),
            padding: padding,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
            minimumSize: Size(0, _getMinHeight()),
          ),
          child: content,
        );
        break;

      case ProButtonType.text:
        button = TextButton(
          onPressed: isLoading ? null : onPressed,
          style: TextButton.styleFrom(
            foregroundColor: buttonColor,
            padding: padding,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
            minimumSize: Size(0, _getMinHeight()),
          ),
          child: content,
        );
        break;

      case ProButtonType.elevated:
        button = ElevatedButton(
          onPressed: isLoading ? null : onPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: buttonColor,
            foregroundColor: Colors.white,
            padding: padding,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
            elevation: 2,
            minimumSize: Size(0, _getMinHeight()),
          ),
          child: content,
        );
        break;

      case ProButtonType.tonal:
        button = FilledButton.tonal(
          onPressed: isLoading ? null : onPressed,
          style: FilledButton.styleFrom(
            backgroundColor: buttonColor.withValues(alpha: 0.1),
            foregroundColor: buttonColor,
            padding: padding,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
            minimumSize: Size(0, _getMinHeight()),
          ),
          child: content,
        );
        break;
    }

    if (fullWidth) {
      return SizedBox(width: double.infinity, child: button);
    } else if (width != null) {
      return SizedBox(width: width, child: button);
    }

    return button;
  }

  EdgeInsets _getPadding() {
    switch (size) {
      case ProButtonSize.small:
        return EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h);
      case ProButtonSize.medium:
        return EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h);
      case ProButtonSize.large:
        return EdgeInsets.symmetric(horizontal: 24.w, vertical: 16.h);
    }
  }

  TextStyle _getTextStyle() {
    switch (size) {
      case ProButtonSize.small:
        return AppTypography.labelSmall;
      case ProButtonSize.medium:
        return AppTypography.labelLarge;
      case ProButtonSize.large:
        return AppTypography.titleSmall;
    }
  }

  double _getIconSize() {
    switch (size) {
      case ProButtonSize.small:
        return 16.sp;
      case ProButtonSize.medium:
        return 20.sp;
      case ProButtonSize.large:
        return 24.sp;
    }
  }

  double _getLoaderSize() {
    switch (size) {
      case ProButtonSize.small:
        return 16.sp;
      case ProButtonSize.medium:
        return 20.sp;
      case ProButtonSize.large:
        return 24.sp;
    }
  }

  double _getMinHeight() {
    switch (size) {
      case ProButtonSize.small:
        return 36.h;
      case ProButtonSize.medium:
        return 44.h;
      case ProButtonSize.large:
        return 52.h;
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // Semantic Factories
  // ═══════════════════════════════════════════════════════════════════════════

  /// زر أساسي
  factory ProButton.primary({
    required String label,
    VoidCallback? onPressed,
    IconData? icon,
    bool iconAtEnd = false,
    ProButtonSize size = ProButtonSize.medium,
    bool isLoading = false,
    bool fullWidth = false,
  }) {
    return ProButton(
      label: label,
      onPressed: onPressed,
      icon: icon,
      iconAtEnd: iconAtEnd,
      type: ProButtonType.filled,
      size: size,
      color: AppColors.primary,
      isLoading: isLoading,
      fullWidth: fullWidth,
    );
  }

  /// زر ثانوي
  factory ProButton.secondary({
    required String label,
    VoidCallback? onPressed,
    IconData? icon,
    bool iconAtEnd = false,
    ProButtonSize size = ProButtonSize.medium,
    bool isLoading = false,
    bool fullWidth = false,
  }) {
    return ProButton(
      label: label,
      onPressed: onPressed,
      icon: icon,
      iconAtEnd: iconAtEnd,
      type: ProButtonType.filled,
      size: size,
      color: AppColors.secondary,
      isLoading: isLoading,
      fullWidth: fullWidth,
    );
  }

  /// زر نجاح
  factory ProButton.success({
    required String label,
    VoidCallback? onPressed,
    IconData? icon,
    bool iconAtEnd = false,
    ProButtonSize size = ProButtonSize.medium,
    bool isLoading = false,
    bool fullWidth = false,
  }) {
    return ProButton(
      label: label,
      onPressed: onPressed,
      icon: icon,
      iconAtEnd: iconAtEnd,
      type: ProButtonType.filled,
      size: size,
      color: AppColors.success,
      isLoading: isLoading,
      fullWidth: fullWidth,
    );
  }

  /// زر خطر
  factory ProButton.danger({
    required String label,
    VoidCallback? onPressed,
    IconData? icon,
    bool iconAtEnd = false,
    ProButtonSize size = ProButtonSize.medium,
    bool isLoading = false,
    bool fullWidth = false,
  }) {
    return ProButton(
      label: label,
      onPressed: onPressed,
      icon: icon,
      iconAtEnd: iconAtEnd,
      type: ProButtonType.filled,
      size: size,
      color: AppColors.error,
      isLoading: isLoading,
      fullWidth: fullWidth,
    );
  }

  /// زر تحذير
  factory ProButton.warning({
    required String label,
    VoidCallback? onPressed,
    IconData? icon,
    bool iconAtEnd = false,
    ProButtonSize size = ProButtonSize.medium,
    bool isLoading = false,
    bool fullWidth = false,
  }) {
    return ProButton(
      label: label,
      onPressed: onPressed,
      icon: icon,
      iconAtEnd: iconAtEnd,
      type: ProButtonType.filled,
      size: size,
      color: AppColors.warning,
      isLoading: isLoading,
      fullWidth: fullWidth,
    );
  }

  /// زر مخطط (outline)
  factory ProButton.outline({
    required String label,
    VoidCallback? onPressed,
    IconData? icon,
    bool iconAtEnd = false,
    ProButtonSize size = ProButtonSize.medium,
    Color? color,
    bool isLoading = false,
    bool fullWidth = false,
  }) {
    return ProButton(
      label: label,
      onPressed: onPressed,
      icon: icon,
      iconAtEnd: iconAtEnd,
      type: ProButtonType.outlined,
      size: size,
      color: color ?? AppColors.primary,
      isLoading: isLoading,
      fullWidth: fullWidth,
    );
  }

  /// زر نصي
  factory ProButton.text({
    required String label,
    VoidCallback? onPressed,
    IconData? icon,
    bool iconAtEnd = false,
    ProButtonSize size = ProButtonSize.medium,
    Color? color,
    bool isLoading = false,
  }) {
    return ProButton(
      label: label,
      onPressed: onPressed,
      icon: icon,
      iconAtEnd: iconAtEnd,
      type: ProButtonType.text,
      size: size,
      color: color ?? AppColors.primary,
      isLoading: isLoading,
    );
  }

  /// زر إلغاء
  factory ProButton.cancel({
    String label = 'إلغاء',
    VoidCallback? onPressed,
    ProButtonSize size = ProButtonSize.medium,
  }) {
    return ProButton(
      label: label,
      onPressed: onPressed,
      type: ProButtonType.text,
      size: size,
      color: AppColors.textSecondary,
    );
  }
}

/// زر أيقونة دائري
class ProIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onPressed;
  final Color? color;
  final Color? backgroundColor;
  final double? size;
  final double? iconSize;
  final bool outlined;
  final String? tooltip;

  const ProIconButton({
    super.key,
    required this.icon,
    this.onPressed,
    this.color,
    this.backgroundColor,
    this.size,
    this.iconSize,
    this.outlined = false,
    this.tooltip,
  });

  @override
  Widget build(BuildContext context) {
    final buttonColor = color ?? AppColors.textSecondary;
    final bgColor = backgroundColor ?? Colors.transparent;
    final btnSize = size ?? 40.w;
    final icoSize = iconSize ?? 24.sp;

    Widget button = Material(
      color: outlined ? Colors.transparent : bgColor,
      borderRadius: BorderRadius.circular(AppRadius.md),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(AppRadius.md),
        child: Container(
          width: btnSize,
          height: btnSize,
          decoration: outlined
              ? BoxDecoration(
                  border: Border.all(color: buttonColor.withValues(alpha: 0.3)),
                  borderRadius: BorderRadius.circular(AppRadius.md),
                )
              : null,
          child: Icon(icon, color: buttonColor, size: icoSize),
        ),
      ),
    );

    if (tooltip != null) {
      return Tooltip(message: tooltip!, child: button);
    }

    return button;
  }

  /// زر العودة
  factory ProIconButton.back({
    VoidCallback? onPressed,
    Color? color,
  }) {
    return ProIconButton(
      icon: Icons.arrow_back_ios_rounded,
      onPressed: onPressed,
      color: color ?? AppColors.textSecondary,
      iconSize: 20.sp,
    );
  }

  /// زر الإغلاق
  factory ProIconButton.close({
    VoidCallback? onPressed,
    Color? color,
  }) {
    return ProIconButton(
      icon: Icons.close_rounded,
      onPressed: onPressed,
      color: color ?? AppColors.textSecondary,
    );
  }

  /// زر المزيد (more)
  factory ProIconButton.more({
    VoidCallback? onPressed,
    Color? color,
  }) {
    return ProIconButton(
      icon: Icons.more_vert_rounded,
      onPressed: onPressed,
      color: color ?? AppColors.textSecondary,
    );
  }

  /// زر الإضافة
  factory ProIconButton.add({
    VoidCallback? onPressed,
    Color? color,
  }) {
    return ProIconButton(
      icon: Icons.add_rounded,
      onPressed: onPressed,
      color: color ?? AppColors.primary,
    );
  }

  /// زر الحذف
  factory ProIconButton.delete({
    VoidCallback? onPressed,
  }) {
    return ProIconButton(
      icon: Icons.delete_outline_rounded,
      onPressed: onPressed,
      color: AppColors.error,
    );
  }

  /// زر التعديل
  factory ProIconButton.edit({
    VoidCallback? onPressed,
    Color? color,
  }) {
    return ProIconButton(
      icon: Icons.edit_outlined,
      onPressed: onPressed,
      color: color ?? AppColors.primary,
    );
  }
}
