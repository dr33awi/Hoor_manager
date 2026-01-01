import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../design_tokens.dart';
import '../typography.dart';

/// ═══════════════════════════════════════════════════════════════════════════
/// HoorLoading - Loading State Components
/// Professional loading indicators and overlays
/// ═══════════════════════════════════════════════════════════════════════════

class HoorLoading extends StatelessWidget {
  final HoorLoadingSize size;
  final Color? color;
  final String? message;

  const HoorLoading({
    super.key,
    this.size = HoorLoadingSize.medium,
    this.color,
    this.message,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveColor = color ?? HoorColors.primary;

    return Column(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        SizedBox(
          width: _getSize(),
          height: _getSize(),
          child: CircularProgressIndicator(
            strokeWidth: _getStrokeWidth(),
            valueColor: AlwaysStoppedAnimation(effectiveColor),
          ),
        ),
        if (message != null) ...[
          SizedBox(height: HoorSpacing.md),
          Text(
            message!,
            style: HoorTypography.bodyMedium.copyWith(
              color: HoorColors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ],
    );
  }

  double _getSize() {
    switch (size) {
      case HoorLoadingSize.small:
        return 20.w;
      case HoorLoadingSize.medium:
        return 36.w;
      case HoorLoadingSize.large:
        return 48.w;
    }
  }

  double _getStrokeWidth() {
    switch (size) {
      case HoorLoadingSize.small:
        return 2.w;
      case HoorLoadingSize.medium:
        return 3.w;
      case HoorLoadingSize.large:
        return 4.w;
    }
  }
}

enum HoorLoadingSize {
  small,
  medium,
  large,
}

/// ═══════════════════════════════════════════════════════════════════════════
/// Full Screen Loading Overlay
/// ═══════════════════════════════════════════════════════════════════════════

class HoorLoadingOverlay extends StatelessWidget {
  final bool isLoading;
  final Widget child;
  final String? message;
  final Color? backgroundColor;

  const HoorLoadingOverlay({
    super.key,
    required this.isLoading,
    required this.child,
    this.message,
    this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        child,
        if (isLoading)
          Positioned.fill(
            child: Container(
              color: backgroundColor ?? Colors.white.withValues(alpha: 0.8),
              child: Center(
                child: HoorLoading(
                  size: HoorLoadingSize.large,
                  message: message,
                ),
              ),
            ),
          ),
      ],
    );
  }
}

/// ═══════════════════════════════════════════════════════════════════════════
/// Button Loading State
/// ═══════════════════════════════════════════════════════════════════════════

class HoorLoadingButton extends StatelessWidget {
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
  Widget build(BuildContext context) {
    final bgColor = backgroundColor ?? HoorColors.primary;
    final fgColor = foregroundColor ?? HoorColors.textOnPrimary;

    return SizedBox(
      width: isFullWidth ? double.infinity : null,
      height: 48.h,
      child: ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: bgColor,
          foregroundColor: fgColor,
          disabledBackgroundColor: bgColor.withValues(alpha: 0.7),
          disabledForegroundColor: fgColor.withValues(alpha: 0.7),
        ),
        child: isLoading
            ? SizedBox(
                width: 20.w,
                height: 20.w,
                child: CircularProgressIndicator(
                  strokeWidth: 2.w,
                  valueColor: AlwaysStoppedAnimation(fgColor),
                ),
              )
            : Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (icon != null) ...[
                    Icon(icon, size: HoorIconSize.md),
                    SizedBox(width: HoorSpacing.xs),
                  ],
                  Text(label),
                ],
              ),
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
