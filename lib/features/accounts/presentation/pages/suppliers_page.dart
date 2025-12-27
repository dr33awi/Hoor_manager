import 'package:flutter/material.dart';
import '../../../../app/theme/app_theme.dart';
import '../../../../shared/widgets/common_widgets.dart';

/// صفحة الموردين
class SuppliersPage extends StatelessWidget {
  const SuppliersPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('الموردون'),
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(AppSizes.paddingSM),
        itemCount: 15,
        itemBuilder: (context, index) {
          final balance = index * 200.0;
          return Card(
            margin: const EdgeInsets.only(bottom: 8),
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: AppColors.warning.withOpacity(0.1),
                child:
                    const Icon(Icons.local_shipping, color: AppColors.warning),
              ),
              title: Text('مورد ${index + 1}'),
              subtitle: Text('0500000000$index'),
              trailing: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '${balance.toStringAsFixed(0)} ر.س',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color:
                          balance > 0 ? AppColors.warning : AppColors.success,
                    ),
                  ),
                  Text(
                    balance > 0 ? 'له' : 'سدد',
                    style: const TextStyle(fontSize: 12),
                  ),
                ],
              ),
              onTap: () {},
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {},
        icon: const Icon(Icons.add),
        label: const Text('مورد جديد'),
      ),
    );
  }
}
