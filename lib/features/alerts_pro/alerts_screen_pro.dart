// ═══════════════════════════════════════════════════════════════════════════
// Alerts Screen Pro - Professional Design System
// System Alerts and Notifications
// ═══════════════════════════════════════════════════════════════════════════

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/pro/design_tokens.dart';

class AlertsScreenPro extends StatefulWidget {
  const AlertsScreenPro({super.key});

  @override
  State<AlertsScreenPro> createState() => _AlertsScreenProState();
}

class _AlertsScreenProState extends State<AlertsScreenPro> {
  final List<Map<String, dynamic>> _alerts = [
    {
      'id': '1',
      'type': 'low_stock',
      'title': 'مخزون منخفض',
      'message': '5 منتجات وصلت للحد الأدنى',
      'time': 'منذ 10 دقائق',
      'isRead': false,
      'priority': 'high',
    },
    {
      'id': '2',
      'type': 'overdue',
      'title': 'فواتير متأخرة',
      'message': '3 فواتير تجاوزت تاريخ الاستحقاق',
      'time': 'منذ ساعة',
      'isRead': false,
      'priority': 'high',
    },
    {
      'id': '3',
      'type': 'payment',
      'title': 'دفعة مستلمة',
      'message': 'تم استلام 5,000 ر.س من شركة النور',
      'time': 'منذ 2 ساعة',
      'isRead': true,
      'priority': 'normal',
    },
    {
      'id': '4',
      'type': 'backup',
      'title': 'نسخ احتياطي ناجح',
      'message': 'تم إنشاء نسخة احتياطية بنجاح',
      'time': 'اليوم 10:30 ص',
      'isRead': true,
      'priority': 'low',
    },
    {
      'id': '5',
      'type': 'sync',
      'title': 'مزامنة البيانات',
      'message': 'تمت مزامنة جميع البيانات',
      'time': 'أمس 5:00 م',
      'isRead': true,
      'priority': 'low',
    },
  ];

  @override
  Widget build(BuildContext context) {
    final unreadCount = _alerts.where((a) => !a['isRead']).length;

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
          if (unreadCount > 0)
            TextButton(
              onPressed: () {
                setState(() {
                  for (var alert in _alerts) {
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
          PopupMenuButton<String>(
            icon: Icon(Icons.more_vert_rounded, color: AppColors.textSecondary),
            itemBuilder: (context) => [
              const PopupMenuItem(
                  value: 'settings', child: Text('إعدادات التنبيهات')),
              const PopupMenuItem(value: 'clear', child: Text('مسح الكل')),
            ],
          ),
        ],
      ),
      body: _alerts.isEmpty
          ? _buildEmptyState()
          : ListView.builder(
              padding: EdgeInsets.all(AppSpacing.md),
              itemCount: _alerts.length,
              itemBuilder: (context, index) {
                final alert = _alerts[index];
                return _AlertCard(
                  alert: alert,
                  onTap: () {
                    setState(() => alert['isRead'] = true);
                    // Navigate based on type
                  },
                  onDismiss: () {
                    setState(() => _alerts.removeAt(index));
                  },
                );
              },
            ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.notifications_none_rounded,
            size: 80.sp,
            color: AppColors.textTertiary,
          ),
          SizedBox(height: AppSpacing.lg),
          Text(
            'لا توجد تنبيهات',
            style: AppTypography.headlineMedium.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          SizedBox(height: AppSpacing.sm),
          Text(
            'ستظهر التنبيهات الجديدة هنا',
            style: AppTypography.bodyMedium.copyWith(
              color: AppColors.textTertiary,
            ),
          ),
        ],
      ),
    );
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
            color: isRead ? AppColors.border : color.withOpacity(0.3),
          ),
        ),
        color: isRead ? AppColors.surface : color.withOpacity(0.05),
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
                    color: color.withOpacity(0.1),
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
