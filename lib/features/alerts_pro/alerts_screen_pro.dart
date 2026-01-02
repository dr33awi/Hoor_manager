// ═══════════════════════════════════════════════════════════════════════════
// Alerts Screen Pro - Professional Design System
// System Alerts and Notifications
// ═══════════════════════════════════════════════════════════════════════════

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/design_tokens.dart';
import '../../core/widgets/widgets.dart';
import '../../core/providers/app_providers.dart';

class AlertsScreenPro extends ConsumerStatefulWidget {
  const AlertsScreenPro({super.key});

  @override
  ConsumerState<AlertsScreenPro> createState() => _AlertsScreenProState();
}

class _AlertsScreenProState extends ConsumerState<AlertsScreenPro> {
  final List<Map<String, dynamic>> _systemAlerts = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadAlerts();
  }

  Future<void> _loadAlerts() async {
    setState(() => _isLoading = true);

    try {
      final alerts = <Map<String, dynamic>>[];

      // Check for low stock products
      final productsAsync = ref.read(activeProductsStreamProvider);
      productsAsync.whenData((products) {
        final lowStock =
            products.where((p) => p.quantity <= p.minQuantity).toList();
        if (lowStock.isNotEmpty) {
          alerts.add({
            'id': 'low_stock',
            'type': 'low_stock',
            'title': 'مخزون منخفض',
            'message': '${lowStock.length} منتجات وصلت للحد الأدنى',
            'time': 'تحديث تلقائي',
            'isRead': false,
            'priority': 'high',
            'items': lowStock,
          });
        }
      });

      // Check for unpaid invoices older than 30 days
      final invoicesAsync = ref.read(salesInvoicesProvider);
      invoicesAsync.whenData((invoices) {
        final thirtyDaysAgo = DateTime.now().subtract(const Duration(days: 30));
        final overdue = invoices.where((inv) {
          if (inv.status == 'paid' || inv.status == 'completed') return false;
          return inv.invoiceDate.isBefore(thirtyDaysAgo);
        }).toList();
        if (overdue.isNotEmpty) {
          alerts.add({
            'id': 'overdue',
            'type': 'overdue',
            'title': 'فواتير متأخرة',
            'message': '${overdue.length} فواتير لم تسدد منذ أكثر من 30 يوم',
            'time': 'تحديث تلقائي',
            'isRead': false,
            'priority': 'high',
            'items': overdue,
          });
        }
      });

      if (mounted) {
        setState(() {
          _systemAlerts.clear();
          _systemAlerts.addAll(alerts);
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Listen to changes
    ref.listen(activeProductsStreamProvider, (_, __) => _loadAlerts());
    ref.listen(salesInvoicesProvider, (_, __) => _loadAlerts());

    final unreadCount = _systemAlerts.where((a) => !a['isRead']).length;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        leading: IconButton(
          onPressed: () => context.go('/'),
          icon: Icon(Icons.arrow_back_ios_rounded,
              color: AppColors.textSecondary),
        ),
        title: Row(
          children: [
            Text(
              'التنبيهات',
              style: AppTypography.headlineSmall.copyWith(
                color: AppColors.textPrimary,
              ),
            ),
            if (unreadCount > 0) ...[
              SizedBox(width: AppSpacing.sm),
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: AppSpacing.sm,
                  vertical: 2.h,
                ),
                decoration: BoxDecoration(
                  color: AppColors.error,
                  borderRadius: BorderRadius.circular(AppRadius.full),
                ),
                child: Text(
                  '$unreadCount',
                  style: AppTypography.labelSmall.copyWith(
                    color: Colors.white,
                    fontFamily: 'JetBrains Mono',
                  ),
                ),
              ),
            ],
          ],
        ),
        actions: [
          IconButton(
            onPressed: _loadAlerts,
            icon: Icon(Icons.refresh_rounded, color: AppColors.textSecondary),
          ),
          if (unreadCount > 0)
            TextButton(
              onPressed: () {
                setState(() {
                  for (var alert in _systemAlerts) {
                    alert['isRead'] = true;
                  }
                });
              },
              child: Text(
                'قراءة الكل',
                style: AppTypography.labelMedium.copyWith(
                  color: AppColors.secondary,
                ),
              ),
            ),
        ],
      ),
      body: _isLoading
          ? ProLoadingState.list()
          : _systemAlerts.isEmpty
              ? const ProEmptyState(
                  icon: Icons.notifications_none_rounded,
                  title: 'لا توجد تنبيهات',
                  message: 'ستظهر التنبيهات الجديدة هنا',
                )
              : ListView.builder(
                  padding: EdgeInsets.all(AppSpacing.md),
                  itemCount: _systemAlerts.length,
                  itemBuilder: (context, index) {
                    final alert = _systemAlerts[index];
                    return _AlertCard(
                      alert: alert,
                      onTap: () {
                        setState(() => alert['isRead'] = true);
                        _handleAlertTap(alert);
                      },
                      onDismiss: () {
                        setState(() => _systemAlerts.removeAt(index));
                      },
                    );
                  },
                ),
    );
  }

  void _handleAlertTap(Map<String, dynamic> alert) {
    final type = alert['type'] as String;
    switch (type) {
      case 'low_stock':
        context.push('/products');
        break;
      case 'overdue':
        context.push('/invoices');
        break;
    }
  }
}

class _AlertCard extends StatelessWidget {
  final Map<String, dynamic> alert;
  final VoidCallback onTap;
  final VoidCallback onDismiss;

  const _AlertCard({
    required this.alert,
    required this.onTap,
    required this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    final type = alert['type'] as String;
    final isRead = alert['isRead'] as bool;
    // ignore: unused_local_variable
    final priority = alert['priority'] as String;

    IconData icon;
    Color color;

    switch (type) {
      case 'low_stock':
        icon = Icons.inventory_2_outlined;
        color = AppColors.warning;
        break;
      case 'overdue':
        icon = Icons.warning_amber_rounded;
        color = AppColors.error;
        break;
      case 'payment':
        icon = Icons.payments_outlined;
        color = AppColors.success;
        break;
      case 'backup':
        icon = Icons.cloud_done_outlined;
        color = AppColors.secondary;
        break;
      default:
        icon = Icons.sync_rounded;
        color = AppColors.textSecondary;
    }

    return Dismissible(
      key: Key(alert['id']),
      direction: DismissDirection.endToStart,
      onDismissed: (_) => onDismiss(),
      background: Container(
        margin: EdgeInsets.only(bottom: AppSpacing.sm),
        alignment: Alignment.centerLeft,
        padding: EdgeInsets.only(left: AppSpacing.lg),
        decoration: BoxDecoration(
          color: AppColors.error,
          borderRadius: BorderRadius.circular(AppRadius.lg),
        ),
        child: Icon(
          Icons.delete_outline_rounded,
          color: Colors.white,
        ),
      ),
      child: Card(
        margin: EdgeInsets.only(bottom: AppSpacing.sm),
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.lg),
          side: BorderSide(
            color: isRead ? AppColors.border : color.border,
          ),
        ),
        color: isRead ? AppColors.surface : color.subtle,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          child: Padding(
            padding: EdgeInsets.all(AppSpacing.md),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: EdgeInsets.all(AppSpacing.sm),
                  decoration: BoxDecoration(
                    color: color.soft,
                    borderRadius: BorderRadius.circular(AppRadius.md),
                  ),
                  child: Icon(icon, color: color, size: AppIconSize.md),
                ),
                SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              alert['title'],
                              style: AppTypography.titleSmall.copyWith(
                                color: AppColors.textPrimary,
                                fontWeight:
                                    isRead ? FontWeight.w500 : FontWeight.w600,
                              ),
                            ),
                          ),
                          if (!isRead)
                            Container(
                              width: 8.w,
                              height: 8.w,
                              decoration: BoxDecoration(
                                color: color,
                                shape: BoxShape.circle,
                              ),
                            ),
                        ],
                      ),
                      SizedBox(height: 4.h),
                      Text(
                        alert['message'],
                        style: AppTypography.bodyMedium.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                      SizedBox(height: AppSpacing.xs),
                      Text(
                        alert['time'],
                        style: AppTypography.labelSmall.copyWith(
                          color: AppColors.textTertiary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
