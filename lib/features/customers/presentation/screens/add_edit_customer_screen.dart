import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/widgets/app_bar_widget.dart';
import '../../../../core/widgets/custom_button.dart';
import '../../../../core/widgets/custom_text_field.dart';
import '../../domain/entities/entities.dart';
import '../providers/customer_providers.dart';

/// شاشة إضافة/تعديل العميل
class AddEditCustomerScreen extends ConsumerStatefulWidget {
  final String? customerId;

  const AddEditCustomerScreen({super.key, this.customerId});

  @override
  ConsumerState<AddEditCustomerScreen> createState() =>
      _AddEditCustomerScreenState();
}

class _AddEditCustomerScreenState extends ConsumerState<AddEditCustomerScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _addressController = TextEditingController();
  final _cityController = TextEditingController();
  final _taxNumberController = TextEditingController();
  final _commercialRegisterController = TextEditingController();
  final _creditLimitController = TextEditingController();
  final _notesController = TextEditingController();

  CustomerType _type = CustomerType.regular;
  CustomerStatus _status = CustomerStatus.active;
  bool _isLoading = false;
  CustomerEntity? _existingCustomer;

  bool get _isEditing => widget.customerId != null;

  @override
  void initState() {
    super.initState();
    if (_isEditing) {
      _loadCustomer();
    }
  }

  Future<void> _loadCustomer() async {
    final customerAsync =
        await ref.read(customerProvider(widget.customerId!).future);
    if (customerAsync != null && mounted) {
      setState(() {
        _existingCustomer = customerAsync;
        _nameController.text = customerAsync.name;
        _phoneController.text = customerAsync.phone ?? '';
        _emailController.text = customerAsync.email ?? '';
        _addressController.text = customerAsync.address ?? '';
        _cityController.text = customerAsync.city ?? '';
        _taxNumberController.text = customerAsync.taxNumber ?? '';
        _commercialRegisterController.text =
            customerAsync.commercialRegister ?? '';
        _creditLimitController.text = customerAsync.creditLimit > 0
            ? customerAsync.creditLimit.toString()
            : '';
        _notesController.text = customerAsync.notes ?? '';
        _type = customerAsync.type;
        _status = customerAsync.status;
      });
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _addressController.dispose();
    _cityController.dispose();
    _taxNumberController.dispose();
    _commercialRegisterController.dispose();
    _creditLimitController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        title: _isEditing ? 'تعديل العميل' : 'إضافة عميل',
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: EdgeInsets.all(16.w),
          children: [
            // الاسم
            CustomTextField(
              controller: _nameController,
              label: 'اسم العميل *',
              prefixIcon: Icons.person_outline,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'الرجاء إدخال اسم العميل';
                }
                return null;
              },
            ),
            SizedBox(height: 16.h),

            // الهاتف
            CustomTextField(
              controller: _phoneController,
              label: 'رقم الهاتف',
              prefixIcon: Icons.phone_outlined,
              keyboardType: TextInputType.phone,
            ),
            SizedBox(height: 16.h),

            // البريد
            CustomTextField(
              controller: _emailController,
              label: 'البريد الإلكتروني',
              prefixIcon: Icons.email_outlined,
              keyboardType: TextInputType.emailAddress,
            ),
            SizedBox(height: 16.h),

            // العنوان
            CustomTextField(
              controller: _addressController,
              label: 'العنوان',
              prefixIcon: Icons.location_on_outlined,
              maxLines: 2,
            ),
            SizedBox(height: 16.h),

            // المدينة
            CustomTextField(
              controller: _cityController,
              label: 'المدينة',
              prefixIcon: Icons.location_city_outlined,
            ),
            SizedBox(height: 16.h),

            // الرقم الضريبي
            CustomTextField(
              controller: _taxNumberController,
              label: 'الرقم الضريبي',
              prefixIcon: Icons.numbers_outlined,
            ),
            SizedBox(height: 16.h),

            // السجل التجاري
            CustomTextField(
              controller: _commercialRegisterController,
              label: 'السجل التجاري',
              prefixIcon: Icons.business_outlined,
            ),
            SizedBox(height: 16.h),

            // نوع العميل
            _buildTypeSelector(),
            SizedBox(height: 16.h),

            // حالة العميل (فقط في التعديل)
            if (_isEditing) ...[
              _buildStatusSelector(),
              SizedBox(height: 16.h),
            ],

            // حد الائتمان
            CustomTextField(
              controller: _creditLimitController,
              label: 'حد الائتمان',
              prefixIcon: Icons.credit_card_outlined,
              keyboardType: TextInputType.number,
              hint: 'اتركه فارغاً إذا لا يوجد حد',
            ),
            SizedBox(height: 16.h),

            // ملاحظات
            CustomTextField(
              controller: _notesController,
              label: 'ملاحظات',
              prefixIcon: Icons.notes_outlined,
              maxLines: 3,
            ),
            SizedBox(height: 24.h),

            // زر الحفظ
            CustomButton(
              text: _isEditing ? 'تحديث' : 'حفظ',
              isLoading: _isLoading,
              onPressed: _saveCustomer,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTypeSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'نوع العميل',
          style: TextStyle(
            fontSize: 14.sp,
            fontWeight: FontWeight.w500,
            color: AppColors.textSecondary,
          ),
        ),
        SizedBox(height: 8.h),
        Row(
          children: [
            _buildTypeChip(CustomerType.regular, 'عادي', Icons.person),
            SizedBox(width: 8.w),
            _buildTypeChip(CustomerType.vip, 'VIP', Icons.star),
            SizedBox(width: 8.w),
            _buildTypeChip(CustomerType.wholesale, 'تاجر جملة', Icons.store),
          ],
        ),
      ],
    );
  }

  Widget _buildTypeChip(CustomerType type, String label, IconData icon) {
    final isSelected = _type == type;
    return Expanded(
      child: InkWell(
        onTap: () => setState(() => _type = type),
        borderRadius: BorderRadius.circular(8.r),
        child: Container(
          padding: EdgeInsets.symmetric(vertical: 12.h),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.primary : Colors.grey[100],
            borderRadius: BorderRadius.circular(8.r),
            border: Border.all(
              color: isSelected ? AppColors.primary : Colors.grey[300]!,
            ),
          ),
          child: Column(
            children: [
              Icon(
                icon,
                color: isSelected ? Colors.white : Colors.grey[600],
                size: 24.sp,
              ),
              SizedBox(height: 4.h),
              Text(
                label,
                style: TextStyle(
                  color: isSelected ? Colors.white : Colors.grey[600],
                  fontSize: 12.sp,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'حالة العميل',
          style: TextStyle(
            fontSize: 14.sp,
            fontWeight: FontWeight.w500,
            color: AppColors.textSecondary,
          ),
        ),
        SizedBox(height: 8.h),
        SegmentedButton<CustomerStatus>(
          segments: const [
            ButtonSegment(
              value: CustomerStatus.active,
              label: Text('نشط'),
              icon: Icon(Icons.check_circle_outline),
            ),
            ButtonSegment(
              value: CustomerStatus.inactive,
              label: Text('غير نشط'),
              icon: Icon(Icons.pause_circle_outline),
            ),
            ButtonSegment(
              value: CustomerStatus.blocked,
              label: Text('محظور'),
              icon: Icon(Icons.block_outlined),
            ),
          ],
          selected: {_status},
          onSelectionChanged: (value) => setState(() => _status = value.first),
        ),
      ],
    );
  }

  Future<void> _saveCustomer() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final customer = CustomerEntity(
      id: _existingCustomer?.id ?? '',
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
      city: _cityController.text.trim().isEmpty
          ? null
          : _cityController.text.trim(),
      taxNumber: _taxNumberController.text.trim().isEmpty
          ? null
          : _taxNumberController.text.trim(),
      commercialRegister: _commercialRegisterController.text.trim().isEmpty
          ? null
          : _commercialRegisterController.text.trim(),
      type: _type,
      status: _status,
      creditLimit: double.tryParse(_creditLimitController.text) ?? 0,
      balance: _existingCustomer?.balance ?? 0,
      totalPurchases: _existingCustomer?.totalPurchases ?? 0,
      totalPayments: _existingCustomer?.totalPayments ?? 0,
      invoicesCount: _existingCustomer?.invoicesCount ?? 0,
      notes: _notesController.text.trim().isEmpty
          ? null
          : _notesController.text.trim(),
      createdAt: _existingCustomer?.createdAt ?? DateTime.now(),
      updatedAt: DateTime.now(),
    );

    final notifier = ref.read(customerNotifierProvider.notifier);
    final success = _isEditing
        ? await notifier.updateCustomer(customer)
        : await notifier.addCustomer(customer);

    setState(() => _isLoading = false);

    if (mounted && success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              _isEditing ? 'تم تحديث العميل بنجاح' : 'تم إضافة العميل بنجاح'),
        ),
      );
      context.pop();
    }
  }
}
