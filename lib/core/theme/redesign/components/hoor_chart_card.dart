import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../design_tokens.dart';
import '../typography.dart';

/// ═══════════════════════════════════════════════════════════════════════════
/// HoorChartCard - Chart Container Components
/// Wrapper cards for charts with headers and legends
/// ═══════════════════════════════════════════════════════════════════════════

class HoorChartCard extends StatelessWidget {
  final String title;
  final String? subtitle;
  final Widget chart;
  final List<HoorLegendItem>? legend;
  final Widget? action;
  final double height;
  final EdgeInsetsGeometry? padding;
  final bool showBorder;

  const HoorChartCard({
    super.key,
    required this.title,
    this.subtitle,
    required this.chart,
    this.legend,
    this.action,
    this.height = 250,
    this.padding,
    this.showBorder = true,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: HoorColors.surface,
        borderRadius: HoorRadius.cardRadius,
        border: showBorder ? Border.all(color: HoorColors.border) : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildHeader(),
          if (legend != null && legend!.isNotEmpty) _buildLegend(),
          SizedBox(
            height: height.h,
            child: Padding(
              padding: padding ?? EdgeInsets.all(HoorSpacing.md),
              child: chart,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        HoorSpacing.md,
        HoorSpacing.md,
        HoorSpacing.md,
        0,
      ),
      child: Row(
        children: [
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

  Widget _buildLegend() {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        HoorSpacing.md,
        HoorSpacing.sm,
        HoorSpacing.md,
        0,
      ),
      child: Wrap(
        spacing: HoorSpacing.md,
        runSpacing: HoorSpacing.xs,
        children: legend!.map((item) => _buildLegendItem(item)).toList(),
      ),
    );
  }

  Widget _buildLegendItem(HoorLegendItem item) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12.w,
          height: 12.w,
          decoration: BoxDecoration(
            color: item.color,
            borderRadius: BorderRadius.circular(3.r),
          ),
        ),
        SizedBox(width: HoorSpacing.xs),
        Text(
          item.label,
          style: HoorTypography.labelSmall.copyWith(
            color: HoorColors.textSecondary,
          ),
        ),
        if (item.value != null) ...[
          SizedBox(width: HoorSpacing.xxs),
          Text(
            item.value!,
            style: HoorTypography.labelSmall.copyWith(
              color: HoorColors.textPrimary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ],
    );
  }
}

class HoorLegendItem {
  final String label;
  final Color color;
  final String? value;

  const HoorLegendItem({
    required this.label,
    required this.color,
    this.value,
  });
}

/// ═══════════════════════════════════════════════════════════════════════════
/// Mini Chart for Dashboard Stats
/// ═══════════════════════════════════════════════════════════════════════════

class HoorMiniChart extends StatelessWidget {
  final List<double> data;
  final Color? color;
  final double height;
  final bool showDots;
  final bool filled;

  const HoorMiniChart({
    super.key,
    required this.data,
    this.color,
    this.height = 40,
    this.showDots = false,
    this.filled = true,
  });

  @override
  Widget build(BuildContext context) {
    if (data.isEmpty) return SizedBox(height: height.h);

    final effectiveColor = color ?? HoorColors.primary;

    return SizedBox(
      height: height.h,
      child: CustomPaint(
        size: Size(double.infinity, height.h),
        painter: _MiniChartPainter(
          data: data,
          color: effectiveColor,
          showDots: showDots,
          filled: filled,
        ),
      ),
    );
  }
}

class _MiniChartPainter extends CustomPainter {
  final List<double> data;
  final Color color;
  final bool showDots;
  final bool filled;

  _MiniChartPainter({
    required this.data,
    required this.color,
    required this.showDots,
    required this.filled,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (data.isEmpty) return;

    final maxValue = data.reduce((a, b) => a > b ? a : b);
    final minValue = data.reduce((a, b) => a < b ? a : b);
    final range = maxValue - minValue;

    final points = <Offset>[];
    final spacing = size.width / (data.length - 1);

    for (var i = 0; i < data.length; i++) {
      final x = i * spacing;
      final normalizedY = range > 0 ? (data[i] - minValue) / range : 0.5;
      final y = size.height - (normalizedY * size.height);
      points.add(Offset(x, y.clamp(0, size.height)));
    }

    // Draw filled area
    if (filled && points.length > 1) {
      final fillPath = Path()
        ..moveTo(points.first.dx, size.height)
        ..lineTo(points.first.dx, points.first.dy);

      for (final point in points.skip(1)) {
        fillPath.lineTo(point.dx, point.dy);
      }

      fillPath
        ..lineTo(points.last.dx, size.height)
        ..close();

      final fillPaint = Paint()
        ..color = color.withValues(alpha: 0.1)
        ..style = PaintingStyle.fill;

      canvas.drawPath(fillPath, fillPaint);
    }

    // Draw line
    if (points.length > 1) {
      final linePath = Path()..moveTo(points.first.dx, points.first.dy);

      for (final point in points.skip(1)) {
        linePath.lineTo(point.dx, point.dy);
      }

      final linePaint = Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.w
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round;

      canvas.drawPath(linePath, linePaint);
    }

    // Draw dots
    if (showDots) {
      final dotPaint = Paint()
        ..color = color
        ..style = PaintingStyle.fill;

      for (final point in points) {
        canvas.drawCircle(point, 3.r, dotPaint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

/// ═══════════════════════════════════════════════════════════════════════════
/// Progress/Percentage Indicators
/// ═══════════════════════════════════════════════════════════════════════════

class HoorProgressBar extends StatelessWidget {
  final double value;
  final Color? color;
  final Color? backgroundColor;
  final double height;
  final BorderRadius? borderRadius;
  final String? label;
  final bool showPercentage;

  const HoorProgressBar({
    super.key,
    required this.value,
    this.color,
    this.backgroundColor,
    this.height = 8,
    this.borderRadius,
    this.label,
    this.showPercentage = false,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveColor = color ?? HoorColors.primary;
    final effectiveBackground = backgroundColor ?? HoorColors.surfaceMuted;
    final effectiveRadius = borderRadius ?? BorderRadius.circular(height.h / 2);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (label != null || showPercentage)
          Padding(
            padding: EdgeInsets.only(bottom: HoorSpacing.xs),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                if (label != null)
                  Text(
                    label!,
                    style: HoorTypography.labelSmall.copyWith(
                      color: HoorColors.textSecondary,
                    ),
                  ),
                if (showPercentage)
                  Text(
                    '${(value * 100).toStringAsFixed(0)}%',
                    style: HoorTypography.labelSmall.copyWith(
                      color: HoorColors.textPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
              ],
            ),
          ),
        Container(
          height: height.h,
          decoration: BoxDecoration(
            color: effectiveBackground,
            borderRadius: effectiveRadius,
          ),
          child: FractionallySizedBox(
            alignment: Alignment.centerRight,
            widthFactor: value.clamp(0, 1),
            child: Container(
              decoration: BoxDecoration(
                color: effectiveColor,
                borderRadius: effectiveRadius,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class HoorCircularProgress extends StatelessWidget {
  final double value;
  final Color? color;
  final Color? backgroundColor;
  final double size;
  final double strokeWidth;
  final Widget? center;
  final bool showPercentage;

  const HoorCircularProgress({
    super.key,
    required this.value,
    this.color,
    this.backgroundColor,
    this.size = 80,
    this.strokeWidth = 8,
    this.center,
    this.showPercentage = true,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveColor = color ?? HoorColors.primary;
    final effectiveBackground = backgroundColor ?? HoorColors.surfaceMuted;

    return SizedBox(
      width: size.w,
      height: size.w,
      child: Stack(
        alignment: Alignment.center,
        children: [
          SizedBox(
            width: size.w,
            height: size.w,
            child: CircularProgressIndicator(
              value: value.clamp(0, 1),
              strokeWidth: strokeWidth.w,
              backgroundColor: effectiveBackground,
              valueColor: AlwaysStoppedAnimation(effectiveColor),
              strokeCap: StrokeCap.round,
            ),
          ),
          if (center != null)
            center!
          else if (showPercentage)
            Text(
              '${(value * 100).toStringAsFixed(0)}%',
              style: HoorTypography.titleMedium.copyWith(
                color: HoorColors.textPrimary,
                fontWeight: FontWeight.w700,
              ),
            ),
        ],
      ),
    );
  }
}
