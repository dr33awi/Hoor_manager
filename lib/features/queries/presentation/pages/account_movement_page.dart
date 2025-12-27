import 'package:flutter/material.dart';
import '../../../../app/theme/app_theme.dart';
import '../../../../shared/widgets/common_widgets.dart';

/// صفحة حركة الحساب
class AccountMovementPage extends StatefulWidget {
  const AccountMovementPage({super.key});

  @override
  State<AccountMovementPage> createState() => _AccountMovementPageState();
}

class _AccountMovementPageState extends State<AccountMovementPage> {
  int? _selectedAccountId;
  String _selectedAccountName = '';
  DateTime _startDate = DateTime.now().subtract(const Duration(days: 30));
  DateTime _endDate = DateTime.now();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('حركة الحساب'),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: _showFilterDialog,
          ),
          IconButton(
            icon: const Icon(Icons.print),
            onPressed: () {},
          ),
        ],
      ),
      body: Column(
        children: [
          // اختيار الحساب
          InkWell(
            onTap: _selectAccount,
            child: Container(
              padding: const EdgeInsets.all(AppSizes.paddingMD),
              decoration: BoxDecoration(
                color: AppColors.surfaceVariant,
                border: Border(
                  bottom: BorderSide(color: Colors.grey.shade300),
                ),
              ),
              child: Row(
                children: [
                  const Icon(Icons.person),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      _selectedAccountName.isEmpty
                          ? 'اختر الحساب'
                          : _selectedAccountName,
                      style: TextStyle(
                        color: _selectedAccountName.isEmpty
                            ? AppColors.textSecondary
                            : AppColors.textPrimary,
                      ),
                    ),
                  ),
                  const Icon(Icons.arrow_drop_down),
                ],
              ),
            ),
          ),

          // الفترة
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSizes.paddingMD,
              vertical: AppSizes.paddingSM,
            ),
            color: Colors.grey.shade100,
            child: Row(
              children: [
                Text(
                  'من ${_startDate.toString().substring(0, 10)}',
                  style: const TextStyle(fontSize: 12),
                ),
                const Text(' - '),
                Text(
                  'إلى ${_endDate.toString().substring(0, 10)}',
                  style: const TextStyle(fontSize: 12),
                ),
              ],
            ),
          ),

          // قائمة الحركات
          if (_selectedAccountId != null)
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.all(AppSizes.paddingSM),
                itemCount: 15,
                itemBuilder: (context, index) {
                  final isDebit = index % 2 == 0;
                  return Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: isDebit
                            ? AppColors.error.withOpacity(0.1)
                            : AppColors.success.withOpacity(0.1),
                        child: Icon(
                          isDebit ? Icons.arrow_upward : Icons.arrow_downward,
                          color: isDebit ? AppColors.error : AppColors.success,
                        ),
                      ),
                      title: Text(isDebit ? 'فاتورة مبيعات' : 'سند قبض'),
                      subtitle: Text(
                          '${DateTime.now().subtract(Duration(days: index)).toString().substring(0, 10)}'),
                      trailing: Text(
                        '${isDebit ? '+' : '-'}${(index + 1) * 100} ر.س',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: isDebit ? AppColors.error : AppColors.success,
                        ),
                      ),
                    ),
                  );
                },
              ),
            )
          else
            const Expanded(
              child: Center(
                child: Text('اختر الحساب لعرض الحركات'),
              ),
            ),
        ],
      ),
    );
  }

  void _selectAccount() {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(AppSizes.paddingMD),
        child: Column(
          children: [
            const Text(
              'اختر الحساب',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: ListView.builder(
                itemCount: 10,
                itemBuilder: (context, index) {
                  return ListTile(
                    title: Text('عميل ${index + 1}'),
                    subtitle: Text('الرصيد: ${index * 100} ر.س'),
                    onTap: () {
                      setState(() {
                        _selectedAccountId = index + 1;
                        _selectedAccountName = 'عميل ${index + 1}';
                      });
                      Navigator.pop(context);
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showFilterDialog() {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(AppSizes.paddingMD),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'تصفية الحركات',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            ListTile(
              title: const Text('اليوم'),
              onTap: () => Navigator.pop(context),
            ),
            ListTile(
              title: const Text('هذا الأسبوع'),
              onTap: () => Navigator.pop(context),
            ),
            ListTile(
              title: const Text('هذا الشهر'),
              onTap: () => Navigator.pop(context),
            ),
            ListTile(
              title: const Text('تحديد فترة'),
              onTap: () => Navigator.pop(context),
            ),
          ],
        ),
      ),
    );
  }
}
