// ═══════════════════════════════════════════════════════════════════════════
// Pro Action Button Component
// Animated, Gradient, Multiple Styles
// ═══════════════════════════════════════════════════════════════════════════

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../theme/design_tokens.dart';

enum ProButtonStyle { primary, secondary, outlined, text, gradient, danger }

enum ProButtonSize { small, medium, large }

class ProActionButton extends StatefulWidget {
  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final ProButtonStyle style;
  final ProButtonSize size;
  final bool isLoading;
  final bool isExpanded;
  final List<Color>? gradientColors;

  const ProActionButton({
    super.key,
    required this.label,
    this.onPressed,
    this.icon,
    this.style = ProButtonStyle.primary,
    this.size = ProButtonSize.medium,
    this.isLoading = false,
    this.isExpanded = false,
    this.gradientColors,
  });

  @override
  State<ProActionButton> createState() => _ProActionButtonState();
}

class _ProActionButtonState extends State<ProActionButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
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

  double get _height {
    switch (widget.size) {
      case ProButtonSize.small:
        return 36.h;
      case ProButtonSize.medium:
        return 48.h;
      case ProButtonSize.large:
        return 56.h;
    }
  }

  double get _fontSize {
    switch (widget.size) {
      case ProButtonSize.small:
        return 12.sp;
      case ProButtonSize.medium:
        return 14.sp;
      case ProButtonSize.large:
        return 16.sp;
    }
  }

  double get _iconSize {
    switch (widget.size) {
      case ProButtonSize.small:
        return 16.sp;
      case ProButtonSize.medium:
        return 20.sp;
      case ProButtonSize.large:
        return 24.sp;
    }
  }

  EdgeInsets get _padding {
    switch (widget.size) {
      case ProButtonSize.small:
        return EdgeInsets.symmetric(horizontal: AppSpacing.md);
      case ProButtonSize.medium:
        return EdgeInsets.symmetric(horizontal: AppSpacing.lg);
      case ProButtonSize.large:
        return EdgeInsets.symmetric(horizontal: AppSpacing.xl);
    }
  }

  Color get _backgroundColor {
    switch (widget.style) {
      case ProButtonStyle.primary:
        return AppColors.primary;
      case ProButtonStyle.secondary:
        return AppColors.secondary;
      case ProButtonStyle.outlined:
      case ProButtonStyle.text:
        return Colors.transparent;
      case ProButtonStyle.gradient:
        return Colors.transparent;
      case ProButtonStyle.danger:
        return AppColors.error;
    }
  }

  Color get _foregroundColor {
    switch (widget.style) {
      case ProButtonStyle.primary:
      case ProButtonStyle.gradient:
      case ProButtonStyle.danger:
        return Colors.white;
      case ProButtonStyle.secondary:
        return AppColors.primary;
      case ProButtonStyle.outlined:
      case ProButtonStyle.text:
        return AppColors.primary;
    }
  }

  List<Color> get _gradientColors {
    if (widget.gradientColors != null) return widget.gradientColors!;
    return [AppColors.primary, AppColors.secondary];
  }

  @override
  Widget build(BuildContext context) {
    final isDisabled = widget.onPressed == null || widget.isLoading;

    return AnimatedBuilder(
      animation: _scaleAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: child,
        );
      },
      child: GestureDetector(
        onTapDown: isDisabled ? null : (_) => _controller.forward(),
        onTapUp: isDisabled ? null : (_) => _controller.reverse(),
        onTapCancel: () => _controller.reverse(),
        onTap: isDisabled ? null : widget.onPressed,
        child: AnimatedOpacity(
          duration: const Duration(milliseconds: 200),
          opacity: isDisabled ? 0.6 : 1.0,
          child: Container(
            height: _height,
            width: widget.isExpanded ? double.infinity : null,
            padding: _padding,
            decoration: _buildDecoration(),
            child: _buildContent(),
          ),
        ),
      ),
    );
  }

  BoxDecoration _buildDecoration() {
    if (widget.style == ProButtonStyle.gradient) {
      return BoxDecoration(
        gradient: LinearGradient(
          colors: _gradientColors,
          begin: Alignment.centerRight,
          end: Alignment.centerLeft,
        ),
        borderRadius: BorderRadius.circular(AppRadius.lg),
        boxShadow: [
          BoxShadow(
            color: _gradientColors.first.withValues(alpha: 0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      );
    }

    if (widget.style == ProButtonStyle.outlined) {
      return BoxDecoration(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(
          color: AppColors.primary,
          width: 1.5,
        ),
      );
    }

    if (widget.style == ProButtonStyle.text) {
      return BoxDecoration(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(AppRadius.lg),
      );
    }

    return BoxDecoration(
      color: _backgroundColor,
      borderRadius: BorderRadius.circular(AppRadius.lg),
      boxShadow: widget.style == ProButtonStyle.primary
          ? [
              BoxShadow(
                color: _backgroundColor.withValues(alpha: 0.25),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ]
          : null,
    );
  }

  Widget _buildContent() {
    if (widget.isLoading) {
      return Center(
        child: SizedBox(
          width: _iconSize,
          height: _iconSize,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            valueColor: AlwaysStoppedAnimation(_foregroundColor),
          ),
        ),
      );
    }

    return Row(
      mainAxisSize: widget.isExpanded ? MainAxisSize.max : MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (widget.icon != null) ...[
          Icon(
            widget.icon,
            size: _iconSize,
            color: _foregroundColor,
          ),
          SizedBox(width: AppSpacing.sm),
        ],
        Text(
          widget.label,
          style: TextStyle(
            fontSize: _fontSize,
            fontWeight: FontWeight.w600,
            color: _foregroundColor,
            fontFamily: 'Cairo',
          ),
        ),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// Icon Action Button
// ═══════════════════════════════════════════════════════════════════════════

class ProIconButton extends StatefulWidget {
  final IconData icon;
  final VoidCallback? onPressed;
  final Color? backgroundColor;
  final Color? iconColor;
  final double size;
  final String? tooltip;
  final bool hasBadge;
  final int? badgeCount;

  const ProIconButton({
    super.key,
    required this.icon,
    this.onPressed,
    this.backgroundColor,
    this.iconColor,
    this.size = 44,
    this.tooltip,
    this.hasBadge = false,
    this.badgeCount,
  });

  @override
  State<ProIconButton> createState() => _ProIconButtonState();
}

class _ProIconButtonState extends State<ProIconButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.9).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final button = GestureDetector(
      onTapDown: widget.onPressed == null ? null : (_) => _controller.forward(),
      onTapUp: widget.onPressed == null ? null : (_) => _controller.reverse(),
      onTapCancel: () => _controller.reverse(),
      onTap: widget.onPressed,
      child: AnimatedBuilder(
        animation: _scaleAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: child,
          );
        },
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Container(
              width: widget.size.w,
              height: widget.size.h,
              decoration: BoxDecoration(
                color: widget.backgroundColor ?? AppColors.surfaceVariant,
                borderRadius: BorderRadius.circular(AppRadius.md),
              ),
              child: Center(
                child: Icon(
                  widget.icon,
                  color: widget.iconColor ?? AppColors.textPrimary,
                  size: (widget.size * 0.5).sp,
                ),
              ),
            ),
            if (widget.hasBadge)
              Positioned(
                top: -4,
                right: -4,
                child: Container(
                  padding:
                      EdgeInsets.all(widget.badgeCount != null ? 4.w : 6.w),
                  decoration: const BoxDecoration(
                    color: AppColors.error,
                    shape: BoxShape.circle,
                  ),
                  child: widget.badgeCount != null
                      ? Text(
                          widget.badgeCount! > 99
                              ? '99+'
                              : widget.badgeCount.toString(),
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 10.sp,
                            fontWeight: FontWeight.bold,
                          ),
                        )
                      : null,
                ),
              ),
          ],
        ),
      ),
    );

    if (widget.tooltip != null) {
      return Tooltip(
        message: widget.tooltip!,
        child: button,
      );
    }

    return button;
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// Floating Action Button Pro
// ═══════════════════════════════════════════════════════════════════════════

class ProFloatingActionButton extends StatefulWidget {
  final IconData icon;
  final VoidCallback? onPressed;
  final List<Color>? gradientColors;
  final String? label;
  final bool isExtended;

  const ProFloatingActionButton({
    super.key,
    required this.icon,
    this.onPressed,
    this.gradientColors,
    this.label,
    this.isExtended = false,
  });

  @override
  State<ProFloatingActionButton> createState() =>
      _ProFloatingActionButtonState();
}

class _ProFloatingActionButtonState extends State<ProFloatingActionButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  List<Color> get _colors =>
      widget.gradientColors ?? [AppColors.primary, AppColors.secondary];

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: widget.onPressed == null ? null : (_) => _controller.forward(),
      onTapUp: widget.onPressed == null ? null : (_) => _controller.reverse(),
      onTapCancel: () => _controller.reverse(),
      onTap: widget.onPressed,
      child: AnimatedBuilder(
        animation: _scaleAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: child,
          );
        },
        child: Container(
          height: 56.h,
          padding: EdgeInsets.symmetric(
            horizontal: widget.isExtended ? AppSpacing.lg : AppSpacing.md,
          ),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: _colors,
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(
              widget.isExtended ? AppRadius.xl : AppRadius.full,
            ),
            boxShadow: [
              BoxShadow(
                color: _colors.first.withValues(alpha: 0.4),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                widget.icon,
                color: Colors.white,
                size: 24.sp,
              ),
              if (widget.isExtended && widget.label != null) ...[
                SizedBox(width: AppSpacing.sm),
                Text(
                  widget.label!,
                  style: AppTypography.titleSmall.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
