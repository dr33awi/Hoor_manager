import 'package:flutter/material.dart';
import '../../../../app/theme/app_theme.dart';
import '../../../../shared/widgets/common_widgets.dart';

/// صفحة ملخص الحركة
class MovementSummaryPage extends StatefulWidget {
  const MovementSummaryPage({super.key});

  @override
  State<MovementSummaryPage> createState() => _MovementSummaryPageState();
}

class _MovementSummaryPageState extends State<MovementSummaryPage> {
  String _period = 'today';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('ملخص الحركة'),
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
                ButtonSegment(value: 'today', label: Text('اليوم')),
                ButtonSegment(value: 'week', label: Text('الأسبوع')),
                ButtonSegment(value: 'month', label: Text('الشهر')),
              ],
              selected: {_period},
              onSelectionChanged: (value) {
                setState(() => _period = value.first);
              },
            ),
            const SizedBox(height: 24),

            // ملخص المبيعات
            _SummarySection(
              title: 'المبيعات',
              icon: Icons.trending_up,
              color: AppColors.success,
              items: [
                _SummaryItem('عدد الفواتير', '25'),
                _SummaryItem('إجمالي المبيعات', '15,000 ر.س'),
                _SummaryItem('مبيعات نقدية', '10,000 ر.س'),
                _SummaryItem('مبيعات آجلة', '5,000 ر.س'),
              ],
            ),
            const SizedBox(height: 16),

            // ملخص المشتريات
            _SummarySection(
              title: 'المشتريات',
              icon: Icons.shopping_cart,
              color: AppColors.warning,
              items: [
                _SummaryItem('عدد الفواتير', '8'),
                _SummaryItem('إجمالي المشتريات', '7,000 ر.س'),
              ],
            ),
            const SizedBox(height: 16),

            // ملخص التحصيلات
            _SummarySection(
              title: 'التحصيلات',
              icon: Icons.attach_money,
              color: AppColors.info,
              items: [
                _SummaryItem('سندات القبض', '3,000 ر.س'),
                _SummaryItem('سندات الصرف', '1,500 ر.س'),
              ],
            ),
            const SizedBox(height: 16),

            // الرصيد
            Card(
              color: AppColors.primary,
              child: Padding(
                padding: const EdgeInsets.all(AppSizes.paddingMD),
                child: Column(
                  children: [
                    const Text(
                      'صافي الحركة',
                      style: TextStyle(color: Colors.white70),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      '9,500.00 ر.س',
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
          ],
        ),
      ),
    );
  }
}

class _SummarySection extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color color;
  final List<_SummaryItem> items;

  const _SummarySection({
    required this.title,
    required this.icon,
    required this.color,
    required this.items,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSizes.paddingMD),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: color),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
              ],
            ),
            const Divider(),
            ...items.map((item) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(item.label),
                      Text(
                        item.value,
                        style: const TextStyle(fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),
                )),
          ],
        ),
      ),
    );
  }
}

class _SummaryItem {
  final String label;
  final String value;

  _SummaryItem(this.label, this.value);
}
