import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:hoor_manager/core/constants/app_colors.dart';

import '../../../../core/widgets/app_bar_widget.dart';
import '../../../../core/widgets/empty_state_widget.dart';
import '../../../../core/widgets/loading_widget.dart';
import '../../../../core/widgets/search_field.dart';
import '../../domain/entities/entities.dart';
import '../providers/customer_providers.dart';
import '../widgets/customer_card.dart';
import '../widgets/customer_stats_card.dart';

/// شاشة العملاء
class CustomersScreen extends ConsumerStatefulWidget {
  const CustomersScreen({super.key});

  @override
  ConsumerState<CustomersScreen> createState() => _CustomersScreenState();
}

class _CustomersScreenState extends ConsumerState<CustomersScreen> {
  final _searchController = TextEditingController();
  CustomerType? _selectedType;
  bool _showOnlyWithDues = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final customersAsync = ref.watch(customersProvider);
    final stats = ref.watch(customerStatsProvider);

    return Scaffold(
      appBar: CustomAppBar(
        title: 'العملاء',
        actions: [
          IconButton(
            icon: const Icon(Icons.file_download_outlined),
            onPressed: _exportToExcel,
            tooltip: 'تصدير Excel',
          ),
          IconButton(
            icon: const Icon(Icons.file_upload_outlined),
            onPressed: _importFromExcel,
            tooltip: 'استيراد Excel',
          ),
        ],
      ),
      body: Column(
        children: [
          // إحصائيات العملاء
          CustomerStatsCard(stats: stats),

          // البحث والفلترة
          Padding(
            padding: EdgeInsets.all(16.w),
            child: Column(
              children: [
                SearchField(
                  controller: _searchController,
                  hint: 'البحث بالاسم أو الهاتف...',
                  onChanged: (value) => setState(() {}),
                ),
                SizedBox(height: 12.h),
                _buildFilters(),
              ],
            ),
          ),

          // قائمة العملاء
          Expanded(
            child: customersAsync.when(
              data: (customers) {
                final filtered = _filterCustomers(customers);
                if (filtered.isEmpty) {
                  return EmptyStateWidget(
                    icon: Icons.people_outline,
                    message: 'لا يوجد عملاء',
                    description: 'اضغط على + لإضافة عميل جديد',
                  );
                }
                return ListView.builder(
                  padding: EdgeInsets.symmetric(horizontal: 16.w),
                  itemCount: filtered.length,
                  itemBuilder: (context, index) {
                    return CustomerCard(
                      customer: filtered[index],
                      onTap: () => _openCustomerDetails(filtered[index]),
                      onEdit: () => _editCustomer(filtered[index]),
                      onDelete: () => _deleteCustomer(filtered[index]),
                    );
                  },
                );
              },
              loading: () => const LoadingWidget(),
              error: (error, _) => Center(child: Text('خطأ: $error')),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addCustomer,
        backgroundColor: AppColors.primary,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildFilters() {
    return Row(
      children: [
        // فلتر النوع
        Expanded(
          child: DropdownButtonFormField<CustomerType?>(
            value: _selectedType,
            decoration: InputDecoration(
              labelText: 'النوع',
              contentPadding:
                  EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8.r),
              ),
            ),
            items: [
              const DropdownMenuItem(value: null, child: Text('الكل')),
              const DropdownMenuItem(
                value: CustomerType.regular,
                child: Text('عادي'),
              ),
              const DropdownMenuItem(
                value: CustomerType.vip,
                child: Text('VIP'),
              ),
              const DropdownMenuItem(
                value: CustomerType.wholesale,
                child: Text('تاجر جملة'),
              ),
            ],
            onChanged: (value) => setState(() => _selectedType = value),
          ),
        ),
        SizedBox(width: 12.w),
        // فلتر المستحقات
        FilterChip(
          label: const Text('عليهم مستحقات'),
          selected: _showOnlyWithDues,
          onSelected: (value) => setState(() => _showOnlyWithDues = value),
        ),
      ],
    );
  }

  List<CustomerEntity> _filterCustomers(List<CustomerEntity> customers) {
    var filtered = customers;

    // البحث
    final query = _searchController.text.toLowerCase();
    if (query.isNotEmpty) {
      filtered = filtered.where((c) {
        return c.name.toLowerCase().contains(query) ||
            (c.phone?.contains(query) ?? false);
      }).toList();
    }

    // فلتر النوع
    if (_selectedType != null) {
      filtered = filtered.where((c) => c.type == _selectedType).toList();
    }

    // فلتر المستحقات
    if (_showOnlyWithDues) {
      filtered = filtered.where((c) => c.amountDue > 0).toList();
    }

    return filtered;
  }

  void _addCustomer() {
    context.push('/customers/add');
  }

  void _openCustomerDetails(CustomerEntity customer) {
    context.push('/customers/${customer.id}');
  }

  void _editCustomer(CustomerEntity customer) {
    context.push('/customers/${customer.id}/edit');
  }

  Future<void> _deleteCustomer(CustomerEntity customer) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('حذف العميل'),
        content: Text('هل أنت متأكد من حذف "${customer.name}"؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('إلغاء'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('حذف'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final notifier = ref.read(customerNotifierProvider.notifier);
      final success = await notifier.deleteCustomer(customer.id);
      if (mounted && success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تم حذف العميل بنجاح')),
        );
      }
    }
  }

  Future<void> _exportToExcel() async {
    final notifier = ref.read(customerNotifierProvider.notifier);
    final filePath = await notifier.exportToExcel();
    if (mounted && filePath != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('تم تصدير الملف: $filePath')),
      );
    }
  }

  Future<void> _importFromExcel() async {
    // TODO: Implement file picker
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('قريباً: استيراد من Excel')),
    );
  }
}
