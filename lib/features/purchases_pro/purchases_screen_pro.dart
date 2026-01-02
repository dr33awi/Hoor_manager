// ═══════════════════════════════════════════════════════════════════════════
// Professional Purchases Screen
// Purchase Orders Management
// ═══════════════════════════════════════════════════════════════════════════

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:hoor_manager/core/theme/design_tokens.dart';
import 'package:hoor_manager/core/widgets/widgets.dart';
import 'package:intl/intl.dart';

import '../dashboard_pro/widgets/pro_navigation_drawer.dart';
import '../../core/providers/app_providers.dart';
import '../../data/database/app_database.dart';

class PurchasesScreenPro extends ConsumerStatefulWidget {
  const PurchasesScreenPro({super.key});

  @override
  ConsumerState<PurchasesScreenPro> createState() => _PurchasesScreenProState();
}

class _PurchasesScreenProState extends ConsumerState<PurchasesScreenPro>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _searchController.addListener(() {
      setState(() => _searchQuery = _searchController.text);
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final invoicesAsync = ref.watch(purchaseInvoicesProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      drawer: const ProNavigationDrawer(currentRoute: '/purchases'),
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            invoicesAsync.when(
              loading: () => const SizedBox.shrink(),
              error: (_, __) => const SizedBox.shrink(),
              data: (invoices) => _buildStatsRow(invoices),
            ),
            _buildTabBar(),
            Expanded(
              child: invoicesAsync.when(
                loading: () => ProLoadingState.list(),
                error: (error, _) =>
                    ProEmptyState.error(error: error.toString()),
                data: (invoices) => _buildOrdersList(invoices),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/invoices/add/purchase'),
        backgroundColor: AppColors.primary,
        icon: const Icon(Icons.add, color: Colors.white),
        label: Text(
          'فاتورة شراء جديدة',
          style: AppTypography.labelLarge.copyWith(color: Colors.white),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: AppShadows.sm,
      ),
      child: Column(
        children: [
          Row(
            children: [
              Builder(
                builder: (context) => IconButton(
                  onPressed: () => Scaffold.of(context).openDrawer(),
                  icon: const Icon(Icons.menu),
                ),
              ),
              SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('المشتريات', style: AppTypography.titleLarge),
                    Text(
                      'إدارة طلبات الشراء',
                      style: AppTypography.bodySmall.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: () {},
                icon: const Icon(Icons.filter_list),
              ),
              IconButton(
                onPressed: () {},
                icon: const Icon(Icons.download),
              ),
            ],
          ),
          SizedBox(height: AppSpacing.md),
          // Search Bar
          Container(
            height: 48.h,
            decoration: BoxDecoration(
              color: AppColors.surfaceVariant,
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'البحث عن طلب شراء...',
                hintStyle: AppTypography.bodyMedium.copyWith(
                  color: AppColors.textTertiary,
                ),
                prefixIcon: const Icon(Icons.search),
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(
                  horizontal: AppSpacing.md,
                  vertical: AppSpacing.sm,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsRow(List<Invoice> invoices) {
    final total = invoices.fold(0.0, (sum, inv) => sum + inv.total);
    final thisMonth = invoices.where((inv) {
      final now = DateTime.now();
      return inv.invoiceDate.month == now.month &&
          inv.invoiceDate.year == now.year;
    }).fold(0.0, (sum, inv) => sum + inv.total);
    final pendingCount = invoices
        .where((inv) => inv.status == 'pending' || inv.status == 'partial')
        .length;

    return Container(
      padding: EdgeInsets.all(AppSpacing.md),
      child: Row(
        children: [
          _buildMiniStat(
            'إجمالي المشتريات',
            total.toStringAsFixed(0),
            'ر.س',
            Icons.shopping_cart,
            AppColors.primary,
            0,
          ),
          SizedBox(width: AppSpacing.md),
          _buildMiniStat(
            'هذا الشهر',
            thisMonth.toStringAsFixed(0),
            'ر.س',
            Icons.calendar_month,
            AppColors.info,
            1,
          ),
          SizedBox(width: AppSpacing.md),
          _buildMiniStat(
            'طلبات معلقة',
            '$pendingCount',
            '',
            Icons.pending_actions,
            AppColors.warning,
            2,
          ),
        ],
      ),
    );
  }

  Widget _buildMiniStat(String title, String value, String suffix,
      IconData icon, Color color, int index) {
    return Expanded(
      child: Container(
        padding: EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(AppRadius.md),
          boxShadow: AppShadows.sm,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 20.sp),
            SizedBox(height: AppSpacing.sm),
            Text(
              title,
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            Row(
              children: [
                Text(
                  value,
                  style: AppTypography.titleMedium.copyWith(
                    fontFamily: 'JetBrains Mono',
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (suffix.isNotEmpty)
                  Text(
                    ' $suffix',
                    style: AppTypography.bodySmall.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(color: AppColors.border),
        ),
      ),
      child: TabBar(
        controller: _tabController,
        labelColor: AppColors.primary,
        unselectedLabelColor: AppColors.textSecondary,
        indicatorColor: AppColors.primary,
        indicatorWeight: 3,
        labelStyle:
            AppTypography.labelMedium.copyWith(fontWeight: FontWeight.w600),
        tabs: const [
          Tab(text: 'الكل'),
          Tab(text: 'معلقة'),
          Tab(text: 'مكتملة'),
          Tab(text: 'ملغاة'),
        ],
      ),
    );
  }

  Widget _buildOrdersList(List<Invoice> invoices) {
    // Filter based on search query
    var filtered = invoices.where((inv) {
      if (_searchQuery.isEmpty) return true;
      return inv.invoiceNumber
          .toLowerCase()
          .contains(_searchQuery.toLowerCase());
    }).toList();

    return TabBarView(
      controller: _tabController,
      children: [
        _buildList(filtered),
        _buildList(filtered
            .where((o) => o.status == 'pending' || o.status == 'partial')
            .toList()),
        _buildList(filtered
            .where((o) => o.status == 'completed' || o.status == 'paid')
            .toList()),
        _buildList(filtered.where((o) => o.status == 'cancelled').toList()),
      ],
    );
  }

  Widget _buildList(List<Invoice> orders) {
    if (orders.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.inbox_outlined,
              size: 64.sp,
              color: AppColors.textTertiary,
            ),
            SizedBox(height: AppSpacing.md),
            Text(
              'لا توجد طلبات',
              style: AppTypography.titleMedium.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: EdgeInsets.all(AppSpacing.md),
      itemCount: orders.length,
      itemBuilder: (context, index) {
        final invoice = orders[index];
        return _PurchaseOrderCard(
          invoice: invoice,
          supplierNameFuture: _getSupplierName(invoice.supplierId),
          onTap: () => context.push('/invoices/${invoice.id}'),
        );
      },
    );
  }

  Future<String> _getSupplierName(String? supplierId) async {
    if (supplierId == null) return 'غير محدد';
    try {
      final supplierRepo = ref.read(supplierRepositoryProvider);
      final supplier = await supplierRepo.getSupplierById(supplierId);
      return supplier?.name ?? 'غير محدد';
    } catch (_) {
      return 'غير محدد';
    }
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// Purchase Order Card
// ═══════════════════════════════════════════════════════════════════════════

class _PurchaseOrderCard extends StatelessWidget {
  final Invoice invoice;
  final Future<String> supplierNameFuture;
  final VoidCallback onTap;

  const _PurchaseOrderCard({
    required this.invoice,
    required this.supplierNameFuture,
    required this.onTap,
  });

  Color get _statusColor {
    switch (invoice.status) {
      case 'completed':
      case 'paid':
        return AppColors.success;
      case 'pending':
        return AppColors.warning;
      case 'partial':
        return AppColors.info;
      case 'cancelled':
        return AppColors.error;
      default:
        return AppColors.textSecondary;
    }
  }

  String get _statusText {
    switch (invoice.status) {
      case 'completed':
      case 'paid':
        return 'مكتمل';
      case 'pending':
        return 'معلق';
      case 'partial':
        return 'جزئي';
      case 'cancelled':
        return 'ملغي';
      default:
        return invoice.status;
    }
  }

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('dd/MM/yyyy');

    return Container(
      margin: EdgeInsets.only(bottom: AppSpacing.md),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        boxShadow: AppShadows.sm,
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          child: Padding(
            padding: EdgeInsets.all(AppSpacing.md),
            child: Column(
              children: [
                Row(
                  children: [
                    // Supplier Icon
                    Container(
                      width: 48.w,
                      height: 48.h,
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(AppRadius.md),
                      ),
                      child: Icon(
                        Icons.local_shipping_outlined,
                        color: AppColors.primary,
                        size: 24.sp,
                      ),
                    ),
                    SizedBox(width: AppSpacing.md),
                    // Order Info
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            invoice.invoiceNumber,
                            style: AppTypography.titleSmall.copyWith(
                              fontFamily: 'JetBrains Mono',
                            ),
                          ),
                          FutureBuilder<String>(
                            future: supplierNameFuture,
                            builder: (context, snapshot) {
                              return Text(
                                snapshot.data ?? '...',
                                style: AppTypography.bodyMedium.copyWith(
                                  color: AppColors.textSecondary,
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                    // Status Badge
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: AppSpacing.sm,
                        vertical: AppSpacing.xs,
                      ),
                      decoration: BoxDecoration(
                        color: _statusColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(AppRadius.full),
                      ),
                      child: Text(
                        _statusText,
                        style: AppTypography.labelSmall.copyWith(
                          color: _statusColor,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: AppSpacing.md),
                Divider(height: 1, color: AppColors.border),
                SizedBox(height: AppSpacing.md),
                Row(
                  children: [
                    _buildInfoItem(
                      Icons.calendar_today,
                      dateFormat.format(invoice.invoiceDate),
                    ),
                    SizedBox(width: AppSpacing.lg),
                    _buildInfoItem(
                      Icons.inventory_2,
                      'فاتورة شراء',
                    ),
                    const Spacer(),
                    Text(
                      '${invoice.total.toStringAsFixed(2)} ر.س',
                      style: AppTypography.titleMedium.copyWith(
                        fontFamily: 'JetBrains Mono',
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInfoItem(IconData icon, String text) {
    return Row(
      children: [
        Icon(
          icon,
          size: 16.sp,
          color: AppColors.textTertiary,
        ),
        SizedBox(width: AppSpacing.xs),
        Text(
          text,
          style: AppTypography.bodySmall.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }
}
