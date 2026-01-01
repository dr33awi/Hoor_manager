import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../design_tokens.dart';
import '../typography.dart';

/// ═══════════════════════════════════════════════════════════════════════════
/// HoorButton - Professional Button Components
/// Modern, accessible buttons with multiple variants
/// ═══════════════════════════════════════════════════════════════════════════

enum HoorButtonVariant {
  /// Primary action button
  primary,

  /// Secondary action button
  secondary,

  /// Outlined button
  outline,

  /// Ghost/text button
  ghost,

  /// Destructive action
  destructive,

  /// Success action
  success,
}

enum HoorButtonSize {
  small,
  medium,
  large,
}

class HoorButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final HoorButtonVariant variant;
  final HoorButtonSize size;
  final IconData? leadingIcon;
  final IconData? trailingIcon;
  final bool isLoading;
  final bool isFullWidth;
  final bool isDisabled;

  const HoorButton({
    super.key,
    required this.label,
    this.onPressed,
    this.variant = HoorButtonVariant.primary,
    this.size = HoorButtonSize.medium,
    this.leadingIcon,
    this.trailingIcon,
    this.isLoading = false,
    this.isFullWidth = false,
    this.isDisabled = false,
  });

  @override
  Widget build(BuildContext context) {
    final isEnabled = !isDisabled && !isLoading && onPressed != null;

    return SizedBox(
      width: isFullWidth ? double.infinity : null,
      height: _getHeight(),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: isEnabled ? onPressed : null,
          borderRadius: HoorRadius.buttonRadius,
          child: AnimatedContainer(
            duration: HoorDurations.fast,
            padding: _getPadding(),
            decoration: _getDecoration(isEnabled),
            child: Row(
              mainAxisSize: isFullWidth ? MainAxisSize.max : MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (isLoading) ...[
                  SizedBox(
                    width: _getIconSize(),
                    height: _getIconSize(),
                    child: CircularProgressIndicator(
                      strokeWidth: 2.w,
                      valueColor:
                          AlwaysStoppedAnimation(_getTextColor(isEnabled)),
                    ),
                  ),
                  SizedBox(width: HoorSpacing.sm.w),
                ] else if (leadingIcon != null) ...[
                  Icon(
                    leadingIcon,
                    size: _getIconSize(),
                    color: _getTextColor(isEnabled),
                  ),
                  SizedBox(width: HoorSpacing.sm.w),
                ],
                Text(
                  label,
                  style: _getTextStyle(isEnabled),
                ),
                if (trailingIcon != null && !isLoading) ...[
                  SizedBox(width: HoorSpacing.sm.w),
                  Icon(
                    trailingIcon,
                    size: _getIconSize(),
                    color: _getTextColor(isEnabled),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  double _getHeight() {
    switch (size) {
      case HoorButtonSize.small:
        return 36.h;
      case HoorButtonSize.medium:
        return 44.h;
      case HoorButtonSize.large:
        return 52.h;
    }
  }

  EdgeInsets _getPadding() {
    switch (size) {
      case HoorButtonSize.small:
        return EdgeInsets.symmetric(horizontal: HoorSpacing.md.w);
      case HoorButtonSize.medium:
        return EdgeInsets.symmetric(horizontal: HoorSpacing.lg.w);
      case HoorButtonSize.large:
        return EdgeInsets.symmetric(horizontal: HoorSpacing.xl.w);
    }
  }

  double _getIconSize() {
    switch (size) {
      case HoorButtonSize.small:
        return HoorIconSize.sm;
      case HoorButtonSize.medium:
        return HoorIconSize.md;
      case HoorButtonSize.large:
        return HoorIconSize.lg;
    }
  }

  BoxDecoration _getDecoration(bool isEnabled) {
    final opacity = isEnabled ? 1.0 : 0.5;

    switch (variant) {
      case HoorButtonVariant.primary:
        return BoxDecoration(
          color: HoorColors.primary.withValues(alpha: opacity),
          borderRadius: HoorRadius.buttonRadius,
        );

      case HoorButtonVariant.secondary:
        return BoxDecoration(
          color: HoorColors.accent.withValues(alpha: opacity),
          borderRadius: HoorRadius.buttonRadius,
        );

      case HoorButtonVariant.outline:
        return BoxDecoration(
          color: Colors.transparent,
          borderRadius: HoorRadius.buttonRadius,
          border: Border.all(
            color: HoorColors.border.withValues(alpha: opacity),
            width: 1.5.w,
          ),
        );

      case HoorButtonVariant.ghost:
        return BoxDecoration(
          color: Colors.transparent,
          borderRadius: HoorRadius.buttonRadius,
        );

      case HoorButtonVariant.destructive:
        return BoxDecoration(
          color: HoorColors.error.withValues(alpha: opacity),
          borderRadius: HoorRadius.buttonRadius,
        );

      case HoorButtonVariant.success:
        return BoxDecoration(
          color: HoorColors.success.withValues(alpha: opacity),
          borderRadius: HoorRadius.buttonRadius,
        );
    }
  }

  Color _getTextColor(bool isEnabled) {
    final opacity = isEnabled ? 1.0 : 0.6;

    switch (variant) {
      case HoorButtonVariant.primary:
      case HoorButtonVariant.destructive:
      case HoorButtonVariant.success:
        return HoorColors.textOnPrimary.withValues(alpha: opacity);

      case HoorButtonVariant.secondary:
        return HoorColors.primary.withValues(alpha: opacity);

      case HoorButtonVariant.outline:
      case HoorButtonVariant.ghost:
        return HoorColors.primary.withValues(alpha: opacity);
    }
  }

  TextStyle _getTextStyle(bool isEnabled) {
    final baseStyle = size == HoorButtonSize.small
        ? HoorTypography.buttonSmall
        : size == HoorButtonSize.large
            ? HoorTypography.buttonLarge
            : HoorTypography.buttonMedium;

    return baseStyle.copyWith(color: _getTextColor(isEnabled));
  }
}

/// ═══════════════════════════════════════════════════════════════════════════
/// Icon Button Variants
/// ═══════════════════════════════════════════════════════════════════════════

class HoorIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onPressed;
  final HoorButtonVariant variant;
  final HoorButtonSize size;
  final String? tooltip;
  final bool isLoading;
  final Color? color;
  final Color? backgroundColor;

  const HoorIconButton({
    super.key,
    required this.icon,
    this.onPressed,
    this.variant = HoorButtonVariant.ghost,
    this.size = HoorButtonSize.medium,
    this.tooltip,
    this.isLoading = false,
    this.color,
    this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    final isEnabled = !isLoading && onPressed != null;
    final dimension = _getDimension();

    Widget button = Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: isEnabled ? onPressed : null,
        borderRadius: BorderRadius.circular(dimension / 2),
        child: Container(
          width: dimension,
          height: dimension,
          decoration: _getDecoration(isEnabled),
          child: Center(
            child: isLoading
                ? SizedBox(
                    width: _getIconSize() - 4.w,
                    height: _getIconSize() - 4.w,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.w,
                      valueColor:
                          AlwaysStoppedAnimation(_getIconColor(isEnabled)),
                    ),
                  )
                : Icon(
                    icon,
                    size: _getIconSize(),
                    color: _getIconColor(isEnabled),
                  ),
          ),
        ),
      ),
    );

    if (tooltip != null) {
      button = Tooltip(message: tooltip!, child: button);
    }

    return button;
  }

  double _getDimension() {
    switch (size) {
      case HoorButtonSize.small:
        return 32.w;
      case HoorButtonSize.medium:
        return 40.w;
      case HoorButtonSize.large:
        return 48.w;
    }
  }

  double _getIconSize() {
    switch (size) {
      case HoorButtonSize.small:
        return HoorIconSize.sm;
      case HoorButtonSize.medium:
        return HoorIconSize.md;
      case HoorButtonSize.large:
        return HoorIconSize.lg;
    }
  }

  BoxDecoration _getDecoration(bool isEnabled) {
    final opacity = isEnabled ? 1.0 : 0.5;

    if (backgroundColor != null) {
      return BoxDecoration(
        color: backgroundColor!.withValues(alpha: opacity),
        shape: BoxShape.circle,
      );
    }

    switch (variant) {
      case HoorButtonVariant.primary:
        return BoxDecoration(
          color: HoorColors.primary.withValues(alpha: opacity),
          shape: BoxShape.circle,
        );

      case HoorButtonVariant.secondary:
        return BoxDecoration(
          color: HoorColors.accent.withValues(alpha: opacity),
          shape: BoxShape.circle,
        );

      case HoorButtonVariant.outline:
        return BoxDecoration(
          color: Colors.transparent,
          shape: BoxShape.circle,
          border: Border.all(
            color: HoorColors.border.withValues(alpha: opacity),
            width: 1.5.w,
          ),
        );

      case HoorButtonVariant.ghost:
        return const BoxDecoration(
          color: Colors.transparent,
          shape: BoxShape.circle,
        );

      case HoorButtonVariant.destructive:
        return BoxDecoration(
          color: HoorColors.error.withValues(alpha: opacity),
          shape: BoxShape.circle,
        );

      case HoorButtonVariant.success:
        return BoxDecoration(
          color: HoorColors.success.withValues(alpha: opacity),
          shape: BoxShape.circle,
        );
    }
  }

  Color _getIconColor(bool isEnabled) {
    final opacity = isEnabled ? 1.0 : 0.6;

    if (color != null) {
      return color!.withValues(alpha: opacity);
    }

    switch (variant) {
      case HoorButtonVariant.primary:
      case HoorButtonVariant.destructive:
      case HoorButtonVariant.success:
        return HoorColors.textOnPrimary.withValues(alpha: opacity);

      case HoorButtonVariant.secondary:
        return HoorColors.primary.withValues(alpha: opacity);

      case HoorButtonVariant.outline:
      case HoorButtonVariant.ghost:
        return HoorColors.textSecondary.withValues(alpha: opacity);
    }
  }
}

/// ═══════════════════════════════════════════════════════════════════════════
/// FAB Variants
/// ═══════════════════════════════════════════════════════════════════════════

class HoorFAB extends StatelessWidget {
  final IconData icon;
  final VoidCallback onPressed;
  final String? label;
  final bool isExtended;
  final Color? backgroundColor;
  final Color? foregroundColor;

  const HoorFAB({
    super.key,
    required this.icon,
    required this.onPressed,
    this.label,
    this.isExtended = false,
    this.backgroundColor,
    this.foregroundColor,
  });

  @override
  Widget build(BuildContext context) {
    final bgColor = backgroundColor ?? HoorColors.primary;
    final fgColor = foregroundColor ?? HoorColors.textOnPrimary;

    if (isExtended && label != null) {
      return FloatingActionButton.extended(
        onPressed: onPressed,
        backgroundColor: bgColor,
        foregroundColor: fgColor,
        elevation: 4,
        icon: Icon(icon),
        label: Text(label!),
      );
    }

    return FloatingActionButton(
      onPressed: onPressed,
      backgroundColor: bgColor,
      foregroundColor: fgColor,
      elevation: 4,
      child: Icon(icon),
    );
  }
}
