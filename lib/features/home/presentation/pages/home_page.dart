import 'package:flutter/material.dart';
import '../../../../app/theme/app_theme.dart';
import '../../../../app/routes/app_router.dart';
import '../../../../shared/widgets/common_widgets.dart';

/// الصفحة الرئيسية
class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('تاجر'),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () => Navigator.pushNamed(context, AppRoutes.priceInquiry),
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () => Navigator.pushNamed(context, AppRoutes.settings),
          ),
        ],
      ),
      drawer: const AppDrawer(),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // قسم: إنشاء فواتير وسندات جديدة
            const SectionHeader(
              title: 'إنشاء فواتير وسندات جديدة',
              icon: Icons.add_circle_outline,
            ),
            MenuGrid(
              items: [
                MenuTileData(
                  icon: Icons.search,
                  title: 'استعلام عن سعر',
                  color: AppColors.info,
                  onTap: () => Navigator.pushNamed(context, AppRoutes.priceInquiry),
                ),
                MenuTileData(
                  icon: Icons.point_of_sale,
                  title: 'فاتورة مبيعات',
                  color: AppColors.success,
                  onTap: () => Navigator.pushNamed(context, AppRoutes.salesInvoice),
                ),
                MenuTileData(
                  icon: Icons.shopping_cart,
                  title: 'فاتورة مشتريات',
                  color: AppColors.warning,
                  onTap: () => Navigator.pushNamed(context, AppRoutes.purchaseInvoice),
                ),
                MenuTileData(
                  icon: Icons.assignment_return,
                  title: 'فاتورة مرتجعات',
                  color: AppColors.error,
                  onTap: () => Navigator.pushNamed(context, AppRoutes.returns),
                ),
                MenuTileData(
                  icon: Icons.receipt_long,
                  title: 'سند قبض',
                  color: AppColors.success,
                  onTap: () => Navigator.pushNamed(context, AppRoutes.voucher, arguments: 'receipt'),
                ),
                MenuTileData(
                  icon: Icons.payments,
                  title: 'سند صرف',
                  color: AppColors.error,
                  onTap: () => Navigator.pushNamed(context, AppRoutes.voucher, arguments: 'payment'),
                ),
              ],
            ),
            
            // قسم: استعراض الفواتير
            const SectionHeader(
              title: 'استعراض الفواتير',
              icon: Icons.list_alt,
            ),
            MenuGrid(
              items: [
                MenuTileData(
                  icon: Icons.trending_up,
                  title: 'استعراض المبيعات',
                  color: AppColors.success,
                  onTap: () => Navigator.pushNamed(context, AppRoutes.salesList),
                ),
                MenuTileData(
                  icon: Icons.trending_down,
                  title: 'استعراض المشتريات',
                  color: AppColors.warning,
                  onTap: () => Navigator.pushNamed(context, AppRoutes.purchasesList),
                ),
                MenuTileData(
                  icon: Icons.undo,
                  title: 'مرتجعات المبيعات',
                  color: AppColors.error,
                  onTap: () => Navigator.pushNamed(context, AppRoutes.salesReturnsList),
                ),
                MenuTileData(
                  icon: Icons.redo,
                  title: 'مرتجعات المشتريات',
                  color: AppColors.info,
                  onTap: () => Navigator.pushNamed(context, AppRoutes.purchaseReturnsList),
                ),
              ],
            ),
            
            // قسم: المواد وتصنيفاتها
            const SectionHeader(
              title: 'المواد وتصنيفاتها',
              icon: Icons.inventory_2,
            ),
            MenuGrid(
              items: [
                MenuTileData(
                  icon: Icons.inventory,
                  title: 'بطاقات المواد',
                  color: AppColors.primary,
                  onTap: () => Navigator.pushNamed(context, AppRoutes.products),
                ),
                MenuTileData(
                  icon: Icons.category,
                  title: 'تصنيفات المواد',
                  color: AppColors.secondary,
                  onTap: () => Navigator.pushNamed(context, AppRoutes.categories),
                ),
                MenuTileData(
                  icon: Icons.fact_check,
                  title: 'جرد المستودع',
                  color: AppColors.info,
                  onTap: () => Navigator.pushNamed(context, AppRoutes.inventoryCount),
                ),
                MenuTileData(
                  icon: Icons.inventory_2_outlined,
                  title: 'فاتورة أول المدة',
                  color: AppColors.warning,
                  onTap: () => Navigator.pushNamed(context, AppRoutes.openingBalance),
                ),
                MenuTileData(
                  icon: Icons.price_change,
                  title: 'تعديل الأسعار',
                  color: AppColors.success,
                  onTap: () => Navigator.pushNamed(context, AppRoutes.priceUpdate),
                ),
              ],
            ),
            
            // قسم: الاستعلام عن
            const SectionHeader(
              title: 'الاستعلام عن',
              icon: Icons.search,
            ),
            MenuGrid(
              items: [
                MenuTileData(
                  icon: Icons.account_balance_wallet,
                  title: 'حركة حساب',
                  color: AppColors.primary,
                  onTap: () => Navigator.pushNamed(context, AppRoutes.accountMovement),
                ),
                MenuTileData(
                  icon: Icons.swap_horiz,
                  title: 'حركة مادة',
                  color: AppColors.info,
                  onTap: () => Navigator.pushNamed(context, AppRoutes.productMovement),
                ),
                MenuTileData(
                  icon: Icons.today,
                  title: 'الحركة اليومية',
                  color: AppColors.success,
                  onTap: () => Navigator.pushNamed(context, AppRoutes.dailyMovement),
                ),
                MenuTileData(
                  icon: Icons.summarize,
                  title: 'إجمالي حركة المواد',
                  color: AppColors.warning,
                  onTap: () => Navigator.pushNamed(context, AppRoutes.totalProductMovement),
                ),
              ],
            ),
            
            // قسم: الحسابات
            const SectionHeader(
              title: 'الحسابات',
              icon: Icons.people,
            ),
            MenuGrid(
              items: [
                MenuTileData(
                  icon: Icons.person,
                  title: 'الزبائن',
                  color: AppColors.success,
                  onTap: () => Navigator.pushNamed(context, AppRoutes.customers),
                ),
                MenuTileData(
                  icon: Icons.local_shipping,
                  title: 'الموردون',
                  color: AppColors.warning,
                  onTap: () => Navigator.pushNamed(context, AppRoutes.suppliers),
                ),
                MenuTileData(
                  icon: Icons.account_balance,
                  title: 'الصناديق والبنوك',
                  color: AppColors.primary,
                  onTap: () => Navigator.pushNamed(context, AppRoutes.cashAccounts),
                ),
                MenuTileData(
                  icon: Icons.account_tree,
                  title: 'شجرة الحسابات',
                  color: AppColors.info,
                  onTap: () => Navigator.pushNamed(context, AppRoutes.accountsTree),
                ),
              ],
            ),
            
            // قسم: الديون والمستحقات
            const SectionHeader(
              title: 'الديون والمستحقات',
              icon: Icons.monetization_on,
            ),
            MenuGrid(
              items: [
                MenuTileData(
                  icon: Icons.arrow_circle_down,
                  title: 'الديون (لنا)',
                  subtitle: 'المستحق من الزبائن',
                  color: AppColors.success,
                  onTap: () => Navigator.pushNamed(context, AppRoutes.debts),
                ),
                MenuTileData(
                  icon: Icons.arrow_circle_up,
                  title: 'المستحقات (علينا)',
                  subtitle: 'المستحق للموردين',
                  color: AppColors.error,
                  onTap: () => Navigator.pushNamed(context, AppRoutes.payables),
                ),
              ],
            ),
            
            // قسم: التقارير المالية
            const SectionHeader(
              title: 'التقارير المالية',
              icon: Icons.bar_chart,
            ),
            MenuGrid(
              items: [
                MenuTileData(
                  icon: Icons.summarize,
                  title: 'ملخص الحركة',
                  color: AppColors.primary,
                  onTap: () => Navigator.pushNamed(context, AppRoutes.movementSummary),
                ),
                MenuTileData(
                  icon: Icons.trending_up,
                  title: 'الأرباح والخسائر',
                  color: AppColors.success,
                  onTap: () => Navigator.pushNamed(context, AppRoutes.profitLoss),
                ),
              ],
            ),
            
            const SizedBox(height: AppSizes.paddingLG),
          ],
        ),
      ),
    );
  }
}

/// القائمة الجانبية
class AppDrawer extends StatelessWidget {
  const AppDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: Column(
        children: [
          // الهيدر
          Container(
            width: double.infinity,
            padding: EdgeInsets.only(
              top: MediaQuery.of(context).padding.top + 24,
              bottom: 24,
              left: 16,
              right: 16,
            ),
            decoration: const BoxDecoration(
              color: AppColors.primary,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.store,
                    color: Colors.white,
                    size: 40,
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'تاجر',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Text(
                  'نظام إدارة تجارية متكامل',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          
          // القائمة
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                ListTileWithIcon(
                  icon: Icons.home,
                  title: 'الرئيسية',
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.pushNamedAndRemoveUntil(
                      context,
                      AppRoutes.home,
                      (route) => false,
                    );
                  },
                ),
                const Divider(),
                ListTileWithIcon(
                  icon: Icons.point_of_sale,
                  title: 'نقطة البيع',
                  iconColor: AppColors.success,
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.pushNamed(context, AppRoutes.salesInvoice);
                  },
                ),
                ListTileWithIcon(
                  icon: Icons.inventory,
                  title: 'المنتجات',
                  iconColor: AppColors.primary,
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.pushNamed(context, AppRoutes.products);
                  },
                ),
                ListTileWithIcon(
                  icon: Icons.people,
                  title: 'العملاء',
                  iconColor: AppColors.info,
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.pushNamed(context, AppRoutes.customers);
                  },
                ),
                ListTileWithIcon(
                  icon: Icons.bar_chart,
                  title: 'التقارير',
                  iconColor: AppColors.warning,
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.pushNamed(context, AppRoutes.movementSummary);
                  },
                ),
                const Divider(),
                ListTileWithIcon(
                  icon: Icons.settings,
                  title: 'الإعدادات',
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.pushNamed(context, AppRoutes.settings);
                  },
                ),
                ListTileWithIcon(
                  icon: Icons.print,
                  title: 'إعدادات الطباعة',
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.pushNamed(context, AppRoutes.printSettings);
                  },
                ),
              ],
            ),
          ),
          
          // التذييل
          Container(
            padding: const EdgeInsets.all(16),
            child: const Text(
              'الإصدار 1.0.0',
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
