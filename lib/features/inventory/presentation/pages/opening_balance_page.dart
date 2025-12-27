import 'package:flutter/material.dart';
import '../../../../app/theme/app_theme.dart';
import '../../../../shared/widgets/common_widgets.dart';

/// صفحة فاتورة أول المدة
class OpeningBalancePage extends StatelessWidget {
  const OpeningBalancePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('فاتورة أول المدة'),
      ),
      body: const Center(
        child: Text('صفحة إدخال أرصدة أول المدة - قيد التطوير'),
      ),
    );
  }
}
