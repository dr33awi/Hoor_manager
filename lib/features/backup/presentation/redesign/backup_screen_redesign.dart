/// ═══════════════════════════════════════════════════════════════════════════
/// Backup Screen - Redesigned
/// Modern Backup Management Interface
/// ═══════════════════════════════════════════════════════════════════════════
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';

import '../../../../core/di/injection.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/services/backup_service.dart';

class BackupScreenRedesign extends ConsumerStatefulWidget {
  const BackupScreenRedesign({super.key});

  @override
  ConsumerState<BackupScreenRedesign> createState() =>
      _BackupScreenRedesignState();
}

class _BackupScreenRedesignState extends ConsumerState<BackupScreenRedesign> {
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
    setState(() {
      _backups = [];
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: HoorColors.background,
      appBar: AppBar(
        backgroundColor: HoorColors.surface,
        title: Text('النسخ الاحتياطي', style: HoorTypography.headlineSmall),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.pop(),
        ),
      ),
      body: ListView(
        padding: EdgeInsets.all(HoorSpacing.md.w),
        children: [
          // Quick Actions
          _buildQuickActions(),
          SizedBox(height: HoorSpacing.lg.h),

          // Auto Backup Settings
          _buildAutoBackupSettings(),
          SizedBox(height: HoorSpacing.lg.h),

          // Backup History
          _buildBackupHistory(),
        ],
      ),
    );
  }

  Widget _buildQuickActions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'إجراءات سريعة',
          style: HoorTypography.titleMedium.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: HoorSpacing.sm.h),
        Row(
          children: [
            Expanded(
              child: _buildActionCard(
                icon: Icons.backup_rounded,
                title: 'نسخ الآن',
                subtitle: 'إنشاء نسخة محلية',
                color: HoorColors.primary,
                onTap: _createLocalBackup,
              ),
            ),
            SizedBox(width: HoorSpacing.sm.w),
            Expanded(
              child: _buildActionCard(
                icon: Icons.cloud_upload_rounded,
                title: 'رفع للسحابة',
                subtitle: 'حفظ نسخة سحابية',
                color: HoorColors.success,
                onTap: _createCloudBackup,
              ),
            ),
          ],
        ),
        SizedBox(height: HoorSpacing.sm.h),
        Row(
          children: [
            Expanded(
              child: _buildActionCard(
                icon: Icons.restore_rounded,
                title: 'استعادة',
                subtitle: 'من نسخة سابقة',
                color: HoorColors.warning,
                onTap: _restoreBackup,
              ),
            ),
            SizedBox(width: HoorSpacing.sm.w),
            Expanded(
              child: _buildActionCard(
                icon: Icons.cloud_download_rounded,
                title: 'تنزيل سحابي',
                subtitle: 'استعادة من السحابة',
                color: HoorColors.info,
                onTap: _restoreFromCloud,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildActionCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(HoorRadius.lg),
      child: Container(
        padding: EdgeInsets.all(HoorSpacing.md.w),
        decoration: BoxDecoration(
          color: HoorColors.surface,
          borderRadius: BorderRadius.circular(HoorRadius.lg),
          border: Border.all(color: HoorColors.border),
        ),
        child: Column(
          children: [
            Container(
              padding: EdgeInsets.all(HoorSpacing.sm.w),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(HoorRadius.md),
              ),
              child: Icon(icon, color: color, size: 28),
            ),
            SizedBox(height: HoorSpacing.sm.h),
            Text(
              title,
              style: HoorTypography.titleSmall.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(height: HoorSpacing.xxs.h),
            Text(
              subtitle,
              style: HoorTypography.labelSmall.copyWith(
                color: HoorColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAutoBackupSettings() {
    return Container(
      decoration: BoxDecoration(
        color: HoorColors.surface,
        borderRadius: BorderRadius.circular(HoorRadius.lg),
        border: Border.all(color: HoorColors.border),
      ),
      child: Column(
        children: [
          SwitchListTile(
            secondary: Container(
              padding: EdgeInsets.all(HoorSpacing.xs.w),
              decoration: BoxDecoration(
                color: HoorColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(HoorRadius.sm),
              ),
              child: Icon(Icons.schedule_rounded,
                  color: HoorColors.primary, size: 20),
            ),
            title: Text('النسخ التلقائي', style: HoorTypography.bodyMedium),
            subtitle: Text(
              'إنشاء نسخة يومية تلقائياً',
              style: HoorTypography.labelSmall.copyWith(
                color: HoorColors.textSecondary,
              ),
            ),
            value: _autoBackupEnabled,
            activeTrackColor: HoorColors.primary,
            onChanged: (value) => setState(() => _autoBackupEnabled = value),
          ),
          Divider(color: HoorColors.border, height: 1),
          ListTile(
            leading: Container(
              padding: EdgeInsets.all(HoorSpacing.xs.w),
              decoration: BoxDecoration(
                color: HoorColors.info.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(HoorRadius.sm),
              ),
              child: Icon(Icons.access_time_rounded,
                  color: HoorColors.info, size: 20),
            ),
            title: Text('وقت النسخ', style: HoorTypography.bodyMedium),
            subtitle: Text(
              '02:00 صباحاً',
              style: HoorTypography.labelSmall.copyWith(
                color: HoorColors.textSecondary,
              ),
            ),
            trailing: Icon(Icons.chevron_left_rounded,
                color: HoorColors.textSecondary),
            enabled: _autoBackupEnabled,
            onTap: _autoBackupEnabled ? () => _selectBackupTime() : null,
          ),
          Divider(color: HoorColors.border, height: 1),
          ListTile(
            leading: Container(
              padding: EdgeInsets.all(HoorSpacing.xs.w),
              decoration: BoxDecoration(
                color: HoorColors.warning.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(HoorRadius.sm),
              ),
              child: Icon(Icons.history_rounded,
                  color: HoorColors.warning, size: 20),
            ),
            title: Text('الاحتفاظ بالنسخ', style: HoorTypography.bodyMedium),
            subtitle: Text(
              'آخر 7 نسخ',
              style: HoorTypography.labelSmall.copyWith(
                color: HoorColors.textSecondary,
              ),
            ),
            trailing: Icon(Icons.chevron_left_rounded,
                color: HoorColors.textSecondary),
            enabled: _autoBackupEnabled,
            onTap: _autoBackupEnabled ? () => _selectRetentionPeriod() : null,
          ),
        ],
      ),
    );
  }

  Widget _buildBackupHistory() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'النسخ السابقة',
              style: HoorTypography.titleMedium.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            TextButton.icon(
              onPressed: _loadBackups,
              icon: Icon(Icons.refresh_rounded,
                  color: HoorColors.primary, size: 18),
              label: Text(
                'تحديث',
                style: HoorTypography.labelMedium.copyWith(
                  color: HoorColors.primary,
                ),
              ),
            ),
          ],
        ),
        SizedBox(height: HoorSpacing.sm.h),
        if (_isLoading)
          const Center(
              child: CircularProgressIndicator(color: HoorColors.primary))
        else if (_backups.isEmpty)
          _buildEmptyBackupState()
        else
          ...(_backups.map((backup) => _buildBackupCard(backup))),
      ],
    );
  }

  Widget _buildEmptyBackupState() {
    return Container(
      padding: EdgeInsets.all(HoorSpacing.xl.w),
      decoration: BoxDecoration(
        color: HoorColors.surface,
        borderRadius: BorderRadius.circular(HoorRadius.lg),
        border: Border.all(color: HoorColors.border),
      ),
      child: Column(
        children: [
          Container(
            padding: EdgeInsets.all(HoorSpacing.lg.w),
            decoration: BoxDecoration(
              color: HoorColors.primary.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.backup_outlined,
                size: 48, color: HoorColors.primary),
          ),
          SizedBox(height: HoorSpacing.md.h),
          Text(
            'لا توجد نسخ احتياطية',
            style: HoorTypography.titleMedium.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: HoorSpacing.xs.h),
          Text(
            'أنشئ نسخة احتياطية للحفاظ على بياناتك',
            style: HoorTypography.bodySmall.copyWith(
              color: HoorColors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: HoorSpacing.md.h),
          ElevatedButton.icon(
            onPressed: _createLocalBackup,
            icon: const Icon(Icons.backup_rounded, color: Colors.white),
            label: Text('إنشاء نسخة احتياطية',
                style: HoorTypography.labelLarge.copyWith(color: Colors.white)),
            style: ElevatedButton.styleFrom(
              backgroundColor: HoorColors.primary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(HoorRadius.md),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBackupCard(Map<String, dynamic> backup) {
    return Container(
      margin: EdgeInsets.only(bottom: HoorSpacing.sm.h),
      decoration: BoxDecoration(
        color: HoorColors.surface,
        borderRadius: BorderRadius.circular(HoorRadius.md),
        border: Border.all(color: HoorColors.border),
      ),
      child: ListTile(
        leading: Container(
          padding: EdgeInsets.all(HoorSpacing.xs.w),
          decoration: BoxDecoration(
            color: HoorColors.success.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(HoorRadius.sm),
          ),
          child: Icon(Icons.folder_zip_rounded,
              color: HoorColors.success, size: 24),
        ),
        title: Text(
          backup['name'] ?? 'نسخة احتياطية',
          style: HoorTypography.bodyMedium.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: Text(
          DateFormat('yyyy/MM/dd - HH:mm').format(
            backup['date'] ?? DateTime.now(),
          ),
          style: HoorTypography.labelSmall.copyWith(
            color: HoorColors.textSecondary,
          ),
        ),
        trailing: PopupMenuButton<String>(
          icon: Icon(Icons.more_vert_rounded, color: HoorColors.textSecondary),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(HoorRadius.md),
          ),
          onSelected: (value) {
            if (value == 'restore') {
              _restoreFromBackup(backup);
            } else if (value == 'share') {
              _shareBackup(backup);
            } else if (value == 'delete') {
              _deleteBackup(backup);
            }
          },
          itemBuilder: (context) => [
            PopupMenuItem(
              value: 'restore',
              child: Row(
                children: [
                  Icon(Icons.restore_rounded,
                      color: HoorColors.primary, size: 20),
                  SizedBox(width: HoorSpacing.sm.w),
                  Text('استعادة', style: HoorTypography.bodyMedium),
                ],
              ),
            ),
            PopupMenuItem(
              value: 'share',
              child: Row(
                children: [
                  Icon(Icons.share_rounded, color: HoorColors.info, size: 20),
                  SizedBox(width: HoorSpacing.sm.w),
                  Text('مشاركة', style: HoorTypography.bodyMedium),
                ],
              ),
            ),
            PopupMenuItem(
              value: 'delete',
              child: Row(
                children: [
                  Icon(Icons.delete_rounded, color: HoorColors.error, size: 20),
                  SizedBox(width: HoorSpacing.sm.w),
                  Text('حذف',
                      style: HoorTypography.bodyMedium
                          .copyWith(color: HoorColors.error)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showLoadingDialog(String message) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: HoorColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(HoorRadius.lg),
        ),
        content: Row(
          children: [
            const CircularProgressIndicator(color: HoorColors.primary),
            SizedBox(width: HoorSpacing.md.w),
            Text(message, style: HoorTypography.bodyMedium),
          ],
        ),
      ),
    );
  }

  Future<void> _createLocalBackup() async {
    _showLoadingDialog('جاري إنشاء النسخة الاحتياطية...');

    try {
      final path = await _backupService.createLocalBackup();
      Navigator.pop(context);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('تم إنشاء النسخة الاحتياطية'),
          backgroundColor: HoorColors.success,
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
          backgroundColor: HoorColors.error,
        ),
      );
    }
  }

  Future<void> _createCloudBackup() async {
    _showLoadingDialog('جاري رفع النسخة للسحابة...');

    try {
      await _backupService.createCloudBackup();
      Navigator.pop(context);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('تم رفع النسخة للسحابة'),
          backgroundColor: HoorColors.success,
        ),
      );
    } catch (e) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('حدث خطأ: $e'),
          backgroundColor: HoorColors.error,
        ),
      );
    }
  }

  Future<void> _restoreBackup() async {
    // TODO: Implement file picker for backup restore
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('اختر ملف النسخة الاحتياطية'),
        backgroundColor: HoorColors.info,
      ),
    );
  }

  Future<void> _restoreFromCloud() async {
    _showLoadingDialog('جاري استعادة النسخة من السحابة...');

    try {
      await _backupService.restoreFromCloud();
      Navigator.pop(context);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('تم استعادة النسخة بنجاح'),
          backgroundColor: HoorColors.success,
        ),
      );
    } catch (e) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('حدث خطأ: $e'),
          backgroundColor: HoorColors.error,
        ),
      );
    }
  }

  void _restoreFromBackup(Map<String, dynamic> backup) {
    // TODO: Implement restore from specific backup
  }

  void _shareBackup(Map<String, dynamic> backup) {
    // TODO: Implement share backup
  }

  void _deleteBackup(Map<String, dynamic> backup) {
    // TODO: Implement delete backup
  }

  void _selectBackupTime() {
    // TODO: Implement time picker
  }

  void _selectRetentionPeriod() {
    // TODO: Implement retention period selector
  }
}
