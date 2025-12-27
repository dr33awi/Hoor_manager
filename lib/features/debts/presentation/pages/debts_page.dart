import 'package:flutter/material.dart';
import '../../../../app/theme/app_theme.dart';
import '../../../../shared/widgets/common_widgets.dart';

/// صفحة الديون (المستحقات على العملاء)
class DebtsPage extends StatelessWidget {
  const DebtsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('الديون'),
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
            color: AppColors.error.withOpacity(0.1),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'إجمالي المستحقات',
                  style: TextStyle(fontWeight: FontWeight.w500),
                ),
                Text(
                  '15,000.00 ر.س',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.error,
                  ),
                ),
              ],
            ),
          ),

          // قائمة الديون
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(AppSizes.paddingSM),
              itemCount: 15,
              itemBuilder: (context, index) {
                final debt = (index + 1) * 1000.0;
                final days = index * 5;
                return Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: days > 30
                          ? AppColors.error.withOpacity(0.1)
                          : AppColors.warning.withOpacity(0.1),
                      child: Icon(
                        Icons.person,
                        color: days > 30 ? AppColors.error : AppColors.warning,
                      ),
                    ),
                    title: Text('عميل ${index + 1}'),
                    subtitle: Text('متأخر $days يوم'),
                    trailing: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          '${debt.toStringAsFixed(0)} ر.س',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color:
                                days > 30 ? AppColors.error : AppColors.warning,
                          ),
                        ),
                        Text(
                          days > 30 ? 'متأخر' : 'مستحق',
                          style: const TextStyle(fontSize: 12),
                        ),
                      ],
                    ),
                    onTap: () {
                      // عرض تفاصيل الدين
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
