// ═══════════════════════════════════════════════════════════════════════════
// Alerts Screen - Redesigned
// Modern Alerts Management Interface
// ═══════════════════════════════════════════════════════════════════════════

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:hoor_manager/core/theme/redesign/design_tokens.dart';
import 'package:hoor_manager/core/theme/redesign/typography.dart';

import '../../../../core/di/injection.dart';
import '../../../../core/services/alert_service.dart';
import '../../../../data/database/app_database.dart';

/// ═══════════════════════════════════════════════════════════════════════════
/// مزود خدمة التنبيهات (Singleton)
/// ═══════════════════════════════════════════════════════════════════════════
AlertService? _alertServiceInstance;

AlertService getAlertService() {
  _alertServiceInstance ??= AlertService(getIt<AppDatabase>())..initialize();
  return _alertServiceInstance!;
}

/// ═══════════════════════════════════════════════════════════════════════════
/// شاشة التنبيهات
/// ═══════════════════════════════════════════════════════════════════════════
class AlertsScreenRedesign extends StatelessWidget {
  const AlertsScreenRedesign({super.key});

  @override
  Widget build(BuildContext context) {
    final alertService = getAlertService();

    return ListenableBuilder(
      listenable: alertService,
      builder: (context, _) {
        final alerts = alertService.alerts;

        return Scaffold(
          backgroundColor: HoorColors.background,
          appBar: AppBar(
            backgroundColor: HoorColors.surface,
            title: Text('التنبيهات', style: HoorTypography.headlineSmall),
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_rounded),
              onPressed: () => context.pop(),
            ),
            actions: [
              if (alertService.hasUnreadAlerts)
                TextButton.icon(
                  onPressed: () => alertService.markAllAsRead(),
                  icon: Icon(Icons.done_all_rounded,
                      color: HoorColors.primary, size: 18),
                  label: Text(
                    'تحديد الكل',
                    style: HoorTypography.labelMedium.copyWith(
                      color: HoorColors.primary,
                    ),
                  ),
                ),
              IconButton(
                icon: const Icon(Icons.refresh_rounded),
                onPressed: () => alertService.checkAllAlerts(),
                tooltip: 'تحديث',
              ),
            ],
          ),
          body: alerts.isEmpty
              ? _buildEmptyState()
              : _buildAlertsList(context, alertService, alerts),
        );
      },
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: EdgeInsets.all(HoorSpacing.xl.w),
            decoration: BoxDecoration(
              color: HoorColors.success.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.notifications_off_outlined,
                size: 64, color: HoorColors.success),
          ),
          SizedBox(height: HoorSpacing.lg.h),
          Text(
            'لا توجد تنبيهات',
            style: HoorTypography.titleLarge.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: HoorSpacing.xs.h),
          Text(
            'كل شيء على ما يرام!',
            style: HoorTypography.bodyMedium.copyWith(
              color: HoorColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAlertsList(
    BuildContext context,
    AlertService alertService,
    List<Alert> alerts,
  ) {
    // Group alerts by severity
    final criticalAlerts =
        alerts.where((a) => a.severity == AlertSeverity.critical).toList();
    final highAlerts =
        alerts.where((a) => a.severity == AlertSeverity.high).toList();
    final mediumAlerts =
        alerts.where((a) => a.severity == AlertSeverity.medium).toList();
    final lowAlerts =
        alerts.where((a) => a.severity == AlertSeverity.low).toList();

    return ListView(
      padding: EdgeInsets.all(HoorSpacing.md.w),
      children: [
        // Summary Cards
        _buildSummaryCards(alertService),
        SizedBox(height: HoorSpacing.lg.h),

        // Critical Alerts
        if (criticalAlerts.isNotEmpty) ...[
          _buildSectionHeader(
              'تنبيهات حرجة', criticalAlerts.length, HoorColors.error),
          ...criticalAlerts.map((alert) => _AlertCardRedesign(
                alert: alert,
                onTap: () => _handleAlertTap(context, alertService, alert),
                onDismiss: () => alertService.dismissAlert(alert.id),
              )),
          SizedBox(height: HoorSpacing.md.h),
        ],

        // High Alerts
        if (highAlerts.isNotEmpty) ...[
          _buildSectionHeader(
              'تنبيهات مرتفعة', highAlerts.length, HoorColors.warning),
          ...highAlerts.map((alert) => _AlertCardRedesign(
                alert: alert,
                onTap: () => _handleAlertTap(context, alertService, alert),
                onDismiss: () => alertService.dismissAlert(alert.id),
              )),
          SizedBox(height: HoorSpacing.md.h),
        ],

        // Medium Alerts
        if (mediumAlerts.isNotEmpty) ...[
          _buildSectionHeader(
              'تنبيهات متوسطة', mediumAlerts.length, HoorColors.info),
          ...mediumAlerts.map((alert) => _AlertCardRedesign(
                alert: alert,
                onTap: () => _handleAlertTap(context, alertService, alert),
                onDismiss: () => alertService.dismissAlert(alert.id),
              )),
          SizedBox(height: HoorSpacing.md.h),
        ],

        // Low Alerts
        if (lowAlerts.isNotEmpty) ...[
          _buildSectionHeader(
              'تنبيهات منخفضة', lowAlerts.length, HoorColors.success),
          ...lowAlerts.map((alert) => _AlertCardRedesign(
                alert: alert,
                onTap: () => _handleAlertTap(context, alertService, alert),
                onDismiss: () => alertService.dismissAlert(alert.id),
              )),
        ],
      ],
    );
  }

  Widget _buildSummaryCards(AlertService alertService) {
    return Row(
      children: [
        Expanded(
          child: _buildSummaryCard(
            icon: Icons.notifications_active_rounded,
            label: 'غير مقروء',
            count: alertService.unreadCount,
            color: HoorColors.primary,
          ),
        ),
        SizedBox(width: HoorSpacing.sm.w),
        Expanded(
          child: _buildSummaryCard(
            icon: Icons.warning_amber_rounded,
            label: 'حرج',
            count: alertService.criticalAlerts.length,
            color: HoorColors.error,
          ),
        ),
        SizedBox(width: HoorSpacing.sm.w),
        Expanded(
          child: _buildSummaryCard(
            icon: Icons.priority_high_rounded,
            label: 'مرتفع',
            count: alertService.highAlerts.length,
            color: HoorColors.warning,
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryCard({
    required IconData icon,
    required String label,
    required int count,
    required Color color,
  }) {
    return Container(
      padding: EdgeInsets.all(HoorSpacing.md.w),
      decoration: BoxDecoration(
        color: HoorColors.surface,
        borderRadius: BorderRadius.circular(HoorRadius.lg),
        border: Border.all(color: HoorColors.border),
      ),
      child: Column(
        children: [
          Container(
            padding: EdgeInsets.all(HoorSpacing.xs.w),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          SizedBox(height: HoorSpacing.xs.h),
          Text(
            count.toString(),
            style: HoorTypography.titleLarge.copyWith(
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            label,
            style: HoorTypography.labelSmall.copyWith(
              color: HoorColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, int count, Color color) {
    return Padding(
      padding: EdgeInsets.only(bottom: HoorSpacing.sm.h),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 20,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          SizedBox(width: HoorSpacing.sm.w),
          Text(
            title,
            style: HoorTypography.titleSmall.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(width: HoorSpacing.xs.w),
          Container(
            padding: EdgeInsets.symmetric(
              horizontal: HoorSpacing.xs.w,
              vertical: 2,
            ),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(HoorRadius.sm),
            ),
            child: Text(
              count.toString(),
              style: HoorTypography.labelSmall.copyWith(
                color: color,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _handleAlertTap(
      BuildContext context, AlertService service, Alert alert) {
    service.markAsRead(alert.id);

    switch (alert.type) {
      case AlertType.lowStock:
        context.push('/inventory');
        break;
      case AlertType.customerDebt:
        context.push('/reports/receivables');
        break;
      case AlertType.supplierDebt:
        context.push('/reports/payables');
        break;
      case AlertType.shiftOpen:
        context.push('/cash');
        break;
      case AlertType.backupNeeded:
        context.push('/settings');
        break;
      case AlertType.syncError:
        context.push('/settings');
        break;
    }
  }
}

/// ═══════════════════════════════════════════════════════════════════════════
/// بطاقة التنبيه المحدثة
/// ═══════════════════════════════════════════════════════════════════════════
class _AlertCardRedesign extends StatelessWidget {
  final Alert alert;
  final VoidCallback onTap;
  final VoidCallback onDismiss;

  const _AlertCardRedesign({
    required this.alert,
    required this.onTap,
    required this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: Key(alert.id),
      direction: DismissDirection.endToStart,
      onDismissed: (_) => onDismiss(),
      background: Container(
        alignment: Alignment.centerLeft,
        padding: EdgeInsets.only(left: HoorSpacing.lg.w),
        margin: EdgeInsets.only(bottom: HoorSpacing.sm.h),
        decoration: BoxDecoration(
          color: HoorColors.error,
          borderRadius: BorderRadius.circular(HoorRadius.md),
        ),
        child: const Icon(Icons.delete_rounded, color: Colors.white),
      ),
      child: Container(
        margin: EdgeInsets.only(bottom: HoorSpacing.sm.h),
        decoration: BoxDecoration(
          color: HoorColors.surface,
          borderRadius: BorderRadius.circular(HoorRadius.md),
          border: Border.all(
            color: alert.isRead
                ? HoorColors.border
                : _getSeverityColor(alert.severity).withValues(alpha: 0.3),
          ),
          boxShadow: alert.isRead
              ? null
              : [
                  BoxShadow(
                    color: _getSeverityColor(alert.severity)
                        .withValues(alpha: 0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
        ),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(HoorRadius.md),
          child: Padding(
            padding: EdgeInsets.all(HoorSpacing.md.w),
            child: Row(
              children: [
                // Severity Indicator
                Container(
                  width: 4,
                  height: 50,
                  decoration: BoxDecoration(
                    color: _getSeverityColor(alert.severity),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                SizedBox(width: HoorSpacing.sm.w),

                // Icon
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: _getTypeColor(alert.type).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(HoorRadius.md),
                  ),
                  child: Icon(
                    _getTypeIcon(alert.type),
                    color: _getTypeColor(alert.type),
                    size: 22,
                  ),
                ),
                SizedBox(width: HoorSpacing.sm.w),

                // Content
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              alert.title,
                              style: HoorTypography.bodyMedium.copyWith(
                                fontWeight: alert.isRead
                                    ? FontWeight.normal
                                    : FontWeight.w600,
                              ),
                            ),
                          ),
                          _buildSeverityBadge(),
                        ],
                      ),
                      SizedBox(height: HoorSpacing.xxs.h),
                      Text(
                        alert.message,
                        style: HoorTypography.bodySmall.copyWith(
                          color: HoorColors.textSecondary,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      SizedBox(height: HoorSpacing.xxs.h),
                      Text(
                        _formatTime(alert.createdAt),
                        style: HoorTypography.labelSmall.copyWith(
                          color: HoorColors.textTertiary,
                        ),
                      ),
                    ],
                  ),
                ),

                // Chevron
                Icon(Icons.chevron_left_rounded,
                    color: HoorColors.textTertiary, size: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSeverityBadge() {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: HoorSpacing.xs.w,
        vertical: 2,
      ),
      decoration: BoxDecoration(
        color: _getSeverityColor(alert.severity).withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(HoorRadius.sm),
      ),
      child: Text(
        _getSeverityLabel(alert.severity),
        style: HoorTypography.labelSmall.copyWith(
          color: _getSeverityColor(alert.severity),
          fontWeight: FontWeight.bold,
          fontSize: 10,
        ),
      ),
    );
  }

  IconData _getTypeIcon(AlertType type) {
    switch (type) {
      case AlertType.lowStock:
        return Icons.inventory_2_outlined;
      case AlertType.customerDebt:
        return Icons.person_outline_rounded;
      case AlertType.supplierDebt:
        return Icons.local_shipping_outlined;
      case AlertType.shiftOpen:
        return Icons.access_time_rounded;
      case AlertType.backupNeeded:
        return Icons.backup_outlined;
      case AlertType.syncError:
        return Icons.sync_problem_rounded;
    }
  }

  Color _getTypeColor(AlertType type) {
    switch (type) {
      case AlertType.lowStock:
        return HoorColors.warning;
      case AlertType.customerDebt:
        return HoorColors.info;
      case AlertType.supplierDebt:
        return HoorColors.primary;
      case AlertType.shiftOpen:
        return const Color(0xFFF59E0B);
      case AlertType.backupNeeded:
        return HoorColors.success;
      case AlertType.syncError:
        return HoorColors.error;
    }
  }

  Color _getSeverityColor(AlertSeverity severity) {
    switch (severity) {
      case AlertSeverity.low:
        return HoorColors.success;
      case AlertSeverity.medium:
        return HoorColors.info;
      case AlertSeverity.high:
        return HoorColors.warning;
      case AlertSeverity.critical:
        return HoorColors.error;
    }
  }

  String _getSeverityLabel(AlertSeverity severity) {
    switch (severity) {
      case AlertSeverity.low:
        return 'منخفض';
      case AlertSeverity.medium:
        return 'متوسط';
      case AlertSeverity.high:
        return 'مرتفع';
      case AlertSeverity.critical:
        return 'حرج';
    }
  }

  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final diff = now.difference(time);

    if (diff.inMinutes < 1) return 'الآن';
    if (diff.inMinutes < 60) return 'منذ ${diff.inMinutes} دقيقة';
    if (diff.inHours < 24) return 'منذ ${diff.inHours} ساعة';
    if (diff.inDays < 7) return 'منذ ${diff.inDays} يوم';
    return '${time.day}/${time.month}/${time.year}';
  }
}

/// ═══════════════════════════════════════════════════════════════════════════
/// زر التنبيهات للـ AppBar المحدث
/// ═══════════════════════════════════════════════════════════════════════════
class AlertsButtonRedesign extends StatelessWidget {
  const AlertsButtonRedesign({super.key});

  @override
  Widget build(BuildContext context) {
    final alertService = getAlertService();

    return ListenableBuilder(
      listenable: alertService,
      builder: (context, _) {
        final unreadCount = alertService.unreadCount;

        return Stack(
          children: [
            Container(
              margin: EdgeInsets.all(HoorSpacing.xs.w),
              decoration: BoxDecoration(
                color: unreadCount > 0
                    ? HoorColors.primary.withValues(alpha: 0.1)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(HoorRadius.md),
              ),
              child: IconButton(
                icon: Icon(
                  unreadCount > 0
                      ? Icons.notifications_active_rounded
                      : Icons.notifications_outlined,
                  color: unreadCount > 0
                      ? HoorColors.primary
                      : HoorColors.textSecondary,
                ),
                onPressed: () => context.push('/alerts'),
                tooltip: 'التنبيهات',
              ),
            ),
            if (unreadCount > 0)
              Positioned(
                right: 4,
                top: 4,
                child: Container(
                  padding: EdgeInsets.all(4),
                  decoration: const BoxDecoration(
                    color: HoorColors.error,
                    shape: BoxShape.circle,
                  ),
                  constraints:
                      const BoxConstraints(minWidth: 18, minHeight: 18),
                  child: Text(
                    unreadCount > 9 ? '9+' : unreadCount.toString(),
                    style: HoorTypography.labelSmall.copyWith(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}

/// ═══════════════════════════════════════════════════════════════════════════
/// ويدجت التنبيهات المصغر للشاشة الرئيسية المحدث
/// ═══════════════════════════════════════════════════════════════════════════
class AlertsSummaryWidgetRedesign extends StatelessWidget {
  const AlertsSummaryWidgetRedesign({super.key});

  @override
  Widget build(BuildContext context) {
    final alertService = getAlertService();

    return ListenableBuilder(
      listenable: alertService,
      builder: (context, _) {
        final criticalCount = alertService.criticalAlerts.length;
        final highCount = alertService.highAlerts.length;
        final totalUnread = alertService.unreadCount;

        if (totalUnread == 0) return const SizedBox.shrink();

        final isCritical = criticalCount > 0;

        return Container(
          margin: EdgeInsets.all(HoorSpacing.md.w),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: isCritical
                  ? [
                      HoorColors.error.withValues(alpha: 0.1),
                      HoorColors.error.withValues(alpha: 0.05)
                    ]
                  : [
                      HoorColors.warning.withValues(alpha: 0.1),
                      HoorColors.warning.withValues(alpha: 0.05)
                    ],
            ),
            borderRadius: BorderRadius.circular(HoorRadius.lg),
            border: Border.all(
              color: isCritical
                  ? HoorColors.error.withValues(alpha: 0.3)
                  : HoorColors.warning.withValues(alpha: 0.3),
            ),
          ),
          child: InkWell(
            onTap: () => context.push('/alerts'),
            borderRadius: BorderRadius.circular(HoorRadius.lg),
            child: Padding(
              padding: EdgeInsets.all(HoorSpacing.md.w),
              child: Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(HoorSpacing.sm.w),
                    decoration: BoxDecoration(
                      color: isCritical
                          ? HoorColors.error.withValues(alpha: 0.2)
                          : HoorColors.warning.withValues(alpha: 0.2),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.notifications_active_rounded,
                      color: isCritical ? HoorColors.error : HoorColors.warning,
                      size: 24,
                    ),
                  ),
                  SizedBox(width: HoorSpacing.md.w),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '$totalUnread تنبيه${totalUnread > 1 ? 'ات' : ''} جديد${totalUnread > 1 ? 'ة' : ''}',
                          style: HoorTypography.titleSmall.copyWith(
                            fontWeight: FontWeight.bold,
                            color: isCritical
                                ? HoorColors.error
                                : HoorColors.warning,
                          ),
                        ),
                        SizedBox(height: HoorSpacing.xxs.h),
                        Text(
                          _buildSubtitle(criticalCount, highCount),
                          style: HoorTypography.bodySmall.copyWith(
                            color: HoorColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(Icons.chevron_left_rounded,
                      color: HoorColors.textTertiary),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  String _buildSubtitle(int critical, int high) {
    final parts = <String>[];
    if (critical > 0) parts.add('$critical حرج');
    if (high > 0) parts.add('$high مرتفع');
    return parts.isEmpty ? 'انقر للتفاصيل' : parts.join(' • ');
  }
}
