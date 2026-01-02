// ═══════════════════════════════════════════════════════════════════════════
// Customer Form Screen Pro
// Add/Edit Customer Form
// ═══════════════════════════════════════════════════════════════════════════

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/design_tokens.dart';
import '../../core/providers/app_providers.dart';
import '../../core/widgets/widgets.dart';
import '../../data/database/app_database.dart';

class CustomerFormScreenPro extends ConsumerStatefulWidget {
  final String? customerId;

  const CustomerFormScreenPro({
    super.key,
    this.customerId,
  });

  bool get isEditing => customerId != null;

  @override
  ConsumerState<CustomerFormScreenPro> createState() =>
      _CustomerFormScreenProState();
}

class _CustomerFormScreenProState extends ConsumerState<CustomerFormScreenPro> {
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
  bool _isLoading = false;
  bool _isSaving = false;
  Customer? _existingCustomer;

  @override
  void initState() {
    super.initState();
    if (widget.isEditing) {
      _loadCustomerData();
    }
  }

  Future<void> _loadCustomerData() async {
    if (widget.customerId == null) return;

    setState(() => _isLoading = true);
    try {
      final customerRepo = ref.read(customerRepositoryProvider);
      final customer = await customerRepo.getCustomerById(widget.customerId!);

      if (customer != null && mounted) {
        setState(() {
          _existingCustomer = customer;
          _nameController.text = customer.name;
          _phoneController.text = customer.phone ?? '';
          _emailController.text = customer.email ?? '';
          _addressController.text = customer.address ?? '';
          _notesController.text = customer.notes ?? '';
          _isActive = customer.isActive;
          // Determine customer type based on name or email
          _customerType =
              customer.email?.contains('@') == true ? 'company' : 'individual';
        });
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
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
    if (_isLoading) {
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
            style:
                AppTypography.titleLarge.copyWith(color: AppColors.textPrimary),
          ),
        ),
        body: ProLoadingState.withMessage(message: 'جاري تحميل البيانات...'),
      );
    }

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
            onPressed: _isSaving ? null : _saveCustomer,
            child: _isSaving
                ? SizedBox(
                    width: 20.w,
                    height: 20.w,
                    child: CircularProgressIndicator(strokeWidth: 2))
                : Text(
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
              const ProSectionTitle('المعلومات الأساسية'),
              SizedBox(height: AppSpacing.md),
              ProTextField(
                controller: _nameController,
                label: _customerType == 'company' ? 'اسم الشركة' : 'اسم العميل',
                hint: _customerType == 'company'
                    ? 'أدخل اسم الشركة'
                    : 'أدخل اسم العميل',
                prefixIcon: _customerType == 'company'
                    ? Icons.business_outlined
                    : Icons.person_outline,
                validator: (value) =>
                    value?.isEmpty ?? true ? 'الاسم مطلوب' : null,
              ),
              SizedBox(height: AppSpacing.md),

              Row(
                children: [
                  Expanded(
                    child: ProTextField(
                      controller: _phoneController,
                      label: 'رقم الجوال',
                      hint: '05xxxxxxxx',
                      prefixIcon: Icons.phone_outlined,
                      keyboardType: TextInputType.phone,
                      validator: (value) =>
                          value?.isEmpty ?? true ? 'رقم الجوال مطلوب' : null,
                    ),
                  ),
                  SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: ProTextField(
                      controller: _emailController,
                      label: 'البريد الإلكتروني',
                      hint: 'email@example.com',
                      prefixIcon: Icons.email_outlined,
                      keyboardType: TextInputType.emailAddress,
                    ),
                  ),
                ],
              ),
              SizedBox(height: AppSpacing.md),

              ProTextField(
                controller: _addressController,
                label: 'العنوان',
                hint: 'أدخل العنوان',
                prefixIcon: Icons.location_on_outlined,
                maxLines: 2,
              ),

              if (_customerType == 'company') ...[
                SizedBox(height: AppSpacing.lg),
                const ProSectionTitle('معلومات الشركة'),
                SizedBox(height: AppSpacing.md),
                ProTextField(
                  controller: _taxNumberController,
                  label: 'الرقم الضريبي',
                  hint: 'أدخل الرقم الضريبي',
                  prefixIcon: Icons.numbers_outlined,
                  keyboardType: TextInputType.number,
                ),
              ],

              SizedBox(height: AppSpacing.lg),

              // Financial Settings
              const ProSectionTitle('الإعدادات المالية'),
              SizedBox(height: AppSpacing.md),
              ProTextField(
                controller: _creditLimitController,
                label: 'حد الائتمان',
                hint: '0.00',
                prefixIcon: Icons.credit_card_outlined,
                keyboardType: TextInputType.number,
                suffixText: 'ر.س',
              ),

              SizedBox(height: AppSpacing.lg),

              // Status Toggle
              ProSwitchTile(
                title: 'عميل نشط',
                subtitle: 'يظهر في قوائم الاختيار',
                value: _isActive,
                onChanged: (value) => setState(() => _isActive = value),
              ),

              SizedBox(height: AppSpacing.lg),

              // Notes
              const ProSectionTitle('ملاحظات'),
              SizedBox(height: AppSpacing.md),
              ProTextField(
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
                  onPressed: _isSaving ? null : _deleteCustomer,
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
                onPressed: _isSaving ? null : _saveCustomer,
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.secondary,
                  padding: EdgeInsets.symmetric(vertical: AppSpacing.md),
                ),
                child: _isSaving
                    ? SizedBox(
                        width: 20.w,
                        height: 20.w,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white))
                    : Text(
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

  Future<void> _deleteCustomer() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('حذف العميل'),
        content: const Text('هل أنت متأكد من حذف هذا العميل؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('إلغاء'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('حذف'),
          ),
        ],
      ),
    );

    if (confirm != true || !mounted) return;

    setState(() => _isSaving = true);
    try {
      final customerRepo = ref.read(customerRepositoryProvider);
      await customerRepo.deleteCustomer(widget.customerId!);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('تم حذف العميل بنجاح'),
              backgroundColor: AppColors.success),
        );
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('خطأ: $e'), backgroundColor: AppColors.error),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _saveCustomer() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() => _isSaving = true);
    try {
      final customerRepo = ref.read(customerRepositoryProvider);

      if (widget.isEditing && _existingCustomer != null) {
        // Update existing customer
        await customerRepo.updateCustomer(
          id: widget.customerId!,
          name: _nameController.text.trim(),
          phone: _phoneController.text.trim().isEmpty
              ? null
              : _phoneController.text.trim(),
          email: _emailController.text.trim().isEmpty
              ? null
              : _emailController.text.trim(),
          address: _addressController.text.trim().isEmpty
              ? null
              : _addressController.text.trim(),
          notes: _notesController.text.trim().isEmpty
              ? null
              : _notesController.text.trim(),
          isActive: _isActive,
        );
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: Text('تم تحديث العميل بنجاح'),
                backgroundColor: AppColors.success),
          );
        }
      } else {
        // Create new customer
        await customerRepo.createCustomer(
          name: _nameController.text.trim(),
          phone: _phoneController.text.trim().isEmpty
              ? null
              : _phoneController.text.trim(),
          email: _emailController.text.trim().isEmpty
              ? null
              : _emailController.text.trim(),
          address: _addressController.text.trim().isEmpty
              ? null
              : _addressController.text.trim(),
          notes: _notesController.text.trim().isEmpty
              ? null
              : _notesController.text.trim(),
        );
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: Text('تم إضافة العميل بنجاح'),
                backgroundColor: AppColors.success),
          );
        }
      }

      if (mounted) context.pop();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('خطأ في حفظ العميل: $e'),
              backgroundColor: AppColors.error),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }
}
