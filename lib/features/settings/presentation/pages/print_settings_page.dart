import 'package:flutter/material.dart';
import '../../../../app/theme/app_theme.dart';
import '../../../../shared/widgets/common_widgets.dart';

/// صفحة إعدادات الطباعة
class PrintSettingsPage extends StatefulWidget {
  const PrintSettingsPage({super.key});

  @override
  State<PrintSettingsPage> createState() => _PrintSettingsPageState();
}

class _PrintSettingsPageState extends State<PrintSettingsPage> {
  String _paperSize = 'A4';
  bool _showLogo = true;
  bool _showQR = true;
  int _copies = 1;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('إعدادات الطباعة'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppSizes.paddingMD),
        children: [
          // حجم الورق
          Card(
            child: Padding(
              padding: const EdgeInsets.all(AppSizes.paddingMD),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'حجم الورق',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    value: _paperSize,
                    items: const [
                      DropdownMenuItem(value: 'A4', child: Text('A4')),
                      DropdownMenuItem(value: 'A5', child: Text('A5')),
                      DropdownMenuItem(
                          value: '80mm', child: Text('80mm (حراري)')),
                      DropdownMenuItem(
                          value: '58mm', child: Text('58mm (حراري)')),
                    ],
                    onChanged: (value) {
                      setState(() => _paperSize = value!);
                    },
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // خيارات الطباعة
          Card(
            child: Column(
              children: [
                SwitchListTile(
                  title: const Text('عرض الشعار'),
                  subtitle: const Text('طباعة شعار المتجر في الفاتورة'),
                  value: _showLogo,
                  onChanged: (value) {
                    setState(() => _showLogo = value);
                  },
                ),
                const Divider(height: 1),
                SwitchListTile(
                  title: const Text('عرض رمز QR'),
                  subtitle: const Text('طباعة رمز QR للفاتورة'),
                  value: _showQR,
                  onChanged: (value) {
                    setState(() => _showQR = value);
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // عدد النسخ
          Card(
            child: Padding(
              padding: const EdgeInsets.all(AppSizes.paddingMD),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'عدد النسخ الافتراضي',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      IconButton(
                        onPressed: _copies > 1
                            ? () => setState(() => _copies--)
                            : null,
                        icon: const Icon(Icons.remove),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          '$_copies',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: () => setState(() => _copies++),
                        icon: const Icon(Icons.add),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          // طباعة تجريبية
          PrimaryButton(
            text: 'طباعة تجريبية',
            icon: Icons.print,
            isOutlined: true,
            onPressed: () {
              showSnackBar(context, 'جاري الطباعة التجريبية...');
            },
          ),
          const SizedBox(height: 8),

          // حفظ
          PrimaryButton(
            text: 'حفظ الإعدادات',
            icon: Icons.save,
            onPressed: () {
              showSnackBar(context, 'تم حفظ الإعدادات');
              Navigator.pop(context);
            },
          ),
        ],
      ),
    );
  }
}
