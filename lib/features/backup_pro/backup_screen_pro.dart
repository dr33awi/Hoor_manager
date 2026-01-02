// ═══════════════════════════════════════════════════════════════════════════
// Backup Screen Pro - Professional Design System
// Backup Management with Modern UI
// ═══════════════════════════════════════════════════════════════════════════

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';

import '../../core/theme/design_tokens.dart';
import '../../core/di/injection.dart';
import '../../core/services/backup_service.dart';

class BackupScreenPro extends ConsumerStatefulWidget {
  const BackupScreenPro({super.key});

  @override
  ConsumerState<BackupScreenPro> createState() => _BackupScreenProState();
}

class _BackupScreenProState extends ConsumerState<BackupScreenPro> {
  final _backupService = getIt<BackupService>();

  bool _isCreatingBackup = false;
  bool _isRestoring = false;
  String? _lastBackupPath;
  DateTime? _lastBackupDate;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        leading: IconButton(
          onPressed: () => context.pop(),
          icon: Icon(Icons.arrow_back_ios_rounded,
              color: AppColors.textSecondary),
        ),
        title: Text(
          'النسخ الاحتياطي',
          style:
              AppTypography.titleLarge.copyWith(color: AppColors.textPrimary),
        ),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Status Card
            _buildStatusCard(),
            SizedBox(height: AppSpacing.lg),

            // Quick Actions
            Text(
              'إجراءات سريعة',
              style: AppTypography.titleMedium
                  .copyWith(fontWeight: FontWeight.bold),
            ),
            SizedBox(height: AppSpacing.md),
            _buildQuickActions(),
            SizedBox(height: AppSpacing.lg),

            // Info Section
            _buildInfoSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusCard() {
    return Container(
      padding: EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.primary, AppColors.primary.withOpacity(0.8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(AppRadius.xl),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
                child: Icon(
                  Icons.cloud_done_rounded,
                  color: Colors.white,
                  size: 32.sp,
                ),
              ),
              SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'حالة النسخ الاحتياطي',
                      style: AppTypography.bodySmall.copyWith(
                        color: Colors.white.withOpacity(0.8),
                      ),
                    ),
                    Text(
                      _lastBackupDate != null
                          ? 'آخر نسخة: ${DateFormat('dd/MM/yyyy hh:mm a', 'ar').format(_lastBackupDate!)}'
                          : 'لم يتم إنشاء نسخة بعد',
                      style: AppTypography.titleSmall.copyWith(
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: AppSpacing.lg),
          Container(
            padding: EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.info_outline_rounded,
                  color: Colors.white.withOpacity(0.8),
                  size: 20.sp,
                ),
                SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    'يُنصح بإنشاء نسخة احتياطية بشكل دوري للحفاظ على بياناتك',
                    style: AppTypography.bodySmall.copyWith(
                      color: Colors.white.withOpacity(0.9),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _ActionCard(
                icon: Icons.backup_rounded,
                title: 'نسخ الآن',
                subtitle: 'إنشاء نسخة محلية',
                color: AppColors.primary,
                isLoading: _isCreatingBackup,
                onTap: _createLocalBackup,
              ),
            ),
            SizedBox(width: AppSpacing.md),
            Expanded(
              child: _ActionCard(
                icon: Icons.cloud_upload_rounded,
                title: 'رفع للسحابة',
                subtitle: 'حفظ نسخة سحابية',
                color: AppColors.success,
                onTap: _createCloudBackup,
              ),
            ),
          ],
        ),
        SizedBox(height: AppSpacing.md),
        Row(
          children: [
            Expanded(
              child: _ActionCard(
                icon: Icons.restore_rounded,
                title: 'استعادة',
                subtitle: 'من نسخة محلية',
                color: AppColors.warning,
                isLoading: _isRestoring,
                onTap: _restoreBackup,
              ),
            ),
            SizedBox(width: AppSpacing.md),
            Expanded(
              child: _ActionCard(
                icon: Icons.share_rounded,
                title: 'مشاركة',
                subtitle: 'مشاركة النسخة',
                color: AppColors.info,
                onTap: _shareBackup,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildInfoSection() {
    return ProCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.help_outline_rounded, color: AppColors.primary),
              SizedBox(width: AppSpacing.sm),
              Text(
                'معلومات مهمة',
                style: AppTypography.titleSmall.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          SizedBox(height: AppSpacing.md),
          _buildInfoItem(
            'النسخ المحلي',
            'يتم حفظ النسخة على جهازك ويمكنك مشاركتها',
          ),
          SizedBox(height: AppSpacing.sm),
          _buildInfoItem(
            'النسخ السحابي',
            'يتم رفع النسخة لخادم Firebase للوصول من أي جهاز',
          ),
          SizedBox(height: AppSpacing.sm),
          _buildInfoItem(
            'الاستعادة',
            'تأكد من إغلاق التطبيق وإعادة فتحه بعد الاستعادة',
          ),
        ],
      ),
    );
  }

  Widget _buildInfoItem(String title, String description) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 6.w,
          height: 6.h,
          margin: EdgeInsets.only(top: 6.h),
          decoration: BoxDecoration(
            color: AppColors.primary,
            shape: BoxShape.circle,
          ),
        ),
        SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: AppTypography.labelLarge.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                description,
                style: AppTypography.bodySmall.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _createLocalBackup() async {
    setState(() => _isCreatingBackup = true);

    try {
      final path = await _backupService.createLocalBackup();
      setState(() {
        _lastBackupPath = path;
        _lastBackupDate = DateTime.now();
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('تم إنشاء النسخة الاحتياطية بنجاح'),
            backgroundColor: AppColors.success,
            action: SnackBarAction(
              label: 'مشاركة',
              textColor: Colors.white,
              onPressed: _shareBackup,
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('خطأ في إنشاء النسخة: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      setState(() => _isCreatingBackup = false);
    }
  }

  Future<void> _createCloudBackup() async {
    // Show coming soon dialog
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.cloud_rounded, color: AppColors.primary),
            SizedBox(width: AppSpacing.sm),
            const Text('النسخ السحابي'),
          ],
        ),
        content: const Text(
          'هذه الميزة قيد التطوير وستكون متاحة قريباً.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('حسناً'),
          ),
        ],
      ),
    );
  }

  Future<void> _restoreBackup() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('استعادة النسخة الاحتياطية'),
        content: const Text(
          'سيتم استبدال جميع البيانات الحالية بالبيانات من النسخة الاحتياطية. '
          'هل أنت متأكد من المتابعة؟',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('إلغاء'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.warning),
            child: const Text('استعادة'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() => _isRestoring = true);

    try {
      await _backupService.restoreFromCloud();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content:
                const Text('تمت الاستعادة بنجاح. يرجى إعادة تشغيل التطبيق.'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('خطأ في الاستعادة: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      setState(() => _isRestoring = false);
    }
  }

  Future<void> _shareBackup() async {
    if (_lastBackupPath == null) {
      // Create backup first
      await _createLocalBackup();
    }

    if (_lastBackupPath != null) {
      try {
        await Share.shareXFiles(
          [XFile(_lastBackupPath!)],
          text: 'نسخة احتياطية - حور المدير',
        );
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('خطأ في المشاركة: $e'),
              backgroundColor: AppColors.error,
            ),
          );
        }
      }
    }
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// Action Card
// ═══════════════════════════════════════════════════════════════════════════

class _ActionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final bool isLoading;
  final VoidCallback onTap;

  const _ActionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    this.isLoading = false,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ProCard(
      onTap: isLoading ? null : onTap,
      child: Column(
        children: [
          Container(
            padding: EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
            child: isLoading
                ? SizedBox(
                    width: 24.w,
                    height: 24.h,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation(color),
                    ),
                  )
                : Icon(icon, color: color, size: 28.sp),
          ),
          SizedBox(height: AppSpacing.sm),
          Text(
            title,
            style: AppTypography.titleSmall.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: AppSpacing.xxs),
          Text(
            subtitle,
            style: AppTypography.labelSmall.copyWith(
              color: AppColors.textTertiary,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
