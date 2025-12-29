import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gap/gap.dart';
import 'package:intl/intl.dart';
import 'package:printing/printing.dart';
import 'package:pdf/pdf.dart';

import '../../../core/di/injection.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/invoice_widgets.dart';
import '../../../core/services/export_service.dart';
import '../../../data/database/app_database.dart';
import '../../../data/repositories/inventory_repository.dart';
import '../../../data/repositories/product_repository.dart';

class InventoryScreen extends ConsumerStatefulWidget {
  const InventoryScreen({super.key});

  @override
  ConsumerState<InventoryScreen> createState() => _InventoryScreenState();
}

class _InventoryScreenState extends ConsumerState<InventoryScreen>
    with SingleTickerProviderStateMixin {
  final _inventoryRepo = getIt<InventoryRepository>();
  final _productRepo = getIt<ProductRepository>();
  final _exportService = getIt<ExportService>();
  final _db = getIt<AppDatabase>();

  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
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
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert),
            onSelected: _handleExport,
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'excel',
                child: Row(
                  children: [
                    Icon(Icons.table_chart, color: Colors.green),
                    SizedBox(width: 8),
                    Text('تصدير Excel'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'pdf',
                child: Row(
                  children: [
                    Icon(Icons.picture_as_pdf, color: Colors.red),
                    SizedBox(width: 8),
                    Text('تصدير PDF'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'share',
                child: Row(
                  children: [
                    Icon(Icons.share, color: Colors.blue),
                    SizedBox(width: 8),
                    Text('مشاركة'),
                  ],
                ),
              ),
            ],
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'الحركات', icon: Icon(Icons.swap_horiz)),
            Tab(text: 'تنبيهات', icon: Icon(Icons.warning)),
            Tab(text: 'جرد', icon: Icon(Icons.inventory)),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _MovementsTab(inventoryRepo: _inventoryRepo),
          _AlertsTab(productRepo: _productRepo),
          _InventoryCountTab(
            productRepo: _productRepo,
            inventoryRepo: _inventoryRepo,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddMovementDialog,
        child: const Icon(Icons.add),
      ),
    );
  }

  Future<void> _handleExport(String type) async {
    final products = await _productRepo.getAllProducts();
    final soldQuantities = await _db.getProductSoldQuantities();

    if (products.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('لا توجد منتجات للتصدير')),
        );
      }
      return;
    }

    try {
      switch (type) {
        case 'excel':
          final filePath = await _exportService.exportInventoryReportToExcel(
            products: products,
          );
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: const Text('تم تصدير تقرير المخزون بنجاح'),
                backgroundColor: Colors.green,
                action: SnackBarAction(
                  label: 'مشاركة',
                  textColor: Colors.white,
                  onPressed: () => _exportService.shareExcelFile(filePath),
                ),
              ),
            );
          }
          break;

        case 'pdf':
          final pdfBytes = await _exportService.generateInventoryReportPdf(
            products: products,
            soldQuantities: soldQuantities,
          );
          await Printing.layoutPdf(
            onLayout: (PdfPageFormat format) async => pdfBytes,
            name: 'inventory_report.pdf',
          );
          break;

        case 'share':
          final filePath = await _exportService.exportInventoryReportToExcel(
            products: products,
          );
          await _exportService.shareExcelFile(filePath);
          break;
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('خطأ في التصدير: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showAddMovementDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => _AddMovementSheet(
        productRepo: _productRepo,
        inventoryRepo: _inventoryRepo,
        onAdded: () => setState(() {}),
      ),
    );
  }
}

class _MovementsTab extends StatelessWidget {
  final InventoryRepository inventoryRepo;

  const _MovementsTab({required this.inventoryRepo});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Filter Chips
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: EdgeInsets.all(12.w),
          child: Row(
            children: [
              _FilterChip(label: 'الكل', type: 'all', selected: true),
              Gap(8.w),
              _FilterChip(label: 'إضافة', type: 'add', selected: false),
              Gap(8.w),
              _FilterChip(label: 'سحب', type: 'remove', selected: false),
              Gap(8.w),
              _FilterChip(label: 'جرد', type: 'adjustment', selected: false),
              Gap(8.w),
              _FilterChip(label: 'تالف', type: 'damage', selected: false),
            ],
          ),
        ),

        Expanded(
          child: StreamBuilder<List<InventoryMovement>>(
            stream: inventoryRepo.watchAllMovements(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              final movements = snapshot.data ?? [];

              if (movements.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.swap_horiz, size: 64.sp, color: Colors.grey),
                      Gap(16.h),
                      Text(
                        'لا توجد حركات مخزون',
                        style: TextStyle(fontSize: 16.sp, color: Colors.grey),
                      ),
                    ],
                  ),
                );
              }

              return ListView.builder(
                padding: EdgeInsets.symmetric(horizontal: 16.w),
                itemCount: movements.length,
                itemBuilder: (context, index) {
                  return _MovementCard(movement: movements[index]);
                },
              );
            },
          ),
        ),
      ],
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final String type;
  final bool selected;

  const _FilterChip({
    required this.label,
    required this.type,
    required this.selected,
  });

  @override
  Widget build(BuildContext context) {
    return FilterChip(
      label: Text(label),
      selected: selected,
      onSelected: (value) {},
    );
  }
}

class _MovementCard extends StatelessWidget {
  final InventoryMovement movement;

  const _MovementCard({required this.movement});

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('dd/MM/yyyy HH:mm');

    IconData icon;
    Color color;
    String typeLabel;

    switch (movement.type) {
      case 'add':
        icon = Icons.add_box;
        color = AppColors.success;
        typeLabel = 'إضافة';
        break;
      case 'remove':
        icon = Icons.indeterminate_check_box;
        color = AppColors.error;
        typeLabel = 'سحب';
        break;
      case 'adjustment':
        icon = Icons.tune;
        color = AppColors.warning;
        typeLabel = 'تعديل جرد';
        break;
      case 'damage':
        icon = Icons.broken_image;
        color = AppColors.error;
        typeLabel = 'تالف';
        break;
      case 'transfer':
        icon = Icons.swap_horiz;
        color = AppColors.accent;
        typeLabel = 'تحويل';
        break;
      case 'sale':
        icon = Icons.point_of_sale;
        color = AppColors.sales;
        typeLabel = 'بيع';
        break;
      case 'purchase':
        icon = Icons.shopping_cart;
        color = AppColors.purchases;
        typeLabel = 'شراء';
        break;
      case 'return':
        icon = Icons.assignment_return;
        color = AppColors.returns;
        typeLabel = 'مرتجع';
        break;
      default:
        icon = Icons.swap_horiz;
        color = AppColors.textSecondary;
        typeLabel = movement.type;
    }

    final isPositive = movement.quantity > 0;

    return Card(
      margin: EdgeInsets.only(bottom: 8.h),
      child: ListTile(
        leading: Container(
          padding: EdgeInsets.all(8.w),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8.r),
          ),
          child: Icon(icon, color: color),
        ),
        title: Text(movement.productId), // TODO: Show product name
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              typeLabel,
              style: TextStyle(color: color, fontWeight: FontWeight.w500),
            ),
            Text(
              dateFormat.format(movement.createdAt),
              style: TextStyle(fontSize: 12.sp, color: AppColors.textSecondary),
            ),
          ],
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              '${isPositive ? '+' : ''}${movement.quantity}',
              style: TextStyle(
                fontSize: 18.sp,
                fontWeight: FontWeight.bold,
                color: isPositive ? AppColors.success : AppColors.error,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AlertsTab extends StatelessWidget {
  final ProductRepository productRepo;

  const _AlertsTab({required this.productRepo});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<Product>>(
      stream: productRepo.watchLowStockProducts(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final products = snapshot.data ?? [];

        if (products.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.check_circle,
                  size: 64.sp,
                  color: AppColors.success,
                ),
                Gap(16.h),
                Text(
                  'جميع المنتجات متوفرة',
                  style: TextStyle(
                    fontSize: 18.sp,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'لا توجد تنبيهات نقص مخزون',
                  style: TextStyle(
                    fontSize: 14.sp,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: EdgeInsets.all(16.w),
          itemCount: products.length,
          itemBuilder: (context, index) {
            final product = products[index];
            return _LowStockCard(product: product);
          },
        );
      },
    );
  }
}

class _LowStockCard extends StatelessWidget {
  final Product product;

  const _LowStockCard({required this.product});

  @override
  Widget build(BuildContext context) {
    final percentage = (product.quantity / product.minQuantity) * 100;

    return Card(
      margin: EdgeInsets.only(bottom: 8.h),
      child: Padding(
        padding: EdgeInsets.all(12.w),
        child: Row(
          children: [
            Container(
              padding: EdgeInsets.all(10.w),
              decoration: BoxDecoration(
                color: AppColors.error.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8.r),
              ),
              child: Icon(
                Icons.warning,
                color: AppColors.error,
                size: 24.sp,
              ),
            ),
            Gap(12.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.name,
                    style: TextStyle(
                      fontSize: 14.sp,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Gap(4.h),
                  LinearProgressIndicator(
                    value: percentage / 100,
                    backgroundColor: AppColors.error.withOpacity(0.2),
                    color: AppColors.error,
                  ),
                  Gap(4.h),
                  Text(
                    'الكمية: ${product.quantity} من ${product.minQuantity} (الحد الأدنى)',
                    style: TextStyle(
                      fontSize: 12.sp,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InventoryCountTab extends StatefulWidget {
  final ProductRepository productRepo;
  final InventoryRepository inventoryRepo;

  const _InventoryCountTab({
    required this.productRepo,
    required this.inventoryRepo,
  });

  @override
  State<_InventoryCountTab> createState() => _InventoryCountTabState();
}

class _InventoryCountTabState extends State<_InventoryCountTab> {
  final Map<String, int> _countedQuantities = {};
  List<Product> _products = [];
  Map<String, int> _soldQuantities = {};
  bool _isLoading = true;
  bool _showSummary = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final products = await widget.productRepo.getAllProducts();
    final db = getIt<AppDatabase>();
    final soldQuantities = await db.getProductSoldQuantities();

    setState(() {
      _products = products;
      _soldQuantities = soldQuantities;
      _isLoading = false;
    });
  }

  // حساب إحصائيات المخزون
  int get _totalProducts => _products.length;
  int get _totalQuantity => _products.fold(0, (sum, p) => sum + p.quantity);
  int get _lowStockCount => _products
      .where((p) => p.quantity > 0 && p.quantity <= p.minQuantity)
      .length;
  int get _outOfStockCount => _products.where((p) => p.quantity <= 0).length;
  double get _totalCostValue =>
      _products.fold(0.0, (sum, p) => sum + (p.purchasePrice * p.quantity));
  double get _totalSaleValue =>
      _products.fold(0.0, (sum, p) => sum + (p.salePrice * p.quantity));
  int get _totalSoldQuantity =>
      _soldQuantities.values.fold(0, (sum, qty) => sum + qty);

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return Column(
      children: [
        // Header with toggle
        Container(
          padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
          color: AppColors.primary.withOpacity(0.1),
          child: Row(
            children: [
              Icon(Icons.inventory, color: AppColors.primary, size: 20.sp),
              Gap(8.w),
              Expanded(
                child: Text(
                  'جرد المخزون',
                  style:
                      TextStyle(fontSize: 14.sp, fontWeight: FontWeight.bold),
                ),
              ),
              TextButton.icon(
                onPressed: () => setState(() => _showSummary = !_showSummary),
                icon: Icon(
                  _showSummary ? Icons.expand_less : Icons.expand_more,
                  size: 18.sp,
                ),
                label: Text(_showSummary ? 'إخفاء الملخص' : 'عرض الملخص'),
                style: TextButton.styleFrom(
                  padding: EdgeInsets.symmetric(horizontal: 8.w),
                ),
              ),
            ],
          ),
        ),

        // Summary Section (collapsible)
        if (_showSummary) ...[
          Container(
            padding: EdgeInsets.all(16.w),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Stats Row 1
                Row(
                  children: [
                    Expanded(
                      child: _StatCard(
                        title: 'إجمالي المنتجات',
                        value: '$_totalProducts',
                        icon: Icons.inventory_2,
                        color: AppColors.primary,
                      ),
                    ),
                    Gap(8.w),
                    Expanded(
                      child: _StatCard(
                        title: 'إجمالي الكميات',
                        value: '$_totalQuantity',
                        icon: Icons.numbers,
                        color: AppColors.accent,
                      ),
                    ),
                    Gap(8.w),
                    Expanded(
                      child: _StatCard(
                        title: 'المباعة',
                        value: '$_totalSoldQuantity',
                        icon: Icons.shopping_cart,
                        color: AppColors.success,
                      ),
                    ),
                  ],
                ),
                Gap(8.h),
                // Stats Row 2
                Row(
                  children: [
                    Expanded(
                      child: _StatCard(
                        title: 'نقص مخزون',
                        value: '$_lowStockCount',
                        icon: Icons.warning,
                        color: AppColors.warning,
                      ),
                    ),
                    Gap(8.w),
                    Expanded(
                      child: _StatCard(
                        title: 'نفذ المخزون',
                        value: '$_outOfStockCount',
                        icon: Icons.error,
                        color: AppColors.error,
                      ),
                    ),
                  ],
                ),
                Gap(12.h),
                // Value Summary
                Card(
                  child: Padding(
                    padding: EdgeInsets.all(12.w),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('قيمة التكلفة:',
                                style: TextStyle(fontSize: 13.sp)),
                            Text(
                              formatPrice(_totalCostValue),
                              style: TextStyle(
                                  fontWeight: FontWeight.bold, fontSize: 13.sp),
                            ),
                          ],
                        ),
                        Gap(4.h),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('قيمة البيع:',
                                style: TextStyle(fontSize: 13.sp)),
                            Text(
                              formatPrice(_totalSaleValue),
                              style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13.sp,
                                  color: AppColors.success),
                            ),
                          ],
                        ),
                        Gap(4.h),
                        Divider(),
                        Gap(4.h),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('الربح المتوقع:',
                                style: TextStyle(
                                    fontSize: 13.sp,
                                    fontWeight: FontWeight.bold)),
                            Text(
                              formatPrice(_totalSaleValue - _totalCostValue),
                              style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14.sp,
                                  color: AppColors.primary),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          Divider(height: 1),
        ],

        // Products List
        Expanded(
          child: ListView.builder(
            padding: EdgeInsets.all(16.w),
            itemCount: _products.length,
            itemBuilder: (context, index) {
              final product = _products[index];
              final soldQty = _soldQuantities[product.id] ?? 0;
              return _InventoryCountItemWithSales(
                product: product,
                soldQuantity: soldQty,
                countedQuantity: _countedQuantities[product.id],
                onCountChanged: (value) {
                  setState(() {
                    if (value != null) {
                      _countedQuantities[product.id] = value;
                    } else {
                      _countedQuantities.remove(product.id);
                    }
                  });
                },
              );
            },
          ),
        ),
        // Action buttons row
        Container(
          padding: EdgeInsets.all(16.w),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            boxShadow: [
              BoxShadow(
                color: Colors.black12,
                blurRadius: 8,
                offset: const Offset(0, -2),
              ),
            ],
          ),
          child: Row(
            children: [
              if (_countedQuantities.isNotEmpty) ...[
                Text(
                  '${_countedQuantities.length} منتج',
                  style: TextStyle(fontSize: 14.sp),
                ),
              ],
              const Spacer(),
              if (_countedQuantities.isNotEmpty)
                ElevatedButton(
                  onPressed: _saveInventoryCount,
                  child: const Text('حفظ الجرد'),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _saveInventoryCount() async {
    try {
      for (final entry in _countedQuantities.entries) {
        final product = _products.firstWhere((p) => p.id == entry.key);

        if (entry.value != product.quantity) {
          await widget.inventoryRepo.adjustStock(
            productId: entry.key,
            actualQuantity: entry.value,
            reason: 'جرد ${DateFormat('yyyy-MM-dd').format(DateTime.now())}',
          );
        }
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('تم حفظ الجرد بنجاح'),
            backgroundColor: AppColors.success,
          ),
        );
        setState(() => _countedQuantities.clear());
        _loadData();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('حدث خطأ: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }
}

class _AddMovementSheet extends StatefulWidget {
  final ProductRepository productRepo;
  final InventoryRepository inventoryRepo;
  final VoidCallback onAdded;

  const _AddMovementSheet({
    required this.productRepo,
    required this.inventoryRepo,
    required this.onAdded,
  });

  @override
  State<_AddMovementSheet> createState() => _AddMovementSheetState();
}

class _AddMovementSheetState extends State<_AddMovementSheet> {
  final _quantityController = TextEditingController();
  final _referenceController = TextEditingController();

  Product? _selectedProduct;
  String _selectedType = 'add';
  List<Product> _products = [];

  @override
  void initState() {
    super.initState();
    _loadProducts();
  }

  Future<void> _loadProducts() async {
    final products = await widget.productRepo.getAllProducts();
    setState(() {
      _products = products;
    });
  }

  @override
  void dispose() {
    _quantityController.dispose();
    _referenceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        padding: EdgeInsets.all(16.w),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'إضافة حركة مخزون',
              style: TextStyle(
                fontSize: 20.sp,
                fontWeight: FontWeight.bold,
              ),
            ),
            Gap(16.h),

            // Movement Type
            Text('نوع الحركة', style: TextStyle(fontWeight: FontWeight.bold)),
            Gap(8.h),
            Wrap(
              spacing: 8.w,
              children: [
                ChoiceChip(
                  label: const Text('إضافة'),
                  selected: _selectedType == 'add',
                  onSelected: (v) => setState(() => _selectedType = 'add'),
                ),
                ChoiceChip(
                  label: const Text('سحب'),
                  selected: _selectedType == 'remove',
                  onSelected: (v) => setState(() => _selectedType = 'remove'),
                ),
                ChoiceChip(
                  label: const Text('تالف'),
                  selected: _selectedType == 'damage',
                  onSelected: (v) => setState(() => _selectedType = 'damage'),
                ),
              ],
            ),
            Gap(16.h),

            // Product Selection
            DropdownButtonFormField<Product>(
              decoration: const InputDecoration(
                labelText: 'المنتج',
                prefixIcon: Icon(Icons.inventory_2),
              ),
              value: _selectedProduct,
              items: _products
                  .map((p) => DropdownMenuItem(
                        value: p,
                        child: Text(p.name),
                      ))
                  .toList(),
              onChanged: (value) => setState(() => _selectedProduct = value),
            ),
            Gap(16.h),

            // Quantity
            TextField(
              controller: _quantityController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'الكمية',
                prefixIcon: Icon(Icons.numbers),
              ),
            ),
            Gap(16.h),

            // Reference
            TextField(
              controller: _referenceController,
              decoration: const InputDecoration(
                labelText: 'المرجع / الملاحظات',
                prefixIcon: Icon(Icons.note),
              ),
            ),
            Gap(24.h),

            // Save Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _save,
                style: ElevatedButton.styleFrom(
                  padding: EdgeInsets.symmetric(vertical: 16.h),
                ),
                child: const Text('حفظ'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _save() async {
    if (_selectedProduct == null) return;

    final quantity = int.tryParse(_quantityController.text) ?? 0;
    if (quantity <= 0) return;

    try {
      if (_selectedType == 'add') {
        await widget.inventoryRepo.addStock(
          productId: _selectedProduct!.id,
          quantity: quantity,
          reason: _referenceController.text.isEmpty
              ? null
              : _referenceController.text,
        );
      } else {
        await widget.inventoryRepo.withdrawStock(
          productId: _selectedProduct!.id,
          quantity: quantity,
          reason: _referenceController.text.isEmpty
              ? null
              : _referenceController.text,
        );
      }

      widget.onAdded();
      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('حدث خطأ: $e'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }
}

/// بطاقة إحصائية صغيرة
class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const _StatCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(10.w),
        child: Column(
          children: [
            Icon(icon, color: color, size: 20.sp),
            Gap(4.h),
            Text(
              value,
              style: TextStyle(
                fontSize: 16.sp,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            Text(
              title,
              style: TextStyle(
                fontSize: 10.sp,
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

/// عنصر جرد مع عدد المبيعات
class _InventoryCountItemWithSales extends StatelessWidget {
  final Product product;
  final int soldQuantity;
  final int? countedQuantity;
  final ValueChanged<int?> onCountChanged;

  const _InventoryCountItemWithSales({
    required this.product,
    required this.soldQuantity,
    required this.countedQuantity,
    required this.onCountChanged,
  });

  @override
  Widget build(BuildContext context) {
    final hasChange =
        countedQuantity != null && countedQuantity != product.quantity;
    final difference =
        countedQuantity != null ? countedQuantity! - product.quantity : 0;

    final isLowStock =
        product.quantity > 0 && product.quantity <= product.minQuantity;
    final isOutOfStock = product.quantity <= 0;

    return Card(
      margin: EdgeInsets.only(bottom: 8.h),
      color: hasChange
          ? (difference > 0 ? AppColors.success : AppColors.error)
              .withOpacity(0.05)
          : isOutOfStock
              ? AppColors.error.withOpacity(0.05)
              : isLowStock
                  ? AppColors.warning.withOpacity(0.05)
                  : null,
      child: Padding(
        padding: EdgeInsets.all(12.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Product Name and Status
            Row(
              children: [
                Expanded(
                  child: Text(
                    product.name,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14.sp,
                    ),
                  ),
                ),
                if (isOutOfStock)
                  Container(
                    padding:
                        EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
                    decoration: BoxDecoration(
                      color: AppColors.error.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(4.r),
                    ),
                    child: Text(
                      'نفذ',
                      style: TextStyle(fontSize: 10.sp, color: AppColors.error),
                    ),
                  )
                else if (isLowStock)
                  Container(
                    padding:
                        EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
                    decoration: BoxDecoration(
                      color: AppColors.warning.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(4.r),
                    ),
                    child: Text(
                      'نقص',
                      style:
                          TextStyle(fontSize: 10.sp, color: AppColors.warning),
                    ),
                  ),
              ],
            ),
            Gap(8.h),
            // Info Row
            Row(
              children: [
                // Current Quantity
                _InfoChip(
                  icon: Icons.inventory,
                  label: 'الكمية',
                  value: '${product.quantity}',
                  color: isOutOfStock
                      ? AppColors.error
                      : isLowStock
                          ? AppColors.warning
                          : AppColors.primary,
                ),
                Gap(8.w),
                // Sold Quantity
                _InfoChip(
                  icon: Icons.shopping_cart,
                  label: 'المباع',
                  value: '$soldQuantity',
                  color: AppColors.success,
                ),
                Gap(8.w),
                // Min Quantity
                _InfoChip(
                  icon: Icons.warning_amber,
                  label: 'الحد الأدنى',
                  value: '${product.minQuantity}',
                  color: AppColors.textSecondary,
                ),
              ],
            ),
            Gap(8.h),
            // Price Row
            Row(
              children: [
                Text(
                  'شراء: ${formatPrice(product.purchasePrice)}',
                  style: TextStyle(
                      fontSize: 11.sp, color: AppColors.textSecondary),
                ),
                Gap(12.w),
                Text(
                  'بيع: ${formatPrice(product.salePrice)}',
                  style: TextStyle(fontSize: 11.sp, color: AppColors.success),
                ),
              ],
            ),
            Gap(8.h),
            // Count Input Row
            Row(
              children: [
                if (hasChange) ...[
                  Text(
                    'الفرق: ${difference > 0 ? '+' : ''}$difference',
                    style: TextStyle(
                      fontSize: 12.sp,
                      color:
                          difference > 0 ? AppColors.success : AppColors.error,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Gap(12.w),
                ],
                const Spacer(),
                SizedBox(
                  width: 100.w,
                  height: 36.h,
                  child: TextField(
                    keyboardType: TextInputType.number,
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 14.sp),
                    decoration: InputDecoration(
                      hintText: '${product.quantity}',
                      labelText: 'الجرد',
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 8.w,
                        vertical: 0,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8.r),
                      ),
                    ),
                    onChanged: (value) {
                      onCountChanged(int.tryParse(value));
                    },
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

/// شريحة معلومات صغيرة
class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _InfoChip({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6.r),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12.sp, color: color),
          Gap(4.w),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style:
                    TextStyle(fontSize: 8.sp, color: AppColors.textSecondary),
              ),
              Text(
                value,
                style: TextStyle(
                  fontSize: 12.sp,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
