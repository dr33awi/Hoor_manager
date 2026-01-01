import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../design_tokens.dart';
import '../typography.dart';

/// ═══════════════════════════════════════════════════════════════════════════
/// HoorLoading - Premium Animated Loading State Components
/// Modern loading indicators with smooth animations
/// ═══════════════════════════════════════════════════════════════════════════

class HoorLoading extends StatefulWidget {
  final HoorLoadingSize size;
  final Color? color;
  final String? message;
  final HoorLoadingStyle style;

  const HoorLoading({
    super.key,
    this.size = HoorLoadingSize.medium,
    this.color,
    this.message,
    this.style = HoorLoadingStyle.circular,
  });

  @override
  State<HoorLoading> createState() => _HoorLoadingState();
}

class _HoorLoadingState extends State<HoorLoading>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _rotationAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat();

    _rotationAnimation = Tween<double>(begin: 0.0, end: 2 * math.pi).animate(
      CurvedAnimation(parent: _controller, curve: Curves.linear),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final effectiveColor = widget.color ?? HoorColors.primary;

    return Column(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        widget.style == HoorLoadingStyle.gradient
            ? _buildGradientLoader(effectiveColor)
            : _buildCircularLoader(effectiveColor),
        if (widget.message != null) ...[
          SizedBox(height: HoorSpacing.lg),
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0.0, end: 1.0),
            duration: HoorDurations.normal,
            builder: (context, value, child) {
              return Opacity(
                opacity: value,
                child: Text(
                  widget.message!,
                  style: HoorTypography.bodyMedium.copyWith(
                    color: HoorColors.textSecondary,
                  ),
                  textAlign: TextAlign.center,
                ),
              );
            },
          ),
        ],
      ],
    );
  }

  Widget _buildCircularLoader(Color color) {
    return SizedBox(
      width: _getSize(),
      height: _getSize(),
      child: CircularProgressIndicator(
        strokeWidth: _getStrokeWidth(),
        valueColor: AlwaysStoppedAnimation(color),
        strokeCap: StrokeCap.round,
      ),
    );
  }

  Widget _buildGradientLoader(Color color) {
    return AnimatedBuilder(
      animation: _rotationAnimation,
      builder: (context, child) {
        return Transform.rotate(
          angle: _rotationAnimation.value,
          child: Container(
            width: _getSize(),
            height: _getSize(),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: SweepGradient(
                colors: [
                  color.withValues(alpha: 0.0),
                  color.withValues(alpha: 0.2),
                  color.withValues(alpha: 0.5),
                  color,
                ],
                stops: const [0.0, 0.25, 0.5, 1.0],
              ),
            ),
            child: Padding(
              padding: EdgeInsets.all(_getStrokeWidth() * 1.5),
              child: Container(
                decoration: BoxDecoration(
                  color: HoorColors.surface,
                  shape: BoxShape.circle,
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  double _getSize() {
    switch (widget.size) {
      case HoorLoadingSize.small:
        return 24.w;
      case HoorLoadingSize.medium:
        return 40.w;
      case HoorLoadingSize.large:
        return 56.w;
    }
  }

  double _getStrokeWidth() {
    switch (widget.size) {
      case HoorLoadingSize.small:
        return 2.5.w;
      case HoorLoadingSize.medium:
        return 3.5.w;
      case HoorLoadingSize.large:
        return 4.5.w;
    }
  }
}

enum HoorLoadingSize {
  small,
  medium,
  large,
}

enum HoorLoadingStyle {
  circular,
  gradient,
}

/// ═══════════════════════════════════════════════════════════════════════════
/// Full Screen Loading Overlay - Premium Animated
/// ═══════════════════════════════════════════════════════════════════════════

class HoorLoadingOverlay extends StatelessWidget {
  final bool isLoading;
  final Widget child;
  final String? message;
  final Color? backgroundColor;
  final bool enableBlur;

  const HoorLoadingOverlay({
    super.key,
    required this.isLoading,
    required this.child,
    this.message,
    this.backgroundColor,
    this.enableBlur = false,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        child,
        AnimatedSwitcher(
          duration: HoorDurations.normal,
          child: isLoading
              ? Container(
                  key: const ValueKey('loading'),
                  color: backgroundColor ??
                      (enableBlur
                          ? Colors.black.withValues(alpha: 0.3)
                          : HoorColors.surface.withValues(alpha: 0.9)),
                  child: Center(
                    child: TweenAnimationBuilder<double>(
                      tween: Tween(begin: 0.8, end: 1.0),
                      duration: HoorDurations.normal,
                      curve: Curves.easeOutBack,
                      builder: (context, value, child) {
                        return Transform.scale(
                          scale: value,
                          child: Container(
                            padding: EdgeInsets.all(HoorSpacing.xl),
                            decoration: BoxDecoration(
                              color: HoorColors.surface,
                              borderRadius:
                                  BorderRadius.circular(HoorRadius.xl),
                              boxShadow: HoorShadows.lg,
                            ),
                            child: HoorLoading(
                              size: HoorLoadingSize.large,
                              message: message,
                              style: HoorLoadingStyle.gradient,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                )
              : const SizedBox.shrink(key: ValueKey('empty')),
        ),
      ],
    );
  }
}

/// ═══════════════════════════════════════════════════════════════════════════
/// Button Loading State - Animated
/// ═══════════════════════════════════════════════════════════════════════════

class HoorLoadingButton extends StatefulWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;
  final bool isFullWidth;
  final IconData? icon;
  final Color? backgroundColor;
  final Color? foregroundColor;

  const HoorLoadingButton({
    super.key,
    required this.label,
    this.onPressed,
    this.isLoading = false,
    this.isFullWidth = false,
    this.icon,
    this.backgroundColor,
    this.foregroundColor,
  });

  @override
  State<HoorLoadingButton> createState() => _HoorLoadingButtonState();
}

class _HoorLoadingButtonState extends State<HoorLoadingButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  bool _isPressed = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 100),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.96).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onTapDown(TapDownDetails details) {
    if (!widget.isLoading && widget.onPressed != null) {
      setState(() => _isPressed = true);
      _controller.forward();
    }
  }

  void _onTapUp(TapUpDetails details) {
    setState(() => _isPressed = false);
    _controller.reverse();
    if (!widget.isLoading) {
      widget.onPressed?.call();
    }
  }

  void _onTapCancel() {
    setState(() => _isPressed = false);
    _controller.reverse();
  }

  @override
  Widget build(BuildContext context) {
    final bgColor = widget.backgroundColor ?? HoorColors.primary;
    final fgColor = widget.foregroundColor ?? HoorColors.textOnPrimary;

    return GestureDetector(
      onTapDown: _onTapDown,
      onTapUp: _onTapUp,
      onTapCancel: _onTapCancel,
      child: AnimatedBuilder(
        animation: _scaleAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: AnimatedContainer(
              duration: HoorDurations.fast,
              width: widget.isFullWidth ? double.infinity : null,
              height: 52.h,
              padding: EdgeInsets.symmetric(horizontal: HoorSpacing.xl),
              decoration: BoxDecoration(
                color: widget.isLoading
                    ? bgColor.withValues(alpha: 0.85)
                    : _isPressed
                        ? bgColor.withValues(alpha: 0.9)
                        : bgColor,
                borderRadius: BorderRadius.circular(HoorRadius.lg),
                boxShadow: widget.isLoading || _isPressed
                    ? []
                    : HoorShadows.colored(bgColor, opacity: 0.3),
              ),
              child: Center(
                child: AnimatedSwitcher(
                  duration: HoorDurations.fast,
                  child: widget.isLoading
                      ? SizedBox(
                          key: const ValueKey('loading'),
                          width: 24.w,
                          height: 24.w,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5.w,
                            valueColor: AlwaysStoppedAnimation(fgColor),
                            strokeCap: StrokeCap.round,
                          ),
                        )
                      : Row(
                          key: const ValueKey('content'),
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (widget.icon != null) ...[
                              Icon(
                                widget.icon,
                                color: fgColor,
                                size: HoorIconSize.md,
                              ),
                              SizedBox(width: HoorSpacing.sm),
                            ],
                            Text(
                              widget.label,
                              style: HoorTypography.titleSmall.copyWith(
                                color: fgColor,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

/// ═══════════════════════════════════════════════════════════════════════════
/// Pull to Refresh Indicator
/// ═══════════════════════════════════════════════════════════════════════════

class HoorRefreshIndicator extends StatelessWidget {
  final Widget child;
  final Future<void> Function() onRefresh;
  final Color? color;
  final Color? backgroundColor;

  const HoorRefreshIndicator({
    super.key,
    required this.child,
    required this.onRefresh,
    this.color,
    this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: onRefresh,
      color: color ?? HoorColors.primary,
      backgroundColor: backgroundColor ?? HoorColors.surface,
      child: child,
    );
  }
}

/// ═══════════════════════════════════════════════════════════════════════════
/// Inline Loading (for lists, buttons, etc.)
/// ═══════════════════════════════════════════════════════════════════════════

class HoorInlineLoading extends StatelessWidget {
  final String? message;
  final Color? color;

  const HoorInlineLoading({
    super.key,
    this.message,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveColor = color ?? HoorColors.primary;

    return Padding(
      padding: EdgeInsets.all(HoorSpacing.md),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: 16.w,
            height: 16.w,
            child: CircularProgressIndicator(
              strokeWidth: 2.w,
              valueColor: AlwaysStoppedAnimation(effectiveColor),
            ),
          ),
          if (message != null) ...[
            SizedBox(width: HoorSpacing.sm),
            Text(
              message!,
              style: HoorTypography.bodySmall.copyWith(
                color: HoorColors.textSecondary,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// ═══════════════════════════════════════════════════════════════════════════
/// Pulsing Dot Loading
/// ═══════════════════════════════════════════════════════════════════════════

class HoorPulsingDots extends StatefulWidget {
  final Color? color;
  final double size;
  final int dotCount;

  const HoorPulsingDots({
    super.key,
    this.color,
    this.size = 8,
    this.dotCount = 3,
  });

  @override
  State<HoorPulsingDots> createState() => _HoorPulsingDotsState();
}

class _HoorPulsingDotsState extends State<HoorPulsingDots>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final effectiveColor = widget.color ?? HoorColors.primary;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(widget.dotCount, (index) {
        return AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            final delay = index * 0.2;
            final progress = (_controller.value - delay).clamp(0.0, 1.0);
            final scale = 0.5 + (0.5 * (1 - (progress * 2 - 1).abs()));

            return Container(
              margin: EdgeInsets.symmetric(horizontal: widget.size.w * 0.3),
              child: Transform.scale(
                scale: scale,
                child: Container(
                  width: widget.size.w,
                  height: widget.size.w,
                  decoration: BoxDecoration(
                    color: effectiveColor,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            );
          },
        );
      }),
    );
  }
}
