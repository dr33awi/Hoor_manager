// ═══════════════════════════════════════════════════════════════════════════
// Shift Status Banner Component
// Displays current shift information prominently
// ═══════════════════════════════════════════════════════════════════════════

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../core/theme/design_tokens.dart';

class ShiftStatusBanner extends StatelessWidget {
  const ShiftStatusBanner({
    super.key,
    required this.isOpen,
    this.startTime,
    this.totalSales,
    this.onTap,
  });

  final bool isOpen;
  final String? startTime;
  final double? totalSales;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        onTap?.call();
      },
      child: AnimatedContainer(
        duration: AppDurations.normal,
        padding: EdgeInsets.all(AppSpacing.md.w),
        decoration: BoxDecoration(
          color: isOpen ? AppColors.incomeSurface : AppColors.warningSurface,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          border: Border.all(
            color: isOpen
                ? AppColors.income.withValues(alpha: 0.3)
                : AppColors.warning.withValues(alpha: 0.3),
          ),
        ),
        child: Row(
          children: [
            // Status Indicator
            _buildStatusIndicator(),
            SizedBox(width: AppSpacing.md.w),

            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        isOpen ? 'الوردية مفتوحة' : 'لا توجد وردية مفتوحة',
                        style: AppTypography.titleSmall.copyWith(
                          color:
                              isOpen ? AppColors.incomeDark : AppColors.warning,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      SizedBox(width: AppSpacing.xs.w),
                      if (isOpen) _buildPulsingDot(),
                    ],
                  ),
                  if (isOpen && (startTime != null || totalSales != null)) ...[
                    SizedBox(height: AppSpacing.xxs.h),
                    Row(
                      children: [
                        if (startTime != null) ...[
                          Icon(
                            Icons.access_time_rounded,
                            color: AppColors.textSecondary,
                            size: AppIconSize.xs,
                          ),
                          SizedBox(width: AppSpacing.xxs.w),
                          Text(
                            'بدأت $startTime',
                            style: AppTypography.bodySmall.copyWith(
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                        if (startTime != null && totalSales != null)
                          Container(
                            margin: EdgeInsets.symmetric(
                                horizontal: AppSpacing.xs.w),
                            width: 4.w,
                            height: 4.w,
                            decoration: BoxDecoration(
                              color: AppColors.textTertiary,
                              shape: BoxShape.circle,
                            ),
                          ),
                        if (totalSales != null) ...[
                          Icon(
                            Icons.monetization_on_outlined,
                            color: AppColors.income,
                            size: AppIconSize.xs,
                          ),
                          SizedBox(width: AppSpacing.xxs.w),
                          Text(
                            '${_formatAmount(totalSales!)} ر.س',
                            style: AppTypography.bodySmall.copyWith(
                              color: AppColors.income,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                  if (!isOpen) ...[
                    SizedBox(height: AppSpacing.xxs.h),
                    Text(
                      'اضغط لفتح وردية جديدة',
                      style: AppTypography.bodySmall.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ],
              ),
            ),

            // Action Icon
            Container(
              padding: EdgeInsets.all(AppSpacing.xs.w),
              decoration: BoxDecoration(
                color: (isOpen ? AppColors.income : AppColors.warning)
                    .withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(AppRadius.md),
              ),
              child: Icon(
                isOpen ? Icons.login_rounded : Icons.add_rounded,
                color: isOpen ? AppColors.income : AppColors.warning,
                size: AppIconSize.md,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusIndicator() {
    return Container(
      padding: EdgeInsets.all(AppSpacing.sm.w),
      decoration: BoxDecoration(
        color: (isOpen ? AppColors.income : AppColors.warning)
            .withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: Icon(
        isOpen ? Icons.point_of_sale_rounded : Icons.warning_amber_rounded,
        color: isOpen ? AppColors.income : AppColors.warning,
        size: AppIconSize.lg,
      ),
    );
  }

  Widget _buildPulsingDot() {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.5, end: 1.0),
      duration: const Duration(milliseconds: 1000),
      builder: (context, value, child) {
        return Container(
          width: 8.w,
          height: 8.w,
          decoration: BoxDecoration(
            color: AppColors.income.withValues(alpha: value),
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: AppColors.income.withValues(alpha: value * 0.5),
                blurRadius: 4,
                spreadRadius: 1,
              ),
            ],
          ),
        );
      },
      onEnd: () {
        // This creates a continuous pulsing effect
      },
    );
  }

  String _formatAmount(double amount) {
    if (amount >= 1000000) {
      return '${(amount / 1000000).toStringAsFixed(1)}M';
    } else if (amount >= 1000) {
      return '${(amount / 1000).toStringAsFixed(1)}K';
    }
    return amount.toStringAsFixed(0);
  }
}
