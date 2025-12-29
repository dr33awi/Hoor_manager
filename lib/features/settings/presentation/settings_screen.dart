import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gap/gap.dart';
import 'package:intl/intl.dart';

import '../../../core/di/injection.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/services/backup_service.dart';
import '../../../core/services/sync_service.dart';
import '../../../core/services/currency_service.dart';
import '../../../data/database/app_database.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  final _backupService = getIt<BackupService>();
  final _syncService = getIt<SyncService>();
  final _currencyService = getIt<CurrencyService>();
  final _database = getIt<AppDatabase>();

  bool _autoBackup = true;
  bool _autoPrint = false;
  String _invoicePrefix = 'INV';
  String _printSize = '80mm';

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final autoBackup = await _database.getSetting('auto_backup');
    final autoPrint = await _database.getSetting('auto_print');
    final invoicePrefix = await _database.getSetting('invoice_prefix');
    final printSize = await _database.getSetting('print_size');

    if (mounted) {
      setState(() {
        _autoBackup = autoBackup == 'true';
        _autoPrint = autoPrint == 'true';
        _invoicePrefix = invoicePrefix ?? 'INV';
        _printSize = printSize ?? '80mm';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('الإعدادات'),
      ),
      body: ListView(
        padding: EdgeInsets.all(16.w),
        children: [
          // Currency & Exchange Rate Settings
          _SectionTitle(title: 'العملة وسعر الصرف'),
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.currency_exchange),
                  title: const Text('العملة الرئيسية'),
                  subtitle: const Text('الليرة السورية (ل.س)'),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.attach_money),
                  title: const Text('سعر صرف الدولار'),
                  subtitle: Text(
                    '1 \$ = ${_currencyService.exchangeRate.toStringAsFixed(0)} ل.س',
                  ),
                  trailing: const Icon(Icons.chevron_left),
                  onTap: () => _showExchangeRateDialog(),
                ),
                const Divider(height: 1),
                SwitchListTile(
                  secondary: const Icon(Icons.swap_horiz),
                  title: const Text('الأسعار المدخلة بالدولار'),
                  subtitle: const Text('تحويل تلقائي للأسعار عند التغيير'),
                  value: _currencyService.basePriceInUsd,
                  onChanged: (value) async {
                    await _currencyService.setBasePriceInUsd(value);
                    setState(() {});
                  },
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

          // Invoice Settings
          _SectionTitle(title: 'إعدادات الفواتير'),
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.numbers),
                  title: const Text('بادئة رقم الفاتورة'),
                  subtitle: Text(_invoicePrefix),
                  trailing: const Icon(Icons.chevron_left),
                  onTap: () => _showInvoicePrefixDialog(),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.print),
                  title: const Text('حجم ورق الطباعة'),
                  subtitle: Text(_printSize),
                  trailing: const Icon(Icons.chevron_left),
                  onTap: () => _showPrintSizeDialog(),
                ),
                const Divider(height: 1),
                SwitchListTile(
                  secondary: const Icon(Icons.auto_awesome),
                  title: const Text('طباعة تلقائية'),
                  subtitle: const Text('طباعة الفاتورة بعد الحفظ'),
                  value: _autoPrint,
                  onChanged: (value) async {
                    await _database.setSetting('auto_print', value.toString());
                    setState(() => _autoPrint = value);
                  },
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
              ],
            ),
          ),
          Gap(32.h),
        ],
      ),
    );
  }

  Future<DateTime?> _getLastBackupTime() async {
    return await _backupService.getLastBackupTime();
  }

  void _showInvoicePrefixDialog() {
    final controller = TextEditingController(text: _invoicePrefix);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('بادئة رقم الفاتورة'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: 'البادئة',
            hintText: 'مثال: INV, FAT',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () async {
              final value = controller.text.trim().toUpperCase();
              if (value.isNotEmpty) {
                await _database.setSetting('invoice_prefix', value);
                setState(() => _invoicePrefix = value);
              }
              Navigator.pop(context);
            },
            child: const Text('حفظ'),
          ),
        ],
      ),
    );
  }

  void _showPrintSizeDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('حجم ورق الطباعة'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            RadioListTile<String>(
              title: const Text('58mm (صغير)'),
              value: '58mm',
              groupValue: _printSize,
              onChanged: (value) async {
                await _database.setSetting('print_size', value!);
                setState(() => _printSize = value);
                Navigator.pop(context);
              },
            ),
            RadioListTile<String>(
              title: const Text('80mm (عادي)'),
              value: '80mm',
              groupValue: _printSize,
              onChanged: (value) async {
                await _database.setSetting('print_size', value!);
                setState(() => _printSize = value);
                Navigator.pop(context);
              },
            ),
            RadioListTile<String>(
              title: const Text('A4'),
              value: 'A4',
              groupValue: _printSize,
              onChanged: (value) async {
                await _database.setSetting('print_size', value!);
                setState(() => _printSize = value);
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showExchangeRateDialog() {
    final controller = TextEditingController(
      text: _currencyService.exchangeRate.toStringAsFixed(0),
    );
    final parentContext = context; // حفظ السياق الأصلي

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('سعر صرف الدولار'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'أدخل سعر صرف الدولار الأمريكي مقابل الليرة السورية',
              style: TextStyle(fontSize: 14),
            ),
            Gap(16.h),
            TextField(
              controller: controller,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'سعر الصرف',
                prefixText: '1 \$ = ',
                suffixText: 'ل.س',
                border: OutlineInputBorder(),
              ),
            ),
            Gap(8.h),
            Text(
              'ملاحظة: تغيير سعر الصرف سيؤثر على عرض أسعار جميع المنتجات',
              style: TextStyle(
                fontSize: 12,
                color: AppColors.warning,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () async {
              final newRate = double.tryParse(controller.text);
              if (newRate != null && newRate > 0) {
                final oldRate = _currencyService.exchangeRate;

                // حساب نسبة التغيير
                final ratio = newRate / oldRate;

                Navigator.pop(dialogContext);

                if (!mounted) return;

                // عرض مربع حوار للتأكيد
                final confirmed = await showDialog<bool>(
                  context: parentContext,
                  builder: (confirmContext) => AlertDialog(
                    title: const Text('تأكيد تحديث الأسعار'),
                    content: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                            'سعر الصرف القديم: ${oldRate.toStringAsFixed(0)} ل.س'),
                        Text(
                            'سعر الصرف الجديد: ${newRate.toStringAsFixed(0)} ل.س'),
                        Gap(8.h),
                        Text(
                          'نسبة التغيير: ${((ratio - 1) * 100).toStringAsFixed(1)}%',
                          style: TextStyle(
                            color:
                                ratio > 1 ? AppColors.error : AppColors.success,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Gap(16.h),
                        const Text(
                          'سيتم تحديث جميع أسعار المنتجات تلقائياً حسب النسبة الجديدة.',
                          style: TextStyle(fontSize: 12),
                        ),
                      ],
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(confirmContext, false),
                        child: const Text('إلغاء'),
                      ),
                      ElevatedButton(
                        onPressed: () => Navigator.pop(confirmContext, true),
                        child: const Text('تأكيد التحديث'),
                      ),
                    ],
                  ),
                );

                if (confirmed == true && mounted) {
                  // عرض مؤشر التحميل
                  showDialog(
                    context: parentContext,
                    barrierDismissible: false,
                    builder: (loadingContext) => const AlertDialog(
                      content: Row(
                        children: [
                          CircularProgressIndicator(),
                          SizedBox(width: 16),
                          Text('جاري تحديث الأسعار...'),
                        ],
                      ),
                    ),
                  );

                  try {
                    // تحديث سعر الصرف
                    await _currencyService.setExchangeRate(newRate);

                    // تحديث جميع أسعار المنتجات
                    final updatedCount =
                        await _database.updateAllProductPricesByRatio(ratio);

                    if (mounted) {
                      Navigator.pop(parentContext); // إغلاق مؤشر التحميل
                      setState(() {});

                      ScaffoldMessenger.of(parentContext).showSnackBar(
                        SnackBar(
                          content: Text(
                            'تم تحديث سعر الصرف وأسعار $updatedCount منتج',
                          ),
                          backgroundColor: AppColors.success,
                        ),
                      );
                    }
                  } catch (e) {
                    if (mounted) {
                      Navigator.pop(parentContext); // إغلاق مؤشر التحميل
                      ScaffoldMessenger.of(parentContext).showSnackBar(
                        SnackBar(
                          content: Text('حدث خطأ: $e'),
                          backgroundColor: AppColors.error,
                        ),
                      );
                    }
                  }
                }
              } else {
                ScaffoldMessenger.of(parentContext).showSnackBar(
                  const SnackBar(
                    content: Text('الرجاء إدخال قيمة صحيحة'),
                    backgroundColor: AppColors.error,
                  ),
                );
              }
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
      await _backupService.saveLastBackupTime();
      Navigator.pop(context);
      setState(() {}); // تحديث عرض وقت آخر نسخة

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
    // أولاً عرض قائمة النسخ الاحتياطية المتاحة
    final backups = await _backupService.getLocalBackups();

    if (backups.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('لا توجد نسخ احتياطية محفوظة'),
          backgroundColor: AppColors.warning,
        ),
      );
      return;
    }

    final selectedBackup = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('اختر نسخة احتياطية'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: backups.length,
            itemBuilder: (context, index) {
              final backup = backups[index];
              final fileName = backup.path.split('/').last.split('\\').last;
              return ListTile(
                leading: const Icon(Icons.backup),
                title: Text(fileName),
                onTap: () => Navigator.pop(context, backup.path),
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إلغاء'),
          ),
        ],
      ),
    );

    if (selectedBackup == null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('تأكيد الاستعادة'),
        content: const Text(
          'سيتم استبدال جميع البيانات الحالية بالنسخة الاحتياطية.\n\nهذا الإجراء لا يمكن التراجع عنه!\n\nهل أنت متأكد؟',
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

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const AlertDialog(
        content: Row(
          children: [
            CircularProgressIndicator(),
            SizedBox(width: 16),
            Text('جاري استعادة النسخة الاحتياطية...'),
          ],
        ),
      ),
    );

    try {
      await _backupService.restoreFromLocalBackup(selectedBackup);
      Navigator.pop(context);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('تمت استعادة النسخة الاحتياطية بنجاح'),
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
