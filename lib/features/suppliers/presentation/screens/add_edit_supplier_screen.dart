import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/widgets/app_bar_widget.dart';
import '../../../../core/widgets/custom_button.dart';
import '../../../../core/widgets/custom_text_field.dart';
import '../../domain/entities/entities.dart';
import '../providers/supplier_providers.dart';

/// شاشة إضافة/تعديل المورد
class AddEditSupplierScreen extends ConsumerStatefulWidget {
  final String? supplierId;

  const AddEditSupplierScreen({super.key, this.supplierId});

  @override
  ConsumerState<AddEditSupplierScreen> createState() =>
      _AddEditSupplierScreenState();
}

class _AddEditSupplierScreenState extends ConsumerState<AddEditSupplierScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _contactPersonController = TextEditingController();
  final _phoneController = TextEditingController();
  final _phone2Controller = TextEditingController();
  final _emailController = TextEditingController();
  final _addressController = TextEditingController();
  final _cityController = TextEditingController();
  final _countryController = TextEditingController();
  final _taxNumberController = TextEditingController();
  final _commercialRegisterController = TextEditingController();
  final _bankNameController = TextEditingController();
  final _bankAccountController = TextEditingController();
  final _ibanController = TextEditingController();
  final _notesController = TextEditingController();

  SupplierStatus _status = SupplierStatus.active;
  SupplierRating _rating = SupplierRating.good;
  bool _isLoading = false;
  SupplierEntity? _existingSupplier;

  bool get _isEditing => widget.supplierId != null;

  @override
  void initState() {
    super.initState();
    if (_isEditing) {
      _loadSupplier();
    }
  }

  Future<void> _loadSupplier() async {
    final supplierAsync =
        await ref.read(supplierProvider(widget.supplierId!).future);
    if (supplierAsync != null && mounted) {
      setState(() {
        _existingSupplier = supplierAsync;
        _nameController.text = supplierAsync.name;
        _contactPersonController.text = supplierAsync.contactPerson ?? '';
        _phoneController.text = supplierAsync.phone ?? '';
        _phone2Controller.text = supplierAsync.phone2 ?? '';
        _emailController.text = supplierAsync.email ?? '';
        _addressController.text = supplierAsync.address ?? '';
        _cityController.text = supplierAsync.city ?? '';
        _countryController.text = supplierAsync.country ?? '';
        _taxNumberController.text = supplierAsync.taxNumber ?? '';
        _commercialRegisterController.text =
            supplierAsync.commercialRegister ?? '';
        _bankNameController.text = supplierAsync.bankName ?? '';
        _bankAccountController.text = supplierAsync.bankAccount ?? '';
        _ibanController.text = supplierAsync.iban ?? '';
        _notesController.text = supplierAsync.notes ?? '';
        _status = supplierAsync.status;
        _rating = supplierAsync.rating;
      });
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _contactPersonController.dispose();
    _phoneController.dispose();
    _phone2Controller.dispose();
    _emailController.dispose();
    _addressController.dispose();
    _cityController.dispose();
    _countryController.dispose();
    _taxNumberController.dispose();
    _commercialRegisterController.dispose();
    _bankNameController.dispose();
    _bankAccountController.dispose();
    _ibanController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        title: _isEditing ? 'تعديل المورد' : 'إضافة مورد',
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: EdgeInsets.all(16.w),
          children: [
            // الاسم
            CustomTextField(
              controller: _nameController,
              label: 'اسم المورد *',
              prefixIcon: Icons.business,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'يرجى إدخال اسم المورد';
                }
                return null;
              },
            ),
            SizedBox(height: 16.h),

            // الشخص المسؤول
            CustomTextField(
              controller: _contactPersonController,
              label: 'الشخص المسؤول',
              prefixIcon: Icons.person,
            ),
            SizedBox(height: 16.h),

            // الهاتف
            Row(
              children: [
                Expanded(
                  child: CustomTextField(
                    controller: _phoneController,
                    label: 'الهاتف',
                    prefixIcon: Icons.phone,
                    keyboardType: TextInputType.phone,
                  ),
                ),
                SizedBox(width: 8.w),
                Expanded(
                  child: CustomTextField(
                    controller: _phone2Controller,
                    label: 'هاتف إضافي',
                    prefixIcon: Icons.phone_android,
                    keyboardType: TextInputType.phone,
                  ),
                ),
              ],
            ),
            SizedBox(height: 16.h),

            // البريد الإلكتروني
            CustomTextField(
              controller: _emailController,
              label: 'البريد الإلكتروني',
              prefixIcon: Icons.email,
              keyboardType: TextInputType.emailAddress,
            ),
            SizedBox(height: 16.h),

            // العنوان والمدينة
            CustomTextField(
              controller: _addressController,
              label: 'العنوان',
              prefixIcon: Icons.location_on,
            ),
            SizedBox(height: 16.h),

            Row(
              children: [
                Expanded(
                  child: CustomTextField(
                    controller: _cityController,
                    label: 'المدينة',
                    prefixIcon: Icons.location_city,
                  ),
                ),
                SizedBox(width: 8.w),
                Expanded(
                  child: CustomTextField(
                    controller: _countryController,
                    label: 'الدولة',
                    prefixIcon: Icons.flag,
                  ),
                ),
              ],
            ),
            SizedBox(height: 16.h),

            // البيانات الضريبية
            Row(
              children: [
                Expanded(
                  child: CustomTextField(
                    controller: _taxNumberController,
                    label: 'الرقم الضريبي',
                    prefixIcon: Icons.receipt,
                  ),
                ),
                SizedBox(width: 8.w),
                Expanded(
                  child: CustomTextField(
                    controller: _commercialRegisterController,
                    label: 'السجل التجاري',
                    prefixIcon: Icons.document_scanner,
                  ),
                ),
              ],
            ),
            SizedBox(height: 16.h),

            // البيانات البنكية
            CustomTextField(
              controller: _bankNameController,
              label: 'اسم البنك',
              prefixIcon: Icons.account_balance,
            ),
            SizedBox(height: 16.h),

            Row(
              children: [
                Expanded(
                  child: CustomTextField(
                    controller: _bankAccountController,
                    label: 'رقم الحساب',
                    prefixIcon: Icons.credit_card,
                  ),
                ),
                SizedBox(width: 8.w),
                Expanded(
                  child: CustomTextField(
                    controller: _ibanController,
                    label: 'IBAN',
                    prefixIcon: Icons.account_balance_wallet,
                  ),
                ),
              ],
            ),
            SizedBox(height: 16.h),

            // الحالة والتقييم
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<SupplierStatus>(
                    value: _status,
                    decoration: InputDecoration(
                      labelText: 'الحالة',
                      prefixIcon: const Icon(Icons.toggle_on),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8.r),
                      ),
                    ),
                    items: SupplierStatus.values.map((status) {
                      return DropdownMenuItem(
                        value: status,
                        child: Text(_getStatusName(status)),
                      );
                    }).toList(),
                    onChanged: (value) {
                      if (value != null) {
                        setState(() => _status = value);
                      }
                    },
                  ),
                ),
                SizedBox(width: 8.w),
                Expanded(
                  child: DropdownButtonFormField<SupplierRating>(
                    value: _rating,
                    decoration: InputDecoration(
                      labelText: 'التقييم',
                      prefixIcon: const Icon(Icons.star),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8.r),
                      ),
                    ),
                    items: SupplierRating.values.map((rating) {
                      return DropdownMenuItem(
                        value: rating,
                        child: Text(_getRatingName(rating)),
                      );
                    }).toList(),
                    onChanged: (value) {
                      if (value != null) {
                        setState(() => _rating = value);
                      }
                    },
                  ),
                ),
              ],
            ),
            SizedBox(height: 16.h),

            // الملاحظات
            CustomTextField(
              controller: _notesController,
              label: 'ملاحظات',
              prefixIcon: Icons.notes,
              maxLines: 3,
            ),
            SizedBox(height: 24.h),

            // زر الحفظ
            CustomButton(
              text: _isEditing ? 'تحديث' : 'حفظ',
              onPressed: _isLoading ? null : _save,
              isLoading: _isLoading,
            ),
          ],
        ),
      ),
    );
  }

  String _getStatusName(SupplierStatus status) {
    switch (status) {
      case SupplierStatus.active:
        return 'نشط';
      case SupplierStatus.inactive:
        return 'غير نشط';
      case SupplierStatus.blocked:
        return 'محظور';
    }
  }

  String _getRatingName(SupplierRating rating) {
    switch (rating) {
      case SupplierRating.excellent:
        return 'ممتاز';
      case SupplierRating.good:
        return 'جيد';
      case SupplierRating.average:
        return 'متوسط';
      case SupplierRating.poor:
        return 'ضعيف';
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final supplier = SupplierEntity(
        id: _existingSupplier?.id ?? '',
        name: _nameController.text.trim(),
        contactPerson: _contactPersonController.text.trim().isEmpty
            ? null
            : _contactPersonController.text.trim(),
        phone: _phoneController.text.trim().isEmpty
            ? null
            : _phoneController.text.trim(),
        phone2: _phone2Controller.text.trim().isEmpty
            ? null
            : _phone2Controller.text.trim(),
        email: _emailController.text.trim().isEmpty
            ? null
            : _emailController.text.trim(),
        address: _addressController.text.trim().isEmpty
            ? null
            : _addressController.text.trim(),
        city: _cityController.text.trim().isEmpty
            ? null
            : _cityController.text.trim(),
        country: _countryController.text.trim().isEmpty
            ? null
            : _countryController.text.trim(),
        taxNumber: _taxNumberController.text.trim().isEmpty
            ? null
            : _taxNumberController.text.trim(),
        commercialRegister: _commercialRegisterController.text.trim().isEmpty
            ? null
            : _commercialRegisterController.text.trim(),
        bankName: _bankNameController.text.trim().isEmpty
            ? null
            : _bankNameController.text.trim(),
        bankAccount: _bankAccountController.text.trim().isEmpty
            ? null
            : _bankAccountController.text.trim(),
        iban: _ibanController.text.trim().isEmpty
            ? null
            : _ibanController.text.trim(),
        status: _status,
        rating: _rating,
        notes: _notesController.text.trim().isEmpty
            ? null
            : _notesController.text.trim(),
        balance: _existingSupplier?.balance ?? 0,
        totalPurchases: _existingSupplier?.totalPurchases ?? 0,
        totalPayments: _existingSupplier?.totalPayments ?? 0,
        purchaseOrdersCount: _existingSupplier?.purchaseOrdersCount ?? 0,
        createdAt: _existingSupplier?.createdAt ?? DateTime.now(),
        updatedAt: DateTime.now(),
      );

      if (_isEditing) {
        await ref
            .read(supplierNotifierProvider.notifier)
            .updateSupplier(supplier);
      } else {
        await ref.read(supplierNotifierProvider.notifier).addSupplier(supplier);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_isEditing ? 'تم تحديث المورد' : 'تم إضافة المورد'),
            backgroundColor: AppColors.success,
          ),
        );
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('حدث خطأ: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }
}
