// ═══════════════════════════════════════════════════════════════════════════
// Pro Navigation Drawer / Sidebar
// Animated, Modern Sidebar Navigation
// ═══════════════════════════════════════════════════════════════════════════

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:hoor_manager/core/theme/design_tokens.dart';

class ProNavigationDrawer extends StatelessWidget {
  final String? currentRoute;
  final VoidCallback? onClose;

  const ProNavigationDrawer({
    super.key,
    this.currentRoute,
    this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: Colors.white,
      child: SafeArea(
        child: Column(
          children: [
            // Header
            _buildHeader(context),

            Divider(height: 1, color: AppColors.border),

            // Navigation Items
            Expanded(
              child: ListView(
                padding: EdgeInsets.symmetric(vertical: AppSpacing.md),
                children: [
                  _NavSection(
                    title: 'الرئيسية',
                    children: [
                      _NavItem(
                        icon: Icons.dashboard_outlined,
                        activeIcon: Icons.dashboard,
                        label: 'لوحة التحكم',
                        route: '/',
                        currentRoute: currentRoute,
                      ),
                    ],
                  ),
                  _NavSection(
                    title: 'المبيعات',
                    children: [
                      _NavItem(
                        icon: Icons.receipt_long_outlined,
                        activeIcon: Icons.receipt_long,
                        label: 'الفواتير',
                        route: '/invoices',
                        currentRoute: currentRoute,
                        badge: '5',
                        badgeColor: AppColors.error,
                      ),
                      _NavItem(
                        icon: Icons.point_of_sale_outlined,
                        activeIcon: Icons.point_of_sale,
                        label: 'نقطة البيع',
                        route: '/sales',
                        currentRoute: currentRoute,
                      ),
                      _NavItem(
                        icon: Icons.people_outline,
                        activeIcon: Icons.people,
                        label: 'العملاء',
                        route: '/customers',
                        currentRoute: currentRoute,
                      ),
                    ],
                  ),
                  _NavSection(
                    title: 'المشتريات',
                    children: [
                      _NavItem(
                        icon: Icons.shopping_cart_outlined,
                        activeIcon: Icons.shopping_cart,
                        label: 'المشتريات',
                        route: '/purchases',
                        currentRoute: currentRoute,
                      ),
                      _NavItem(
                        icon: Icons.local_shipping_outlined,
                        activeIcon: Icons.local_shipping,
                        label: 'الموردين',
                        route: '/suppliers',
                        currentRoute: currentRoute,
                      ),
                    ],
                  ),
                  _NavSection(
                    title: 'المخزون',
                    children: [
                      _NavItem(
                        icon: Icons.inventory_2_outlined,
                        activeIcon: Icons.inventory_2,
                        label: 'المنتجات',
                        route: '/products',
                        currentRoute: currentRoute,
                      ),
                      _NavItem(
                        icon: Icons.warehouse_outlined,
                        activeIcon: Icons.warehouse,
                        label: 'المخزون',
                        route: '/inventory',
                        currentRoute: currentRoute,
                      ),
                      _NavItem(
                        icon: Icons.category_outlined,
                        activeIcon: Icons.category,
                        label: 'التصنيفات',
                        route: '/categories',
                        currentRoute: currentRoute,
                      ),
                    ],
                  ),
                  _NavSection(
                    title: 'المحاسبة',
                    children: [
                      _NavItem(
                        icon: Icons.account_balance_wallet_outlined,
                        activeIcon: Icons.account_balance_wallet,
                        label: 'السندات',
                        route: '/vouchers',
                        currentRoute: currentRoute,
                      ),
                      _NavItem(
                        icon: Icons.point_of_sale_outlined,
                        activeIcon: Icons.point_of_sale,
                        label: 'الصندوق',
                        route: '/cash',
                        currentRoute: currentRoute,
                      ),
                      _NavItem(
                        icon: Icons.schedule_outlined,
                        activeIcon: Icons.schedule,
                        label: 'الورديات',
                        route: '/shifts',
                        currentRoute: currentRoute,
                      ),
                      _NavItem(
                        icon: Icons.bar_chart_outlined,
                        activeIcon: Icons.bar_chart,
                        label: 'التقارير',
                        route: '/reports',
                        currentRoute: currentRoute,
                      ),
                    ],
                  ),
                  _NavSection(
                    title: 'النظام',
                    children: [
                      _NavItem(
                        icon: Icons.notifications_outlined,
                        activeIcon: Icons.notifications,
                        label: 'التنبيهات',
                        route: '/alerts',
                        currentRoute: currentRoute,
                      ),
                      _NavItem(
                        icon: Icons.backup_outlined,
                        activeIcon: Icons.backup,
                        label: 'النسخ الاحتياطي',
                        route: '/backup',
                        currentRoute: currentRoute,
                      ),
                      _NavItem(
                        icon: Icons.settings_outlined,
                        activeIcon: Icons.settings,
                        label: 'الإعدادات',
                        route: '/settings',
                        currentRoute: currentRoute,
                      ),
                    ],
                  ),
                ],
              ),
            ),

            Divider(height: 1, color: AppColors.border),

            // Footer
            _buildFooter(context),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(AppSpacing.lg),
      child: Row(
        children: [
          // Logo
          Container(
            width: 48.w,
            height: 48.h,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppColors.primary, AppColors.secondary],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(AppRadius.md),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Center(
              child: Text(
                'ح',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24.sp,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Cairo',
                ),
              ),
            ),
          ),
          SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'حور مانجر',
                  style: AppTypography.titleMedium.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'نظام المحاسبة',
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: Icon(Icons.close, color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }

  Widget _buildFooter(BuildContext context) {
    return Padding(
      padding: EdgeInsets.all(AppSpacing.lg),
      child: Column(
        children: [
          // Settings & Alerts Row
          Row(
            children: [
              Expanded(
                child: _FooterButton(
                  icon: Icons.notifications_outlined,
                  label: 'التنبيهات',
                  onTap: () {
                    Navigator.pop(context);
                    context.go('/alerts');
                  },
                  badge: '3',
                ),
              ),
              SizedBox(width: AppSpacing.md),
              Expanded(
                child: _FooterButton(
                  icon: Icons.settings_outlined,
                  label: 'الإعدادات',
                  onTap: () {
                    Navigator.pop(context);
                    context.go('/settings');
                  },
                ),
              ),
            ],
          ),
          SizedBox(height: AppSpacing.md),
          // Version Info
          Text(
            'الإصدار 2.0.0 Pro',
            style: AppTypography.bodySmall.copyWith(
              color: AppColors.textTertiary,
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// Navigation Section
// ═══════════════════════════════════════════════════════════════════════════

class _NavSection extends StatelessWidget {
  final String title;
  final List<Widget> children;

  const _NavSection({
    required this.title,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.sm,
          ),
          child: Text(
            title,
            style: AppTypography.labelSmall.copyWith(
              color: AppColors.textTertiary,
              letterSpacing: 0.5,
            ),
          ),
        ),
        ...children,
        SizedBox(height: AppSpacing.sm),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// Navigation Item
// ═══════════════════════════════════════════════════════════════════════════

class _NavItem extends StatelessWidget {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final String route;
  final String? currentRoute;
  final String? badge;
  final Color? badgeColor;

  const _NavItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.route,
    this.currentRoute,
    this.badge,
    this.badgeColor,
  });

  bool get isActive => currentRoute == route;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: 2.h,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            Navigator.pop(context);
            context.go(route);
          },
          borderRadius: BorderRadius.circular(AppRadius.md),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.md,
            ),
            decoration: BoxDecoration(
              color: isActive
                  ? AppColors.primary.withValues(alpha: 0.1)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
            child: Row(
              children: [
                Icon(
                  isActive ? activeIcon : icon,
                  color: isActive ? AppColors.primary : AppColors.textSecondary,
                  size: 22.sp,
                ),
                SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Text(
                    label,
                    style: AppTypography.bodyMedium.copyWith(
                      color:
                          isActive ? AppColors.primary : AppColors.textPrimary,
                      fontWeight:
                          isActive ? FontWeight.w600 : FontWeight.normal,
                    ),
                  ),
                ),
                if (badge != null)
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: AppSpacing.sm,
                      vertical: 2.h,
                    ),
                    decoration: BoxDecoration(
                      color: badgeColor ?? AppColors.primary,
                      borderRadius: BorderRadius.circular(AppRadius.full),
                    ),
                    child: Text(
                      badge!,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 11.sp,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// Footer Button
// ═══════════════════════════════════════════════════════════════════════════

class _FooterButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final String? badge;

  const _FooterButton({
    required this.icon,
    required this.label,
    required this.onTap,
    this.badge,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surfaceVariant,
      borderRadius: BorderRadius.circular(AppRadius.md),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.md),
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.sm,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Stack(
                clipBehavior: Clip.none,
                children: [
                  Icon(
                    icon,
                    color: AppColors.textSecondary,
                    size: 20.sp,
                  ),
                  if (badge != null)
                    Positioned(
                      top: -6,
                      right: -6,
                      child: Container(
                        padding: EdgeInsets.all(4.w),
                        decoration: const BoxDecoration(
                          color: AppColors.error,
                          shape: BoxShape.circle,
                        ),
                        child: Text(
                          badge!,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 9.sp,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              SizedBox(width: AppSpacing.sm),
              Text(
                label,
                style: AppTypography.labelMedium.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
