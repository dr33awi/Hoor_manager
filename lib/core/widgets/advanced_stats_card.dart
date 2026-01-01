// ═══════════════════════════════════════════════════════════════════════════
// Advanced Stats Card Pro with Animations
// ═══════════════════════════════════════════════════════════════════════════

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../theme/design_tokens.dart';
import '../animations/pro_animations.dart';

class AdvancedStatsCard extends StatelessWidget {
  final String title;
  final double value;
  final String? subtitle;
  final IconData icon;
  final Color? iconColor;
  final Color? backgroundColor;
  final double? changePercent;
  final bool isPositiveChange;
  final String? prefix;
  final String? suffix;
  final int decimalPlaces;
  final VoidCallback? onTap;
  final int animationIndex;

  const AdvancedStatsCard({
    super.key,
    required this.title,
    required this.value,
    this.subtitle,
    required this.icon,
    this.iconColor,
    this.backgroundColor,
    this.changePercent,
    this.isPositiveChange = true,
    this.prefix,
    this.suffix,
    this.decimalPlaces = 0,
    this.onTap,
    this.animationIndex = 0,
  });

  @override
  Widget build(BuildContext context) {
    final bgColor = backgroundColor ?? Colors.white;
    final iconClr = iconColor ?? AppColors.primary;

    return StaggeredListAnimation(
      index: animationIndex,
      direction: SlideDirection.up,
      child: BounceAnimation(
        onTap: onTap,
        child: Container(
          padding: EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(AppRadius.lg),
            boxShadow: AppShadows.md,
            border: Border.all(
              color: AppColors.border,
              width: 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(AppSpacing.sm),
                    decoration: BoxDecoration(
                      color: iconClr.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(AppRadius.md),
                    ),
                    child: Icon(
                      icon,
                      color: iconClr,
                      size: AppIconSize.md,
                    ),
                  ),
                  const Spacer(),
                  if (changePercent != null) _buildChangeIndicator(),
                ],
              ),

              SizedBox(height: AppSpacing.md),

              // Value with Animation
              AnimatedCounter(
                value: value,
                prefix: prefix,
                suffix: suffix,
                decimalPlaces: decimalPlaces,
                style: AppTypography.headlineLarge.copyWith(
                  color: AppColors.textPrimary,
                  fontFamily: 'JetBrains Mono',
                  fontWeight: FontWeight.bold,
                ),
              ),

              SizedBox(height: AppSpacing.xs),

              // Title
              Text(
                title,
                style: AppTypography.bodySmall.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),

              if (subtitle != null) ...[
                SizedBox(height: AppSpacing.xs),
                Text(
                  subtitle!,
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.textTertiary,
                    fontSize: 11.sp,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildChangeIndicator() {
    final color = isPositiveChange ? AppColors.success : AppColors.error;
    final icon = isPositiveChange ? Icons.trending_up : Icons.trending_down;

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppRadius.full),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14.sp, color: color),
          SizedBox(width: 2.w),
          Text(
            '${changePercent!.toStringAsFixed(1)}%',
            style: AppTypography.labelSmall.copyWith(
              color: color,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// Mini Stats Card
// ═══════════════════════════════════════════════════════════════════════════

class MiniStatsCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;
  final int animationIndex;

  const MiniStatsCard({
    super.key,
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
    this.animationIndex = 0,
  });

  @override
  Widget build(BuildContext context) {
    return StaggeredListAnimation(
      index: animationIndex,
      child: Container(
        padding: EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(
            color: color.withValues(alpha: 0.2),
          ),
        ),
        child: Row(
          children: [
            Icon(icon, color: color, size: AppIconSize.md),
            SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    value,
                    style: AppTypography.titleMedium.copyWith(
                      color: color,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'JetBrains Mono',
                    ),
                  ),
                  Text(
                    title,
                    style: AppTypography.bodySmall.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// Gradient Stats Card
// ═══════════════════════════════════════════════════════════════════════════

class GradientStatsCard extends StatelessWidget {
  final String title;
  final double value;
  final String? subtitle;
  final IconData icon;
  final List<Color> gradientColors;
  final String? prefix;
  final String? suffix;
  final int decimalPlaces;
  final int animationIndex;

  const GradientStatsCard({
    super.key,
    required this.title,
    required this.value,
    this.subtitle,
    required this.icon,
    required this.gradientColors,
    this.prefix,
    this.suffix,
    this.decimalPlaces = 0,
    this.animationIndex = 0,
  });

  @override
  Widget build(BuildContext context) {
    return StaggeredListAnimation(
      index: animationIndex,
      direction: SlideDirection.up,
      child: Container(
        padding: EdgeInsets.all(AppSpacing.lg),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: gradientColors,
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(AppRadius.xl),
          boxShadow: [
            BoxShadow(
              color: gradientColors.first.withValues(alpha: 0.3),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: EdgeInsets.all(AppSpacing.sm),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(AppRadius.md),
                  ),
                  child: Icon(
                    icon,
                    color: Colors.white,
                    size: AppIconSize.lg,
                  ),
                ),
                const Spacer(),
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: AppSpacing.sm,
                    vertical: AppSpacing.xs,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(AppRadius.full),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.arrow_upward,
                        size: 14.sp,
                        color: Colors.white,
                      ),
                      SizedBox(width: 2.w),
                      Text(
                        'اليوم',
                        style: AppTypography.labelSmall.copyWith(
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            SizedBox(height: AppSpacing.lg),
            AnimatedCounter(
              value: value,
              prefix: prefix,
              suffix: suffix,
              decimalPlaces: decimalPlaces,
              style: AppTypography.displaySmall.copyWith(
                color: Colors.white,
                fontFamily: 'JetBrains Mono',
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: AppSpacing.xs),
            Text(
              title,
              style: AppTypography.titleMedium.copyWith(
                color: Colors.white.withValues(alpha: 0.9),
              ),
            ),
            if (subtitle != null) ...[
              SizedBox(height: AppSpacing.xs),
              Text(
                subtitle!,
                style: AppTypography.bodySmall.copyWith(
                  color: Colors.white.withValues(alpha: 0.7),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// Progress Stats Card
// ═══════════════════════════════════════════════════════════════════════════

class ProgressStatsCard extends StatelessWidget {
  final String title;
  final double current;
  final double total;
  final Color color;
  final IconData icon;
  final int animationIndex;

  const ProgressStatsCard({
    super.key,
    required this.title,
    required this.current,
    required this.total,
    required this.color,
    required this.icon,
    this.animationIndex = 0,
  });

  double get progress => total > 0 ? (current / total).clamp(0.0, 1.0) : 0.0;

  @override
  Widget build(BuildContext context) {
    return StaggeredListAnimation(
      index: animationIndex,
      child: Container(
        padding: EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          boxShadow: AppShadows.sm,
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: color, size: AppIconSize.md),
                SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    title,
                    style: AppTypography.titleSmall.copyWith(
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
                Text(
                  '${(progress * 100).toStringAsFixed(0)}%',
                  style: AppTypography.labelMedium.copyWith(
                    color: color,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            SizedBox(height: AppSpacing.md),
            TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: progress),
              duration: const Duration(milliseconds: 1000),
              curve: Curves.easeOutCubic,
              builder: (context, value, child) {
                return ClipRRect(
                  borderRadius: BorderRadius.circular(AppRadius.full),
                  child: LinearProgressIndicator(
                    value: value,
                    backgroundColor: color.withValues(alpha: 0.1),
                    valueColor: AlwaysStoppedAnimation(color),
                    minHeight: 8.h,
                  ),
                );
              },
            ),
            SizedBox(height: AppSpacing.sm),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${current.toStringAsFixed(0)} من ${total.toStringAsFixed(0)}',
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.textSecondary,
                    fontFamily: 'JetBrains Mono',
                  ),
                ),
                Text(
                  'المتبقي: ${(total - current).toStringAsFixed(0)}',
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.textTertiary,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
