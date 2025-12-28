import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gap/gap.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';

import '../../../core/di/injection.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/services/backup_service.dart';

class BackupScreen extends ConsumerStatefulWidget {
  const BackupScreen({super.key});

  @override
  ConsumerState<BackupScreen> createState() => _BackupScreenState();
}

class _BackupScreenState extends ConsumerState<BackupScreen> {
  final _backupService = getIt<BackupService>();

  List<Map<String, dynamic>> _backups = [];
  bool _isLoading = true;
  bool _autoBackupEnabled = true;

  @override
  void initState() {
    super.initState();
    _loadBackups();
  }

  Future<void> _loadBackups() async {
    // TODO: Load backup list from storage
    setState(() {
      _backups = [];
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('النسخ الاحتياطي'),
      ),
      body: ListView(
        padding: EdgeInsets.all(16.w),
        children: [
          // Quick Actions
          Row(
            children: [
              Expanded(
                child: _ActionCard(
                  icon: Icons.backup,
                  title: 'نسخ الآن',
                  subtitle: 'إنشاء نسخة محلية',
                  color: AppColors.primary,
                  onTap: _createLocalBackup,
                ),
              ),
              Gap(12.w),
              Expanded(
                child: _ActionCard(
                  icon: Icons.cloud_upload,
                  title: 'رفع للسحابة',
                  subtitle: 'حفظ نسخة سحابية',
                  color: AppColors.success,
                  onTap: _createCloudBackup,
                ),
              ),
            ],
          ),
          Gap(12.h),
          Row(
            children: [
              Expanded(
                child: _ActionCard(
                  icon: Icons.restore,
                  title: 'استعادة',
                  subtitle: 'من نسخة سابقة',
                  color: AppColors.warning,
                  onTap: _restoreBackup,
                ),
              ),
              Gap(12.w),
              Expanded(
                child: _ActionCard(
                  icon: Icons.cloud_download,
                  title: 'تنزيل سحابي',
                  subtitle: 'استعادة من السحابة',
                  color: AppColors.accent,
                  onTap: _restoreFromCloud,
                ),
              ),
            ],
          ),
          Gap(24.h),

          // Auto Backup Settings
          Card(
            child: Column(
              children: [
                SwitchListTile(
                  secondary: const Icon(Icons.schedule),
                  title: const Text('النسخ التلقائي'),
                  subtitle: const Text('إنشاء نسخة يومية تلقائياً'),
                  value: _autoBackupEnabled,
                  onChanged: (value) =>
                      setState(() => _autoBackupEnabled = value),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.access_time),
                  title: const Text('وقت النسخ'),
                  subtitle: const Text('02:00 صباحاً'),
                  trailing: const Icon(Icons.chevron_left),
                  enabled: _autoBackupEnabled,
                  onTap: () => _selectBackupTime(),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.history),
                  title: const Text('الاحتفاظ بالنسخ'),
                  subtitle: const Text('آخر 7 نسخ'),
                  trailing: const Icon(Icons.chevron_left),
                  enabled: _autoBackupEnabled,
                  onTap: () => _selectRetentionPeriod(),
                ),
              ],
            ),
          ),
          Gap(24.h),

          // Backup History
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'النسخ السابقة',
                style: TextStyle(
                  fontSize: 18.sp,
                  fontWeight: FontWeight.bold,
                ),
              ),
              TextButton(
                onPressed: _loadBackups,
                child: const Text('تحديث'),
              ),
            ],
          ),
          Gap(8.h),

          if (_isLoading)
            const Center(child: CircularProgressIndicator())
          else if (_backups.isEmpty)
            Card(
              child: Padding(
                padding: EdgeInsets.all(32.w),
                child: Column(
                  children: [
                    Icon(
                      Icons.backup_outlined,
                      size: 48.sp,
                      color: Colors.grey,
                    ),
                    Gap(16.h),
                    Text(
                      'لا توجد نسخ احتياطية',
                      style: TextStyle(
                        fontSize: 16.sp,
                        color: Colors.grey,
                      ),
                    ),
                    Gap(8.h),
                    Text(
                      'أنشئ نسخة احتياطية للحفاظ على بياناتك',
                      style: TextStyle(
                        fontSize: 14.sp,
                        color: AppColors.textSecondary,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            )
          else
            ...(_backups.map((backup) => _BackupCard(
                  backup: backup,
                  onRestore: () => _restoreFromBackup(backup),
                  onDelete: () => _deleteBackup(backup),
                  onShare: () => _shareBackup(backup),
                ))),
        ],
      ),
    );
  }

  Future<void> _createLocalBackup() async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const AlertDialog(
        content: Row(
          children: [
            CircularProgressIndicator(),
            SizedBox(width: 16),
            Text('جاري إنشاء النسخة الاحتياطية...'),
          ],
        ),
      ),
    );

    try {
      final path = await _backupService.createLocalBackup();
      Navigator.pop(context);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('تم إنشاء النسخة الاحتياطية'),
          backgroundColor: AppColors.success,
          action: SnackBarAction(
            label: 'مشاركة',
            textColor: Colors.white,
            onPressed: () => Share.shareXFiles([XFile(path)]),
          ),
        ),
      );

      _loadBackups();
    } catch (e) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('حدث خطأ: $e'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  Future<void> _createCloudBackup() async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const AlertDialog(
        content: Row(
          children: [
            CircularProgressIndicator(),
            SizedBox(width: 16),
            Text('جاري الرفع للسحابة...'),
          ],
        ),
      ),
    );

    try {
      await _backupService.createCloudBackup();
      Navigator.pop(context);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('تم رفع النسخة الاحتياطية للسحابة'),
          backgroundColor: AppColors.success,
        ),
      );
    } catch (e) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('حدث خطأ: $e'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  Future<void> _restoreBackup() async {
    // TODO: Implement file picker
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('اختر ملف النسخة الاحتياطية')),
    );
  }

  Future<void> _restoreFromCloud() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('استعادة من السحابة'),
        content: const Text(
          'سيتم استبدال جميع البيانات الحالية.\n\nهل أنت متأكد؟',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.warning),
            child: const Text('استعادة'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const AlertDialog(
        content: Row(
          children: [
            CircularProgressIndicator(),
            SizedBox(width: 16),
            Text('جاري الاستعادة...'),
          ],
        ),
      ),
    );

    try {
      await _backupService.restoreFromCloud();
      Navigator.pop(context);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('تمت الاستعادة بنجاح'),
          backgroundColor: AppColors.success,
        ),
      );
    } catch (e) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('حدث خطأ: $e'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  Future<void> _restoreFromBackup(Map<String, dynamic> backup) async {
    // TODO: Implement restore
  }

  Future<void> _deleteBackup(Map<String, dynamic> backup) async {
    // TODO: Implement delete
  }

  Future<void> _shareBackup(Map<String, dynamic> backup) async {
    final path = backup['path'] as String?;
    if (path != null) {
      await Share.shareXFiles([XFile(path)]);
    }
  }

  void _selectBackupTime() async {
    final time = await showTimePicker(
      context: context,
      initialTime: const TimeOfDay(hour: 2, minute: 0),
    );

    if (time != null) {
      // TODO: Save backup time
    }
  }

  void _selectRetentionPeriod() {
    showDialog(
      context: context,
      builder: (context) => SimpleDialog(
        title: const Text('الاحتفاظ بالنسخ'),
        children: [
          _RetentionOption(label: 'آخر 3 نسخ', value: 3),
          _RetentionOption(label: 'آخر 7 نسخ', value: 7),
          _RetentionOption(label: 'آخر 14 نسخة', value: 14),
          _RetentionOption(label: 'آخر 30 نسخة', value: 30),
        ],
      ),
    );
  }
}

class _ActionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  const _ActionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12.r),
        child: Padding(
          padding: EdgeInsets.all(16.w),
          child: Column(
            children: [
              Icon(icon, color: color, size: 36.sp),
              Gap(8.h),
              Text(
                title,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 12.sp,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BackupCard extends StatelessWidget {
  final Map<String, dynamic> backup;
  final VoidCallback onRestore;
  final VoidCallback onDelete;
  final VoidCallback onShare;

  const _BackupCard({
    required this.backup,
    required this.onRestore,
    required this.onDelete,
    required this.onShare,
  });

  @override
  Widget build(BuildContext context) {
    final date = backup['date'] as DateTime?;
    final size = backup['size'] as int?;
    final type = backup['type'] as String?;

    return Card(
      margin: EdgeInsets.only(bottom: 8.h),
      child: ListTile(
        leading: Icon(
          type == 'cloud' ? Icons.cloud_done : Icons.folder,
          color: type == 'cloud' ? AppColors.success : AppColors.primary,
        ),
        title: Text(
          date != null
              ? DateFormat('dd/MM/yyyy HH:mm').format(date)
              : 'نسخة احتياطية',
        ),
        subtitle: Text(
          size != null ? _formatSize(size) : '',
        ),
        trailing: PopupMenuButton(
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'restore',
              child: Row(
                children: [
                  Icon(Icons.restore),
                  SizedBox(width: 8),
                  Text('استعادة'),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'share',
              child: Row(
                children: [
                  Icon(Icons.share),
                  SizedBox(width: 8),
                  Text('مشاركة'),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'delete',
              child: Row(
                children: [
                  Icon(Icons.delete, color: AppColors.error),
                  SizedBox(width: 8),
                  Text('حذف', style: TextStyle(color: AppColors.error)),
                ],
              ),
            ),
          ],
          onSelected: (value) {
            switch (value) {
              case 'restore':
                onRestore();
                break;
              case 'share':
                onShare();
                break;
              case 'delete':
                onDelete();
                break;
            }
          },
        ),
      ),
    );
  }

  String _formatSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
}

class _RetentionOption extends StatelessWidget {
  final String label;
  final int value;

  const _RetentionOption({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return SimpleDialogOption(
      onPressed: () => Navigator.pop(context, value),
      child: Text(label),
    );
  }
}
