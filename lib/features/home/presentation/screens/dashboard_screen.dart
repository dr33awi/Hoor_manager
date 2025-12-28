import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:hoor_manager/core/services/barcode_service.dart';

import '../../../../core/constants/constants.dart';
import '../../../../core/extensions/extensions.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../reports/domain/entities/entities.dart';
import '../../../reports/presentation/providers/reports_providers.dart';
import '../../../reports/presentation/widgets/widgets.dart';
import '../../../products/presentation/providers/product_providers.dart';

/// شاشة لوحة التحكم الرئيسية
class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    // استخدام StreamProvider للتحديث التلقائي
    final summaryAsync = ref.watch(dashboardSummaryStreamProvider);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.menu),
          onPressed: () => Scaffold.of(context).openDrawer(),
          tooltip: 'القائمة',
        ),
        title: const Text(
          'الرئيسية',
          style: TextStyle(fontSize: 18),
        ),
        actions: [
          // إشعارات المخزون
          summaryAsync.whenData(
                (summary) {
                  final alertCount =
                      summary.lowStockCount + summary.outOfStockCount;
                  if (alertCount == 0) return const SizedBox.shrink();
                  return Padding(
                    padding: const EdgeInsets.only(left: AppSizes.sm),
                    child: Badge(
                      label: Text(
                        '$alertCount',
                        style: const TextStyle(fontSize: 10),
                      ),
                      alignment: Alignment.topRight,
                      offset: const Offset(-4, 4),
                      child: IconButton(
                        icon: const Icon(Icons.notifications_outlined),
                        onPressed: () =>
                            _showStockAlerts(context, ref, summary),
                      ),
                    ),
                  );
                },
              ).value ??
              const SizedBox.shrink(),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(dashboardSummaryStreamProvider);
        },
        child: summaryAsync.when(
          data: (summary) => _buildDashboard(context, ref, summary),
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(child: Text('خطأ: $e')),
        ),
      ),
    );
  }

  Widget _buildDashboard(
    BuildContext context,
    WidgetRef ref,
    DashboardSummary summary,
  ) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSizes.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // بطاقة الترحيب والتاريخ
          _buildWelcomeCard(context, ref),

          const SizedBox(height: AppSizes.md),

          // إحصائيات اليوم
          Text(
            'إحصائيات اليوم',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: AppSizes.sm),
          Row(
            children: [
              Expanded(
                child: _QuickStatCard(
                  title: 'المبيعات',
                  value: summary.todaySales.toCurrency(),
                  icon: Icons.attach_money,
                  color: AppColors.primary,
                  onTap: () => context.push('/reports/sales'),
                ),
              ),
              const SizedBox(width: AppSizes.sm),
              Expanded(
                child: _QuickStatCard(
                  title: 'الأرباح',
                  value: summary.todayProfit.toCurrency(),
                  icon: Icons.trending_up,
                  color: AppColors.success,
                  onTap: () => context.push('/reports/profits'),
                ),
              ),
            ],
          ),

          const SizedBox(height: AppSizes.sm),

          Row(
            children: [
              Expanded(
                child: _QuickStatCard(
                  title: 'الفواتير',
                  value: '${summary.todayInvoices}',
                  icon: Icons.receipt_long,
                  color: AppColors.info,
                  onTap: () => context.go('/sales'),
                ),
              ),
              const SizedBox(width: AppSizes.sm),
              Expanded(
                child: _QuickStatCard(
                  title: 'مبيعات الشهر',
                  value: summary.monthSales.toCompactCurrency(),
                  icon: Icons.calendar_month,
                  color: AppColors.secondary,
                  valueColor: AppColors.textPrimary,
                  onTap: () => context.push('/reports/sales'),
                ),
              ),
            ],
          ),

          const SizedBox(height: AppSizes.lg),

          // الوصول السريع
          Text(
            'الوصول السريع',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: AppSizes.sm),
          _buildQuickActions(context, ref),

          const SizedBox(height: AppSizes.lg),

          // تنبيهات المخزون
          if (summary.lowStockCount > 0 || summary.outOfStockCount > 0) ...[
            _buildStockAlert(context, summary),
            const SizedBox(height: AppSizes.lg),
          ],

          // المنتجات الأكثر مبيعاً
          if (summary.topProducts.isNotEmpty) ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'الأكثر مبيعاً',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                TextButton(
                  onPressed: () => context.push('/reports/top-products'),
                  child: const Text('عرض الكل'),
                ),
              ],
            ),
            const SizedBox(height: AppSizes.sm),
            ...summary.topProducts.take(3).map<Widget>((product) {
              return TopProductTile(product: product);
            }),
          ],

          const SizedBox(height: AppSizes.xl),
        ],
      ),
    );
  }

  Widget _buildWelcomeCard(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    return Container(
      padding: const EdgeInsets.all(AppSizes.md),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.primary, AppColors.primary.withOpacity(0.8)],
        ),
        borderRadius: BorderRadius.circular(AppSizes.radiusMd),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  DateTime.now().toArabicDate(),
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.textLight.withOpacity(0.8),
                      ),
                ),
                const SizedBox(height: AppSizes.xs),
                Text(
                  '${_getGreeting()} ${user?.fullName ?? ''}',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: AppColors.textLight,
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(AppSizes.sm),
            decoration: BoxDecoration(
              color: AppColors.secondary.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: SvgPicture.asset(
              'assets/images/Hoor_1.svg',
              width: 40,
              height: 40,
              colorFilter: const ColorFilter.mode(
                AppColors.secondary,
                BlendMode.srcIn,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions(BuildContext context, WidgetRef ref) {
    return Row(
      children: [
        Expanded(
          child: _QuickActionButton(
            icon: Icons.add_shopping_cart,
            label: 'بيع جديد',
            color: AppColors.primary,
            onTap: () => context.push('/sales/new'),
          ),
        ),
        const SizedBox(width: AppSizes.sm),
        Expanded(
          child: _QuickActionButton(
            icon: Icons.add_box,
            label: 'منتج جديد',
            color: AppColors.success,
            onTap: () => context.push('/products/add'),
          ),
        ),
        const SizedBox(width: AppSizes.sm),
        Expanded(
          child: _QuickActionButton(
            icon: Icons.qr_code_scanner,
            label: 'مسح باركود',
            color: AppColors.info,
            onTap: () => _showBarcodeScanner(context, ref),
          ),
        ),
      ],
    );
  }

  Widget _buildStockAlert(BuildContext context, DashboardSummary summary) {
    return Card(
      color: AppColors.warning.withOpacity(0.1),
      child: InkWell(
        onTap: () => context.push('/reports/inventory'),
        borderRadius: BorderRadius.circular(AppSizes.radiusMd),
        child: Padding(
          padding: const EdgeInsets.all(AppSizes.md),
          child: Row(
            children: [
              const Icon(Icons.warning_amber,
                  color: AppColors.warning, size: 32),
              const SizedBox(width: AppSizes.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'تنبيهات المخزون',
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                    Text(
                      '${summary.outOfStockCount} نفد • ${summary.lowStockCount} منخفض',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppColors.textSecondary,
                          ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_left, color: AppColors.textSecondary),
            ],
          ),
        ),
      ),
    );
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'صباح الخير';
    if (hour < 17) return 'مساء الخير';
    return 'مساء الخير';
  }

  void _showStockAlerts(
      BuildContext context, WidgetRef ref, DashboardSummary summary) {
    context.push('/reports/inventory');
  }

  Future<void> _showBarcodeScanner(BuildContext context, WidgetRef ref) async {
    final barcode = await BarcodeScannerService.scan(context);

    if (barcode != null && barcode.isNotEmpty && context.mounted) {
      // البحث عن المنتج بالباركود
      final productAsync =
          await ref.read(productByBarcodeProvider(barcode).future);

      if (context.mounted) {
        if (productAsync != null) {
          context.push('/products/${productAsync.id}');
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('لم يتم العثور على منتج بالباركود: $barcode'),
              action: SnackBarAction(
                label: 'إضافة منتج',
                onPressed: () => context.push('/products/add'),
              ),
            ),
          );
        }
      }
    }
  }
}

/// بطاقة إحصائية سريعة
class _QuickStatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;
  final Color? valueColor;
  final VoidCallback? onTap;

  const _QuickStatCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
    this.valueColor,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppSizes.radiusMd),
        child: Padding(
          padding: const EdgeInsets.all(AppSizes.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(AppSizes.xs),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(AppSizes.radiusSm),
                    ),
                    child: Icon(icon, color: color, size: 18),
                  ),
                  const Spacer(),
                  Icon(Icons.chevron_left, size: 16, color: AppColors.textHint),
                ],
              ),
              const SizedBox(height: AppSizes.sm),
              Text(
                value,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: valueColor ?? color,
                    ),
              ),
              Text(
                title,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
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

/// زر إجراء سريع
class _QuickActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback? onTap;

  const _QuickActionButton({
    required this.icon,
    required this.label,
    required this.color,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppSizes.radiusMd),
        child: Padding(
          padding: const EdgeInsets.all(AppSizes.md),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(AppSizes.sm),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color),
              ),
              const SizedBox(height: AppSizes.sm),
              Text(
                label,
                style: Theme.of(context).textTheme.bodySmall,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
