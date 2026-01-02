// ═══════════════════════════════════════════════════════════════════════════
// Settings Screen Pro - Professional Design System
// App Settings and Configuration
// ═══════════════════════════════════════════════════════════════════════════

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../../core/theme/design_tokens.dart';
import '../../core/di/injection.dart';
import '../../core/services/backup_service.dart';

class SettingsScreenPro extends ConsumerStatefulWidget {
  const SettingsScreenPro({super.key});

  @override
  ConsumerState<SettingsScreenPro> createState() => _SettingsScreenProState();
}

class _SettingsScreenProState extends ConsumerState<SettingsScreenPro> {
  bool _notifications = true;
  String _currency = 'SAR';
  String _appVersion = '';
  String _buildNumber = '';
  DateTime? _lastBackupDate;

  @override
  void initState() {
    super.initState();
    _loadAppInfo();
    _loadLastBackupDate();
  }

  Future<void> _loadAppInfo() async {
    final packageInfo = await PackageInfo.fromPlatform();
    setState(() {
      _appVersion = packageInfo.version;
      _buildNumber = packageInfo.buildNumber;
    });
  }

  Future<void> _loadLastBackupDate() async {
    final backupService = getIt<BackupService>();
    final lastBackupTime = await backupService.getLastBackupTime();
    setState(() {
      _lastBackupDate = lastBackupTime;
    });
  }

  @override
  Widget build(BuildContext context) {
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
        title: Text(
          'الإعدادات',
          style: AppTypography.headlineSmall.copyWith(
            color: AppColors.textPrimary,
          ),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ═══════════════════════════════════════════════════════════════
            // Business Info
            // ═══════════════════════════════════════════════════════════════
            _buildBusinessCard(),

            // ═══════════════════════════════════════════════════════════════
            // App Settings
            // ═══════════════════════════════════════════════════════════════
            _buildSectionTitle('إعدادات التطبيق'),
            _buildSettingsTile(
              icon: Icons.attach_money_rounded,
              title: 'العملة',
              subtitle: _currency == 'SAR' ? 'ريال سعودي' : _currency,
              onTap: () => _showCurrencyDialog(),
            ),

            // ═══════════════════════════════════════════════════════════════
            // Notifications
            // ═══════════════════════════════════════════════════════════════
            _buildSectionTitle('الإشعارات'),
            _buildSettingsTile(
              icon: Icons.notifications_outlined,
              title: 'الإشعارات',
              subtitle: 'تلقي إشعارات التنبيهات',
              trailing: Switch.adaptive(
                value: _notifications,
                onChanged: (value) => setState(() => _notifications = value),
                activeColor: AppColors.secondary,
              ),
            ),
            _buildSettingsTile(
              icon: Icons.inventory_2_outlined,
              title: 'تنبيهات المخزون',
              subtitle: 'تنبيه عند انخفاض المخزون',
              onTap: () {},
            ),

            // ═══════════════════════════════════════════════════════════════
            // Data & Backup
            // ═══════════════════════════════════════════════════════════════
            _buildSectionTitle('البيانات والنسخ الاحتياطي'),
            _buildSettingsTile(
              icon: Icons.cloud_upload_outlined,
              title: 'النسخ الاحتياطي',
              subtitle: _lastBackupDate != null
                  ? 'آخر نسخة: ${_formatDate(_lastBackupDate!)}'
                  : 'لم يتم إنشاء نسخة احتياطية',
              onTap: () => context.push('/backup'),
            ),

            // ═══════════════════════════════════════════════════════════════
            // Invoice Settings
            // ═══════════════════════════════════════════════════════════════
            _buildSectionTitle('إعدادات الفواتير'),
            _buildSettingsTile(
              icon: Icons.print_rounded,
              title: 'إعدادات الطباعة',
              subtitle: 'إعداد الطابعة وقالب الفاتورة',
              onTap: () => context.push('/settings/print'),
            ),
            _buildSettingsTile(
              icon: Icons.receipt_outlined,
              title: 'قالب الفاتورة',
              subtitle: 'تخصيص تصميم الفاتورة',
              onTap: () {},
            ),
            _buildSettingsTile(
              icon: Icons.percent_rounded,
              title: 'إعدادات الضريبة',
              subtitle: 'ضريبة القيمة المضافة 15%',
              onTap: () {},
            ),

            // ═══════════════════════════════════════════════════════════════
            // Logout
            // ═══════════════════════════════════════════════════════════════
            SizedBox(height: AppSpacing.lg),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: AppSpacing.md),
              child: OutlinedButton(
                onPressed: () => _showLogoutDialog(),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.error,
                  side: BorderSide(color: AppColors.error),
                  padding: EdgeInsets.symmetric(vertical: AppSpacing.md),
                  minimumSize: Size(double.infinity, 50.h),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.logout_rounded),
                    SizedBox(width: AppSpacing.sm),
                    Text(
                      'تسجيل الخروج',
                      style: AppTypography.labelLarge.copyWith(
                        color: AppColors.error,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            SizedBox(height: AppSpacing.xxl),
          ],
        ),
      ),
    );
  }

  Widget _buildBusinessCard() {
    return Container(
      margin: EdgeInsets.all(AppSpacing.md),
      padding: EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.primary,
            AppColors.primary.withOpacity(0.8),
          ],
        ),
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 64.w,
                height: 64.w,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
                child: Icon(
                  Icons.store_rounded,
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
                      'مؤسسة الهور التجارية',
                      style: AppTypography.titleMedium.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    SizedBox(height: 4.h),
                    Text(
                      'الباقة المميزة',
                      style: AppTypography.bodySmall.copyWith(
                        color: Colors.white.withOpacity(0.8),
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: () {},
                icon: Icon(
                  Icons.edit_outlined,
                  color: Colors.white.withOpacity(0.8),
                ),
              ),
            ],
          ),
          SizedBox(height: AppSpacing.md),
          Container(
            padding: EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.sm,
            ),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              borderRadius: BorderRadius.circular(AppRadius.sm),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.info_outline_rounded,
                  color: Colors.white.withOpacity(0.9),
                  size: 16.sp,
                ),
                SizedBox(width: AppSpacing.xs),
                Text(
                  'Hoor Manager',
                  style: AppTypography.bodySmall.copyWith(
                    color: Colors.white.withOpacity(0.9),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                SizedBox(width: AppSpacing.sm),
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: AppSpacing.sm,
                    vertical: 2.h,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(AppRadius.xs),
                  ),
                  child: Text(
                    'v$_appVersion${_buildNumber.isNotEmpty ? ' ($_buildNumber)' : ''}',
                    style: AppTypography.labelSmall.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
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

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.lg,
        AppSpacing.md,
        AppSpacing.sm,
      ),
      child: Text(
        title,
        style: AppTypography.labelLarge.copyWith(
          color: AppColors.textTertiary,
        ),
      ),
    );
  }

  Widget _buildSettingsTile({
    required IconData icon,
    required String title,
    required String subtitle,
    Widget? trailing,
    VoidCallback? onTap,
  }) {
    return ListTile(
      onTap: onTap,
      leading: Container(
        padding: EdgeInsets.all(AppSpacing.sm),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppRadius.sm),
        ),
        child: Icon(icon, color: AppColors.textSecondary, size: AppIconSize.sm),
      ),
      title: Text(
        title,
        style: AppTypography.titleSmall.copyWith(
          color: AppColors.textPrimary,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: AppTypography.bodySmall.copyWith(
          color: AppColors.textTertiary,
        ),
      ),
      trailing: trailing ??
          Icon(
            Icons.chevron_left_rounded,
            color: AppColors.textTertiary,
          ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);

    if (diff.inDays == 0) {
      return 'اليوم ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
    } else if (diff.inDays == 1) {
      return 'أمس ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }

  void _showCurrencyDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('اختر العملة'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            RadioListTile(
              value: 'SAR',
              groupValue: _currency,
              onChanged: (value) {
                setState(() => _currency = value!);
                Navigator.pop(context);
              },
              title: const Text('ريال سعودي (ر.س)'),
            ),
            RadioListTile(
              value: 'USD',
              groupValue: _currency,
              onChanged: (value) {
                setState(() => _currency = value!);
                Navigator.pop(context);
              },
              title: const Text('دولار أمريكي (\$)'),
            ),
            RadioListTile(
              value: 'AED',
              groupValue: _currency,
              onChanged: (value) {
                setState(() => _currency = value!);
                Navigator.pop(context);
              },
              title: const Text('درهم إماراتي'),
            ),
          ],
        ),
      ),
    );
  }

  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('تسجيل الخروج'),
        content: const Text('هل أنت متأكد من تسجيل الخروج؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إلغاء'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(context);
              // TODO: Handle logout
            },
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.error,
            ),
            child: const Text('تسجيل الخروج'),
          ),
        ],
      ),
    );
  }
}
