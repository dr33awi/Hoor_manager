import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../app/providers/database_providers.dart';
import '../../../../app/theme/app_theme.dart';
import '../../../../data/database.dart';
import '../../../../shared/widgets/common_widgets.dart';

/// صفحة استعلام السعر
class PriceInquiryPage extends ConsumerStatefulWidget {
  const PriceInquiryPage({super.key});

  @override
  ConsumerState<PriceInquiryPage> createState() => _PriceInquiryPageState();
}

class _PriceInquiryPageState extends ConsumerState<PriceInquiryPage> {
  final _searchController = TextEditingController();
  Product? _foundProduct;
  bool _isSearching = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _searchProduct(String query) async {
    if (query.length < 2) {
      setState(() {
        _foundProduct = null;
      });
      return;
    }

    setState(() => _isSearching = true);

    try {
      final repo = ref.read(productRepositoryProvider);

      // البحث أولاً بالباركود
      Product? product = await repo.getProductByBarcode(query);

      // إذا لم يُوجد، البحث بالاسم
      if (product == null) {
        final products = await repo.searchProducts(query);
        if (products.isNotEmpty) {
          product = products.first;
        }
      }

      setState(() {
        _foundProduct = product;
        _isSearching = false;
      });
    } catch (e) {
      setState(() => _isSearching = false);
      if (mounted) {
        showSnackBar(context, 'حدث خطأ في البحث: $e', isError: true);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('استعلام عن سعر'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(AppSizes.paddingMD),
        child: Column(
          children: [
            // حقل البحث
            CustomSearchField(
              controller: _searchController,
              hintText: 'ابحث بالاسم أو الباركود...',
              autofocus: true,
              onScan: () {
                // مسح باركود
              },
              onChanged: (value) {
                _searchProduct(value);
              },
            ),
            const SizedBox(height: 24),

            // مؤشر التحميل
            if (_isSearching) const Center(child: CircularProgressIndicator()),

            // نتيجة البحث
            if (_foundProduct != null && !_isSearching)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(AppSizes.paddingMD),
                  child: Column(
                    children: [
                      // صورة المنتج
                      Container(
                        width: 120,
                        height: 120,
                        decoration: BoxDecoration(
                          color: AppColors.surfaceVariant,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.inventory_2,
                          size: 60,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 16),

                      // اسم المنتج
                      Text(
                        _foundProduct!.name,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (_foundProduct!.barcode != null)
                        Text(
                          _foundProduct!.barcode!,
                          style: const TextStyle(
                            color: AppColors.textSecondary,
                          ),
                        ),
                      const SizedBox(height: 24),

                      // السعر
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppColors.success.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          children: [
                            const Text(
                              'سعر البيع',
                              style: TextStyle(fontSize: 14),
                            ),
                            Text(
                              '${_foundProduct!.salePrice} ر.س',
                              style: const TextStyle(
                                fontSize: 32,
                                fontWeight: FontWeight.bold,
                                color: AppColors.success,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),

                      // معلومات إضافية
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          Column(
                            children: [
                              const Text('الكمية المتوفرة'),
                              Text(
                                '${_foundProduct!.qty}',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 18,
                                  color: _foundProduct!.qty > 0
                                      ? AppColors.success
                                      : AppColors.error,
                                ),
                              ),
                            ],
                          ),
                          Column(
                            children: [
                              const Text('سعر الشراء'),
                              Text(
                                '${_foundProduct!.costPrice} ر.س',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 18,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

            // رسالة عدم وجود نتائج
            if (_foundProduct == null &&
                !_isSearching &&
                _searchController.text.length >= 2)
              const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.search_off, size: 64, color: Colors.grey),
                    SizedBox(height: 16),
                    Text(
                      'لم يتم العثور على منتج',
                      style: TextStyle(color: Colors.grey, fontSize: 16),
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
