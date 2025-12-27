import 'package:flutter/material.dart';
import '../../../../app/theme/app_theme.dart';
import '../../../../shared/widgets/common_widgets.dart';

/// صفحة العملاء
class CustomersPage extends StatelessWidget {
  const CustomersPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('الزبائن'),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {},
          ),
        ],
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(AppSizes.paddingSM),
        itemCount: 20,
        itemBuilder: (context, index) {
          final balance = index * 100.0;
          return Card(
            margin: const EdgeInsets.only(bottom: 8),
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: AppColors.success.withOpacity(0.1),
                child: Text('${index + 1}'),
              ),
              title: Text('عميل ${index + 1}'),
              subtitle: Text('0500000000$index'),
              trailing: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '${balance.toStringAsFixed(0)} ر.س',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: balance > 0 ? AppColors.error : AppColors.success,
                    ),
                  ),
                  Text(
                    balance > 0 ? 'مدين' : 'سدد',
                    style: const TextStyle(fontSize: 12),
                  ),
                ],
              ),
              onTap: () {
                // عرض تفاصيل العميل
              },
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          _showCustomerDialog(context);
        },
        icon: const Icon(Icons.person_add),
        label: const Text('عميل جديد'),
      ),
    );
  }

  void _showCustomerDialog(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: Container(
          padding: const EdgeInsets.all(AppSizes.paddingMD),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'عميل جديد',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              const TextField(
                decoration: InputDecoration(
                  labelText: 'اسم العميل *',
                  prefixIcon: Icon(Icons.person),
                ),
              ),
              const SizedBox(height: 12),
              const TextField(
                decoration: InputDecoration(
                  labelText: 'رقم الجوال',
                  prefixIcon: Icon(Icons.phone),
                ),
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 12),
              const TextField(
                decoration: InputDecoration(
                  labelText: 'العنوان',
                  prefixIcon: Icon(Icons.location_on),
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  showSnackBar(context, 'تم إضافة العميل');
                },
                child: const Text('حفظ'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
