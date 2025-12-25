import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../features/products/presentation/providers/product_providers.dart';
import '../services/offline_service.dart';

/// مؤشر حالة الأوفلاين في شريط التطبيق
class OfflineAppBarIndicator extends ConsumerWidget {
  const OfflineAppBarIndicator({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return StreamBuilder<bool>(
      stream: OfflineService().connectivityStream,
      initialData: OfflineService().isOnline,
      builder: (context, snapshot) {
        final isOnline = snapshot.data ?? true;

        if (isOnline) return const SizedBox.shrink();

        return Container(
          padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
          margin: EdgeInsets.only(left: 8.w),
          decoration: BoxDecoration(
            color: Colors.orange.shade100,
            borderRadius: BorderRadius.circular(12.r),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.cloud_off,
                size: 14.sp,
                color: Colors.orange.shade800,
              ),
              SizedBox(width: 4.w),
              Text(
                'غير متصل',
                style: TextStyle(
                  fontSize: 11.sp,
                  fontWeight: FontWeight.w500,
                  color: Colors.orange.shade800,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

/// شريط العمليات المعلقة
class PendingOperationsBanner extends ConsumerWidget {
  const PendingOperationsBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pendingCount = ref.watch(pendingOperationsCountProvider);

    if (pendingCount == 0) return const SizedBox.shrink();

    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 10.h),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        border: Border(
          bottom: BorderSide(color: Colors.blue.shade200),
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.sync,
            size: 20.sp,
            color: Colors.blue.shade700,
          ),
          SizedBox(width: 8.w),
          Expanded(
            child: Text(
              '$pendingCount عملية في انتظار المزامنة',
              style: TextStyle(
                fontSize: 13.sp,
                color: Colors.blue.shade700,
              ),
            ),
          ),
          StreamBuilder<bool>(
            stream: OfflineService().connectivityStream,
            initialData: OfflineService().isOnline,
            builder: (context, snapshot) {
              final isOnline = snapshot.data ?? false;

              if (!isOnline) {
                return Text(
                  'ستتم عند الاتصال',
                  style: TextStyle(
                    fontSize: 11.sp,
                    color: Colors.blue.shade500,
                  ),
                );
              }

              return TextButton.icon(
                onPressed: () => _syncNow(context),
                icon: Icon(Icons.sync, size: 16.sp),
                label: Text(
                  'مزامنة الآن',
                  style: TextStyle(fontSize: 12.sp),
                ),
                style: TextButton.styleFrom(
                  padding: EdgeInsets.symmetric(horizontal: 8.w),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Future<void> _syncNow(BuildContext context) async {
    final result = await OfflineService().syncPendingOperations();

    if (!context.mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(result.message),
        backgroundColor: result.success ? Colors.green : Colors.orange,
        behavior: SnackBarBehavior.floating,
        margin: EdgeInsets.all(16.r),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8.r),
        ),
      ),
    );
  }
}

/// بطاقة حالة المزامنة
class SyncStatusCard extends StatelessWidget {
  const SyncStatusCard({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<SyncStatus>(
      stream: OfflineService().syncStatusStream,
      builder: (context, snapshot) {
        final status = snapshot.data;

        if (status == null || status == SyncStatus.idle) {
          return const SizedBox.shrink();
        }

        return Container(
          margin: EdgeInsets.all(16.r),
          padding: EdgeInsets.all(16.r),
          decoration: BoxDecoration(
            color: _getStatusColor(status),
            borderRadius: BorderRadius.circular(12.r),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              _getStatusIcon(status),
              SizedBox(width: 12.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _getStatusTitle(status),
                      style: TextStyle(
                        fontSize: 14.sp,
                        fontWeight: FontWeight.bold,
                        color: _getStatusTextColor(status),
                      ),
                    ),
                    SizedBox(height: 4.h),
                    Text(
                      _getStatusMessage(status),
                      style: TextStyle(
                        fontSize: 12.sp,
                        color: _getStatusTextColor(status).withOpacity(0.8),
                      ),
                    ),
                  ],
                ),
              ),
              if (status == SyncStatus.error)
                IconButton(
                  onPressed: () => OfflineService().syncPendingOperations(),
                  icon: Icon(
                    Icons.refresh,
                    color: _getStatusTextColor(status),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Color _getStatusColor(SyncStatus status) {
    switch (status) {
      case SyncStatus.idle:
        return Colors.transparent;
      case SyncStatus.syncing:
        return Colors.blue.shade50;
      case SyncStatus.completed:
        return Colors.green.shade50;
      case SyncStatus.error:
        return Colors.red.shade50;
    }
  }

  Color _getStatusTextColor(SyncStatus status) {
    switch (status) {
      case SyncStatus.idle:
        return Colors.black;
      case SyncStatus.syncing:
        return Colors.blue.shade700;
      case SyncStatus.completed:
        return Colors.green.shade700;
      case SyncStatus.error:
        return Colors.red.shade700;
    }
  }

  Widget _getStatusIcon(SyncStatus status) {
    switch (status) {
      case SyncStatus.idle:
        return const SizedBox.shrink();
      case SyncStatus.syncing:
        return SizedBox(
          width: 24.w,
          height: 24.w,
          child: CircularProgressIndicator(
            strokeWidth: 2.w,
            valueColor: AlwaysStoppedAnimation(Colors.blue.shade700),
          ),
        );
      case SyncStatus.completed:
        return Icon(
          Icons.check_circle,
          color: Colors.green.shade700,
          size: 24.sp,
        );
      case SyncStatus.error:
        return Icon(
          Icons.error,
          color: Colors.red.shade700,
          size: 24.sp,
        );
    }
  }

  String _getStatusTitle(SyncStatus status) {
    switch (status) {
      case SyncStatus.idle:
        return '';
      case SyncStatus.syncing:
        return 'جاري المزامنة...';
      case SyncStatus.completed:
        return 'تمت المزامنة';
      case SyncStatus.error:
        return 'فشلت المزامنة';
    }
  }

  String _getStatusMessage(SyncStatus status) {
    switch (status) {
      case SyncStatus.idle:
        return '';
      case SyncStatus.syncing:
        return 'يرجى الانتظار حتى اكتمال المزامنة';
      case SyncStatus.completed:
        return 'تم تحديث جميع البيانات بنجاح';
      case SyncStatus.error:
        return 'اضغط على زر إعادة المحاولة';
    }
  }
}

/// مربع حوار التأكيد قبل عملية تحتاج اتصال
class OfflineWarningDialog extends StatelessWidget {
  final String title;
  final String message;
  final VoidCallback? onProceed;

  const OfflineWarningDialog({
    super.key,
    required this.title,
    required this.message,
    this.onProceed,
  });

  static Future<bool> show(
    BuildContext context, {
    required String title,
    required String message,
  }) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => OfflineWarningDialog(
        title: title,
        message: message,
      ),
    );
    return result ?? false;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16.r),
      ),
      title: Row(
        children: [
          Icon(
            Icons.cloud_off,
            color: Colors.orange.shade700,
            size: 24.sp,
          ),
          SizedBox(width: 8.w),
          Text(
            title,
            style: TextStyle(fontSize: 18.sp),
          ),
        ],
      ),
      content: Text(
        message,
        style: TextStyle(fontSize: 14.sp),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('إلغاء'),
        ),
        ElevatedButton(
          onPressed: () => Navigator.of(context).pop(true),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.orange,
          ),
          child: const Text('متابعة'),
        ),
      ],
    );
  }
}

/// شريط توضيح الوضع الأوفلاين في صفحة معينة
class OfflineModeInfoBar extends StatelessWidget {
  final String message;

  const OfflineModeInfoBar({
    super.key,
    this.message =
        'أنت تعمل في وضع عدم الاتصال. سيتم مزامنة البيانات عند عودة الاتصال.',
  });

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<bool>(
      stream: OfflineService().connectivityStream,
      initialData: OfflineService().isOnline,
      builder: (context, snapshot) {
        final isOnline = snapshot.data ?? true;

        if (isOnline) return const SizedBox.shrink();

        return Container(
          width: double.infinity,
          padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.orange.shade400, Colors.orange.shade600],
            ),
          ),
          child: Row(
            children: [
              Icon(
                Icons.info_outline,
                color: Colors.white,
                size: 20.sp,
              ),
              SizedBox(width: 8.w),
              Expanded(
                child: Text(
                  message,
                  style: TextStyle(
                    fontSize: 12.sp,
                    color: Colors.white,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

/// زر إضافة مع مؤشر أوفلاين
class OfflineAwareAddButton extends StatelessWidget {
  final VoidCallback onPressed;
  final String label;
  final IconData icon;

  const OfflineAwareAddButton({
    super.key,
    required this.onPressed,
    required this.label,
    this.icon = Icons.add,
  });

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<bool>(
      stream: OfflineService().connectivityStream,
      initialData: OfflineService().isOnline,
      builder: (context, snapshot) {
        final isOnline = snapshot.data ?? true;

        return FloatingActionButton.extended(
          onPressed: onPressed,
          backgroundColor:
              isOnline ? Theme.of(context).primaryColor : Colors.orange,
          icon: Row(
            children: [
              Icon(icon, size: 20.sp),
              if (!isOnline) ...[
                SizedBox(width: 4.w),
                Icon(Icons.cloud_off, size: 14.sp),
              ],
            ],
          ),
          label: Text(
            isOnline ? label : '$label (أوفلاين)',
            style: TextStyle(fontSize: 14.sp),
          ),
        );
      },
    );
  }
}
