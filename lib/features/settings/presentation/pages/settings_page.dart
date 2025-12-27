import 'package:flutter/material.dart';
import '../../../../app/theme/app_theme.dart';
import '../../../../app/routes/app_router.dart';
import '../../../../shared/widgets/common_widgets.dart';

/// صفحة الإعدادات
class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('الإعدادات'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppSizes.paddingSM),
        children: [
          // إعدادات التطبيق
          _SettingsSection(
            title: 'التطبيق',
            items: [
              _SettingsItem(
                icon: Icons.print,
                title: 'إعدادات الطباعة',
                onTap: () {
                  Navigator.pushNamed(context, AppRoutes.printSettings);
                },
              ),
              _SettingsItem(
                icon: Icons.language,
                title: 'اللغة',
                subtitle: 'العربية',
                onTap: () {},
              ),
              _SettingsItem(
                icon: Icons.dark_mode,
                title: 'المظهر',
                subtitle: 'فاتح',
                onTap: () {},
              ),
            ],
          ),

          // إعدادات المتجر
          _SettingsSection(
            title: 'المتجر',
            items: [
              _SettingsItem(
                icon: Icons.store,
                title: 'بيانات المتجر',
                onTap: () {},
              ),
              _SettingsItem(
                icon: Icons.receipt_long,
                title: 'إعدادات الفواتير',
                onTap: () {},
              ),
              _SettingsItem(
                icon: Icons.percent,
                title: 'إعدادات الضريبة',
                subtitle: '15%',
                onTap: () {},
              ),
            ],
          ),

          // البيانات
          _SettingsSection(
            title: 'البيانات',
            items: [
              _SettingsItem(
                icon: Icons.backup,
                title: 'النسخ الاحتياطي',
                onTap: () {},
              ),
              _SettingsItem(
                icon: Icons.restore,
                title: 'استعادة البيانات',
                onTap: () {},
              ),
              _SettingsItem(
                icon: Icons.cloud_sync,
                title: 'المزامنة',
                subtitle: 'آخر مزامنة: منذ 5 دقائق',
                onTap: () {},
              ),
            ],
          ),

          // حول
          _SettingsSection(
            title: 'حول',
            items: [
              _SettingsItem(
                icon: Icons.info,
                title: 'عن التطبيق',
                subtitle: 'الإصدار 1.0.0',
                onTap: () {},
              ),
              _SettingsItem(
                icon: Icons.help,
                title: 'المساعدة',
                onTap: () {},
              ),
              _SettingsItem(
                icon: Icons.privacy_tip,
                title: 'سياسة الخصوصية',
                onTap: () {},
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SettingsSection extends StatelessWidget {
  final String title;
  final List<_SettingsItem> items;

  const _SettingsSection({
    required this.title,
    required this.items,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSizes.paddingSM,
            vertical: AppSizes.paddingSM,
          ),
          child: Text(
            title,
            style: const TextStyle(
              color: AppColors.primary,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        Card(
          child: Column(
            children: items
                .map((item) => Column(
                      children: [
                        item,
                        if (items.indexOf(item) < items.length - 1)
                          const Divider(height: 1),
                      ],
                    ))
                .toList(),
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }
}

class _SettingsItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final VoidCallback onTap;

  const _SettingsItem({
    required this.icon,
    required this.title,
    this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: AppColors.primary),
      title: Text(title),
      subtitle: subtitle != null ? Text(subtitle!) : null,
      trailing: const Icon(Icons.chevron_left),
      onTap: onTap,
    );
  }
}
