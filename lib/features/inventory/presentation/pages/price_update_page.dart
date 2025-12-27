import 'package:flutter/material.dart';
import '../../../../app/theme/app_theme.dart';
import '../../../../shared/widgets/common_widgets.dart';

/// صفحة تعديل الأسعار
class PriceUpdatePage extends StatefulWidget {
  const PriceUpdatePage({super.key});

  @override
  State<PriceUpdatePage> createState() => _PriceUpdatePageState();
}

class _PriceUpdatePageState extends State<PriceUpdatePage> {
  String _updateType = 'percent'; // 'percent' or 'amount'
  String _priceType = 'sale'; // 'sale' or 'cost'
  final _valueController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('تعديل الأسعار'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(AppSizes.paddingMD),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // نوع التعديل
            const Text(
              'نوع التعديل',
              style: TextStyle(fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: RadioListTile<String>(
                    title: const Text('نسبة %'),
                    value: 'percent',
                    groupValue: _updateType,
                    onChanged: (value) {
                      setState(() => _updateType = value!);
                    },
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
                Expanded(
                  child: RadioListTile<String>(
                    title: const Text('مبلغ ثابت'),
                    value: 'amount',
                    groupValue: _updateType,
                    onChanged: (value) {
                      setState(() => _updateType = value!);
                    },
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // نوع السعر
            const Text(
              'السعر المراد تعديله',
              style: TextStyle(fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: RadioListTile<String>(
                    title: const Text('سعر البيع'),
                    value: 'sale',
                    groupValue: _priceType,
                    onChanged: (value) {
                      setState(() => _priceType = value!);
                    },
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
                Expanded(
                  child: RadioListTile<String>(
                    title: const Text('سعر الشراء'),
                    value: 'cost',
                    groupValue: _priceType,
                    onChanged: (value) {
                      setState(() => _priceType = value!);
                    },
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // القيمة
            TextField(
              controller: _valueController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: _updateType == 'percent' ? 'النسبة' : 'المبلغ',
                suffixText: _updateType == 'percent' ? '%' : 'ر.س',
                helperText: 'استخدم قيمة سالبة للتخفيض',
              ),
            ),
            const SizedBox(height: 24),

            // زر التطبيق
            PrimaryButton(
              text: 'تطبيق على جميع المنتجات',
              icon: Icons.check,
              onPressed: () {
                showConfirmDialog(
                  context,
                  title: 'تأكيد التعديل',
                  message: 'سيتم تعديل أسعار جميع المنتجات. هل تريد المتابعة؟',
                  confirmText: 'تطبيق',
                ).then((confirmed) {
                  if (confirmed == true) {
                    showSnackBar(context, 'تم تعديل الأسعار بنجاح');
                  }
                });
              },
            ),
            const SizedBox(height: 8),
            PrimaryButton(
              text: 'تطبيق على تصنيف محدد',
              icon: Icons.category,
              isOutlined: true,
              onPressed: () {
                // اختيار تصنيف
              },
            ),
          ],
        ),
      ),
    );
  }
}
