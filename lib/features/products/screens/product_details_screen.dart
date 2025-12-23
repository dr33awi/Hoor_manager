// lib/features/products/screens/product_details_screen.dart
// شاشة تفاصيل المنتج - تصميم حديث

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../models/product_model.dart';
import '../providers/product_provider.dart';
import 'add_edit_product_screen.dart';

class ProductDetailsScreen extends StatelessWidget {
  final ProductModel product;

  const ProductDetailsScreen({super.key, required this.product});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.arrow_back_ios_rounded,
              size: 18,
              color: Color(0xFF1A1A2E),
            ),
          ),
        ),
        title: Text(
          product.name,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Color(0xFF1A1A2E),
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.edit_outlined,
                size: 18,
                color: Color(0xFF1A1A2E),
              ),
            ),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => AddEditProductScreen(product: product),
              ),
            ),
          ),
          IconButton(
            icon: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFFFEE2E2),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.delete_outline,
                size: 18,
                color: Color(0xFFEF4444),
              ),
            ),
            onPressed: () => _showDeleteDialog(context),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Image
            Container(
              height: 220,
              width: double.infinity,
              color: Colors.grey.shade200,
              child: Stack(
                children: [
                  Center(
                    child: Icon(
                      Icons.shopping_bag_outlined,
                      size: 80,
                      color: Colors.grey.shade400,
                    ),
                  ),
                  Positioned(top: 16, right: 16, child: _buildStockBadge()),
                ],
              ),
            ),

            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Name & Brand
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              product.name,
                              style: const TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            if (product.brand.isNotEmpty) ...[
                              const SizedBox(height: 4),
                              Text(
                                product.brand,
                                style: TextStyle(
                                  color: Colors.grey.shade500,
                                  fontSize: 15,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Price
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: Colors.grey.shade100),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'سعر البيع',
                                style: TextStyle(
                                  color: Colors.grey.shade500,
                                  fontSize: 12,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${product.price.toStringAsFixed(2)} ر.س',
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF1A1A2E),
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          width: 1,
                          height: 40,
                          color: Colors.grey.shade200,
                        ),
                        Expanded(
                          child: Column(
                            children: [
                              Text(
                                'التكلفة',
                                style: TextStyle(
                                  color: Colors.grey.shade500,
                                  fontSize: 12,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${product.costPrice.toStringAsFixed(2)} ر.س',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.grey.shade700,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          width: 1,
                          height: 40,
                          color: Colors.grey.shade200,
                        ),
                        Expanded(
                          child: Column(
                            children: [
                              Text(
                                'الربح',
                                style: TextStyle(
                                  color: Colors.grey.shade500,
                                  fontSize: 12,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${product.profitMargin.toStringAsFixed(2)} ر.س',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF10B981),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Category
                  _buildInfoCard(
                    Icons.category_outlined,
                    'الفئة',
                    product.category,
                  ),
                  if (product.description.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    _buildInfoCard(
                      Icons.description_outlined,
                      'الوصف',
                      product.description,
                    ),
                  ],
                  const SizedBox(height: 24),

                  // Colors
                  const Text(
                    'الألوان',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: product.colors.map((c) => _buildChip(c)).toList(),
                  ),
                  const SizedBox(height: 20),

                  // Sizes
                  const Text(
                    'المقاسات',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: product.sizes
                        .map((s) => _buildChip('$s'))
                        .toList(),
                  ),
                  const SizedBox(height: 24),

                  // Inventory
                  const Text(
                    'المخزون',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 12),
                  _buildInventoryTable(),
                  const SizedBox(height: 24),

                  // Details
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: Colors.grey.shade100),
                    ),
                    child: Column(
                      children: [
                        _buildDetailRow(
                          'إجمالي المخزون',
                          '${product.totalQuantity} قطعة',
                        ),
                        Divider(height: 24, color: Colors.grey.shade100),
                        _buildDetailRow(
                          'نسبة الربح',
                          '${product.profitPercentage.toStringAsFixed(1)}%',
                        ),
                        Divider(height: 24, color: Colors.grey.shade100),
                        _buildDetailRow(
                          'تاريخ الإضافة',
                          DateFormat('dd/MM/yyyy').format(product.createdAt),
                        ),
                        if (product.updatedAt != null) ...[
                          Divider(height: 24, color: Colors.grey.shade100),
                          _buildDetailRow(
                            'آخر تحديث',
                            DateFormat('dd/MM/yyyy').format(product.updatedAt!),
                          ),
                        ],
                      ],
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

  Widget _buildStockBadge() {
    Color color;
    String text;
    IconData icon;

    if (product.isOutOfStock) {
      color = const Color(0xFFEF4444);
      text = 'نفذ المخزون';
      icon = Icons.error_outline;
    } else if (product.isLowStock) {
      color = const Color(0xFFD97706);
      text = 'مخزون منخفض';
      icon = Icons.warning_amber_rounded;
    } else {
      color = const Color(0xFF10B981);
      text = 'متوفر';
      icon = Icons.check_circle_outline;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(width: 6),
          Text(
            text,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w600,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard(IconData icon, String label, String value) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.grey.shade500),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChip(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Text(
        label,
        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
      ),
    );
  }

  Widget _buildInventoryTable() {
    if (product.colors.isEmpty || product.sizes.isEmpty) {
      return Text(
        'لا توجد بيانات مخزون',
        style: TextStyle(color: Colors.grey.shade500),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          headingRowColor: WidgetStateProperty.all(Colors.grey.shade50),
          headingRowHeight: 44,
          dataRowMinHeight: 40,
          dataRowMaxHeight: 44,
          columns: [
            const DataColumn(
              label: Text(
                'اللون',
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
              ),
            ),
            ...product.sizes.map(
              (size) => DataColumn(
                label: Text(
                  '$size',
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
                numeric: true,
              ),
            ),
          ],
          rows: product.colors.map((color) {
            return DataRow(
              cells: [
                DataCell(Text(color, style: const TextStyle(fontSize: 13))),
                ...product.sizes.map((size) {
                  final qty = product.getQuantity(color, size);
                  return DataCell(
                    Text(
                      '$qty',
                      style: TextStyle(
                        color: _getStockColor(qty),
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                  );
                }),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }

  Color _getStockColor(int qty) {
    if (qty == 0) return const Color(0xFFEF4444);
    if (qty <= 5) return const Color(0xFFD97706);
    return const Color(0xFF1A1A2E);
  }

  Widget _buildDetailRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(color: Colors.grey.shade500, fontSize: 13),
        ),
        Text(
          value,
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
        ),
      ],
    );
  }

  void _showDeleteDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: const Color(0xFFFEE2E2),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(
                  Icons.delete_outline,
                  color: Color(0xFFEF4444),
                  size: 28,
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'حذف المنتج',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 8),
              Text(
                'هل أنت متأكد من حذف "${product.name}"؟',
                style: TextStyle(color: Colors.grey.shade600),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(ctx),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        side: BorderSide(color: Colors.grey.shade200),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        'إلغاء',
                        style: TextStyle(color: Colors.grey.shade600),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () async {
                        Navigator.pop(ctx);
                        final provider = context.read<ProductProvider>();
                        final success = await provider.deleteProduct(
                          product.id,
                        );
                        if (success && context.mounted) {
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: const Text('تم حذف المنتج'),
                              backgroundColor: const Color(0xFF10B981),
                              behavior: SnackBarBehavior.floating,
                              margin: const EdgeInsets.all(20),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          );
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFEF4444),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text('حذف'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
