// ═══════════════════════════════════════════════════════════════════════════
// Hoor Manager Pro - Professional Dashboard
// A clean, minimal, and efficient dashboard for daily accounting operations
// ═══════════════════════════════════════════════════════════════════════════

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/design_tokens.dart';
import '../../core/providers/app_providers.dart';
import 'widgets/pro_navigation_drawer.dart';
import 'widgets/kpi_card.dart';
import 'widgets/quick_action_button.dart';
import 'widgets/recent_transactions_list.dart';
import 'widgets/shift_status_banner.dart';
import 'widgets/alerts_widget.dart';

class DashboardPro extends ConsumerStatefulWidget {
  const DashboardPro({super.key});

  @override
  ConsumerState<DashboardPro> createState() => _DashboardProState();
}

class _DashboardProState extends ConsumerState<DashboardPro>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  int _currentNavIndex = 0;

  @override
  void initState() {
    super.initState();
    _setupAnimations();
  }

  void _setupAnimations() {
    _animationController = AnimationController(
      duration: AppDurations.slower,
      vsync: this,
    );

    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: AppCurves.enter,
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.05),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: AppCurves.enter,
    ));

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
      ),
      child: Scaffold(
        key: _scaffoldKey,
        backgroundColor: AppColors.background,
        drawer: const ProNavigationDrawer(currentRoute: '/'),
        body: SafeArea(
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: SlideTransition(
              position: _slideAnimation,
              child: RefreshIndicator(
                onRefresh: _handleRefresh,
                color: AppColors.secondary,
                backgroundColor: AppColors.surface,
                child: CustomScrollView(
                  physics: const BouncingScrollPhysics(),
                  slivers: [
                    // Header
                    SliverToBoxAdapter(child: _buildHeader()),

                    // Shift Status Banner
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: AppSpacing.screenPadding.w,
                        ),
                        child: _buildShiftStatusBanner(),
                      ),
                    ),

                    SliverToBoxAdapter(
                        child: SizedBox(height: AppSpacing.lg.h)),

                    // KPI Cards Section
                    SliverToBoxAdapter(child: _buildKPISection()),

                    SliverToBoxAdapter(
                        child: SizedBox(height: AppSpacing.xl.h)),

                    // Quick Actions Section
                    SliverToBoxAdapter(child: _buildQuickActionsSection()),

                    SliverToBoxAdapter(
                        child: SizedBox(height: AppSpacing.xl.h)),

                    // Recent Transactions Section
                    SliverToBoxAdapter(
                        child: _buildRecentTransactionsSection()),

                    SliverToBoxAdapter(
                        child: SizedBox(height: AppSpacing.xl.h)),

                    // Alerts Section
                    SliverToBoxAdapter(child: _buildAlertsSection()),

                    // Bottom padding
                    SliverToBoxAdapter(
                        child: SizedBox(height: AppSpacing.huge.h)),
                  ],
                ),
              ),
            ),
          ),
        ),
        bottomNavigationBar: _buildBottomNavigation(),
        floatingActionButton: _buildFAB(),
        floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // HEADER
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildHeader() {
    // Get real alerts count
    final alertsAsync = ref.watch(dashboardAlertsProvider);
    final alertsCount =
        alertsAsync.whenOrNull(data: (alerts) => alerts.length) ?? 0;

    return Padding(
      padding: EdgeInsets.all(AppSpacing.screenPadding.w),
      child: Row(
        children: [
          // Menu Button
          _buildHeaderAction(
            icon: Icons.menu_rounded,
            onTap: () => _scaffoldKey.currentState?.openDrawer(),
          ),
          SizedBox(width: AppSpacing.sm.w),

          // Logo & Title
          Expanded(
            child: Row(
              children: [
                _buildLogo(),
                SizedBox(width: AppSpacing.md.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Hoor Manager',
                        style: AppTypography.headlineMedium.copyWith(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Text(
                        'نظام إدارة الأعمال المتكامل',
                        style: AppTypography.bodySmall.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Action Buttons
          Row(
            children: [
              _buildHeaderAction(
                icon: Icons.notifications_outlined,
                badge: alertsCount,
                onTap: () => context.push('/alerts'),
              ),
              SizedBox(width: AppSpacing.xs.w),
              _buildHeaderAction(
                icon: Icons.sync_outlined,
                onTap: _handleSync,
              ),
              SizedBox(width: AppSpacing.xs.w),
              _buildHeaderAction(
                icon: Icons.settings_outlined,
                onTap: () => context.push('/settings'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLogo() {
    return Container(
      width: 48.w,
      height: 48.w,
      decoration: BoxDecoration(
        gradient: AppColors.premiumGradient,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        boxShadow: AppShadows.colored(AppColors.secondary),
      ),
      child: Icon(
        Icons.store_rounded,
        color: AppColors.textOnPrimary,
        size: AppIconSize.lg,
      ),
    );
  }

  Widget _buildHeaderAction({
    required IconData icon,
    int badge = 0,
    required VoidCallback onTap,
  }) {
    return Material(
      color: AppColors.surfaceMuted,
      borderRadius: BorderRadius.circular(AppRadius.lg),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        child: Container(
          width: 44.w,
          height: 44.w,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadius.lg),
            border: Border.all(color: AppColors.border),
          ),
          child: badge > 0
              ? Badge(
                  label: Text(badge.toString()),
                  child: Icon(
                    icon,
                    color: AppColors.textSecondary,
                    size: AppIconSize.md,
                  ),
                )
              : Icon(
                  icon,
                  color: AppColors.textSecondary,
                  size: AppIconSize.md,
                ),
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // KPI SECTION
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildKPISection() {
    final statsAsync = ref.watch(dashboardStatsProvider);

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: AppSpacing.screenPadding.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader(
            title: 'نظرة عامة',
            icon: Icons.analytics_outlined,
            action: TextButton(
              onPressed: () => context.push('/reports'),
              child: Text(
                'التفاصيل',
                style: AppTypography.labelMedium.copyWith(
                  color: AppColors.secondary,
                ),
              ),
            ),
          ),
          SizedBox(height: AppSpacing.md.h),
          statsAsync.when(
            loading: () => _buildKPILoading(),
            error: (e, _) => _buildKPIError(),
            data: (stats) => Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: KPICard(
                        title: 'مبيعات اليوم',
                        value: _formatNumber(stats.todaySales),
                        currency: 'ر.س',
                        icon: Icons.trending_up_rounded,
                        trend: 0, // TODO: Calculate trend
                        trendLabel: '${stats.salesCount} فاتورة',
                        gradient: AppColors.incomeGradient,
                        onTap: () => context.push('/invoices'),
                      ),
                    ),
                    SizedBox(width: AppSpacing.md.w),
                    Expanded(
                      child: KPICard(
                        title: 'المشتريات',
                        value: _formatNumber(stats.todayPurchases),
                        currency: 'ر.س',
                        icon: Icons.shopping_cart_outlined,
                        trend: 0,
                        trendLabel: 'اليوم',
                        gradient: AppColors.expenseGradient,
                        onTap: () => context.push('/purchases'),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: AppSpacing.md.h),
                Row(
                  children: [
                    Expanded(
                      child: KPICard.mini(
                        title: 'صافي الربح',
                        value: _formatNumber(stats.todayProfit),
                        currency: 'ر.س',
                        icon: Icons.account_balance_wallet_outlined,
                        color: stats.todayProfit >= 0
                            ? AppColors.income
                            : AppColors.expense,
                        onTap: () => context.push('/reports'),
                      ),
                    ),
                    SizedBox(width: AppSpacing.md.w),
                    Expanded(
                      child: KPICard.mini(
                        title: 'المنتجات',
                        value: stats.totalProducts.toString(),
                        currency: '',
                        icon: Icons.inventory_2_outlined,
                        color: AppColors.inventory,
                        onTap: () => context.push('/products'),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: AppSpacing.md.h),
                Row(
                  children: [
                    Expanded(
                      child: KPICard.mini(
                        title: 'نفاد المخزون',
                        value: stats.lowStockCount.toString(),
                        currency: 'منتج',
                        icon: Icons.warning_amber_outlined,
                        color: stats.lowStockCount > 0
                            ? AppColors.warning
                            : AppColors.success,
                        onTap: () => context.push('/products?filter=low_stock'),
                      ),
                    ),
                    SizedBox(width: AppSpacing.md.w),
                    Expanded(
                      child: KPICard.mini(
                        title: 'العملاء',
                        value: stats.totalCustomers.toString(),
                        currency: '',
                        icon: Icons.people_outlined,
                        color: AppColors.customers,
                        onTap: () => context.push('/customers'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildKPILoading() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(child: _buildShimmerCard(height: 120.h)),
            SizedBox(width: AppSpacing.md.w),
            Expanded(child: _buildShimmerCard(height: 120.h)),
          ],
        ),
        SizedBox(height: AppSpacing.md.h),
        Row(
          children: [
            Expanded(child: _buildShimmerCard(height: 80.h)),
            SizedBox(width: AppSpacing.md.w),
            Expanded(child: _buildShimmerCard(height: 80.h)),
          ],
        ),
      ],
    );
  }

  Widget _buildShimmerCard({required double height}) {
    return Container(
      height: height,
      decoration: BoxDecoration(
        color: AppColors.surfaceMuted,
        borderRadius: BorderRadius.circular(AppRadius.xl),
      ),
    );
  }

  Widget _buildKPIError() {
    return Container(
      padding: EdgeInsets.all(AppSpacing.lg.w),
      decoration: BoxDecoration(
        color: AppColors.expenseLight,
        borderRadius: BorderRadius.circular(AppRadius.xl),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline, color: AppColors.expense),
          SizedBox(width: AppSpacing.md.w),
          Text(
            'حدث خطأ في تحميل البيانات',
            style: AppTypography.bodyMedium.copyWith(color: AppColors.expense),
          ),
        ],
      ),
    );
  }

  String _formatNumber(double number) {
    if (number >= 1000000) {
      return '${(number / 1000000).toStringAsFixed(1)}M';
    } else if (number >= 1000) {
      return '${(number / 1000).toStringAsFixed(1)}K';
    }
    return number.toStringAsFixed(2);
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // QUICK ACTIONS SECTION
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildQuickActionsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.symmetric(horizontal: AppSpacing.screenPadding.w),
          child: _buildSectionHeader(
            title: 'إجراءات سريعة',
            icon: Icons.flash_on_outlined,
          ),
        ),
        SizedBox(height: AppSpacing.md.h),
        SizedBox(
          height: 90.h,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding:
                EdgeInsets.symmetric(horizontal: AppSpacing.screenPadding.w),
            children: [
              QuickActionButton(
                icon: Icons.receipt_long_outlined,
                label: 'فاتورة بيع',
                color: AppColors.sales,
                onTap: () => context.push('/sales/add'),
              ),
              SizedBox(width: AppSpacing.md.w),
              QuickActionButton(
                icon: Icons.shopping_cart_outlined,
                label: 'فاتورة شراء',
                color: AppColors.purchases,
                onTap: () => context.push('/purchases/add'),
              ),
              SizedBox(width: AppSpacing.md.w),
              QuickActionButton(
                icon: Icons.payments_outlined,
                label: 'سند قبض',
                color: AppColors.income,
                onTap: () => context.push('/vouchers/receipt/add'),
              ),
              SizedBox(width: AppSpacing.md.w),
              QuickActionButton(
                icon: Icons.money_off_outlined,
                label: 'سند صرف',
                color: AppColors.expense,
                onTap: () => context.push('/vouchers/payment/add'),
              ),
              SizedBox(width: AppSpacing.md.w),
              QuickActionButton(
                icon: Icons.inventory_2_outlined,
                label: 'جرد المخزون',
                color: AppColors.inventory,
                onTap: () => context.push('/inventory/count'),
              ),
              SizedBox(width: AppSpacing.md.w),
              QuickActionButton(
                icon: Icons.person_add_outlined,
                label: 'عميل جديد',
                color: AppColors.customers,
                onTap: () => context.push('/customers/add'),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // RECENT TRANSACTIONS SECTION
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildRecentTransactionsSection() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: AppSpacing.screenPadding.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader(
            title: 'آخر المعاملات',
            icon: Icons.history_outlined,
            action: TextButton(
              onPressed: () => context.push('/sales'),
              child: Text(
                'عرض الكل',
                style: AppTypography.labelMedium.copyWith(
                  color: AppColors.secondary,
                ),
              ),
            ),
          ),
          SizedBox(height: AppSpacing.md.h),
          const RecentTransactionsList(),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // ALERTS SECTION
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildAlertsSection() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: AppSpacing.screenPadding.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader(
            title: 'تنبيهات',
            icon: Icons.warning_amber_outlined,
            action: TextButton(
              onPressed: () => context.push('/alerts'),
              child: Text(
                'عرض الكل',
                style: AppTypography.labelMedium.copyWith(
                  color: AppColors.secondary,
                ),
              ),
            ),
          ),
          SizedBox(height: AppSpacing.md.h),
          const AlertsWidget(),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // BOTTOM NAVIGATION
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildBottomNavigation() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border(
          top: BorderSide(color: AppColors.border, width: 1),
        ),
        boxShadow: AppShadows.sm,
      ),
      child: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: AppSpacing.md.w,
            vertical: AppSpacing.xs.h,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildNavItem(
                icon: Icons.home_outlined,
                activeIcon: Icons.home_rounded,
                label: 'الرئيسية',
                index: 0,
              ),
              _buildNavItem(
                icon: Icons.receipt_long_outlined,
                activeIcon: Icons.receipt_long_rounded,
                label: 'المبيعات',
                index: 1,
              ),
              SizedBox(width: 56.w), // Space for FAB
              _buildNavItem(
                icon: Icons.inventory_2_outlined,
                activeIcon: Icons.inventory_2_rounded,
                label: 'المخزون',
                index: 2,
              ),
              _buildNavItem(
                icon: Icons.bar_chart_outlined,
                activeIcon: Icons.bar_chart_rounded,
                label: 'التقارير',
                index: 3,
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
  }) {
    final isSelected = _currentNavIndex == index;

    return InkWell(
      onTap: () {
        setState(() => _currentNavIndex = index);
        HapticFeedback.lightImpact();
        _navigateToIndex(index);
      },
      borderRadius: BorderRadius.circular(AppRadius.lg),
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: AppSpacing.sm.w,
          vertical: AppSpacing.xs.h,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedContainer(
              duration: AppDurations.fast,
              padding: EdgeInsets.all(AppSpacing.xs.w),
              decoration: BoxDecoration(
                color:
                    isSelected ? AppColors.secondaryMuted : Colors.transparent,
                borderRadius: BorderRadius.circular(AppRadius.md),
              ),
              child: Icon(
                isSelected ? activeIcon : icon,
                color:
                    isSelected ? AppColors.secondary : AppColors.textTertiary,
                size: AppIconSize.md,
              ),
            ),
            SizedBox(height: AppSpacing.xxs.h),
            Text(
              label,
              style: AppTypography.labelSmall.copyWith(
                color:
                    isSelected ? AppColors.secondary : AppColors.textTertiary,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // FLOATING ACTION BUTTON
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildFAB() {
    return Container(
      decoration: BoxDecoration(
        boxShadow: AppShadows.fab,
        borderRadius: BorderRadius.circular(AppRadius.xl),
      ),
      child: FloatingActionButton(
        onPressed: _showQuickAddMenu,
        backgroundColor: AppColors.secondary,
        foregroundColor: AppColors.textOnSecondary,
        elevation: 0,
        child: Icon(Icons.add_rounded, size: AppIconSize.lg),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // HELPERS
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildSectionHeader({
    required String title,
    required IconData icon,
    Widget? action,
  }) {
    return Row(
      children: [
        Container(
          padding: EdgeInsets.all(AppSpacing.xs.w),
          decoration: BoxDecoration(
            color: AppColors.secondaryMuted,
            borderRadius: BorderRadius.circular(AppRadius.sm),
          ),
          child: Icon(
            icon,
            color: AppColors.secondary,
            size: AppIconSize.sm,
          ),
        ),
        SizedBox(width: AppSpacing.sm.w),
        Expanded(
          child: Text(
            title,
            style: AppTypography.titleMedium.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        if (action != null) action,
      ],
    );
  }

  void _navigateToIndex(int index) {
    switch (index) {
      case 0:
        // Already on home
        break;
      case 1:
        context.push('/sales');
        break;
      case 2:
        context.push('/products');
        break;
      case 3:
        context.push('/reports');
        break;
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // SHIFT STATUS BANNER (Real Data)
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildShiftStatusBanner() {
    final shiftAsync = ref.watch(openShiftStreamProvider);
    final statsAsync = ref.watch(dashboardStatsProvider);

    return shiftAsync.when(
      loading: () => _buildShimmerCard(height: 80.h),
      error: (_, __) => const SizedBox.shrink(),
      data: (shift) {
        if (shift == null) {
          // No open shift
          return ShiftStatusBanner(
            isOpen: false,
            startTime: '',
            totalSales: 0,
            onTap: () => context.push('/shifts'),
          );
        }

        final totalSales = statsAsync.whenOrNull(data: (s) => s.todaySales) ??
            shift.totalSales;

        return ShiftStatusBanner(
          isOpen: true,
          startTime: _formatTime(shift.openedAt),
          totalSales: totalSales,
          onTap: () => context.push('/shifts'),
        );
      },
    );
  }

  String _formatTime(DateTime dateTime) {
    final hour = dateTime.hour;
    final minute = dateTime.minute.toString().padLeft(2, '0');
    final period = hour >= 12 ? 'م' : 'ص';
    final displayHour = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);
    return '$displayHour:$minute $period';
  }

  Future<void> _handleRefresh() async {
    HapticFeedback.mediumImpact();
    // Refresh all dashboard data providers
    ref.invalidate(dashboardStatsProvider);
    ref.invalidate(openShiftStreamProvider);
    ref.invalidate(recentTransactionsProvider);
    ref.invalidate(dashboardAlertsProvider);
    await Future.delayed(const Duration(milliseconds: 500));
  }

  void _handleSync() {
    HapticFeedback.lightImpact();
    final syncService = ref.read(syncServiceProvider);
    syncService.syncAll();
  }

  void _showQuickAddMenu() {
    HapticFeedback.mediumImpact();
    showModalBottomSheet(
      context: context,
      builder: (context) => _QuickAddBottomSheet(),
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// QUICK ADD BOTTOM SHEET
// ═══════════════════════════════════════════════════════════════════════════

class _QuickAddBottomSheet extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadius.sheet,
      ),
      child: SafeArea(
        child: Padding(
          padding: EdgeInsets.all(AppSpacing.screenPadding.w),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Handle
              Container(
                width: 40.w,
                height: 4.h,
                decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(AppRadius.full),
                ),
              ),
              SizedBox(height: AppSpacing.lg.h),

              // Title
              Text(
                'إنشاء جديد',
                style: AppTypography.titleLarge.copyWith(
                  color: AppColors.textPrimary,
                ),
              ),
              SizedBox(height: AppSpacing.xl.h),

              // Options Grid
              Row(
                children: [
                  Expanded(
                    child: _QuickAddOption(
                      icon: Icons.receipt_long_outlined,
                      label: 'فاتورة بيع',
                      color: AppColors.sales,
                      onTap: () {
                        Navigator.pop(context);
                        context.push('/sales/add');
                      },
                    ),
                  ),
                  SizedBox(width: AppSpacing.md.w),
                  Expanded(
                    child: _QuickAddOption(
                      icon: Icons.shopping_cart_outlined,
                      label: 'فاتورة شراء',
                      color: AppColors.purchases,
                      onTap: () {
                        Navigator.pop(context);
                        context.push('/purchases/add');
                      },
                    ),
                  ),
                ],
              ),
              SizedBox(height: AppSpacing.md.h),
              Row(
                children: [
                  Expanded(
                    child: _QuickAddOption(
                      icon: Icons.payments_outlined,
                      label: 'سند قبض',
                      color: AppColors.income,
                      onTap: () {
                        Navigator.pop(context);
                        context.push('/vouchers/receipt/add');
                      },
                    ),
                  ),
                  SizedBox(width: AppSpacing.md.w),
                  Expanded(
                    child: _QuickAddOption(
                      icon: Icons.money_off_outlined,
                      label: 'سند صرف',
                      color: AppColors.expense,
                      onTap: () {
                        Navigator.pop(context);
                        context.push('/vouchers/payment/add');
                      },
                    ),
                  ),
                ],
              ),
              SizedBox(height: AppSpacing.md.h),
              Row(
                children: [
                  Expanded(
                    child: _QuickAddOption(
                      icon: Icons.inventory_2_outlined,
                      label: 'منتج جديد',
                      color: AppColors.inventory,
                      onTap: () {
                        Navigator.pop(context);
                        context.push('/products/add');
                      },
                    ),
                  ),
                  SizedBox(width: AppSpacing.md.w),
                  Expanded(
                    child: _QuickAddOption(
                      icon: Icons.person_add_outlined,
                      label: 'عميل جديد',
                      color: AppColors.customers,
                      onTap: () {
                        Navigator.pop(context);
                        context.push('/customers/add');
                      },
                    ),
                  ),
                ],
              ),
              SizedBox(height: AppSpacing.lg.h),
            ],
          ),
        ),
      ),
    );
  }
}

class _QuickAddOption extends StatelessWidget {
  const _QuickAddOption({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ProCard(
      backgroundColor: color.withValues(alpha: 0.1),
      onTap: onTap,
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(AppSpacing.sm.w),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
            child: Icon(icon, color: color, size: AppIconSize.md),
          ),
          SizedBox(width: AppSpacing.sm.w),
          Expanded(
            child: Text(
              label,
              style: AppTypography.labelMedium.copyWith(
                color: AppColors.textPrimary,
              ),
            ),
          ),
          Icon(
            Icons.arrow_forward_ios_rounded,
            color: AppColors.textTertiary,
            size: AppIconSize.xs,
          ),
        ],
      ),
    );
  }
}
