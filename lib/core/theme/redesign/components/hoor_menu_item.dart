import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../design_tokens.dart';
import '../typography.dart';

/// ═══════════════════════════════════════════════════════════════════════════
/// HoorMenuItem - Navigation Menu Item Components
/// Professional menu cards with consistent styling
/// ═══════════════════════════════════════════════════════════════════════════

class HoorMenuItem extends StatelessWidget {
  final String title;
  final String? subtitle;
  final IconData icon;
  final Color? color;
  final VoidCallback onTap;
  final bool showBadge;
  final String? badgeText;
  final bool isNew;

  const HoorMenuItem({
    super.key,
    required this.title,
    this.subtitle,
    required this.icon,
    this.color,
    required this.onTap,
    this.showBadge = false,
    this.badgeText,
    this.isNew = false,
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
          padding: EdgeInsets.all(HoorSpacing.md),
          decoration: BoxDecoration(
            color: HoorColors.surface,
            borderRadius: HoorRadius.cardRadius,
            border: Border.all(color: HoorColors.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: EdgeInsets.all(HoorSpacing.sm),
                    decoration: BoxDecoration(
                      color: effectiveColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(HoorRadius.md),
                    ),
                    child: Icon(
                      icon,
                      color: effectiveColor,
                      size: HoorIconSize.md,
                    ),
                  ),
                  if (showBadge || isNew) _buildBadge(effectiveColor),
                ],
              ),
              SizedBox(height: HoorSpacing.sm),
              Text(
                title,
                style: HoorTypography.titleSmall.copyWith(
                  color: HoorColors.textPrimary,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              if (subtitle != null)
                Text(
                  subtitle!,
                  style: HoorTypography.bodySmall.copyWith(
                    color: HoorColors.textSecondary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBadge(Color color) {
    if (isNew) {
      return Container(
        padding: EdgeInsets.symmetric(
          horizontal: HoorSpacing.xs,
          vertical: 2.h,
        ),
        decoration: BoxDecoration(
          color: HoorColors.success,
          borderRadius: BorderRadius.circular(HoorRadius.full),
        ),
        child: Text(
          'جديد',
          style: HoorTypography.labelSmall.copyWith(
            color: Colors.white,
            fontSize: 9.sp,
          ),
        ),
      );
    }

    if (badgeText != null) {
      return Container(
        padding: EdgeInsets.symmetric(
          horizontal: HoorSpacing.xs,
          vertical: 2.h,
        ),
        constraints: BoxConstraints(minWidth: 20.w),
        decoration: BoxDecoration(
          color: HoorColors.error,
          borderRadius: BorderRadius.circular(HoorRadius.full),
        ),
        child: Text(
          badgeText!,
          style: HoorTypography.labelSmall.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.w700,
          ),
          textAlign: TextAlign.center,
        ),
      );
    }

    return Container(
      width: 8.w,
      height: 8.w,
      decoration: const BoxDecoration(
        color: HoorColors.error,
        shape: BoxShape.circle,
      ),
    );
  }
}

/// ═══════════════════════════════════════════════════════════════════════════
/// List Style Menu Item
/// ═══════════════════════════════════════════════════════════════════════════

class HoorMenuListItem extends StatelessWidget {
  final String title;
  final String? subtitle;
  final IconData icon;
  final Color? color;
  final VoidCallback onTap;
  final Widget? trailing;
  final bool showArrow;
  final bool isDestructive;

  const HoorMenuListItem({
    super.key,
    required this.title,
    this.subtitle,
    required this.icon,
    this.color,
    required this.onTap,
    this.trailing,
    this.showArrow = true,
    this.isDestructive = false,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveColor =
        isDestructive ? HoorColors.error : (color ?? HoorColors.primary);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: HoorSpacing.md,
            vertical: HoorSpacing.sm,
          ),
          child: Row(
            children: [
              Container(
                padding: EdgeInsets.all(HoorSpacing.sm),
                decoration: BoxDecoration(
                  color: effectiveColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(HoorRadius.md),
                ),
                child: Icon(
                  icon,
                  color: effectiveColor,
                  size: HoorIconSize.md,
                ),
              ),
              SizedBox(width: HoorSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: HoorTypography.bodyMedium.copyWith(
                        color: isDestructive
                            ? HoorColors.error
                            : HoorColors.textPrimary,
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
              if (trailing != null) trailing!,
              if (showArrow && trailing == null)
                Icon(
                  Icons.arrow_forward_ios_rounded,
                  color: HoorColors.textTertiary,
                  size: HoorIconSize.sm,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// ═══════════════════════════════════════════════════════════════════════════
/// Divider with optional label
/// ═══════════════════════════════════════════════════════════════════════════

class HoorDivider extends StatelessWidget {
  final String? label;
  final EdgeInsetsGeometry? margin;

  const HoorDivider({
    super.key,
    this.label,
    this.margin,
  });

  @override
  Widget build(BuildContext context) {
    if (label == null) {
      return Padding(
        padding: margin ?? EdgeInsets.symmetric(vertical: HoorSpacing.sm),
        child: const Divider(height: 1),
      );
    }

    return Padding(
      padding: margin ?? EdgeInsets.symmetric(vertical: HoorSpacing.sm),
      child: Row(
        children: [
          const Expanded(child: Divider()),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: HoorSpacing.md),
            child: Text(
              label!,
              style: HoorTypography.caption,
            ),
          ),
          const Expanded(child: Divider()),
        ],
      ),
    );
  }
}
