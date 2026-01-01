import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'dart:ui';

import '../../../../core/theme/redesign/design_system.dart';

/// ═══════════════════════════════════════════════════════════════════════════
/// Shift Status Card - Premium Hero Card with Glassmorphism
/// ═══════════════════════════════════════════════════════════════════════════

class ShiftStatusCard extends StatefulWidget {
  final bool hasOpenShift;
  final VoidCallback onTap;

  const ShiftStatusCard({
    super.key,
    required this.hasOpenShift,
    required this.onTap,
  });

  @override
  State<ShiftStatusCard> createState() => _ShiftStatusCardState();
}

class _ShiftStatusCardState extends State<ShiftStatusCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.15).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    if (widget.hasOpenShift) {
      _pulseController.repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(ShiftStatusCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.hasOpenShift && !_pulseController.isAnimating) {
      _pulseController.repeat(reverse: true);
    } else if (!widget.hasOpenShift) {
      _pulseController.stop();
      _pulseController.reset();
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final gradientColors = widget.hasOpenShift
        ? [
            const Color(0xFF12334E),
            const Color(0xFF1E4A6E),
            const Color(0xFF2A5F8F)
          ]
        : [
            const Color(0xFFFF9A56),
            const Color(0xFFFF6B6B),
            const Color(0xFFEE5A24)
          ];

    return GestureDetector(
      onTap: widget.onTap,
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: gradientColors,
            begin: Alignment.topRight,
            end: Alignment.bottomLeft,
          ),
          borderRadius: BorderRadius.circular(HoorRadius.xxl),
          boxShadow: [
            BoxShadow(
              color: gradientColors[0].withValues(alpha: 0.35),
              blurRadius: 24,
              offset: const Offset(0, 12),
              spreadRadius: -4,
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(HoorRadius.xxl),
          child: Stack(
            children: [
              // Background pattern
              Positioned(
                top: -50,
                left: -50,
                child: Container(
                  width: 200,
                  height: 200,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withValues(alpha: 0.05),
                  ),
                ),
              ),
              Positioned(
                bottom: -30,
                right: -30,
                child: Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withValues(alpha: 0.05),
                  ),
                ),
              ),
              // Content
              Padding(
                padding: EdgeInsets.all(HoorSpacing.xl.w),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildTopRow(),
                    SizedBox(height: HoorSpacing.xl.h),
                    _buildTitle(),
                    SizedBox(height: HoorSpacing.xs.h),
                    _buildDescription(),
                    if (!widget.hasOpenShift) ...[
                      SizedBox(height: HoorSpacing.xl.h),
                      _buildOpenShiftButton(),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTopRow() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // Status Icon with glass effect
        ClipRRect(
          borderRadius: BorderRadius.circular(HoorRadius.lg),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
            child: Container(
              padding: EdgeInsets.all(HoorSpacing.md.w),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(HoorRadius.lg),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.2),
                ),
              ),
              child: Icon(
                widget.hasOpenShift
                    ? Icons.lock_open_rounded
                    : Icons.lock_outline_rounded,
                color: Colors.white,
                size: HoorIconSize.xl,
              ),
            ),
          ),
        ),

        // Status Badge with pulse animation
        AnimatedBuilder(
          animation: _pulseAnimation,
          builder: (context, child) {
            return Transform.scale(
              scale: widget.hasOpenShift ? _pulseAnimation.value : 1.0,
              child: Container(
                padding: EdgeInsets.symmetric(
                  horizontal: HoorSpacing.md.w,
                  vertical: HoorSpacing.sm.h,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(HoorRadius.full),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 10.w,
                      height: 10.w,
                      decoration: BoxDecoration(
                        color: widget.hasOpenShift
                            ? const Color(0xFF4ADE80)
                            : Colors.white.withValues(alpha: 0.7),
                        shape: BoxShape.circle,
                        boxShadow: widget.hasOpenShift
                            ? [
                                BoxShadow(
                                  color: const Color(0xFF4ADE80)
                                      .withValues(alpha: 0.5),
                                  blurRadius: 8,
                                  spreadRadius: 2,
                                ),
                              ]
                            : null,
                      ),
                    ),
                    SizedBox(width: HoorSpacing.sm.w),
                    Text(
                      widget.hasOpenShift ? 'نشط الآن' : 'مغلق',
                      style: HoorTypography.labelMedium.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildTitle() {
    return Text(
      widget.hasOpenShift ? 'الوردية مفتوحة' : 'لا توجد وردية مفتوحة',
      style: HoorTypography.headlineMedium.copyWith(
        color: Colors.white,
        fontWeight: FontWeight.bold,
      ),
    );
  }

  Widget _buildDescription() {
    return Text(
      widget.hasOpenShift
          ? 'يمكنك إجراء العمليات المالية والمبيعات'
          : 'يجب فتح وردية جديدة للبدء في العمل',
      style: HoorTypography.bodyMedium.copyWith(
        color: Colors.white.withValues(alpha: 0.9),
      ),
    );
  }

  Widget _buildOpenShiftButton() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(HoorRadius.lg),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
        child: Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(HoorRadius.lg),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.3),
            ),
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: widget.onTap,
              borderRadius: BorderRadius.circular(HoorRadius.lg),
              child: Padding(
                padding: EdgeInsets.symmetric(
                  vertical: HoorSpacing.md.h,
                  horizontal: HoorSpacing.lg.w,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: EdgeInsets.all(HoorSpacing.xs.w),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.add_rounded,
                        color: Colors.white,
                        size: HoorIconSize.md,
                      ),
                    ),
                    SizedBox(width: HoorSpacing.sm.w),
                    Text(
                      'فتح وردية جديدة',
                      style: HoorTypography.labelLarge.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
