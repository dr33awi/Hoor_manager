import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/redesign/design_system.dart';
import '../../../../core/di/injection.dart';
import '../../../../core/services/backup_service.dart';
import '../../../../core/services/sync_service.dart';
import '../../../../core/services/currency_service.dart';
import '../../../../data/database/app_database.dart';

/// ═══════════════════════════════════════════════════════════════════════════
/// Settings Screen - Modern Redesign
/// Professional Settings & Configuration Interface
/// ═══════════════════════════════════════════════════════════════════════════

class SettingsScreenRedesign extends ConsumerStatefulWidget {
  const SettingsScreenRedesign({super.key});

  @override
  ConsumerState<SettingsScreenRedesign> createState() =>
      _SettingsScreenRedesignState();
}

class _SettingsScreenRedesignState
    extends ConsumerState<SettingsScreenRedesign> {
  final _backupService = getIt<BackupService>();
  final _syncService = getIt<SyncService>();
  final _currencyService = getIt<CurrencyService>();
  final _database = getIt<AppDatabase>();

  bool _autoBackup = true;
  bool _autoPrint = false;
  String _invoicePrefix = 'INV';
  bool _isSyncing = false;
  bool _isBackingUp = false;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final autoBackup = await _database.getSetting('auto_backup');
    final autoPrint = await _database.getSetting('auto_print');
    final invoicePrefix = await _database.getSetting('invoice_prefix');

    if (mounted) {
      setState(() {
        _autoBackup = autoBackup == 'true';
        _autoPrint = autoPrint == 'true';
        _invoicePrefix = invoicePrefix ?? 'INV';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: HoorColors.background,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            _buildHeader(context),

            // Content
            Expanded(
              child: ListView(
                padding: EdgeInsets.symmetric(horizontal: HoorSpacing.lg.w),
                children: [
                  // App Info Card
                  _AppInfoCard(),
                  SizedBox(height: HoorSpacing.lg.h),

                  // Currency & Exchange
                  _SettingsSection(
                    title: 'العملة وسعر الصرف',
                    icon: Icons.currency_exchange_rounded,
                    children: [
                      _SettingsTile(
                        title: 'العملة الرئيسية',
                        subtitle: 'الليرة السورية (ل.س)',
                        icon: Icons.money_rounded,
                        trailing: HoorBadge(
                          label: 'ل.س',
                          color: HoorColors.primary,
                          size: HoorBadgeSize.small,
                        ),
                      ),
                      _SettingsTile(
                        title: 'سعر صرف الدولار',
                        subtitle:
                            '1 \$ = ${_currencyService.exchangeRate.toStringAsFixed(0)} ل.س',
                        icon: Icons.attach_money_rounded,
                        showArrow: true,
                        onTap: _showExchangeRateDialog,
                      ),
                      _SettingsSwitch(
                        title: 'الأسعار المدخلة بالدولار',
                        subtitle: 'تحويل تلقائي للأسعار عند التغيير',
                        icon: Icons.swap_horiz_rounded,
                        value: _currencyService.basePriceInUsd,
                        onChanged: (value) async {
                          await _currencyService.setBasePriceInUsd(value);
                          setState(() {});
                        },
                      ),
                    ],
                  ),
                  SizedBox(height: HoorSpacing.lg.h),

                  // Sync & Backup
                  _SettingsSection(
                    title: 'المزامنة والنسخ الاحتياطي',
                    icon: Icons.cloud_sync_rounded,
                    children: [
                      _SettingsTile(
                        title: 'المزامنة السحابية',
                        subtitle: 'متصل',
                        icon: Icons.cloud_done_rounded,
                        iconColor: HoorColors.success,
                        trailing: _isSyncing
                            ? SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: HoorColors.primary,
                                ),
                              )
                            : _ActionButton(
                                label: 'مزامنة',
                                onTap: _syncNow,
                              ),
                      ),
                      _SettingsTile(
                        title: 'النسخ الاحتياطي',
                        subtitle: 'آخر نسخة: اليوم',
                        icon: Icons.backup_rounded,
                        trailing: _isBackingUp
                            ? SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: HoorColors.primary,
                                ),
                              )
                            : _ActionButton(
                                label: 'نسخ',
                                onTap: _createBackup,
                              ),
                      ),
                      _SettingsSwitch(
                        title: 'نسخ احتياطي تلقائي',
                        subtitle: 'نسخ يومي للبيانات',
                        icon: Icons.schedule_rounded,
                        value: _autoBackup,
                        onChanged: (value) async {
                          await _database.setSetting(
                              'auto_backup', value.toString());
                          setState(() => _autoBackup = value);
                        },
                      ),
                      _SettingsTile(
                        title: 'استعادة نسخة احتياطية',
                        subtitle: 'استعادة البيانات من نسخة سابقة',
                        icon: Icons.restore_rounded,
                        showArrow: true,
                        onTap: _restoreBackup,
                      ),
                    ],
                  ),
                  SizedBox(height: HoorSpacing.lg.h),

                  // Invoice Settings
                  _SettingsSection(
                    title: 'إعدادات الفواتير',
                    icon: Icons.receipt_long_rounded,
                    children: [
                      _SettingsTile(
                        title: 'بادئة رقم الفاتورة',
                        subtitle: _invoicePrefix,
                        icon: Icons.tag_rounded,
                        showArrow: true,
                        onTap: _showInvoicePrefixDialog,
                      ),
                      _SettingsSwitch(
                        title: 'طباعة تلقائية',
                        subtitle: 'طباعة الفاتورة بعد الحفظ',
                        icon: Icons.print_rounded,
                        value: _autoPrint,
                        onChanged: (value) async {
                          await _database.setSetting(
                              'auto_print', value.toString());
                          setState(() => _autoPrint = value);
                        },
                      ),
                      _SettingsTile(
                        title: 'إعدادات الطباعة',
                        subtitle: 'تخصيص شكل الفاتورة المطبوعة',
                        icon: Icons.settings_rounded,
                        showArrow: true,
                        onTap: () => context.push('/settings/print'),
                      ),
                    ],
                  ),
                  SizedBox(height: HoorSpacing.lg.h),

                  // App Settings
                  _SettingsSection(
                    title: 'التطبيق',
                    icon: Icons.apps_rounded,
                    children: [
                      _SettingsTile(
                        title: 'اللغة',
                        subtitle: 'العربية',
                        icon: Icons.language_rounded,
                        showArrow: true,
                      ),
                      _SettingsTile(
                        title: 'الأمان والخصوصية',
                        subtitle: 'كلمة المرور والحماية',
                        icon: Icons.security_rounded,
                        showArrow: true,
                      ),
                      _SettingsTile(
                        title: 'حول التطبيق',
                        subtitle: 'الإصدار 1.0.0',
                        icon: Icons.info_outline_rounded,
                        showArrow: true,
                      ),
                    ],
                  ),
                  SizedBox(height: HoorSpacing.xxl.h),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(HoorSpacing.lg.w),
      child: Row(
        children: [
          // Back Button
          _IconButton(
            icon: Icons.arrow_forward_ios_rounded,
            onTap: () => context.pop(),
          ),
          SizedBox(width: HoorSpacing.md.w),

          // Title
          Expanded(
            child: Text(
              'الإعدادات',
              style: HoorTypography.headlineSmall.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showExchangeRateDialog() {
    final controller = TextEditingController(
      text: _currencyService.exchangeRate.toStringAsFixed(0),
    );

    HoorBottomSheet.show(
      context,
      title: 'سعر صرف الدولار',
      showCloseButton: true,
      child: Padding(
        padding: EdgeInsets.all(HoorSpacing.lg.w),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            HoorTextField(
              controller: controller,
              label: 'سعر الصرف',
              hint: 'أدخل سعر الصرف',
              prefixIcon: Icons.attach_money_rounded,
              keyboardType: TextInputType.number,
            ),
            SizedBox(height: HoorSpacing.lg.h),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () async {
                  final rate = double.tryParse(controller.text);
                  if (rate != null && rate > 0) {
                    await _currencyService.setExchangeRate(rate);
                    if (mounted) {
                      Navigator.pop(context);
                      setState(() {});
                    }
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: HoorColors.primary,
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.all(HoorSpacing.md.w),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(HoorRadius.md),
                  ),
                ),
                child: const Text('حفظ'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showInvoicePrefixDialog() {
    final controller = TextEditingController(text: _invoicePrefix);

    HoorBottomSheet.show(
      context,
      title: 'بادئة رقم الفاتورة',
      showCloseButton: true,
      child: Padding(
        padding: EdgeInsets.all(HoorSpacing.lg.w),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            HoorTextField(
              controller: controller,
              label: 'البادئة',
              hint: 'مثال: INV',
              prefixIcon: Icons.tag_rounded,
            ),
            SizedBox(height: HoorSpacing.lg.h),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () async {
                  if (controller.text.isNotEmpty) {
                    await _database.setSetting(
                        'invoice_prefix', controller.text);
                    if (mounted) {
                      Navigator.pop(context);
                      setState(() => _invoicePrefix = controller.text);
                    }
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: HoorColors.primary,
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.all(HoorSpacing.md.w),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(HoorRadius.md),
                  ),
                ),
                child: const Text('حفظ'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _syncNow() async {
    setState(() => _isSyncing = true);
    try {
      await _syncService.syncAll();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('تمت المزامنة بنجاح'),
            backgroundColor: HoorColors.success,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(HoorRadius.md),
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('خطأ في المزامنة: $e'),
            backgroundColor: HoorColors.error,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(HoorRadius.md),
            ),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSyncing = false);
      }
    }
  }

  Future<void> _createBackup() async {
    setState(() => _isBackingUp = true);
    try {
      await _backupService.createLocalBackup();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('تم إنشاء النسخة الاحتياطية بنجاح'),
            backgroundColor: HoorColors.success,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(HoorRadius.md),
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('خطأ في إنشاء النسخة الاحتياطية: $e'),
            backgroundColor: HoorColors.error,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(HoorRadius.md),
            ),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isBackingUp = false);
      }
    }
  }

  Future<void> _restoreBackup() async {
    final confirmed = await HoorDialog.showConfirm(
      context,
      title: 'استعادة النسخة الاحتياطية',
      message: 'سيتم استبدال جميع البيانات الحالية. هل تريد المتابعة؟',
      confirmLabel: 'استعادة',
      cancelLabel: 'إلغاء',
      isDestructive: true,
    );

    if (confirmed == true) {
      try {
        // Note: In a real implementation, you'd use file_picker to select a backup file
        // For now, we'll restore from the latest cloud backup
        await _backupService.restoreFromCloud();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('تمت الاستعادة بنجاح'),
              backgroundColor: HoorColors.success,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(HoorRadius.md),
              ),
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('خطأ في الاستعادة: $e'),
              backgroundColor: HoorColors.error,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(HoorRadius.md),
              ),
            ),
          );
        }
      }
    }
  }
}

/// ═══════════════════════════════════════════════════════════════════════════
/// Supporting Widgets
/// ═══════════════════════════════════════════════════════════════════════════

class _IconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _IconButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: HoorColors.surface,
      borderRadius: BorderRadius.circular(HoorRadius.md),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(HoorRadius.md),
        child: Container(
          padding: EdgeInsets.all(HoorSpacing.sm.w),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(HoorRadius.md),
            border: Border.all(color: HoorColors.border),
          ),
          child: Icon(icon,
              size: HoorIconSize.md, color: HoorColors.textSecondary),
        ),
      ),
    );
  }
}

class _AppInfoCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(HoorSpacing.lg.w),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            HoorColors.primary,
            HoorColors.primary.withValues(alpha: 0.85),
          ],
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
        ),
        borderRadius: BorderRadius.circular(HoorRadius.xl),
        boxShadow: [
          BoxShadow(
            color: HoorColors.primary.withValues(alpha: 0.2),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          // App Icon
          Container(
            padding: EdgeInsets.all(HoorSpacing.md.w),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(HoorRadius.lg),
            ),
            child: Icon(
              Icons.business_center_rounded,
              color: Colors.white,
              size: HoorIconSize.xxl,
            ),
          ),
          SizedBox(width: HoorSpacing.lg.w),

          // App Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Hoor Manager',
                  style: HoorTypography.titleLarge.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: HoorSpacing.xxs.h),
                Text(
                  'نظام إدارة الأعمال المتكامل',
                  style: HoorTypography.bodySmall.copyWith(
                    color: Colors.white.withValues(alpha: 0.8),
                  ),
                ),
                SizedBox(height: HoorSpacing.sm.h),
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: HoorSpacing.sm.w,
                    vertical: HoorSpacing.xxs.h,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(HoorRadius.full),
                  ),
                  child: Text(
                    'الإصدار 1.0.0',
                    style: HoorTypography.labelSmall.copyWith(
                      color: Colors.white,
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
}

class _SettingsSection extends StatelessWidget {
  final String title;
  final IconData icon;
  final List<Widget> children;

  const _SettingsSection({
    required this.title,
    required this.icon,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        HoorDecoratedHeader(
          title: title,
          icon: icon,
        ),
        SizedBox(height: HoorSpacing.md.h),
        Container(
          decoration: BoxDecoration(
            color: HoorColors.surface,
            borderRadius: BorderRadius.circular(HoorRadius.lg),
            border: Border.all(color: HoorColors.border.withValues(alpha: 0.5)),
          ),
          child: Column(
            children: children.asMap().entries.map((entry) {
              final isLast = entry.key == children.length - 1;
              return Column(
                children: [
                  entry.value,
                  if (!isLast)
                    Divider(
                      height: 1,
                      indent: HoorSpacing.lg.w,
                      endIndent: HoorSpacing.lg.w,
                      color: HoorColors.border.withValues(alpha: 0.5),
                    ),
                ],
              );
            }).toList(),
          ),
        ),
      ],
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color? iconColor;
  final Widget? trailing;
  final bool showArrow;
  final VoidCallback? onTap;

  const _SettingsTile({
    required this.title,
    required this.subtitle,
    required this.icon,
    this.iconColor,
    this.trailing,
    this.showArrow = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: EdgeInsets.all(HoorSpacing.md.w),
          child: Row(
            children: [
              Container(
                padding: EdgeInsets.all(HoorSpacing.sm.w),
                decoration: BoxDecoration(
                  color:
                      (iconColor ?? HoorColors.primary).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(HoorRadius.md),
                ),
                child: Icon(
                  icon,
                  size: HoorIconSize.md,
                  color: iconColor ?? HoorColors.primary,
                ),
              ),
              SizedBox(width: HoorSpacing.md.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: HoorTypography.titleSmall.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    SizedBox(height: 2.h),
                    Text(
                      subtitle,
                      style: HoorTypography.bodySmall.copyWith(
                        color: HoorColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              if (trailing != null) trailing!,
              if (showArrow)
                Icon(
                  Icons.chevron_left_rounded,
                  color: HoorColors.textTertiary,
                  size: HoorIconSize.md,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SettingsSwitch extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _SettingsSwitch({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.all(HoorSpacing.md.w),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(HoorSpacing.sm.w),
            decoration: BoxDecoration(
              color: HoorColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(HoorRadius.md),
            ),
            child: Icon(
              icon,
              size: HoorIconSize.md,
              color: HoorColors.primary,
            ),
          ),
          SizedBox(width: HoorSpacing.md.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: HoorTypography.titleSmall.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                ),
                SizedBox(height: 2.h),
                Text(
                  subtitle,
                  style: HoorTypography.bodySmall.copyWith(
                    color: HoorColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeTrackColor: HoorColors.primary,
          ),
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _ActionButton({
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: HoorColors.primary,
      borderRadius: BorderRadius.circular(HoorRadius.md),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(HoorRadius.md),
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: HoorSpacing.md.w,
            vertical: HoorSpacing.xs.h,
          ),
          child: Text(
            label,
            style: HoorTypography.labelMedium.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }
}
