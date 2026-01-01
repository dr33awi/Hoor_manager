import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../design_tokens.dart';
import '../typography.dart';

/// ═══════════════════════════════════════════════════════════════════════════
/// HoorEmptyState - Empty State Components
/// Professional placeholders for empty lists and error states
/// ═══════════════════════════════════════════════════════════════════════════

enum EmptyStateType {
  noData,
  noResults,
  error,
  noConnection,
  noPermission,
  comingSoon,
}

class HoorEmptyState extends StatelessWidget {
  final EmptyStateType type;
  final String? title;
  final String? message;
  final String? actionLabel;
  final VoidCallback? onAction;
  final IconData? icon;
  final Widget? customIllustration;
  final double? iconSize;
  final bool compact;

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
  });

  @override
  Widget build(BuildContext context) {
    if (compact) {
      return _buildCompact();
    }
    return _buildFull();
  }

  Widget _buildFull() {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(HoorSpacing.xl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildIllustration(),
            SizedBox(height: HoorSpacing.xl),
            Text(
              title ?? _getDefaultTitle(),
              style: HoorTypography.headlineSmall.copyWith(
                color: HoorColors.textPrimary,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: HoorSpacing.sm),
            Text(
              message ?? _getDefaultMessage(),
              style: HoorTypography.bodyMedium.copyWith(
                color: HoorColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            if (actionLabel != null && onAction != null) ...[
              SizedBox(height: HoorSpacing.xl),
              ElevatedButton(
                onPressed: onAction,
                child: Text(actionLabel!),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildCompact() {
    return Padding(
      padding: EdgeInsets.all(HoorSpacing.lg),
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
                  title ?? _getDefaultTitle(),
                  style: HoorTypography.titleSmall.copyWith(
                    color: HoorColors.textPrimary,
                  ),
                ),
                SizedBox(height: HoorSpacing.xxs),
                Text(
                  message ?? _getDefaultMessage(),
                  style: HoorTypography.bodySmall.copyWith(
                    color: HoorColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          if (actionLabel != null && onAction != null)
            TextButton(
              onPressed: onAction,
              child: Text(actionLabel!),
            ),
        ],
      ),
    );
  }

  Widget _buildIllustration() {
    if (customIllustration != null) {
      return customIllustration!;
    }

    final effectiveIcon = icon ?? _getDefaultIcon();
    final effectiveSize = iconSize ?? 80.0;
    final color = _getIconColor();

    return Container(
      width: effectiveSize * 1.5,
      height: effectiveSize * 1.5,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        shape: BoxShape.circle,
      ),
      child: Icon(
        effectiveIcon,
        size: effectiveSize.sp,
        color: color,
      ),
    );
  }

  Widget _buildSmallIcon() {
    final effectiveIcon = icon ?? _getDefaultIcon();
    final color = _getIconColor();

    return Container(
      padding: EdgeInsets.all(HoorSpacing.sm),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
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
    switch (type) {
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
    switch (type) {
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
    switch (type) {
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
    switch (type) {
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
