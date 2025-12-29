import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gap/gap.dart';
import 'package:intl/intl.dart';
import 'package:go_router/go_router.dart';

import '../../../core/di/injection.dart';
import '../../../core/theme/app_colors.dart';
import '../../../data/database/app_database.dart';
import '../../../data/repositories/supplier_repository.dart';

class SuppliersScreen extends ConsumerStatefulWidget {
  const SuppliersScreen({super.key});

  @override
  ConsumerState<SuppliersScreen> createState() => _SuppliersScreenState();
}

class _SuppliersScreenState extends ConsumerState<SuppliersScreen> {
  final _supplierRepo = getIt<SupplierRepository>();
  final _database = getIt<AppDatabase>();
  final _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('الموردين'),
      ),
      body: Column(
        children: [
          // Search Bar
          Padding(
            padding: EdgeInsets.all(16.w),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'بحث عن مورد...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _searchQuery = '');
                        },
                      )
                    : null,
              ),
              onChanged: (value) => setState(() => _searchQuery = value),
            ),
          ),

          // Suppliers List
          Expanded(
            child: StreamBuilder<List<Supplier>>(
              stream: _supplierRepo.watchAllSuppliers(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                var suppliers = snapshot.data ?? [];

                if (_searchQuery.isNotEmpty) {
                  suppliers = suppliers
                      .where((s) =>
                          s.name
                              .toLowerCase()
                              .contains(_searchQuery.toLowerCase()) ||
                          (s.phone?.contains(_searchQuery) ?? false))
                      .toList();
                }

                if (suppliers.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.local_shipping_outlined,
                          size: 64.sp,
                          color: Colors.grey,
                        ),
                        Gap(16.h),
                        Text(
                          'لا يوجد موردين',
                          style: TextStyle(
                            fontSize: 16.sp,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: EdgeInsets.symmetric(horizontal: 16.w),
                  itemCount: suppliers.length,
                  itemBuilder: (context, index) {
                    final supplier = suppliers[index];
                    return _SupplierCard(
                      supplier: supplier,
                      onTap: () => _showSupplierDetails(supplier),
                      onEdit: () => _showSupplierDialog(supplier),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showSupplierDialog(null),
        child: const Icon(Icons.add),
      ),
    );
  }

  void _showSupplierDialog(Supplier? supplier) {
    final nameController = TextEditingController(text: supplier?.name);
    final phoneController = TextEditingController(text: supplier?.phone);
    final emailController = TextEditingController(text: supplier?.email);
    final addressController = TextEditingController(text: supplier?.address);
    final notesController = TextEditingController(text: supplier?.notes);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(supplier == null ? 'إضافة مورد' : 'تعديل مورد'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'اسم المورد *',
                  prefixIcon: Icon(Icons.business),
                ),
              ),
              Gap(12.h),
              TextField(
                controller: phoneController,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(
                  labelText: 'رقم الهاتف',
                  prefixIcon: Icon(Icons.phone),
                ),
              ),
              Gap(12.h),
              TextField(
                controller: emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                  labelText: 'البريد الإلكتروني',
                  prefixIcon: Icon(Icons.email),
                ),
              ),
              Gap(12.h),
              TextField(
                controller: addressController,
                maxLines: 2,
                decoration: const InputDecoration(
                  labelText: 'العنوان',
                  prefixIcon: Icon(Icons.location_on),
                ),
              ),
              Gap(12.h),
              TextField(
                controller: notesController,
                maxLines: 2,
                decoration: const InputDecoration(
                  labelText: 'ملاحظات',
                  prefixIcon: Icon(Icons.note),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (nameController.text.isEmpty) return;

              Navigator.pop(context);

              if (supplier == null) {
                await _supplierRepo.createSupplier(
                  name: nameController.text,
                  phone: phoneController.text.isEmpty
                      ? null
                      : phoneController.text,
                  email: emailController.text.isEmpty
                      ? null
                      : emailController.text,
                  address: addressController.text.isEmpty
                      ? null
                      : addressController.text,
                  notes: notesController.text.isEmpty
                      ? null
                      : notesController.text,
                );
              } else {
                await _supplierRepo.updateSupplier(
                  id: supplier.id,
                  name: nameController.text,
                  phone: phoneController.text.isEmpty
                      ? null
                      : phoneController.text,
                  email: emailController.text.isEmpty
                      ? null
                      : emailController.text,
                  address: addressController.text.isEmpty
                      ? null
                      : addressController.text,
                  notes: notesController.text.isEmpty
                      ? null
                      : notesController.text,
                );
              }
            },
            child: Text(supplier == null ? 'إضافة' : 'حفظ'),
          ),
        ],
      ),
    );
  }

  void _showSupplierDetails(Supplier supplier) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (context, scrollController) => Container(
          padding: EdgeInsets.all(16.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Handle bar
              Center(
                child: Container(
                  width: 40.w,
                  height: 4.h,
                  margin: EdgeInsets.only(bottom: 16.h),
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2.r),
                  ),
                ),
              ),
              // Supplier Info Header
              Row(
                children: [
                  CircleAvatar(
                    radius: 30.r,
                    backgroundColor: AppColors.suppliers.withOpacity(0.2),
                    child: Icon(
                      Icons.local_shipping,
                      color: AppColors.suppliers,
                      size: 28.sp,
                    ),
                  ),
                  Gap(16.w),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          supplier.name,
                          style: TextStyle(
                            fontSize: 20.sp,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (supplier.phone != null)
                          Text(
                            supplier.phone!,
                            style: TextStyle(color: AppColors.textSecondary),
                          ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.edit),
                    onPressed: () {
                      Navigator.pop(context);
                      _showSupplierDialog(supplier);
                    },
                  ),
                ],
              ),
              Gap(16.h),

              // Supplier Summary
              FutureBuilder<Map<String, double>>(
                future: _database.getSupplierSummary(supplier.id),
                builder: (context, snapshot) {
                  final summary = snapshot.data ?? {};
                  return Row(
                    children: [
                      Expanded(
                        child: _SummaryItem(
                          label: 'إجمالي المشتريات',
                          value:
                              '${(summary['totalPurchases'] ?? 0).toStringAsFixed(0)} ل.س',
                          color: AppColors.primary,
                        ),
                      ),
                      Gap(8.w),
                      Expanded(
                        child: _SummaryItem(
                          label: 'المرتجعات',
                          value:
                              '${(summary['totalReturns'] ?? 0).toStringAsFixed(0)} ل.س',
                          color: AppColors.warning,
                        ),
                      ),
                      Gap(8.w),
                      Expanded(
                        child: _SummaryItem(
                          label: 'عدد الفواتير',
                          value:
                              '${(summary['invoiceCount'] ?? 0).toStringAsFixed(0)}',
                          color: AppColors.success,
                        ),
                      ),
                    ],
                  );
                },
              ),
              Gap(16.h),

              // Contact Info
              if (supplier.email != null || supplier.address != null) ...[
                if (supplier.email != null)
                  _DetailRow(
                      icon: Icons.email,
                      label: 'البريد',
                      value: supplier.email!),
                if (supplier.address != null)
                  _DetailRow(
                      icon: Icons.location_on,
                      label: 'العنوان',
                      value: supplier.address!),
                Gap(8.h),
              ],

              _DetailRow(
                icon: Icons.account_balance_wallet,
                label: 'المستحق',
                value: '${supplier.balance.toStringAsFixed(0)} ل.س',
                valueColor:
                    supplier.balance >= 0 ? AppColors.success : AppColors.error,
              ),

              if (supplier.notes != null)
                _DetailRow(
                    icon: Icons.note, label: 'ملاحظات', value: supplier.notes!),

              Gap(16.h),
              Divider(),
              Gap(8.h),

              // Invoices Section
              Text(
                'فواتير المورد',
                style: TextStyle(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Gap(8.h),

              // Invoices List
              Expanded(
                child: StreamBuilder<List<Invoice>>(
                  stream: _database.watchInvoicesBySupplier(supplier.id),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    final invoices = snapshot.data ?? [];

                    if (invoices.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.receipt_long,
                              size: 48.sp,
                              color: Colors.grey,
                            ),
                            Gap(8.h),
                            Text(
                              'لا توجد فواتير',
                              style: TextStyle(color: Colors.grey),
                            ),
                          ],
                        ),
                      );
                    }

                    return ListView.builder(
                      controller: scrollController,
                      itemCount: invoices.length,
                      itemBuilder: (context, index) {
                        final invoice = invoices[index];
                        return _InvoiceCard(
                          invoice: invoice,
                          onTap: () {
                            Navigator.pop(context);
                            context.push('/invoices/${invoice.id}');
                          },
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SupplierCard extends StatelessWidget {
  final Supplier supplier;
  final VoidCallback onTap;
  final VoidCallback onEdit;

  const _SupplierCard({
    required this.supplier,
    required this.onTap,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.only(bottom: 8.h),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12.r),
        child: Padding(
          padding: EdgeInsets.all(12.w),
          child: Row(
            children: [
              CircleAvatar(
                backgroundColor: AppColors.suppliers.withOpacity(0.2),
                child: Icon(
                  Icons.local_shipping,
                  color: AppColors.suppliers,
                ),
              ),
              Gap(12.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      supplier.name,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (supplier.phone != null)
                      Text(
                        supplier.phone!,
                        style: TextStyle(
                          fontSize: 12.sp,
                          color: AppColors.textSecondary,
                        ),
                      ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '${supplier.balance.toStringAsFixed(2)}',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: supplier.balance >= 0
                          ? AppColors.success
                          : AppColors.error,
                    ),
                  ),
                  Text(
                    'ل.س',
                    style: TextStyle(
                      fontSize: 10.sp,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color? valueColor;

  const _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8.h),
      child: Row(
        children: [
          Icon(icon, size: 20.sp, color: AppColors.textSecondary),
          Gap(12.w),
          Text(
            '$label:',
            style: TextStyle(color: AppColors.textSecondary),
          ),
          Gap(8.w),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontWeight: FontWeight.w500,
                color: valueColor,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SummaryItem extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _SummaryItem({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8.r),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: 14.sp,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Gap(4.h),
          Text(
            label,
            style: TextStyle(
              fontSize: 10.sp,
              color: AppColors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _InvoiceCard extends StatelessWidget {
  final Invoice invoice;
  final VoidCallback onTap;

  const _InvoiceCard({
    required this.invoice,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isReturn = invoice.type == 'purchase_return';
    final typeLabel = isReturn ? 'مرتجع مشتريات' : 'فاتورة شراء';
    final typeColor = isReturn ? AppColors.warning : AppColors.primary;

    return Card(
      margin: EdgeInsets.only(bottom: 8.h),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12.r),
        child: Padding(
          padding: EdgeInsets.all(12.w),
          child: Row(
            children: [
              Container(
                padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                decoration: BoxDecoration(
                  color: typeColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(4.r),
                ),
                child: Text(
                  typeLabel,
                  style: TextStyle(
                    fontSize: 10.sp,
                    color: typeColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Gap(12.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '#${invoice.invoiceNumber}',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      DateFormat('yyyy/MM/dd').format(invoice.invoiceDate),
                      style: TextStyle(
                        fontSize: 12.sp,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                '${invoice.total.toStringAsFixed(0)} ل.س',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: typeColor,
                ),
              ),
              Gap(8.w),
              Icon(
                Icons.arrow_forward_ios,
                size: 16.sp,
                color: AppColors.textSecondary,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
