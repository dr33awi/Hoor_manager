import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/constants.dart';
import '../../../../core/extensions/extensions.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../products/domain/entities/entities.dart';
import '../../domain/entities/entities.dart';
import '../providers/sales_providers.dart';

/// بطاقة منتج للبيع
class ProductSaleCard extends StatelessWidget {
  final ProductEntity product;
  final VoidCallback? onTap;

  const ProductSaleCard({
    super.key,
    required this.product,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // صورة المنتج
            Expanded(
              flex: 3,
              child: Container(
                color: AppColors.secondaryLight,
                child: product.imageUrl != null
                    ? Image.network(product.imageUrl!, fit: BoxFit.cover)
                    : const Icon(Icons.image,
                        size: 48, color: AppColors.textHint),
              ),
            ),
            // معلومات المنتج
            Expanded(
              flex: 2,
              child: Padding(
                padding: const EdgeInsets.all(AppSizes.sm),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      product.name,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w500,
                          ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const Spacer(),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          product.price.toCurrency(),
                          style:
                              Theme.of(context).textTheme.titleSmall?.copyWith(
                                    color: AppColors.primary,
                                    fontWeight: FontWeight.bold,
                                  ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSizes.xs,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: product.isLowStock
                                ? AppColors.warning.withOpacity(0.1)
                                : AppColors.success.withOpacity(0.1),
                            borderRadius:
                                BorderRadius.circular(AppSizes.radiusXs),
                          ),
                          child: Text(
                            '${product.totalStock}',
                            style: TextStyle(
                              fontSize: 10,
                              color: product.isLowStock
                                  ? AppColors.warning
                                  : AppColors.success,
                            ),
                          ),
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

/// شيت اختيار اللون والمقاس
class VariantSelectorSheet extends StatefulWidget {
  final ProductEntity product;
  final void Function(ProductVariant variant, int quantity) onSelect;

  const VariantSelectorSheet({
    super.key,
    required this.product,
    required this.onSelect,
  });

  @override
  State<VariantSelectorSheet> createState() => _VariantSelectorSheetState();
}

class _VariantSelectorSheetState extends State<VariantSelectorSheet> {
  String? _selectedColor;
  String? _selectedSize;
  int _quantity = 1;

  ProductVariant? get _selectedVariant {
    if (_selectedColor == null || _selectedSize == null) return null;
    return widget.product.getVariant(_selectedColor!, _selectedSize!);
  }

  @override
  Widget build(BuildContext context) {
    final availableColors = widget.product.availableColors;
    final availableSizes = _selectedColor != null
        ? widget.product.availableSizesForColor(_selectedColor!)
        : <String>[];

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        left: AppSizes.md,
        right: AppSizes.md,
        top: AppSizes.md,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // العنوان
          Row(
            children: [
              Expanded(
                child: Text(
                  widget.product.name,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ),
              Text(
                widget.product.price.toCurrency(),
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.bold,
                    ),
              ),
            ],
          ),

          const SizedBox(height: AppSizes.lg),

          // اختيار اللون
          Text('اللون', style: Theme.of(context).textTheme.labelLarge),
          const SizedBox(height: AppSizes.sm),
          Wrap(
            spacing: AppSizes.sm,
            children: availableColors.map((color) {
              final isSelected = _selectedColor == color;
              final colorCode = CommonColors.getColorCode(color);
              return GestureDetector(
                onTap: () {
                  setState(() {
                    _selectedColor = color;
                    _selectedSize = null;
                  });
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSizes.md,
                    vertical: AppSizes.sm,
                  ),
                  decoration: BoxDecoration(
                    color: isSelected ? AppColors.primary : AppColors.surface,
                    borderRadius: BorderRadius.circular(AppSizes.radiusSm),
                    border: Border.all(
                      color: isSelected ? AppColors.primary : AppColors.border,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 16,
                        height: 16,
                        decoration: BoxDecoration(
                          color: _hexToColor(colorCode),
                          shape: BoxShape.circle,
                          border: Border.all(color: AppColors.border),
                        ),
                      ),
                      const SizedBox(width: AppSizes.xs),
                      Text(
                        color,
                        style: TextStyle(
                          color: isSelected
                              ? AppColors.textLight
                              : AppColors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),

          const SizedBox(height: AppSizes.lg),

          // اختيار المقاس
          Text('المقاس', style: Theme.of(context).textTheme.labelLarge),
          const SizedBox(height: AppSizes.sm),
          if (_selectedColor == null)
            Text(
              'اختر اللون أولاً',
              style: TextStyle(color: AppColors.textHint),
            )
          else
            Wrap(
              spacing: AppSizes.sm,
              children: availableSizes.map((size) {
                final isSelected = _selectedSize == size;
                final variant =
                    widget.product.getVariant(_selectedColor!, size);
                return GestureDetector(
                  onTap: () => setState(() => _selectedSize = size),
                  child: Container(
                    width: 50,
                    height: 40,
                    decoration: BoxDecoration(
                      color: isSelected ? AppColors.primary : AppColors.surface,
                      borderRadius: BorderRadius.circular(AppSizes.radiusSm),
                      border: Border.all(
                        color:
                            isSelected ? AppColors.primary : AppColors.border,
                      ),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          size,
                          style: TextStyle(
                            color: isSelected
                                ? AppColors.textLight
                                : AppColors.textPrimary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        Text(
                          '(${variant?.quantity ?? 0})',
                          style: TextStyle(
                            fontSize: 10,
                            color: isSelected
                                ? AppColors.textLight.withOpacity(0.7)
                                : AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),

          const SizedBox(height: AppSizes.lg),

          // الكمية
          if (_selectedVariant != null) ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  onPressed:
                      _quantity > 1 ? () => setState(() => _quantity--) : null,
                  icon: const Icon(Icons.remove_circle_outline),
                ),
                Container(
                  width: 60,
                  alignment: Alignment.center,
                  child: Text(
                    '$_quantity',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ),
                IconButton(
                  onPressed: _quantity < _selectedVariant!.quantity
                      ? () => setState(() => _quantity++)
                      : null,
                  icon: const Icon(Icons.add_circle_outline),
                ),
              ],
            ),
            Text(
              'المتوفر: ${_selectedVariant!.quantity}',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.textSecondary,
                  ),
              textAlign: TextAlign.center,
            ),
          ],

          const SizedBox(height: AppSizes.lg),

          // زر الإضافة
          ElevatedButton(
            onPressed: _selectedVariant != null
                ? () => widget.onSelect(_selectedVariant!, _quantity)
                : null,
            child: Text(
              _selectedVariant != null
                  ? 'إضافة للسلة (${(widget.product.price * _quantity).toCurrency()})'
                  : 'اختر اللون والمقاس',
            ),
          ),

          const SizedBox(height: AppSizes.lg),
        ],
      ),
    );
  }

  Color _hexToColor(String hex) {
    // التعامل مع حالة اللون المتعدد
    if (hex == '#GRADIENT' || hex == 'GRADIENT') {
      return Colors.grey; // لون افتراضي للمتعدد
    }
    hex = hex.replaceFirst('#', '');
    if (hex.length == 6) hex = 'FF$hex';
    try {
      return Color(int.parse(hex, radix: 16));
    } catch (e) {
      return Colors.grey; // لون افتراضي في حالة الخطأ
    }
  }
}

/// شيت السلة
class CartSheet extends ConsumerWidget {
  const CartSheet({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cart = ref.watch(cartProvider);

    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) {
        return Column(
          children: [
            // المقبض
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.symmetric(vertical: AppSizes.sm),
              decoration: BoxDecoration(
                color: AppColors.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            // العنوان
            Padding(
              padding: const EdgeInsets.all(AppSizes.md),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'السلة (${cart.itemCount})',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  TextButton.icon(
                    onPressed: () {
                      ref.read(cartProvider.notifier).clear();
                      Navigator.pop(context);
                    },
                    icon: const Icon(Icons.delete_outline,
                        color: AppColors.error),
                    label: const Text('مسح',
                        style: TextStyle(color: AppColors.error)),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            // قائمة العناصر
            Expanded(
              child: ListView.builder(
                controller: scrollController,
                itemCount: cart.items.length,
                itemBuilder: (context, index) {
                  final item = cart.items[index];
                  return _CartItemTile(item: item);
                },
              ),
            ),
            // الإجمالي
            Container(
              padding: const EdgeInsets.all(AppSizes.md),
              decoration: BoxDecoration(
                color: AppColors.surface,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 8,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: SafeArea(
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('الإجمالي'),
                        Text(
                          cart.total.toCurrency(),
                          style:
                              Theme.of(context).textTheme.titleLarge?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _CartItemTile extends ConsumerWidget {
  final CartItem item;

  const _CartItemTile({required this.item});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ListTile(
      leading: Container(
        width: 50,
        height: 50,
        decoration: BoxDecoration(
          color: AppColors.secondaryLight,
          borderRadius: BorderRadius.circular(AppSizes.radiusSm),
        ),
        child: item.productImage != null
            ? ClipRRect(
                borderRadius: BorderRadius.circular(AppSizes.radiusSm),
                child: Image.network(item.productImage!, fit: BoxFit.cover),
              )
            : const Icon(Icons.image, color: AppColors.textHint),
      ),
      title: Text(item.productName),
      subtitle: Text('${item.color} - ${item.size}'),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: const Icon(Icons.remove_circle_outline),
            onPressed: () =>
                ref.read(cartProvider.notifier).decrementQuantity(item.id),
          ),
          Text('${item.quantity}'),
          IconButton(
            icon: const Icon(Icons.add_circle_outline),
            onPressed: () =>
                ref.read(cartProvider.notifier).incrementQuantity(item.id),
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline, color: AppColors.error),
            onPressed: () =>
                ref.read(cartProvider.notifier).removeItem(item.id),
          ),
        ],
      ),
    );
  }
}

/// شيت الدفع
class CheckoutSheet extends ConsumerStatefulWidget {
  final void Function(InvoiceEntity invoice) onComplete;

  const CheckoutSheet({super.key, required this.onComplete});

  @override
  ConsumerState<CheckoutSheet> createState() => _CheckoutSheetState();
}

class _CheckoutSheetState extends ConsumerState<CheckoutSheet> {
  final _amountController = TextEditingController();
  bool _isLoading = false;
  DiscountType _discountType = DiscountType.percentage;
  final _discountController = TextEditingController();

  @override
  void initState() {
    super.initState();
    final cart = ref.read(cartProvider);
    _amountController.text = cart.total.toStringAsFixed(0);
  }

  @override
  void dispose() {
    _amountController.dispose();
    _discountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cart = ref.watch(cartProvider);
    final user = ref.watch(currentUserProvider);

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        left: AppSizes.md,
        right: AppSizes.md,
        top: AppSizes.md,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('إتمام عملية البيع',
                style: Theme.of(context).textTheme.titleLarge),

            const SizedBox(height: AppSizes.lg),

            // ملخص
            Container(
              padding: const EdgeInsets.all(AppSizes.md),
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(AppSizes.radiusMd),
              ),
              child: Column(
                children: [
                  _buildRow('عدد المنتجات', '${cart.itemCount}'),
                  _buildRow('المجموع الفرعي', cart.subtotal.toCurrency()),
                  if (cart.discount.hasDiscount)
                    _buildRow('الخصم', '- ${cart.discountAmount.toCurrency()}',
                        color: AppColors.error),
                  const Divider(),
                  _buildRow('الإجمالي', cart.total.toCurrency(), isBold: true),
                ],
              ),
            ),

            const SizedBox(height: AppSizes.md),

            // الخصم
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _discountController,
                    decoration: const InputDecoration(labelText: 'الخصم'),
                    keyboardType: TextInputType.number,
                    onChanged: (_) => _applyDiscount(),
                  ),
                ),
                const SizedBox(width: AppSizes.sm),
                SegmentedButton<DiscountType>(
                  segments: const [
                    ButtonSegment(
                        value: DiscountType.percentage, label: Text('%')),
                    ButtonSegment(
                        value: DiscountType.fixed, label: Text('ل.س')),
                  ],
                  selected: {_discountType},
                  onSelectionChanged: (set) {
                    setState(() => _discountType = set.first);
                    _applyDiscount();
                  },
                ),
              ],
            ),

            const SizedBox(height: AppSizes.md),

            // المبلغ المدفوع
            TextField(
              controller: _amountController,
              decoration: const InputDecoration(
                labelText: 'المبلغ المدفوع',
                suffixText: 'ل.س',
              ),
              keyboardType: TextInputType.number,
              onChanged: (_) => setState(() {}),
            ),

            const SizedBox(height: AppSizes.sm),

            // الباقي
            if (_change > 0)
              Text(
                'الباقي: ${_change.toCurrency()}',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: AppColors.success,
                    ),
                textAlign: TextAlign.center,
              ),

            const SizedBox(height: AppSizes.lg),

            // زر الإتمام
            ElevatedButton(
              onPressed:
                  _isLoading || !_canComplete ? null : () => _complete(user),
              child: _isLoading
                  ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('إتمام البيع'),
            ),

            const SizedBox(height: AppSizes.lg),
          ],
        ),
      ),
    );
  }

  Widget _buildRow(String label, String value,
      {bool isBold = false, Color? color}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSizes.xs),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Text(
            value,
            style: TextStyle(
              fontWeight: isBold ? FontWeight.bold : null,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  double get _amountPaid => double.tryParse(_amountController.text) ?? 0;
  double get _change {
    final cart = ref.read(cartProvider);
    return _amountPaid - cart.total;
  }

  bool get _canComplete => _amountPaid >= ref.read(cartProvider).total;

  void _applyDiscount() {
    final value = double.tryParse(_discountController.text) ?? 0;
    if (value > 0) {
      ref.read(cartProvider.notifier).applyDiscount(
            Discount(type: _discountType, value: value),
          );
    } else {
      ref.read(cartProvider.notifier).removeDiscount();
    }
    // تحديث المبلغ المدفوع
    final cart = ref.read(cartProvider);
    _amountController.text = cart.total.toStringAsFixed(0);
    setState(() {});
  }

  Future<void> _complete(user) async {
    setState(() => _isLoading = true);

    final invoice = await ref.read(salesActionsProvider.notifier).createInvoice(
          soldBy: user?.id ?? '',
          soldByName: user?.fullName,
          amountPaid: _amountPaid,
        );

    setState(() => _isLoading = false);

    if (invoice != null) {
      widget.onComplete(invoice);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('فشل إنشاء الفاتورة'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }
}
