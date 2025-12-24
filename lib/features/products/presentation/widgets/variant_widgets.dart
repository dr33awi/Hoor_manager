import 'package:flutter/material.dart';

import '../../../../core/constants/constants.dart';
import '../../../../core/utils/app_utils.dart';
import '../../domain/entities/entities.dart';

/// بطاقة عرض المتغير
class VariantCard extends StatelessWidget {
  final ProductVariant variant;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  const VariantCard({
    super.key,
    required this.variant,
    this.onEdit,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: AppSizes.sm),
      child: ListTile(
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: _hexToColor(variant.colorCode),
            shape: BoxShape.circle,
            border: Border.all(color: AppColors.border),
          ),
        ),
        title: Text('${variant.color} - مقاس ${variant.size}'),
        subtitle: Text(
          'الكمية: ${variant.quantity}',
          style: TextStyle(
            color: variant.isLowStock
                ? AppColors.warning
                : variant.isOutOfStock
                    ? AppColors.error
                    : AppColors.textSecondary,
          ),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.edit_outlined),
              onPressed: onEdit,
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline, color: AppColors.error),
              onPressed: onDelete,
            ),
          ],
        ),
      ),
    );
  }

  Color _hexToColor(String hex) {
    if (hex == '#GRADIENT' || hex == 'GRADIENT') {
      return Colors.grey;
    }
    hex = hex.replaceFirst('#', '');
    if (hex.length == 6) hex = 'FF$hex';
    try {
      return Color(int.parse(hex, radix: 16));
    } catch (e) {
      return Colors.grey;
    }
  }
}

/// نموذج إضافة/تعديل متغير
class VariantFormSheet extends StatefulWidget {
  final ProductVariant? variant;
  final void Function(ProductVariant) onSave;

  const VariantFormSheet({
    super.key,
    this.variant,
    required this.onSave,
  });

  @override
  State<VariantFormSheet> createState() => _VariantFormSheetState();
}

class _VariantFormSheetState extends State<VariantFormSheet> {
  String? _selectedColor;
  String? _selectedSize;
  final _quantityController = TextEditingController();
  final _barcodeController = TextEditingController();

  @override
  void initState() {
    super.initState();
    if (widget.variant != null) {
      _selectedColor = widget.variant!.color;
      _selectedSize = widget.variant!.size;
      _quantityController.text = widget.variant!.quantity.toString();
      _barcodeController.text = widget.variant!.barcode ?? '';
    } else {
      _quantityController.text = '0';
    }
  }

  @override
  void dispose() {
    _quantityController.dispose();
    _barcodeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
            // العنوان
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  widget.variant != null ? 'تعديل المتغير' : 'إضافة متغير',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),

            const SizedBox(height: AppSizes.lg),

            // اختيار اللون
            Text('اللون', style: Theme.of(context).textTheme.labelLarge),
            const SizedBox(height: AppSizes.sm),
            Wrap(
              spacing: AppSizes.sm,
              runSpacing: AppSizes.sm,
              children: CommonColors.colors.entries.map((entry) {
                final isSelected = _selectedColor == entry.key;
                return GestureDetector(
                  onTap: () => setState(() => _selectedColor = entry.key),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSizes.md,
                      vertical: AppSizes.sm,
                    ),
                    decoration: BoxDecoration(
                      color: isSelected ? AppColors.primary : AppColors.surface,
                      borderRadius: BorderRadius.circular(AppSizes.radiusSm),
                      border: Border.all(
                        color:
                            isSelected ? AppColors.primary : AppColors.border,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 16,
                          height: 16,
                          decoration: BoxDecoration(
                            color: _hexToColor(entry.value),
                            shape: BoxShape.circle,
                            border: Border.all(color: AppColors.border),
                          ),
                        ),
                        const SizedBox(width: AppSizes.xs),
                        Text(
                          entry.key,
                          style: TextStyle(
                            color: isSelected
                                ? AppColors.textLight
                                : AppColors.textPrimary,
                            fontSize: 12,
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
            Wrap(
              spacing: AppSizes.sm,
              runSpacing: AppSizes.sm,
              children: CommonSizes.allSizes.map((size) {
                final isSelected = _selectedSize == size;
                return GestureDetector(
                  onTap: () => setState(() => _selectedSize = size),
                  child: Container(
                    width: 48,
                    height: 40,
                    decoration: BoxDecoration(
                      color: isSelected ? AppColors.primary : AppColors.surface,
                      borderRadius: BorderRadius.circular(AppSizes.radiusSm),
                      border: Border.all(
                        color:
                            isSelected ? AppColors.primary : AppColors.border,
                      ),
                    ),
                    child: Center(
                      child: Text(
                        size,
                        style: TextStyle(
                          color: isSelected
                              ? AppColors.textLight
                              : AppColors.textPrimary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),

            const SizedBox(height: AppSizes.lg),

            // الكمية
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _quantityController,
                    decoration: const InputDecoration(
                      labelText: 'الكمية',
                      prefixIcon: Icon(Icons.inventory),
                    ),
                    keyboardType: TextInputType.number,
                  ),
                ),
                const SizedBox(width: AppSizes.md),
                IconButton(
                  onPressed: () {
                    final current = int.tryParse(_quantityController.text) ?? 0;
                    if (current > 0) {
                      _quantityController.text = (current - 1).toString();
                    }
                  },
                  icon: const Icon(Icons.remove_circle_outline),
                ),
                IconButton(
                  onPressed: () {
                    final current = int.tryParse(_quantityController.text) ?? 0;
                    _quantityController.text = (current + 1).toString();
                  },
                  icon: const Icon(Icons.add_circle_outline),
                ),
              ],
            ),

            const SizedBox(height: AppSizes.md),

            // الباركود
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _barcodeController,
                    decoration: const InputDecoration(
                      labelText: 'باركود (اختياري)',
                      prefixIcon: Icon(Icons.qr_code),
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.auto_awesome),
                  onPressed: () {
                    _barcodeController.text = AppUtils.generateBarcode();
                  },
                  tooltip: 'توليد باركود',
                ),
              ],
            ),

            const SizedBox(height: AppSizes.xl),

            // زر الحفظ
            ElevatedButton(
              onPressed: _save,
              child: Text(widget.variant != null ? 'تحديث' : 'إضافة'),
            ),

            const SizedBox(height: AppSizes.lg),
          ],
        ),
      ),
    );
  }

  void _save() {
    if (_selectedColor == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('اختر اللون')),
      );
      return;
    }

    if (_selectedSize == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('اختر المقاس')),
      );
      return;
    }

    final quantity = int.tryParse(_quantityController.text) ?? 0;

    final variant = ProductVariant(
      id: widget.variant?.id ?? AppUtils.generateId(),
      color: _selectedColor!,
      colorCode: CommonColors.getColorCode(_selectedColor!),
      size: _selectedSize!,
      quantity: quantity,
      barcode: _barcodeController.text.trim().isEmpty
          ? null
          : _barcodeController.text.trim(),
    );

    widget.onSave(variant);
    Navigator.pop(context);
  }

  Color _hexToColor(String hex) {
    if (hex == '#GRADIENT' || hex == 'GRADIENT') {
      return Colors.grey;
    }
    hex = hex.replaceFirst('#', '');
    if (hex.length == 6) hex = 'FF$hex';
    try {
      return Color(int.parse(hex, radix: 16));
    } catch (e) {
      return Colors.grey;
    }
  }
}
