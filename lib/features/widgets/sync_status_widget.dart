import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../core/di/injection.dart';
import '../../core/services/sync_service.dart';
import '../../core/theme/redesign/design_tokens.dart';

class SyncStatusWidget extends StatelessWidget {
  const SyncStatusWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final syncService = getIt<SyncService>();

    return ListenableBuilder(
      listenable: syncService,
      builder: (context, _) {
        return Padding(
          padding: EdgeInsets.symmetric(horizontal: 8.w),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Online/Offline indicator
              Container(
                width: 8.w,
                height: 8.w,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: syncService.isOnline
                      ? HoorColors.success
                      : HoorColors.error,
                ),
              ),
              SizedBox(width: 4.w),

              // Sync button
              if (syncService.isSyncing)
                SizedBox(
                  width: 20.w,
                  height: 20.w,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor:
                        const AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
              else
                IconButton(
                  icon: Icon(
                    Icons.sync,
                    size: 20.sp,
                    color: Colors.white,
                  ),
                  onPressed:
                      syncService.isOnline ? () => syncService.syncAll() : null,
                  tooltip: syncService.isOnline ? 'مزامنة' : 'غير متصل',
                ),
            ],
          ),
        );
      },
    );
  }
}
