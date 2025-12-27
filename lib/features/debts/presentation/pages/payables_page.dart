import 'package:flutter/material.dart';
import '../../../../app/theme/app_theme.dart';
import '../../../../shared/widgets/common_widgets.dart';

/// صفحة المستحقات (الديون للموردين)
class PayablesPage extends StatelessWidget {
  const PayablesPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('المستحقات'),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: () {},
          ),
        ],
      ),
      body: Column(
        children: [
          // ملخص
          Container(
            padding: const EdgeInsets.all(AppSizes.paddingMD),
            color: AppColors.warning.withOpacity(0.1),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'إجمالي المستحقات للموردين',
                  style: TextStyle(fontWeight: FontWeight.w500),
                ),
                Text(
                  '8,000.00 ر.س',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.warning,
                  ),
                ),
              ],
            ),
          ),

          // قائمة المستحقات
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(AppSizes.paddingSM),
              itemCount: 10,
              itemBuilder: (context, index) {
                final amount = (index + 1) * 800.0;
                final days = index * 7;
                return Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: AppColors.warning.withOpacity(0.1),
                      child: const Icon(
                        Icons.local_shipping,
                        color: AppColors.warning,
                      ),
                    ),
                    title: Text('مورد ${index + 1}'),
                    subtitle: Text('منذ $days يوم'),
                    trailing: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          '${amount.toStringAsFixed(0)} ر.س',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: AppColors.warning,
                          ),
                        ),
                        const Text(
                          'مستحق',
                          style: TextStyle(fontSize: 12),
                        ),
                      ],
                    ),
                    onTap: () {
                      // عرض التفاصيل
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
