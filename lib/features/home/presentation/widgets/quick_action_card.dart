import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../core/theme/redesign/design_system.dart';

/// ═══════════════════════════════════════════════════════════════════════════
/// Quick Action Card - Colorful action button for quick operations
/// ═══════════════════════════════════════════════════════════════════════════

class QuickActionCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const QuickActionCard({
    super.key,
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: color.withValues(alpha: 0.1),
      borderRadius: BorderRadius.circular(HoorRadius.lg),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(HoorRadius.lg),
        child: Container(
          padding: EdgeInsets.symmetric(
            vertical: HoorSpacing.lg.h,
            horizontal: HoorSpacing.sm.w,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: EdgeInsets.all(HoorSpacing.sm.w),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color, size: HoorIconSize.lg),
              ),
              SizedBox(height: HoorSpacing.sm.h),
              Text(
                label,
                textAlign: TextAlign.center,
                style: HoorTypography.labelMedium.copyWith(
                  color: color,
                  fontWeight: FontWeight.w600,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
