import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../design_tokens.dart';
import '../typography.dart';

/// ═══════════════════════════════════════════════════════════════════════════
/// HoorStatCard - Modern Animated Statistics Cards
/// Professional KPI and metric display with smooth animations
/// ═══════════════════════════════════════════════════════════════════════════

enum StatTrend { up, down, neutral }

class HoorStatCard extends StatefulWidget {
  final String title;
  final String value;
  final String? subtitle;
  final IconData? icon;
  final Color? color;
  final StatTrend? trend;
  final String? trendValue;
  final VoidCallback? onTap;
  final bool isCompact;
  final bool enableGradient;

  const HoorStatCard({
    super.key,
    required this.title,
    required this.value,
    this.subtitle,
    this.icon,
    this.color,
    this.trend,
    this.trendValue,
    this.onTap,
    this.isCompact = false,
    this.enableGradient = false,
  });

  @override
  State<HoorStatCard> createState() => _HoorStatCardState();
}

class _HoorStatCardState extends State<HoorStatCard>
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
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.97).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onTapDown(TapDownDetails details) {
    if (widget.onTap != null) {
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
    final effectiveColor = widget.color ?? HoorColors.primary;

    return GestureDetector(
      onTapDown: _onTapDown,
      onTapUp: _onTapUp,
      onTapCancel: _onTapCancel,
      onTap: widget.onTap,
      child: AnimatedBuilder(
        animation: _scaleAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: AnimatedContainer(
              duration: HoorDurations.fast,
              padding: EdgeInsets.all(
                  widget.isCompact ? HoorSpacing.md : HoorSpacing.lg),
              decoration: BoxDecoration(
                gradient: widget.enableGradient
                    ? LinearGradient(
                        colors: [
                          effectiveColor,
                          effectiveColor.withValues(alpha: 0.8),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      )
                    : null,
                color: widget.enableGradient ? null : HoorColors.surface,
                borderRadius: BorderRadius.circular(HoorRadius.xl),
                border: widget.enableGradient
                    ? null
                    : Border.all(
                        color: _isPressed
                            ? effectiveColor.withValues(alpha: 0.3)
                            : HoorColors.border,
                      ),
                boxShadow: _isPressed
                    ? []
                    : widget.enableGradient
                        ? HoorShadows.colored(effectiveColor, opacity: 0.3)
                        : HoorShadows.xs,
              ),
              child: widget.isCompact
                  ? _buildCompact(effectiveColor)
                  : _buildFull(effectiveColor),
            ),
          );
        },
      ),
    );
  }

  Widget _buildCompact(Color color) {
    final textColor =
        widget.enableGradient ? Colors.white : HoorColors.textPrimary;
    final secondaryTextColor = widget.enableGradient
        ? Colors.white.withValues(alpha: 0.8)
        : HoorColors.textSecondary;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            if (widget.icon != null) ...[
              Container(
                padding: EdgeInsets.all(HoorSpacing.xs),
                decoration: BoxDecoration(
                  color: widget.enableGradient
                      ? Colors.white.withValues(alpha: 0.2)
                      : color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(HoorRadius.md),
                ),
                child: Icon(
                  widget.icon,
                  color: widget.enableGradient ? Colors.white : color,
                  size: HoorIconSize.sm,
                ),
              ),
              SizedBox(width: HoorSpacing.xs),
            ],
            Expanded(
              child: Text(
                widget.title,
                style: HoorTypography.labelSmall.copyWith(
                  color: secondaryTextColor,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        SizedBox(height: HoorSpacing.sm),
        Text(
          widget.value,
          style: HoorTypography.headlineSmall.copyWith(
            color: textColor,
            fontWeight: FontWeight.bold,
          ),
        ),
        if (widget.trend != null && widget.trendValue != null) ...[
          SizedBox(height: HoorSpacing.xs),
          _buildTrend(),
        ],
      ],
    );
  }

  Widget _buildFull(Color color) {
    final textColor =
        widget.enableGradient ? Colors.white : HoorColors.textPrimary;
    final secondaryTextColor = widget.enableGradient
        ? Colors.white.withValues(alpha: 0.8)
        : HoorColors.textSecondary;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            if (widget.icon != null)
              Container(
                padding: EdgeInsets.all(HoorSpacing.sm),
                decoration: BoxDecoration(
                  color: widget.enableGradient
                      ? Colors.white.withValues(alpha: 0.2)
                      : color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(HoorRadius.lg),
                ),
                child: Icon(
                  widget.icon,
                  color: widget.enableGradient ? Colors.white : color,
                  size: HoorIconSize.lg,
                ),
              ),
            const Spacer(),
            if (widget.trend != null && widget.trendValue != null)
              _buildTrend(),
          ],
        ),
        SizedBox(height: HoorSpacing.lg),
        Text(
          widget.value,
          style: HoorTypography.displaySmall.copyWith(
            color: textColor,
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: HoorSpacing.xxs),
        Text(
          widget.title,
          style: HoorTypography.bodyMedium.copyWith(
            color: secondaryTextColor,
          ),
        ),
        if (widget.subtitle != null) ...[
          SizedBox(height: HoorSpacing.xxs),
          Text(
            widget.subtitle!,
            style: HoorTypography.caption.copyWith(
              color: widget.enableGradient
                  ? Colors.white.withValues(alpha: 0.6)
                  : HoorColors.textTertiary,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildTrend() {
    final trendColor = switch (widget.trend) {
      StatTrend.up => HoorColors.income,
      StatTrend.down => HoorColors.expense,
      StatTrend.neutral => HoorColors.textTertiary,
      null => HoorColors.textTertiary,
    };

    final trendIcon = switch (widget.trend) {
      StatTrend.up => Icons.trending_up_rounded,
      StatTrend.down => Icons.trending_down_rounded,
      StatTrend.neutral => Icons.trending_flat_rounded,
      null => Icons.trending_flat_rounded,
    };

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: HoorSpacing.sm,
        vertical: HoorSpacing.xxs,
      ),
      decoration: BoxDecoration(
        color: widget.enableGradient
            ? Colors.white.withValues(alpha: 0.2)
            : trendColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(HoorRadius.full),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            trendIcon,
            color: widget.enableGradient ? Colors.white : trendColor,
            size: HoorIconSize.xs,
          ),
          SizedBox(width: 4.w),
          Text(
            widget.trendValue!,
            style: HoorTypography.labelSmall.copyWith(
              color: widget.enableGradient ? Colors.white : trendColor,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

/// ═══════════════════════════════════════════════════════════════════════════
/// Large Hero Stat Card - Premium Animated Version
/// ═══════════════════════════════════════════════════════════════════════════

class HoorHeroStatCard extends StatefulWidget {
  final String title;
  final String value;
  final String? subtitle;
  final IconData icon;
  final Color? color;
  final bool useGradient;
  final Widget? action;
  final VoidCallback? onTap;
  final bool enableShimmer;

  const HoorHeroStatCard({
    super.key,
    required this.title,
    required this.value,
    this.subtitle,
    required this.icon,
    this.color,
    this.useGradient = true,
    this.action,
    this.onTap,
    this.enableShimmer = false,
  });

  @override
  State<HoorHeroStatCard> createState() => _HoorHeroStatCardState();
}

class _HoorHeroStatCardState extends State<HoorHeroStatCard>
    with TickerProviderStateMixin {
  late AnimationController _scaleController;
  late AnimationController _shimmerController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _shimmerAnimation;
  bool _isPressed = false;

  @override
  void initState() {
    super.initState();
    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.97).animate(
      CurvedAnimation(parent: _scaleController, curve: Curves.easeOutCubic),
    );

    _shimmerController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );
    _shimmerAnimation = Tween<double>(begin: -1.0, end: 2.0).animate(
      CurvedAnimation(parent: _shimmerController, curve: Curves.easeInOut),
    );

    if (widget.enableShimmer) {
      _shimmerController.repeat();
    }
  }

  @override
  void dispose() {
    _scaleController.dispose();
    _shimmerController.dispose();
    super.dispose();
  }

  void _onTapDown(TapDownDetails details) {
    if (widget.onTap != null) {
      setState(() => _isPressed = true);
      _scaleController.forward();
    }
  }

  void _onTapUp(TapUpDetails details) {
    setState(() => _isPressed = false);
    _scaleController.reverse();
  }

  void _onTapCancel() {
    setState(() => _isPressed = false);
    _scaleController.reverse();
  }

  @override
  Widget build(BuildContext context) {
    final effectiveColor = widget.color ?? HoorColors.primary;

    return GestureDetector(
      onTapDown: _onTapDown,
      onTapUp: _onTapUp,
      onTapCancel: _onTapCancel,
      onTap: widget.onTap,
      child: AnimatedBuilder(
        animation: _scaleAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: AnimatedContainer(
              duration: HoorDurations.fast,
              width: double.infinity,
              padding: EdgeInsets.all(HoorSpacing.xl),
              decoration: BoxDecoration(
                gradient: widget.useGradient
                    ? LinearGradient(
                        colors: [
                          effectiveColor,
                          effectiveColor.withValues(alpha: 0.75),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      )
                    : null,
                color: widget.useGradient ? null : effectiveColor,
                borderRadius: BorderRadius.circular(HoorRadius.xxl),
                boxShadow: _isPressed
                    ? HoorShadows.colored(effectiveColor, opacity: 0.15)
                    : HoorShadows.colored(effectiveColor, opacity: 0.4),
              ),
              child: Stack(
                children: [
                  // Decorative background pattern
                  Positioned(
                    top: -20.h,
                    right: -20.w,
                    child: Container(
                      width: 100.w,
                      height: 100.h,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white.withValues(alpha: 0.05),
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: -30.h,
                    left: -30.w,
                    child: Container(
                      width: 80.w,
                      height: 80.h,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white.withValues(alpha: 0.03),
                      ),
                    ),
                  ),
                  // Content
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: EdgeInsets.all(HoorSpacing.md),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.2),
                              borderRadius:
                                  BorderRadius.circular(HoorRadius.lg),
                            ),
                            child: Icon(
                              widget.icon,
                              color: Colors.white,
                              size: HoorIconSize.xl,
                            ),
                          ),
                          const Spacer(),
                          if (widget.action != null) widget.action!,
                        ],
                      ),
                      SizedBox(height: HoorSpacing.xl),
                      widget.enableShimmer
                          ? AnimatedBuilder(
                              animation: _shimmerAnimation,
                              builder: (context, child) {
                                return ShaderMask(
                                  shaderCallback: (bounds) {
                                    return LinearGradient(
                                      colors: [
                                        Colors.white,
                                        Colors.white.withValues(alpha: 0.5),
                                        Colors.white,
                                      ],
                                      stops: [
                                        (_shimmerAnimation.value - 0.3)
                                            .clamp(0.0, 1.0),
                                        _shimmerAnimation.value.clamp(0.0, 1.0),
                                        (_shimmerAnimation.value + 0.3)
                                            .clamp(0.0, 1.0),
                                      ],
                                      begin: Alignment.centerLeft,
                                      end: Alignment.centerRight,
                                    ).createShader(bounds);
                                  },
                                  child: Text(
                                    widget.value,
                                    style:
                                        HoorTypography.displayMedium.copyWith(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                );
                              },
                            )
                          : Text(
                              widget.value,
                              style: HoorTypography.displayMedium.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                      SizedBox(height: HoorSpacing.xs),
                      Text(
                        widget.title,
                        style: HoorTypography.titleMedium.copyWith(
                          color: Colors.white.withValues(alpha: 0.9),
                        ),
                      ),
                      if (widget.subtitle != null) ...[
                        SizedBox(height: HoorSpacing.xxs),
                        Text(
                          widget.subtitle!,
                          style: HoorTypography.bodySmall.copyWith(
                            color: Colors.white.withValues(alpha: 0.7),
                          ),
                        ),
                      ],
                    ],
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

/// ═══════════════════════════════════════════════════════════════════════════
/// Financial Balance Card - Premium Animated Version
/// ═══════════════════════════════════════════════════════════════════════════

class HoorBalanceCard extends StatefulWidget {
  final String balance;
  final String? income;
  final String? expense;
  final String? period;
  final VoidCallback? onTap;
  final bool enablePulse;

  const HoorBalanceCard({
    super.key,
    required this.balance,
    this.income,
    this.expense,
    this.period,
    this.onTap,
    this.enablePulse = false,
  });

  @override
  State<HoorBalanceCard> createState() => _HoorBalanceCardState();
}

class _HoorBalanceCardState extends State<HoorBalanceCard>
    with TickerProviderStateMixin {
  late AnimationController _scaleController;
  late AnimationController _pulseController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _pulseAnimation;
  bool _isPressed = false;

  @override
  void initState() {
    super.initState();
    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.97).animate(
      CurvedAnimation(parent: _scaleController, curve: Curves.easeOutCubic),
    );

    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );
    _pulseAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    if (widget.enablePulse) {
      _pulseController.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _scaleController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  void _onTapDown(TapDownDetails details) {
    if (widget.onTap != null) {
      setState(() => _isPressed = true);
      _scaleController.forward();
    }
  }

  void _onTapUp(TapUpDetails details) {
    setState(() => _isPressed = false);
    _scaleController.reverse();
  }

  void _onTapCancel() {
    setState(() => _isPressed = false);
    _scaleController.reverse();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: _onTapDown,
      onTapUp: _onTapUp,
      onTapCancel: _onTapCancel,
      onTap: widget.onTap,
      child: AnimatedBuilder(
        animation: Listenable.merge([_scaleAnimation, _pulseAnimation]),
        builder: (context, child) {
          final pulseValue = widget.enablePulse ? _pulseAnimation.value : 0.0;
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: AnimatedContainer(
              duration: HoorDurations.fast,
              width: double.infinity,
              padding: EdgeInsets.all(HoorSpacing.xl),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    HoorColors.primary,
                    Color.lerp(
                      HoorColors.primary.withValues(alpha: 0.85),
                      HoorColors.primaryDark,
                      pulseValue * 0.3,
                    )!,
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(HoorRadius.xxl),
                boxShadow: _isPressed
                    ? HoorShadows.colored(HoorColors.primary, opacity: 0.15)
                    : HoorShadows.colored(
                        HoorColors.primary,
                        opacity: 0.3 + (pulseValue * 0.15),
                      ),
              ),
              child: Stack(
                children: [
                  // Decorative elements
                  Positioned(
                    top: -30.h,
                    right: -30.w,
                    child: Container(
                      width: 120.w,
                      height: 120.h,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(
                          colors: [
                            Colors.white.withValues(alpha: 0.1),
                            Colors.white.withValues(alpha: 0.0),
                          ],
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: -40.h,
                    left: -20.w,
                    child: Container(
                      width: 100.w,
                      height: 100.h,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white.withValues(alpha: 0.05),
                      ),
                    ),
                  ),
                  // Content
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: EdgeInsets.all(HoorSpacing.sm),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.15),
                              borderRadius:
                                  BorderRadius.circular(HoorRadius.md),
                            ),
                            child: Icon(
                              Icons.account_balance_wallet_rounded,
                              color: Colors.white,
                              size: HoorIconSize.md,
                            ),
                          ),
                          SizedBox(width: HoorSpacing.sm),
                          Text(
                            'الرصيد الإجمالي',
                            style: HoorTypography.titleSmall.copyWith(
                              color: Colors.white.withValues(alpha: 0.9),
                            ),
                          ),
                          const Spacer(),
                          if (widget.period != null)
                            Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: HoorSpacing.md,
                                vertical: HoorSpacing.xs,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.15),
                                borderRadius:
                                    BorderRadius.circular(HoorRadius.full),
                                border: Border.all(
                                  color: Colors.white.withValues(alpha: 0.2),
                                ),
                              ),
                              child: Text(
                                widget.period!,
                                style: HoorTypography.labelSmall.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                        ],
                      ),
                      SizedBox(height: HoorSpacing.lg),
                      Text(
                        widget.balance,
                        style: HoorTypography.displayLarge.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          letterSpacing: -1,
                        ),
                      ),
                      if (widget.income != null || widget.expense != null) ...[
                        SizedBox(height: HoorSpacing.xl),
                        Row(
                          children: [
                            if (widget.income != null)
                              Expanded(
                                child: _buildSubStat(
                                  'الدخل',
                                  widget.income!,
                                  Icons.arrow_downward_rounded,
                                  HoorColors.income,
                                ),
                              ),
                            if (widget.income != null && widget.expense != null)
                              SizedBox(width: HoorSpacing.md),
                            if (widget.expense != null)
                              Expanded(
                                child: _buildSubStat(
                                  'المصروفات',
                                  widget.expense!,
                                  Icons.arrow_upward_rounded,
                                  HoorColors.expense,
                                ),
                              ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildSubStat(String label, String value, IconData icon, Color color) {
    return Container(
      padding: EdgeInsets.all(HoorSpacing.md),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(HoorRadius.lg),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.1),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(HoorSpacing.xs),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.25),
              borderRadius: BorderRadius.circular(HoorRadius.md),
            ),
            child: Icon(icon, color: color, size: HoorIconSize.sm),
          ),
          SizedBox(width: HoorSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: HoorTypography.labelSmall.copyWith(
                    color: Colors.white.withValues(alpha: 0.7),
                  ),
                ),
                SizedBox(height: 2.h),
                Text(
                  value,
                  style: HoorTypography.titleMedium.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
