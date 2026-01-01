/// ═══════════════════════════════════════════════════════════════════════════
/// Print Settings Screen - Redesigned
/// Modern Print Settings Interface
/// ═══════════════════════════════════════════════════════════════════════════
library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/di/injection.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/services/print_settings_service.dart';
import '../../../../core/services/printing/print_settings.dart';

class PrintSettingsScreenRedesign extends StatefulWidget {
  const PrintSettingsScreenRedesign({super.key});

  @override
  State<PrintSettingsScreenRedesign> createState() =>
      _PrintSettingsScreenRedesignState();
}

class _PrintSettingsScreenRedesignState
    extends State<PrintSettingsScreenRedesign> {
  final _printSettingsService = getIt<PrintSettingsService>();
  final _formKey = GlobalKey<FormState>();

  final _companyNameController = TextEditingController();
  final _companyAddressController = TextEditingController();
  final _companyPhoneController = TextEditingController();
  final _companyTaxNumberController = TextEditingController();
  final _footerMessageController = TextEditingController();

  PrintSettings? _settings;
  bool _isLoading = true;
  bool _isSaving = false;

  StreamSubscription<PrintSettings>? _settingsSubscription;

  @override
  void initState() {
    super.initState();
    _loadSettings();
    _setupRealtimeSync();
  }

  @override
  void dispose() {
    _settingsSubscription?.cancel();
    _companyNameController.dispose();
    _companyAddressController.dispose();
    _companyPhoneController.dispose();
    _companyTaxNumberController.dispose();
    _footerMessageController.dispose();
    super.dispose();
  }

  void _setupRealtimeSync() {
    _settingsSubscription =
        _printSettingsService.settingsStream.listen((settings) {
      if (mounted && !_isSaving) {
        setState(() {
          _settings = settings;
          _companyNameController.text = settings.companyName ?? '';
          _companyAddressController.text = settings.companyAddress ?? '';
          _companyPhoneController.text = settings.companyPhone ?? '';
          _companyTaxNumberController.text = settings.companyTaxNumber ?? '';
          _footerMessageController.text = settings.footerMessage ?? '';
        });
      }
    });
  }

  Future<void> _loadSettings() async {
    setState(() => _isLoading = true);
    try {
      final settings = await _printSettingsService.getSettings();
      setState(() {
        _settings = settings;
        _companyNameController.text = settings.companyName ?? '';
        _companyAddressController.text = settings.companyAddress ?? '';
        _companyPhoneController.text = settings.companyPhone ?? '';
        _companyTaxNumberController.text = settings.companyTaxNumber ?? '';
        _footerMessageController.text = settings.footerMessage ?? '';
      });
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _saveSettings() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);
    try {
      final updatedSettings = _settings!.copyWith(
        companyName: _companyNameController.text.trim().isEmpty
            ? null
            : _companyNameController.text.trim(),
        companyAddress: _companyAddressController.text.trim().isEmpty
            ? null
            : _companyAddressController.text.trim(),
        companyPhone: _companyPhoneController.text.trim().isEmpty
            ? null
            : _companyPhoneController.text.trim(),
        companyTaxNumber: _companyTaxNumberController.text.trim().isEmpty
            ? null
            : _companyTaxNumberController.text.trim(),
        footerMessage: _footerMessageController.text.trim().isEmpty
            ? null
            : _footerMessageController.text.trim(),
      );

      await _printSettingsService.saveSettings(updatedSettings);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('تم حفظ الإعدادات بنجاح'),
            backgroundColor: HoorColors.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('خطأ في حفظ الإعدادات: $e'),
            backgroundColor: HoorColors.error,
          ),
        );
      }
    } finally {
      setState(() => _isSaving = false);
    }
  }

  void _updateSetting(PrintSettings Function(PrintSettings) updater) {
    if (_settings != null) {
      setState(() {
        _settings = updater(_settings!);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: HoorColors.background,
      appBar: AppBar(
        backgroundColor: HoorColors.surface,
        title: Text('إعدادات الطباعة', style: HoorTypography.headlineSmall),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.pop(),
        ),
        actions: [
          if (!_isLoading)
            TextButton.icon(
              onPressed: _isSaving ? null : _saveSettings,
              icon: _isSaving
                  ? SizedBox(
                      width: 16.w,
                      height: 16.w,
                      child: const CircularProgressIndicator(
                        strokeWidth: 2,
                        color: HoorColors.primary,
                      ),
                    )
                  : Icon(Icons.save_rounded, color: HoorColors.primary),
              label: Text(
                'حفظ',
                style: HoorTypography.labelLarge.copyWith(
                  color: HoorColors.primary,
                ),
              ),
            ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: HoorColors.primary))
          : Form(
              key: _formKey,
              child: ListView(
                padding: EdgeInsets.all(HoorSpacing.md.w),
                children: [
                  _buildCompanyInfoCard(),
                  SizedBox(height: HoorSpacing.md.h),
                  _buildGeneralSettingsCard(),
                  SizedBox(height: HoorSpacing.md.h),
                  _buildInvoiceContentCard(),
                  SizedBox(height: HoorSpacing.md.h),
                  _buildFooterMessageCard(),
                  SizedBox(height: HoorSpacing.md.h),
                  _buildResetButton(),
                  SizedBox(height: HoorSpacing.xl.h),
                ],
              ),
            ),
    );
  }

  Widget _buildCompanyInfoCard() {
    return _buildSectionCard(
      title: 'معلومات الشركة',
      icon: Icons.business_rounded,
      children: [
        _buildTextField(
          controller: _companyNameController,
          label: 'اسم الشركة',
          icon: Icons.store_rounded,
        ),
        SizedBox(height: HoorSpacing.sm.h),
        _buildTextField(
          controller: _companyAddressController,
          label: 'العنوان',
          icon: Icons.location_on_outlined,
          maxLines: 2,
        ),
        SizedBox(height: HoorSpacing.sm.h),
        _buildTextField(
          controller: _companyPhoneController,
          label: 'رقم الهاتف',
          icon: Icons.phone_outlined,
          keyboardType: TextInputType.phone,
        ),
        SizedBox(height: HoorSpacing.sm.h),
        _buildTextField(
          controller: _companyTaxNumberController,
          label: 'الرقم الضريبي',
          icon: Icons.receipt_long_outlined,
        ),
      ],
    );
  }

  Widget _buildGeneralSettingsCard() {
    if (_settings == null) return const SizedBox();

    return _buildSectionCard(
      title: 'إعدادات الطباعة العامة',
      icon: Icons.print_rounded,
      children: [
        _buildSwitchTile(
          title: 'طباعة تلقائية',
          subtitle: 'طباعة الفاتورة تلقائياً بعد الحفظ',
          value: _settings!.autoPrintAfterSave,
          onChanged: (value) =>
              _updateSetting((s) => s.copyWith(autoPrintAfterSave: value)),
        ),
        Divider(color: HoorColors.border, height: 1),
        _buildSwitchTile(
          title: 'إظهار تفاصيل المنتج',
          subtitle: 'عرض وصف المنتج في الفاتورة',
          value: _settings!.showProductDetails,
          onChanged: (value) =>
              _updateSetting((s) => s.copyWith(showProductDetails: value)),
        ),
        Divider(color: HoorColors.border, height: 1),
        Padding(
          padding: EdgeInsets.all(HoorSpacing.md.w),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('عدد النسخ', style: HoorTypography.bodyMedium),
                  Text(
                    'عدد نسخ الطباعة الافتراضي',
                    style: HoorTypography.labelSmall.copyWith(
                      color: HoorColors.textSecondary,
                    ),
                  ),
                ],
              ),
              Container(
                decoration: BoxDecoration(
                  color: HoorColors.background,
                  borderRadius: BorderRadius.circular(HoorRadius.md),
                  border: Border.all(color: HoorColors.border),
                ),
                child: Row(
                  children: [
                    IconButton(
                      icon: Icon(Icons.remove_rounded,
                          color: HoorColors.textSecondary),
                      onPressed: _settings!.copies > 1
                          ? () => _updateSetting(
                              (s) => s.copyWith(copies: s.copies - 1))
                          : null,
                    ),
                    Container(
                      padding:
                          EdgeInsets.symmetric(horizontal: HoorSpacing.sm.w),
                      child: Text(
                        '${_settings!.copies}',
                        style: HoorTypography.titleMedium.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: Icon(Icons.add_rounded, color: HoorColors.primary),
                      onPressed: _settings!.copies < 5
                          ? () => _updateSetting(
                              (s) => s.copyWith(copies: s.copies + 1))
                          : null,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildInvoiceContentCard() {
    if (_settings == null) return const SizedBox();

    return _buildSectionCard(
      title: 'محتوى الفاتورة',
      icon: Icons.receipt_outlined,
      children: [
        _buildSwitchTile(
          title: 'إظهار الشعار',
          subtitle: 'عرض شعار الشركة في الفاتورة',
          value: _settings!.showLogo,
          onChanged: (value) =>
              _updateSetting((s) => s.copyWith(showLogo: value)),
        ),
        Divider(color: HoorColors.border, height: 1),
        _buildSwitchTile(
          title: 'إظهار الباركود',
          subtitle: 'عرض باركود المنتجات في الفاتورة',
          value: _settings!.showBarcode,
          onChanged: (value) =>
              _updateSetting((s) => s.copyWith(showBarcode: value)),
        ),
        Divider(color: HoorColors.border, height: 1),
        _buildSwitchTile(
          title: 'إظهار QR Code',
          subtitle: 'عرض رمز باركود للفاتورة',
          value: _settings!.showInvoiceBarcode,
          onChanged: (value) =>
              _updateSetting((s) => s.copyWith(showInvoiceBarcode: value)),
        ),
        Divider(color: HoorColors.border, height: 1),
        _buildSwitchTile(
          title: 'إظهار رقم العميل',
          subtitle: 'عرض معلومات العميل في الفاتورة',
          value: _settings!.showCustomerInfo,
          onChanged: (value) =>
              _updateSetting((s) => s.copyWith(showCustomerInfo: value)),
        ),
      ],
    );
  }

  Widget _buildFooterMessageCard() {
    return _buildSectionCard(
      title: 'رسالة التذييل',
      icon: Icons.message_outlined,
      children: [
        Padding(
          padding: EdgeInsets.all(HoorSpacing.md.w),
          child: _buildTextField(
            controller: _footerMessageController,
            label: 'رسالة في أسفل الفاتورة',
            icon: Icons.edit_note_rounded,
            maxLines: 3,
            hint: 'مثال: شكراً لتعاملكم معنا',
          ),
        ),
      ],
    );
  }

  Widget _buildResetButton() {
    return OutlinedButton.icon(
      onPressed: _resetToDefaults,
      icon: Icon(Icons.restart_alt_rounded, color: HoorColors.error),
      label: Text(
        'إعادة التعيين للافتراضي',
        style: HoorTypography.labelLarge.copyWith(color: HoorColors.error),
      ),
      style: OutlinedButton.styleFrom(
        side: BorderSide(color: HoorColors.error),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(HoorRadius.md),
        ),
        padding: EdgeInsets.symmetric(vertical: HoorSpacing.md.h),
      ),
    );
  }

  Widget _buildSectionCard({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: HoorColors.surface,
        borderRadius: BorderRadius.circular(HoorRadius.lg),
        border: Border.all(color: HoorColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.all(HoorSpacing.md.w),
            child: Row(
              children: [
                Icon(icon, color: HoorColors.primary, size: HoorIconSize.sm),
                SizedBox(width: HoorSpacing.xs.w),
                Text(
                  title,
                  style: HoorTypography.titleMedium.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          Divider(color: HoorColors.border, height: 1),
          ...children,
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    int maxLines = 1,
    TextInputType? keyboardType,
    String? hint,
  }) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      keyboardType: keyboardType,
      style: HoorTypography.bodyMedium,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        labelStyle: HoorTypography.bodySmall.copyWith(
          color: HoorColors.textSecondary,
        ),
        hintStyle: HoorTypography.bodySmall.copyWith(
          color: HoorColors.textSecondary.withValues(alpha: 0.5),
        ),
        prefixIcon: Icon(icon, color: HoorColors.textSecondary, size: 20),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(HoorRadius.md),
          borderSide: BorderSide(color: HoorColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(HoorRadius.md),
          borderSide: BorderSide(color: HoorColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(HoorRadius.md),
          borderSide: BorderSide(color: HoorColors.primary),
        ),
        filled: true,
        fillColor: HoorColors.background,
      ),
    );
  }

  Widget _buildSwitchTile({
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return SwitchListTile(
      title: Text(title, style: HoorTypography.bodyMedium),
      subtitle: Text(
        subtitle,
        style: HoorTypography.labelSmall.copyWith(
          color: HoorColors.textSecondary,
        ),
      ),
      value: value,
      activeTrackColor: HoorColors.primary,
      onChanged: onChanged,
    );
  }

  Future<void> _resetToDefaults() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: HoorColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(HoorRadius.lg),
        ),
        title: Text('إعادة التعيين', style: HoorTypography.titleLarge),
        content: Text(
          'سيتم إعادة جميع الإعدادات للقيم الافتراضية.\nهل أنت متأكد؟',
          style: HoorTypography.bodyMedium,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('إلغاء', style: HoorTypography.labelLarge),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: HoorColors.error,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(HoorRadius.sm),
              ),
            ),
            onPressed: () => Navigator.pop(context, true),
            child: Text('إعادة التعيين',
                style: HoorTypography.labelLarge.copyWith(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() {
      _settings = PrintSettings.defaultSettings;
      _companyNameController.clear();
      _companyAddressController.clear();
      _companyPhoneController.clear();
      _companyTaxNumberController.clear();
      _footerMessageController.clear();
    });

    await _saveSettings();
  }
}
