/// ═══════════════════════════════════════════════════════════════════════════
/// Stock Transfer Screen - Redesigned
/// Modern Stock Transfer Interface
/// ═══════════════════════════════════════════════════════════════════════════
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/di/injection.dart';
import '../../../../data/database/app_database.dart';
import '../../../../data/repositories/warehouse_repository.dart';

class StockTransferScreenRedesign extends ConsumerStatefulWidget {
  const StockTransferScreenRedesign({super.key});

  @override
  ConsumerState<StockTransferScreenRedesign> createState() =>
      _StockTransferScreenRedesignState();
}

class _StockTransferScreenRedesignState
    extends ConsumerState<StockTransferScreenRedesign>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _warehouseRepo = getIt<WarehouseRepository>();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: HoorColors.background,
      appBar: AppBar(
        backgroundColor: HoorColors.surface,
        title: Text('نقل المخزون', style: HoorTypography.headlineSmall),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.pop(),
        ),
        actions: [
          IconButton(
            icon: Container(
              padding: EdgeInsets.all(HoorSpacing.xs.w),
              decoration: BoxDecoration(
                color: HoorColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(HoorRadius.sm),
              ),
              child: Icon(Icons.add_rounded, color: HoorColors.primary),
            ),
            onPressed: () => context.push('/inventory/transfer/new'),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: Size.fromHeight(48.h),
          child: Container(
            margin: EdgeInsets.symmetric(horizontal: HoorSpacing.md.w),
            decoration: BoxDecoration(
              color: HoorColors.background,
              borderRadius: BorderRadius.circular(HoorRadius.md),
            ),
            child: TabBar(
              controller: _tabController,
              indicatorSize: TabBarIndicatorSize.tab,
              indicator: BoxDecoration(
                color: HoorColors.primary,
                borderRadius: BorderRadius.circular(HoorRadius.md),
              ),
              labelColor: Colors.white,
              unselectedLabelColor: HoorColors.textSecondary,
              labelStyle: HoorTypography.labelMedium,
              tabs: const [
                Tab(text: 'معلقة'),
                Tab(text: 'السجل'),
              ],
            ),
          ),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _PendingTransfersTab(warehouseRepo: _warehouseRepo),
          _TransferHistoryTab(warehouseRepo: _warehouseRepo),
        ],
      ),
    );
  }
}

/// ═══════════════════════════════════════════════════════════════════════════
/// Pending Transfers Tab
/// ═══════════════════════════════════════════════════════════════════════════
class _PendingTransfersTab extends StatelessWidget {
  final WarehouseRepository warehouseRepo;

  const _PendingTransfersTab({required this.warehouseRepo});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<StockTransfer>>(
      stream: warehouseRepo.watchPendingTransfers(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(color: HoorColors.primary),
          );
        }

        final transfers = snapshot.data ?? [];

        if (transfers.isEmpty) {
          return _buildEmptyState(context);
        }

        return ListView.builder(
          padding: EdgeInsets.all(HoorSpacing.md.w),
          itemCount: transfers.length,
          itemBuilder: (context, index) {
            final transfer = transfers[index];
            return _TransferCard(
              transfer: transfer,
              warehouseRepo: warehouseRepo,
            );
          },
        );
      },
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: EdgeInsets.all(HoorSpacing.lg.w),
            decoration: BoxDecoration(
              color: HoorColors.warning.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.swap_horiz_rounded,
                size: 64, color: HoorColors.warning),
          ),
          SizedBox(height: HoorSpacing.lg.h),
          Text(
            'لا توجد عمليات نقل معلقة',
            style: HoorTypography.titleLarge.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: HoorSpacing.xs.h),
          Text(
            'أنشئ عملية نقل جديدة',
            style: HoorTypography.bodyMedium.copyWith(
              color: HoorColors.textSecondary,
            ),
          ),
          SizedBox(height: HoorSpacing.lg.h),
          ElevatedButton.icon(
            onPressed: () => context.push('/inventory/transfer/new'),
            icon: const Icon(Icons.add_rounded, color: Colors.white),
            label: Text('إنشاء نقل جديد',
                style: HoorTypography.labelLarge.copyWith(color: Colors.white)),
            style: ElevatedButton.styleFrom(
              backgroundColor: HoorColors.primary,
              padding: EdgeInsets.symmetric(
                horizontal: HoorSpacing.lg.w,
                vertical: HoorSpacing.sm.h,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(HoorRadius.md),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// ═══════════════════════════════════════════════════════════════════════════
/// Transfer History Tab
/// ═══════════════════════════════════════════════════════════════════════════
class _TransferHistoryTab extends StatelessWidget {
  final WarehouseRepository warehouseRepo;

  const _TransferHistoryTab({required this.warehouseRepo});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<StockTransfer>>(
      stream: warehouseRepo.watchAllTransfers(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(color: HoorColors.primary),
          );
        }

        final transfers =
            (snapshot.data ?? []).where((t) => t.status != 'pending').toList();

        if (transfers.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.history_rounded,
                    size: 64, color: HoorColors.textSecondary),
                SizedBox(height: HoorSpacing.md.h),
                Text(
                  'لا يوجد سجل نقل',
                  style: HoorTypography.titleMedium.copyWith(
                    color: HoorColors.textSecondary,
                  ),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: EdgeInsets.all(HoorSpacing.md.w),
          itemCount: transfers.length,
          itemBuilder: (context, index) {
            final transfer = transfers[index];
            return _TransferCard(
              transfer: transfer,
              warehouseRepo: warehouseRepo,
            );
          },
        );
      },
    );
  }
}

/// ═══════════════════════════════════════════════════════════════════════════
/// Transfer Card
/// ═══════════════════════════════════════════════════════════════════════════
class _TransferCard extends StatelessWidget {
  final StockTransfer transfer;
  final WarehouseRepository warehouseRepo;

  const _TransferCard({
    required this.transfer,
    required this.warehouseRepo,
  });

  Color _getStatusColor() {
    switch (transfer.status) {
      case 'pending':
        return HoorColors.warning;
      case 'completed':
        return HoorColors.success;
      case 'cancelled':
        return HoorColors.error;
      default:
        return HoorColors.textSecondary;
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
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(bottom: HoorSpacing.sm.h),
      decoration: BoxDecoration(
        color: HoorColors.surface,
        borderRadius: BorderRadius.circular(HoorRadius.lg),
        border: Border.all(color: HoorColors.border),
      ),
      child: InkWell(
        onTap: () => context.push('/inventory/transfer/${transfer.id}'),
        borderRadius: BorderRadius.circular(HoorRadius.lg),
        child: Padding(
          padding: EdgeInsets.all(HoorSpacing.md.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Row
              Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(HoorSpacing.xs.w),
                    decoration: BoxDecoration(
                      color: _getStatusColor().withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(HoorRadius.sm),
                    ),
                    child: Icon(Icons.swap_horiz_rounded,
                        color: _getStatusColor(), size: 20),
                  ),
                  SizedBox(width: HoorSpacing.sm.w),
                  Expanded(
                    child: Text(
                      transfer.transferNumber,
                      style: HoorTypography.titleMedium.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: HoorSpacing.sm.w,
                      vertical: HoorSpacing.xxs.h,
                    ),
                    decoration: BoxDecoration(
                      color: _getStatusColor().withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(HoorRadius.full),
                    ),
                    child: Text(
                      _getStatusText(),
                      style: HoorTypography.labelSmall.copyWith(
                        color: _getStatusColor(),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: HoorSpacing.md.h),

              // Warehouses
              FutureBuilder<List<Warehouse>>(
                future: Future.wait([
                  warehouseRepo.getWarehouseById(transfer.fromWarehouseId),
                  warehouseRepo.getWarehouseById(transfer.toWarehouseId),
                ]).then(
                    (warehouses) => warehouses.whereType<Warehouse>().toList()),
                builder: (context, snapshot) {
                  final warehouses = snapshot.data ?? [];
                  final fromName =
                      warehouses.isNotEmpty ? warehouses[0].name : '---';
                  final toName =
                      warehouses.length > 1 ? warehouses[1].name : '---';

                  return Container(
                    padding: EdgeInsets.all(HoorSpacing.sm.w),
                    decoration: BoxDecoration(
                      color: HoorColors.background,
                      borderRadius: BorderRadius.circular(HoorRadius.md),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Text(
                                'من',
                                style: HoorTypography.labelSmall.copyWith(
                                  color: HoorColors.textSecondary,
                                ),
                              ),
                              SizedBox(height: HoorSpacing.xxs.h),
                              Text(
                                fromName,
                                style: HoorTypography.bodyMedium.copyWith(
                                  fontWeight: FontWeight.w500,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: EdgeInsets.all(HoorSpacing.xs.w),
                          decoration: BoxDecoration(
                            color: HoorColors.primary.withValues(alpha: 0.1),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(Icons.arrow_forward_rounded,
                              color: HoorColors.primary, size: 16),
                        ),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Text(
                                'إلى',
                                style: HoorTypography.labelSmall.copyWith(
                                  color: HoorColors.textSecondary,
                                ),
                              ),
                              SizedBox(height: HoorSpacing.xxs.h),
                              Text(
                                toName,
                                style: HoorTypography.bodyMedium.copyWith(
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
              SizedBox(height: HoorSpacing.sm.h),

              // Footer
              Row(
                children: [
                  Icon(Icons.calendar_today_rounded,
                      size: 14, color: HoorColors.textSecondary),
                  SizedBox(width: HoorSpacing.xxs.w),
                  Text(
                    DateFormat('yyyy/MM/dd - HH:mm')
                        .format(transfer.transferDate),
                    style: HoorTypography.labelSmall.copyWith(
                      color: HoorColors.textSecondary,
                    ),
                  ),
                  const Spacer(),
                  Icon(Icons.chevron_left_rounded,
                      color: HoorColors.textSecondary, size: 20),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// ═══════════════════════════════════════════════════════════════════════════
/// New Stock Transfer Screen
/// ═══════════════════════════════════════════════════════════════════════════
class NewStockTransferScreenRedesign extends ConsumerStatefulWidget {
  const NewStockTransferScreenRedesign({super.key});

  @override
  ConsumerState<NewStockTransferScreenRedesign> createState() =>
      _NewStockTransferScreenRedesignState();
}

class _NewStockTransferScreenRedesignState
    extends ConsumerState<NewStockTransferScreenRedesign> {
  final _warehouseRepo = getIt<WarehouseRepository>();
  Warehouse? _fromWarehouse;
  Warehouse? _toWarehouse;
  final List<Map<String, dynamic>> _items = [];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: HoorColors.background,
      appBar: AppBar(
        backgroundColor: HoorColors.surface,
        title: Text('نقل جديد', style: HoorTypography.headlineSmall),
        leading: IconButton(
          icon: const Icon(Icons.close_rounded),
          onPressed: () => context.pop(),
        ),
        actions: [
          TextButton.icon(
            onPressed: _items.isEmpty ? null : _submitTransfer,
            icon: Icon(Icons.check_rounded,
                color: _items.isEmpty
                    ? HoorColors.textTertiary
                    : HoorColors.primary),
            label: Text(
              'تأكيد',
              style: HoorTypography.labelLarge.copyWith(
                color: _items.isEmpty
                    ? HoorColors.textTertiary
                    : HoorColors.primary,
              ),
            ),
          ),
        ],
      ),
      body: ListView(
        padding: EdgeInsets.all(HoorSpacing.md.w),
        children: [
          // Warehouse Selection
          _buildWarehouseSelection(),
          SizedBox(height: HoorSpacing.lg.h),

          // Items Section
          _buildItemsSection(),
        ],
      ),
    );
  }

  Widget _buildWarehouseSelection() {
    return Container(
      padding: EdgeInsets.all(HoorSpacing.md.w),
      decoration: BoxDecoration(
        color: HoorColors.surface,
        borderRadius: BorderRadius.circular(HoorRadius.lg),
        border: Border.all(color: HoorColors.border),
      ),
      child: StreamBuilder<List<Warehouse>>(
        stream: _warehouseRepo.watchActiveWarehouses(),
        builder: (context, snapshot) {
          final warehouses = snapshot.data ?? [];

          return Row(
            children: [
              Expanded(
                child: _WarehouseDropdown(
                  label: 'من المستودع',
                  value: _fromWarehouse,
                  warehouses: warehouses,
                  onChanged: (w) => setState(() => _fromWarehouse = w),
                ),
              ),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: HoorSpacing.md.w),
                child: Container(
                  padding: EdgeInsets.all(HoorSpacing.xs.w),
                  decoration: BoxDecoration(
                    color: HoorColors.primary.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.arrow_forward_rounded,
                      color: HoorColors.primary, size: 20),
                ),
              ),
              Expanded(
                child: _WarehouseDropdown(
                  label: 'إلى المستودع',
                  value: _toWarehouse,
                  warehouses: warehouses,
                  onChanged: (w) => setState(() => _toWarehouse = w),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildItemsSection() {
    return Container(
      decoration: BoxDecoration(
        color: HoorColors.surface,
        borderRadius: BorderRadius.circular(HoorRadius.lg),
        border: Border.all(color: HoorColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.all(HoorSpacing.md.w),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'المنتجات',
                  style: HoorTypography.titleMedium.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                TextButton.icon(
                  onPressed: _addItem,
                  icon: Icon(Icons.add_rounded, color: HoorColors.primary),
                  label: Text(
                    'إضافة',
                    style: HoorTypography.labelMedium.copyWith(
                      color: HoorColors.primary,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Divider(color: HoorColors.border, height: 1),
          if (_items.isEmpty)
            Padding(
              padding: EdgeInsets.all(HoorSpacing.xl.w),
              child: Center(
                child: Text(
                  'لم تتم إضافة منتجات بعد',
                  style: HoorTypography.bodyMedium.copyWith(
                    color: HoorColors.textSecondary,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  void _addItem() {
    // TODO: Show product picker
  }

  void _submitTransfer() {
    // TODO: Submit transfer
  }
}

class _WarehouseDropdown extends StatelessWidget {
  final String label;
  final Warehouse? value;
  final List<Warehouse> warehouses;
  final ValueChanged<Warehouse?> onChanged;

  const _WarehouseDropdown({
    required this.label,
    required this.value,
    required this.warehouses,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: HoorTypography.labelSmall.copyWith(
            color: HoorColors.textSecondary,
          ),
        ),
        SizedBox(height: HoorSpacing.xs.h),
        Container(
          padding: EdgeInsets.symmetric(horizontal: HoorSpacing.sm.w),
          decoration: BoxDecoration(
            border: Border.all(color: HoorColors.border),
            borderRadius: BorderRadius.circular(HoorRadius.md),
          ),
          child: DropdownButton<Warehouse>(
            value: value,
            isExpanded: true,
            underline: const SizedBox(),
            hint: Text('اختر', style: HoorTypography.bodyMedium),
            items: warehouses.map((w) {
              return DropdownMenuItem(
                value: w,
                child: Text(w.name, style: HoorTypography.bodyMedium),
              );
            }).toList(),
            onChanged: onChanged,
          ),
        ),
      ],
    );
  }
}
