import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/presentation/providers/auth_provider.dart';
import '../constants/constants.dart';

/// عنصر في القائمة الجانبية
class DrawerItem {
  final IconData icon;
  final IconData? selectedIcon;
  final String title;
  final String? route;
  final VoidCallback? onTap;
  final bool isDivider;
  final Color? iconColor;

  const DrawerItem({
    required this.icon,
    this.selectedIcon,
    required this.title,
    this.route,
    this.onTap,
    this.isDivider = false,
    this.iconColor,
  });

  const DrawerItem.divider()
      : icon = Icons.horizontal_rule,
        selectedIcon = null,
        title = '',
        route = null,
        onTap = null,
        isDivider = true,
        iconColor = null;
}

/// الشريط الجانبي للتطبيق
class AppDrawer extends ConsumerWidget {
  final int currentIndex;
  final Function(int) onIndexChanged;

  const AppDrawer({
    super.key,
    required this.currentIndex,
    required this.onIndexChanged,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);

    return Drawer(
      backgroundColor: AppColors.surface,
      child: SafeArea(
        child: Column(
          children: [
            // رأس الشريط الجانبي
            _buildHeader(context, user),

            const Divider(height: 1),

            // قائمة الصفحات الرئيسية
            Expanded(
              child: ListView(
                padding: EdgeInsets.zero,
                children: [
                  const SizedBox(height: AppSizes.sm),

                  // الصفحات الرئيسية
                  _buildSectionTitle(context, 'الصفحات الرئيسية'),
                  _buildNavItem(
                    context: context,
                    icon: Icons.dashboard_outlined,
                    selectedIcon: Icons.dashboard,
                    title: 'الرئيسية',
                    index: 0,
                    isSelected: currentIndex == 0,
                  ),
                  _buildNavItem(
                    context: context,
                    icon: Icons.inventory_2_outlined,
                    selectedIcon: Icons.inventory_2,
                    title: 'المنتجات',
                    index: 1,
                    isSelected: currentIndex == 1,
                  ),
                  _buildQuickActionItem(
                    context: context,
                    icon: Icons.warehouse_outlined,
                    title: 'المخزون',
                    route: '/inventory',
                    color: AppColors.warning,
                  ),
                  _buildNavItem(
                    context: context,
                    icon: Icons.point_of_sale_outlined,
                    selectedIcon: Icons.point_of_sale,
                    title: 'المبيعات',
                    index: 2,
                    isSelected: currentIndex == 2,
                  ),
                  _buildQuickActionItem(
                    context: context,
                    icon: Icons.receipt_long_outlined,
                    title: 'الفواتير',
                    route: '/invoices',
                    color: AppColors.info,
                  ),
                  _buildNavItem(
                    context: context,
                    icon: Icons.bar_chart_outlined,
                    selectedIcon: Icons.bar_chart,
                    title: 'التقارير',
                    index: 3,
                    isSelected: currentIndex == 3,
                  ),
                  _buildNavItem(
                    context: context,
                    icon: Icons.settings_outlined,
                    selectedIcon: Icons.settings,
                    title: 'الإعدادات',
                    index: 4,
                    isSelected: currentIndex == 4,
                  ),

                  const Divider(height: AppSizes.lg),

                  // التقارير
                  _buildSectionTitle(context, 'التقارير'),
                  _buildQuickActionItem(
                    context: context,
                    icon: Icons.receipt_long,
                    title: 'تقرير المبيعات',
                    route: '/reports/sales',
                    color: AppColors.primary,
                  ),
                  _buildQuickActionItem(
                    context: context,
                    icon: Icons.trending_up,
                    title: 'تقرير الأرباح',
                    route: '/reports/profits',
                    color: AppColors.success,
                  ),
                  _buildQuickActionItem(
                    context: context,
                    icon: Icons.inventory,
                    title: 'تقرير المخزون',
                    route: '/reports/inventory',
                    color: AppColors.warning,
                  ),
                  _buildQuickActionItem(
                    context: context,
                    icon: Icons.star,
                    title: 'الأكثر مبيعاً',
                    route: '/reports/top-products',
                    color: AppColors.info,
                  ),

                  const Divider(height: AppSizes.lg),

                  // إدارة المستخدمين
                  _buildSectionTitle(context, 'الإدارة'),
                  _buildQuickActionItem(
                    context: context,
                    icon: Icons.people,
                    title: 'إدارة المستخدمين',
                    route: '/users',
                    color: AppColors.primary,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// رأس الشريط الجانبي
  Widget _buildHeader(BuildContext context, user) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSizes.md),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.primary, AppColors.primaryLight],
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
        ),
      ),
      child: SvgPicture.asset(
        'assets/images/Hoor.svg',
        height: 80,
        fit: BoxFit.contain,
        colorFilter: const ColorFilter.mode(
          AppColors.secondary,
          BlendMode.srcIn,
        ),
      ),
    );
  }

  /// عنوان القسم
  Widget _buildSectionTitle(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSizes.lg,
        vertical: AppSizes.sm,
      ),
      child: Text(
        title,
        style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: AppColors.textSecondary,
              fontWeight: FontWeight.bold,
            ),
      ),
    );
  }

  /// عنصر التنقل الرئيسي
  Widget _buildNavItem({
    required BuildContext context,
    required IconData icon,
    required IconData selectedIcon,
    required String title,
    required int index,
    required bool isSelected,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(
        horizontal: AppSizes.sm,
        vertical: AppSizes.xs,
      ),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppSizes.radiusMd),
        color: isSelected ? AppColors.primary.withOpacity(0.1) : null,
      ),
      child: ListTile(
        leading: Icon(
          isSelected ? selectedIcon : icon,
          color: isSelected ? AppColors.primary : AppColors.textSecondary,
        ),
        title: Text(
          title,
          style: TextStyle(
            color: isSelected ? AppColors.primary : AppColors.textPrimary,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSizes.radiusMd),
        ),
        onTap: () {
          Navigator.pop(context); // إغلاق الشريط الجانبي
          onIndexChanged(index);
        },
        selected: isSelected,
      ),
    );
  }

  /// عنصر الوصول السريع
  Widget _buildQuickActionItem({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String route,
    required Color color,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(
        horizontal: AppSizes.sm,
        vertical: AppSizes.xs,
      ),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(AppSizes.xs),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(AppSizes.radiusSm),
          ),
          child: Icon(
            icon,
            color: color,
            size: 20,
          ),
        ),
        title: Text(
          title,
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontSize: 14,
          ),
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSizes.radiusMd),
        ),
        onTap: () {
          Navigator.pop(context); // إغلاق الشريط الجانبي
          context.push(route);
        },
        dense: true,
      ),
    );
  }
}
