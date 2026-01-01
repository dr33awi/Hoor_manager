// ═══════════════════════════════════════════════════════════════════════════
// Alerts Widget Component
// Displays important notifications and warnings
// ═══════════════════════════════════════════════════════════════════════════

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../core/theme/pro/design_tokens.dart';

/// Alert severity levels
enum AlertSeverity {
  critical,
  warning,
  info,
  success,
}

/// Alert data model
class AlertItem {
  const AlertItem({
    required this.id,
    required this.severity,
    required this.title,
    required this.message,
    this.actionLabel,
    this.onAction,
    this.timestamp,
  });

  final String id;
  final AlertSeverity severity;
  final String title;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;
  final DateTime? timestamp;
}

class AlertsWidget extends StatelessWidget {
  const AlertsWidget({
    super.key,
    this.alerts,
    this.maxItems = 3,
    this.onAlertTap,
    this.onDismiss,
  });

  final List<AlertItem>? alerts;
  final int maxItems;
  final void Function(AlertItem)? onAlertTap;
  final void Function(AlertItem)? onDismiss;

  @override
  Widget build(BuildContext context) {
    final items = alerts ?? _sampleAlerts;

    if (items.isEmpty) {
      return _buildEmptyState();
    }

    return Column(
      children: [
        for (int i = 0; i < items.take(maxItems).length; i++) ...[
          _AlertCard(
            alert: items[i],
            onTap: () {
              HapticFeedback.lightImpact();
              onAlertTap?.call(items[i]);
            },
            onDismiss: onDismiss != null ? () => onDismiss!(items[i]) : null,
          ),
          if (i < items.take(maxItems).length - 1)
            SizedBox(height: AppSpacing.sm.h),
        ],
      ],
    );
  }

  Widget _buildEmptyState() {
    return Container(
      padding: EdgeInsets.all(AppSpacing.lg.w),
      decoration: BoxDecoration(
        color: AppColors.incomeSurface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(
          color: AppColors.income.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(AppSpacing.sm.w),
            decoration: BoxDecoration(
              color: AppColors.income.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
            child: Icon(
              Icons.check_circle_outline_rounded,
              color: AppColors.income,
              size: AppIconSize.lg,
            ),
          ),
          SizedBox(width: AppSpacing.md.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'كل شيء على ما يرام!',
                  style: AppTypography.titleSmall.copyWith(
                    color: AppColors.incomeDark,
                  ),
                ),
                SizedBox(height: AppSpacing.xxxs.h),
                Text(
                  'لا توجد تنبيهات تحتاج لانتباهك',
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static final _sampleAlerts = [
    AlertItem(
      id: '1',
      severity: AlertSeverity.warning,
      title: 'منتجات وصلت للحد الأدنى',
      message: '3 منتجات تحتاج لإعادة طلب',
      actionLabel: 'عرض المنتجات',
    ),
    AlertItem(
      id: '2',
      severity: AlertSeverity.info,
      title: 'فواتير مستحقة اليوم',
      message: '2 فواتير بقيمة 3,500 ر.س',
      actionLabel: 'عرض الفواتير',
    ),
  ];
}

class _AlertCard extends StatelessWidget {
  const _AlertCard({
    required this.alert,
    this.onTap,
    this.onDismiss,
  });

  final AlertItem alert;
  final VoidCallback? onTap;
  final VoidCallback? onDismiss;

  @override
  Widget build(BuildContext context) {
    final severityInfo = _getSeverityInfo(alert.severity);

    return Dismissible(
      key: Key(alert.id),
      direction: onDismiss != null
          ? DismissDirection.endToStart
          : DismissDirection.none,
      onDismissed: (_) => onDismiss?.call(),
      background: Container(
        alignment: Alignment.centerLeft,
        padding: EdgeInsets.only(left: AppSpacing.lg.w),
        decoration: BoxDecoration(
          color: AppColors.expense,
          borderRadius: BorderRadius.circular(AppRadius.lg),
        ),
        child: Icon(
          Icons.delete_outline_rounded,
          color: Colors.white,
          size: AppIconSize.lg,
        ),
      ),
      child: Material(
        color: severityInfo.bgColor,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        child: InkWell(
          onTap: onTap ?? alert.onAction,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          child: Container(
            padding: EdgeInsets.all(AppSpacing.md.w),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppRadius.lg),
              border: Border.all(
                color: severityInfo.color.withValues(alpha: 0.3),
              ),
            ),
            child: Row(
              children: [
                // Icon
                Container(
                  padding: EdgeInsets.all(AppSpacing.sm.w),
                  decoration: BoxDecoration(
                    color: severityInfo.color.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(AppRadius.md),
                  ),
                  child: Icon(
                    severityInfo.icon,
                    color: severityInfo.color,
                    size: AppIconSize.md,
                  ),
                ),
                SizedBox(width: AppSpacing.md.w),

                // Content
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        alert.title,
                        style: AppTypography.titleSmall.copyWith(
                          color: severityInfo.textColor,
                        ),
                      ),
                      SizedBox(height: AppSpacing.xxxs.h),
                      Text(
                        alert.message,
                        style: AppTypography.bodySmall.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),

                // Action
                if (alert.actionLabel != null)
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: AppSpacing.sm.w,
                      vertical: AppSpacing.xs.h,
                    ),
                    decoration: BoxDecoration(
                      color: severityInfo.color.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(AppRadius.full),
                    ),
                    child: Text(
                      alert.actionLabel!,
                      style: AppTypography.labelSmall.copyWith(
                        color: severityInfo.color,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  )
                else
                  Icon(
                    Icons.chevron_left_rounded,
                    color: AppColors.textTertiary,
                    size: AppIconSize.md,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  ({IconData icon, Color color, Color bgColor, Color textColor})
      _getSeverityInfo(
    AlertSeverity severity,
  ) {
    return switch (severity) {
      AlertSeverity.critical => (
          icon: Icons.error_outline_rounded,
          color: AppColors.expense,
          bgColor: AppColors.expenseSurface,
          textColor: AppColors.expenseDark,
        ),
      AlertSeverity.warning => (
          icon: Icons.warning_amber_rounded,
          color: AppColors.warning,
          bgColor: AppColors.warningSurface,
          textColor: AppColors.warning,
        ),
      AlertSeverity.info => (
          icon: Icons.info_outline_rounded,
          color: AppColors.info,
          bgColor: AppColors.infoSurface,
          textColor: AppColors.info,
        ),
      AlertSeverity.success => (
          icon: Icons.check_circle_outline_rounded,
          color: AppColors.income,
          bgColor: AppColors.incomeSurface,
          textColor: AppColors.incomeDark,
        ),
    };
  }
}
