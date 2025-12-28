import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gap/gap.dart';
import 'package:intl/intl.dart';

import '../../../core/di/injection.dart';
import '../../../core/theme/app_colors.dart';
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
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadProducts();
  }

  Future<void> _loadProducts() async {
    final products = await widget.productRepo.getAllProducts();
    setState(() {
      _products = products;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return Column(
      children: [
        Container(
          padding: EdgeInsets.all(16.w),
          color: AppColors.primary.withOpacity(0.1),
          child: Row(
            children: [
              Icon(Icons.info, color: AppColors.primary),
              Gap(8.w),
              Expanded(
                child: Text(
                  'أدخل الكمية الفعلية لكل منتج ثم اضغط "حفظ الجرد"',
                  style: TextStyle(fontSize: 14.sp),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: EdgeInsets.all(16.w),
            itemCount: _products.length,
            itemBuilder: (context, index) {
              final product = _products[index];
              return _InventoryCountItem(
                product: product,
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
        if (_countedQuantities.isNotEmpty)
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
                Text(
                  '${_countedQuantities.length} منتج',
                  style: TextStyle(fontSize: 14.sp),
                ),
                const Spacer(),
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
        _loadProducts();
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

class _InventoryCountItem extends StatelessWidget {
  final Product product;
  final int? countedQuantity;
  final ValueChanged<int?> onCountChanged;

  const _InventoryCountItem({
    required this.product,
    required this.countedQuantity,
    required this.onCountChanged,
  });

  @override
  Widget build(BuildContext context) {
    final hasChange =
        countedQuantity != null && countedQuantity != product.quantity;
    final difference =
        countedQuantity != null ? countedQuantity! - product.quantity : 0;

    return Card(
      margin: EdgeInsets.only(bottom: 8.h),
      color: hasChange
          ? (difference > 0 ? AppColors.success : AppColors.error)
              .withOpacity(0.05)
          : null,
      child: Padding(
        padding: EdgeInsets.all(12.w),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.name,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    'الكمية الحالية: ${product.quantity}',
                    style: TextStyle(
                      fontSize: 12.sp,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  if (hasChange)
                    Text(
                      'الفرق: ${difference > 0 ? '+' : ''}$difference',
                      style: TextStyle(
                        fontSize: 12.sp,
                        color: difference > 0
                            ? AppColors.success
                            : AppColors.error,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                ],
              ),
            ),
            SizedBox(
              width: 100.w,
              child: TextField(
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  hintText: '${product.quantity}',
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 12.w,
                    vertical: 8.h,
                  ),
                ),
                onChanged: (value) {
                  onCountChanged(int.tryParse(value));
                },
              ),
            ),
          ],
        ),
      ),
    );
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
