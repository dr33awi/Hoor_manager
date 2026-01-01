// ═══════════════════════════════════════════════════════════════════════════
// Professional Purchases Screen
// Purchase Orders Management
// ═══════════════════════════════════════════════════════════════════════════

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/design_tokens.dart';
import '../../core/animations/pro_animations.dart';
import '../../core/widgets/pro_navigation_drawer.dart';

class PurchasesScreenPro extends ConsumerStatefulWidget {
  const PurchasesScreenPro({super.key});

  @override
  ConsumerState<PurchasesScreenPro> createState() => _PurchasesScreenProState();
}

class _PurchasesScreenProState extends ConsumerState<PurchasesScreenPro>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  // Sample data
  final List<_PurchaseOrder> _orders = [
    _PurchaseOrder(
      id: 'PO-2024-001',
      supplierName: 'شركة الأغذية المتحدة',
      date: DateTime.now(),
      total: 15750.0,
      status: 'completed',
      itemsCount: 25,
    ),
    _PurchaseOrder(
      id: 'PO-2024-002',
      supplierName: 'مؤسسة المشروبات',
      date: DateTime.now().subtract(const Duration(days: 1)),
      total: 8500.0,
      status: 'pending',
      itemsCount: 12,
    ),
    _PurchaseOrder(
      id: 'PO-2024-003',
      supplierName: 'مصنع المعجنات',
      date: DateTime.now().subtract(const Duration(days: 2)),
      total: 3200.0,
      status: 'partial',
      itemsCount: 8,
    ),
    _PurchaseOrder(
      id: 'PO-2024-004',
      supplierName: 'شركة الألبان الطازجة',
      date: DateTime.now().subtract(const Duration(days: 3)),
      total: 5600.0,
      status: 'cancelled',
      itemsCount: 15,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      drawer: const ProNavigationDrawer(currentRoute: '/purchases'),
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            _buildStatsRow(),
            _buildTabBar(),
            Expanded(child: _buildOrdersList()),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/purchases/add'),
        backgroundColor: AppColors.primary,
        icon: const Icon(Icons.add, color: Colors.white),
        label: Text(
          'طلب شراء جديد',
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

  Widget _buildStatsRow() {
    return Container(
      padding: EdgeInsets.all(AppSpacing.md),
      child: Row(
        children: [
          _buildMiniStat(
            'إجمالي المشتريات',
            '33,050',
            'ر.س',
            Icons.shopping_cart,
            AppColors.primary,
            0,
          ),
          SizedBox(width: AppSpacing.md),
          _buildMiniStat(
            'هذا الشهر',
            '24,250',
            'ر.س',
            Icons.calendar_month,
            AppColors.info,
            1,
          ),
          SizedBox(width: AppSpacing.md),
          _buildMiniStat(
            'طلبات معلقة',
            '3',
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
      child: StaggeredListAnimation(
        index: index,
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

  Widget _buildOrdersList() {
    return TabBarView(
      controller: _tabController,
      children: [
        _buildList(_orders),
        _buildList(_orders.where((o) => o.status == 'pending').toList()),
        _buildList(_orders.where((o) => o.status == 'completed').toList()),
        _buildList(_orders.where((o) => o.status == 'cancelled').toList()),
      ],
    );
  }

  Widget _buildList(List<_PurchaseOrder> orders) {
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
        return StaggeredListAnimation(
          index: index,
          child: _PurchaseOrderCard(
            order: orders[index],
            onTap: () => context.push('/purchases/${orders[index].id}'),
          ),
        );
      },
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// Purchase Order Card
// ═══════════════════════════════════════════════════════════════════════════

class _PurchaseOrderCard extends StatelessWidget {
  final _PurchaseOrder order;
  final VoidCallback onTap;

  const _PurchaseOrderCard({
    required this.order,
    required this.onTap,
  });

  Color get _statusColor {
    switch (order.status) {
      case 'completed':
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
    switch (order.status) {
      case 'completed':
        return 'مكتمل';
      case 'pending':
        return 'معلق';
      case 'partial':
        return 'جزئي';
      case 'cancelled':
        return 'ملغي';
      default:
        return order.status;
    }
  }

  @override
  Widget build(BuildContext context) {
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
                            order.id,
                            style: AppTypography.titleSmall.copyWith(
                              fontFamily: 'JetBrains Mono',
                            ),
                          ),
                          Text(
                            order.supplierName,
                            style: AppTypography.bodyMedium.copyWith(
                              color: AppColors.textSecondary,
                            ),
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
                      '${order.date.day}/${order.date.month}/${order.date.year}',
                    ),
                    SizedBox(width: AppSpacing.lg),
                    _buildInfoItem(
                      Icons.inventory_2,
                      '${order.itemsCount} صنف',
                    ),
                    const Spacer(),
                    Text(
                      '${order.total.toStringAsFixed(2)} ر.س',
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

// ═══════════════════════════════════════════════════════════════════════════
// Data Model
// ═══════════════════════════════════════════════════════════════════════════

class _PurchaseOrder {
  final String id;
  final String supplierName;
  final DateTime date;
  final double total;
  final String status;
  final int itemsCount;

  _PurchaseOrder({
    required this.id,
    required this.supplierName,
    required this.date,
    required this.total,
    required this.status,
    required this.itemsCount,
  });
}
