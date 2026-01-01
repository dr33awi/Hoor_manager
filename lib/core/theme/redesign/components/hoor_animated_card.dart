import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'dart:ui';
import '../design_tokens.dart';
import '../typography.dart';

/// ═══════════════════════════════════════════════════════════════════════════
/// HoorAnimatedCard - Modern Animated Card with Glassmorphism
/// Professional card with smooth animations and modern effects
/// ═══════════════════════════════════════════════════════════════════════════

class HoorAnimatedCard extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final Color? backgroundColor;
  final Gradient? gradient;
  final bool enableGlassEffect;
  final bool enableScaleAnimation;
  final EdgeInsetsGeometry? padding;
  final double? borderRadius;

  const HoorAnimatedCard({
    super.key,
    required this.child,
    this.onTap,
    this.backgroundColor,
    this.gradient,
    this.enableGlassEffect = false,
    this.enableScaleAnimation = true,
    this.padding,
    this.borderRadius,
  });

  @override
  State<HoorAnimatedCard> createState() => _HoorAnimatedCardState();
}

class _HoorAnimatedCardState extends State<HoorAnimatedCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  bool _isPressed = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: HoorDurations.fast,
      vsync: this,
    );

    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.97,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    ));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleTapDown(TapDownDetails details) {
    if (widget.enableScaleAnimation) {
      setState(() => _isPressed = true);
      _controller.forward();
    }
  }

  void _handleTapUp(TapUpDetails details) {
    if (widget.enableScaleAnimation) {
      setState(() => _isPressed = false);
      _controller.reverse();
    }
  }

  void _handleTapCancel() {
    if (widget.enableScaleAnimation) {
      setState(() => _isPressed = false);
      _controller.reverse();
    }
  }

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(widget.borderRadius ?? HoorRadius.xl);

    return GestureDetector(
      onTapDown: widget.onTap != null ? _handleTapDown : null,
      onTapUp: widget.onTap != null ? _handleTapUp : null,
      onTapCancel: widget.onTap != null ? _handleTapCancel : null,
      onTap: widget.onTap,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return Transform.scale(
            scale: widget.enableScaleAnimation ? _scaleAnimation.value : 1.0,
            child: AnimatedContainer(
              duration: HoorDurations.fast,
              decoration: BoxDecoration(
                borderRadius: radius,
                boxShadow: _isPressed ? HoorShadows.sm : HoorShadows.md,
              ),
              child: ClipRRect(
                borderRadius: radius,
                child: widget.enableGlassEffect
                    ? _buildGlassCard(radius)
                    : _buildSolidCard(radius),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildGlassCard(BorderRadius radius) {
    return BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
      child: Container(
        padding: widget.padding ?? EdgeInsets.all(HoorSpacing.lg),
        decoration: BoxDecoration(
          gradient: widget.gradient ??
              LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.white.withValues(alpha: 0.2),
                  Colors.white.withValues(alpha: 0.1),
                ],
              ),
          borderRadius: radius,
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.2),
            width: 1.5,
          ),
        ),
        child: widget.child,
      ),
    );
  }

  Widget _buildSolidCard(BorderRadius radius) {
    return Container(
      padding: widget.padding ?? EdgeInsets.all(HoorSpacing.lg),
      decoration: BoxDecoration(
        color: widget.backgroundColor ?? HoorColors.surface,
        gradient: widget.gradient,
        borderRadius: radius,
        border: widget.gradient == null
            ? Border.all(color: HoorColors.border)
            : null,
      ),
      child: widget.child,
    );
  }
}

/// ═══════════════════════════════════════════════════════════════════════════
/// HoorPremiumStatCard - Modern Premium Statistics Card
/// Beautiful stat card with gradient and animations
/// ═══════════════════════════════════════════════════════════════════════════

class HoorPremiumStatCard extends StatefulWidget {
  final String title;
  final String value;
  final String? subtitle;
  final IconData icon;
  final Gradient gradient;
  final VoidCallback? onTap;
  final String? badge;

  const HoorPremiumStatCard({
    super.key,
    required this.title,
    required this.value,
    this.subtitle,
    required this.icon,
    required this.gradient,
    this.onTap,
    this.badge,
  });

  @override
  State<HoorPremiumStatCard> createState() => _HoorPremiumStatCardState();
}

class _HoorPremiumStatCardState extends State<HoorPremiumStatCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _shimmerController;

  @override
  void initState() {
    super.initState();
    _shimmerController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat();
  }

  @override
  void dispose() {
    _shimmerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return HoorAnimatedCard(
      onTap: widget.onTap,
      gradient: widget.gradient,
      child: Stack(
        children: [
          // Shimmer effect overlay
          Positioned.fill(
            child: AnimatedBuilder(
              animation: _shimmerController,
              builder: (context, child) {
                return ShaderMask(
                  shaderCallback: (bounds) {
                    return LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Colors.white.withValues(alpha: 0),
                        Colors.white.withValues(alpha: 0.1),
                        Colors.white.withValues(alpha: 0),
                      ],
                      stops: [
                        _shimmerController.value - 0.3,
                        _shimmerController.value,
                        _shimmerController.value + 0.3,
                      ].map((s) => s.clamp(0.0, 1.0)).toList(),
                    ).createShader(bounds);
                  },
                  blendMode: BlendMode.srcATop,
                  child: Container(color: Colors.white),
                );
              },
            ),
          ),
          // Content
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: EdgeInsets.all(HoorSpacing.sm),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(HoorRadius.md),
                    ),
                    child: Icon(
                      widget.icon,
                      color: Colors.white,
                      size: HoorIconSize.lg,
                    ),
                  ),
                  if (widget.badge != null)
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: HoorSpacing.sm,
                        vertical: HoorSpacing.xxs,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(HoorRadius.full),
                      ),
                      child: Text(
                        widget.badge!,
                        style: HoorTypography.labelSmall.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                ],
              ),
              SizedBox(height: HoorSpacing.lg.h),
              Text(
                widget.value,
                style: HoorTypography.displaySmall.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: HoorSpacing.xxs.h),
              Text(
                widget.title,
                style: HoorTypography.bodyMedium.copyWith(
                  color: Colors.white.withValues(alpha: 0.9),
                ),
              ),
              if (widget.subtitle != null) ...[
                SizedBox(height: HoorSpacing.xxs.h),
                Text(
                  widget.subtitle!,
                  style: HoorTypography.caption.copyWith(
                    color: Colors.white.withValues(alpha: 0.7),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

/// ═══════════════════════════════════════════════════════════════════════════
/// HoorGlassButton - Glassmorphism Button
/// Modern glass effect button
/// ═══════════════════════════════════════════════════════════════════════════

class HoorGlassButton extends StatefulWidget {
  final String label;
  final IconData? icon;
  final VoidCallback? onTap;
  final Color? color;
  final bool isFullWidth;

  const HoorGlassButton({
    super.key,
    required this.label,
    this.icon,
    this.onTap,
    this.color,
    this.isFullWidth = false,
  });

  @override
  State<HoorGlassButton> createState() => _HoorGlassButtonState();
}

class _HoorGlassButtonState extends State<HoorGlassButton> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final effectiveColor = widget.color ?? HoorColors.primary;

    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) => setState(() => _isPressed = false),
      onTapCancel: () => setState(() => _isPressed = false),
      onTap: widget.onTap,
      child: AnimatedScale(
        scale: _isPressed ? 0.96 : 1.0,
        duration: HoorDurations.fast,
        curve: Curves.easeOutCubic,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(HoorRadius.lg),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
            child: Container(
              width: widget.isFullWidth ? double.infinity : null,
              padding: EdgeInsets.symmetric(
                horizontal: HoorSpacing.xl,
                vertical: HoorSpacing.md,
              ),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    effectiveColor.withValues(alpha: 0.8),
                    effectiveColor.withValues(alpha: 0.6),
                  ],
                ),
                borderRadius: BorderRadius.circular(HoorRadius.lg),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.2),
                  width: 1,
                ),
                boxShadow: HoorShadows.glow(effectiveColor),
              ),
              child: Row(
                mainAxisSize:
                    widget.isFullWidth ? MainAxisSize.max : MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (widget.icon != null) ...[
                    Icon(widget.icon,
                        color: Colors.white, size: HoorIconSize.md),
                    SizedBox(width: HoorSpacing.sm.w),
                  ],
                  Text(
                    widget.label,
                    style: HoorTypography.labelLarge.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// ═══════════════════════════════════════════════════════════════════════════
/// HoorFloatingActionCard - Floating Action Quick Access Card
/// Modern FAB-style quick action with animation
/// ═══════════════════════════════════════════════════════════════════════════

class HoorFloatingActionCard extends StatefulWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const HoorFloatingActionCard({
    super.key,
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  State<HoorFloatingActionCard> createState() => _HoorFloatingActionCardState();
}

class _HoorFloatingActionCardState extends State<HoorFloatingActionCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _bounceController;
  late Animation<double> _bounceAnimation;
  bool _isHovered = false;

  @override
  void initState() {
    super.initState();
    _bounceController = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );

    _bounceAnimation = Tween<double>(begin: 1.0, end: 1.1).animate(
      CurvedAnimation(parent: _bounceController, curve: Curves.easeOutBack),
    );
  }

  @override
  void dispose() {
    _bounceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) {
        _bounceController.forward();
        setState(() => _isHovered = true);
      },
      onTapUp: (_) {
        _bounceController.reverse();
        setState(() => _isHovered = false);
      },
      onTapCancel: () {
        _bounceController.reverse();
        setState(() => _isHovered = false);
      },
      onTap: widget.onTap,
      child: AnimatedBuilder(
        animation: _bounceAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: _bounceAnimation.value,
            child: AnimatedContainer(
              duration: HoorDurations.fast,
              padding: EdgeInsets.symmetric(
                vertical: HoorSpacing.lg.h,
                horizontal: HoorSpacing.md.w,
              ),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    widget.color,
                    widget.color.withValues(alpha: 0.8),
                  ],
                ),
                borderRadius: BorderRadius.circular(HoorRadius.xl),
                boxShadow: _isHovered
                    ? HoorShadows.glow(widget.color)
                    : HoorShadows.colored(widget.color, opacity: 0.3),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: EdgeInsets.all(HoorSpacing.md),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      widget.icon,
                      color: Colors.white,
                      size: HoorIconSize.xl,
                    ),
                  ),
                  SizedBox(height: HoorSpacing.md.h),
                  Text(
                    widget.label,
                    textAlign: TextAlign.center,
                    style: HoorTypography.labelMedium.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
