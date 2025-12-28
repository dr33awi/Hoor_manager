import 'package:flutter/material.dart';

import '../../../../core/constants/constants.dart';
import '../../../../core/utils/app_utils.dart';
import '../../domain/entities/entities.dart';

/// خيارات ترتيب المتغيرات
enum VariantSortOption {
  color('اللون'),
  size('المقاس'),
  quantityAsc('الكمية (تصاعدي)'),
  quantityDesc('الكمية (تنازلي)');

  final String label;
  const VariantSortOption(this.label);
}

/// بطاقة عرض المتغير مع تعديل الكمية السريع
class VariantCard extends StatelessWidget {
  final ProductVariant variant;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final VoidCallback? onCopy;
  final void Function(int)? onQuantityChanged;

  const VariantCard({
    super.key,
    required this.variant,
    this.onEdit,
    this.onDelete,
    this.onCopy,
    this.onQuantityChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: AppSizes.sm),
      child: Padding(
        padding: const EdgeInsets.all(AppSizes.sm),
        child: Row(
          children: [
            // دائرة اللون
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: _hexToColor(variant.colorCode),
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.border, width: 2),
              ),
            ),
            const SizedBox(width: AppSizes.md),

            // معلومات المتغير
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    variant.color,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSizes.sm,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withOpacity(0.1),
                          borderRadius:
                              BorderRadius.circular(AppSizes.radiusXs),
                        ),
                        child: Text(
                          'مقاس ${variant.size}',
                          style: const TextStyle(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w500,
                            fontSize: 11,
                          ),
                        ),
                      ),
                      const SizedBox(width: AppSizes.sm),
                      _buildStockBadge(),
                    ],
                  ),
                ],
              ),
            ),

            // تعديل الكمية السريع
            if (onQuantityChanged != null) _buildQuantityControls(),

            // قائمة الإجراءات
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert, color: AppColors.textSecondary),
              onSelected: (value) {
                switch (value) {
                  case 'edit':
                    onEdit?.call();
                    break;
                  case 'copy':
                    onCopy?.call();
                    break;
                  case 'delete':
                    onDelete?.call();
                    break;
                }
              },
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'edit',
                  child: Row(
                    children: [
                      Icon(Icons.edit_outlined, size: 20),
                      SizedBox(width: AppSizes.sm),
                      Text('تعديل'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'copy',
                  child: Row(
                    children: [
                      Icon(Icons.copy_outlined, size: 20),
                      SizedBox(width: AppSizes.sm),
                      Text('نسخ'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'delete',
                  child: Row(
                    children: [
                      Icon(Icons.delete_outline,
                          size: 20, color: AppColors.error),
                      SizedBox(width: AppSizes.sm),
                      Text('حذف', style: TextStyle(color: AppColors.error)),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStockBadge() {
    Color bgColor;
    Color textColor;
    String text;

    if (variant.isOutOfStock) {
      bgColor = AppColors.error.withOpacity(0.1);
      textColor = AppColors.error;
      text = 'نفد';
    } else if (variant.isLowStock) {
      bgColor = AppColors.warning.withOpacity(0.1);
      textColor = AppColors.warning;
      text = 'منخفض';
    } else {
      bgColor = AppColors.success.withOpacity(0.1);
      textColor = AppColors.success;
      text = 'متوفر';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSizes.sm, vertical: 2),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(AppSizes.radiusXs),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: textColor,
          fontWeight: FontWeight.w500,
          fontSize: 11,
        ),
      ),
    );
  }

  Widget _buildQuantityControls() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(AppSizes.radiusSm),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          InkWell(
            onTap: variant.quantity > 0
                ? () => onQuantityChanged?.call(variant.quantity - 1)
                : null,
            borderRadius: BorderRadius.circular(AppSizes.radiusSm),
            child: Padding(
              padding: const EdgeInsets.all(AppSizes.xs),
              child: Icon(
                Icons.remove,
                size: 18,
                color:
                    variant.quantity > 0 ? AppColors.error : AppColors.disabled,
              ),
            ),
          ),
          Container(
            constraints: const BoxConstraints(minWidth: 36),
            alignment: Alignment.center,
            child: Text(
              '${variant.quantity}',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
                color: variant.isOutOfStock
                    ? AppColors.error
                    : AppColors.textPrimary,
              ),
            ),
          ),
          InkWell(
            onTap: () => onQuantityChanged?.call(variant.quantity + 1),
            borderRadius: BorderRadius.circular(AppSizes.radiusSm),
            child: const Padding(
              padding: EdgeInsets.all(AppSizes.xs),
              child: Icon(Icons.add, size: 18, color: AppColors.success),
            ),
          ),
        ],
      ),
    );
  }

  Color _hexToColor(String? hex) {
    if (hex == null || hex.isEmpty) return Colors.grey;
    if (hex == '#GRADIENT' || hex == 'GRADIENT') return Colors.grey;

    String cleanHex = hex.replaceFirst('#', '');
    if (cleanHex.length == 6) cleanHex = 'FF$cleanHex';

    try {
      return Color(int.parse(cleanHex, radix: 16));
    } catch (e) {
      return Colors.grey;
    }
  }
}

/// إحصائيات المتغيرات
class VariantsStats extends StatelessWidget {
  final List<ProductVariant> variants;

  const VariantsStats({super.key, required this.variants});

  @override
  Widget build(BuildContext context) {
    if (variants.isEmpty) return const SizedBox.shrink();

    final totalQuantity = variants.fold(0, (sum, v) => sum + v.quantity);
    final uniqueColors = variants.map((v) => v.color).toSet().length;
    final uniqueSizes = variants.map((v) => v.size).toSet().length;
    final lowStockCount = variants.where((v) => v.isLowStock).length;
    final outOfStockCount = variants.where((v) => v.isOutOfStock).length;

    return Container(
      padding: const EdgeInsets.all(AppSizes.md),
      decoration: BoxDecoration(
        color: AppColors.secondaryLight,
        borderRadius: BorderRadius.circular(AppSizes.radiusMd),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStatItem(
            icon: Icons.inventory_2,
            value: '$totalQuantity',
            label: 'إجمالي',
            color: AppColors.primary,
          ),
          _buildDivider(),
          _buildStatItem(
            icon: Icons.palette,
            value: '$uniqueColors',
            label: 'ألوان',
            color: AppColors.info,
          ),
          _buildDivider(),
          _buildStatItem(
            icon: Icons.straighten,
            value: '$uniqueSizes',
            label: 'مقاسات',
            color: AppColors.success,
          ),
          if (lowStockCount > 0 || outOfStockCount > 0) ...[
            _buildDivider(),
            _buildStatItem(
              icon: Icons.warning_amber,
              value: '${lowStockCount + outOfStockCount}',
              label: 'تنبيه',
              color: AppColors.warning,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStatItem({
    required IconData icon,
    required String value,
    required String label,
    required Color color,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: color,
            fontSize: 16,
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            color: AppColors.textSecondary,
            fontSize: 11,
          ),
        ),
      ],
    );
  }

  Widget _buildDivider() {
    return Container(
      width: 1,
      height: 40,
      color: AppColors.border,
    );
  }
}

/// شريط أدوات المتغيرات
class VariantsToolbar extends StatelessWidget {
  final VoidCallback onAddSingle;
  final VoidCallback onAddBulk;
  final VariantSortOption currentSort;
  final void Function(VariantSortOption) onSortChanged;

  const VariantsToolbar({
    super.key,
    required this.onAddSingle,
    required this.onAddBulk,
    required this.currentSort,
    required this.onSortChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Text(
          'المتغيرات',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const Spacer(),
        // زر الترتيب
        PopupMenuButton<VariantSortOption>(
          icon: const Icon(Icons.sort, size: 20),
          tooltip: 'ترتيب',
          onSelected: onSortChanged,
          itemBuilder: (context) => VariantSortOption.values.map((option) {
            return PopupMenuItem(
              value: option,
              child: Row(
                children: [
                  if (currentSort == option)
                    const Icon(Icons.check, size: 18, color: AppColors.primary)
                  else
                    const SizedBox(width: 18),
                  const SizedBox(width: AppSizes.sm),
                  Text(option.label),
                ],
              ),
            );
          }).toList(),
        ),
        // زر إضافة متعدد
        IconButton(
          icon: const Icon(Icons.add_box_outlined, size: 20),
          tooltip: 'إضافة متعددة',
          onPressed: onAddBulk,
        ),
        // زر إضافة واحد
        TextButton.icon(
          onPressed: onAddSingle,
          icon: const Icon(Icons.add, size: 18),
          label: const Text('إضافة'),
        ),
      ],
    );
  }
}

/// نموذج إضافة/تعديل متغير واحد
class VariantFormSheet extends StatefulWidget {
  final ProductVariant? variant;
  final List<ProductVariant> existingVariants;
  final void Function(ProductVariant) onSave;
  final bool isCopyMode;

  const VariantFormSheet({
    super.key,
    this.variant,
    this.existingVariants = const [],
    required this.onSave,
    this.isCopyMode = false,
  });

  @override
  State<VariantFormSheet> createState() => _VariantFormSheetState();
}

class _VariantFormSheetState extends State<VariantFormSheet> {
  String? _selectedColor;
  String? _selectedSize;
  final _quantityController = TextEditingController();
  final _customColorController = TextEditingController();
  final _customSizeController = TextEditingController();
  bool _showCustomColor = false;
  bool _showCustomSize = false;
  String? _duplicateError;

  late Map<String, String> _availableColors;
  late List<String> _availableSizes;

  @override
  void initState() {
    super.initState();
    _availableColors = Map.from(CommonColors.colors);
    _availableSizes = List.from(CommonSizes.allSizes);

    for (var v in widget.existingVariants) {
      if (!_availableColors.containsKey(v.color)) {
        _availableColors[v.color] = v.colorCode;
      }
      if (!_availableSizes.contains(v.size)) {
        _availableSizes.add(v.size);
      }
    }

    if (widget.variant != null) {
      _selectedColor = widget.variant!.color;
      _selectedSize = widget.isCopyMode ? null : widget.variant!.size;
      _quantityController.text = widget.variant!.quantity.toString();
    } else {
      _quantityController.text = '0';
    }
  }

  @override
  void dispose() {
    _quantityController.dispose();
    _customColorController.dispose();
    _customSizeController.dispose();
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
            _buildHeader(),
            const SizedBox(height: AppSizes.lg),
            if (_duplicateError != null) _buildDuplicateWarning(),
            _buildColorSection(),
            const SizedBox(height: AppSizes.lg),
            _buildSizeSection(),
            const SizedBox(height: AppSizes.lg),
            _buildQuantitySection(),
            const SizedBox(height: AppSizes.xl),
            ElevatedButton(
              onPressed: _duplicateError != null ? null : _save,
              child: Text(_getButtonText()),
            ),
            const SizedBox(height: AppSizes.lg),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    String title;
    if (widget.isCopyMode) {
      title = 'نسخ المتغير';
    } else if (widget.variant != null) {
      title = 'تعديل المتغير';
    } else {
      title = 'إضافة متغير';
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.pop(context),
        ),
      ],
    );
  }

  Widget _buildDuplicateWarning() {
    return Container(
      margin: const EdgeInsets.only(bottom: AppSizes.md),
      padding: const EdgeInsets.all(AppSizes.sm),
      decoration: BoxDecoration(
        color: AppColors.error.withOpacity(0.1),
        borderRadius: BorderRadius.circular(AppSizes.radiusSm),
        border: Border.all(color: AppColors.error.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.warning_amber, color: AppColors.error, size: 20),
          const SizedBox(width: AppSizes.sm),
          Expanded(
            child: Text(
              _duplicateError!,
              style: const TextStyle(color: AppColors.error, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildColorSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('اللون', style: TextStyle(fontWeight: FontWeight.w500)),
            TextButton.icon(
              onPressed: () =>
                  setState(() => _showCustomColor = !_showCustomColor),
              icon: Icon(_showCustomColor ? Icons.close : Icons.add, size: 16),
              label: Text(_showCustomColor ? 'إلغاء' : 'لون مخصص'),
            ),
          ],
        ),
        const SizedBox(height: AppSizes.sm),
        if (_showCustomColor) _buildCustomColorInput(),
        Wrap(
          spacing: AppSizes.sm,
          runSpacing: AppSizes.sm,
          children: _availableColors.entries.map((entry) {
            final isSelected = _selectedColor == entry.key;
            return GestureDetector(
              onTap: () {
                setState(() {
                  _selectedColor = entry.key;
                  _checkDuplicate();
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
                    width: isSelected ? 2 : 1,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 18,
                      height: 18,
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
                        fontWeight:
                            isSelected ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildCustomColorInput() {
    return Container(
      margin: const EdgeInsets.only(bottom: AppSizes.md),
      padding: const EdgeInsets.all(AppSizes.sm),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(AppSizes.radiusSm),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _customColorController,
              decoration: const InputDecoration(
                hintText: 'اسم اللون (مثال: تركواز)',
                isDense: true,
                contentPadding: EdgeInsets.symmetric(
                  horizontal: AppSizes.sm,
                  vertical: AppSizes.sm,
                ),
              ),
            ),
          ),
          const SizedBox(width: AppSizes.sm),
          ElevatedButton(
            onPressed: _addCustomColor,
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: AppSizes.md),
              minimumSize: const Size(0, 40),
            ),
            child: const Text('إضافة'),
          ),
        ],
      ),
    );
  }

  Widget _buildSizeSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('المقاس', style: TextStyle(fontWeight: FontWeight.w500)),
            TextButton.icon(
              onPressed: () =>
                  setState(() => _showCustomSize = !_showCustomSize),
              icon: Icon(_showCustomSize ? Icons.close : Icons.add, size: 16),
              label: Text(_showCustomSize ? 'إلغاء' : 'مقاس مخصص'),
            ),
          ],
        ),
        const SizedBox(height: AppSizes.sm),
        if (_showCustomSize) _buildCustomSizeInput(),
        Wrap(
          spacing: AppSizes.sm,
          runSpacing: AppSizes.sm,
          children: _availableSizes.map((size) {
            final isSelected = _selectedSize == size;
            return GestureDetector(
              onTap: () {
                setState(() {
                  _selectedSize = size;
                  _checkDuplicate();
                });
              },
              child: Container(
                width: 52,
                height: 44,
                decoration: BoxDecoration(
                  color: isSelected ? AppColors.primary : AppColors.surface,
                  borderRadius: BorderRadius.circular(AppSizes.radiusSm),
                  border: Border.all(
                    color: isSelected ? AppColors.primary : AppColors.border,
                    width: isSelected ? 2 : 1,
                  ),
                ),
                child: Center(
                  child: Text(
                    size,
                    style: TextStyle(
                      color: isSelected
                          ? AppColors.textLight
                          : AppColors.textPrimary,
                      fontWeight:
                          isSelected ? FontWeight.bold : FontWeight.w500,
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildCustomSizeInput() {
    return Container(
      margin: const EdgeInsets.only(bottom: AppSizes.md),
      padding: const EdgeInsets.all(AppSizes.sm),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(AppSizes.radiusSm),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _customSizeController,
              decoration: const InputDecoration(
                hintText: 'المقاس (مثال: XXL أو 45)',
                isDense: true,
                contentPadding: EdgeInsets.symmetric(
                  horizontal: AppSizes.sm,
                  vertical: AppSizes.sm,
                ),
              ),
            ),
          ),
          const SizedBox(width: AppSizes.sm),
          ElevatedButton(
            onPressed: _addCustomSize,
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: AppSizes.md),
              minimumSize: const Size(0, 40),
            ),
            child: const Text('إضافة'),
          ),
        ],
      ),
    );
  }

  Widget _buildQuantitySection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('الكمية', style: TextStyle(fontWeight: FontWeight.w500)),
        const SizedBox(height: AppSizes.sm),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _quantityController,
                decoration: const InputDecoration(
                  hintText: '0',
                  prefixIcon: Icon(Icons.inventory),
                ),
                keyboardType: TextInputType.number,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 18),
              ),
            ),
            const SizedBox(width: AppSizes.md),
            Container(
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(AppSizes.radiusMd),
              ),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () {
                      final current =
                          int.tryParse(_quantityController.text) ?? 0;
                      if (current > 0) {
                        _quantityController.text = (current - 1).toString();
                      }
                    },
                    icon: const Icon(Icons.remove_circle,
                        color: AppColors.error, size: 28),
                  ),
                  IconButton(
                    onPressed: () {
                      final current =
                          int.tryParse(_quantityController.text) ?? 0;
                      _quantityController.text = (current + 1).toString();
                    },
                    icon: const Icon(Icons.add_circle,
                        color: AppColors.success, size: 28),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSizes.sm),
        Row(
          children: [5, 10, 20, 50].map((qty) {
            return Padding(
              padding: const EdgeInsets.only(left: AppSizes.sm),
              child: ActionChip(
                label: Text('+$qty'),
                onPressed: () {
                  final current = int.tryParse(_quantityController.text) ?? 0;
                  _quantityController.text = (current + qty).toString();
                },
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  void _addCustomColor() {
    final colorName = _customColorController.text.trim();
    if (colorName.isEmpty) return;

    if (_availableColors.containsKey(colorName)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('هذا اللون موجود بالفعل')),
      );
      return;
    }

    setState(() {
      _availableColors[colorName] = '#808080';
      _selectedColor = colorName;
      _customColorController.clear();
      _showCustomColor = false;
      _checkDuplicate();
    });
  }

  void _addCustomSize() {
    final size = _customSizeController.text.trim();
    if (size.isEmpty) return;

    if (_availableSizes.contains(size)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('هذا المقاس موجود بالفعل')),
      );
      return;
    }

    setState(() {
      _availableSizes.add(size);
      _selectedSize = size;
      _customSizeController.clear();
      _showCustomSize = false;
      _checkDuplicate();
    });
  }

  void _checkDuplicate() {
    if (_selectedColor == null || _selectedSize == null) {
      _duplicateError = null;
      return;
    }

    final isDuplicate = widget.existingVariants.any((v) =>
        v.color == _selectedColor &&
        v.size == _selectedSize &&
        (widget.variant == null || v.id != widget.variant!.id));

    setState(() {
      _duplicateError =
          isDuplicate ? 'يوجد متغير بنفس اللون والمقاس بالفعل' : null;
    });
  }

  String _getButtonText() {
    if (widget.isCopyMode) return 'نسخ';
    if (widget.variant != null) return 'تحديث';
    return 'إضافة';
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
      id: widget.isCopyMode
          ? AppUtils.generateId()
          : (widget.variant?.id ?? AppUtils.generateId()),
      color: _selectedColor!,
      colorCode: _availableColors[_selectedColor!] ?? '#808080',
      size: _selectedSize!,
      quantity: quantity,
    );

    widget.onSave(variant);
    Navigator.pop(context);
  }

  Color _hexToColor(String? hex) {
    if (hex == null || hex.isEmpty) return Colors.grey;
    if (hex == '#GRADIENT' || hex == 'GRADIENT') return Colors.grey;

    String cleanHex = hex.replaceFirst('#', '');
    if (cleanHex.length == 6) cleanHex = 'FF$cleanHex';

    try {
      return Color(int.parse(cleanHex, radix: 16));
    } catch (e) {
      return Colors.grey;
    }
  }
}

/// نموذج الإضافة السريعة للمتغيرات المتعددة
class BulkVariantFormSheet extends StatefulWidget {
  final List<ProductVariant> existingVariants;
  final void Function(List<ProductVariant>) onSave;

  const BulkVariantFormSheet({
    super.key,
    this.existingVariants = const [],
    required this.onSave,
  });

  @override
  State<BulkVariantFormSheet> createState() => _BulkVariantFormSheetState();
}

class _BulkVariantFormSheetState extends State<BulkVariantFormSheet> {
  final Set<String> _selectedColors = {};
  final Set<String> _selectedSizes = {};
  final _quantityController = TextEditingController(text: '0');

  late Map<String, String> _availableColors;
  late List<String> _availableSizes;

  @override
  void initState() {
    super.initState();
    _availableColors = Map.from(CommonColors.colors);
    _availableSizes = List.from(CommonSizes.allSizes);

    for (var v in widget.existingVariants) {
      if (!_availableColors.containsKey(v.color)) {
        _availableColors[v.color] = v.colorCode;
      }
      if (!_availableSizes.contains(v.size)) {
        _availableSizes.add(v.size);
      }
    }
  }

  @override
  void dispose() {
    _quantityController.dispose();
    super.dispose();
  }

  int get _newVariantsCount {
    int count = 0;
    for (var color in _selectedColors) {
      for (var size in _selectedSizes) {
        final exists = widget.existingVariants.any(
          (v) => v.color == color && v.size == size,
        );
        if (!exists) count++;
      }
    }
    return count;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      padding: const EdgeInsets.all(AppSizes.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // العنوان
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'إضافة متغيرات متعددة',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),

          const SizedBox(height: AppSizes.md),

          // معاينة العدد
          Container(
            padding: const EdgeInsets.all(AppSizes.sm),
            decoration: BoxDecoration(
              color: AppColors.info.withOpacity(0.1),
              borderRadius: BorderRadius.circular(AppSizes.radiusSm),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.info_outline, color: AppColors.info, size: 18),
                const SizedBox(width: AppSizes.sm),
                Text(
                  'سيتم إنشاء $_newVariantsCount متغير جديد',
                  style: const TextStyle(
                    color: AppColors.info,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: AppSizes.lg),

          Expanded(
            child: ListView(
              children: [
                // اختيار الألوان
                const Text('اختر الألوان',
                    style: TextStyle(fontWeight: FontWeight.w500)),
                const SizedBox(height: AppSizes.sm),
                Wrap(
                  spacing: AppSizes.sm,
                  runSpacing: AppSizes.sm,
                  children: _availableColors.entries.map((entry) {
                    final isSelected = _selectedColors.contains(entry.key);
                    return FilterChip(
                      selected: isSelected,
                      label: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 14,
                            height: 14,
                            decoration: BoxDecoration(
                              color: _hexToColor(entry.value),
                              shape: BoxShape.circle,
                              border: Border.all(color: AppColors.border),
                            ),
                          ),
                          const SizedBox(width: AppSizes.xs),
                          Text(entry.key),
                        ],
                      ),
                      onSelected: (selected) {
                        setState(() {
                          if (selected) {
                            _selectedColors.add(entry.key);
                          } else {
                            _selectedColors.remove(entry.key);
                          }
                        });
                      },
                    );
                  }).toList(),
                ),

                const SizedBox(height: AppSizes.lg),

                // اختيار المقاسات
                const Text('اختر المقاسات',
                    style: TextStyle(fontWeight: FontWeight.w500)),
                const SizedBox(height: AppSizes.sm),
                Wrap(
                  spacing: AppSizes.sm,
                  runSpacing: AppSizes.sm,
                  children: _availableSizes.map((size) {
                    final isSelected = _selectedSizes.contains(size);
                    return FilterChip(
                      selected: isSelected,
                      label: Text(size),
                      onSelected: (selected) {
                        setState(() {
                          if (selected) {
                            _selectedSizes.add(size);
                          } else {
                            _selectedSizes.remove(size);
                          }
                        });
                      },
                    );
                  }).toList(),
                ),

                const SizedBox(height: AppSizes.lg),

                // الكمية الافتراضية
                const Text('الكمية الافتراضية لكل متغير',
                    style: TextStyle(fontWeight: FontWeight.w500)),
                const SizedBox(height: AppSizes.sm),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _quantityController,
                        decoration: const InputDecoration(
                          hintText: '0',
                          prefixIcon: Icon(Icons.inventory),
                        ),
                        keyboardType: TextInputType.number,
                        textAlign: TextAlign.center,
                      ),
                    ),
                    const SizedBox(width: AppSizes.md),
                    ...[0, 5, 10].map((qty) {
                      return Padding(
                        padding: const EdgeInsets.only(left: AppSizes.xs),
                        child: ActionChip(
                          label: Text('$qty'),
                          onPressed: () {
                            _quantityController.text = qty.toString();
                          },
                        ),
                      );
                    }),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: AppSizes.md),

          // زر الإضافة
          ElevatedButton(
            onPressed: _newVariantsCount > 0 ? _save : null,
            child: Text('إضافة $_newVariantsCount متغير'),
          ),
        ],
      ),
    );
  }

  void _save() {
    final quantity = int.tryParse(_quantityController.text) ?? 0;
    final newVariants = <ProductVariant>[];

    for (var color in _selectedColors) {
      for (var size in _selectedSizes) {
        final exists = widget.existingVariants.any(
          (v) => v.color == color && v.size == size,
        );
        if (!exists) {
          newVariants.add(ProductVariant(
            id: AppUtils.generateId(),
            color: color,
            colorCode: _availableColors[color] ?? '#808080',
            size: size,
            quantity: quantity,
          ));
        }
      }
    }

    widget.onSave(newVariants);
    Navigator.pop(context);
  }

  Color _hexToColor(String? hex) {
    if (hex == null || hex.isEmpty) return Colors.grey;
    if (hex == '#GRADIENT' || hex == 'GRADIENT') return Colors.grey;

    String cleanHex = hex.replaceFirst('#', '');
    if (cleanHex.length == 6) cleanHex = 'FF$cleanHex';

    try {
      return Color(int.parse(cleanHex, radix: 16));
    } catch (e) {
      return Colors.grey;
    }
  }
}
