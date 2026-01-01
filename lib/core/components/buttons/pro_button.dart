// ═══════════════════════════════════════════════════════════════════════════
// Pro Button Component
// Modern, accessible button with multiple variants
// ═══════════════════════════════════════════════════════════════════════════

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../theme/pro/design_tokens.dart';

/// Button variants
enum ProButtonVariant {
  primary, // Filled with primary color
  secondary, // Filled with secondary color
  outlined, // Bordered
  ghost, // Text only
  danger, // Red for destructive actions
}

/// Button sizes
enum ProButtonSize {
  small,
  medium,
  large,
}

class ProButton extends StatefulWidget {
  const ProButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.variant = ProButtonVariant.primary,
    this.size = ProButtonSize.medium,
    this.icon,
    this.iconPosition = IconPosition.start,
    this.isLoading = false,
    this.isDisabled = false,
    this.isExpanded = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final ProButtonVariant variant;
  final ProButtonSize size;
  final IconData? icon;
  final IconPosition iconPosition;
  final bool isLoading;
  final bool isDisabled;
  final bool isExpanded;

  @override
  State<ProButton> createState() => _ProButtonState();
}

enum IconPosition { start, end }

class _ProButtonState extends State<ProButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: AppDurations.instant,
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.97).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleTapDown(TapDownDetails details) {
    if (!widget.isDisabled && !widget.isLoading) {
      _controller.forward();
    }
  }

  void _handleTapUp(TapUpDetails details) {
    _controller.reverse();
  }

  void _handleTapCancel() {
    _controller.reverse();
  }

  @override
  Widget build(BuildContext context) {
    final isDisabled = widget.isDisabled || widget.isLoading;
    final styles = _getStyles();

    return GestureDetector(
      onTapDown: _handleTapDown,
      onTapUp: _handleTapUp,
      onTapCancel: _handleTapCancel,
      child: AnimatedBuilder(
        animation: _scaleAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: child,
          );
        },
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: isDisabled
                ? null
                : () {
                    HapticFeedback.lightImpact();
                    widget.onPressed?.call();
                  },
            borderRadius: BorderRadius.circular(styles.radius),
            child: AnimatedContainer(
              duration: AppDurations.fast,
              padding: styles.padding,
              constraints: BoxConstraints(
                minWidth: widget.isExpanded ? double.infinity : 88.w,
                minHeight: styles.height,
              ),
              decoration: BoxDecoration(
                color: isDisabled
                    ? styles.backgroundColor.withValues(alpha: 0.5)
                    : styles.backgroundColor,
                borderRadius: BorderRadius.circular(styles.radius),
                border: styles.border,
                boxShadow: isDisabled ? null : styles.shadow,
              ),
              child: Row(
                mainAxisSize:
                    widget.isExpanded ? MainAxisSize.max : MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (widget.isLoading)
                    _buildLoadingIndicator(styles)
                  else ...[
                    if (widget.icon != null &&
                        widget.iconPosition == IconPosition.start) ...[
                      Icon(
                        widget.icon,
                        color: isDisabled
                            ? styles.foregroundColor.withValues(alpha: 0.5)
                            : styles.foregroundColor,
                        size: styles.iconSize,
                      ),
                      SizedBox(width: AppSpacing.xs.w),
                    ],
                    Text(
                      widget.label,
                      style: styles.textStyle.copyWith(
                        color: isDisabled
                            ? styles.foregroundColor.withValues(alpha: 0.5)
                            : styles.foregroundColor,
                      ),
                    ),
                    if (widget.icon != null &&
                        widget.iconPosition == IconPosition.end) ...[
                      SizedBox(width: AppSpacing.xs.w),
                      Icon(
                        widget.icon,
                        color: isDisabled
                            ? styles.foregroundColor.withValues(alpha: 0.5)
                            : styles.foregroundColor,
                        size: styles.iconSize,
                      ),
                    ],
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingIndicator(_ButtonStyles styles) {
    return SizedBox(
      width: styles.iconSize,
      height: styles.iconSize,
      child: CircularProgressIndicator(
        strokeWidth: 2.w,
        valueColor: AlwaysStoppedAnimation<Color>(
          styles.foregroundColor.withValues(alpha: 0.7),
        ),
      ),
    );
  }

  _ButtonStyles _getStyles() {
    // Size-based values
    final (height, padding, textStyle, iconSize, radius) =
        switch (widget.size) {
      ProButtonSize.small => (
          36.h,
          EdgeInsets.symmetric(horizontal: AppSpacing.md.w),
          AppTypography.labelSmall,
          AppIconSize.sm,
          AppRadius.sm,
        ),
      ProButtonSize.medium => (
          48.h,
          EdgeInsets.symmetric(horizontal: AppSpacing.lg.w),
          AppTypography.labelMedium,
          AppIconSize.md,
          AppRadius.md,
        ),
      ProButtonSize.large => (
          56.h,
          EdgeInsets.symmetric(horizontal: AppSpacing.xl.w),
          AppTypography.labelLarge,
          AppIconSize.md,
          AppRadius.md,
        ),
    };

    // Variant-based colors
    final (bgColor, fgColor, border, shadow) = switch (widget.variant) {
      ProButtonVariant.primary => (
          AppColors.primary,
          AppColors.textOnPrimary,
          null as Border?,
          AppShadows.sm,
        ),
      ProButtonVariant.secondary => (
          AppColors.secondary,
          AppColors.textOnSecondary,
          null,
          AppShadows.colored(AppColors.secondary, opacity: 0.25),
        ),
      ProButtonVariant.outlined => (
          Colors.transparent,
          AppColors.primary,
          Border.all(color: AppColors.border, width: 1.5),
          null as List<BoxShadow>?,
        ),
      ProButtonVariant.ghost => (
          Colors.transparent,
          AppColors.secondary,
          null,
          null,
        ),
      ProButtonVariant.danger => (
          AppColors.expense,
          AppColors.textOnPrimary,
          null,
          AppShadows.colored(AppColors.expense, opacity: 0.25),
        ),
    };

    return _ButtonStyles(
      height: height,
      padding: padding,
      textStyle: textStyle,
      iconSize: iconSize,
      radius: radius,
      backgroundColor: bgColor,
      foregroundColor: fgColor,
      border: border,
      shadow: shadow,
    );
  }
}

class _ButtonStyles {
  const _ButtonStyles({
    required this.height,
    required this.padding,
    required this.textStyle,
    required this.iconSize,
    required this.radius,
    required this.backgroundColor,
    required this.foregroundColor,
    this.border,
    this.shadow,
  });

  final double height;
  final EdgeInsets padding;
  final TextStyle textStyle;
  final double iconSize;
  final double radius;
  final Color backgroundColor;
  final Color foregroundColor;
  final Border? border;
  final List<BoxShadow>? shadow;
}

/// Icon-only button variant
class ProIconButton extends StatelessWidget {
  const ProIconButton({
    super.key,
    required this.icon,
    required this.onPressed,
    this.variant = ProButtonVariant.ghost,
    this.size = ProButtonSize.medium,
    this.tooltip,
    this.badge,
    this.isDisabled = false,
  });

  final IconData icon;
  final VoidCallback? onPressed;
  final ProButtonVariant variant;
  final ProButtonSize size;
  final String? tooltip;
  final int? badge;
  final bool isDisabled;

  @override
  Widget build(BuildContext context) {
    final buttonSize = switch (size) {
      ProButtonSize.small => 32.w,
      ProButtonSize.medium => 44.w,
      ProButtonSize.large => 52.w,
    };

    final iconSize = switch (size) {
      ProButtonSize.small => AppIconSize.sm,
      ProButtonSize.medium => AppIconSize.md,
      ProButtonSize.large => AppIconSize.lg,
    };

    final (bgColor, fgColor, border) = switch (variant) {
      ProButtonVariant.primary => (
          AppColors.primary,
          AppColors.textOnPrimary,
          null as Border?,
        ),
      ProButtonVariant.secondary => (
          AppColors.secondary,
          AppColors.textOnSecondary,
          null,
        ),
      ProButtonVariant.outlined => (
          Colors.transparent,
          AppColors.textSecondary,
          Border.all(color: AppColors.border),
        ),
      ProButtonVariant.ghost => (
          AppColors.surfaceMuted,
          AppColors.textSecondary,
          null,
        ),
      ProButtonVariant.danger => (
          AppColors.expense,
          AppColors.textOnPrimary,
          null,
        ),
    };

    Widget button = Material(
      color: isDisabled ? bgColor.withValues(alpha: 0.5) : bgColor,
      borderRadius: BorderRadius.circular(AppRadius.lg),
      child: InkWell(
        onTap: isDisabled
            ? null
            : () {
                HapticFeedback.lightImpact();
                onPressed?.call();
              },
        borderRadius: BorderRadius.circular(AppRadius.lg),
        child: Container(
          width: buttonSize,
          height: buttonSize,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadius.lg),
            border: border,
          ),
          child: badge != null && badge! > 0
              ? Badge(
                  label: Text(badge! > 99 ? '99+' : badge.toString()),
                  child: Icon(
                    icon,
                    color:
                        isDisabled ? fgColor.withValues(alpha: 0.5) : fgColor,
                    size: iconSize,
                  ),
                )
              : Icon(
                  icon,
                  color: isDisabled ? fgColor.withValues(alpha: 0.5) : fgColor,
                  size: iconSize,
                ),
        ),
      ),
    );

    if (tooltip != null) {
      return Tooltip(
        message: tooltip!,
        child: button,
      );
    }

    return button;
  }
}
