import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../core/theme/redesign/design_system.dart';
import '../../../../core/di/injection.dart';
import '../../../../core/services/sync_service.dart';
import '../../../../data/repositories/shift_repository.dart';
import '../../../widgets/sync_status_widget.dart';
import '../../../alerts/redesign/alerts_screen_redesign.dart';
import '../widgets/dashboard_widgets.dart';

/// ═══════════════════════════════════════════════════════════════════════════
/// Hoor Dashboard - Modern Redesign
/// Professional, Clean & Minimal Dashboard
/// ═══════════════════════════════════════════════════════════════════════════

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  final _syncService = getIt<SyncService>();
  final _shiftRepo = getIt<ShiftRepository>();

  int _selectedNavIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: HoorColors.background,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async => await _syncService.syncAll(),
          color: HoorColors.primary,
          child: StreamBuilder<bool>(
            stream: _shiftRepo.watchOpenShift().map((shift) => shift != null),
            initialData: false,
            builder: (context, snapshot) {
              final hasOpenShift = snapshot.data ?? false;
              return CustomScrollView(
                slivers: [
                  SliverToBoxAdapter(child: _buildHeader()),
                  SliverPadding(
                    padding: EdgeInsets.symmetric(horizontal: HoorSpacing.lg.w),
                    sliver: SliverList(
                      delegate: SliverChildListDelegate([
                        ShiftStatusCard(
                          hasOpenShift: hasOpenShift,
                          onTap: () => context.push('/shifts'),
                        ),
                        SizedBox(height: HoorSpacing.xl.h),
                        _buildQuickStats(),
                        SizedBox(height: HoorSpacing.xl.h),
                        _buildQuickActions(hasOpenShift),
                        SizedBox(height: HoorSpacing.xl.h),
                        _buildMainMenu(),
                        SizedBox(height: HoorSpacing.xxl.h),
                      ]),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: EdgeInsets.all(HoorSpacing.lg.w),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Hoor Manager',
                  style: HoorTypography.headlineMedium.copyWith(
                    color: HoorColors.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 4.h),
                Text(
                  'نظام إدارة الأعمال المتكامل',
                  style: HoorTypography.bodySmall.copyWith(
                    color: HoorColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          Row(
            children: [
              const AlertsButtonRedesign(),
              SizedBox(width: HoorSpacing.xs.w),
              const SyncStatusWidget(),
              SizedBox(width: HoorSpacing.xs.w),
              HeaderIconButton(
                icon: Icons.settings_outlined,
                onTap: () => context.push('/settings'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuickStats() {
    // TODO: Connect to actual data providers
    return Row(
      children: [
        Expanded(
          child: HoorStatCard(
            title: 'مبيعات اليوم',
            value: '0',
            subtitle: 'ر.س',
            icon: Icons.trending_up_rounded,
            color: HoorColors.income,
            onTap: () => context.push('/reports/sales'),
          ),
        ),
        SizedBox(width: HoorSpacing.md.w),
        Expanded(
          child: HoorStatCard(
            title: 'المشتريات',
            value: '0',
            subtitle: 'ر.س',
            icon: Icons.trending_down_rounded,
            color: HoorColors.expense,
            onTap: () => context.push('/reports/purchases'),
          ),
        ),
      ],
    );
  }

  Widget _buildQuickActions(bool hasOpenShift) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        HoorSectionHeader(
          title: 'إجراءات سريعة',
          icon: Icons.flash_on_rounded,
        ),
        SizedBox(height: HoorSpacing.md.h),
        Row(
          children: [
            Expanded(
              child: QuickActionCard(
                icon: Icons.point_of_sale_rounded,
                label: 'فاتورة مبيعات',
                color: HoorColors.sales,
                onTap: () => context.push('/invoices/new/sale'),
              ),
            ),
            SizedBox(width: HoorSpacing.sm.w),
            Expanded(
              child: QuickActionCard(
                icon: Icons.shopping_cart_rounded,
                label: 'فاتورة مشتريات',
                color: HoorColors.purchases,
                onTap: () => context.push('/invoices/new/purchase'),
              ),
            ),
            SizedBox(width: HoorSpacing.sm.w),
            Expanded(
              child: QuickActionCard(
                icon: Icons.assignment_return_rounded,
                label: 'مرتجعات',
                color: HoorColors.returns,
                onTap: () => context.push('/invoices/new/sale_return'),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildMainMenu() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Sales & Invoices Section
        MenuGroup(
          title: 'المبيعات والفواتير',
          icon: Icons.shopping_bag_rounded,
          items: [
            MenuItemCard(
              icon: Icons.receipt_long_rounded,
              label: 'الفواتير',
              subtitle: 'عرض وإدارة الفواتير',
              color: HoorColors.sales,
              onTap: () => context.push('/invoices'),
            ),
            MenuItemCard(
              icon: Icons.people_rounded,
              label: 'العملاء',
              subtitle: 'إدارة بيانات العملاء',
              color: HoorColors.info,
              onTap: () => context.push('/customers'),
            ),
            MenuItemCard(
              icon: Icons.local_shipping_rounded,
              label: 'الموردين',
              subtitle: 'إدارة بيانات الموردين',
              color: HoorColors.purchases,
              onTap: () => context.push('/suppliers'),
            ),
          ],
        ),
        SizedBox(height: HoorSpacing.xl.h),

        // Inventory Section
        MenuGroup(
          title: 'المخزون والمنتجات',
          icon: Icons.inventory_rounded,
          items: [
            MenuItemCard(
              icon: Icons.inventory_2_rounded,
              label: 'المنتجات',
              subtitle: 'إدارة قائمة المنتجات',
              color: HoorColors.primary,
              onTap: () => context.push('/products'),
            ),
            MenuItemCard(
              icon: Icons.category_rounded,
              label: 'التصنيفات',
              subtitle: 'تنظيم وتصنيف المواد',
              color: HoorColors.accent,
              onTap: () => context.push('/categories'),
            ),
            MenuItemCard(
              icon: Icons.warehouse_rounded,
              label: 'المخزون',
              subtitle: 'متابعة حركة المخزون',
              color: HoorColors.inventory,
              onTap: () => context.push('/inventory'),
            ),
          ],
        ),
        SizedBox(height: HoorSpacing.xl.h),

        // Finance Section
        MenuGroup(
          title: 'المالية والتقارير',
          icon: Icons.account_balance_rounded,
          items: [
            MenuItemCard(
              icon: Icons.access_time_rounded,
              label: 'الورديات',
              subtitle: 'إدارة فترات العمل',
              color: HoorColors.textSecondary,
              onTap: () => context.push('/shifts'),
            ),
            MenuItemCard(
              icon: Icons.account_balance_wallet_rounded,
              label: 'الصندوق',
              subtitle: 'حركة النقدية اليومية',
              color: HoorColors.income,
              onTap: () => context.push('/cash'),
            ),
            MenuItemCard(
              icon: Icons.receipt_rounded,
              label: 'السندات',
              subtitle: 'قبض ودفع ومصاريف',
              color: HoorColors.warning,
              onTap: () => context.push('/vouchers'),
            ),
            MenuItemCard(
              icon: Icons.bar_chart_rounded,
              label: 'التقارير',
              subtitle: 'تقارير وإحصائيات شاملة',
              color: HoorColors.success,
              onTap: () => context.push('/reports'),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildBottomNav() {
    return HoorBottomNav(
      currentIndex: _selectedNavIndex,
      onTap: (index) {
        switch (index) {
          case 0:
            if (_selectedNavIndex != 0) setState(() => _selectedNavIndex = 0);
            break;
          case 1:
            context.push('/invoices');
            break;
          case 2:
            context.push('/products');
            break;
          case 3:
            context.push('/reports');
            break;
          case 4:
            context.push('/settings');
            break;
        }
      },
      items: [
        HoorBottomNavItem(
          icon: Icons.dashboard_outlined,
          activeIcon: Icons.dashboard,
          label: 'الرئيسية',
        ),
        HoorBottomNavItem(
          icon: Icons.receipt_long_outlined,
          activeIcon: Icons.receipt_long,
          label: 'الفواتير',
        ),
        HoorBottomNavItem(
          icon: Icons.inventory_2_outlined,
          activeIcon: Icons.inventory_2,
          label: 'المنتجات',
        ),
        HoorBottomNavItem(
          icon: Icons.bar_chart_outlined,
          activeIcon: Icons.bar_chart,
          label: 'التقارير',
        ),
        HoorBottomNavItem(
          icon: Icons.settings_outlined,
          activeIcon: Icons.settings,
          label: 'الإعدادات',
        ),
      ],
    );
  }
}
