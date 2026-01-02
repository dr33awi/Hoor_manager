// ═══════════════════════════════════════════════════════════════════════════
// Stock Transfer Screen Pro - Professional Design System
// Modern Stock Transfer Interface
// ═══════════════════════════════════════════════════════════════════════════

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../core/theme/design_tokens.dart';
import '../../core/providers/app_providers.dart';
import '../../core/widgets/widgets.dart';
import '../../data/database/app_database.dart';

class StockTransferScreenPro extends ConsumerStatefulWidget {
  const StockTransferScreenPro({super.key});

  @override
  ConsumerState<StockTransferScreenPro> createState() =>
      _StockTransferScreenProState();
}

class _StockTransferScreenProState extends ConsumerState<StockTransferScreenPro>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final transfersAsync = ref.watch(stockTransfersStreamProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            _buildTabBar(),
            Expanded(
              child: transfersAsync.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (error, _) => ProEmptyState.error(
                  error: error.toString(),
                  onRetry: () => ref.invalidate(stockTransfersStreamProvider),
                ),
                data: (transfers) => TabBarView(
                  controller: _tabController,
                  children: [
                    _buildTransfersList(
                        transfers.where((t) => t.status == 'pending').toList()),
                    _buildTransfersList(transfers
                        .where((t) => t.status == 'completed')
                        .toList()),
                    _buildTransfersList(transfers),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showNewTransferSheet(),
        backgroundColor: AppColors.secondary,
        icon: const Icon(Icons.swap_horiz_rounded, color: Colors.white),
        label: Text(
          'نقل جديد',
          style: AppTypography.labelLarge.copyWith(color: Colors.white),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return ProHeader(
      title: 'نقل المخزون',
      subtitle: 'نقل البضائع بين المستودعات',
      actions: [
        IconButton(
          onPressed: () => context.push('/inventory/warehouses'),
          icon: Icon(Icons.warehouse_outlined, color: AppColors.secondary),
          tooltip: 'المستودعات',
        ),
      ],
    );
  }

  Widget _buildTabBar() {
    return Container(
      margin: EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surfaceMuted,
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
      child: TabBar(
        controller: _tabController,
        labelColor: AppColors.textOnPrimary,
        unselectedLabelColor: AppColors.textSecondary,
        indicator: BoxDecoration(
          color: AppColors.secondary,
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
        indicatorSize: TabBarIndicatorSize.tab,
        dividerColor: Colors.transparent,
        tabs: const [
          Tab(text: 'معلقة'),
          Tab(text: 'مكتملة'),
          Tab(text: 'الكل'),
        ],
      ),
    );
  }

  Widget _buildTransfersList(List<StockTransfer> transfers) {
    if (transfers.isEmpty) {
      return ProEmptyState(
        icon: Icons.swap_horiz_rounded,
        iconColor: AppColors.warning,
        title: 'لا توجد عمليات نقل',
        message: 'أنشئ عملية نقل جديدة لنقل البضائع بين المستودعات',
      );
    }

    // Sort by date descending
    transfers.sort((a, b) => b.createdAt.compareTo(a.createdAt));

    return ListView.builder(
      padding: EdgeInsets.symmetric(horizontal: AppSpacing.md),
      itemCount: transfers.length,
      itemBuilder: (context, index) {
        return _TransferCard(
          transfer: transfers[index],
          onTap: () => _showTransferDetails(transfers[index]),
          onComplete: transfers[index].status == 'pending'
              ? () => _completeTransfer(transfers[index])
              : null,
          onCancel: transfers[index].status == 'pending'
              ? () => _cancelTransfer(transfers[index])
              : null,
        );
      },
    );
  }

  void _showNewTransferSheet() {
    final warehousesAsync = ref.read(warehousesStreamProvider);
    final productsAsync = ref.read(activeProductsStreamProvider);

    Warehouse? fromWarehouse;
    Warehouse? toWarehouse;
    Product? selectedProduct;
    final quantityController = TextEditingController();
    final notesController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setSheetState) => Container(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius:
                BorderRadius.vertical(top: Radius.circular(AppRadius.xl)),
          ),
          child: SingleChildScrollView(
            padding: EdgeInsets.all(AppSpacing.lg),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Handle
                Center(
                  child: Container(
                    width: 40.w,
                    height: 4.h,
                    decoration: BoxDecoration(
                      color: AppColors.border,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                SizedBox(height: AppSpacing.lg),

                // Title
                Row(
                  children: [
                    Container(
                      padding: EdgeInsets.all(AppSpacing.sm),
                      decoration: BoxDecoration(
                        color: AppColors.secondary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(AppRadius.md),
                      ),
                      child: Icon(Icons.swap_horiz_rounded,
                          color: AppColors.secondary),
                    ),
                    SizedBox(width: AppSpacing.md),
                    Text(
                      'نقل مخزون جديد',
                      style: AppTypography.titleLarge
                          .copyWith(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                SizedBox(height: AppSpacing.xl),

                // From Warehouse
                Text('من مستودع', style: AppTypography.labelLarge),
                SizedBox(height: AppSpacing.sm),
                warehousesAsync.when(
                  loading: () => const LinearProgressIndicator(),
                  error: (_, __) => const Text('خطأ في تحميل المستودعات'),
                  data: (warehouses) => Container(
                    padding: EdgeInsets.symmetric(horizontal: AppSpacing.md),
                    decoration: BoxDecoration(
                      border: Border.all(color: AppColors.border),
                      borderRadius: BorderRadius.circular(AppRadius.md),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<Warehouse>(
                        isExpanded: true,
                        value: fromWarehouse,
                        hint: const Text('اختر المستودع المصدر'),
                        items: warehouses
                            .where((w) => w != toWarehouse)
                            .map((w) => DropdownMenuItem(
                                  value: w,
                                  child: Text(w.name),
                                ))
                            .toList(),
                        onChanged: (value) =>
                            setSheetState(() => fromWarehouse = value),
                      ),
                    ),
                  ),
                ),
                SizedBox(height: AppSpacing.md),

                // To Warehouse
                Text('إلى مستودع', style: AppTypography.labelLarge),
                SizedBox(height: AppSpacing.sm),
                warehousesAsync.when(
                  loading: () => const LinearProgressIndicator(),
                  error: (_, __) => const Text('خطأ في تحميل المستودعات'),
                  data: (warehouses) => Container(
                    padding: EdgeInsets.symmetric(horizontal: AppSpacing.md),
                    decoration: BoxDecoration(
                      border: Border.all(color: AppColors.border),
                      borderRadius: BorderRadius.circular(AppRadius.md),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<Warehouse>(
                        isExpanded: true,
                        value: toWarehouse,
                        hint: const Text('اختر المستودع الهدف'),
                        items: warehouses
                            .where((w) => w != fromWarehouse)
                            .map((w) => DropdownMenuItem(
                                  value: w,
                                  child: Text(w.name),
                                ))
                            .toList(),
                        onChanged: (value) =>
                            setSheetState(() => toWarehouse = value),
                      ),
                    ),
                  ),
                ),
                SizedBox(height: AppSpacing.md),

                // Product
                Text('المنتج', style: AppTypography.labelLarge),
                SizedBox(height: AppSpacing.sm),
                productsAsync.when(
                  loading: () => const LinearProgressIndicator(),
                  error: (_, __) => const Text('خطأ في تحميل المنتجات'),
                  data: (products) => Container(
                    padding: EdgeInsets.symmetric(horizontal: AppSpacing.md),
                    decoration: BoxDecoration(
                      border: Border.all(color: AppColors.border),
                      borderRadius: BorderRadius.circular(AppRadius.md),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<Product>(
                        isExpanded: true,
                        value: selectedProduct,
                        hint: const Text('اختر المنتج'),
                        items: products
                            .map((p) => DropdownMenuItem(
                                  value: p,
                                  child:
                                      Text('${p.name} (${p.quantity} متوفر)'),
                                ))
                            .toList(),
                        onChanged: (value) =>
                            setSheetState(() => selectedProduct = value),
                      ),
                    ),
                  ),
                ),
                SizedBox(height: AppSpacing.md),

                // Quantity
                Text('الكمية', style: AppTypography.labelLarge),
                SizedBox(height: AppSpacing.sm),
                TextField(
                  controller: quantityController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    hintText: 'أدخل الكمية',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppRadius.md),
                    ),
                    prefixIcon: const Icon(Icons.numbers),
                  ),
                ),
                SizedBox(height: AppSpacing.md),

                // Notes
                Text('ملاحظات (اختياري)', style: AppTypography.labelLarge),
                SizedBox(height: AppSpacing.sm),
                TextField(
                  controller: notesController,
                  maxLines: 2,
                  decoration: InputDecoration(
                    hintText: 'أدخل ملاحظات',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppRadius.md),
                    ),
                    prefixIcon: const Icon(Icons.notes),
                  ),
                ),
                SizedBox(height: AppSpacing.xl),

                // Buttons
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(context),
                        style: OutlinedButton.styleFrom(
                          padding: EdgeInsets.all(AppSpacing.md),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(AppRadius.md),
                          ),
                        ),
                        child: const Text('إلغاء'),
                      ),
                    ),
                    SizedBox(width: AppSpacing.md),
                    Expanded(
                      flex: 2,
                      child: ElevatedButton(
                        onPressed: () => _createTransfer(
                          fromWarehouse: fromWarehouse,
                          toWarehouse: toWarehouse,
                          product: selectedProduct,
                          quantity: int.tryParse(quantityController.text) ?? 0,
                          notes: notesController.text,
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.secondary,
                          foregroundColor: Colors.white,
                          padding: EdgeInsets.all(AppSpacing.md),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(AppRadius.md),
                          ),
                        ),
                        child: const Text('إنشاء النقل'),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: AppSpacing.md),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _createTransfer({
    required Warehouse? fromWarehouse,
    required Warehouse? toWarehouse,
    required Product? product,
    required int quantity,
    required String notes,
  }) async {
    if (fromWarehouse == null ||
        toWarehouse == null ||
        product == null ||
        quantity <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('يرجى ملء جميع الحقول المطلوبة'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    try {
      final warehouseRepo = ref.read(warehouseRepositoryProvider);
      await warehouseRepo.createTransfer(
        fromWarehouseId: fromWarehouse.id,
        toWarehouseId: toWarehouse.id,
        items: [
          {
            'productId': product.id,
            'quantity': quantity,
            'notes': notes.isEmpty ? null : notes
          }
        ],
        notes: notes.isEmpty ? null : notes,
      );

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('تم إنشاء عملية النقل بنجاح'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('خطأ: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  void _showTransferDetails(StockTransfer transfer) {
    // Navigate to transfer details or show bottom sheet
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.xl)),
      ),
      builder: (context) => Padding(
        padding: EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40.w,
                height: 4.h,
                decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            SizedBox(height: AppSpacing.lg),
            Text('تفاصيل النقل', style: AppTypography.titleLarge),
            SizedBox(height: AppSpacing.md),
            _buildDetailRow('رقم العملية', transfer.transferNumber),
            _buildDetailRow('الحالة', _getStatusText(transfer.status)),
            _buildDetailRow(
              'التاريخ',
              DateFormat('yyyy/MM/dd HH:mm', 'ar').format(transfer.createdAt),
            ),
            if (transfer.notes != null)
              _buildDetailRow('ملاحظات', transfer.notes!),
            SizedBox(height: AppSpacing.lg),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: AppSpacing.xs),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: AppTypography.bodyMedium.copyWith(
                color: AppColors.textSecondary,
              )),
          Text(value,
              style: AppTypography.bodyMedium.copyWith(
                fontWeight: FontWeight.w600,
              )),
        ],
      ),
    );
  }

  String _getStatusText(String status) {
    switch (status) {
      case 'pending':
        return 'معلقة';
      case 'completed':
        return 'مكتملة';
      case 'cancelled':
        return 'ملغية';
      default:
        return status;
    }
  }

  Future<void> _completeTransfer(StockTransfer transfer) async {
    try {
      final warehouseRepo = ref.read(warehouseRepositoryProvider);
      await warehouseRepo.completeTransfer(transfer.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('تم إكمال النقل بنجاح'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('خطأ: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  Future<void> _cancelTransfer(StockTransfer transfer) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('تأكيد الإلغاء'),
        content: const Text('هل تريد إلغاء عملية النقل هذه؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('لا'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            child:
                const Text('نعم، إلغاء', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      final warehouseRepo = ref.read(warehouseRepositoryProvider);
      await warehouseRepo.cancelTransfer(transfer.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('تم إلغاء النقل'),
            backgroundColor: AppColors.warning,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('خطأ: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// Transfer Card Widget
// ═══════════════════════════════════════════════════════════════════════════

class _TransferCard extends ConsumerWidget {
  final StockTransfer transfer;
  final VoidCallback onTap;
  final VoidCallback? onComplete;
  final VoidCallback? onCancel;

  const _TransferCard({
    required this.transfer,
    required this.onTap,
    this.onComplete,
    this.onCancel,
  });

  Color _getStatusColor() {
    switch (transfer.status) {
      case 'pending':
        return AppColors.warning;
      case 'completed':
        return AppColors.success;
      case 'cancelled':
        return AppColors.error;
      default:
        return AppColors.textTertiary;
    }
  }

  String _getStatusText() {
    switch (transfer.status) {
      case 'pending':
        return 'معلقة';
      case 'completed':
        return 'مكتملة';
      case 'cancelled':
        return 'ملغية';
      default:
        return transfer.status;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final warehousesAsync = ref.watch(warehousesStreamProvider);
    final dateFormat = DateFormat('yyyy/MM/dd', 'ar');

    return Container(
      margin: EdgeInsets.only(bottom: AppSpacing.md.h),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.border),
        boxShadow: AppShadows.sm,
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        child: Padding(
          padding: EdgeInsets.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(AppSpacing.sm),
                    decoration: BoxDecoration(
                      color: _getStatusColor().withOpacity(0.1),
                      borderRadius: BorderRadius.circular(AppRadius.md),
                    ),
                    child: Icon(
                      Icons.swap_horiz_rounded,
                      color: _getStatusColor(),
                      size: 20.sp,
                    ),
                  ),
                  SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          transfer.transferNumber,
                          style: AppTypography.titleSmall.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          dateFormat.format(transfer.createdAt),
                          style: AppTypography.bodySmall.copyWith(
                            color: AppColors.textTertiary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: AppSpacing.sm,
                      vertical: 4.h,
                    ),
                    decoration: BoxDecoration(
                      color: _getStatusColor().withOpacity(0.1),
                      borderRadius: BorderRadius.circular(AppRadius.full),
                    ),
                    child: Text(
                      _getStatusText(),
                      style: AppTypography.labelSmall.copyWith(
                        color: _getStatusColor(),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: AppSpacing.md),

              // Warehouses Flow
              warehousesAsync.when(
                loading: () => const LinearProgressIndicator(),
                error: (_, __) => const SizedBox.shrink(),
                data: (warehouses) {
                  final fromWarehouse = warehouses.firstWhere(
                    (w) => w.id == transfer.fromWarehouseId,
                    orElse: () => Warehouse(
                      id: '',
                      name: '---',
                      isDefault: false,
                      isActive: true,
                      syncStatus: 'synced',
                      createdAt: DateTime.now(),
                      updatedAt: DateTime.now(),
                    ),
                  );
                  final toWarehouse = warehouses.firstWhere(
                    (w) => w.id == transfer.toWarehouseId,
                    orElse: () => Warehouse(
                      id: '',
                      name: '---',
                      isDefault: false,
                      isActive: true,
                      syncStatus: 'synced',
                      createdAt: DateTime.now(),
                      updatedAt: DateTime.now(),
                    ),
                  );

                  return Container(
                    padding: EdgeInsets.all(AppSpacing.sm),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceMuted,
                      borderRadius: BorderRadius.circular(AppRadius.md),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            children: [
                              Text(
                                'من',
                                style: AppTypography.labelSmall.copyWith(
                                  color: AppColors.textTertiary,
                                ),
                              ),
                              SizedBox(height: 2.h),
                              Text(
                                fromWarehouse.name,
                                style: AppTypography.bodyMedium.copyWith(
                                  fontWeight: FontWeight.w500,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: EdgeInsets.all(AppSpacing.xs),
                          decoration: BoxDecoration(
                            color: AppColors.secondary.withOpacity(0.1),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.arrow_forward_rounded,
                            color: AppColors.secondary,
                            size: 16.sp,
                          ),
                        ),
                        Expanded(
                          child: Column(
                            children: [
                              Text(
                                'إلى',
                                style: AppTypography.labelSmall.copyWith(
                                  color: AppColors.textTertiary,
                                ),
                              ),
                              SizedBox(height: 2.h),
                              Text(
                                toWarehouse.name,
                                style: AppTypography.bodyMedium.copyWith(
                                  fontWeight: FontWeight.w500,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
              SizedBox(height: AppSpacing.sm),

              // Quantity & Actions
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(Icons.inventory_2_outlined,
                          size: 16.sp, color: AppColors.textTertiary),
                      SizedBox(width: 4.w),
                      Text(
                        'عملية نقل',
                        style: AppTypography.bodySmall.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                  if (onComplete != null || onCancel != null)
                    Row(
                      children: [
                        if (onComplete != null)
                          TextButton.icon(
                            onPressed: onComplete,
                            icon: Icon(Icons.check_circle_outline,
                                size: 16.sp, color: AppColors.success),
                            label: Text(
                              'إكمال',
                              style: AppTypography.labelSmall.copyWith(
                                color: AppColors.success,
                              ),
                            ),
                          ),
                        if (onCancel != null)
                          TextButton.icon(
                            onPressed: onCancel,
                            icon: Icon(Icons.cancel_outlined,
                                size: 16.sp, color: AppColors.error),
                            label: Text(
                              'إلغاء',
                              style: AppTypography.labelSmall.copyWith(
                                color: AppColors.error,
                              ),
                            ),
                          ),
                      ],
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
