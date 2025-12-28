import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gap/gap.dart';
import 'package:intl/intl.dart';

import '../../../core/di/injection.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/services/backup_service.dart';
import '../../../core/services/sync_service.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  final _backupService = getIt<BackupService>();
  final _syncService = getIt<SyncService>();

  bool _autoBackup = true;
  bool _darkMode = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('الإعدادات'),
      ),
      body: ListView(
        padding: EdgeInsets.all(16.w),
        children: [
          // Store Info Section
          _SectionTitle(title: 'معلومات المتجر'),
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.store),
                  title: const Text('اسم المتجر'),
                  subtitle: const Text('متجر هور'),
                  trailing: const Icon(Icons.chevron_left),
                  onTap: () => _showEditDialog('اسم المتجر', 'متجر هور'),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.phone),
                  title: const Text('رقم الهاتف'),
                  subtitle: const Text('0500000000'),
                  trailing: const Icon(Icons.chevron_left),
                  onTap: () => _showEditDialog('رقم الهاتف', '0500000000'),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.location_on),
                  title: const Text('العنوان'),
                  subtitle: const Text('المملكة العربية السعودية'),
                  trailing: const Icon(Icons.chevron_left),
                  onTap: () =>
                      _showEditDialog('العنوان', 'المملكة العربية السعودية'),
                ),
              ],
            ),
          ),
          Gap(16.h),

          // Tax Settings
          _SectionTitle(title: 'الضرائب'),
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.percent),
                  title: const Text('نسبة ضريبة القيمة المضافة'),
                  subtitle: const Text('15%'),
                  trailing: const Icon(Icons.chevron_left),
                  onTap: () => _showTaxDialog(),
                ),
                const Divider(height: 1),
                SwitchListTile(
                  secondary: const Icon(Icons.calculate),
                  title: const Text('أسعار شاملة الضريبة'),
                  subtitle: const Text('احتساب الضريبة ضمن السعر'),
                  value: true,
                  onChanged: (value) {},
                ),
              ],
            ),
          ),
          Gap(16.h),

          // Sync & Backup Section
          _SectionTitle(title: 'المزامنة والنسخ الاحتياطي'),
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.cloud_sync),
                  title: const Text('المزامنة السحابية'),
                  subtitle: const Text('متصل'),
                  trailing: ElevatedButton(
                    onPressed: _syncNow,
                    child: const Text('مزامنة الآن'),
                  ),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.backup),
                  title: const Text('النسخ الاحتياطي'),
                  subtitle: FutureBuilder<DateTime?>(
                    future: _getLastBackupTime(),
                    builder: (context, snapshot) {
                      if (snapshot.data != null) {
                        return Text(
                          'آخر نسخة: ${DateFormat('dd/MM/yyyy HH:mm').format(snapshot.data!)}',
                        );
                      }
                      return const Text('لا يوجد نسخ احتياطي');
                    },
                  ),
                  trailing: ElevatedButton(
                    onPressed: _createBackup,
                    child: const Text('نسخ الآن'),
                  ),
                ),
                const Divider(height: 1),
                SwitchListTile(
                  secondary: const Icon(Icons.schedule),
                  title: const Text('نسخ احتياطي تلقائي'),
                  subtitle: const Text('نسخ يومي للبيانات'),
                  value: _autoBackup,
                  onChanged: (value) => setState(() => _autoBackup = value),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.restore),
                  title: const Text('استعادة نسخة احتياطية'),
                  trailing: const Icon(Icons.chevron_left),
                  onTap: _restoreBackup,
                ),
              ],
            ),
          ),
          Gap(16.h),

          // Appearance Section
          _SectionTitle(title: 'المظهر'),
          Card(
            child: Column(
              children: [
                SwitchListTile(
                  secondary: const Icon(Icons.dark_mode),
                  title: const Text('الوضع الداكن'),
                  value: _darkMode,
                  onChanged: (value) => setState(() => _darkMode = value),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.language),
                  title: const Text('اللغة'),
                  subtitle: const Text('العربية'),
                  trailing: const Icon(Icons.chevron_left),
                  onTap: () {},
                ),
              ],
            ),
          ),
          Gap(16.h),

          // Invoice Settings
          _SectionTitle(title: 'إعدادات الفواتير'),
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.numbers),
                  title: const Text('بادئة رقم الفاتورة'),
                  subtitle: const Text('INV-'),
                  trailing: const Icon(Icons.chevron_left),
                  onTap: () => _showEditDialog('بادئة رقم الفاتورة', 'INV-'),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.print),
                  title: const Text('حجم ورق الطباعة'),
                  subtitle: const Text('80mm'),
                  trailing: const Icon(Icons.chevron_left),
                  onTap: () {},
                ),
                const Divider(height: 1),
                SwitchListTile(
                  secondary: const Icon(Icons.auto_awesome),
                  title: const Text('طباعة تلقائية'),
                  subtitle: const Text('طباعة الفاتورة بعد الحفظ'),
                  value: false,
                  onChanged: (value) {},
                ),
              ],
            ),
          ),
          Gap(16.h),

          // About Section
          _SectionTitle(title: 'حول التطبيق'),
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.info),
                  title: const Text('الإصدار'),
                  subtitle: const Text('1.0.0'),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.help),
                  title: const Text('المساعدة والدعم'),
                  trailing: const Icon(Icons.chevron_left),
                  onTap: () {},
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.privacy_tip),
                  title: const Text('سياسة الخصوصية'),
                  trailing: const Icon(Icons.chevron_left),
                  onTap: () {},
                ),
              ],
            ),
          ),
          Gap(32.h),
        ],
      ),
    );
  }

  Future<DateTime?> _getLastBackupTime() async {
    // TODO: Get from settings
    return null;
  }

  void _showEditDialog(String title, String currentValue) {
    final controller = TextEditingController(text: currentValue);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: TextField(
          controller: controller,
          decoration: InputDecoration(
            labelText: title,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              // TODO: Save setting
            },
            child: const Text('حفظ'),
          ),
        ],
      ),
    );
  }

  void _showTaxDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('نسبة الضريبة'),
        content: TextField(
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            labelText: 'النسبة المئوية',
            suffixText: '%',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              // TODO: Save tax rate
            },
            child: const Text('حفظ'),
          ),
        ],
      ),
    );
  }

  Future<void> _syncNow() async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const AlertDialog(
        content: Row(
          children: [
            CircularProgressIndicator(),
            SizedBox(width: 16),
            Text('جاري المزامنة...'),
          ],
        ),
      ),
    );

    try {
      await _syncService.syncAll();
      Navigator.pop(context);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('تمت المزامنة بنجاح'),
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

  Future<void> _createBackup() async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const AlertDialog(
        content: Row(
          children: [
            CircularProgressIndicator(),
            SizedBox(width: 16),
            Text('جاري إنشاء نسخة احتياطية...'),
          ],
        ),
      ),
    );

    try {
      final path = await _backupService.createLocalBackup();
      Navigator.pop(context);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('تم إنشاء النسخة الاحتياطية: $path'),
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
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('استعادة نسخة احتياطية'),
        content: const Text(
          'سيتم استبدال جميع البيانات الحالية بالنسخة الاحتياطية.\n\nهل أنت متأكد؟',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('استعادة'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    // TODO: Implement file picker and restore
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('اختر ملف النسخة الاحتياطية'),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;

  const _SectionTitle({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: 8.h, right: 4.w),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 14.sp,
          fontWeight: FontWeight.bold,
          color: AppColors.primary,
        ),
      ),
    );
  }
}
