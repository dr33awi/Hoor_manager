// ═══════════════════════════════════════════════════════════════════════════
// Inventory Screen Pro - Professional Design System
// Inventory Management with Modern UI
// ═══════════════════════════════════════════════════════════════════════════

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../core/theme/design_tokens.dart';
import '../dashboard_pro/widgets/pro_navigation_drawer.dart';
import '../../core/providers/app_providers.dart';
import '../../data/database/app_database.dart';

class InventoryScreenPro extends ConsumerStatefulWidget {
  const InventoryScreenPro({super.key});

  @override
  ConsumerState<InventoryScreenPro> createState() => _InventoryScreenProState();
}

class _InventoryScreenProState extends ConsumerState<InventoryScreenPro>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _searchController.addListener(() {
      setState(() => _searchQuery = _searchController.text);
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      drawer: const ProNavigationDrawer(currentRoute: '/inventory'),
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            _buildTabBar(),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildMovementsTab(),
                  _buildAlertsTab(),
                  _buildStockTab(),
                ],
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddMovementSheet,
        backgroundColor: AppColors.primary,
        icon: const Icon(Icons.add, color: Colors.white),
        label: Text(
          'حركة جديدة',
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
                    Text('المخزون', style: AppTypography.titleLarge),
                    Text(
                      'إدارة حركات المخزون والجرد',
                      style: AppTypography.bodySmall.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: () => context.push('/inventory/warehouses'),
                icon: const Icon(Icons.warehouse_outlined),
                tooltip: 'المستودعات',
              ),
              IconButton(
                onPressed: () => context.push('/inventory/transfer'),
                icon: const Icon(Icons.swap_horiz_rounded),
                tooltip: 'نقل المخزون',
              ),
              IconButton(
                onPressed: () => context.push('/inventory/count'),
                icon: const Icon(Icons.inventory_2_outlined),
                tooltip: 'جرد المخزون',
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
                hintText: 'البحث في المخزون...',
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
          Tab(text: 'الحركات'),
          Tab(text: 'التنبيهات'),
          Tab(text: 'المخزون'),
        ],
      ),
    );
  }

  Widget _buildMovementsTab() {
    final movementsAsync = ref.watch(inventoryMovementsStreamProvider);

    return movementsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => Center(child: Text('خطأ: $error')),
      data: (movements) {
        var filtered = movements.where((m) {
          if (_searchQuery.isEmpty) return true;
          return m.reason?.toLowerCase().contains(_searchQuery.toLowerCase()) ??
              false;
        }).toList();

        if (filtered.isEmpty) {
          return _buildEmptyState(
            icon: Icons.swap_vert_rounded,
            title: 'لا توجد حركات',
            message: 'سجل حركات المخزون ستظهر هنا',
          );
        }

        return ListView.builder(
          padding: EdgeInsets.all(AppSpacing.md),
          itemCount: filtered.length,
          itemBuilder: (context, index) {
            return _MovementCard(movement: filtered[index]);
          },
        );
      },
    );
  }

  Widget _buildAlertsTab() {
    final productsAsync = ref.watch(activeProductsStreamProvider);

    return productsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => Center(child: Text('خطأ: $error')),
      data: (products) {
        final lowStock =
            products.where((p) => p.quantity <= p.minQuantity).toList();

        if (lowStock.isEmpty) {
          return _buildEmptyState(
            icon: Icons.check_circle_outline,
            title: 'لا توجد تنبيهات',
            message: 'جميع المنتجات لديها مخزون كافٍ',
          );
        }

        return ListView.builder(
          padding: EdgeInsets.all(AppSpacing.md),
          itemCount: lowStock.length,
          itemBuilder: (context, index) {
            return _LowStockCard(product: lowStock[index]);
          },
        );
      },
    );
  }

  Widget _buildStockTab() {
    final productsAsync = ref.watch(activeProductsStreamProvider);

    return productsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => Center(child: Text('خطأ: $error')),
      data: (products) {
        var filtered = products.where((p) {
          if (_searchQuery.isEmpty) return true;
          return p.name.toLowerCase().contains(_searchQuery.toLowerCase());
        }).toList();

        if (filtered.isEmpty) {
          return _buildEmptyState(
            icon: Icons.inventory_2_outlined,
            title: 'لا توجد منتجات',
            message: 'أضف منتجات لعرض المخزون',
          );
        }

        return ListView.builder(
          padding: EdgeInsets.all(AppSpacing.md),
          itemCount: filtered.length,
          itemBuilder: (context, index) {
            return _StockCard(product: filtered[index]);
          },
        );
      },
    );
  }

  Widget _buildEmptyState({
    required IconData icon,
    required String title,
    required String message,
  }) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 64.sp, color: AppColors.textTertiary),
          SizedBox(height: AppSpacing.md),
          Text(
            title,
            style: AppTypography.titleMedium.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          SizedBox(height: AppSpacing.xs),
          Text(
            message,
            style: AppTypography.bodySmall.copyWith(
              color: AppColors.textTertiary,
            ),
          ),
        ],
      ),
    );
  }

  void _showAddMovementSheet() {
    final quantityController = TextEditingController();
    final reasonController = TextEditingController();
    String selectedType = 'add';
    Product? selectedProduct;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setSheetState) {
          final productsAsync = ref.watch(activeProductsStreamProvider);

          return Container(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom,
            ),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(
                top: Radius.circular(AppRadius.xl),
              ),
            ),
            child: Padding(
              padding: EdgeInsets.all(AppSpacing.lg),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40.w,
                      height: 4.h,
                      decoration: BoxDecoration(
                        color: AppColors.border,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  SizedBox(height: AppSpacing.lg),
                  Text('حركة مخزون جديدة', style: AppTypography.titleLarge),
                  SizedBox(height: AppSpacing.lg),

                  // Movement Type
                  Text('نوع الحركة', style: AppTypography.labelLarge),
                  SizedBox(height: AppSpacing.sm),
                  Row(
                    children: [
                      Expanded(
                        child: _TypeButton(
                          label: 'إضافة',
                          icon: Icons.add_circle_outline,
                          isSelected: selectedType == 'add',
                          color: AppColors.success,
                          onTap: () =>
                              setSheetState(() => selectedType = 'add'),
                        ),
                      ),
                      SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: _TypeButton(
                          label: 'سحب',
                          icon: Icons.remove_circle_outline,
                          isSelected: selectedType == 'withdraw',
                          color: AppColors.error,
                          onTap: () =>
                              setSheetState(() => selectedType = 'withdraw'),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: AppSpacing.lg),

                  // Product Selection
                  Text('المنتج', style: AppTypography.labelLarge),
                  SizedBox(height: AppSpacing.sm),
                  productsAsync.when(
                    loading: () => const CircularProgressIndicator(),
                    error: (_, __) => const Text('خطأ في تحميل المنتجات'),
                    data: (products) => Container(
                      padding: EdgeInsets.symmetric(horizontal: AppSpacing.md),
                      decoration: BoxDecoration(
                        border: Border.all(color: AppColors.border),
                        borderRadius: BorderRadius.circular(AppRadius.md),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<Product>(
                          isExpanded: true,
                          value: selectedProduct,
                          hint: const Text('اختر المنتج'),
                          items: products
                              .map((p) => DropdownMenuItem(
                                    value: p,
                                    child: Text(p.name),
                                  ))
                              .toList(),
                          onChanged: (value) =>
                              setSheetState(() => selectedProduct = value),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: AppSpacing.md),

                  // Quantity
                  TextField(
                    controller: quantityController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: 'الكمية',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(AppRadius.md),
                      ),
                    ),
                  ),
                  SizedBox(height: AppSpacing.md),

                  // Reason
                  TextField(
                    controller: reasonController,
                    decoration: InputDecoration(
                      labelText: 'السبب (اختياري)',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(AppRadius.md),
                      ),
                    ),
                  ),
                  SizedBox(height: AppSpacing.lg),

                  // Save Button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () async {
                        if (selectedProduct == null) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('اختر المنتج')),
                          );
                          return;
                        }
                        final quantity =
                            int.tryParse(quantityController.text) ?? 0;
                        if (quantity <= 0) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('أدخل كمية صحيحة')),
                          );
                          return;
                        }

                        try {
                          final inventoryRepo =
                              ref.read(inventoryRepositoryProvider);
                          if (selectedType == 'add') {
                            await inventoryRepo.addStock(
                              productId: selectedProduct!.id,
                              quantity: quantity,
                              reason: reasonController.text.isNotEmpty
                                  ? reasonController.text
                                  : 'إضافة يدوية',
                            );
                          } else {
                            await inventoryRepo.withdrawStock(
                              productId: selectedProduct!.id,
                              quantity: quantity,
                              reason: reasonController.text.isNotEmpty
                                  ? reasonController.text
                                  : 'سحب يدوي',
                            );
                          }

                          if (context.mounted) {
                            Navigator.pop(context);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: const Text('تم تسجيل الحركة بنجاح'),
                                backgroundColor: AppColors.success,
                              ),
                            );
                          }
                        } catch (e) {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('خطأ: $e'),
                                backgroundColor: AppColors.error,
                              ),
                            );
                          }
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.all(AppSpacing.md),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppRadius.md),
                        ),
                      ),
                      child: Text(
                        'حفظ الحركة',
                        style: AppTypography.labelLarge
                            .copyWith(color: Colors.white),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// Movement Card
// ═══════════════════════════════════════════════════════════════════════════

class _MovementCard extends StatelessWidget {
  final InventoryMovement movement;

  const _MovementCard({required this.movement});

  @override
  Widget build(BuildContext context) {
    final isAdd = movement.type == 'add' || movement.type == 'purchase';
    final dateFormat = DateFormat('dd/MM/yyyy hh:mm a', 'ar');

    return Container(
      margin: EdgeInsets.only(bottom: AppSpacing.sm),
      padding: EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        boxShadow: AppShadows.sm,
      ),
      child: Row(
        children: [
          Container(
            width: 48.w,
            height: 48.h,
            decoration: BoxDecoration(
              color: (isAdd ? AppColors.success : AppColors.error)
                  .withOpacity(0.1),
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
            child: Icon(
              isAdd ? Icons.add_circle_outline : Icons.remove_circle_outline,
              color: isAdd ? AppColors.success : AppColors.error,
            ),
          ),
          SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  movement.reason ?? (isAdd ? 'إضافة' : 'سحب'),
                  style: AppTypography.titleSmall,
                ),
                Text(
                  dateFormat.format(movement.createdAt),
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.textTertiary,
                  ),
                ),
              ],
            ),
          ),
          Text(
            '${isAdd ? '+' : '-'}${movement.quantity}',
            style: AppTypography.titleMedium.copyWith(
              color: isAdd ? AppColors.success : AppColors.error,
              fontFamily: 'JetBrains Mono',
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// Low Stock Card
// ═══════════════════════════════════════════════════════════════════════════

class _LowStockCard extends StatelessWidget {
  final Product product;

  const _LowStockCard({required this.product});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(bottom: AppSpacing.sm),
      padding: EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.warning.withOpacity(0.3)),
        boxShadow: AppShadows.sm,
      ),
      child: Row(
        children: [
          Container(
            width: 48.w,
            height: 48.h,
            decoration: BoxDecoration(
              color: AppColors.warning.withOpacity(0.1),
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
            child: Icon(Icons.warning_amber_rounded, color: AppColors.warning),
          ),
          SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(product.name, style: AppTypography.titleSmall),
                Text(
                  'الحد الأدنى: ${product.minQuantity}',
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.textTertiary,
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${product.quantity}',
                style: AppTypography.titleMedium.copyWith(
                  color: AppColors.warning,
                  fontFamily: 'JetBrains Mono',
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                'متبقي',
                style: AppTypography.labelSmall.copyWith(
                  color: AppColors.textTertiary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// Stock Card
// ═══════════════════════════════════════════════════════════════════════════

class _StockCard extends StatelessWidget {
  final Product product;

  const _StockCard({required this.product});

  @override
  Widget build(BuildContext context) {
    final isLow = product.quantity <= product.minQuantity;

    return Container(
      margin: EdgeInsets.only(bottom: AppSpacing.sm),
      padding: EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        boxShadow: AppShadows.sm,
      ),
      child: Row(
        children: [
          Container(
            width: 48.w,
            height: 48.h,
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
            child: Icon(Icons.inventory_2_outlined, color: AppColors.primary),
          ),
          SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(product.name, style: AppTypography.titleSmall),
                Text(
                  'SKU: ${product.sku ?? 'N/A'}',
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.textTertiary,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.xs,
            ),
            decoration: BoxDecoration(
              color: (isLow ? AppColors.warning : AppColors.success)
                  .withOpacity(0.1),
              borderRadius: BorderRadius.circular(AppRadius.full),
            ),
            child: Text(
              '${product.quantity}',
              style: AppTypography.labelLarge.copyWith(
                color: isLow ? AppColors.warning : AppColors.success,
                fontFamily: 'JetBrains Mono',
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// Type Button
// ═══════════════════════════════════════════════════════════════════════════

class _TypeButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isSelected;
  final Color color;
  final VoidCallback onTap;

  const _TypeButton({
    required this.label,
    required this.icon,
    required this.isSelected,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.md),
      child: Container(
        padding: EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: isSelected ? color.withOpacity(0.1) : AppColors.surfaceVariant,
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(
            color: isSelected ? color : AppColors.border,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: isSelected ? color : AppColors.textSecondary),
            SizedBox(width: AppSpacing.xs),
            Text(
              label,
              style: AppTypography.labelLarge.copyWith(
                color: isSelected ? color : AppColors.textSecondary,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
