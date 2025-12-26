import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../domain/entities/entities.dart';
import '../providers/inventory_providers.dart';
import '../widgets/warehouse_card.dart';
import '../widgets/stock_movement_card.dart';
import '../widgets/inventory_stats_card.dart';

/// شاشة المخزون الرئيسية
class InventoryScreen extends ConsumerStatefulWidget {
  const InventoryScreen({super.key});

  @override
  ConsumerState<InventoryScreen> createState() => _InventoryScreenState();
}

class _InventoryScreenState extends ConsumerState<InventoryScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('إدارة المخزون'),
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabs: const [
            Tab(text: 'نظرة عامة', icon: Icon(Icons.dashboard)),
            Tab(text: 'المستودعات', icon: Icon(Icons.warehouse)),
            Tab(text: 'الحركات', icon: Icon(Icons.swap_horiz)),
            Tab(text: 'الجرد', icon: Icon(Icons.inventory)),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildOverviewTab(),
          _buildWarehousesTab(),
          _buildMovementsTab(),
          _buildStockTakesTab(),
        ],
      ),
      floatingActionButton: _buildFAB(),
    );
  }

  Widget _buildOverviewTab() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(16.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const InventoryStatsCard(),
          SizedBox(height: 16.h),

          // المنتجات منخفضة المخزون
          _buildSectionHeader('المنتجات منخفضة المخزون', Icons.warning_amber),
          SizedBox(height: 8.h),
          Consumer(
            builder: (context, ref, child) {
              final lowStockAsync = ref.watch(lowStockProductsProvider);
              return lowStockAsync.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (error, stack) => Text('خطأ: $error'),
                data: (products) {
                  if (products.isEmpty) {
                    return Card(
                      child: Padding(
                        padding: EdgeInsets.all(16.w),
                        child: Row(
                          children: [
                            Icon(Icons.check_circle, color: Colors.green),
                            SizedBox(width: 8.w),
                            const Text('لا توجد منتجات منخفضة المخزون'),
                          ],
                        ),
                      ),
                    );
                  }
                  return Column(
                    children: products
                        .take(5)
                        .map((product) => Card(
                              margin: EdgeInsets.only(bottom: 8.h),
                              child: ListTile(
                                leading:
                                    Icon(Icons.warning, color: Colors.orange),
                                title: Text(product.productName),
                                subtitle: Text(product.warehouseName),
                                trailing: Text(
                                  '${product.quantity}',
                                  style: TextStyle(
                                    fontSize: 18.sp,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.orange,
                                  ),
                                ),
                              ),
                            ))
                        .toList(),
                  );
                },
              );
            },
          ),
          SizedBox(height: 16.h),

          // آخر الحركات
          _buildSectionHeader('آخر الحركات', Icons.history),
          SizedBox(height: 8.h),
          Consumer(
            builder: (context, ref, child) {
              final movementsAsync = ref.watch(stockMovementsProvider);
              return movementsAsync.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (error, stack) => Text('خطأ: $error'),
                data: (movements) {
                  if (movements.isEmpty) {
                    return Card(
                      child: Padding(
                        padding: EdgeInsets.all(16.w),
                        child: const Text('لا توجد حركات'),
                      ),
                    );
                  }
                  return Column(
                    children: movements
                        .take(5)
                        .map(
                            (movement) => StockMovementCard(movement: movement))
                        .toList(),
                  );
                },
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 20.sp),
        SizedBox(width: 8.w),
        Text(
          title,
          style: TextStyle(
            fontSize: 16.sp,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildWarehousesTab() {
    final warehousesAsync = ref.watch(warehousesProvider);

    return warehousesAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => Center(child: Text('خطأ: $error')),
      data: (warehouses) {
        if (warehouses.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.warehouse, size: 64.sp, color: Colors.grey),
                SizedBox(height: 16.h),
                Text(
                  'لا توجد مستودعات',
                  style: TextStyle(fontSize: 18.sp, color: Colors.grey),
                ),
                SizedBox(height: 16.h),
                ElevatedButton.icon(
                  onPressed: () => _showAddWarehouseDialog(),
                  icon: const Icon(Icons.add),
                  label: const Text('إضافة مستودع'),
                ),
              ],
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: () async => ref.invalidate(warehousesProvider),
          child: ListView.builder(
            padding: EdgeInsets.all(16.w),
            itemCount: warehouses.length,
            itemBuilder: (context, index) {
              final warehouse = warehouses[index];
              return WarehouseCard(
                warehouse: warehouse,
                onTap: () => _showWarehouseDetails(warehouse),
                onEdit: () => _showEditWarehouseDialog(warehouse),
                onDelete: () => _confirmDeleteWarehouse(warehouse),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildMovementsTab() {
    final movementsAsync = ref.watch(stockMovementsProvider);

    return movementsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => Center(child: Text('خطأ: $error')),
      data: (movements) {
        if (movements.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.swap_horiz, size: 64.sp, color: Colors.grey),
                SizedBox(height: 16.h),
                Text(
                  'لا توجد حركات',
                  style: TextStyle(fontSize: 18.sp, color: Colors.grey),
                ),
              ],
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: () async => ref.invalidate(stockMovementsProvider),
          child: ListView.builder(
            padding: EdgeInsets.all(16.w),
            itemCount: movements.length,
            itemBuilder: (context, index) {
              final movement = movements[index];
              return StockMovementCard(
                movement: movement,
                onTap: () => _showMovementDetails(movement),
                onApprove: movement.status == StockMovementStatus.pending
                    ? () => _approveMovement(movement)
                    : null,
                onCancel: movement.status == StockMovementStatus.pending
                    ? () => _cancelMovement(movement)
                    : null,
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildStockTakesTab() {
    final stockTakesAsync = ref.watch(stockTakesProvider);

    return stockTakesAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => Center(child: Text('خطأ: $error')),
      data: (stockTakes) {
        if (stockTakes.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.inventory, size: 64.sp, color: Colors.grey),
                SizedBox(height: 16.h),
                Text(
                  'لا توجد عمليات جرد',
                  style: TextStyle(fontSize: 18.sp, color: Colors.grey),
                ),
                SizedBox(height: 16.h),
                ElevatedButton.icon(
                  onPressed: () => _showAddStockTakeDialog(),
                  icon: const Icon(Icons.add),
                  label: const Text('إنشاء جرد'),
                ),
              ],
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: () async => ref.invalidate(stockTakesProvider),
          child: ListView.builder(
            padding: EdgeInsets.all(16.w),
            itemCount: stockTakes.length,
            itemBuilder: (context, index) {
              final stockTake = stockTakes[index];
              return _buildStockTakeCard(stockTake);
            },
          ),
        );
      },
    );
  }

  Widget _buildStockTakeCard(StockTakeEntity stockTake) {
    return Card(
      margin: EdgeInsets.only(bottom: 12.h),
      child: Padding(
        padding: EdgeInsets.all(16.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    stockTake.stockTakeNumber,
                    style: TextStyle(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Container(
                  padding:
                      EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
                  decoration: BoxDecoration(
                    color: stockTake.status.color.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(20.r),
                  ),
                  child: Text(
                    stockTake.status.arabicName,
                    style: TextStyle(
                      color: stockTake.status.color,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 8.h),
            Text(
              stockTake.warehouseName,
              style: TextStyle(color: Colors.grey[600]),
            ),
            SizedBox(height: 8.h),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('عدد الأصناف: ${stockTake.itemCount}'),
                Text(
                    'التاريخ: ${stockTake.stockTakeDate.toString().split(' ')[0]}'),
              ],
            ),
            if (stockTake.status == StockTakeStatus.completed) ...[
              SizedBox(height: 8.h),
              Row(
                children: [
                  _buildStatChip(
                      'متطابق', stockTake.matchedCount, Colors.green),
                  SizedBox(width: 8.w),
                  _buildStatChip('زيادة', stockTake.surplusCount, Colors.blue),
                  SizedBox(width: 8.w),
                  _buildStatChip('نقص', stockTake.shortageCount, Colors.red),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStatChip(String label, int count, Color color) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12.r),
      ),
      child: Text(
        '$label: $count',
        style: TextStyle(
          fontSize: 12.sp,
          color: color,
        ),
      ),
    );
  }

  Widget _buildFAB() {
    return FloatingActionButton.extended(
      onPressed: () {
        switch (_tabController.index) {
          case 1:
            _showAddWarehouseDialog();
            break;
          case 2:
            _showAddMovementDialog();
            break;
          case 3:
            _showAddStockTakeDialog();
            break;
          default:
            _showQuickActionsSheet();
        }
      },
      icon: const Icon(Icons.add),
      label: Text(_getFABLabel()),
    );
  }

  String _getFABLabel() {
    switch (_tabController.index) {
      case 1:
        return 'مستودع جديد';
      case 2:
        return 'حركة جديدة';
      case 3:
        return 'جرد جديد';
      default:
        return 'إجراء سريع';
    }
  }

  void _showQuickActionsSheet() {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.warehouse),
              title: const Text('إضافة مستودع'),
              onTap: () {
                Navigator.pop(context);
                _showAddWarehouseDialog();
              },
            ),
            ListTile(
              leading: const Icon(Icons.swap_horiz),
              title: const Text('حركة مخزون جديدة'),
              onTap: () {
                Navigator.pop(context);
                _showAddMovementDialog();
              },
            ),
            ListTile(
              leading: const Icon(Icons.inventory),
              title: const Text('إنشاء جرد'),
              onTap: () {
                Navigator.pop(context);
                _showAddStockTakeDialog();
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showAddWarehouseDialog() {
    final formKey = GlobalKey<FormState>();
    final nameController = TextEditingController();
    final codeController = TextEditingController();
    final addressController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('إضافة مستودع جديد'),
        content: Form(
          key: formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: nameController,
                  decoration:
                      const InputDecoration(labelText: 'اسم المستودع *'),
                  validator: (value) =>
                      value?.isEmpty ?? true ? 'الاسم مطلوب' : null,
                ),
                SizedBox(height: 16.h),
                TextFormField(
                  controller: codeController,
                  decoration: const InputDecoration(labelText: 'كود المستودع'),
                ),
                SizedBox(height: 16.h),
                TextFormField(
                  controller: addressController,
                  decoration: const InputDecoration(labelText: 'العنوان'),
                  maxLines: 2,
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (formKey.currentState!.validate()) {
                final notifier = ref.read(warehouseNotifierProvider.notifier);
                final warehouse = WarehouseEntity(
                  id: '',
                  name: nameController.text,
                  code:
                      codeController.text.isEmpty ? null : codeController.text,
                  address: addressController.text.isEmpty
                      ? null
                      : addressController.text,
                  createdAt: DateTime.now(),
                  updatedAt: DateTime.now(),
                );
                await notifier.createWarehouse(warehouse);
                if (mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('تم إضافة المستودع بنجاح')),
                  );
                }
              }
            },
            child: const Text('حفظ'),
          ),
        ],
      ),
    );
  }

  void _showEditWarehouseDialog(WarehouseEntity warehouse) {
    final formKey = GlobalKey<FormState>();
    final nameController = TextEditingController(text: warehouse.name);
    final codeController = TextEditingController(text: warehouse.code ?? '');
    final addressController =
        TextEditingController(text: warehouse.address ?? '');

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('تعديل المستودع'),
        content: Form(
          key: formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: nameController,
                  decoration:
                      const InputDecoration(labelText: 'اسم المستودع *'),
                  validator: (value) =>
                      value?.isEmpty ?? true ? 'الاسم مطلوب' : null,
                ),
                SizedBox(height: 16.h),
                TextFormField(
                  controller: codeController,
                  decoration: const InputDecoration(labelText: 'كود المستودع'),
                ),
                SizedBox(height: 16.h),
                TextFormField(
                  controller: addressController,
                  decoration: const InputDecoration(labelText: 'العنوان'),
                  maxLines: 2,
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (formKey.currentState!.validate()) {
                final notifier = ref.read(warehouseNotifierProvider.notifier);
                final updated = warehouse.copyWith(
                  name: nameController.text,
                  code:
                      codeController.text.isEmpty ? null : codeController.text,
                  address: addressController.text.isEmpty
                      ? null
                      : addressController.text,
                  updatedAt: DateTime.now(),
                );
                await notifier.updateWarehouse(updated);
                if (mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('تم تحديث المستودع بنجاح')),
                  );
                }
              }
            },
            child: const Text('حفظ'),
          ),
        ],
      ),
    );
  }

  void _confirmDeleteWarehouse(WarehouseEntity warehouse) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('حذف المستودع'),
        content: Text('هل أنت متأكد من حذف مستودع "${warehouse.name}"؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إلغاء'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              final notifier = ref.read(warehouseNotifierProvider.notifier);
              await notifier.deleteWarehouse(warehouse.id);
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('تم حذف المستودع بنجاح')),
                );
              }
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('حذف'),
          ),
        ],
      ),
    );
  }

  void _showWarehouseDetails(WarehouseEntity warehouse) {
    // TODO: Navigate to warehouse details screen
  }

  void _showAddMovementDialog() {
    // TODO: Show add movement dialog
  }

  void _showMovementDetails(StockMovementEntity movement) {
    // TODO: Navigate to movement details screen
  }

  void _approveMovement(StockMovementEntity movement) async {
    final notifier = ref.read(stockMovementNotifierProvider.notifier);
    await notifier.approveMovement(
      id: movement.id,
      approvedBy: 'current_user', // TODO: Get current user
    );
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تم اعتماد الحركة بنجاح')),
      );
    }
  }

  void _cancelMovement(StockMovementEntity movement) async {
    final notifier = ref.read(stockMovementNotifierProvider.notifier);
    await notifier.cancelMovement(movement.id);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تم إلغاء الحركة')),
      );
    }
  }

  void _showAddStockTakeDialog() {
    // TODO: Show add stock take dialog
  }
}
