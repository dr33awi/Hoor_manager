import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/redesign/design_system.dart';
import '../../../../core/di/injection.dart';
import '../../../../core/services/currency_service.dart';
import '../../../../data/database/app_database.dart';
import '../../../../data/repositories/inventory_repository.dart';
import '../../../../data/repositories/product_repository.dart';

/// ═══════════════════════════════════════════════════════════════════════════
/// Inventory Screen - Modern Redesign
/// Professional Inventory Management with Tabs
/// ═══════════════════════════════════════════════════════════════════════════

class InventoryScreenRedesign extends ConsumerStatefulWidget {
  const InventoryScreenRedesign({super.key});

  @override
  ConsumerState<InventoryScreenRedesign> createState() =>
      _InventoryScreenRedesignState();
}

class _InventoryScreenRedesignState
    extends ConsumerState<InventoryScreenRedesign>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  final _inventoryRepo = getIt<InventoryRepository>();
  final _productRepo = getIt<ProductRepository>();
  final _currencyService = getIt<CurrencyService>();

  final _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
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
      backgroundColor: HoorColors.background,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(context),
            _buildSearchBar(),
            _buildTabBar(),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildMovementsTab(),
                  _buildAlertsTab(),
                  _buildCountTab(),
                ],
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddMovementSheet,
        backgroundColor: HoorColors.primary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_rounded),
        label: const Text('حركة جديدة'),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(HoorSpacing.lg.w),
      child: Row(
        children: [
          _IconButton(
            icon: Icons.arrow_forward_ios_rounded,
            onTap: () => context.pop(),
          ),
          SizedBox(width: HoorSpacing.md.w),
          Expanded(
            child: Text(
              'المخزون',
              style: HoorTypography.headlineSmall.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          _IconButton(
            icon: Icons.file_download_rounded,
            onTap: _exportInventory,
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: HoorSpacing.lg.w),
      child: HoorSearchBar(
        controller: _searchController,
        hint: 'بحث في المخزون...',
        onChanged: (value) => setState(() => _searchQuery = value),
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      margin: EdgeInsets.symmetric(
        horizontal: HoorSpacing.lg.w,
        vertical: HoorSpacing.md.h,
      ),
      decoration: BoxDecoration(
        color: HoorColors.surface,
        borderRadius: BorderRadius.circular(HoorRadius.lg),
        border: Border.all(color: HoorColors.border.withValues(alpha: 0.5)),
      ),
      child: TabBar(
        controller: _tabController,
        indicatorSize: TabBarIndicatorSize.tab,
        dividerColor: Colors.transparent,
        indicator: BoxDecoration(
          borderRadius: BorderRadius.circular(HoorRadius.md),
          color: HoorColors.primary,
        ),
        labelColor: Colors.white,
        unselectedLabelColor: HoorColors.textSecondary,
        labelStyle: HoorTypography.labelLarge.copyWith(
          fontWeight: FontWeight.bold,
        ),
        unselectedLabelStyle: HoorTypography.labelLarge,
        tabs: const [
          Tab(text: 'الحركات'),
          Tab(text: 'التنبيهات'),
          Tab(text: 'الجرد'),
        ],
      ),
    );
  }

  Widget _buildMovementsTab() {
    return StreamBuilder<List<InventoryMovement>>(
      stream: _inventoryRepo.watchAllMovements(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: HoorLoading());
        }

        var movements = snapshot.data ?? [];

        if (_searchQuery.isNotEmpty) {
          movements = movements
              .where((m) =>
                  m.reason
                      ?.toLowerCase()
                      .contains(_searchQuery.toLowerCase()) ==
                  true)
              .toList();
        }

        if (movements.isEmpty) {
          return HoorEmptyState(
            icon: Icons.swap_vert_rounded,
            title: 'لا توجد حركات',
            message: 'سجل حركات المخزون ستظهر هنا',
          );
        }

        // Group by date
        final grouped = _groupMovementsByDate(movements);

        return ListView.builder(
          padding: EdgeInsets.symmetric(horizontal: HoorSpacing.lg.w),
          itemCount: grouped.length,
          itemBuilder: (context, index) {
            final entry = grouped.entries.elementAt(index);
            return _buildDateGroup(entry.key, entry.value);
          },
        );
      },
    );
  }

  Map<String, List<InventoryMovement>> _groupMovementsByDate(
      List<InventoryMovement> movements) {
    final grouped = <String, List<InventoryMovement>>{};
    for (final movement in movements) {
      final dateKey = DateFormat('yyyy-MM-dd').format(movement.createdAt);
      grouped.putIfAbsent(dateKey, () => []).add(movement);
    }
    return grouped;
  }

  Widget _buildDateGroup(String dateKey, List<InventoryMovement> movements) {
    final date = DateTime.parse(dateKey);
    final isToday = DateFormat('yyyy-MM-dd').format(DateTime.now()) == dateKey;
    final displayDate =
        isToday ? 'اليوم' : DateFormat('EEEE, d MMMM', 'ar').format(date);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(height: HoorSpacing.md.h),
        Text(
          displayDate,
          style: HoorTypography.labelLarge.copyWith(
            color: HoorColors.textSecondary,
            fontWeight: FontWeight.w600,
          ),
        ),
        SizedBox(height: HoorSpacing.sm.h),
        ...movements.map((movement) => _MovementCard(
              movement: movement,
              currencyService: _currencyService,
            )),
      ],
    );
  }

  Widget _buildAlertsTab() {
    return StreamBuilder<List<Product>>(
      stream: _productRepo.watchLowStockProducts(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: HoorLoading());
        }

        final products = snapshot.data ?? [];

        if (products.isEmpty) {
          return _buildNoAlertsState();
        }

        return ListView(
          padding: EdgeInsets.symmetric(horizontal: HoorSpacing.lg.w),
          children: [
            SizedBox(height: HoorSpacing.md.h),
            // Summary Card
            _buildAlertsSummary(products),
            SizedBox(height: HoorSpacing.lg.h),

            // Alert List
            HoorDecoratedHeader(
              title: 'منتجات تحتاج إعادة طلب',
              icon: Icons.warning_rounded,
            ),
            SizedBox(height: HoorSpacing.md.h),
            ...products.map((product) => _AlertCard(
                  product: product,
                  currencyService: _currencyService,
                  onTap: () => _showRestockSheet(product),
                )),
          ],
        );
      },
    );
  }

  Widget _buildNoAlertsState() {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(HoorSpacing.xl.w),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: EdgeInsets.all(HoorSpacing.xl.w),
              decoration: BoxDecoration(
                color: HoorColors.success.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.check_circle_rounded,
                color: HoorColors.success,
                size: 64.sp,
              ),
            ),
            SizedBox(height: HoorSpacing.xl.h),
            Text(
              'المخزون جيد! 👍',
              style: HoorTypography.headlineSmall.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: HoorSpacing.sm.h),
            Text(
              'جميع المنتجات لديها كميات كافية',
              style: HoorTypography.bodyMedium.copyWith(
                color: HoorColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAlertsSummary(List<Product> products) {
    final outOfStock = products.where((p) => p.quantity <= 0).length;
    final lowStock = products.where((p) => p.quantity > 0).length;

    return Container(
      padding: EdgeInsets.all(HoorSpacing.lg.w),
      decoration: BoxDecoration(
        color: HoorColors.warning.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(HoorRadius.lg),
        border: Border.all(color: HoorColors.warning.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(
            Icons.warning_rounded,
            color: HoorColors.warning,
            size: HoorIconSize.xl,
          ),
          SizedBox(width: HoorSpacing.md.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${products.length} منتج يحتاج انتباه',
                  style: HoorTypography.titleMedium.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: HoorSpacing.xxs.h),
                Text(
                  '$outOfStock نفذ • $lowStock منخفض',
                  style: HoorTypography.bodySmall.copyWith(
                    color: HoorColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCountTab() {
    return StreamBuilder<List<Product>>(
      stream: _productRepo.watchAllProducts(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: HoorLoading());
        }

        var products = snapshot.data ?? [];

        if (_searchQuery.isNotEmpty) {
          products = products
              .where((p) =>
                  p.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
                  (p.barcode?.contains(_searchQuery) ?? false))
              .toList();
        }

        if (products.isEmpty) {
          return HoorEmptyState(
            icon: Icons.inventory_2_outlined,
            title: 'لا توجد منتجات',
            message: 'أضف منتجات للبدء في إدارة المخزون',
          );
        }

        // Calculate totals
        final totalItems = products.fold<int>(0, (sum, p) => sum + p.quantity);
        final totalValue = products.fold<double>(
            0, (sum, p) => sum + (p.quantity * p.purchasePrice));

        return ListView(
          padding: EdgeInsets.symmetric(horizontal: HoorSpacing.lg.w),
          children: [
            SizedBox(height: HoorSpacing.md.h),
            // Summary Cards
            Row(
              children: [
                Expanded(
                  child: _StatCard(
                    icon: Icons.inventory_rounded,
                    label: 'إجمالي القطع',
                    value: totalItems.toString(),
                    color: HoorColors.primary,
                  ),
                ),
                SizedBox(width: HoorSpacing.md.w),
                Expanded(
                  child: _StatCard(
                    icon: Icons.account_balance_wallet_rounded,
                    label: 'قيمة المخزون',
                    value: _currencyService.formatSyp(totalValue),
                    color: HoorColors.income,
                  ),
                ),
              ],
            ),
            SizedBox(height: HoorSpacing.lg.h),

            // Product List
            HoorDecoratedHeader(
              title: 'قائمة المنتجات',
              icon: Icons.list_rounded,
            ),
            SizedBox(height: HoorSpacing.md.h),
            ...products.map((product) => _CountCard(
                  product: product,
                  currencyService: _currencyService,
                  onTap: () => _showAdjustQuantitySheet(product),
                )),
          ],
        );
      },
    );
  }

  void _showAddMovementSheet() {
    final quantityController = TextEditingController();
    final noteController = TextEditingController();
    String movementType = 'in';
    Product? selectedProduct;

    HoorBottomSheet.show(
      context,
      title: 'حركة مخزون جديدة',
      showCloseButton: true,
      child: StatefulBuilder(
        builder: (context, setSheetState) {
          return StreamBuilder<List<Product>>(
            stream: _productRepo.watchAllProducts(),
            builder: (context, snapshot) {
              final products = snapshot.data ?? [];

              return Padding(
                padding: EdgeInsets.all(HoorSpacing.lg.w),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Movement Type
                    Text(
                      'نوع الحركة',
                      style: HoorTypography.labelLarge.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    SizedBox(height: HoorSpacing.sm.h),
                    Row(
                      children: [
                        Expanded(
                          child: _TypeToggleButton(
                            label: 'وارد',
                            icon: Icons.arrow_downward_rounded,
                            isSelected: movementType == 'in',
                            color: HoorColors.income,
                            onTap: () =>
                                setSheetState(() => movementType = 'in'),
                          ),
                        ),
                        SizedBox(width: HoorSpacing.md.w),
                        Expanded(
                          child: _TypeToggleButton(
                            label: 'صادر',
                            icon: Icons.arrow_upward_rounded,
                            isSelected: movementType == 'out',
                            color: HoorColors.expense,
                            onTap: () =>
                                setSheetState(() => movementType = 'out'),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: HoorSpacing.lg.h),

                    // Product Selection
                    Text(
                      'المنتج',
                      style: HoorTypography.labelLarge.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    SizedBox(height: HoorSpacing.sm.h),
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: HoorSpacing.md.w,
                        vertical: HoorSpacing.xs.h,
                      ),
                      decoration: BoxDecoration(
                        color: HoorColors.surface,
                        borderRadius: BorderRadius.circular(HoorRadius.md),
                        border: Border.all(color: HoorColors.border),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<Product>(
                          isExpanded: true,
                          hint: const Text('اختر منتج'),
                          value: selectedProduct,
                          items: products.map((product) {
                            return DropdownMenuItem(
                              value: product,
                              child: Text(product.name),
                            );
                          }).toList(),
                          onChanged: (product) {
                            setSheetState(() => selectedProduct = product);
                          },
                        ),
                      ),
                    ),
                    SizedBox(height: HoorSpacing.lg.h),

                    // Quantity
                    HoorTextField(
                      controller: quantityController,
                      label: 'الكمية',
                      hint: 'أدخل الكمية',
                      prefixIcon: Icons.numbers_rounded,
                      keyboardType: TextInputType.number,
                    ),
                    SizedBox(height: HoorSpacing.md.h),

                    // Note
                    HoorTextField(
                      controller: noteController,
                      label: 'ملاحظة (اختياري)',
                      hint: 'أدخل ملاحظة',
                      prefixIcon: Icons.note_rounded,
                    ),
                    SizedBox(height: HoorSpacing.xl.h),

                    // Save Button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () => _saveMovement(
                          selectedProduct,
                          movementType,
                          quantityController.text,
                          noteController.text,
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: movementType == 'in'
                              ? HoorColors.income
                              : HoorColors.expense,
                          foregroundColor: Colors.white,
                          padding: EdgeInsets.all(HoorSpacing.md.w),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(HoorRadius.md),
                          ),
                        ),
                        child: const Text('حفظ الحركة'),
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }

  Future<void> _saveMovement(
    Product? product,
    String type,
    String quantityText,
    String note,
  ) async {
    if (product == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('يرجى اختيار منتج'),
          backgroundColor: HoorColors.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    final quantity = int.tryParse(quantityText);
    if (quantity == null || quantity <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('يرجى إدخال كمية صحيحة'),
          backgroundColor: HoorColors.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    try {
      if (type == 'in') {
        await _inventoryRepo.addStock(
          productId: product.id,
          quantity: quantity,
          reason: note.isNotEmpty ? note : null,
        );
      } else {
        await _inventoryRepo.withdrawStock(
          productId: product.id,
          quantity: quantity,
          reason: note.isNotEmpty ? note : null,
        );
      }
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('تم حفظ الحركة بنجاح'),
            backgroundColor: HoorColors.success,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(HoorRadius.md),
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('خطأ: $e'),
            backgroundColor: HoorColors.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  void _showRestockSheet(Product product) {
    final quantityController = TextEditingController();

    HoorBottomSheet.show(
      context,
      title: 'إعادة تعبئة المخزون',
      showCloseButton: true,
      child: Padding(
        padding: EdgeInsets.all(HoorSpacing.lg.w),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: EdgeInsets.all(HoorSpacing.lg.w),
              decoration: BoxDecoration(
                color: HoorColors.income.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(HoorRadius.lg),
              ),
              child: Column(
                children: [
                  Icon(
                    Icons.add_circle_rounded,
                    color: HoorColors.income,
                    size: HoorIconSize.xxl,
                  ),
                  SizedBox(height: HoorSpacing.md.h),
                  Text(
                    product.name,
                    style: HoorTypography.titleLarge.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: HoorSpacing.xs.h),
                  Text(
                    'الكمية الحالية: ${product.quantity}',
                    style: HoorTypography.bodyMedium.copyWith(
                      color: HoorColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: HoorSpacing.lg.h),
            HoorTextField(
              controller: quantityController,
              label: 'الكمية المضافة',
              hint: 'أدخل الكمية',
              prefixIcon: Icons.add_rounded,
              keyboardType: TextInputType.number,
              autofocus: true,
            ),
            SizedBox(height: HoorSpacing.xl.h),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => _restock(product, quantityController.text),
                style: ElevatedButton.styleFrom(
                  backgroundColor: HoorColors.income,
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.all(HoorSpacing.md.w),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(HoorRadius.md),
                  ),
                ),
                child: const Text('تأكيد الإضافة'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _restock(Product product, String quantityText) async {
    final quantity = int.tryParse(quantityText);
    if (quantity == null || quantity <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('يرجى إدخال كمية صحيحة'),
          backgroundColor: HoorColors.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    try {
      await _inventoryRepo.addStock(
        productId: product.id,
        quantity: quantity,
        reason: 'إعادة تعبئة المخزون',
      );
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('تم إضافة الكمية بنجاح'),
            backgroundColor: HoorColors.success,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(HoorRadius.md),
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('خطأ: $e'),
            backgroundColor: HoorColors.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  void _showAdjustQuantitySheet(Product product) {
    final quantityController =
        TextEditingController(text: product.quantity.toString());

    HoorBottomSheet.show(
      context,
      title: 'تعديل الكمية',
      showCloseButton: true,
      child: Padding(
        padding: EdgeInsets.all(HoorSpacing.lg.w),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              product.name,
              style: HoorTypography.titleLarge.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: HoorSpacing.lg.h),
            HoorTextField(
              controller: quantityController,
              label: 'الكمية الجديدة',
              hint: 'أدخل الكمية',
              prefixIcon: Icons.inventory_2_rounded,
              keyboardType: TextInputType.number,
              autofocus: true,
            ),
            SizedBox(height: HoorSpacing.xl.h),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () =>
                    _adjustQuantity(product, quantityController.text),
                style: ElevatedButton.styleFrom(
                  backgroundColor: HoorColors.primary,
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.all(HoorSpacing.md.w),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(HoorRadius.md),
                  ),
                ),
                child: const Text('حفظ التغييرات'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _adjustQuantity(Product product, String quantityText) async {
    final newQuantity = int.tryParse(quantityText);
    if (newQuantity == null || newQuantity < 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('يرجى إدخال كمية صحيحة'),
          backgroundColor: HoorColors.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    try {
      final diff = newQuantity - product.quantity;
      if (diff != 0) {
        await _inventoryRepo.adjustStock(
          productId: product.id,
          actualQuantity: newQuantity,
          reason: 'تعديل الجرد',
        );
      }
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('تم تحديث الكمية'),
            backgroundColor: HoorColors.success,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(HoorRadius.md),
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('خطأ: $e'),
            backgroundColor: HoorColors.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  void _exportInventory() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('جاري تصدير تقرير المخزون...'),
        backgroundColor: HoorColors.info,
        behavior: SnackBarBehavior.floating,
      ),
    );
    // TODO: Implement export
  }
}

/// ═══════════════════════════════════════════════════════════════════════════
/// Supporting Widgets
/// ═══════════════════════════════════════════════════════════════════════════

class _IconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _IconButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: HoorColors.surface,
      borderRadius: BorderRadius.circular(HoorRadius.md),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(HoorRadius.md),
        child: Container(
          padding: EdgeInsets.all(HoorSpacing.sm.w),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(HoorRadius.md),
            border: Border.all(color: HoorColors.border),
          ),
          child: Icon(icon,
              size: HoorIconSize.md, color: HoorColors.textSecondary),
        ),
      ),
    );
  }
}

class _TypeToggleButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isSelected;
  final Color color;
  final VoidCallback onTap;

  const _TypeToggleButton({
    required this.label,
    required this.icon,
    required this.isSelected,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: isSelected ? color.withValues(alpha: 0.15) : HoorColors.surface,
      borderRadius: BorderRadius.circular(HoorRadius.md),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(HoorRadius.md),
        child: Container(
          padding: EdgeInsets.all(HoorSpacing.md.w),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(HoorRadius.md),
            border: Border.all(
              color: isSelected ? color : HoorColors.border,
              width: isSelected ? 2 : 1,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                color: isSelected ? color : HoorColors.textSecondary,
                size: HoorIconSize.md,
              ),
              SizedBox(width: HoorSpacing.xs.w),
              Text(
                label,
                style: HoorTypography.labelLarge.copyWith(
                  color: isSelected ? color : HoorColors.textSecondary,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _StatCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(HoorSpacing.lg.w),
      decoration: BoxDecoration(
        color: HoorColors.surface,
        borderRadius: BorderRadius.circular(HoorRadius.lg),
        border: Border.all(color: HoorColors.border.withValues(alpha: 0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: EdgeInsets.all(HoorSpacing.sm.w),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(HoorRadius.sm),
            ),
            child: Icon(icon, color: color, size: HoorIconSize.md),
          ),
          SizedBox(height: HoorSpacing.md.h),
          Text(
            label,
            style: HoorTypography.labelSmall.copyWith(
              color: HoorColors.textSecondary,
            ),
          ),
          SizedBox(height: HoorSpacing.xxs.h),
          Text(
            value,
            style: HoorTypography.titleMedium.copyWith(
              fontWeight: FontWeight.bold,
              color: color,
              fontFamily: 'IBM Plex Sans Arabic',
            ),
          ),
        ],
      ),
    );
  }
}

class _MovementCard extends StatelessWidget {
  final InventoryMovement movement;
  final CurrencyService currencyService;

  const _MovementCard({
    required this.movement,
    required this.currencyService,
  });

  @override
  Widget build(BuildContext context) {
    final isIn = movement.type == 'in';

    return Padding(
      padding: EdgeInsets.only(bottom: HoorSpacing.sm.h),
      child: Container(
        padding: EdgeInsets.all(HoorSpacing.md.w),
        decoration: BoxDecoration(
          color: HoorColors.surface,
          borderRadius: BorderRadius.circular(HoorRadius.lg),
          border: Border.all(color: HoorColors.border.withValues(alpha: 0.5)),
        ),
        child: Row(
          children: [
            Container(
              padding: EdgeInsets.all(HoorSpacing.md.w),
              decoration: BoxDecoration(
                color: isIn
                    ? HoorColors.income.withValues(alpha: 0.1)
                    : HoorColors.expense.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(HoorRadius.md),
              ),
              child: Icon(
                isIn
                    ? Icons.arrow_downward_rounded
                    : Icons.arrow_upward_rounded,
                color: isIn ? HoorColors.income : HoorColors.expense,
                size: HoorIconSize.lg,
              ),
            ),
            SizedBox(width: HoorSpacing.md.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'منتج #${movement.productId}',
                    style: HoorTypography.titleSmall.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (movement.reason?.isNotEmpty == true) ...[
                    SizedBox(height: HoorSpacing.xxs.h),
                    Text(
                      movement.reason!,
                      style: HoorTypography.bodySmall.copyWith(
                        color: HoorColors.textSecondary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                  SizedBox(height: HoorSpacing.xxs.h),
                  Text(
                    DateFormat('HH:mm').format(movement.createdAt),
                    style: HoorTypography.labelSmall.copyWith(
                      color: HoorColors.textTertiary,
                    ),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '${isIn ? '+' : '-'}${movement.quantity}',
                  style: HoorTypography.titleMedium.copyWith(
                    fontWeight: FontWeight.bold,
                    color: isIn ? HoorColors.income : HoorColors.expense,
                  ),
                ),
                Text(
                  isIn ? 'وارد' : 'صادر',
                  style: HoorTypography.labelSmall.copyWith(
                    color: HoorColors.textTertiary,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _AlertCard extends StatelessWidget {
  final Product product;
  final CurrencyService currencyService;
  final VoidCallback onTap;

  const _AlertCard({
    required this.product,
    required this.currencyService,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isOutOfStock = product.quantity <= 0;

    return Padding(
      padding: EdgeInsets.only(bottom: HoorSpacing.sm.h),
      child: Material(
        color: HoorColors.surface,
        borderRadius: BorderRadius.circular(HoorRadius.lg),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(HoorRadius.lg),
          child: Container(
            padding: EdgeInsets.all(HoorSpacing.md.w),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(HoorRadius.lg),
              border: Border.all(
                color: isOutOfStock
                    ? HoorColors.error.withValues(alpha: 0.5)
                    : HoorColors.warning.withValues(alpha: 0.5),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: EdgeInsets.all(HoorSpacing.md.w),
                  decoration: BoxDecoration(
                    color: isOutOfStock
                        ? HoorColors.error.withValues(alpha: 0.1)
                        : HoorColors.warning.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(HoorRadius.md),
                  ),
                  child: Icon(
                    isOutOfStock ? Icons.error_rounded : Icons.warning_rounded,
                    color: isOutOfStock ? HoorColors.error : HoorColors.warning,
                    size: HoorIconSize.lg,
                  ),
                ),
                SizedBox(width: HoorSpacing.md.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        product.name,
                        style: HoorTypography.titleSmall.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      SizedBox(height: HoorSpacing.xxs.h),
                      Row(
                        children: [
                          HoorBadge(
                            label: isOutOfStock ? 'نفذ' : 'منخفض',
                            color: isOutOfStock
                                ? HoorColors.error
                                : HoorColors.warning,
                            size: HoorBadgeSize.small,
                          ),
                          SizedBox(width: HoorSpacing.sm.w),
                          Text(
                            'الكمية: ${product.quantity}',
                            style: HoorTypography.labelSmall.copyWith(
                              color: HoorColors.textTertiary,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                ElevatedButton(
                  onPressed: onTap,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: HoorColors.income,
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(
                      horizontal: HoorSpacing.md.w,
                      vertical: HoorSpacing.sm.h,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(HoorRadius.md),
                    ),
                  ),
                  child: const Text('تعبئة'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _CountCard extends StatelessWidget {
  final Product product;
  final CurrencyService currencyService;
  final VoidCallback onTap;

  const _CountCard({
    required this.product,
    required this.currencyService,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final stockValue = product.quantity * product.purchasePrice;
    final stockStatus = _getStockStatus(product);

    return Padding(
      padding: EdgeInsets.only(bottom: HoorSpacing.sm.h),
      child: Material(
        color: HoorColors.surface,
        borderRadius: BorderRadius.circular(HoorRadius.lg),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(HoorRadius.lg),
          child: Container(
            padding: EdgeInsets.all(HoorSpacing.md.w),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(HoorRadius.lg),
              border:
                  Border.all(color: HoorColors.border.withValues(alpha: 0.5)),
            ),
            child: Row(
              children: [
                Container(
                  width: 48.w,
                  height: 48.w,
                  decoration: BoxDecoration(
                    color: HoorColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(HoorRadius.md),
                  ),
                  child: Icon(
                    Icons.inventory_2_rounded,
                    color: HoorColors.primary,
                    size: HoorIconSize.lg,
                  ),
                ),
                SizedBox(width: HoorSpacing.md.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        product.name,
                        style: HoorTypography.titleSmall.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      SizedBox(height: HoorSpacing.xxs.h),
                      Row(
                        children: [
                          Container(
                            width: 8.w,
                            height: 8.w,
                            decoration: BoxDecoration(
                              color: stockStatus.color,
                              shape: BoxShape.circle,
                            ),
                          ),
                          SizedBox(width: HoorSpacing.xxs.w),
                          Text(
                            stockStatus.label,
                            style: HoorTypography.labelSmall.copyWith(
                              color: HoorColors.textTertiary,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '${product.quantity}',
                      style: HoorTypography.titleMedium.copyWith(
                        fontWeight: FontWeight.bold,
                        color: stockStatus.color,
                      ),
                    ),
                    Text(
                      currencyService.formatSyp(stockValue),
                      style: HoorTypography.labelSmall.copyWith(
                        color: HoorColors.textTertiary,
                        fontFamily: 'IBM Plex Sans Arabic',
                      ),
                    ),
                  ],
                ),
                SizedBox(width: HoorSpacing.xs.w),
                Icon(
                  Icons.chevron_left_rounded,
                  color: HoorColors.textTertiary,
                  size: HoorIconSize.md,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  ({String label, Color color}) _getStockStatus(Product product) {
    if (product.quantity <= 0) {
      return (label: 'نفذ', color: HoorColors.error);
    } else if (product.quantity <= 5) {
      return (label: 'منخفض', color: HoorColors.warning);
    } else {
      return (label: 'متوفر', color: HoorColors.success);
    }
  }
}
