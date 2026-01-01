import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../design_tokens.dart';
import '../typography.dart';

/// ═══════════════════════════════════════════════════════════════════════════
/// HoorQuickAction - Quick Action Button Components
/// Professional, colorful action buttons for common operations
/// ═══════════════════════════════════════════════════════════════════════════

class HoorQuickAction extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  final bool isEnabled;
  final bool showBadge;
  final String? badgeText;

  const HoorQuickAction({
    super.key,
    required this.label,
    required this.icon,
    required this.color,
    required this.onTap,
    this.isEnabled = true,
    this.showBadge = false,
    this.badgeText,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: isEnabled ? onTap : null,
        borderRadius: HoorRadius.cardRadius,
        child: Opacity(
          opacity: isEnabled ? 1.0 : 0.5,
          child: Container(
            padding: EdgeInsets.symmetric(
              vertical: HoorSpacing.md,
              horizontal: HoorSpacing.sm,
            ),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [color, color.withValues(alpha: 0.85)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: HoorRadius.cardRadius,
              boxShadow: HoorShadows.colored(color, opacity: 0.3),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Container(
                      padding: EdgeInsets.all(HoorSpacing.sm),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        icon,
                        color: Colors.white,
                        size: HoorIconSize.lg,
                      ),
                    ),
                    if (showBadge)
                      Positioned(
                        top: -4.h,
                        left: -4.w,
                        child: Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: HoorSpacing.xxs,
                            vertical: 2.h,
                          ),
                          constraints: BoxConstraints(minWidth: 18.w),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius:
                                BorderRadius.circular(HoorRadius.full),
                          ),
                          child: Text(
                            badgeText ?? '',
                            style: HoorTypography.labelSmall.copyWith(
                              color: color,
                              fontWeight: FontWeight.w700,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                  ],
                ),
                SizedBox(height: HoorSpacing.sm),
                Text(
                  label,
                  style: HoorTypography.labelMedium.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// ═══════════════════════════════════════════════════════════════════════════
/// Horizontal Quick Action (for bottom sheets or horizontal lists)
/// ═══════════════════════════════════════════════════════════════════════════

class HoorQuickActionHorizontal extends StatelessWidget {
  final String label;
  final String? subtitle;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  final bool isEnabled;

  const HoorQuickActionHorizontal({
    super.key,
    required this.label,
    this.subtitle,
    required this.icon,
    required this.color,
    required this.onTap,
    this.isEnabled = true,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: isEnabled ? onTap : null,
        borderRadius: HoorRadius.cardRadius,
        child: Opacity(
          opacity: isEnabled ? 1.0 : 0.5,
          child: Container(
            padding: EdgeInsets.all(HoorSpacing.md),
            decoration: BoxDecoration(
              color: HoorColors.surface,
              borderRadius: HoorRadius.cardRadius,
              border: Border.all(color: HoorColors.border),
            ),
            child: Row(
              children: [
                Container(
                  padding: EdgeInsets.all(HoorSpacing.sm),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(HoorRadius.md),
                  ),
                  child: Icon(icon, color: color, size: HoorIconSize.md),
                ),
                SizedBox(width: HoorSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        label,
                        style: HoorTypography.titleSmall.copyWith(
                          color: HoorColors.textPrimary,
                        ),
                      ),
                      if (subtitle != null) ...[
                        SizedBox(height: 2.h),
                        Text(
                          subtitle!,
                          style: HoorTypography.bodySmall.copyWith(
                            color: HoorColors.textSecondary,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios_rounded,
                  color: HoorColors.textTertiary,
                  size: HoorIconSize.sm,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// ═══════════════════════════════════════════════════════════════════════════
/// Mini Quick Action (for dense grids)
/// ═══════════════════════════════════════════════════════════════════════════

class HoorQuickActionMini extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color? color;
  final VoidCallback onTap;
  final bool isEnabled;

  const HoorQuickActionMini({
    super.key,
    required this.label,
    required this.icon,
    this.color,
    required this.onTap,
    this.isEnabled = true,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveColor = color ?? HoorColors.primary;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: isEnabled ? onTap : null,
        borderRadius: HoorRadius.cardRadius,
        child: Opacity(
          opacity: isEnabled ? 1.0 : 0.5,
          child: Container(
            padding: EdgeInsets.all(HoorSpacing.sm),
            decoration: BoxDecoration(
              color: HoorColors.surface,
              borderRadius: HoorRadius.cardRadius,
              border: Border.all(color: HoorColors.border),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: EdgeInsets.all(HoorSpacing.xs),
                  decoration: BoxDecoration(
                    color: effectiveColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(HoorRadius.sm),
                  ),
                  child: Icon(
                    icon,
                    color: effectiveColor,
                    size: HoorIconSize.md,
                  ),
                ),
                SizedBox(height: HoorSpacing.xs),
                Text(
                  label,
                  style: HoorTypography.labelSmall.copyWith(
                    color: HoorColors.textPrimary,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
