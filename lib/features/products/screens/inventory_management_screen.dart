// lib/features/products/screens/inventory_management_screen.dart
// شاشة إدارة المخزون المتقدمة

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../providers/product_provider.dart';
import '../models/product_model.dart';
import '../widgets/barcode_scanner_widget.dart';
import '../../../core/theme/app_theme.dart';

class InventoryManagementScreen extends StatefulWidget {
  const InventoryManagementScreen({super.key});

  @override
  State<InventoryManagementScreen> createState() =>
      _InventoryManagementScreenState();
}

class _InventoryManagementScreenState extends State<InventoryManagementScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
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
            child: Icon(
              Icons.arrow_back_ios_rounded,
              size: 16,
              color: AppColors.primary,
            ),
          ),
        ),
        title: const Text(
          'إدارة المخزون',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: AppColors.primary,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppColors.info.withValues(alpha: 0.15),
                    AppColors.info.withValues(alpha: 0.1),
                  ],
                ),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.qr_code_scanner,
                size: 18,
                color: AppColors.info,
              ),
            ),
            onPressed: _scanBarcode,
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        children: [
          // البحث
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.03),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.grey.shade100),
              ),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'بحث بالاسم أو الباركود...',
                  hintStyle: TextStyle(
                    color: Colors.grey.shade400,
                    fontSize: 14,
                  ),
                  prefixIcon: Icon(Icons.search, color: Colors.grey.shade400),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(
                          icon: Icon(
                            Icons.close,
                            color: Colors.grey.shade400,
                            size: 20,
                          ),
                          onPressed: () {
                            _searchController.clear();
                            setState(() => _searchQuery = '');
                          },
                        )
                      : null,
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                ),
                onChanged: (v) => setState(() => _searchQuery = v),
              ),
            ),
          ),

          // التبويبات
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(10),
            ),
            child: TabBar(
              controller: _tabController,
              indicator: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(8),
              ),
              indicatorPadding: const EdgeInsets.all(4),
              labelColor: Colors.white,
              unselectedLabelColor: Colors.grey.shade600,
              labelStyle: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
              tabs: const [
                Tab(text: 'الكل'),
                Tab(text: 'منخفض'),
                Tab(text: 'نفذ'),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // المحتوى
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildProductsList(filter: 'all'),
                _buildProductsList(filter: 'low'),
                _buildProductsList(filter: 'out'),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showBulkActions,
        backgroundColor: AppColors.primary,
        elevation: 4,
        icon: const Icon(Icons.inventory),
        label: const Text(
          'إجراءات جماعية',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
      ),
    );
  }

  Widget _buildProductsList({required String filter}) {
    return Consumer<ProductProvider>(
      builder: (context, provider, _) {
        var products = provider.allProducts.where((p) => p.isActive).toList();

        switch (filter) {
          case 'low':
            products = products
                .where((p) => p.isLowStock && !p.isOutOfStock)
                .toList();
            break;
          case 'out':
            products = products.where((p) => p.isOutOfStock).toList();
            break;
        }

        if (_searchQuery.isNotEmpty) {
          products = products
              .where(
                (p) =>
                    p.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
                    p.barcode.contains(_searchQuery),
              )
              .toList();
        }

        if (products.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  filter == 'out'
                      ? Icons.check_circle_outline
                      : Icons.inventory_2_outlined,
                  size: 60,
                  color: Colors.grey.shade300,
                ),
                const SizedBox(height: 16),
                Text(
                  filter == 'out'
                      ? 'جميع المنتجات متوفرة!'
                      : filter == 'low'
                      ? 'لا توجد منتجات منخفضة المخزون'
                      : 'لا توجد منتجات',
                  style: TextStyle(color: Colors.grey.shade500, fontSize: 14),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          itemCount: products.length,
          itemBuilder: (_, i) => _buildProductCard(products[i]),
        );
      },
    );
  }

  Widget _buildProductCard(ProductModel product) {
    final stockColor = product.isOutOfStock
        ? AppColors.error
        : product.isLowStock
        ? AppColors.warning
        : AppColors.success;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          leading: Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: stockColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              product.isOutOfStock
                  ? Icons.error_outline
                  : product.isLowStock
                  ? Icons.warning_amber_rounded
                  : Icons.check_circle_outline,
              color: stockColor,
            ),
          ),
          title: Text(
            product.name,
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                product.barcode,
                style: TextStyle(
                  fontSize: 10,
                  color: Colors.grey.shade500,
                  fontFamily: 'monospace',
                ),
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: stockColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      '${product.totalQuantity} قطعة',
                      style: TextStyle(
                        color: stockColor,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '${product.colors.length} لون • ${product.sizes.length} مقاس',
                    style: TextStyle(fontSize: 10, color: Colors.grey.shade500),
                  ),
                ],
              ),
            ],
          ),
          trailing: PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert, size: 20),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            itemBuilder: (_) => [
              const PopupMenuItem(
                value: 'add',
                child: Row(
                  children: [
                    Icon(Icons.add_circle_outline, size: 20),
                    SizedBox(width: 12),
                    Text('إضافة مخزون'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'print',
                child: Row(
                  children: [
                    Icon(Icons.print, size: 20),
                    SizedBox(width: 12),
                    Text('طباعة باركود'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'history',
                child: Row(
                  children: [
                    Icon(Icons.history, size: 20),
                    SizedBox(width: 12),
                    Text('سجل الحركات'),
                  ],
                ),
              ),
            ],
            onSelected: (v) {
              switch (v) {
                case 'add':
                  _showAddStockDialog(product);
                  break;
                case 'print':
                  _showPrintAllBarcodes(product);
                  break;
                case 'history':
                  _showStockHistory(product);
                  break;
              }
            },
          ),
          children: [
            _buildInventoryTable(product),
          ],
        ),
      ),
    );
  }

  Widget _buildInventoryTable(ProductModel product) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Divider(),
        const SizedBox(height: 8),
        const Text(
          'تفاصيل المخزون',
          style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
        ),
        const SizedBox(height: 12),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: DataTable(
            columnSpacing: 16,
            headingRowHeight: 40,
            dataRowMinHeight: 36,
            dataRowMaxHeight: 40,
            headingRowColor: WidgetStateProperty.all(Colors.grey.shade50),
            columns: [
              const DataColumn(
                label: Text('اللون', style: TextStyle(fontSize: 12)),
              ),
              ...product.sizes.map(
                (s) => DataColumn(
                  label: Text('$s', style: const TextStyle(fontSize: 12)),
                  numeric: true,
                ),
              ),
              const DataColumn(label: Text('', style: TextStyle(fontSize: 12))),
            ],
            rows: product.colors.map((color) {
              return DataRow(
                cells: [
                  DataCell(Text(color, style: const TextStyle(fontSize: 12))),
                  ...product.sizes.map((size) {
                    final qty = product.getQuantity(color, size);
                    final qtyColor = qty == 0
                        ? AppColors.error
                        : qty <= 5
                        ? AppColors.warning
                        : Colors.black;
                    return DataCell(
                      GestureDetector(
                        onTap: () => _editVariantStock(product, color, size),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: qtyColor.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            '$qty',
                            style: TextStyle(
                              color: qtyColor,
                              fontWeight: FontWeight.w600,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ),
                    );
                  }),
                  DataCell(
                    IconButton(
                      icon: const Icon(Icons.print, size: 16),
                      onPressed: () => _printColorBarcodes(product, color),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ),
                ],
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  void _scanBarcode() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => BarcodeScannerWidget(
        onBarcodeScanned: (barcode) {
          Navigator.pop(context);
          _findProductByBarcode(barcode);
        },
      ),
    );
  }

  void _findProductByBarcode(String barcode) {
    final provider = context.read<ProductProvider>();

    for (final product in provider.allProducts) {
      if (product.barcode == barcode) {
        _showAddStockDialog(product);
        return;
      }

      final variant = product.findVariantByBarcode(barcode);
      if (variant != null) {
        _editVariantStock(product, variant.color, variant.size);
        return;
      }
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('لم يتم العثور على منتج بهذا الباركود'),
        backgroundColor: AppColors.error,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(20),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  void _showAddStockDialog(ProductModel product) {
    String? selectedColor;
    int? selectedSize;
    final qtyController = TextEditingController(text: '1');

    showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (ctx, setState) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.success.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.add_circle,
                  color: AppColors.success,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('إضافة مخزون', style: TextStyle(fontSize: 14)),
                    Text(
                      product.name,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'اللون:',
                  style: TextStyle(fontWeight: FontWeight.w500, fontSize: 13),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: product.colors
                      .map(
                        (c) => ChoiceChip(
                          label: Text(c),
                          selected: selectedColor == c,
                          onSelected: (s) =>
                              setState(() => selectedColor = s ? c : null),
                        ),
                      )
                      .toList(),
                ),
                const SizedBox(height: 16),
                const Text(
                  'المقاس:',
                  style: TextStyle(fontWeight: FontWeight.w500, fontSize: 13),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: product.sizes
                      .map(
                        (s) => ChoiceChip(
                          label: Text('$s'),
                          selected: selectedSize == s,
                          onSelected: (sel) =>
                              setState(() => selectedSize = sel ? s : null),
                        ),
                      )
                      .toList(),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: qtyController,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  decoration: InputDecoration(
                    labelText: 'الكمية المضافة',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
                if (selectedColor != null && selectedSize != null) ...[
                  const SizedBox(height: 12),
                  Text(
                    'المخزون الحالي: ${product.getQuantity(selectedColor!, selectedSize!)}',
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                  ),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('إلغاء'),
            ),
            ElevatedButton(
              onPressed: selectedColor != null && selectedSize != null
                  ? () async {
                      final qty = int.tryParse(qtyController.text) ?? 0;
                      if (qty <= 0) return;

                      final currentQty = product.getQuantity(
                        selectedColor!,
                        selectedSize!,
                      );
                      final provider = context.read<ProductProvider>();
                      await provider.updateInventory(
                        product.id,
                        selectedColor!,
                        selectedSize!,
                        currentQty + qty,
                      );

                      if (mounted) {
                        Navigator.pop(ctx);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('تم إضافة $qty قطعة'),
                            backgroundColor: AppColors.success,
                            behavior: SnackBarBehavior.floating,
                            margin: const EdgeInsets.all(20),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        );
                      }
                    }
                  : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.success,
              ),
              child: const Text('إضافة'),
            ),
          ],
        ),
      ),
    );
  }

  void _editVariantStock(ProductModel product, String color, int size) {
    final currentQty = product.getQuantity(color, size);
    final qtyController = TextEditingController(text: currentQty.toString());

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('تعديل المخزون', style: const TextStyle(fontSize: 16)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              product.name,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            Text(
              '$color - مقاس $size',
              style: TextStyle(color: Colors.grey.shade600),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: qtyController,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: InputDecoration(
                labelText: 'الكمية',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              autofocus: true,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () async {
              final newQty = int.tryParse(qtyController.text) ?? 0;
              final provider = context.read<ProductProvider>();
              await provider.updateInventory(product.id, color, size, newQty);

              if (mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: const Text('تم تحديث المخزون'),
                    backgroundColor: AppColors.success,
                    behavior: SnackBarBehavior.floating,
                    margin: const EdgeInsets.all(20),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
            child: const Text('حفظ'),
          ),
        ],
      ),
    );
  }

  void _showPrintAllBarcodes(ProductModel product) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('طباعة باركود'),
        content: Text('سيتم طباعة باركود لجميع متغيرات "${product.name}"'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(const SnackBar(content: Text('جاري الطباعة...')));
            },
            child: const Text('طباعة'),
          ),
        ],
      ),
    );
  }

  void _printColorBarcodes(ProductModel product, String color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('طباعة باركود $color'),
        backgroundColor: AppColors.success,
      ),
    );
  }

  void _showStockHistory(ProductModel product) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('سجل الحركات - قريباً')));
  }

  void _showBulkActions() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'إجراءات جماعية',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 20),
            _buildActionTile(
              icon: Icons.print,
              title: 'طباعة جميع الباركود',
              subtitle: 'طباعة باركود لجميع المنتجات',
              onTap: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('جاري الطباعة...')),
                );
              },
            ),
            _buildActionTile(
              icon: Icons.file_download,
              title: 'تصدير المخزون',
              subtitle: 'تصدير بيانات المخزون لملف Excel',
              onTap: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('جاري التصدير...')),
                );
              },
            ),
            _buildActionTile(
              icon: Icons.warning_amber,
              title: 'تنبيهات المخزون',
              subtitle: 'إعداد تنبيهات نفاد المخزون',
              onTap: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(const SnackBar(content: Text('قريباً...')));
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: AppColors.primary.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: AppColors.primary),
      ),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
      subtitle: Text(
        subtitle,
        style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
      ),
      onTap: onTap,
    );
  }
}
