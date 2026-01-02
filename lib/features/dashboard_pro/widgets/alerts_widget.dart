// ═══════════════════════════════════════════════════════════════════════════
// Alerts Widget Component
// Displays important notifications and warnings FROM REAL DATABASE
// ═══════════════════════════════════════════════════════════════════════════

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/design_tokens.dart';
import '../../../core/providers/app_providers.dart';

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
    this.route,
    this.timestamp,
  });

  final String id;
  final AlertSeverity severity;
  final String title;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;
  final String? route;
  final DateTime? timestamp;
}

/// Provider for dashboard alerts (from real data)
final dashboardAlertsProvider = FutureProvider<List<AlertItem>>((ref) async {
  final List<AlertItem> alerts = [];

  // 1. Check for low stock products
  final lowStockProducts = await ref.watch(lowStockProductsProvider.future);
  if (lowStockProducts.isNotEmpty) {
    alerts.add(AlertItem(
      id: 'low_stock',
      severity: AlertSeverity.warning,
      title: 'منتجات وصلت للحد الأدنى',
      message:
          '${lowStockProducts.length} منتج${lowStockProducts.length > 1 ? "ات" : ""} تحتاج لإعادة طلب',
      actionLabel: 'عرض المنتجات',
      route: '/products?filter=low_stock',
    ));
  }

  // 2. Check for customers with high balances (receivables)
  final customers = await ref.watch(customersStreamProvider.future);
  final customersWithBalance = customers.where((c) => c.balance > 0).toList();
  if (customersWithBalance.isNotEmpty) {
    final totalReceivables =
        customersWithBalance.fold<double>(0, (sum, c) => sum + c.balance);
    final formatter = NumberFormat('#,##0', 'ar');
    alerts.add(AlertItem(
      id: 'receivables',
      severity: AlertSeverity.info,
      title: 'ذمم مدينة مستحقة',
      message:
          '${customersWithBalance.length} عميل بإجمالي ${formatter.format(totalReceivables)} ر.س',
      actionLabel: 'عرض العملاء',
      route: '/customers',
    ));
  }

  // 3. Check for suppliers with balance (payables)
  final suppliers = await ref.watch(suppliersStreamProvider.future);
  final suppliersWithBalance = suppliers.where((s) => s.balance > 0).toList();
  if (suppliersWithBalance.isNotEmpty) {
    final totalPayables =
        suppliersWithBalance.fold<double>(0, (sum, s) => sum + s.balance);
    final formatter = NumberFormat('#,##0', 'ar');
    alerts.add(AlertItem(
      id: 'payables',
      severity: AlertSeverity.info,
      title: 'ذمم دائنة مستحقة',
      message:
          '${suppliersWithBalance.length} مورد بإجمالي ${formatter.format(totalPayables)} ر.س',
      actionLabel: 'عرض الموردين',
      route: '/suppliers',
    ));
  }

  // 4. Check if no shift is open
  final openShift = await ref.watch(openShiftStreamProvider.future);
  if (openShift == null) {
    alerts.add(AlertItem(
      id: 'no_shift',
      severity: AlertSeverity.warning,
      title: 'لا توجد وردية مفتوحة',
      message: 'افتح وردية جديدة لتسجيل المعاملات',
      actionLabel: 'فتح وردية',
      route: '/shifts',
    ));
  }

  // 5. Check for products with zero stock
  final products = await ref.watch(activeProductsStreamProvider.future);
  final zeroStockProducts = products.where((p) => p.quantity == 0).toList();
  if (zeroStockProducts.isNotEmpty) {
    alerts.add(AlertItem(
      id: 'zero_stock',
      severity: AlertSeverity.critical,
      title: 'منتجات نفدت من المخزون',
      message:
          '${zeroStockProducts.length} منتج${zeroStockProducts.length > 1 ? "ات" : ""} بدون مخزون',
      actionLabel: 'عرض المنتجات',
      route: '/products?filter=zero_stock',
    ));
  }

  // Sort by severity (critical first)
  alerts.sort((a, b) {
    final severityOrder = {
      AlertSeverity.critical: 0,
      AlertSeverity.warning: 1,
      AlertSeverity.info: 2,
      AlertSeverity.success: 3,
    };
    return severityOrder[a.severity]!.compareTo(severityOrder[b.severity]!);
  });

  return alerts;
});

class AlertsWidget extends ConsumerWidget {
  const AlertsWidget({
    super.key,
    this.maxItems = 3,
  });

  final int maxItems;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final alertsAsync = ref.watch(dashboardAlertsProvider);

    return alertsAsync.when(
      loading: () => _buildLoadingState(),
      error: (error, _) => _buildErrorState(),
      data: (alerts) {
        if (alerts.isEmpty) {
          return _buildEmptyState();
        }

        return Column(
          children: [
            for (int i = 0; i < alerts.take(maxItems).length; i++) ...[
              _AlertCard(
                alert: alerts[i],
                onTap: () {
                  HapticFeedback.lightImpact();
                  if (alerts[i].route != null) {
                    context.push(alerts[i].route!);
                  }
                },
              ),
              if (i < alerts.take(maxItems).length - 1)
                SizedBox(height: AppSpacing.sm.h),
            ],
          ],
        );
      },
    );
  }

  Widget _buildLoadingState() {
    return Container(
      padding: EdgeInsets.all(AppSpacing.lg.w),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.border),
      ),
      child: const Center(
        child: CircularProgressIndicator(),
      ),
    );
  }

  Widget _buildErrorState() {
    return Container(
      padding: EdgeInsets.all(AppSpacing.lg.w),
      decoration: BoxDecoration(
        color: AppColors.expenseSurface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.expense.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline, color: AppColors.expense),
          SizedBox(width: AppSpacing.md.w),
          Text(
            'خطأ في تحميل التنبيهات',
            style: AppTypography.bodyMedium.copyWith(color: AppColors.expense),
          ),
        ],
      ),
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
}

class _AlertCard extends StatelessWidget {
  const _AlertCard({
    required this.alert,
    this.onTap,
  });

  final AlertItem alert;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final severityInfo = _getSeverityInfo(alert.severity);

    return Material(
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
