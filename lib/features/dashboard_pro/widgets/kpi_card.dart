// ═══════════════════════════════════════════════════════════════════════════
// KPI Card Component - Key Performance Indicator
// Professional card for displaying financial metrics
// ═══════════════════════════════════════════════════════════════════════════

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../core/theme/design_tokens.dart';

/// A premium KPI card with gradient background and trend indicator
class KPICard extends StatelessWidget {
  const KPICard({
    super.key,
    required this.title,
    required this.value,
    required this.currency,
    required this.icon,
    required this.gradient,
    this.trend,
    this.trendLabel,
    this.onTap,
  })  : _isMini = false,
        color = null;

  const KPICard.mini({
    super.key,
    required this.title,
    required this.value,
    required this.currency,
    required this.icon,
    required this.color,
    this.onTap,
  })  : _isMini = true,
        gradient = null,
        trend = null,
        trendLabel = null;

  final String title;
  final String value;
  final String currency;
  final IconData icon;
  final Gradient? gradient;
  final Color? color;
  final double? trend;
  final String? trendLabel;
  final VoidCallback? onTap;
  final bool _isMini;

  @override
  Widget build(BuildContext context) {
    if (_isMini) {
      return _buildMiniCard(context);
    }
    return _buildFullCard(context);
  }

  Widget _buildFullCard(BuildContext context) {
    final isPositive = (trend ?? 0) >= 0;

    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        onTap?.call();
      },
      child: AnimatedContainer(
        duration: AppDurations.fast,
        padding: EdgeInsets.all(AppSpacing.lg.w),
        decoration: BoxDecoration(
          gradient: gradient,
          borderRadius: BorderRadius.circular(AppRadius.xl),
          boxShadow: AppShadows.colored(
            (gradient as LinearGradient).colors.first,
            opacity: 0.3,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Icon
                Container(
                  padding: EdgeInsets.all(AppSpacing.sm.w),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(AppRadius.md),
                  ),
                  child: Icon(
                    icon,
                    color: Colors.white,
                    size: AppIconSize.md,
                  ),
                ),
                // Arrow
                Icon(
                  Icons.arrow_forward_ios_rounded,
                  color: Colors.white.withValues(alpha: 0.7),
                  size: AppIconSize.sm,
                ),
              ],
            ),
            SizedBox(height: AppSpacing.lg.h),

            // Title
            Text(
              title,
              style: AppTypography.bodySmall.copyWith(
                color: Colors.white.withValues(alpha: 0.9),
              ),
            ),
            SizedBox(height: AppSpacing.xxs.h),

            // Value
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerRight,
                    child: Text(
                      value,
                      style: AppTypography.moneyLarge.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
                SizedBox(width: AppSpacing.xs.w),
                Padding(
                  padding: EdgeInsets.only(bottom: 4.h),
                  child: Text(
                    currency,
                    style: AppTypography.bodySmall.copyWith(
                      color: Colors.white.withValues(alpha: 0.8),
                    ),
                  ),
                ),
              ],
            ),

            // Trend
            if (trend != null) ...[
              SizedBox(height: AppSpacing.md.h),
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: AppSpacing.sm.w,
                  vertical: AppSpacing.xxs.h,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(AppRadius.full),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      isPositive
                          ? Icons.trending_up_rounded
                          : Icons.trending_down_rounded,
                      color: Colors.white,
                      size: AppIconSize.xs,
                    ),
                    SizedBox(width: AppSpacing.xxs.w),
                    Text(
                      '${isPositive ? '+' : ''}${trend!.toStringAsFixed(1)}%',
                      style: AppTypography.labelSmall.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (trendLabel != null) ...[
                      SizedBox(width: AppSpacing.xxs.w),
                      Text(
                        trendLabel!,
                        style: AppTypography.caption.copyWith(
                          color: Colors.white.withValues(alpha: 0.8),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildMiniCard(BuildContext context) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        onTap?.call();
      },
      child: Container(
        padding: EdgeInsets.all(AppSpacing.md.w),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          border: Border.all(color: AppColors.border),
          boxShadow: AppShadows.card,
        ),
        child: Row(
          children: [
            // Icon
            Container(
              padding: EdgeInsets.all(AppSpacing.sm.w),
              decoration: BoxDecoration(
                color: color!.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(AppRadius.md),
              ),
              child: Icon(
                icon,
                color: color,
                size: AppIconSize.md,
              ),
            ),
            SizedBox(width: AppSpacing.sm.w),

            // Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AppTypography.bodySmall.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                  SizedBox(height: AppSpacing.xxxs.h),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          value,
                          style: AppTypography.moneySmall.copyWith(
                            color: AppColors.textPrimary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      Text(
                        currency,
                        style: AppTypography.caption.copyWith(
                          color: AppColors.textTertiary,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Arrow
            Icon(
              Icons.chevron_left_rounded,
              color: AppColors.textTertiary,
              size: AppIconSize.md,
            ),
          ],
        ),
      ),
    );
  }
}
