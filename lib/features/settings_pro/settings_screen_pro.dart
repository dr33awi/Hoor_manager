// ═══════════════════════════════════════════════════════════════════════════
// Settings Screen Pro - Professional Design System
// App Settings and Configuration
// ═══════════════════════════════════════════════════════════════════════════

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/pro/design_tokens.dart';

class SettingsScreenPro extends StatefulWidget {
  const SettingsScreenPro({super.key});

  @override
  State<SettingsScreenPro> createState() => _SettingsScreenProState();
}

class _SettingsScreenProState extends State<SettingsScreenPro> {
  bool _darkMode = false;
  bool _notifications = true;
  bool _biometricAuth = false;
  String _language = 'ar';
  String _currency = 'SAR';

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
              icon: Icons.dark_mode_outlined,
              title: 'الوضع الداكن',
              subtitle: 'تفعيل المظهر الداكن',
              trailing: Switch.adaptive(
                value: _darkMode,
                onChanged: (value) => setState(() => _darkMode = value),
                activeColor: AppColors.secondary,
              ),
            ),
            _buildSettingsTile(
              icon: Icons.language_outlined,
              title: 'اللغة',
              subtitle: _language == 'ar' ? 'العربية' : 'English',
              onTap: () => _showLanguageDialog(),
            ),
            _buildSettingsTile(
              icon: Icons.attach_money_rounded,
              title: 'العملة',
              subtitle: _currency == 'SAR' ? 'ريال سعودي' : _currency,
              onTap: () => _showCurrencyDialog(),
            ),

            // ═══════════════════════════════════════════════════════════════
            // Security
            // ═══════════════════════════════════════════════════════════════
            _buildSectionTitle('الأمان'),
            _buildSettingsTile(
              icon: Icons.fingerprint_rounded,
              title: 'تسجيل الدخول بالبصمة',
              subtitle: 'استخدام البصمة لفتح التطبيق',
              trailing: Switch.adaptive(
                value: _biometricAuth,
                onChanged: (value) => setState(() => _biometricAuth = value),
                activeColor: AppColors.secondary,
              ),
            ),
            _buildSettingsTile(
              icon: Icons.lock_outline_rounded,
              title: 'تغيير كلمة المرور',
              subtitle: 'تحديث كلمة المرور',
              onTap: () {},
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
              subtitle: 'آخر نسخة: اليوم 10:30 ص',
              onTap: () {},
            ),
            _buildSettingsTile(
              icon: Icons.cloud_download_outlined,
              title: 'استعادة البيانات',
              subtitle: 'استعادة من نسخة احتياطية',
              onTap: () {},
            ),
            _buildSettingsTile(
              icon: Icons.upload_file_outlined,
              title: 'تصدير البيانات',
              subtitle: 'تصدير البيانات بصيغة Excel',
              onTap: () {},
            ),

            // ═══════════════════════════════════════════════════════════════
            // Invoice Settings
            // ═══════════════════════════════════════════════════════════════
            _buildSectionTitle('إعدادات الفواتير'),
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
            // About & Support
            // ═══════════════════════════════════════════════════════════════
            _buildSectionTitle('حول التطبيق'),
            _buildSettingsTile(
              icon: Icons.help_outline_rounded,
              title: 'المساعدة والدعم',
              subtitle: 'الأسئلة الشائعة والتواصل',
              onTap: () {},
            ),
            _buildSettingsTile(
              icon: Icons.info_outline_rounded,
              title: 'حول Hoor Manager',
              subtitle: 'الإصدار 2.0.0',
              onTap: () {},
            ),
            _buildSettingsTile(
              icon: Icons.star_outline_rounded,
              title: 'تقييم التطبيق',
              subtitle: 'قيّم التطبيق على المتجر',
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
      child: Row(
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

  void _showLanguageDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('اختر اللغة'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            RadioListTile(
              value: 'ar',
              groupValue: _language,
              onChanged: (value) {
                setState(() => _language = value!);
                Navigator.pop(context);
              },
              title: const Text('العربية'),
            ),
            RadioListTile(
              value: 'en',
              groupValue: _language,
              onChanged: (value) {
                setState(() => _language = value!);
                Navigator.pop(context);
              },
              title: const Text('English'),
            ),
          ],
        ),
      ),
    );
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
