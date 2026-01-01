import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../core/theme/redesign/design_system.dart';

/// ═══════════════════════════════════════════════════════════════════════════
/// Header Icon Button - Reusable header action button
/// ═══════════════════════════════════════════════════════════════════════════

class HeaderIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final int? badge;

  const HeaderIconButton({
    super.key,
    required this.icon,
    required this.onTap,
    this.badge,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Material(
          color: HoorColors.surface,
          borderRadius: BorderRadius.circular(HoorRadius.md),
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(HoorRadius.md),
            child: Container(
              padding: EdgeInsets.all(HoorSpacing.sm.w),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(HoorRadius.md),
                border: Border.all(color: HoorColors.border),
              ),
              child: Icon(
                icon,
                size: HoorIconSize.md,
                color: HoorColors.textSecondary,
              ),
            ),
          ),
        ),
        if (badge != null && badge! > 0)
          Positioned(
            top: 0,
            left: 0,
            child: Container(
              padding: EdgeInsets.all(4.w),
              decoration: const BoxDecoration(
                color: HoorColors.error,
                shape: BoxShape.circle,
              ),
              child: Text(
                badge! > 9 ? '9+' : badge.toString(),
                style: HoorTypography.labelSmall.copyWith(
                  color: Colors.white,
                  fontSize: 10.sp,
                ),
              ),
            ),
          ),
      ],
    );
  }
}
