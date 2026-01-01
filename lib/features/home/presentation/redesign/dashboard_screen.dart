import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../core/theme/redesign/design_system.dart';
import '../../../../core/di/injection.dart';
import '../../../../core/services/sync_service.dart';
import '../../../../data/repositories/shift_repository.dart';
import '../../../alerts/redesign/alerts_screen_redesign.dart';
import '../widgets/dashboard_widgets.dart';

/// ═══════════════════════════════════════════════════════════════════════════
/// Hoor Dashboard - Modern Premium Redesign
/// Professional, Clean & Minimal Dashboard with Glassmorphism
/// ═══════════════════════════════════════════════════════════════════════════

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen>
    with TickerProviderStateMixin {
  final _syncService = getIt<SyncService>();
  final _shiftRepo = getIt<ShiftRepository>();

  int _selectedNavIndex = 0;
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeOutCubic,
    );
    _fadeController.forward();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: HoorColors.background,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async => await _syncService.syncAll(),
          color: HoorColors.primary,
          backgroundColor: HoorColors.surface,
          child: StreamBuilder<bool>(
            stream: _shiftRepo.watchOpenShift().map((shift) => shift != null),
            initialData: false,
            builder: (context, snapshot) {
              final hasOpenShift = snapshot.data ?? false;
              return FadeTransition(
                opacity: _fadeAnimation,
                child: CustomScrollView(
                  physics: const BouncingScrollPhysics(),
                  slivers: [
                    SliverToBoxAdapter(child: _buildHeader()),
                    SliverPadding(
                      padding:
                          EdgeInsets.symmetric(horizontal: HoorSpacing.lg.w),
                      sliver: SliverList(
                        delegate: SliverChildListDelegate([
                          ShiftStatusCard(
                            hasOpenShift: hasOpenShift,
                            onTap: () => context.push('/shifts'),
                          ),
                          SizedBox(height: HoorSpacing.xxl.h),
                          _buildQuickStats(),
                          SizedBox(height: HoorSpacing.xxl.h),
                          _buildQuickActions(hasOpenShift),
                          SizedBox(height: HoorSpacing.xxl.h),
                          _buildMainMenu(),
                          SizedBox(height: HoorSpacing.xxxl.h),
                        ]),
                      ),
                    ),
                  ],
                ),
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
                Row(
                  children: [
                    Container(
                      padding: EdgeInsets.all(HoorSpacing.sm.w),
                      decoration: BoxDecoration(
                        gradient: HoorColors.royalGradient,
                        borderRadius: BorderRadius.circular(HoorRadius.lg),
                        boxShadow: HoorShadows.colored(HoorColors.primary,
                            opacity: 0.3),
                      ),
                      child: Icon(
                        Icons.store_rounded,
                        color: Colors.white,
                        size: HoorIconSize.lg,
                      ),
                    ),
                    SizedBox(width: HoorSpacing.md.w),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Hoor Manager',
                          style: HoorTypography.headlineMedium.copyWith(
                            color: HoorColors.primary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          'نظام إدارة الأعمال المتكامل',
                          style: HoorTypography.bodySmall.copyWith(
                            color: HoorColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
          Row(
            children: [
              const AlertsButtonRedesign(),
              SizedBox(width: HoorSpacing.xs.w),
              // SyncStatusWidget removed - use new pro version
              SizedBox(width: HoorSpacing.xs.w),
              _buildHeaderIconButton(
                icon: Icons.settings_outlined,
                onTap: () => context.push('/settings'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderIconButton({
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return Material(
      color: HoorColors.surfaceMuted,
      borderRadius: BorderRadius.circular(HoorRadius.lg),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(HoorRadius.lg),
        child: Container(
          padding: EdgeInsets.all(HoorSpacing.sm.w),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(HoorRadius.lg),
            border: Border.all(color: HoorColors.border),
          ),
          child: Icon(
            icon,
            color: HoorColors.textSecondary,
            size: HoorIconSize.md,
          ),
        ),
      ),
    );
  }

  Widget _buildQuickStats() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader(
          title: 'نظرة عامة',
          icon: Icons.analytics_outlined,
        ),
        SizedBox(height: HoorSpacing.md.h),
        Row(
          children: [
            Expanded(
              child: _buildPremiumStatCard(
                title: 'مبيعات اليوم',
                value: '0',
                subtitle: 'ر.س',
                icon: Icons.trending_up_rounded,
                gradient: HoorColors.forestGradient,
                onTap: () => context.push('/reports/sales'),
              ),
            ),
            SizedBox(width: HoorSpacing.md.w),
            Expanded(
              child: _buildPremiumStatCard(
                title: 'المشتريات',
                value: '0',
                subtitle: 'ر.س',
                icon: Icons.trending_down_rounded,
                gradient: HoorColors.premiumGradient,
                onTap: () => context.push('/reports/purchases'),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildPremiumStatCard({
    required String title,
    required String value,
    required String subtitle,
    required IconData icon,
    required Gradient gradient,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.all(HoorSpacing.lg.w),
        decoration: BoxDecoration(
          gradient: gradient,
          borderRadius: BorderRadius.circular(HoorRadius.xl),
          boxShadow: [
            BoxShadow(
              color: (gradient as LinearGradient)
                  .colors
                  .first
                  .withValues(alpha: 0.3),
              blurRadius: 16,
              offset: const Offset(0, 8),
              spreadRadius: -4,
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: EdgeInsets.all(HoorSpacing.sm.w),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(HoorRadius.md),
                  ),
                  child: Icon(icon, color: Colors.white, size: HoorIconSize.md),
                ),
                Icon(
                  Icons.arrow_forward_ios_rounded,
                  color: Colors.white.withValues(alpha: 0.7),
                  size: HoorIconSize.sm,
                ),
              ],
            ),
            SizedBox(height: HoorSpacing.lg.h),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  value,
                  style: HoorTypography.displaySmall.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(width: HoorSpacing.xs.w),
                Padding(
                  padding: EdgeInsets.only(bottom: 4.h),
                  child: Text(
                    subtitle,
                    style: HoorTypography.bodySmall.copyWith(
                      color: Colors.white.withValues(alpha: 0.8),
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: HoorSpacing.xs.h),
            Text(
              title,
              style: HoorTypography.bodySmall.copyWith(
                color: Colors.white.withValues(alpha: 0.9),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader({
    required String title,
    required IconData icon,
  }) {
    return Row(
      children: [
        Container(
          padding: EdgeInsets.all(HoorSpacing.xs.w),
          decoration: BoxDecoration(
            color: HoorColors.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(HoorRadius.sm),
          ),
          child: Icon(icon, color: HoorColors.primary, size: HoorIconSize.sm),
        ),
        SizedBox(width: HoorSpacing.sm.w),
        Text(
          title,
          style: HoorTypography.titleMedium.copyWith(
            fontWeight: FontWeight.w600,
            color: HoorColors.textPrimary,
          ),
        ),
      ],
    );
  }

  Widget _buildQuickActions(bool hasOpenShift) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader(
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
        _buildMenuSection(
          title: 'المبيعات والفواتير',
          icon: Icons.shopping_bag_rounded,
          items: [
            _MenuItemData(
              icon: Icons.receipt_long_rounded,
              label: 'الفواتير',
              subtitle: 'عرض وإدارة الفواتير',
              color: HoorColors.sales,
              route: '/invoices',
            ),
            _MenuItemData(
              icon: Icons.people_rounded,
              label: 'العملاء',
              subtitle: 'إدارة بيانات العملاء',
              color: HoorColors.info,
              route: '/customers',
            ),
            _MenuItemData(
              icon: Icons.local_shipping_rounded,
              label: 'الموردين',
              subtitle: 'إدارة بيانات الموردين',
              color: HoorColors.purchases,
              route: '/suppliers',
            ),
          ],
        ),
        SizedBox(height: HoorSpacing.xxl.h),

        // Inventory Section
        _buildMenuSection(
          title: 'المخزون والمنتجات',
          icon: Icons.inventory_rounded,
          items: [
            _MenuItemData(
              icon: Icons.inventory_2_rounded,
              label: 'المنتجات',
              subtitle: 'إدارة قائمة المنتجات',
              color: HoorColors.primary,
              route: '/products',
            ),
            _MenuItemData(
              icon: Icons.category_rounded,
              label: 'التصنيفات',
              subtitle: 'تنظيم وتصنيف المواد',
              color: const Color(0xFFD4A574),
              route: '/categories',
            ),
            _MenuItemData(
              icon: Icons.warehouse_rounded,
              label: 'المخزون',
              subtitle: 'متابعة حركة المخزون',
              color: HoorColors.inventory,
              route: '/inventory',
            ),
          ],
        ),
        SizedBox(height: HoorSpacing.xxl.h),

        // Finance Section
        _buildMenuSection(
          title: 'المالية والتقارير',
          icon: Icons.account_balance_rounded,
          items: [
            _MenuItemData(
              icon: Icons.access_time_rounded,
              label: 'الورديات',
              subtitle: 'إدارة فترات العمل',
              color: HoorColors.textSecondary,
              route: '/shifts',
            ),
            _MenuItemData(
              icon: Icons.account_balance_wallet_rounded,
              label: 'الصندوق',
              subtitle: 'حركة النقدية اليومية',
              color: HoorColors.income,
              route: '/cash',
            ),
            _MenuItemData(
              icon: Icons.receipt_rounded,
              label: 'السندات',
              subtitle: 'قبض ودفع ومصاريف',
              color: HoorColors.warning,
              route: '/vouchers',
            ),
            _MenuItemData(
              icon: Icons.bar_chart_rounded,
              label: 'التقارير',
              subtitle: 'تقارير وإحصائيات شاملة',
              color: HoorColors.success,
              route: '/reports',
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildMenuSection({
    required String title,
    required IconData icon,
    required List<_MenuItemData> items,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section Header with gradient background
        Container(
          padding: EdgeInsets.symmetric(
            horizontal: HoorSpacing.md.w,
            vertical: HoorSpacing.sm.h,
          ),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                HoorColors.primary.withValues(alpha: 0.08),
                HoorColors.primary.withValues(alpha: 0.02),
              ],
            ),
            borderRadius: BorderRadius.circular(HoorRadius.lg),
          ),
          child: Row(
            children: [
              Container(
                padding: EdgeInsets.all(HoorSpacing.xs.w),
                decoration: BoxDecoration(
                  color: HoorColors.primary.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(HoorRadius.sm),
                ),
                child: Icon(icon,
                    color: HoorColors.primary, size: HoorIconSize.md),
              ),
              SizedBox(width: HoorSpacing.sm.w),
              Text(
                title,
                style: HoorTypography.titleMedium.copyWith(
                  fontWeight: FontWeight.bold,
                  color: HoorColors.primary,
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: HoorSpacing.md.h),

        // Grid of Items
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            mainAxisSpacing: HoorSpacing.sm.h,
            crossAxisSpacing: HoorSpacing.sm.w,
            childAspectRatio: 1.55,
          ),
          itemCount: items.length,
          itemBuilder: (context, index) {
            final item = items[index];
            return MenuItemCard(
              icon: item.icon,
              label: item.label,
              subtitle: item.subtitle,
              color: item.color,
              onTap: () => context.push(item.route),
            );
          },
        ),
      ],
    );
  }

  Widget _buildBottomNav() {
    return Container(
      decoration: BoxDecoration(
        color: HoorColors.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 20,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: HoorSpacing.md.w,
            vertical: HoorSpacing.sm.h,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildNavItem(
                icon: Icons.dashboard_outlined,
                activeIcon: Icons.dashboard_rounded,
                label: 'الرئيسية',
                index: 0,
                onTap: () {
                  if (_selectedNavIndex != 0) {
                    setState(() => _selectedNavIndex = 0);
                  }
                },
              ),
              _buildNavItem(
                icon: Icons.receipt_long_outlined,
                activeIcon: Icons.receipt_long_rounded,
                label: 'الفواتير',
                index: 1,
                onTap: () => context.push('/invoices'),
              ),
              _buildNavItem(
                icon: Icons.inventory_2_outlined,
                activeIcon: Icons.inventory_2_rounded,
                label: 'المنتجات',
                index: 2,
                onTap: () => context.push('/products'),
              ),
              _buildNavItem(
                icon: Icons.bar_chart_outlined,
                activeIcon: Icons.bar_chart_rounded,
                label: 'التقارير',
                index: 3,
                onTap: () => context.push('/reports'),
              ),
              _buildNavItem(
                icon: Icons.settings_outlined,
                activeIcon: Icons.settings_rounded,
                label: 'الإعدادات',
                index: 4,
                onTap: () => context.push('/settings'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem({
    required IconData icon,
    required IconData activeIcon,
    required String label,
    required int index,
    required VoidCallback onTap,
  }) {
    final isSelected = _selectedNavIndex == index;

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: EdgeInsets.symmetric(
          horizontal: isSelected ? HoorSpacing.md.w : HoorSpacing.sm.w,
          vertical: HoorSpacing.sm.h,
        ),
        decoration: BoxDecoration(
          color: isSelected
              ? HoorColors.primary.withValues(alpha: 0.1)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(HoorRadius.lg),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isSelected ? activeIcon : icon,
              color: isSelected ? HoorColors.primary : HoorColors.textSecondary,
              size: HoorIconSize.md,
            ),
            SizedBox(height: HoorSpacing.xxs.h),
            Text(
              label,
              style: HoorTypography.labelSmall.copyWith(
                color:
                    isSelected ? HoorColors.primary : HoorColors.textSecondary,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Helper class for menu item data
class _MenuItemData {
  final IconData icon;
  final String label;
  final String subtitle;
  final Color color;
  final String route;

  const _MenuItemData({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.color,
    required this.route,
  });
}
