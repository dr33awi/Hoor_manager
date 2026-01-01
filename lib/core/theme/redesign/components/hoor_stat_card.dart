import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../design_tokens.dart';
import '../typography.dart';

/// ═══════════════════════════════════════════════════════════════════════════
/// HoorStatCard - Financial Statistics Cards
/// Professional KPI and metric display components
/// ═══════════════════════════════════════════════════════════════════════════

enum StatTrend { up, down, neutral }

class HoorStatCard extends StatelessWidget {
  final String title;
  final String value;
  final String? subtitle;
  final IconData? icon;
  final Color? color;
  final StatTrend? trend;
  final String? trendValue;
  final VoidCallback? onTap;
  final bool isCompact;

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
  });

  @override
  Widget build(BuildContext context) {
    final effectiveColor = color ?? HoorColors.primary;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: HoorRadius.cardRadius,
        child: Container(
          padding: EdgeInsets.all(isCompact ? HoorSpacing.sm : HoorSpacing.md),
          decoration: BoxDecoration(
            color: HoorColors.surface,
            borderRadius: HoorRadius.cardRadius,
            border: Border.all(color: HoorColors.border),
          ),
          child: isCompact
              ? _buildCompact(effectiveColor)
              : _buildFull(effectiveColor),
        ),
      ),
    );
  }

  Widget _buildCompact(Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            if (icon != null) ...[
              Container(
                padding: EdgeInsets.all(HoorSpacing.xs),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(HoorRadius.sm),
                ),
                child: Icon(icon, color: color, size: HoorIconSize.sm),
              ),
              SizedBox(width: HoorSpacing.xs),
            ],
            Expanded(
              child: Text(
                title,
                style: HoorTypography.labelSmall.copyWith(
                  color: HoorColors.textSecondary,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        SizedBox(height: HoorSpacing.xs),
        Text(
          value,
          style: HoorTypography.numericSmall.copyWith(
            color: HoorColors.textPrimary,
          ),
        ),
        if (trend != null && trendValue != null) ...[
          SizedBox(height: HoorSpacing.xxs),
          _buildTrend(),
        ],
      ],
    );
  }

  Widget _buildFull(Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            if (icon != null)
              Container(
                padding: EdgeInsets.all(HoorSpacing.sm),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(HoorRadius.md),
                ),
                child: Icon(icon, color: color, size: HoorIconSize.md),
              ),
            const Spacer(),
            if (trend != null && trendValue != null) _buildTrend(),
          ],
        ),
        SizedBox(height: HoorSpacing.md),
        Text(
          value,
          style: HoorTypography.numericMedium.copyWith(
            color: HoorColors.textPrimary,
          ),
        ),
        SizedBox(height: HoorSpacing.xxs),
        Text(
          title,
          style: HoorTypography.bodySmall.copyWith(
            color: HoorColors.textSecondary,
          ),
        ),
        if (subtitle != null) ...[
          SizedBox(height: HoorSpacing.xxs),
          Text(
            subtitle!,
            style: HoorTypography.caption.copyWith(
              color: HoorColors.textTertiary,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildTrend() {
    final trendColor = switch (trend) {
      StatTrend.up => HoorColors.income,
      StatTrend.down => HoorColors.expense,
      StatTrend.neutral => HoorColors.textTertiary,
      null => HoorColors.textTertiary,
    };

    final trendIcon = switch (trend) {
      StatTrend.up => Icons.trending_up_rounded,
      StatTrend.down => Icons.trending_down_rounded,
      StatTrend.neutral => Icons.trending_flat_rounded,
      null => Icons.trending_flat_rounded,
    };

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: HoorSpacing.xs,
        vertical: HoorSpacing.xxxs,
      ),
      decoration: BoxDecoration(
        color: trendColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(HoorRadius.full),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(trendIcon, color: trendColor, size: HoorIconSize.xs),
          SizedBox(width: 2.w),
          Text(
            trendValue!,
            style: HoorTypography.labelSmall.copyWith(
              color: trendColor,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

/// ═══════════════════════════════════════════════════════════════════════════
/// Large Hero Stat Card
/// ═══════════════════════════════════════════════════════════════════════════

class HoorHeroStatCard extends StatelessWidget {
  final String title;
  final String value;
  final String? subtitle;
  final IconData icon;
  final Color? color;
  final bool useGradient;
  final Widget? action;
  final VoidCallback? onTap;

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
  });

  @override
  Widget build(BuildContext context) {
    final effectiveColor = color ?? HoorColors.primary;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: HoorRadius.cardRadius,
        child: Container(
          width: double.infinity,
          padding: EdgeInsets.all(HoorSpacing.lg),
          decoration: BoxDecoration(
            gradient: useGradient
                ? LinearGradient(
                    colors: [
                      effectiveColor,
                      effectiveColor.withValues(alpha: 0.85)
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  )
                : null,
            color: useGradient ? null : effectiveColor,
            borderRadius: HoorRadius.cardRadius,
            boxShadow: HoorShadows.colored(effectiveColor, opacity: 0.3),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(HoorSpacing.sm),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(HoorRadius.md),
                    ),
                    child: Icon(
                      icon,
                      color: Colors.white,
                      size: HoorIconSize.lg,
                    ),
                  ),
                  const Spacer(),
                  if (action != null) action!,
                ],
              ),
              SizedBox(height: HoorSpacing.lg),
              Text(
                value,
                style: HoorTypography.numericLarge.copyWith(
                  color: Colors.white,
                ),
              ),
              SizedBox(height: HoorSpacing.xxs),
              Text(
                title,
                style: HoorTypography.titleMedium.copyWith(
                  color: Colors.white.withValues(alpha: 0.9),
                ),
              ),
              if (subtitle != null) ...[
                SizedBox(height: HoorSpacing.xxs),
                Text(
                  subtitle!,
                  style: HoorTypography.bodySmall.copyWith(
                    color: Colors.white.withValues(alpha: 0.7),
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

/// ═══════════════════════════════════════════════════════════════════════════
/// Financial Balance Card
/// ═══════════════════════════════════════════════════════════════════════════

class HoorBalanceCard extends StatelessWidget {
  final String balance;
  final String? income;
  final String? expense;
  final String? period;
  final VoidCallback? onTap;

  const HoorBalanceCard({
    super.key,
    required this.balance,
    this.income,
    this.expense,
    this.period,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: HoorRadius.cardRadius,
        child: Container(
          width: double.infinity,
          padding: EdgeInsets.all(HoorSpacing.lg),
          decoration: BoxDecoration(
            gradient: HoorColors.heroGradient,
            borderRadius: HoorRadius.cardRadius,
            boxShadow: HoorShadows.colored(HoorColors.primary, opacity: 0.25),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    'الرصيد الإجمالي',
                    style: HoorTypography.bodyMedium.copyWith(
                      color: Colors.white.withValues(alpha: 0.8),
                    ),
                  ),
                  const Spacer(),
                  if (period != null)
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
                        period!,
                        style: HoorTypography.labelSmall.copyWith(
                          color: Colors.white,
                        ),
                      ),
                    ),
                ],
              ),
              SizedBox(height: HoorSpacing.sm),
              Text(
                balance,
                style: HoorTypography.numericLarge.copyWith(
                  color: Colors.white,
                  fontSize: 36.sp,
                ),
              ),
              if (income != null || expense != null) ...[
                SizedBox(height: HoorSpacing.lg),
                Row(
                  children: [
                    if (income != null)
                      Expanded(
                          child: _buildSubStat(
                              'الدخل',
                              income!,
                              Icons.arrow_downward_rounded,
                              HoorColors.incomeLight)),
                    if (income != null && expense != null)
                      SizedBox(width: HoorSpacing.md),
                    if (expense != null)
                      Expanded(
                          child: _buildSubStat(
                              'المصروفات',
                              expense!,
                              Icons.arrow_upward_rounded,
                              HoorColors.expenseLight)),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSubStat(String label, String value, IconData icon, Color color) {
    return Container(
      padding: EdgeInsets.all(HoorSpacing.sm),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(HoorRadius.md),
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(HoorSpacing.xxs),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: HoorIconSize.xs),
          ),
          SizedBox(width: HoorSpacing.xs),
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
                Text(
                  value,
                  style: HoorTypography.titleSmall.copyWith(
                    color: Colors.white,
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
