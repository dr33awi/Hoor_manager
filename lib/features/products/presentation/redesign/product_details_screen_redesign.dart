// Modern Product Details View
// ═══════════════════════════════════════════════════════════════════════════

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:barcode_widget/barcode_widget.dart';
import 'package:hoor_manager/core/theme/redesign/design_tokens.dart';
import 'package:hoor_manager/core/theme/redesign/typography.dart';
import 'package:intl/intl.dart';
import 'package:printing/printing.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../../../../core/di/injection.dart';
import '../../../../core/services/currency_service.dart';
import '../../../../data/database/app_database.dart';
import '../../../../data/repositories/product_repository.dart';
import '../../../../data/repositories/inventory_repository.dart';

class ProductDetailsScreenRedesign extends ConsumerStatefulWidget {
  final String productId;

  const ProductDetailsScreenRedesign({super.key, required this.productId});

  @override
  ConsumerState<ProductDetailsScreenRedesign> createState() =>
      _ProductDetailsScreenRedesignState();
}

class _ProductDetailsScreenRedesignState
    extends ConsumerState<ProductDetailsScreenRedesign> {
  final _productRepo = getIt<ProductRepository>();
  final _inventoryRepo = getIt<InventoryRepository>();
  final _currencyService = getIt<CurrencyService>();

  Product? _product;
  List<InventoryMovement> _movements = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final product = await _productRepo.getProductById(widget.productId);
    final movements =
        await _inventoryRepo.getProductMovements(widget.productId);

    setState(() {
      _product = product;
      _movements = movements;
      _isLoading = false;
    });
  }

  String _formatPrice(double price) {
    return '${NumberFormat('#,###').format(price)} ل.س';
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: HoorColors.background,
        appBar: AppBar(
          backgroundColor: HoorColors.surface,
          title: Text('تفاصيل المنتج', style: HoorTypography.headlineSmall),
        ),
        body: const Center(
          child: CircularProgressIndicator(color: HoorColors.primary),
        ),
      );
    }

    if (_product == null) {
      return Scaffold(
        backgroundColor: HoorColors.background,
        appBar: AppBar(
          backgroundColor: HoorColors.surface,
          title: Text('تفاصيل المنتج', style: HoorTypography.headlineSmall),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline_rounded,
                  size: 64, color: HoorColors.textSecondary),
              SizedBox(height: HoorSpacing.md.h),
              Text('المنتج غير موجود', style: HoorTypography.titleMedium),
            ],
          ),
        ),
      );
    }

    final product = _product!;
    final isLowStock = product.quantity <= product.minQuantity;

    return Scaffold(
      backgroundColor: HoorColors.background,
      body: CustomScrollView(
        slivers: [
          _buildAppBar(product),
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.all(HoorSpacing.md.w),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Stock Status Card
                  _buildStockCard(product, isLowStock),
                  SizedBox(height: HoorSpacing.md.h),

                  // Barcode Card
                  if (product.barcode != null) ...[
                    _buildBarcodeCard(product),
                    SizedBox(height: HoorSpacing.md.h),
                  ],

                  // Pricing Card
                  _buildPricingCard(product),
                  SizedBox(height: HoorSpacing.md.h),

                  // Details Card
                  _buildDetailsCard(product),
                  SizedBox(height: HoorSpacing.md.h),

                  // Movement History
                  _buildMovementHistory(),
                  SizedBox(height: HoorSpacing.xl.h),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAppBar(Product product) {
    return SliverAppBar(
      expandedHeight: 180.h,
      pinned: true,
      backgroundColor: HoorColors.primary,
      leading: IconButton(
        icon: Container(
          padding: EdgeInsets.all(HoorSpacing.xs.w),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(HoorRadius.sm),
          ),
          child: const Icon(Icons.arrow_back_rounded, color: Colors.white),
        ),
        onPressed: () => context.pop(),
      ),
      actions: [
        IconButton(
          icon: Container(
            padding: EdgeInsets.all(HoorSpacing.xs.w),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(HoorRadius.sm),
            ),
            child: const Icon(Icons.edit_rounded, color: Colors.white),
          ),
          onPressed: () async {
            await context.push('/products/edit/${product.id}');
            _loadData();
          },
        ),
        PopupMenuButton<String>(
          icon: Container(
            padding: EdgeInsets.all(HoorSpacing.xs.w),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(HoorRadius.sm),
            ),
            child: const Icon(Icons.more_vert_rounded, color: Colors.white),
          ),
          onSelected: (value) async {
            switch (value) {
              case 'print_barcode':
                await _printBarcode(product);
                break;
              case 'delete':
                await _deleteProduct(product);
                break;
            }
          },
          itemBuilder: (context) => [
            if (product.barcode != null)
              const PopupMenuItem(
                value: 'print_barcode',
                child: Row(
                  children: [
                    Icon(Icons.print_rounded, color: HoorColors.textSecondary),
                    SizedBox(width: 12),
                    Text('طباعة الباركود'),
                  ],
                ),
              ),
            const PopupMenuItem(
              value: 'delete',
              child: Row(
                children: [
                  Icon(Icons.delete_rounded, color: HoorColors.error),
                  SizedBox(width: 12),
                  Text('حذف', style: TextStyle(color: HoorColors.error)),
                ],
              ),
            ),
          ],
        ),
        SizedBox(width: HoorSpacing.xs.w),
      ],
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                HoorColors.primary,
                HoorColors.primaryDark,
              ],
            ),
          ),
          child: SafeArea(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Container(
                  width: 70.w,
                  height: 70.w,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(HoorRadius.lg),
                  ),
                  child: Icon(
                    Icons.inventory_2_rounded,
                    size: 36,
                    color: Colors.white,
                  ),
                ),
                SizedBox(height: HoorSpacing.sm.h),
                Text(
                  product.name,
                  style: HoorTypography.headlineSmall.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: HoorSpacing.md.h),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStockCard(Product product, bool isLowStock) {
    return Container(
      padding: EdgeInsets.all(HoorSpacing.md.w),
      decoration: BoxDecoration(
        color: isLowStock
            ? HoorColors.warning.withValues(alpha: 0.1)
            : HoorColors.success.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(HoorRadius.lg),
        border: Border.all(
          color: isLowStock
              ? HoorColors.warning.withValues(alpha: 0.3)
              : HoorColors.success.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(HoorSpacing.sm.w),
            decoration: BoxDecoration(
              color: isLowStock
                  ? HoorColors.warning.withValues(alpha: 0.2)
                  : HoorColors.success.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(HoorRadius.md),
            ),
            child: Icon(
              isLowStock ? Icons.warning_rounded : Icons.inventory_rounded,
              color: isLowStock ? HoorColors.warning : HoorColors.success,
              size: 28,
            ),
          ),
          SizedBox(width: HoorSpacing.md.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'المخزون الحالي',
                  style: HoorTypography.labelMedium.copyWith(
                    color: HoorColors.textSecondary,
                  ),
                ),
                Row(
                  children: [
                    Text(
                      '${product.quantity}',
                      style: HoorTypography.headlineMedium.copyWith(
                        color: isLowStock
                            ? HoorColors.warning
                            : HoorColors.success,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(width: HoorSpacing.xs.w),
                    Text(
                      'وحدة',
                      style: HoorTypography.bodyMedium.copyWith(
                        color: HoorColors.textSecondary,
                      ),
                    ),
                  ],
                ),
                if (isLowStock)
                  Text(
                    'المخزون منخفض! الحد الأدنى: ${product.minQuantity}',
                    style: HoorTypography.labelSmall.copyWith(
                      color: HoorColors.warning,
                    ),
                  ),
              ],
            ),
          ),
          ElevatedButton.icon(
            onPressed: _showStockAdjustmentDialog,
            icon: const Icon(Icons.edit_rounded, size: 18),
            label: const Text('تعديل'),
            style: ElevatedButton.styleFrom(
              backgroundColor:
                  isLowStock ? HoorColors.warning : HoorColors.success,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(HoorRadius.sm),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBarcodeCard(Product product) {
    return Container(
      padding: EdgeInsets.all(HoorSpacing.md.w),
      decoration: BoxDecoration(
        color: HoorColors.surface,
        borderRadius: BorderRadius.circular(HoorRadius.lg),
        border: Border.all(color: HoorColors.border),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(Icons.qr_code_rounded,
                  color: HoorColors.primary, size: HoorIconSize.sm),
              SizedBox(width: HoorSpacing.xs.w),
              Text(
                'الباركود',
                style: HoorTypography.titleMedium.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              TextButton.icon(
                onPressed: () => _printBarcode(product),
                icon: const Icon(Icons.print_rounded, size: 18),
                label: const Text('طباعة'),
              ),
            ],
          ),
          SizedBox(height: HoorSpacing.md.h),
          Container(
            padding: EdgeInsets.all(HoorSpacing.md.w),
            decoration: BoxDecoration(
              color: HoorColors.background,
              borderRadius: BorderRadius.circular(HoorRadius.md),
            ),
            child: Column(
              children: [
                BarcodeWidget(
                  data: product.barcode!,
                  barcode: Barcode.code128(),
                  width: 200.w,
                  height: 60.h,
                  drawText: false,
                ),
                SizedBox(height: HoorSpacing.xs.h),
                Text(
                  product.barcode!,
                  style: HoorTypography.bodyMedium.copyWith(
                    fontFamily: 'monospace',
                    letterSpacing: 2,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPricingCard(Product product) {
    final profit = product.salePrice - product.purchasePrice;
    final profitPercent =
        product.purchasePrice > 0 ? (profit / product.purchasePrice * 100) : 0;

    return Container(
      padding: EdgeInsets.all(HoorSpacing.md.w),
      decoration: BoxDecoration(
        color: HoorColors.surface,
        borderRadius: BorderRadius.circular(HoorRadius.lg),
        border: Border.all(color: HoorColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.attach_money_rounded,
                  color: HoorColors.primary, size: HoorIconSize.sm),
              SizedBox(width: HoorSpacing.xs.w),
              Text(
                'الأسعار',
                style: HoorTypography.titleMedium.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          SizedBox(height: HoorSpacing.md.h),

          // USD Price if available
          if (product.purchasePriceUsd != null &&
              product.purchasePriceUsd! > 0) ...[
            Container(
              padding: EdgeInsets.all(HoorSpacing.sm.w),
              decoration: BoxDecoration(
                color: HoorColors.info.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(HoorRadius.sm),
                border:
                    Border.all(color: HoorColors.info.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  Icon(Icons.currency_exchange_rounded,
                      color: HoorColors.info, size: 20),
                  SizedBox(width: HoorSpacing.sm.w),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'سعر الشراء بالدولار',
                        style: HoorTypography.labelSmall.copyWith(
                          color: HoorColors.textSecondary,
                        ),
                      ),
                      Text(
                        '\$${product.purchasePriceUsd!.toStringAsFixed(2)}',
                        style: HoorTypography.titleMedium.copyWith(
                          color: HoorColors.info,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const Spacer(),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        'يعادل حالياً',
                        style: HoorTypography.labelSmall.copyWith(
                          color: HoorColors.textSecondary,
                        ),
                      ),
                      Text(
                        _currencyService.formatSyp(_currencyService
                            .usdToSyp(product.purchasePriceUsd!)),
                        style: HoorTypography.bodySmall.copyWith(
                          color: HoorColors.info,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            SizedBox(height: HoorSpacing.md.h),
          ],

          // Prices Grid
          Row(
            children: [
              Expanded(
                child: _buildPriceItem(
                  label: 'سعر الشراء',
                  value: _formatPrice(product.purchasePrice),
                  subValue:
                      '\$${_currencyService.sypToUsd(product.purchasePrice).toStringAsFixed(2)}',
                  icon: Icons.shopping_cart_rounded,
                  color: HoorColors.warning,
                ),
              ),
              SizedBox(width: HoorSpacing.sm.w),
              Expanded(
                child: _buildPriceItem(
                  label: 'سعر البيع',
                  value: _formatPrice(product.salePrice),
                  subValue:
                      '\$${_currencyService.sypToUsd(product.salePrice).toStringAsFixed(2)}',
                  icon: Icons.sell_rounded,
                  color: HoorColors.success,
                ),
              ),
            ],
          ),
          SizedBox(height: HoorSpacing.sm.h),

          // Profit Indicator
          Container(
            padding: EdgeInsets.all(HoorSpacing.sm.w),
            decoration: BoxDecoration(
              color: (profit >= 0 ? HoorColors.success : HoorColors.error)
                  .withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(HoorRadius.sm),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  profit >= 0
                      ? Icons.trending_up_rounded
                      : Icons.trending_down_rounded,
                  color: profit >= 0 ? HoorColors.success : HoorColors.error,
                  size: 20,
                ),
                SizedBox(width: HoorSpacing.xs.w),
                Text(
                  profit >= 0 ? 'هامش الربح: ' : 'خسارة: ',
                  style: HoorTypography.labelMedium.copyWith(
                    color: profit >= 0 ? HoorColors.success : HoorColors.error,
                  ),
                ),
                Text(
                  _formatPrice(profit.abs()),
                  style: HoorTypography.titleSmall.copyWith(
                    color: profit >= 0 ? HoorColors.success : HoorColors.error,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(width: HoorSpacing.xs.w),
                Text(
                  '(${profitPercent.toStringAsFixed(1)}%)',
                  style: HoorTypography.labelSmall.copyWith(
                    color: profit >= 0 ? HoorColors.success : HoorColors.error,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPriceItem({
    required String label,
    required String value,
    String? subValue,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: EdgeInsets.all(HoorSpacing.sm.w),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(HoorRadius.md),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 18),
              SizedBox(width: HoorSpacing.xxs.w),
              Text(
                label,
                style: HoorTypography.labelSmall.copyWith(
                  color: HoorColors.textSecondary,
                ),
              ),
            ],
          ),
          SizedBox(height: HoorSpacing.xxs.h),
          Text(
            value,
            style: HoorTypography.titleMedium.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          if (subValue != null)
            Text(
              subValue,
              style: HoorTypography.labelSmall.copyWith(
                color: color,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildDetailsCard(Product product) {
    return Container(
      padding: EdgeInsets.all(HoorSpacing.md.w),
      decoration: BoxDecoration(
        color: HoorColors.surface,
        borderRadius: BorderRadius.circular(HoorRadius.lg),
        border: Border.all(color: HoorColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.info_rounded,
                  color: HoorColors.primary, size: HoorIconSize.sm),
              SizedBox(width: HoorSpacing.xs.w),
              Text(
                'معلومات إضافية',
                style: HoorTypography.titleMedium.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          SizedBox(height: HoorSpacing.md.h),
          _buildDetailRow('الكود', product.id),
          _buildDetailRow('الحد الأدنى للمخزون', '${product.minQuantity} وحدة'),
          if (product.description != null && product.description!.isNotEmpty)
            _buildDetailRow('الوصف', product.description!),
          _buildDetailRow(
            'تاريخ الإضافة',
            DateFormat('dd/MM/yyyy').format(product.createdAt),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.only(bottom: HoorSpacing.sm.h),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120.w,
            child: Text(
              label,
              style: HoorTypography.bodyMedium.copyWith(
                color: HoorColors.textSecondary,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: HoorTypography.bodyMedium.copyWith(
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMovementHistory() {
    return Container(
      padding: EdgeInsets.all(HoorSpacing.md.w),
      decoration: BoxDecoration(
        color: HoorColors.surface,
        borderRadius: BorderRadius.circular(HoorRadius.lg),
        border: Border.all(color: HoorColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.history_rounded,
                  color: HoorColors.primary, size: HoorIconSize.sm),
              SizedBox(width: HoorSpacing.xs.w),
              Text(
                'سجل الحركات',
                style: HoorTypography.titleMedium.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              Text(
                '${_movements.length} حركة',
                style: HoorTypography.labelMedium.copyWith(
                  color: HoorColors.textSecondary,
                ),
              ),
            ],
          ),
          SizedBox(height: HoorSpacing.md.h),
          if (_movements.isEmpty)
            Center(
              child: Padding(
                padding: EdgeInsets.all(HoorSpacing.lg.w),
                child: Column(
                  children: [
                    Icon(Icons.inventory_2_outlined,
                        size: 48, color: HoorColors.textSecondary),
                    SizedBox(height: HoorSpacing.sm.h),
                    Text(
                      'لا توجد حركات',
                      style: HoorTypography.bodyMedium.copyWith(
                        color: HoorColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _movements.take(5).length,
              separatorBuilder: (_, __) => Divider(
                color: HoorColors.border,
                height: HoorSpacing.md.h,
              ),
              itemBuilder: (context, index) {
                final movement = _movements[index];
                final isIn = movement.type == 'in';
                return Row(
                  children: [
                    Container(
                      padding: EdgeInsets.all(HoorSpacing.xs.w),
                      decoration: BoxDecoration(
                        color: (isIn ? HoorColors.success : HoorColors.error)
                            .withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(HoorRadius.sm),
                      ),
                      child: Icon(
                        isIn
                            ? Icons.arrow_downward_rounded
                            : Icons.arrow_upward_rounded,
                        color: isIn ? HoorColors.success : HoorColors.error,
                        size: 18,
                      ),
                    ),
                    SizedBox(width: HoorSpacing.sm.w),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            movement.reason ?? (isIn ? 'إضافة' : 'سحب'),
                            style: HoorTypography.bodyMedium.copyWith(
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          Text(
                            DateFormat('dd/MM/yyyy HH:mm')
                                .format(movement.createdAt),
                            style: HoorTypography.labelSmall.copyWith(
                              color: HoorColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      '${isIn ? '+' : '-'}${movement.quantity}',
                      style: HoorTypography.titleMedium.copyWith(
                        color: isIn ? HoorColors.success : HoorColors.error,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                );
              },
            ),
          if (_movements.length > 5) ...[
            SizedBox(height: HoorSpacing.sm.h),
            Center(
              child: TextButton(
                onPressed: () {
                  // Navigate to full history
                },
                child: Text('عرض كل الحركات (${_movements.length})'),
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // Actions
  // ═══════════════════════════════════════════════════════════════════════════

  Future<void> _showStockAdjustmentDialog() async {
    final quantityController = TextEditingController();
    final reasonController = TextEditingController();
    String movementType = 'in';

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setSheetState) => Container(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          decoration: BoxDecoration(
            color: HoorColors.surface,
            borderRadius: BorderRadius.vertical(
              top: Radius.circular(HoorRadius.xl),
            ),
          ),
          child: Padding(
            padding: EdgeInsets.all(HoorSpacing.lg.w),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40.w,
                    height: 4.h,
                    decoration: BoxDecoration(
                      color: HoorColors.border,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                SizedBox(height: HoorSpacing.md.h),
                Text(
                  'تعديل المخزون',
                  style: HoorTypography.headlineSmall,
                ),
                SizedBox(height: HoorSpacing.lg.h),

                // Movement Type
                Row(
                  children: [
                    Expanded(
                      child: _buildTypeChip(
                        label: 'إضافة للمخزون',
                        icon: Icons.add_rounded,
                        isSelected: movementType == 'in',
                        color: HoorColors.success,
                        onTap: () => setSheetState(() => movementType = 'in'),
                      ),
                    ),
                    SizedBox(width: HoorSpacing.sm.w),
                    Expanded(
                      child: _buildTypeChip(
                        label: 'سحب من المخزون',
                        icon: Icons.remove_rounded,
                        isSelected: movementType == 'out',
                        color: HoorColors.error,
                        onTap: () => setSheetState(() => movementType = 'out'),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: HoorSpacing.md.h),

                // Quantity
                TextField(
                  controller: quantityController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: 'الكمية',
                    prefixIcon: const Icon(Icons.numbers_rounded),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(HoorRadius.md),
                    ),
                  ),
                ),
                SizedBox(height: HoorSpacing.md.h),

                // Reason
                TextField(
                  controller: reasonController,
                  decoration: InputDecoration(
                    labelText: 'السبب (اختياري)',
                    prefixIcon: const Icon(Icons.notes_rounded),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(HoorRadius.md),
                    ),
                  ),
                ),
                SizedBox(height: HoorSpacing.lg.h),

                // Save Button
                SizedBox(
                  width: double.infinity,
                  height: 50.h,
                  child: ElevatedButton(
                    onPressed: () async {
                      final quantity =
                          int.tryParse(quantityController.text) ?? 0;
                      if (quantity <= 0) return;

                      if (movementType == 'in') {
                        await _inventoryRepo.addStock(
                          productId: widget.productId,
                          quantity: quantity,
                          reason: reasonController.text.isEmpty
                              ? null
                              : reasonController.text,
                        );
                      } else {
                        await _inventoryRepo.withdrawStock(
                          productId: widget.productId,
                          quantity: quantity,
                          reason: reasonController.text.isEmpty
                              ? null
                              : reasonController.text,
                        );
                      }

                      if (mounted) {
                        Navigator.pop(context);
                        _loadData();
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: HoorColors.primary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(HoorRadius.md),
                      ),
                    ),
                    child: Text(
                      'حفظ',
                      style: HoorTypography.titleMedium.copyWith(
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
                SizedBox(height: HoorSpacing.md.h),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTypeChip({
    required String label,
    required IconData icon,
    required bool isSelected,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(HoorRadius.md),
      child: Container(
        padding: EdgeInsets.all(HoorSpacing.md.w),
        decoration: BoxDecoration(
          color:
              isSelected ? color.withValues(alpha: 0.1) : HoorColors.background,
          borderRadius: BorderRadius.circular(HoorRadius.md),
          border: Border.all(
            color: isSelected ? color : HoorColors.border,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          children: [
            Icon(icon, color: isSelected ? color : HoorColors.textSecondary),
            SizedBox(height: HoorSpacing.xxs.h),
            Text(
              label,
              style: HoorTypography.labelSmall.copyWith(
                color: isSelected ? color : HoorColors.textSecondary,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _printBarcode(Product product) async {
    if (product.barcode == null) return;

    final doc = pw.Document();
    doc.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.roll80,
        build: (context) => pw.Center(
          child: pw.Column(
            mainAxisSize: pw.MainAxisSize.min,
            children: [
              pw.BarcodeWidget(
                barcode: pw.Barcode.ean13(),
                data: product.barcode!,
                width: 200,
                height: 80,
              ),
              pw.SizedBox(height: 8),
              pw.Text(product.name, style: pw.TextStyle(fontSize: 12)),
            ],
          ),
        ),
      ),
    );

    await Printing.layoutPdf(onLayout: (format) => doc.save());
  }

  Future<void> _deleteProduct(Product product) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(HoorRadius.lg),
        ),
        title: const Text('حذف المنتج'),
        content: Text('هل أنت متأكد من حذف "${product.name}"؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: HoorColors.error,
            ),
            child: const Text('حذف'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _productRepo.deleteProduct(product.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('تم حذف المنتج'),
            backgroundColor: HoorColors.success,
            behavior: SnackBarBehavior.floating,
          ),
        );
        context.pop();
      }
    }
  }
}
