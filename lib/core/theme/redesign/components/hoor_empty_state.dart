import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../design_tokens.dart';
import '../typography.dart';

/// ═══════════════════════════════════════════════════════════════════════════
/// HoorEmptyState - Animated Empty State Components
/// Professional placeholders with smooth entrance animations
/// ═══════════════════════════════════════════════════════════════════════════

enum EmptyStateType {
  noData,
  noResults,
  error,
  noConnection,
  noPermission,
  comingSoon,
}

class HoorEmptyState extends StatefulWidget {
  final EmptyStateType type;
  final String? title;
  final String? message;
  final String? actionLabel;
  final VoidCallback? onAction;
  final IconData? icon;
  final Widget? customIllustration;
  final double? iconSize;
  final bool compact;
  final bool enableAnimation;

  const HoorEmptyState({
    super.key,
    this.type = EmptyStateType.noData,
    this.title,
    this.message,
    this.actionLabel,
    this.onAction,
    this.icon,
    this.customIllustration,
    this.iconSize,
    this.compact = false,
    this.enableAnimation = true,
  });

  @override
  State<HoorEmptyState> createState() => _HoorEmptyStateState();
}

class _HoorEmptyStateState extends State<HoorEmptyState>
    with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late AnimationController _bounceController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _bounceAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _bounceController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeOut),
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.1),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeOutCubic),
    );
    _bounceAnimation = Tween<double>(begin: 0.0, end: 8.0).animate(
      CurvedAnimation(parent: _bounceController, curve: Curves.easeInOut),
    );

    if (widget.enableAnimation) {
      _fadeController.forward();
      _bounceController.repeat(reverse: true);
    } else {
      _fadeController.value = 1.0;
    }
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _bounceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.compact) {
      return _buildCompact();
    }
    return _buildFull();
  }

  Widget _buildFull() {
    return AnimatedBuilder(
      animation: Listenable.merge([_fadeAnimation, _bounceAnimation]),
      builder: (context, child) {
        return FadeTransition(
          opacity: _fadeAnimation,
          child: SlideTransition(
            position: _slideAnimation,
            child: Center(
              child: Padding(
                padding: EdgeInsets.all(HoorSpacing.xl),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Transform.translate(
                      offset: Offset(0, -_bounceAnimation.value),
                      child: _buildIllustration(),
                    ),
                    SizedBox(height: HoorSpacing.xl),
                    Text(
                      widget.title ?? _getDefaultTitle(),
                      style: HoorTypography.headlineSmall.copyWith(
                        color: HoorColors.textPrimary,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: HoorSpacing.sm),
                    Text(
                      widget.message ?? _getDefaultMessage(),
                      style: HoorTypography.bodyMedium.copyWith(
                        color: HoorColors.textSecondary,
                        height: 1.5,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    if (widget.actionLabel != null &&
                        widget.onAction != null) ...[
                      SizedBox(height: HoorSpacing.xl),
                      _AnimatedActionButton(
                        label: widget.actionLabel!,
                        onPressed: widget.onAction!,
                        color: _getIconColor(),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildCompact() {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: Container(
        padding: EdgeInsets.all(HoorSpacing.lg),
        margin: EdgeInsets.symmetric(horizontal: HoorSpacing.md),
        decoration: BoxDecoration(
          color: HoorColors.surfaceMuted.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(HoorRadius.lg),
          border: Border.all(color: HoorColors.border),
        ),
        child: Row(
          children: [
            _buildSmallIcon(),
            SizedBox(width: HoorSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    widget.title ?? _getDefaultTitle(),
                    style: HoorTypography.titleSmall.copyWith(
                      color: HoorColors.textPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  SizedBox(height: HoorSpacing.xxs),
                  Text(
                    widget.message ?? _getDefaultMessage(),
                    style: HoorTypography.bodySmall.copyWith(
                      color: HoorColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            if (widget.actionLabel != null && widget.onAction != null)
              TextButton(
                onPressed: widget.onAction,
                child: Text(widget.actionLabel!),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildIllustration() {
    if (widget.customIllustration != null) {
      return widget.customIllustration!;
    }

    final effectiveIcon = widget.icon ?? _getDefaultIcon();
    final effectiveSize = widget.iconSize ?? 80.0;
    final color = _getIconColor();

    return Container(
      width: effectiveSize * 1.6,
      height: effectiveSize * 1.6,
      decoration: BoxDecoration(
        gradient: RadialGradient(
          colors: [
            color.withValues(alpha: 0.15),
            color.withValues(alpha: 0.05),
            Colors.transparent,
          ],
          stops: const [0.0, 0.6, 1.0],
        ),
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Container(
          width: effectiveSize * 1.2,
          height: effectiveSize * 1.2,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(
            effectiveIcon,
            size: effectiveSize.sp,
            color: color,
          ),
        ),
      ),
    );
  }

  Widget _buildSmallIcon() {
    final effectiveIcon = widget.icon ?? _getDefaultIcon();
    final color = _getIconColor();

    return Container(
      padding: EdgeInsets.all(HoorSpacing.sm),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            color.withValues(alpha: 0.15),
            color.withValues(alpha: 0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(HoorRadius.md),
      ),
      child: Icon(
        effectiveIcon,
        size: HoorIconSize.lg,
        color: color,
      ),
    );
  }

  IconData _getDefaultIcon() {
    switch (widget.type) {
      case EmptyStateType.noData:
        return Icons.inbox_rounded;
      case EmptyStateType.noResults:
        return Icons.search_off_rounded;
      case EmptyStateType.error:
        return Icons.error_outline_rounded;
      case EmptyStateType.noConnection:
        return Icons.wifi_off_rounded;
      case EmptyStateType.noPermission:
        return Icons.lock_outline_rounded;
      case EmptyStateType.comingSoon:
        return Icons.construction_rounded;
    }
  }

  String _getDefaultTitle() {
    switch (widget.type) {
      case EmptyStateType.noData:
        return 'لا توجد بيانات';
      case EmptyStateType.noResults:
        return 'لا توجد نتائج';
      case EmptyStateType.error:
        return 'حدث خطأ';
      case EmptyStateType.noConnection:
        return 'لا يوجد اتصال';
      case EmptyStateType.noPermission:
        return 'غير مصرح';
      case EmptyStateType.comingSoon:
        return 'قريباً';
    }
  }

  String _getDefaultMessage() {
    switch (widget.type) {
      case EmptyStateType.noData:
        return 'لم يتم إضافة أي عناصر بعد';
      case EmptyStateType.noResults:
        return 'جرب تغيير معايير البحث';
      case EmptyStateType.error:
        return 'حدث خطأ غير متوقع، يرجى المحاولة مرة أخرى';
      case EmptyStateType.noConnection:
        return 'تحقق من اتصالك بالإنترنت';
      case EmptyStateType.noPermission:
        return 'ليس لديك صلاحية للوصول لهذا المحتوى';
      case EmptyStateType.comingSoon:
        return 'هذه الميزة قيد التطوير';
    }
  }

  Color _getIconColor() {
    switch (widget.type) {
      case EmptyStateType.noData:
      case EmptyStateType.noResults:
      case EmptyStateType.comingSoon:
        return HoorColors.textTertiary;
      case EmptyStateType.error:
        return HoorColors.error;
      case EmptyStateType.noConnection:
        return HoorColors.warning;
      case EmptyStateType.noPermission:
        return HoorColors.primary;
    }
  }
}

/// Animated Action Button for Empty State
class _AnimatedActionButton extends StatefulWidget {
  final String label;
  final VoidCallback onPressed;
  final Color color;

  const _AnimatedActionButton({
    required this.label,
    required this.onPressed,
    required this.color,
  });

  @override
  State<_AnimatedActionButton> createState() => _AnimatedActionButtonState();
}

class _AnimatedActionButtonState extends State<_AnimatedActionButton>
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
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) {
        setState(() => _isPressed = true);
        _controller.forward();
      },
      onTapUp: (_) {
        setState(() => _isPressed = false);
        _controller.reverse();
        widget.onPressed();
      },
      onTapCancel: () {
        setState(() => _isPressed = false);
        _controller.reverse();
      },
      child: AnimatedBuilder(
        animation: _scaleAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: AnimatedContainer(
              duration: HoorDurations.fast,
              padding: EdgeInsets.symmetric(
                horizontal: HoorSpacing.xl,
                vertical: HoorSpacing.md,
              ),
              decoration: BoxDecoration(
                color: _isPressed
                    ? widget.color.withValues(alpha: 0.85)
                    : widget.color,
                borderRadius: BorderRadius.circular(HoorRadius.full),
                boxShadow: [
                  BoxShadow(
                    color:
                        widget.color.withValues(alpha: _isPressed ? 0.2 : 0.3),
                    blurRadius: _isPressed ? 8 : 16,
                    offset: Offset(0, _isPressed ? 4 : 8),
                  ),
                ],
              ),
              child: Text(
                widget.label,
                style: HoorTypography.titleSmall.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
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
/// Shimmer Loading Placeholder
/// ═══════════════════════════════════════════════════════════════════════════

class HoorShimmer extends StatefulWidget {
  final Widget child;
  final bool isLoading;
  final Color? baseColor;
  final Color? highlightColor;

  const HoorShimmer({
    super.key,
    required this.child,
    this.isLoading = true,
    this.baseColor,
    this.highlightColor,
  });

  @override
  State<HoorShimmer> createState() => _HoorShimmerState();
}

class _HoorShimmerState extends State<HoorShimmer>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();

    _animation = Tween<double>(begin: -1.0, end: 2.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOutSine),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.isLoading) {
      return widget.child;
    }

    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return ShaderMask(
          blendMode: BlendMode.srcATop,
          shaderCallback: (bounds) {
            return LinearGradient(
              begin: Alignment.centerRight,
              end: Alignment.centerLeft,
              colors: [
                widget.baseColor ?? HoorColors.surfaceMuted,
                widget.highlightColor ?? HoorColors.surface,
                widget.baseColor ?? HoorColors.surfaceMuted,
              ],
              stops: [
                _animation.value - 0.3,
                _animation.value,
                _animation.value + 0.3,
              ].map((e) => e.clamp(0.0, 1.0)).toList(),
            ).createShader(bounds);
          },
          child: widget.child,
        );
      },
    );
  }
}

/// ═══════════════════════════════════════════════════════════════════════════
/// Skeleton Loaders
/// ═══════════════════════════════════════════════════════════════════════════

class HoorSkeleton extends StatelessWidget {
  final double? width;
  final double height;
  final BorderRadius? borderRadius;

  const HoorSkeleton({
    super.key,
    this.width,
    this.height = 16,
    this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height.h,
      decoration: BoxDecoration(
        color: HoorColors.surfaceMuted,
        borderRadius: borderRadius ?? BorderRadius.circular(HoorRadius.xs),
      ),
    );
  }
}

class HoorSkeletonCard extends StatelessWidget {
  final double? height;

  const HoorSkeletonCard({super.key, this.height});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height?.h ?? 120.h,
      padding: EdgeInsets.all(HoorSpacing.md),
      decoration: BoxDecoration(
        color: HoorColors.surface,
        borderRadius: HoorRadius.cardRadius,
        border: Border.all(color: HoorColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              HoorSkeleton(
                width: 40.w,
                height: 40.w,
                borderRadius: BorderRadius.all(Radius.circular(8.r)),
              ),
              SizedBox(width: HoorSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    HoorSkeleton(width: 100.w, height: 14.h),
                    SizedBox(height: HoorSpacing.xs),
                    HoorSkeleton(width: 150.w, height: 12.h),
                  ],
                ),
              ),
            ],
          ),
          Spacer(),
          HoorSkeleton(height: 20.h),
        ],
      ),
    );
  }
}

class HoorSkeletonListItem extends StatelessWidget {
  const HoorSkeletonListItem({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: HoorSpacing.md,
        vertical: HoorSpacing.sm,
      ),
      child: Row(
        children: [
          HoorSkeleton(
            width: 48.w,
            height: 48.w,
            borderRadius: BorderRadius.all(Radius.circular(24.r)),
          ),
          SizedBox(width: HoorSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                HoorSkeleton(width: double.infinity, height: 14.h),
                SizedBox(height: HoorSpacing.xs),
                HoorSkeleton(width: 100.w, height: 12.h),
              ],
            ),
          ),
          SizedBox(width: HoorSpacing.md),
          HoorSkeleton(width: 60.w, height: 14.h),
        ],
      ),
    );
  }
}
