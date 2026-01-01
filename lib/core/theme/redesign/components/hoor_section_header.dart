import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../design_tokens.dart';
import '../typography.dart';

/// ═══════════════════════════════════════════════════════════════════════════
/// HoorSectionHeader - Section Header Components
/// Clean section dividers with optional actions
/// ═══════════════════════════════════════════════════════════════════════════

class HoorSectionHeader extends StatelessWidget {
  final String title;
  final IconData? icon;
  final String? actionLabel;
  final VoidCallback? onActionTap;
  final Widget? trailing;
  final EdgeInsetsGeometry? padding;
  final bool showDivider;

  const HoorSectionHeader({
    super.key,
    required this.title,
    this.icon,
    this.actionLabel,
    this.onActionTap,
    this.trailing,
    this.padding,
    this.showDivider = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: padding ??
          EdgeInsets.symmetric(
            horizontal: HoorSpacing.md,
            vertical: HoorSpacing.sm,
          ),
      child: Row(
        children: [
          if (icon != null) ...[
            Icon(
              icon,
              color: HoorColors.textSecondary,
              size: HoorIconSize.sm,
            ),
            SizedBox(width: HoorSpacing.xs),
          ],
          Expanded(
            child: Text(
              title,
              style: HoorTypography.labelLarge.copyWith(
                color: HoorColors.textSecondary,
              ),
            ),
          ),
          if (showDivider)
            Expanded(
              child: Container(
                height: 1.h,
                margin: EdgeInsets.only(right: HoorSpacing.md),
                color: HoorColors.border,
              ),
            ),
          if (trailing != null)
            trailing!
          else if (actionLabel != null && onActionTap != null)
            TextButton(
              onPressed: onActionTap,
              style: TextButton.styleFrom(
                padding: EdgeInsets.symmetric(
                  horizontal: HoorSpacing.sm,
                ),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: Text(
                actionLabel!,
                style: HoorTypography.labelMedium.copyWith(
                  color: HoorColors.primary,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// ═══════════════════════════════════════════════════════════════════════════
/// Decorated Section Header
/// ═══════════════════════════════════════════════════════════════════════════

class HoorDecoratedHeader extends StatelessWidget {
  final String title;
  final String? subtitle;
  final IconData? icon;
  final Color? color;
  final Widget? action;
  final EdgeInsetsGeometry? padding;

  const HoorDecoratedHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.icon,
    this.color,
    this.action,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveColor = color ?? HoorColors.primary;

    return Padding(
      padding: padding ?? EdgeInsets.all(HoorSpacing.md),
      child: Row(
        children: [
          Container(
            width: 4.w,
            height: subtitle != null ? 44.h : 32.h,
            decoration: BoxDecoration(
              color: effectiveColor,
              borderRadius: BorderRadius.circular(2.r),
            ),
          ),
          SizedBox(width: HoorSpacing.md),
          if (icon != null) ...[
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
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: HoorTypography.titleMedium.copyWith(
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
          if (action != null) action!,
        ],
      ),
    );
  }
}

/// ═══════════════════════════════════════════════════════════════════════════
/// Page Header with background
/// ═══════════════════════════════════════════════════════════════════════════

class HoorPageHeader extends StatelessWidget {
  final String title;
  final String? subtitle;
  final Widget? leading;
  final List<Widget>? actions;
  final Color? backgroundColor;
  final bool useGradient;
  final double height;

  const HoorPageHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.leading,
    this.actions,
    this.backgroundColor,
    this.useGradient = true,
    this.height = 160,
  });

  @override
  Widget build(BuildContext context) {
    final bgColor = backgroundColor ?? HoorColors.primary;

    return Container(
      width: double.infinity,
      height: height.h,
      decoration: BoxDecoration(
        gradient: useGradient
            ? LinearGradient(
                colors: [bgColor, bgColor.withValues(alpha: 0.85)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              )
            : null,
        color: useGradient ? null : bgColor,
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: EdgeInsets.all(HoorSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  if (leading != null) leading!,
                  const Spacer(),
                  if (actions != null) ...actions!,
                ],
              ),
              const Spacer(),
              Text(
                title,
                style: HoorTypography.headlineLarge.copyWith(
                  color: Colors.white,
                ),
              ),
              if (subtitle != null) ...[
                SizedBox(height: HoorSpacing.xxs),
                Text(
                  subtitle!,
                  style: HoorTypography.bodyMedium.copyWith(
                    color: Colors.white.withValues(alpha: 0.8),
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
/// Collapsible Section
/// ═══════════════════════════════════════════════════════════════════════════

class HoorCollapsibleSection extends StatefulWidget {
  final String title;
  final IconData? icon;
  final Widget child;
  final bool initiallyExpanded;
  final EdgeInsetsGeometry? padding;

  const HoorCollapsibleSection({
    super.key,
    required this.title,
    this.icon,
    required this.child,
    this.initiallyExpanded = true,
    this.padding,
  });

  @override
  State<HoorCollapsibleSection> createState() => _HoorCollapsibleSectionState();
}

class _HoorCollapsibleSectionState extends State<HoorCollapsibleSection>
    with SingleTickerProviderStateMixin {
  late bool _isExpanded;
  late AnimationController _controller;
  late Animation<double> _iconTurns;
  late Animation<double> _heightFactor;

  @override
  void initState() {
    super.initState();
    _isExpanded = widget.initiallyExpanded;
    _controller = AnimationController(
      duration: HoorDurations.normal,
      vsync: this,
    );
    _iconTurns = Tween<double>(begin: 0.0, end: 0.5).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
    _heightFactor = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    );

    if (_isExpanded) {
      _controller.value = 1.0;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _toggle() {
    setState(() {
      _isExpanded = !_isExpanded;
      if (_isExpanded) {
        _controller.forward();
      } else {
        _controller.reverse();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        InkWell(
          onTap: _toggle,
          child: Padding(
            padding: widget.padding ??
                EdgeInsets.symmetric(
                  horizontal: HoorSpacing.md,
                  vertical: HoorSpacing.sm,
                ),
            child: Row(
              children: [
                if (widget.icon != null) ...[
                  Icon(
                    widget.icon,
                    color: HoorColors.textSecondary,
                    size: HoorIconSize.sm,
                  ),
                  SizedBox(width: HoorSpacing.xs),
                ],
                Expanded(
                  child: Text(
                    widget.title,
                    style: HoorTypography.labelLarge.copyWith(
                      color: HoorColors.textSecondary,
                    ),
                  ),
                ),
                RotationTransition(
                  turns: _iconTurns,
                  child: Icon(
                    Icons.keyboard_arrow_down_rounded,
                    color: HoorColors.textSecondary,
                    size: HoorIconSize.md,
                  ),
                ),
              ],
            ),
          ),
        ),
        ClipRect(
          child: SizeTransition(
            sizeFactor: _heightFactor,
            child: widget.child,
          ),
        ),
      ],
    );
  }
}
