import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/widgets/app_bar_widget.dart';
import '../../../../core/widgets/loading_widget.dart';
import '../../domain/entities/entities.dart';
import '../providers/customer_providers.dart';

/// شاشة تفاصيل العميل
class CustomerDetailsScreen extends ConsumerWidget {
  final String customerId;

  const CustomerDetailsScreen({super.key, required this.customerId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final customerAsync = ref.watch(customerProvider(customerId));

    return Scaffold(
      appBar: CustomAppBar(
        title: 'تفاصيل العميل',
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            onPressed: () => context.push('/customers/$customerId/edit'),
          ),
        ],
      ),
      body: customerAsync.when(
        data: (customer) {
          if (customer == null) {
            return const Center(child: Text('العميل غير موجود'));
          }
          return _buildContent(context, customer);
        },
        loading: () => LoadingWidget(),
        error: (error, _) => Center(child: Text('خطأ: $error')),
      ),
    );
  }

  Widget _buildContent(BuildContext context, CustomerEntity customer) {
    return ListView(
      padding: EdgeInsets.all(16.w),
      children: [
        // بطاقة المعلومات الأساسية
        _buildInfoCard(customer),
        SizedBox(height: 16.h),

        // بطاقة الرصيد
        _buildBalanceCard(customer),
        SizedBox(height: 16.h),

        // بطاقة الإحصائيات
        _buildStatsCard(customer),
        SizedBox(height: 16.h),

        // الإجراءات السريعة
        _buildQuickActions(context, customer),
      ],
    );
  }

  Widget _buildInfoCard(CustomerEntity customer) {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(16.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 30.r,
                  backgroundColor:
                      _getTypeColor(customer.type).withOpacity(0.2),
                  child: Text(
                    customer.name.isNotEmpty ? customer.name[0] : '?',
                    style: TextStyle(
                      fontSize: 24.sp,
                      fontWeight: FontWeight.bold,
                      color: _getTypeColor(customer.type),
                    ),
                  ),
                ),
                SizedBox(width: 16.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              customer.name,
                              style: TextStyle(
                                fontSize: 18.sp,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          _buildTypeChip(customer.type),
                        ],
                      ),
                      if (customer.phone != null) ...[
                        SizedBox(height: 4.h),
                        Text(
                          customer.phone!,
                          style: TextStyle(
                            fontSize: 14.sp,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
            Divider(height: 24.h),
            if (customer.email != null)
              _buildInfoRow(Icons.email_outlined, 'البريد', customer.email!),
            if (customer.address != null)
              _buildInfoRow(
                  Icons.location_on_outlined, 'العنوان', customer.address!),
            if (customer.city != null)
              _buildInfoRow(
                  Icons.location_city_outlined, 'المدينة', customer.city!),
            if (customer.taxNumber != null)
              _buildInfoRow(
                  Icons.numbers_outlined, 'الرقم الضريبي', customer.taxNumber!),
            if (customer.commercialRegister != null)
              _buildInfoRow(Icons.business_outlined, 'السجل التجاري',
                  customer.commercialRegister!),
            if (customer.notes != null)
              _buildInfoRow(Icons.notes_outlined, 'ملاحظات', customer.notes!),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: EdgeInsets.only(bottom: 12.h),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20.sp, color: AppColors.textSecondary),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12.sp,
                    color: AppColors.textSecondary,
                  ),
                ),
                Text(
                  value,
                  style: TextStyle(fontSize: 14.sp),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBalanceCard(CustomerEntity customer) {
    final hasDebt = customer.amountDue > 0;
    final hasCredit = customer.amountOwed > 0;

    return Card(
      color: hasDebt ? Colors.red[50] : (hasCredit ? Colors.green[50] : null),
      child: Padding(
        padding: EdgeInsets.all(16.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'الرصيد',
              style: TextStyle(
                fontSize: 14.sp,
                fontWeight: FontWeight.w500,
                color: AppColors.textSecondary,
              ),
            ),
            SizedBox(height: 12.h),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildBalanceItem(
                  'عليه',
                  customer.amountDue,
                  Colors.red,
                ),
                Container(
                  width: 1,
                  height: 40.h,
                  color: Colors.grey[300],
                ),
                _buildBalanceItem(
                  'له',
                  customer.amountOwed,
                  Colors.green,
                ),
                Container(
                  width: 1,
                  height: 40.h,
                  color: Colors.grey[300],
                ),
                _buildBalanceItem(
                  'حد الائتمان',
                  customer.creditLimit,
                  AppColors.primary,
                ),
              ],
            ),
            if (customer.isOverCreditLimit) ...[
              SizedBox(height: 12.h),
              Container(
                padding: EdgeInsets.all(8.w),
                decoration: BoxDecoration(
                  color: Colors.red[100],
                  borderRadius: BorderRadius.circular(8.r),
                ),
                child: Row(
                  children: [
                    Icon(Icons.warning_amber_outlined,
                        color: Colors.red, size: 20.sp),
                    SizedBox(width: 8.w),
                    Expanded(
                      child: Text(
                        'تجاوز حد الائتمان المسموح!',
                        style: TextStyle(
                          color: Colors.red[900],
                          fontSize: 12.sp,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildBalanceItem(String label, double amount, Color color) {
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12.sp,
            color: AppColors.textSecondary,
          ),
        ),
        SizedBox(height: 4.h),
        Text(
          '${amount.toStringAsFixed(2)} ر.س',
          style: TextStyle(
            fontSize: 16.sp,
            fontWeight: FontWeight.bold,
            color: amount > 0 ? color : AppColors.textSecondary,
          ),
        ),
      ],
    );
  }

  Widget _buildStatsCard(CustomerEntity customer) {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(16.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'الإحصائيات',
              style: TextStyle(
                fontSize: 14.sp,
                fontWeight: FontWeight.w500,
                color: AppColors.textSecondary,
              ),
            ),
            SizedBox(height: 12.h),
            Row(
              children: [
                Expanded(
                  child: _buildStatItem(
                    Icons.receipt_long_outlined,
                    'عدد الفواتير',
                    customer.invoicesCount.toString(),
                  ),
                ),
                Expanded(
                  child: _buildStatItem(
                    Icons.shopping_cart_outlined,
                    'إجمالي المشتريات',
                    '${customer.totalPurchases.toStringAsFixed(0)} ر.س',
                  ),
                ),
              ],
            ),
            SizedBox(height: 12.h),
            Row(
              children: [
                Expanded(
                  child: _buildStatItem(
                    Icons.payments_outlined,
                    'إجمالي المدفوعات',
                    '${customer.totalPayments.toStringAsFixed(0)} ر.س',
                  ),
                ),
                Expanded(
                  child: _buildStatItem(
                    Icons.calendar_today_outlined,
                    'آخر شراء',
                    customer.lastPurchaseDate != null
                        ? _formatDate(customer.lastPurchaseDate!)
                        : 'لا يوجد',
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 20.sp, color: AppColors.primary),
        SizedBox(width: 8.w),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 10.sp,
                  color: AppColors.textSecondary,
                ),
              ),
              Text(
                value,
                style: TextStyle(
                  fontSize: 12.sp,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildQuickActions(BuildContext context, CustomerEntity customer) {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(16.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'إجراءات سريعة',
              style: TextStyle(
                fontSize: 14.sp,
                fontWeight: FontWeight.w500,
                color: AppColors.textSecondary,
              ),
            ),
            SizedBox(height: 12.h),
            Row(
              children: [
                Expanded(
                  child: _buildActionButton(
                    context,
                    Icons.add_shopping_cart_outlined,
                    'فاتورة جديدة',
                    () => context.push('/sales/new?customerId=${customer.id}'),
                  ),
                ),
                SizedBox(width: 12.w),
                Expanded(
                  child: _buildActionButton(
                    context,
                    Icons.receipt_long_outlined,
                    'كشف حساب',
                    () => context.push('/customers/${customer.id}/statement'),
                  ),
                ),
              ],
            ),
            SizedBox(height: 12.h),
            Row(
              children: [
                Expanded(
                  child: _buildActionButton(
                    context,
                    Icons.payment_outlined,
                    'سند قبض',
                    () => context
                        .push('/payments/receipt?customerId=${customer.id}'),
                  ),
                ),
                SizedBox(width: 12.w),
                Expanded(
                  child: _buildActionButton(
                    context,
                    Icons.history_outlined,
                    'سجل المعاملات',
                    () =>
                        context.push('/customers/${customer.id}/transactions'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton(
    BuildContext context,
    IconData icon,
    String label,
    VoidCallback onPressed,
  ) {
    return OutlinedButton(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        padding: EdgeInsets.symmetric(vertical: 12.h),
      ),
      child: Column(
        children: [
          Icon(icon, size: 24.sp),
          SizedBox(height: 4.h),
          Text(label, style: TextStyle(fontSize: 12.sp)),
        ],
      ),
    );
  }

  Widget _buildTypeChip(CustomerType type) {
    String label;
    Color color;
    switch (type) {
      case CustomerType.regular:
        label = 'عادي';
        color = Colors.grey;
        break;
      case CustomerType.vip:
        label = 'VIP';
        color = Colors.amber;
        break;
      case CustomerType.wholesale:
        label = 'تاجر جملة';
        color = Colors.blue;
        break;
    }
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(4.r),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10.sp,
          color: color,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Color _getTypeColor(CustomerType type) {
    switch (type) {
      case CustomerType.regular:
        return Colors.grey;
      case CustomerType.vip:
        return Colors.amber;
      case CustomerType.wholesale:
        return Colors.blue;
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}
