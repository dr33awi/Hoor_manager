import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/widgets/app_bar_widget.dart';
import '../../../../core/widgets/empty_state_widget.dart';
import '../../../../core/widgets/loading_widget.dart';
import '../../../../core/widgets/search_field.dart';
import '../../domain/entities/entities.dart';
import '../providers/supplier_providers.dart';
import '../widgets/supplier_card.dart';
import '../widgets/supplier_stats_card.dart';

/// شاشة الموردين
class SuppliersScreen extends ConsumerStatefulWidget {
  const SuppliersScreen({super.key});

  @override
  ConsumerState<SuppliersScreen> createState() => _SuppliersScreenState();
}

class _SuppliersScreenState extends ConsumerState<SuppliersScreen> {
  final _searchController = TextEditingController();
  SupplierRating? _selectedRating;
  bool _showOnlyWithDues = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final suppliersAsync = ref.watch(suppliersProvider);
    final stats = ref.watch(supplierStatsProvider);

    return Scaffold(
      appBar: CustomAppBar(
        title: 'الموردين',
        actions: [
          IconButton(
            icon: const Icon(Icons.file_download_outlined),
            onPressed: _exportToExcel,
            tooltip: 'تصدير Excel',
          ),
        ],
      ),
      body: Column(
        children: [
          // إحصائيات الموردين
          SupplierStatsCard(stats: stats),

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

          // قائمة الموردين
          Expanded(
            child: suppliersAsync.when(
              data: (suppliers) {
                final filtered = _filterSuppliers(suppliers);
                if (filtered.isEmpty) {
                  return EmptyStateWidget(
                    icon: Icons.local_shipping_outlined,
                    message: 'لا يوجد موردين',
                    description: 'اضغط على + لإضافة مورد جديد',
                  );
                }
                return ListView.builder(
                  padding: EdgeInsets.symmetric(horizontal: 16.w),
                  itemCount: filtered.length,
                  itemBuilder: (context, index) {
                    return SupplierCard(
                      supplier: filtered[index],
                      onTap: () => _openSupplierDetails(filtered[index]),
                      onEdit: () => _editSupplier(filtered[index]),
                      onDelete: () => _deleteSupplier(filtered[index]),
                    );
                  },
                );
              },
              loading: () => LoadingWidget(),
              error: (error, _) => Center(child: Text('خطأ: $error')),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addSupplier,
        backgroundColor: AppColors.primary,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildFilters() {
    return Row(
      children: [
        // فلتر التقييم
        Expanded(
          child: DropdownButtonFormField<SupplierRating?>(
            value: _selectedRating,
            decoration: InputDecoration(
              labelText: 'التقييم',
              contentPadding:
                  EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8.r),
              ),
            ),
            items: [
              const DropdownMenuItem(value: null, child: Text('الكل')),
              const DropdownMenuItem(
                value: SupplierRating.excellent,
                child: Text('ممتاز'),
              ),
              const DropdownMenuItem(
                value: SupplierRating.good,
                child: Text('جيد'),
              ),
              const DropdownMenuItem(
                value: SupplierRating.average,
                child: Text('متوسط'),
              ),
              const DropdownMenuItem(
                value: SupplierRating.poor,
                child: Text('ضعيف'),
              ),
            ],
            onChanged: (value) => setState(() => _selectedRating = value),
          ),
        ),
        SizedBox(width: 12.w),
        // فلتر المستحقات
        FilterChip(
          label: const Text('لهم مستحقات'),
          selected: _showOnlyWithDues,
          onSelected: (value) => setState(() => _showOnlyWithDues = value),
        ),
      ],
    );
  }

  List<SupplierEntity> _filterSuppliers(List<SupplierEntity> suppliers) {
    var filtered = suppliers;

    // البحث
    final query = _searchController.text.toLowerCase();
    if (query.isNotEmpty) {
      filtered = filtered.where((s) {
        return s.name.toLowerCase().contains(query) ||
            (s.phone?.contains(query) ?? false) ||
            (s.contactPerson?.toLowerCase().contains(query) ?? false);
      }).toList();
    }

    // فلتر التقييم
    if (_selectedRating != null) {
      filtered = filtered.where((s) => s.rating == _selectedRating).toList();
    }

    // فلتر المستحقات
    if (_showOnlyWithDues) {
      filtered = filtered.where((s) => s.amountDue > 0).toList();
    }

    return filtered;
  }

  void _addSupplier() {
    context.push('/suppliers/add');
  }

  void _openSupplierDetails(SupplierEntity supplier) {
    context.push('/suppliers/${supplier.id}');
  }

  void _editSupplier(SupplierEntity supplier) {
    context.push('/suppliers/${supplier.id}/edit');
  }

  Future<void> _deleteSupplier(SupplierEntity supplier) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('حذف المورد'),
        content: Text('هل أنت متأكد من حذف "${supplier.name}"؟'),
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
      final notifier = ref.read(supplierNotifierProvider.notifier);
      final success = await notifier.deleteSupplier(supplier.id);
      if (mounted && success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تم حذف المورد بنجاح')),
        );
      }
    }
  }

  Future<void> _exportToExcel() async {
    final notifier = ref.read(supplierNotifierProvider.notifier);
    final filePath = await notifier.exportToExcel();
    if (mounted && filePath != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('تم تصدير الملف: $filePath')),
      );
    }
  }
}
