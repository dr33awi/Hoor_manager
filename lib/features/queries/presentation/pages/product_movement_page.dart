import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../app/providers/database_providers.dart';
import '../../../../app/theme/app_theme.dart';
import '../../../../data/database.dart';
import '../../../../shared/widgets/common_widgets.dart';

/// صفحة حركة المنتج
class ProductMovementPage extends ConsumerStatefulWidget {
  const ProductMovementPage({super.key});

  @override
  ConsumerState<ProductMovementPage> createState() =>
      _ProductMovementPageState();
}

class _ProductMovementPageState extends ConsumerState<ProductMovementPage> {
  final _searchController = TextEditingController();
  Product? _selectedProduct;
  List<InventoryMovement> _movements = [];
  bool _isLoading = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _searchAndSelectProduct(String query) async {
    if (query.length < 2) {
      setState(() {
        _selectedProduct = null;
        _movements = [];
      });
      return;
    }

    setState(() => _isLoading = true);

    try {
      final repo = ref.read(productRepositoryProvider);

      // البحث بالباركود أولاً
      Product? product = await repo.getProductByBarcode(query);

      // إذا لم يُوجد، البحث بالاسم
      if (product == null) {
        final products = await repo.searchProducts(query);
        if (products.isNotEmpty) {
          product = products.first;
        }
      }

      if (product != null) {
        // جلب حركات المنتج
        final movementRepo = ref.read(inventoryMovementRepositoryProvider);
        final movements = await movementRepo.getProductMovements(product.id);
        setState(() {
          _selectedProduct = product;
          _movements = movements;
          _isLoading = false;
        });
      } else {
        setState(() {
          _selectedProduct = null;
          _movements = [];
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        showSnackBar(context, 'حدث خطأ: $e', isError: true);
      }
    }
  }

  String _getMovementTypeText(String type) {
    switch (type) {
      case 'purchase':
        return 'فاتورة شراء';
      case 'sale':
        return 'فاتورة مبيعات';
      case 'return':
        return 'مرتجع';
      case 'adjustment':
        return 'تعديل جرد';
      case 'transfer':
        return 'نقل';
      default:
        return type;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('حركة المنتج'),
        actions: [
          IconButton(
            icon: const Icon(Icons.print),
            onPressed: _selectedProduct != null ? () {} : null,
          ),
        ],
      ),
      body: Column(
        children: [
          // البحث عن المنتج
          Padding(
            padding: const EdgeInsets.all(AppSizes.paddingMD),
            child: CustomSearchField(
              controller: _searchController,
              hintText: 'ابحث عن منتج...',
              onScan: () {},
              onChanged: (value) {
                _searchAndSelectProduct(value);
              },
            ),
          ),

          // مؤشر التحميل
          if (_isLoading) const LinearProgressIndicator(),

          // معلومات المنتج المختار
          if (_selectedProduct != null)
            Container(
              padding: const EdgeInsets.all(AppSizes.paddingMD),
              color: AppColors.surfaceVariant,
              child: Row(
                children: [
                  Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.inventory_2),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _selectedProduct!.name,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        Text(
                          'الكمية الحالية: ${_selectedProduct!.qty}',
                          style: const TextStyle(fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

          // قائمة الحركات
          if (_selectedProduct != null)
            Expanded(
              child: _movements.isEmpty
                  ? const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.history, size: 64, color: Colors.grey),
                          SizedBox(height: 16),
                          Text(
                            'لا توجد حركات لهذا المنتج',
                            style: TextStyle(color: Colors.grey),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(AppSizes.paddingSM),
                      itemCount: _movements.length,
                      itemBuilder: (context, index) {
                        final movement = _movements[index];
                        final isIn = movement.qty > 0;
                        return Card(
                          margin: const EdgeInsets.only(bottom: 8),
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor: isIn
                                  ? AppColors.success.withOpacity(0.1)
                                  : AppColors.error.withOpacity(0.1),
                              child: Icon(
                                isIn ? Icons.add : Icons.remove,
                                color:
                                    isIn ? AppColors.success : AppColors.error,
                              ),
                            ),
                            title: Text(_getMovementTypeText(movement.type)),
                            subtitle: Text(
                              movement.createdAt.toString().substring(0, 10),
                            ),
                            trailing: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  '${isIn ? '+' : ''}${movement.qty.toInt()}',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: isIn
                                        ? AppColors.success
                                        : AppColors.error,
                                  ),
                                ),
                                Text(
                                  'الرصيد: ${movement.qtyAfter.toInt()}',
                                  style: const TextStyle(fontSize: 12),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            )
          else if (!_isLoading && _searchController.text.length >= 2)
            const Expanded(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.search_off, size: 64, color: Colors.grey),
                    SizedBox(height: 16),
                    Text(
                      'لم يتم العثور على منتج',
                      style: TextStyle(color: Colors.grey),
                    ),
                  ],
                ),
              ),
            )
          else
            const Expanded(
              child: Center(
                child: Text('ابحث عن منتج لعرض حركته'),
              ),
            ),
        ],
      ),
    );
  }
}
