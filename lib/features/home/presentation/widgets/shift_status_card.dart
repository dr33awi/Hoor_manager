import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../core/theme/redesign/design_system.dart';

/// ═══════════════════════════════════════════════════════════════════════════
/// Shift Status Card - Hero card showing shift status
/// ═══════════════════════════════════════════════════════════════════════════

class ShiftStatusCard extends StatelessWidget {
  final bool hasOpenShift;
  final VoidCallback onTap;

  const ShiftStatusCard({
    super.key,
    required this.hasOpenShift,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.all(HoorSpacing.lg.w),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: hasOpenShift
                ? [
                    HoorColors.primary,
                    HoorColors.primary.withValues(alpha: 0.85)
                  ]
                : [
                    HoorColors.warning,
                    HoorColors.warning.withValues(alpha: 0.85)
                  ],
            begin: Alignment.topRight,
            end: Alignment.bottomLeft,
          ),
          borderRadius: BorderRadius.circular(HoorRadius.xl),
          boxShadow: [
            BoxShadow(
              color: (hasOpenShift ? HoorColors.primary : HoorColors.warning)
                  .withValues(alpha: 0.25),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildTopRow(),
            SizedBox(height: HoorSpacing.lg.h),
            _buildTitle(),
            SizedBox(height: HoorSpacing.xs.h),
            _buildDescription(),
            if (!hasOpenShift) ...[
              SizedBox(height: HoorSpacing.lg.h),
              _buildOpenShiftButton(),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildTopRow() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // Status Icon
        Container(
          padding: EdgeInsets.all(HoorSpacing.sm.w),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(HoorRadius.md),
          ),
          child: Icon(
            hasOpenShift ? Icons.lock_open_rounded : Icons.lock_outline_rounded,
            color: Colors.white,
            size: HoorIconSize.lg,
          ),
        ),

        // Status Badge
        Container(
          padding: EdgeInsets.symmetric(
            horizontal: HoorSpacing.md.w,
            vertical: HoorSpacing.xs.h,
          ),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(HoorRadius.full),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 8.w,
                height: 8.w,
                decoration: BoxDecoration(
                  color: hasOpenShift
                      ? HoorColors.success
                      : Colors.white.withValues(alpha: 0.7),
                  shape: BoxShape.circle,
                ),
              ),
              SizedBox(width: HoorSpacing.xs.w),
              Text(
                hasOpenShift ? 'نشط الآن' : 'مغلق',
                style: HoorTypography.labelMedium.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTitle() {
    return Text(
      hasOpenShift ? 'الوردية مفتوحة' : 'لا توجد وردية مفتوحة',
      style: HoorTypography.headlineSmall.copyWith(
        color: Colors.white,
        fontWeight: FontWeight.bold,
      ),
    );
  }

  Widget _buildDescription() {
    return Text(
      hasOpenShift
          ? 'يمكنك إجراء العمليات المالية والمبيعات'
          : 'يجب فتح وردية جديدة للبدء في العمل',
      style: HoorTypography.bodyMedium.copyWith(
        color: Colors.white.withValues(alpha: 0.9),
      ),
    );
  }

  Widget _buildOpenShiftButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: onTap,
        icon: const Icon(Icons.add_circle_outline),
        label: const Text('فتح وردية جديدة'),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.white,
          foregroundColor: HoorColors.warning,
          elevation: 0,
          padding: EdgeInsets.symmetric(vertical: HoorSpacing.md.h),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(HoorRadius.md),
          ),
        ),
      ),
    );
  }
}
