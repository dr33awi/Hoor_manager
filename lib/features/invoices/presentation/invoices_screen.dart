import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gap/gap.dart';
import 'package:intl/intl.dart';

import '../../../core/di/injection.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/constants/app_constants.dart';
import '../../../data/database/app_database.dart';
import '../../../data/repositories/invoice_repository.dart';

class InvoicesScreen extends ConsumerStatefulWidget {
  final String? type;

  const InvoicesScreen({super.key, this.type});

  @override
  ConsumerState<InvoicesScreen> createState() => _InvoicesScreenState();
}

class _InvoicesScreenState extends ConsumerState<InvoicesScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  final _tabs = [
    {'type': null, 'label': 'الكل'},
    {'type': 'sale', 'label': 'المبيعات'},
    {'type': 'purchase', 'label': 'المشتريات'},
    {'type': 'sale_return', 'label': 'مرتجع مبيعات'},
    {'type': 'purchase_return', 'label': 'مرتجع مشتريات'},
  ];

  @override
  void initState() {
    super.initState();
    int initialIndex = 0;
    if (widget.type != null) {
      initialIndex = _tabs.indexWhere((t) => t['type'] == widget.type);
      if (initialIndex < 0) initialIndex = 0;
    }
    _tabController = TabController(
        length: _tabs.length, vsync: this, initialIndex: initialIndex);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('الفواتير'),
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabs: _tabs.map((t) => Tab(text: t['label'] as String)).toList(),
        ),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.add),
            onSelected: (value) => context.push('/invoices/new/$value'),
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'sale',
                child: Row(
                  children: [
                    Icon(Icons.point_of_sale, color: AppColors.sales),
                    SizedBox(width: 8),
                    Text('فاتورة مبيعات'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'purchase',
                child: Row(
                  children: [
                    Icon(Icons.shopping_cart, color: AppColors.purchases),
                    SizedBox(width: 8),
                    Text('فاتورة مشتريات'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'sale_return',
                child: Row(
                  children: [
                    Icon(Icons.assignment_return, color: AppColors.returns),
                    SizedBox(width: 8),
                    Text('مرتجع مبيعات'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'purchase_return',
                child: Row(
                  children: [
                    Icon(Icons.assignment_returned, color: AppColors.returns),
                    SizedBox(width: 8),
                    Text('مرتجع مشتريات'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'opening_balance',
                child: Row(
                  children: [
                    Icon(Icons.inventory, color: AppColors.inventory),
                    SizedBox(width: 8),
                    Text('فاتورة أول المدة'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: TabBarView(
        controller: _tabController,
        children: _tabs.map((tab) => _InvoicesList(type: tab['type'])).toList(),
      ),
    );
  }
}

class _InvoicesList extends StatelessWidget {
  final String? type;
  final _invoiceRepo = getIt<InvoiceRepository>();

  _InvoicesList({required this.type});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<Invoice>>(
      stream: _invoiceRepo.watchAllInvoices(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        var invoices = snapshot.data ?? [];

        if (type != null) {
          invoices = invoices.where((i) => i.type == type).toList();
        }

        if (invoices.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.receipt_long_outlined,
                  size: 64.sp,
                  color: Colors.grey,
                ),
                Gap(16.h),
                Text(
                  'لا توجد فواتير',
                  style: TextStyle(
                    fontSize: 18.sp,
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: EdgeInsets.all(16.w),
          itemCount: invoices.length,
          itemBuilder: (context, index) {
            final invoice = invoices[index];
            return _InvoiceCard(
              invoice: invoice,
              onTap: () => context.push('/invoices/${invoice.id}'),
            );
          },
        );
      },
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
    final typeInfo = _getTypeInfo(invoice.type);
    final dateFormat = DateFormat('dd/MM/yyyy HH:mm');

    return Card(
      margin: EdgeInsets.only(bottom: 8.h),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12.r),
        child: Padding(
          padding: EdgeInsets.all(12.w),
          child: Row(
            children: [
              // Type Icon
              Container(
                padding: EdgeInsets.all(10.w),
                decoration: BoxDecoration(
                  color: typeInfo['color'].withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8.r),
                ),
                child: Icon(
                  typeInfo['icon'],
                  color: typeInfo['color'],
                  size: 24.sp,
                ),
              ),
              Gap(12.w),

              // Invoice Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            invoice.invoiceNumber,
                            style: TextStyle(
                              fontSize: 14.sp,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 8.w,
                            vertical: 2.h,
                          ),
                          decoration: BoxDecoration(
                            color: typeInfo['color'].withOpacity(0.1),
                            borderRadius: BorderRadius.circular(4.r),
                          ),
                          child: Text(
                            typeInfo['label'],
                            style: TextStyle(
                              fontSize: 10.sp,
                              color: typeInfo['color'],
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                    Gap(4.h),
                    Text(
                      dateFormat.format(invoice.invoiceDate),
                      style: TextStyle(
                        fontSize: 12.sp,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    Gap(4.h),
                    Row(
                      children: [
                        Text(
                          '${invoice.total.toStringAsFixed(2)} ل.س',
                          style: TextStyle(
                            fontSize: 16.sp,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primary,
                          ),
                        ),
                        Gap(8.w),
                        Text(
                          InvoiceType.values
                              .firstWhere(
                                  (e) => e.value == invoice.paymentMethod,
                                  orElse: () => InvoiceType.sale)
                              .label,
                          style: TextStyle(
                            fontSize: 12.sp,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              Icon(
                Icons.chevron_left,
                color: AppColors.textSecondary,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Map<String, dynamic> _getTypeInfo(String type) {
    switch (type) {
      case 'sale':
        return {
          'icon': Icons.point_of_sale,
          'color': AppColors.sales,
          'label': 'مبيعات'
        };
      case 'purchase':
        return {
          'icon': Icons.shopping_cart,
          'color': AppColors.purchases,
          'label': 'مشتريات'
        };
      case 'sale_return':
        return {
          'icon': Icons.assignment_return,
          'color': AppColors.returns,
          'label': 'مرتجع مبيعات'
        };
      case 'purchase_return':
        return {
          'icon': Icons.assignment_returned,
          'color': AppColors.returns,
          'label': 'مرتجع مشتريات'
        };
      case 'opening_balance':
        return {
          'icon': Icons.inventory,
          'color': AppColors.inventory,
          'label': 'أول المدة'
        };
      default:
        return {
          'icon': Icons.receipt,
          'color': AppColors.primary,
          'label': 'فاتورة'
        };
    }
  }
}
