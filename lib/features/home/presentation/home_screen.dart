import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gap/gap.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/di/injection.dart';
import '../../../core/services/sync_service.dart';
import '../../../data/repositories/shift_repository.dart';
import '../../widgets/sync_status_widget.dart';
import '../../widgets/menu_card.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  final _syncService = getIt<SyncService>();
  final _shiftRepo = getIt<ShiftRepository>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Hoor Manager'),
        actions: [
          const SyncStatusWidget(),
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () => context.push('/settings'),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await _syncService.syncAll();
        },
        child: StreamBuilder<bool>(
          stream: _shiftRepo.watchOpenShift().map((shift) => shift != null),
          initialData: false,
          builder: (context, snapshot) {
            final hasOpenShift = snapshot.data ?? false;
            return SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: EdgeInsets.all(16.w),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Shift Status Card
                  _buildShiftStatusCard(hasOpenShift),
                  Gap(20.h),

                  // Quick Actions
                  Text(
                    'إجراءات سريعة',
                    style: TextStyle(
                      fontSize: 18.sp,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Gap(12.h),
                  _buildQuickActions(hasOpenShift),
                  Gap(24.h),

                  // Main Menu
                  Text(
                    'القائمة الرئيسية',
                    style: TextStyle(
                      fontSize: 18.sp,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Gap(12.h),
                  _buildMainMenu(),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildShiftStatusCard(bool hasOpenShift) {
    return Card(
      color: hasOpenShift
          ? AppColors.success.withOpacity(0.1)
          : AppColors.warning.withOpacity(0.1),
      child: Padding(
        padding: EdgeInsets.all(16.w),
        child: Row(
          children: [
            Icon(
              hasOpenShift ? Icons.check_circle : Icons.warning,
              color: hasOpenShift ? AppColors.success : AppColors.warning,
              size: 32.sp,
            ),
            Gap(12.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    hasOpenShift ? 'الوردية مفتوحة' : 'لا توجد وردية مفتوحة',
                    style: TextStyle(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    hasOpenShift
                        ? 'يمكنك إجراء العمليات المالية'
                        : 'افتح وردية جديدة للبدء',
                    style: TextStyle(
                      fontSize: 14.sp,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            ElevatedButton(
              onPressed: () => context.push('/shifts'),
              style: ElevatedButton.styleFrom(
                backgroundColor:
                    hasOpenShift ? AppColors.success : AppColors.warning,
              ),
              child: Text(hasOpenShift ? 'إدارة' : 'فتح'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActions(bool hasOpenShift) {
    return Row(
      children: [
        Expanded(
          child: _QuickActionButton(
            icon: Icons.point_of_sale,
            label: 'فاتورة مبيعات',
            color: AppColors.sales,
            onTap: () => context.push('/invoices/new/sale'),
          ),
        ),
        Gap(12.w),
        Expanded(
          child: _QuickActionButton(
            icon: Icons.shopping_cart,
            label: 'فاتورة مشتريات',
            color: AppColors.purchases,
            onTap: () => context.push('/invoices/new/purchase'),
          ),
        ),
        Gap(12.w),
        Expanded(
          child: _QuickActionButton(
            icon: Icons.assignment_return,
            label: 'مرتجعات',
            color: AppColors.returns,
            onTap: () => context.push('/invoices/new/sale_return'),
          ),
        ),
      ],
    );
  }

  Widget _buildMainMenu() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // قسم المبيعات والفواتير
        _buildSectionTitle('المبيعات والفواتير', Icons.shopping_bag),
        Gap(8.h),
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 3,
          mainAxisSpacing: 10.h,
          crossAxisSpacing: 10.w,
          childAspectRatio: 0.75,
          children: [
            MenuCard(
              icon: Icons.receipt_long,
              title: 'الفواتير',
              subtitle: 'عرض الفواتير',
              color: AppColors.sales,
              onTap: () => context.push('/invoices'),
            ),
            MenuCard(
              icon: Icons.people,
              title: 'العملاء',
              subtitle: 'إدارة العملاء',
              color: AppColors.primaryLight,
              onTap: () => context.push('/customers'),
            ),
            MenuCard(
              icon: Icons.local_shipping,
              title: 'الموردين',
              subtitle: 'إدارة الموردين',
              color: AppColors.purchases,
              onTap: () => context.push('/suppliers'),
            ),
          ],
        ),
        Gap(20.h),

        // قسم المخزون والمنتجات
        _buildSectionTitle('المخزون والمنتجات', Icons.inventory),
        Gap(8.h),
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 3,
          mainAxisSpacing: 10.h,
          crossAxisSpacing: 10.w,
          childAspectRatio: 0.75,
          children: [
            MenuCard(
              icon: Icons.inventory_2,
              title: 'المنتجات',
              subtitle: 'إدارة المنتجات',
              color: AppColors.primary,
              onTap: () => context.push('/products'),
            ),
            MenuCard(
              icon: Icons.category,
              title: 'التصنيفات',
              subtitle: 'تصنيفات المواد',
              color: AppColors.secondary,
              onTap: () => context.push('/categories'),
            ),
            MenuCard(
              icon: Icons.warehouse,
              title: 'المخزون',
              subtitle: 'حركة المخزون',
              color: AppColors.inventory,
              onTap: () => context.push('/inventory'),
            ),
          ],
        ),
        Gap(20.h),

        // قسم المالية والتقارير
        _buildSectionTitle('المالية والتقارير', Icons.account_balance),
        Gap(8.h),
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 3,
          mainAxisSpacing: 10.h,
          crossAxisSpacing: 10.w,
          childAspectRatio: 0.75,
          children: [
            MenuCard(
              icon: Icons.access_time,
              title: 'الورديات',
              subtitle: 'إدارة الورديات',
              color: AppColors.accent,
              onTap: () => context.push('/shifts'),
            ),
            MenuCard(
              icon: Icons.account_balance_wallet,
              title: 'الصندوق',
              subtitle: 'حركة الصندوق',
              color: AppColors.income,
              onTap: () => context.push('/cash'),
            ),
            MenuCard(
              icon: Icons.bar_chart,
              title: 'التقارير',
              subtitle: 'تقارير شاملة',
              color: AppColors.info,
              onTap: () => context.push('/reports'),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSectionTitle(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 20.sp, color: AppColors.textSecondary),
        Gap(8.w),
        Text(
          title,
          style: TextStyle(
            fontSize: 16.sp,
            fontWeight: FontWeight.bold,
            color: AppColors.textSecondary,
          ),
        ),
        Gap(8.w),
        Expanded(
          child: Divider(color: AppColors.textSecondary.withOpacity(0.3)),
        ),
      ],
    );
  }
}

class _QuickActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _QuickActionButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: color,
      borderRadius: BorderRadius.circular(12.r),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12.r),
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 16.h, horizontal: 8.w),
          child: Column(
            children: [
              Icon(icon, color: Colors.white, size: 28.sp),
              Gap(8.h),
              Text(
                label,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 12.sp,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
