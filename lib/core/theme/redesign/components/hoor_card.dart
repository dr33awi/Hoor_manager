import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../design_tokens.dart';

/// ═══════════════════════════════════════════════════════════════════════════
/// HoorCard - Professional Animated Card Component
/// Clean, minimal card with smooth animations and modern effects
/// ═══════════════════════════════════════════════════════════════════════════

enum HoorCardVariant {
  /// Default card with subtle border
  outlined,

  /// Card with soft shadow
  elevated,

  /// Filled card without border
  filled,

  /// Card with accent color stripe
  accented,

  /// Gradient card
  gradient,

  /// Glass effect card
  glass,
}

class HoorCard extends StatefulWidget {
  final Widget child;
  final HoorCardVariant variant;
  final Color? accentColor;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final bool isSelected;
  final double? width;
  final double? height;
  final BorderRadius? borderRadius;
  final Gradient? gradient;
  final bool enableAnimation;

  const HoorCard({
    super.key,
    required this.child,
    this.variant = HoorCardVariant.outlined,
    this.accentColor,
    this.padding,
    this.margin,
    this.onTap,
    this.onLongPress,
    this.isSelected = false,
    this.width,
    this.height,
    this.borderRadius,
    this.gradient,
    this.enableAnimation = true,
  });

  @override
  State<HoorCard> createState() => _HoorCardState();
}

class _HoorCardState extends State<HoorCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  bool _isPressed = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.98).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onTapDown(TapDownDetails details) {
    if (widget.onTap != null && widget.enableAnimation) {
      setState(() => _isPressed = true);
      _controller.forward();
    }
  }

  void _onTapUp(TapUpDetails details) {
    setState(() => _isPressed = false);
    _controller.reverse();
  }

  void _onTapCancel() {
    setState(() => _isPressed = false);
    _controller.reverse();
  }

  @override
  Widget build(BuildContext context) {
    final effectiveBorderRadius =
        widget.borderRadius ?? BorderRadius.circular(HoorRadius.xl);

    Widget card = AnimatedBuilder(
      animation: _scaleAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: widget.enableAnimation ? _scaleAnimation.value : 1.0,
          child: AnimatedContainer(
            duration: HoorDurations.fast,
            width: widget.width,
            height: widget.height,
            decoration: _buildDecoration(effectiveBorderRadius),
            child: ClipRRect(
              borderRadius: effectiveBorderRadius,
              child: Stack(
                children: [
                  // Accent stripe for accented variant
                  if (widget.variant == HoorCardVariant.accented &&
                      widget.accentColor != null)
                    Positioned(
                      top: 0,
                      bottom: 0,
                      right: 0,
                      child: Container(
                        width: 4.w,
                        decoration: BoxDecoration(
                          color: widget.accentColor,
                          borderRadius: BorderRadius.only(
                            topRight: Radius.circular(HoorRadius.xl),
                            bottomRight: Radius.circular(HoorRadius.xl),
                          ),
                        ),
                      ),
                    ),
                  // Content
                  Padding(
                    padding: widget.padding ?? EdgeInsets.all(HoorSpacing.lg),
                    child: widget.child,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );

    // Wrap with GestureDetector if interactive
    if (widget.onTap != null || widget.onLongPress != null) {
      card = GestureDetector(
        onTapDown: _onTapDown,
        onTapUp: _onTapUp,
        onTapCancel: _onTapCancel,
        onTap: widget.onTap,
        onLongPress: widget.onLongPress,
        child: card,
      );
    }

    if (widget.margin != null) {
      card = Padding(padding: widget.margin!, child: card);
    }

    return card;
  }

  BoxDecoration _buildDecoration(BorderRadius radius) {
    switch (widget.variant) {
      case HoorCardVariant.outlined:
        return BoxDecoration(
          color:
              widget.isSelected ? HoorColors.primarySoft : HoorColors.surface,
          borderRadius: radius,
          border: Border.all(
            color: widget.isSelected
                ? HoorColors.primary
                : _isPressed
                    ? HoorColors.primary.withValues(alpha: 0.3)
                    : HoorColors.border,
            width: widget.isSelected ? 2.w : 1.w,
          ),
          boxShadow: _isPressed ? [] : HoorShadows.xs,
        );

      case HoorCardVariant.elevated:
        return BoxDecoration(
          color: HoorColors.surface,
          borderRadius: radius,
          boxShadow: _isPressed ? HoorShadows.sm : HoorShadows.lg,
        );

      case HoorCardVariant.filled:
        return BoxDecoration(
          color: widget.isSelected
              ? HoorColors.primarySoft
              : HoorColors.surfaceMuted,
          borderRadius: radius,
        );

      case HoorCardVariant.accented:
        return BoxDecoration(
          color: HoorColors.surface,
          borderRadius: radius,
          border: Border.all(color: HoorColors.border),
          boxShadow: HoorShadows.xs,
        );

      case HoorCardVariant.gradient:
        return BoxDecoration(
          gradient: widget.gradient ?? HoorColors.royalGradient,
          borderRadius: radius,
          boxShadow: _isPressed ? [] : HoorShadows.md,
        );

      case HoorCardVariant.glass:
        return BoxDecoration(
          color: Colors.white.withValues(alpha: 0.1),
          borderRadius: radius,
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.2),
            width: 1.5,
          ),
        );
    }
  }
}

/// ═══════════════════════════════════════════════════════════════════════════
/// Specialized Card Variants
/// ═══════════════════════════════════════════════════════════════════════════

/// Card for metrics and KPIs
class HoorMetricCard extends StatelessWidget {
  final String title;
  final String value;
  final String? subtitle;
  final IconData icon;
  final Color? color;
  final Widget? trend;
  final VoidCallback? onTap;

  const HoorMetricCard({
    super.key,
    required this.title,
    required this.value,
    this.subtitle,
    required this.icon,
    this.color,
    this.trend,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveColor = color ?? HoorColors.primary;

    return HoorCard(
      variant: HoorCardVariant.outlined,
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              _buildIconContainer(effectiveColor),
              const Spacer(),
              if (trend != null) trend!,
            ],
          ),
          SizedBox(height: HoorSpacing.md),
          Text(
            value,
            style: TextStyle(
              fontSize: 28.sp,
              fontWeight: FontWeight.w700,
              color: HoorColors.textPrimary,
              height: 1.1,
            ),
          ),
          SizedBox(height: HoorSpacing.xxs),
          Text(
            title,
            style: TextStyle(
              fontSize: 14.sp,
              color: HoorColors.textSecondary,
            ),
          ),
          if (subtitle != null) ...[
            SizedBox(height: HoorSpacing.xxs),
            Text(
              subtitle!,
              style: TextStyle(
                fontSize: 12.sp,
                color: HoorColors.textTertiary,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildIconContainer(Color color) {
    return Container(
      padding: EdgeInsets.all(HoorSpacing.sm),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(HoorRadius.md),
      ),
      child: Icon(
        icon,
        color: color,
        size: HoorIconSize.md,
      ),
    );
  }
}

/// Interactive action card
class HoorActionCard extends StatelessWidget {
  final String title;
  final String? description;
  final IconData icon;
  final Color? color;
  final VoidCallback onTap;
  final bool isCompact;

  const HoorActionCard({
    super.key,
    required this.title,
    this.description,
    required this.icon,
    this.color,
    required this.onTap,
    this.isCompact = false,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveColor = color ?? HoorColors.primary;

    if (isCompact) {
      return _buildCompact(effectiveColor);
    }

    return _buildFull(effectiveColor);
  }

  Widget _buildCompact(Color color) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: HoorRadius.cardRadius,
        child: Container(
          padding: EdgeInsets.all(HoorSpacing.md),
          decoration: BoxDecoration(
            color: HoorColors.surface,
            borderRadius: HoorRadius.cardRadius,
            border: Border.all(color: HoorColors.border),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: EdgeInsets.all(HoorSpacing.sm),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(HoorRadius.md),
                ),
                child: Icon(icon, color: color, size: HoorIconSize.lg),
              ),
              SizedBox(height: HoorSpacing.sm),
              Text(
                title,
                style: TextStyle(
                  fontSize: 13.sp,
                  fontWeight: FontWeight.w600,
                  color: HoorColors.textPrimary,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFull(Color color) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: HoorRadius.cardRadius,
        child: Container(
          padding: EdgeInsets.all(HoorSpacing.md),
          decoration: BoxDecoration(
            color: HoorColors.surface,
            borderRadius: HoorRadius.cardRadius,
            border: Border.all(color: HoorColors.border),
          ),
          child: Row(
            children: [
              Container(
                padding: EdgeInsets.all(HoorSpacing.sm),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(HoorRadius.md),
                ),
                child: Icon(icon, color: color, size: HoorIconSize.md),
              ),
              SizedBox(width: HoorSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w600,
                        color: HoorColors.textPrimary,
                      ),
                    ),
                    if (description != null) ...[
                      SizedBox(height: 2.h),
                      Text(
                        description!,
                        style: TextStyle(
                          fontSize: 12.sp,
                          color: HoorColors.textSecondary,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios_rounded,
                color: HoorColors.textTertiary,
                size: HoorIconSize.sm,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
