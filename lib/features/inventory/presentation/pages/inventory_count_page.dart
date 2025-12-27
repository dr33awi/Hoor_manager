import 'package:flutter/material.dart';
import '../../../../app/theme/app_theme.dart';
import '../../../../shared/widgets/common_widgets.dart';

/// صفحة جرد المستودع
class InventoryCountPage extends StatefulWidget {
  const InventoryCountPage({super.key});

  @override
  State<InventoryCountPage> createState() => _InventoryCountPageState();
}

class _InventoryCountPageState extends State<InventoryCountPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('جرد المستودع'),
        actions: [
          IconButton(
            icon: const Icon(Icons.history),
            onPressed: () {
              // عرض سجل الجرد
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // إحصائيات سريعة
          Container(
            padding: const EdgeInsets.all(AppSizes.paddingMD),
            child: Row(
              children: [
                Expanded(
                  child: _StatCard(
                    title: 'إجمالي المنتجات',
                    value: '150',
                    icon: Icons.inventory,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _StatCard(
                    title: 'تم جردها',
                    value: '45',
                    icon: Icons.check_circle,
                    color: AppColors.success,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _StatCard(
                    title: 'فروقات',
                    value: '3',
                    icon: Icons.warning,
                    color: AppColors.warning,
                  ),
                ),
              ],
            ),
          ),

          // حقل البحث
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSizes.paddingMD),
            child: CustomSearchField(
              hintText: 'ابحث أو امسح الباركود...',
              onScan: () {},
            ),
          ),

          const SizedBox(height: 8),

          // قائمة المنتجات للجرد
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(AppSizes.paddingSM),
              itemCount: 20,
              itemBuilder: (context, index) {
                final systemQty = 50 - index;
                final actualQty = systemQty + (index % 3 == 0 ? -2 : 0);
                final hasDifference = systemQty != actualQty;

                return Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'منتج ${index + 1}',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  Text(
                                    '${6000000000000 + index}',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            if (hasDifference)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.warning.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  'فرق: ${actualQty - systemQty}',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: AppColors.warning,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'الكمية بالنظام',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                  Text(
                                    '$systemQty',
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Expanded(
                              child: TextFormField(
                                initialValue: actualQty.toString(),
                                keyboardType: TextInputType.number,
                                decoration: const InputDecoration(
                                  labelText: 'الكمية الفعلية',
                                  contentPadding: EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 8,
                                  ),
                                ),
                                onChanged: (value) {
                                  // تحديث الكمية
                                },
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          // حفظ الجرد
          showConfirmDialog(
            context,
            title: 'حفظ الجرد',
            message: 'هل تريد حفظ نتائج الجرد وتعديل الكميات؟',
            confirmText: 'حفظ',
          ).then((confirmed) {
            if (confirmed == true) {
              showSnackBar(context, 'تم حفظ الجرد بنجاح');
            }
          });
        },
        icon: const Icon(Icons.save),
        label: const Text('حفظ الجرد'),
        backgroundColor: AppColors.success,
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const _StatCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            title,
            style: const TextStyle(
              fontSize: 10,
              color: AppColors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
