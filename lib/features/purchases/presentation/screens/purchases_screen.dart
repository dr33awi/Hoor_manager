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
import '../providers/purchase_providers.dart';
import '../widgets/purchase_card.dart';
import '../widgets/purchase_stats_card.dart';

/// شاشة المشتريات
class PurchasesScreen extends ConsumerStatefulWidget {
  const PurchasesScreen({super.key});

  @override
  ConsumerState<PurchasesScreen> createState() => _PurchasesScreenState();
}

class _PurchasesScreenState extends ConsumerState<PurchasesScreen> {
  final _searchController = TextEditingController();
  PurchaseInvoiceStatus? _selectedStatus;
  PurchasePaymentStatus? _selectedPaymentStatus;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final purchasesAsync = ref.watch(purchasesProvider);
    final statsAsync = ref.watch(purchaseStatsProvider);

    return Scaffold(
      appBar: CustomAppBar(
        title: 'المشتريات',
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: _showFilterDialog,
            tooltip: 'فلترة',
          ),
        ],
      ),
      body: Column(
        children: [
          // إحصائيات المشتريات
          statsAsync.when(
            data: (stats) => PurchaseStatsCard(stats: stats),
            loading: () => const SizedBox.shrink(),
            error: (_, __) => const SizedBox.shrink(),
          ),

          // البحث
          Padding(
            padding: EdgeInsets.all(16.w),
            child: SearchField(
              controller: _searchController,
              hint: 'البحث برقم الفاتورة...',
              onChanged: (value) => setState(() {}),
            ),
          ),

          // الفلاتر النشطة
          if (_selectedStatus != null || _selectedPaymentStatus != null)
            _buildActiveFilters(),

          // قائمة الفواتير
          Expanded(
            child: purchasesAsync.when(
              data: (purchases) {
                final filtered = _filterPurchases(purchases);
                if (filtered.isEmpty) {
                  return EmptyStateWidget(
                    icon: Icons.shopping_cart_outlined,
                    message: 'لا توجد فواتير شراء',
                    description: 'اضغط على + لإنشاء فاتورة جديدة',
                  );
                }
                return ListView.builder(
                  padding: EdgeInsets.symmetric(horizontal: 16.w),
                  itemCount: filtered.length,
                  itemBuilder: (context, index) {
                    return PurchaseCard(
                      purchase: filtered[index],
                      onTap: () => _openPurchaseDetails(filtered[index]),
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
        onPressed: _createPurchase,
        backgroundColor: AppColors.primary,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildActiveFilters() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16.w),
      child: Wrap(
        spacing: 8.w,
        children: [
          if (_selectedStatus != null)
            Chip(
              label: Text(_getStatusLabel(_selectedStatus!)),
              onDeleted: () => setState(() => _selectedStatus = null),
              deleteIconColor: Colors.red,
            ),
          if (_selectedPaymentStatus != null)
            Chip(
              label: Text(_getPaymentStatusLabel(_selectedPaymentStatus!)),
              onDeleted: () => setState(() => _selectedPaymentStatus = null),
              deleteIconColor: Colors.red,
            ),
        ],
      ),
    );
  }

  List<PurchaseInvoiceEntity> _filterPurchases(
      List<PurchaseInvoiceEntity> purchases) {
    var filtered = purchases;

    // البحث
    final query = _searchController.text.toLowerCase();
    if (query.isNotEmpty) {
      filtered = filtered.where((p) {
        return p.invoiceNumber.toLowerCase().contains(query) ||
            (p.supplierName?.toLowerCase().contains(query) ?? false);
      }).toList();
    }

    // فلتر الحالة
    if (_selectedStatus != null) {
      filtered = filtered.where((p) => p.status == _selectedStatus).toList();
    }

    // فلتر حالة الدفع
    if (_selectedPaymentStatus != null) {
      filtered = filtered
          .where((p) => p.paymentStatus == _selectedPaymentStatus)
          .toList();
    }

    return filtered;
  }

  void _showFilterDialog() {
    showModalBottomSheet(
      context: context,
      builder: (context) => _FilterBottomSheet(
        selectedStatus: _selectedStatus,
        selectedPaymentStatus: _selectedPaymentStatus,
        onApply: (status, paymentStatus) {
          setState(() {
            _selectedStatus = status;
            _selectedPaymentStatus = paymentStatus;
          });
          Navigator.pop(context);
        },
      ),
    );
  }

  void _createPurchase() {
    context.push('/purchases/new');
  }

  void _openPurchaseDetails(PurchaseInvoiceEntity purchase) {
    context.push('/purchases/${purchase.id}');
  }

  String _getStatusLabel(PurchaseInvoiceStatus status) {
    switch (status) {
      case PurchaseInvoiceStatus.draft:
        return 'مسودة';
      case PurchaseInvoiceStatus.pending:
        return 'معلقة';
      case PurchaseInvoiceStatus.approved:
        return 'موافق عليها';
      case PurchaseInvoiceStatus.received:
        return 'تم الاستلام';
      case PurchaseInvoiceStatus.partiallyReceived:
        return 'استلام جزئي';
      case PurchaseInvoiceStatus.completed:
        return 'مكتملة';
      case PurchaseInvoiceStatus.cancelled:
        return 'ملغاة';
    }
  }

  String _getPaymentStatusLabel(PurchasePaymentStatus status) {
    switch (status) {
      case PurchasePaymentStatus.unpaid:
        return 'غير مدفوعة';
      case PurchasePaymentStatus.partiallyPaid:
        return 'مدفوعة جزئياً';
      case PurchasePaymentStatus.paid:
        return 'مدفوعة';
    }
  }
}

/// Bottom Sheet للفلترة
class _FilterBottomSheet extends StatefulWidget {
  final PurchaseInvoiceStatus? selectedStatus;
  final PurchasePaymentStatus? selectedPaymentStatus;
  final Function(PurchaseInvoiceStatus?, PurchasePaymentStatus?) onApply;

  const _FilterBottomSheet({
    this.selectedStatus,
    this.selectedPaymentStatus,
    required this.onApply,
  });

  @override
  State<_FilterBottomSheet> createState() => _FilterBottomSheetState();
}

class _FilterBottomSheetState extends State<_FilterBottomSheet> {
  PurchaseInvoiceStatus? _status;
  PurchasePaymentStatus? _paymentStatus;

  @override
  void initState() {
    super.initState();
    _status = widget.selectedStatus;
    _paymentStatus = widget.selectedPaymentStatus;
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.all(16.w),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'فلترة الفواتير',
            style: TextStyle(
              fontSize: 18.sp,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 16.h),

          // حالة الفاتورة
          Text('حالة الفاتورة', style: TextStyle(fontSize: 14.sp)),
          SizedBox(height: 8.h),
          Wrap(
            spacing: 8.w,
            children: PurchaseInvoiceStatus.values.map((status) {
              return FilterChip(
                label: Text(_getStatusLabel(status)),
                selected: _status == status,
                onSelected: (selected) {
                  setState(() => _status = selected ? status : null);
                },
              );
            }).toList(),
          ),
          SizedBox(height: 16.h),

          // حالة الدفع
          Text('حالة الدفع', style: TextStyle(fontSize: 14.sp)),
          SizedBox(height: 8.h),
          Wrap(
            spacing: 8.w,
            children: PurchasePaymentStatus.values.map((status) {
              return FilterChip(
                label: Text(_getPaymentStatusLabel(status)),
                selected: _paymentStatus == status,
                onSelected: (selected) {
                  setState(() => _paymentStatus = selected ? status : null);
                },
              );
            }).toList(),
          ),
          SizedBox(height: 24.h),

          // الأزرار
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () {
                    setState(() {
                      _status = null;
                      _paymentStatus = null;
                    });
                  },
                  child: const Text('مسح الكل'),
                ),
              ),
              SizedBox(width: 16.w),
              Expanded(
                child: ElevatedButton(
                  onPressed: () => widget.onApply(_status, _paymentStatus),
                  child: const Text('تطبيق'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _getStatusLabel(PurchaseInvoiceStatus status) {
    switch (status) {
      case PurchaseInvoiceStatus.draft:
        return 'مسودة';
      case PurchaseInvoiceStatus.pending:
        return 'معلقة';
      case PurchaseInvoiceStatus.approved:
        return 'موافق عليها';
      case PurchaseInvoiceStatus.received:
        return 'تم الاستلام';
      case PurchaseInvoiceStatus.partiallyReceived:
        return 'استلام جزئي';
      case PurchaseInvoiceStatus.completed:
        return 'مكتملة';
      case PurchaseInvoiceStatus.cancelled:
        return 'ملغاة';
    }
  }

  String _getPaymentStatusLabel(PurchasePaymentStatus status) {
    switch (status) {
      case PurchasePaymentStatus.unpaid:
        return 'غير مدفوعة';
      case PurchasePaymentStatus.partiallyPaid:
        return 'مدفوعة جزئياً';
      case PurchasePaymentStatus.paid:
        return 'مدفوعة';
    }
  }
}
