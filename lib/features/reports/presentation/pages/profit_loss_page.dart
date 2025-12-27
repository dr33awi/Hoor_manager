import 'package:flutter/material.dart';
import '../../../../app/theme/app_theme.dart';
import '../../../../shared/widgets/common_widgets.dart';

/// صفحة الأرباح والخسائر
class ProfitLossPage extends StatefulWidget {
  const ProfitLossPage({super.key});

  @override
  State<ProfitLossPage> createState() => _ProfitLossPageState();
}

class _ProfitLossPageState extends State<ProfitLossPage> {
  String _period = 'month';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('الأرباح والخسائر'),
        actions: [
          IconButton(
            icon: const Icon(Icons.print),
            onPressed: () {},
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSizes.paddingMD),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // اختيار الفترة
            SegmentedButton<String>(
              segments: const [
                ButtonSegment(value: 'week', label: Text('أسبوع')),
                ButtonSegment(value: 'month', label: Text('شهر')),
                ButtonSegment(value: 'year', label: Text('سنة')),
              ],
              selected: {_period},
              onSelectionChanged: (value) {
                setState(() => _period = value.first);
              },
            ),
            const SizedBox(height: 24),

            // صافي الربح
            Card(
              color: AppColors.success,
              child: Padding(
                padding: const EdgeInsets.all(AppSizes.paddingLG),
                child: Column(
                  children: [
                    const Icon(Icons.trending_up,
                        color: Colors.white, size: 40),
                    const SizedBox(height: 8),
                    const Text(
                      'صافي الربح',
                      style: TextStyle(color: Colors.white70, fontSize: 16),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      '12,500.00 ر.س',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // الإيرادات
            Card(
              child: Padding(
                padding: const EdgeInsets.all(AppSizes.paddingMD),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'الإيرادات',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.success,
                      ),
                    ),
                    const Divider(),
                    _buildRow('إجمالي المبيعات', '50,000 ر.س'),
                    _buildRow('مرتجعات المبيعات', '(-) 2,000 ر.س'),
                    _buildRow('صافي المبيعات', '48,000 ر.س', isBold: true),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // التكاليف
            Card(
              child: Padding(
                padding: const EdgeInsets.all(AppSizes.paddingMD),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'التكاليف',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.warning,
                      ),
                    ),
                    const Divider(),
                    _buildRow('تكلفة المبيعات', '30,000 ر.س'),
                    _buildRow('مرتجعات المشتريات', '(-) 1,000 ر.س'),
                    _buildRow('صافي التكاليف', '29,000 ر.س', isBold: true),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // المصروفات
            Card(
              child: Padding(
                padding: const EdgeInsets.all(AppSizes.paddingMD),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'المصروفات',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.error,
                      ),
                    ),
                    const Divider(),
                    _buildRow('مصاريف تشغيلية', '5,000 ر.س'),
                    _buildRow('مصاريف إدارية', '1,500 ر.س'),
                    _buildRow('إجمالي المصروفات', '6,500 ر.س', isBold: true),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRow(String label, String value, {bool isBold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Text(
            value,
            style: TextStyle(
              fontWeight: isBold ? FontWeight.bold : FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
