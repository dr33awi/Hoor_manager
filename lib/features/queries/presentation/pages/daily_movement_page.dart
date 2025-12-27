import 'package:flutter/material.dart';
import '../../../../app/theme/app_theme.dart';
import '../../../../shared/widgets/common_widgets.dart';

/// صفحة الحركة اليومية
class DailyMovementPage extends StatefulWidget {
  const DailyMovementPage({super.key});

  @override
  State<DailyMovementPage> createState() => _DailyMovementPageState();
}

class _DailyMovementPageState extends State<DailyMovementPage> {
  DateTime _selectedDate = DateTime.now();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('الحركة اليومية'),
        actions: [
          IconButton(
            icon: const Icon(Icons.calendar_today),
            onPressed: _selectDate,
          ),
          IconButton(
            icon: const Icon(Icons.print),
            onPressed: () {},
          ),
        ],
      ),
      body: Column(
        children: [
          // التاريخ المحدد
          Container(
            padding: const EdgeInsets.all(AppSizes.paddingMD),
            color: AppColors.surfaceVariant,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  icon: const Icon(Icons.chevron_right),
                  onPressed: () {
                    setState(() {
                      _selectedDate =
                          _selectedDate.add(const Duration(days: 1));
                    });
                  },
                ),
                Text(
                  _selectedDate.toString().substring(0, 10),
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.chevron_left),
                  onPressed: () {
                    setState(() {
                      _selectedDate =
                          _selectedDate.subtract(const Duration(days: 1));
                    });
                  },
                ),
              ],
            ),
          ),

          // ملخص اليوم
          Padding(
            padding: const EdgeInsets.all(AppSizes.paddingMD),
            child: Row(
              children: [
                Expanded(
                  child: _SummaryCard(
                    title: 'المبيعات',
                    value: '5,000',
                    color: AppColors.success,
                    icon: Icons.arrow_upward,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _SummaryCard(
                    title: 'المشتريات',
                    value: '2,000',
                    color: AppColors.warning,
                    icon: Icons.arrow_downward,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _SummaryCard(
                    title: 'التحصيلات',
                    value: '3,000',
                    color: AppColors.info,
                    icon: Icons.attach_money,
                  ),
                ),
              ],
            ),
          ),

          // قائمة الحركات
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(AppSizes.paddingSM),
              itemCount: 10,
              itemBuilder: (context, index) {
                final types = ['مبيعات', 'مشتريات', 'سند قبض', 'سند صرف'];
                final type = types[index % 4];
                final isIncome = type == 'مبيعات' || type == 'سند قبض';

                return Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: isIncome
                          ? AppColors.success.withOpacity(0.1)
                          : AppColors.warning.withOpacity(0.1),
                      child: Icon(
                        isIncome ? Icons.arrow_upward : Icons.arrow_downward,
                        color: isIncome ? AppColors.success : AppColors.warning,
                      ),
                    ),
                    title: Text(type),
                    subtitle: Text('رقم العملية: ${1000 + index}'),
                    trailing: Text(
                      '${(index + 1) * 500} ر.س',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: isIncome ? AppColors.success : AppColors.warning,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _selectDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (date != null) {
      setState(() => _selectedDate = date);
    }
  }
}

class _SummaryCard extends StatelessWidget {
  final String title;
  final String value;
  final Color color;
  final IconData icon;

  const _SummaryCard({
    required this.title,
    required this.value,
    required this.color,
    required this.icon,
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
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            title,
            style: const TextStyle(fontSize: 10),
          ),
        ],
      ),
    );
  }
}
