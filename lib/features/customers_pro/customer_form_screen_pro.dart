// ═══════════════════════════════════════════════════════════════════════════
// Customer Form Screen Pro
// Add/Edit Customer Form
// ═══════════════════════════════════════════════════════════════════════════

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/pro/design_tokens.dart';

class CustomerFormScreenPro extends StatefulWidget {
  final String? customerId;

  const CustomerFormScreenPro({
    super.key,
    this.customerId,
  });

  bool get isEditing => customerId != null;

  @override
  State<CustomerFormScreenPro> createState() => _CustomerFormScreenProState();
}

class _CustomerFormScreenProState extends State<CustomerFormScreenPro> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _addressController = TextEditingController();
  final _taxNumberController = TextEditingController();
  final _notesController = TextEditingController();
  final _creditLimitController = TextEditingController();

  String _customerType = 'individual';
  bool _isActive = true;

  @override
  void initState() {
    super.initState();
    if (widget.isEditing) {
      _loadCustomerData();
    }
  }

  void _loadCustomerData() {
    // TODO: Load customer data
    _nameController.text = 'شركة النور للتجارة';
    _phoneController.text = '0551234567';
    _emailController.text = 'info@alnoor.com';
    _customerType = 'company';
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _addressController.dispose();
    _taxNumberController.dispose();
    _notesController.dispose();
    _creditLimitController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        leading: IconButton(
          onPressed: () => context.pop(),
          icon: Icon(Icons.close_rounded, color: AppColors.textSecondary),
        ),
        title: Text(
          widget.isEditing ? 'تعديل عميل' : 'عميل جديد',
          style: AppTypography.titleLarge.copyWith(
            color: AppColors.textPrimary,
          ),
        ),
        actions: [
          TextButton(
            onPressed: _saveCustomer,
            child: Text(
              'حفظ',
              style: AppTypography.labelLarge.copyWith(
                color: AppColors.secondary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          SizedBox(width: AppSpacing.sm),
        ],
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: EdgeInsets.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Customer Type Selection
              _buildTypeSelection(),
              SizedBox(height: AppSpacing.lg),

              // Basic Info Section
              _buildSectionTitle('المعلومات الأساسية'),
              SizedBox(height: AppSpacing.md),
              _buildTextField(
                controller: _nameController,
                label: _customerType == 'company' ? 'اسم الشركة' : 'اسم العميل',
                hint: _customerType == 'company'
                    ? 'أدخل اسم الشركة'
                    : 'أدخل اسم العميل',
                icon: _customerType == 'company'
                    ? Icons.business_outlined
                    : Icons.person_outline,
                validator: (value) =>
                    value?.isEmpty ?? true ? 'الاسم مطلوب' : null,
              ),
              SizedBox(height: AppSpacing.md),

              Row(
                children: [
                  Expanded(
                    child: _buildTextField(
                      controller: _phoneController,
                      label: 'رقم الجوال',
                      hint: '05xxxxxxxx',
                      icon: Icons.phone_outlined,
                      keyboardType: TextInputType.phone,
                      validator: (value) =>
                          value?.isEmpty ?? true ? 'رقم الجوال مطلوب' : null,
                    ),
                  ),
                  SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: _buildTextField(
                      controller: _emailController,
                      label: 'البريد الإلكتروني',
                      hint: 'email@example.com',
                      icon: Icons.email_outlined,
                      keyboardType: TextInputType.emailAddress,
                    ),
                  ),
                ],
              ),
              SizedBox(height: AppSpacing.md),

              _buildTextField(
                controller: _addressController,
                label: 'العنوان',
                hint: 'أدخل العنوان',
                icon: Icons.location_on_outlined,
                maxLines: 2,
              ),

              if (_customerType == 'company') ...[
                SizedBox(height: AppSpacing.lg),
                _buildSectionTitle('معلومات الشركة'),
                SizedBox(height: AppSpacing.md),
                _buildTextField(
                  controller: _taxNumberController,
                  label: 'الرقم الضريبي',
                  hint: 'أدخل الرقم الضريبي',
                  icon: Icons.numbers_outlined,
                  keyboardType: TextInputType.number,
                ),
              ],

              SizedBox(height: AppSpacing.lg),

              // Financial Settings
              _buildSectionTitle('الإعدادات المالية'),
              SizedBox(height: AppSpacing.md),
              _buildTextField(
                controller: _creditLimitController,
                label: 'حد الائتمان',
                hint: '0.00',
                icon: Icons.credit_card_outlined,
                keyboardType: TextInputType.number,
                suffixText: 'ر.س',
              ),

              SizedBox(height: AppSpacing.lg),

              // Status Toggle
              _buildSwitchTile(
                title: 'عميل نشط',
                subtitle: 'يظهر في قوائم الاختيار',
                value: _isActive,
                onChanged: (value) => setState(() => _isActive = value),
              ),

              SizedBox(height: AppSpacing.lg),

              // Notes
              _buildSectionTitle('ملاحظات'),
              SizedBox(height: AppSpacing.md),
              _buildTextField(
                controller: _notesController,
                label: 'ملاحظات إضافية',
                hint: 'أضف ملاحظات عن العميل...',
                maxLines: 3,
              ),

              SizedBox(height: AppSpacing.xxl),
            ],
          ),
        ),
      ),
      bottomNavigationBar: _buildBottomBar(),
    );
  }

  Widget _buildTypeSelection() {
    return Container(
      padding: EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'نوع العميل',
            style: AppTypography.titleSmall.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: AppSpacing.md),
          Row(
            children: [
              Expanded(
                child: _buildTypeOption(
                  label: 'فرد',
                  icon: Icons.person_outline_rounded,
                  value: 'individual',
                ),
              ),
              SizedBox(width: AppSpacing.md),
              Expanded(
                child: _buildTypeOption(
                  label: 'شركة',
                  icon: Icons.business_outlined,
                  value: 'company',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTypeOption({
    required String label,
    required IconData icon,
    required String value,
  }) {
    final isSelected = _customerType == value;
    return InkWell(
      onTap: () => setState(() => _customerType = value),
      borderRadius: BorderRadius.circular(AppRadius.md),
      child: AnimatedContainer(
        duration: AppDurations.fast,
        padding: EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.secondary.withOpacity(0.1)
              : AppColors.background,
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(
            color: isSelected ? AppColors.secondary : AppColors.border,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              size: 32.sp,
              color: isSelected ? AppColors.secondary : AppColors.textTertiary,
            ),
            SizedBox(height: AppSpacing.xs),
            Text(
              label,
              style: AppTypography.labelMedium.copyWith(
                color:
                    isSelected ? AppColors.secondary : AppColors.textSecondary,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: AppTypography.titleMedium.copyWith(
        color: AppColors.textPrimary,
        fontWeight: FontWeight.w600,
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    IconData? icon,
    TextInputType? keyboardType,
    int maxLines = 1,
    String? suffixText,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppTypography.labelMedium.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
        SizedBox(height: AppSpacing.xs),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          maxLines: maxLines,
          validator: validator,
          style: AppTypography.bodyMedium,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: AppTypography.bodyMedium.copyWith(
              color: AppColors.textTertiary,
            ),
            prefixIcon: icon != null
                ? Icon(icon,
                    color: AppColors.textTertiary, size: AppIconSize.sm)
                : null,
            suffixText: suffixText,
            filled: true,
            fillColor: AppColors.surface,
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
              borderSide: BorderSide(color: AppColors.secondary, width: 2),
            ),
            contentPadding: EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.md,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSwitchTile({
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Container(
      padding: EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTypography.titleSmall.copyWith(
                    color: AppColors.textPrimary,
                  ),
                ),
                SizedBox(height: 2.h),
                Text(
                  subtitle,
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.textTertiary,
                  ),
                ),
              ],
            ),
          ),
          Switch.adaptive(
            value: value,
            onChanged: onChanged,
            activeColor: AppColors.secondary,
          ),
        ],
      ),
    );
  }

  Widget _buildBottomBar() {
    return Container(
      padding: EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border(top: BorderSide(color: AppColors.border)),
      ),
      child: SafeArea(
        child: Row(
          children: [
            if (widget.isEditing)
              Expanded(
                child: OutlinedButton(
                  onPressed: () {
                    // TODO: Show delete confirmation
                  },
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.error,
                    side: BorderSide(color: AppColors.error),
                    padding: EdgeInsets.symmetric(vertical: AppSpacing.md),
                  ),
                  child: const Text('حذف'),
                ),
              ),
            if (widget.isEditing) SizedBox(width: AppSpacing.md),
            Expanded(
              flex: 2,
              child: FilledButton(
                onPressed: _saveCustomer,
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.secondary,
                  padding: EdgeInsets.symmetric(vertical: AppSpacing.md),
                ),
                child: Text(
                  widget.isEditing ? 'حفظ التغييرات' : 'إضافة العميل',
                  style: AppTypography.labelLarge.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _saveCustomer() {
    if (_formKey.currentState?.validate() ?? false) {
      // TODO: Save customer
      context.pop();
    }
  }
}
