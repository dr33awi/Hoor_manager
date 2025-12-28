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

  bool _hasOpenShift = false;

  @override
  void initState() {
    super.initState();
    _checkOpenShift();
  }

  Future<void> _checkOpenShift() async {
    final hasOpen = await _shiftRepo.hasOpenShift();
    setState(() => _hasOpenShift = hasOpen);
  }

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
          await _checkOpenShift();
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: EdgeInsets.all(16.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Shift Status Card
              _buildShiftStatusCard(),
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
              _buildQuickActions(),
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
        ),
      ),
    );
  }

  Widget _buildShiftStatusCard() {
    return Card(
      color: _hasOpenShift
          ? AppColors.success.withOpacity(0.1)
          : AppColors.warning.withOpacity(0.1),
      child: Padding(
        padding: EdgeInsets.all(16.w),
        child: Row(
          children: [
            Icon(
              _hasOpenShift ? Icons.check_circle : Icons.warning,
              color: _hasOpenShift ? AppColors.success : AppColors.warning,
              size: 32.sp,
            ),
            Gap(12.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _hasOpenShift ? 'الوردية مفتوحة' : 'لا توجد وردية مفتوحة',
                    style: TextStyle(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    _hasOpenShift
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
                    _hasOpenShift ? AppColors.success : AppColors.warning,
              ),
              child: Text(_hasOpenShift ? 'إدارة' : 'فتح'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActions() {
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
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      mainAxisSpacing: 12.h,
      crossAxisSpacing: 12.w,
      childAspectRatio: 1.3,
      children: [
        MenuCard(
          icon: Icons.inventory_2,
          title: 'المنتجات',
          subtitle: 'إدارة المنتجات والمخزون',
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
          icon: Icons.receipt_long,
          title: 'الفواتير',
          subtitle: 'عرض جميع الفواتير',
          color: AppColors.sales,
          onTap: () => context.push('/invoices'),
        ),
        MenuCard(
          icon: Icons.warehouse,
          title: 'المخزون',
          subtitle: 'حركة وجرد المخزون',
          color: AppColors.inventory,
          onTap: () => context.push('/inventory'),
        ),
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
          subtitle: 'تقارير المبيعات والمخزون',
          color: AppColors.info,
          onTap: () => context.push('/reports'),
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
        MenuCard(
          icon: Icons.backup,
          title: 'النسخ الاحتياطي',
          subtitle: 'حفظ واستعادة البيانات',
          color: AppColors.success,
          onTap: () => context.push('/backup'),
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
