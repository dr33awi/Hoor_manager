// ═══════════════════════════════════════════════════════════════════════════
// Print Settings Screen Pro - Professional Design System
// Modern Print Settings Interface with Printer Management
// ═══════════════════════════════════════════════════════════════════════════

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../core/theme/design_tokens.dart';
import '../../core/providers/app_providers.dart';
import '../../core/widgets/widgets.dart';
import '../../core/services/printing/print_settings.dart';
import '../../core/services/printing/invoice_pdf_generator.dart';

class PrintSettingsScreenPro extends ConsumerStatefulWidget {
  const PrintSettingsScreenPro({super.key});

  @override
  ConsumerState<PrintSettingsScreenPro> createState() =>
      _PrintSettingsScreenProState();
}

class _PrintSettingsScreenProState
    extends ConsumerState<PrintSettingsScreenPro> {
  final _formKey = GlobalKey<FormState>();

  final _companyNameController = TextEditingController();
  final _companyAddressController = TextEditingController();
  final _companyPhoneController = TextEditingController();
  final _companyTaxNumberController = TextEditingController();
  final _footerMessageController = TextEditingController();

  PrintSettings? _settings;
  bool _isLoading = true;
  bool _isSaving = false;

  // Paper size options
  final List<Map<String, dynamic>> _paperSizes = [
    {'value': '58mm', 'label': '58mm (صغير)', 'width': 58},
    {'value': '80mm', 'label': '80mm (قياسي)', 'width': 80},
  ];

  // Printer connection types
  String _selectedConnectionType = 'bluetooth';

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  @override
  void dispose() {
    _companyNameController.dispose();
    _companyAddressController.dispose();
    _companyPhoneController.dispose();
    _companyTaxNumberController.dispose();
    _footerMessageController.dispose();
    super.dispose();
  }

  Future<void> _loadSettings() async {
    setState(() => _isLoading = true);
    try {
      final printSettingsService = ref.read(printSettingsServiceProvider);
      final settings = await printSettingsService.getSettings();
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
      final printSettingsService = ref.read(printSettingsServiceProvider);
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

      await printSettingsService.saveSettings(updatedSettings);

      if (mounted) {
        ProSnackbar.saved(context);
      }
    } catch (e) {
      if (mounted) {
        ProSnackbar.showError(context, e);
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
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: _isLoading
                  ? ProLoadingState.withMessage(
                      message: 'جاري تحميل الإعدادات...')
                  : Form(
                      key: _formKey,
                      child: ListView(
                        padding: EdgeInsets.all(AppSpacing.md),
                        children: [
                          _buildPrinterConnectionCard(),
                          SizedBox(height: AppSpacing.md),
                          _buildPaperSettingsCard(),
                          SizedBox(height: AppSpacing.md),
                          _buildCompanyInfoCard(),
                          SizedBox(height: AppSpacing.md),
                          _buildGeneralSettingsCard(),
                          SizedBox(height: AppSpacing.md),
                          _buildInvoiceContentCard(),
                          SizedBox(height: AppSpacing.md),
                          _buildFooterMessageCard(),
                          SizedBox(height: AppSpacing.md),
                          _buildTestPrintButton(),
                          SizedBox(height: AppSpacing.sm),
                          _buildResetButton(),
                          SizedBox(height: AppSpacing.xl),
                        ],
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return ProHeader(
      title: 'إعدادات الطباعة',
      subtitle: 'إعداد الطابعة وقالب الفاتورة',
      actions: [
        if (!_isLoading)
          TextButton.icon(
            onPressed: _isSaving ? null : _saveSettings,
            icon: _isSaving
                ? SizedBox(
                    width: 16.w,
                    height: 16.w,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppColors.primary,
                    ),
                  )
                : Icon(Icons.save_rounded, color: AppColors.primary),
            label: Text(
              'حفظ',
              style: AppTypography.labelLarge.copyWith(
                color: AppColors.primary,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildPrinterConnectionCard() {
    return _buildSectionCard(
      title: 'اتصال الطابعة',
      icon: Icons.print_rounded,
      iconColor: AppColors.secondary,
      children: [
        Padding(
          padding: EdgeInsets.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('نوع الاتصال', style: AppTypography.labelLarge),
              SizedBox(height: AppSpacing.sm),
              Row(
                children: [
                  _buildConnectionTypeChip(
                    icon: Icons.bluetooth,
                    label: 'Bluetooth',
                    value: 'bluetooth',
                  ),
                  SizedBox(width: AppSpacing.sm),
                  _buildConnectionTypeChip(
                    icon: Icons.usb,
                    label: 'USB',
                    value: 'usb',
                  ),
                  SizedBox(width: AppSpacing.sm),
                  _buildConnectionTypeChip(
                    icon: Icons.wifi,
                    label: 'WiFi',
                    value: 'wifi',
                  ),
                ],
              ),
              SizedBox(height: AppSpacing.lg),

              // Search for printers button
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: _searchPrinters,
                  icon: const Icon(Icons.search),
                  label: const Text('البحث عن الطابعات'),
                  style: OutlinedButton.styleFrom(
                    padding: EdgeInsets.all(AppSpacing.md),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppRadius.md),
                    ),
                  ),
                ),
              ),
              SizedBox(height: AppSpacing.md),

              // Connected printer info
              Container(
                padding: EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: AppColors.surfaceMuted,
                  borderRadius: BorderRadius.circular(AppRadius.md),
                  border: Border.all(color: AppColors.border),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: EdgeInsets.all(AppSpacing.sm),
                      decoration: BoxDecoration(
                        color: AppColors.success.soft,
                        borderRadius: BorderRadius.circular(AppRadius.sm),
                      ),
                      child: Icon(Icons.print,
                          color: AppColors.success, size: 20.sp),
                    ),
                    SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'لم يتم توصيل طابعة',
                            style: AppTypography.bodyMedium.copyWith(
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          Text(
                            'اضغط على البحث لاكتشاف الطابعات',
                            style: AppTypography.bodySmall.copyWith(
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: AppColors.textTertiary,
                        shape: BoxShape.circle,
                      ),
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

  Widget _buildConnectionTypeChip({
    required IconData icon,
    required String label,
    required String value,
  }) {
    final isSelected = _selectedConnectionType == value;
    return Expanded(
      child: InkWell(
        onTap: () => setState(() => _selectedConnectionType = value),
        borderRadius: BorderRadius.circular(AppRadius.md),
        child: Container(
          padding: EdgeInsets.all(AppSpacing.sm),
          decoration: BoxDecoration(
            color: isSelected
                ? AppColors.secondary.soft
                : AppColors.surfaceMuted,
            borderRadius: BorderRadius.circular(AppRadius.md),
            border: Border.all(
              color: isSelected ? AppColors.secondary : AppColors.border,
            ),
          ),
          child: Column(
            children: [
              Icon(
                icon,
                color:
                    isSelected ? AppColors.secondary : AppColors.textSecondary,
                size: 24.sp,
              ),
              SizedBox(height: 4.h),
              Text(
                label,
                style: AppTypography.labelSmall.copyWith(
                  color: isSelected
                      ? AppColors.secondary
                      : AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPaperSettingsCard() {
    if (_settings == null) return const SizedBox();

    return _buildSectionCard(
      title: 'إعدادات الورق',
      icon: Icons.straighten_rounded,
      iconColor: AppColors.warning,
      children: [
        Padding(
          padding: EdgeInsets.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('حجم الورق', style: AppTypography.labelLarge),
              SizedBox(height: AppSpacing.sm),
              Row(
                children: _paperSizes.map((size) {
                  final isSelected =
                      _settings!.defaultSize.index == _paperSizes.indexOf(size);
                  return Expanded(
                    child: Padding(
                      padding: EdgeInsets.only(
                        right: size != _paperSizes.last ? AppSpacing.sm : 0,
                      ),
                      child: InkWell(
                        onTap: () => _updateSetting((s) => s.copyWith(
                            defaultSize: InvoicePrintSize
                                .values[_paperSizes.indexOf(size)])),
                        borderRadius: BorderRadius.circular(AppRadius.md),
                        child: Container(
                          padding: EdgeInsets.all(AppSpacing.md),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? AppColors.primary.soft
                                : AppColors.surfaceMuted,
                            borderRadius: BorderRadius.circular(AppRadius.md),
                            border: Border.all(
                              color: isSelected
                                  ? AppColors.primary
                                  : AppColors.border,
                              width: isSelected ? 2 : 1,
                            ),
                          ),
                          child: Column(
                            children: [
                              Icon(
                                Icons.receipt_long,
                                color: isSelected
                                    ? AppColors.primary
                                    : AppColors.textSecondary,
                              ),
                              SizedBox(height: AppSpacing.xs),
                              Text(
                                size['label'],
                                style: AppTypography.labelMedium.copyWith(
                                  color: isSelected
                                      ? AppColors.primary
                                      : AppColors.textSecondary,
                                  fontWeight: isSelected
                                      ? FontWeight.w600
                                      : FontWeight.normal,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCompanyInfoCard() {
    return _buildSectionCard(
      title: 'معلومات الشركة',
      icon: Icons.business_rounded,
      iconColor: AppColors.info,
      children: [
        Padding(
          padding: EdgeInsets.all(AppSpacing.md),
          child: Column(
            children: [
              _buildTextField(
                controller: _companyNameController,
                label: 'اسم الشركة',
                icon: Icons.store_rounded,
              ),
              SizedBox(height: AppSpacing.sm),
              _buildTextField(
                controller: _companyAddressController,
                label: 'العنوان',
                icon: Icons.location_on_outlined,
                maxLines: 2,
              ),
              SizedBox(height: AppSpacing.sm),
              _buildTextField(
                controller: _companyPhoneController,
                label: 'رقم الهاتف',
                icon: Icons.phone_outlined,
                keyboardType: TextInputType.phone,
              ),
              SizedBox(height: AppSpacing.sm),
              _buildTextField(
                controller: _companyTaxNumberController,
                label: 'الرقم الضريبي',
                icon: Icons.receipt_long_outlined,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildGeneralSettingsCard() {
    if (_settings == null) return const SizedBox();

    return _buildSectionCard(
      title: 'إعدادات الطباعة العامة',
      icon: Icons.settings_rounded,
      iconColor: AppColors.primary,
      children: [
        _buildSwitchTile(
          title: 'طباعة تلقائية',
          subtitle: 'طباعة الفاتورة تلقائياً بعد الحفظ',
          value: _settings!.autoPrintAfterSave,
          onChanged: (value) =>
              _updateSetting((s) => s.copyWith(autoPrintAfterSave: value)),
        ),
        Divider(color: AppColors.border, height: 1),
        _buildSwitchTile(
          title: 'إظهار تفاصيل المنتج',
          subtitle: 'عرض وصف المنتج في الفاتورة',
          value: _settings!.showProductDetails,
          onChanged: (value) =>
              _updateSetting((s) => s.copyWith(showProductDetails: value)),
        ),
        Divider(color: AppColors.border, height: 1),
        Padding(
          padding: EdgeInsets.all(AppSpacing.md),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('عدد النسخ', style: AppTypography.bodyMedium),
                  Text(
                    'عدد نسخ الطباعة الافتراضي',
                    style: AppTypography.labelSmall.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
              Container(
                decoration: BoxDecoration(
                  color: AppColors.surfaceMuted,
                  borderRadius: BorderRadius.circular(AppRadius.md),
                  border: Border.all(color: AppColors.border),
                ),
                child: Row(
                  children: [
                    IconButton(
                      icon: Icon(Icons.remove_rounded,
                          color: AppColors.textSecondary),
                      onPressed: _settings!.copies > 1
                          ? () => _updateSetting(
                              (s) => s.copyWith(copies: s.copies - 1))
                          : null,
                    ),
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: AppSpacing.sm),
                      child: Text(
                        '${_settings!.copies}',
                        style: AppTypography.titleMedium.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: Icon(Icons.add_rounded, color: AppColors.primary),
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
      iconColor: AppColors.success,
      children: [
        _buildSwitchTile(
          title: 'إظهار الشعار',
          subtitle: 'عرض شعار الشركة في الفاتورة',
          value: _settings!.showLogo,
          onChanged: (value) =>
              _updateSetting((s) => s.copyWith(showLogo: value)),
        ),
        Divider(color: AppColors.border, height: 1),
        _buildSwitchTile(
          title: 'إظهار الباركود',
          subtitle: 'عرض باركود المنتجات في الفاتورة',
          value: _settings!.showBarcode,
          onChanged: (value) =>
              _updateSetting((s) => s.copyWith(showBarcode: value)),
        ),
        Divider(color: AppColors.border, height: 1),
        _buildSwitchTile(
          title: 'إظهار QR Code',
          subtitle: 'عرض رمز QR للفاتورة',
          value: _settings!.showInvoiceBarcode,
          onChanged: (value) =>
              _updateSetting((s) => s.copyWith(showInvoiceBarcode: value)),
        ),
        Divider(color: AppColors.border, height: 1),
        _buildSwitchTile(
          title: 'إظهار معلومات العميل',
          subtitle: 'عرض اسم ورقم العميل في الفاتورة',
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
      iconColor: AppColors.warning,
      children: [
        Padding(
          padding: EdgeInsets.all(AppSpacing.md),
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

  Widget _buildTestPrintButton() {
    return ElevatedButton.icon(
      onPressed: _testPrint,
      icon: const Icon(Icons.print_rounded, color: Colors.white),
      label: Text(
        'طباعة تجريبية',
        style: AppTypography.labelLarge.copyWith(color: Colors.white),
      ),
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.primary,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
        padding: EdgeInsets.symmetric(vertical: AppSpacing.md),
      ),
    );
  }

  Widget _buildResetButton() {
    return OutlinedButton.icon(
      onPressed: _resetToDefaults,
      icon: Icon(Icons.restart_alt_rounded, color: AppColors.error),
      label: Text(
        'إعادة التعيين للافتراضي',
        style: AppTypography.labelLarge.copyWith(color: AppColors.error),
      ),
      style: OutlinedButton.styleFrom(
        side: BorderSide(color: AppColors.error),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
        padding: EdgeInsets.symmetric(vertical: AppSpacing.md),
      ),
    );
  }

  Widget _buildSectionCard({
    required String title,
    required IconData icon,
    required Color iconColor,
    required List<Widget> children,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.border),
        boxShadow: AppShadows.xs,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.all(AppSpacing.md),
            child: Row(
              children: [
                Container(
                  padding: EdgeInsets.all(AppSpacing.sm),
                  decoration: BoxDecoration(
                    color: iconColor.soft,
                    borderRadius: BorderRadius.circular(AppRadius.md),
                  ),
                  child: Icon(icon, color: iconColor, size: 20.sp),
                ),
                SizedBox(width: AppSpacing.sm),
                Text(
                  title,
                  style: AppTypography.titleMedium.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          Divider(color: AppColors.border, height: 1),
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
      style: AppTypography.bodyMedium,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        labelStyle: AppTypography.bodySmall.copyWith(
          color: AppColors.textSecondary,
        ),
        hintStyle: AppTypography.bodySmall.copyWith(
          color: AppColors.textSecondary.borderStrong,
        ),
        prefixIcon: Icon(icon, color: AppColors.textSecondary, size: 20.sp),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: BorderSide(color: AppColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: BorderSide(color: AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: BorderSide(color: AppColors.primary),
        ),
        filled: true,
        fillColor: AppColors.surfaceMuted,
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
      title: Text(title, style: AppTypography.bodyMedium),
      subtitle: Text(
        subtitle,
        style: AppTypography.labelSmall.copyWith(
          color: AppColors.textSecondary,
        ),
      ),
      value: value,
      activeTrackColor: AppColors.primary,
      onChanged: onChanged,
    );
  }

  void _searchPrinters() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.xl)),
      ),
      builder: (context) => Container(
        padding: EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40.w,
              height: 4.h,
              decoration: BoxDecoration(
                color: AppColors.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            SizedBox(height: AppSpacing.lg),
            Row(
              children: [
                Icon(Icons.bluetooth_searching,
                    color: AppColors.secondary, size: 24.sp),
                SizedBox(width: AppSpacing.sm),
                Text('البحث عن الطابعات...', style: AppTypography.titleMedium),
              ],
            ),
            SizedBox(height: AppSpacing.xl),
            const CircularProgressIndicator(),
            SizedBox(height: AppSpacing.xl),
            Text(
              'جاري البحث عن الطابعات المتاحة',
              style: AppTypography.bodyMedium.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            SizedBox(height: AppSpacing.lg),
            // Placeholder for found printers
            Container(
              padding: EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: AppColors.surfaceMuted,
                borderRadius: BorderRadius.circular(AppRadius.md),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline,
                      color: AppColors.textSecondary, size: 20.sp),
                  SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Text(
                      'تأكد من تشغيل الطابعة وتفعيل ${_selectedConnectionType == 'bluetooth' ? 'البلوتوث' : _selectedConnectionType == 'wifi' ? 'WiFi' : 'USB'}',
                      style: AppTypography.bodySmall.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: AppSpacing.lg),
          ],
        ),
      ),
    );
  }

  void _testPrint() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.lg),
        ),
        title: Row(
          children: [
            Icon(Icons.print, color: AppColors.primary),
            SizedBox(width: AppSpacing.sm),
            Text('طباعة تجريبية', style: AppTypography.titleLarge),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.check_circle_outline,
                size: 64.sp, color: AppColors.success),
            SizedBox(height: AppSpacing.md),
            Text(
              'سيتم إرسال صفحة اختبار للطابعة',
              style: AppTypography.bodyMedium,
              textAlign: TextAlign.center,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ProSnackbar.info(context, 'جاري الطباعة...');
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
            ),
            child: const Text('طباعة', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Future<void> _resetToDefaults() async {
    final confirm = await showProConfirmDialog(
      context: context,
      title: 'إعادة التعيين',
      message: 'سيتم إعادة جميع الإعدادات للقيم الافتراضية.\nهل أنت متأكد؟',
      icon: Icons.restore_rounded,
      isDanger: true,
      confirmText: 'إعادة التعيين',
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
