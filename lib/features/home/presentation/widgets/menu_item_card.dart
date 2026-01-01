import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../core/theme/redesign/design_system.dart';

/// ═══════════════════════════════════════════════════════════════════════════
/// Menu Item Card - Modern Navigation Menu Item with Hover Effects
/// ═══════════════════════════════════════════════════════════════════════════

class MenuItemCard extends StatefulWidget {
  final IconData icon;
  final String label;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;
  final String? badge;

  const MenuItemCard({
    super.key,
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.color,
    required this.onTap,
    this.badge,
  });

  @override
  State<MenuItemCard> createState() => _MenuItemCardState();
}

class _MenuItemCardState extends State<MenuItemCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<Color?> _colorAnimation;
  bool _isPressed = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.98).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
    );

    _colorAnimation = ColorTween(
      begin: HoorColors.surface,
      end: widget.color.withValues(alpha: 0.05),
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onTapDown(TapDownDetails details) {
    setState(() => _isPressed = true);
    _controller.forward();
  }

  void _onTapUp(TapUpDetails details) {
    setState(() => _isPressed = false);
    _controller.reverse();
  }

  void _onTapCancel() {
    setState(() => _isPressed = false);
    _controller.reverse();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: _onTapDown,
      onTapUp: _onTapUp,
      onTapCancel: _onTapCancel,
      onTap: widget.onTap,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: Container(
              padding: EdgeInsets.all(HoorSpacing.md.w),
              decoration: BoxDecoration(
                color: _colorAnimation.value,
                borderRadius: BorderRadius.circular(HoorRadius.xl),
                border: Border.all(
                  color: _isPressed
                      ? widget.color.withValues(alpha: 0.3)
                      : HoorColors.border.withValues(alpha: 0.5),
                  width: _isPressed ? 1.5 : 1,
                ),
                boxShadow: _isPressed ? HoorShadows.sm : HoorShadows.xs,
              ),
              child: Row(
                children: [
                  // Icon Container with gradient
                  Container(
                    padding: EdgeInsets.all(HoorSpacing.sm.w),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          widget.color.withValues(alpha: 0.15),
                          widget.color.withValues(alpha: 0.08),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(HoorRadius.lg),
                      border: Border.all(
                        color: widget.color.withValues(alpha: 0.1),
                      ),
                    ),
                    child: Icon(
                      widget.icon,
                      color: widget.color,
                      size: HoorIconSize.lg,
                    ),
                  ),
                  SizedBox(width: HoorSpacing.md.w),

                  // Text Content
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                widget.label,
                                style: HoorTypography.titleSmall.copyWith(
                                  fontWeight: FontWeight.w600,
                                  color: HoorColors.textPrimary,
                                ),
                              ),
                            ),
                            if (widget.badge != null)
                              Container(
                                padding: EdgeInsets.symmetric(
                                  horizontal: HoorSpacing.xs.w,
                                  vertical: 2.h,
                                ),
                                decoration: BoxDecoration(
                                  color: widget.color,
                                  borderRadius:
                                      BorderRadius.circular(HoorRadius.full),
                                ),
                                child: Text(
                                  widget.badge!,
                                  style: HoorTypography.labelSmall.copyWith(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 10.sp,
                                  ),
                                ),
                              ),
                          ],
                        ),
                        SizedBox(height: 3.h),
                        Text(
                          widget.subtitle,
                          style: HoorTypography.bodySmall.copyWith(
                            color: HoorColors.textSecondary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),

                  // Animated Arrow
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: EdgeInsets.all(HoorSpacing.xs.w),
                    decoration: BoxDecoration(
                      color: _isPressed
                          ? widget.color.withValues(alpha: 0.1)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(HoorRadius.md),
                    ),
                    child: Icon(
                      Icons.chevron_left_rounded,
                      color: _isPressed
                          ? widget.color
                          : HoorColors.textSecondary.withValues(alpha: 0.5),
                      size: HoorIconSize.md,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
