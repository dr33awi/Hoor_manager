import 'package:flutter/material.dart';
import '../../../../app/theme/app_theme.dart';
import '../../../../shared/widgets/common_widgets.dart';

/// صفحة استعلام السعر
class PriceInquiryPage extends StatefulWidget {
  const PriceInquiryPage({super.key});

  @override
  State<PriceInquiryPage> createState() => _PriceInquiryPageState();
}

class _PriceInquiryPageState extends State<PriceInquiryPage> {
  final _searchController = TextEditingController();
  Map<String, dynamic>? _foundProduct;

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
                if (value.length >= 3) {
                  // البحث
                  setState(() {
                    _foundProduct = {
                      'name': 'منتج تجريبي',
                      'barcode': value,
                      'salePrice': 75.0,
                      'costPrice': 50.0,
                      'qty': 25.0,
                    };
                  });
                }
              },
            ),
            const SizedBox(height: 24),

            // نتيجة البحث
            if (_foundProduct != null)
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
                        _foundProduct!['name'],
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        _foundProduct!['barcode'],
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
                              '${_foundProduct!['salePrice']} ر.س',
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
                                '${_foundProduct!['qty']}',
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
          ],
        ),
      ),
    );
  }
}
