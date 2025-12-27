import 'package:flutter/material.dart';
import '../../../../app/theme/app_theme.dart';
import '../../../../shared/widgets/common_widgets.dart';

/// صفحة الصناديق والبنوك
class CashAccountsPage extends StatelessWidget {
  const CashAccountsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('الصناديق والبنوك'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppSizes.paddingSM),
        children: [
          // إجمالي الرصيد
          Card(
            color: AppColors.primary,
            child: Padding(
              padding: const EdgeInsets.all(AppSizes.paddingMD),
              child: Column(
                children: [
                  const Text(
                    'إجمالي الرصيد',
                    style: TextStyle(color: Colors.white70),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    '25,000.00 ر.س',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // قائمة الصناديق
          Card(
            child: ListTile(
              leading: const CircleAvatar(
                backgroundColor: AppColors.success,
                child: Icon(Icons.money, color: Colors.white),
              ),
              title: const Text('الصندوق الرئيسي'),
              subtitle: const Text('صندوق نقدي'),
              trailing: const Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '15,000.00 ر.س',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Text('افتراضي', style: TextStyle(fontSize: 12)),
                ],
              ),
              onTap: () {},
            ),
          ),
          const SizedBox(height: 8),
          Card(
            child: ListTile(
              leading: const CircleAvatar(
                backgroundColor: AppColors.info,
                child: Icon(Icons.account_balance, color: Colors.white),
              ),
              title: const Text('البنك الأهلي'),
              subtitle: const Text('حساب بنكي'),
              trailing: const Text(
                '10,000.00 ر.س',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              onTap: () {},
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {},
        icon: const Icon(Icons.add),
        label: const Text('صندوق جديد'),
      ),
    );
  }
}
