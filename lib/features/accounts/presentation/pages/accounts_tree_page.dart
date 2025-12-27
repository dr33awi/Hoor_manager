import 'package:flutter/material.dart';
import '../../../../app/theme/app_theme.dart';
import '../../../../shared/widgets/common_widgets.dart';

/// صفحة شجرة الحسابات
class AccountsTreePage extends StatelessWidget {
  const AccountsTreePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('شجرة الحسابات'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppSizes.paddingSM),
        children: [
          _AccountTreeItem(
            title: 'الأصول',
            children: [
              _AccountTreeItem(title: 'الصناديق', value: '15,000'),
              _AccountTreeItem(title: 'البنوك', value: '10,000'),
              _AccountTreeItem(title: 'المدينون', value: '5,000'),
            ],
          ),
          _AccountTreeItem(
            title: 'الخصوم',
            children: [
              _AccountTreeItem(title: 'الدائنون', value: '3,000'),
            ],
          ),
          _AccountTreeItem(
            title: 'الإيرادات',
            children: [
              _AccountTreeItem(title: 'المبيعات', value: '50,000'),
            ],
          ),
          _AccountTreeItem(
            title: 'المصروفات',
            children: [
              _AccountTreeItem(title: 'المشتريات', value: '30,000'),
              _AccountTreeItem(title: 'مصاريف عامة', value: '2,000'),
            ],
          ),
        ],
      ),
    );
  }
}

class _AccountTreeItem extends StatelessWidget {
  final String title;
  final String? value;
  final List<_AccountTreeItem>? children;

  const _AccountTreeItem({
    required this.title,
    this.value,
    this.children,
  });

  @override
  Widget build(BuildContext context) {
    if (children != null && children!.isNotEmpty) {
      return ExpansionTile(
        title: Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.w500),
        ),
        children: children!,
      );
    }

    return ListTile(
      title: Text(title),
      trailing: value != null
          ? Text(
              '$value ر.س',
              style: const TextStyle(fontWeight: FontWeight.w500),
            )
          : null,
      contentPadding: const EdgeInsets.only(right: 32),
    );
  }
}
