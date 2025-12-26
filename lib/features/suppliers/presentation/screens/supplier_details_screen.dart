import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/widgets/app_bar_widget.dart';
import '../../domain/entities/entities.dart';
import '../providers/supplier_providers.dart';

/// شاشة تفاصيل المورد
class SupplierDetailsScreen extends ConsumerWidget {
  final String supplierId;

  const SupplierDetailsScreen({super.key, required this.supplierId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final supplierAsync = ref.watch(supplierProvider(supplierId));

    return Scaffold(
      appBar: CustomAppBar(
        title: 'تفاصيل المورد',
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () => context.push('/suppliers/edit/$supplierId'),
          ),
        ],
      ),
      body: supplierAsync.when(
        data: (supplier) {
          if (supplier == null) {
            return const Center(child: Text('المورد غير موجود'));
          }
          return _buildContent(context, supplier);
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text('خطأ: $error')),
      ),
    );
  }

  Widget _buildContent(BuildContext context, SupplierEntity supplier) {
    final dateFormat = DateFormat('yyyy/MM/dd');
    final currencyFormat = NumberFormat.currency(locale: 'ar', symbol: 'ر.س');

    return ListView(
      padding: EdgeInsets.all(16.w),
      children: [
        // معلومات أساسية
        _buildCard(
          context,
          title: 'المعلومات الأساسية',
          icon: Icons.business,
          children: [
            _buildInfoRow('الاسم', supplier.name),
            if (supplier.contactPerson != null)
              _buildInfoRow('الشخص المسؤول', supplier.contactPerson!),
            _buildInfoRow('الحالة', _getStatusName(supplier.status),
                color: _getStatusColor(supplier.status)),
            _buildInfoRow('التقييم', _getRatingName(supplier.rating),
                color: _getRatingColor(supplier.rating)),
          ],
        ),
        SizedBox(height: 16.h),

        // معلومات الاتصال
        _buildCard(
          context,
          title: 'معلومات الاتصال',
          icon: Icons.contact_phone,
          children: [
            if (supplier.phone != null)
              _buildInfoRow('الهاتف', supplier.phone!),
            if (supplier.phone2 != null)
              _buildInfoRow('هاتف إضافي', supplier.phone2!),
            if (supplier.email != null)
              _buildInfoRow('البريد الإلكتروني', supplier.email!),
            if (supplier.address != null)
              _buildInfoRow('العنوان', supplier.address!),
            if (supplier.city != null) _buildInfoRow('المدينة', supplier.city!),
            if (supplier.country != null)
              _buildInfoRow('الدولة', supplier.country!),
          ],
        ),
        SizedBox(height: 16.h),

        // المعلومات المالية
        _buildCard(
          context,
          title: 'المعلومات المالية',
          icon: Icons.account_balance_wallet,
          children: [
            _buildInfoRow('الرصيد', currencyFormat.format(supplier.balance),
                color: supplier.balance >= 0 ? Colors.red : Colors.green),
            _buildInfoRow('إجمالي المشتريات',
                currencyFormat.format(supplier.totalPurchases)),
            _buildInfoRow('إجمالي المدفوعات',
                currencyFormat.format(supplier.totalPayments)),
            _buildInfoRow('عدد الفواتير', '${supplier.purchaseOrdersCount}'),
          ],
        ),
        SizedBox(height: 16.h),

        // البيانات الضريبية والبنكية
        if (supplier.taxNumber != null ||
            supplier.commercialRegister != null ||
            supplier.bankName != null)
          _buildCard(
            context,
            title: 'البيانات الضريبية والبنكية',
            icon: Icons.receipt_long,
            children: [
              if (supplier.taxNumber != null)
                _buildInfoRow('الرقم الضريبي', supplier.taxNumber!),
              if (supplier.commercialRegister != null)
                _buildInfoRow('السجل التجاري', supplier.commercialRegister!),
              if (supplier.bankName != null)
                _buildInfoRow('البنك', supplier.bankName!),
              if (supplier.bankAccount != null)
                _buildInfoRow('رقم الحساب', supplier.bankAccount!),
              if (supplier.iban != null) _buildInfoRow('IBAN', supplier.iban!),
            ],
          ),
        SizedBox(height: 16.h),

        // معلومات إضافية
        _buildCard(
          context,
          title: 'معلومات إضافية',
          icon: Icons.info,
          children: [
            _buildInfoRow(
                'تاريخ الإضافة', dateFormat.format(supplier.createdAt)),
            if (supplier.lastPurchaseDate != null)
              _buildInfoRow(
                  'آخر شراء', dateFormat.format(supplier.lastPurchaseDate!)),
            if (supplier.notes != null && supplier.notes!.isNotEmpty)
              _buildInfoRow('ملاحظات', supplier.notes!),
          ],
        ),
      ],
    );
  }

  Widget _buildCard(
    BuildContext context, {
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(16.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: AppColors.primary, size: 20.sp),
                SizedBox(width: 8.w),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            Divider(height: 24.h),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, {Color? color}) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4.h),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120.w,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 13.sp,
                color: Colors.grey[600],
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 14.sp,
                fontWeight: FontWeight.w500,
                color: color,
              ),
            ),
          ),
        ],
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

  Color _getStatusColor(SupplierStatus status) {
    switch (status) {
      case SupplierStatus.active:
        return Colors.green;
      case SupplierStatus.inactive:
        return Colors.orange;
      case SupplierStatus.blocked:
        return Colors.red;
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

  Color _getRatingColor(SupplierRating rating) {
    switch (rating) {
      case SupplierRating.excellent:
        return Colors.green;
      case SupplierRating.good:
        return Colors.blue;
      case SupplierRating.average:
        return Colors.orange;
      case SupplierRating.poor:
        return Colors.red;
    }
  }
}
