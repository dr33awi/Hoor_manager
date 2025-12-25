import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/constants.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../products/domain/entities/entities.dart';
import '../../../products/presentation/providers/product_providers.dart';

/// شاشة الإعدادات
class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.menu),
          onPressed: () => Scaffold.of(context).openDrawer(),
          tooltip: 'القائمة',
        ),
        title: const Text(AppStrings.settings),
      ),
      body: ListView(
        children: [
          // معلومات المستخدم
          Container(
            padding: const EdgeInsets.all(AppSizes.lg),
            color: AppColors.primary,
            child: Row(
              children: [
                CircleAvatar(
                  radius: 30,
                  backgroundColor: AppColors.secondary,
                  child: Text(
                    user?.fullName.isNotEmpty == true
                        ? user!.fullName[0].toUpperCase()
                        : '؟',
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                  ),
                ),
                const SizedBox(width: AppSizes.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        user?.fullName ?? 'مستخدم',
                        style:
                            Theme.of(context).textTheme.titleMedium?.copyWith(
                                  color: AppColors.textLight,
                                  fontWeight: FontWeight.bold,
                                ),
                      ),
                      Text(
                        user?.email ?? '',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppColors.textLight.withOpacity(0.8),
                            ),
                      ),
                      Container(
                        margin: const EdgeInsets.only(top: AppSizes.xs),
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSizes.sm,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.secondary,
                          borderRadius:
                              BorderRadius.circular(AppSizes.radiusSm),
                        ),
                        child: Text(
                          user?.role.arabicName ?? '',
                          style: const TextStyle(
                            fontSize: 10,
                            color: AppColors.primary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: AppSizes.md),

          // إدارة المستخدمين (للمدير والمؤسس فقط)
          if (user?.canManageUsers == true)
            _SettingsTile(
              icon: Icons.people_outline,
              title: 'إدارة المستخدمين',
              subtitle: 'الموافقة على المستخدمين الجدد',
              onTap: () => context.push('/users'),
            ),

          // إدارة الفئات
          if (user?.canManageProducts == true)
            _SettingsTile(
              icon: Icons.category_outlined,
              title: 'إدارة الفئات',
              subtitle: 'إضافة وتعديل فئات المنتجات',
              onTap: () => _showCategoriesSheet(context, ref),
            ),

          const Divider(),

          // حول التطبيق
          _SettingsHeader(title: 'حول'),

          _SettingsTile(
            icon: Icons.info_outline,
            title: 'حول التطبيق',
            subtitle: 'الإصدار 1.0.0',
            onTap: () => _showAboutDialog(context),
          ),

          const Divider(),

          // تسجيل الخروج
          _SettingsTile(
            icon: Icons.logout,
            title: 'تسجيل الخروج',
            titleColor: AppColors.error,
            onTap: () => _confirmLogout(context, ref),
          ),

          const SizedBox(height: AppSizes.xl),
        ],
      ),
    );
  }

  void _showCategoriesSheet(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => const CategoriesManagementSheet(),
    );
  }

  void _showAboutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(AppSizes.sm),
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(AppSizes.radiusSm),
              ),
              child: const Icon(
                Icons.storefront,
                color: AppColors.secondary,
              ),
            ),
            const SizedBox(width: AppSizes.md),
            const Text('Hoor Manager'),
          ],
        ),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('تطبيق إدارة متجر Hoor للأحذية النسائية والولادية'),
            SizedBox(height: AppSizes.md),
            Text('الإصدار: 1.0.0'),
            Text('تاريخ البناء: 2026'),
            SizedBox(height: AppSizes.md),
            Text(
              'تم التطوير بواسطة Mohammad Al Masri',
              style: TextStyle(color: AppColors.textSecondary),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إغلاق'),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmLogout(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('تسجيل الخروج'),
        content: const Text('هل أنت متأكد من تسجيل الخروج؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text(AppStrings.cancel),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
            ),
            child: const Text('تسجيل الخروج'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await ref.read(authNotifierProvider.notifier).signOut();
      if (context.mounted) {
        context.go('/login');
      }
    }
  }
}

/// عنوان قسم الإعدادات
class _SettingsHeader extends StatelessWidget {
  final String title;

  const _SettingsHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSizes.md,
        AppSizes.md,
        AppSizes.md,
        AppSizes.xs,
      ),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleSmall?.copyWith(
              color: AppColors.primary,
              fontWeight: FontWeight.bold,
            ),
      ),
    );
  }
}

/// عنصر إعداد
class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final Widget? trailing;
  final Color? titleColor;
  final VoidCallback? onTap;

  const _SettingsTile({
    required this.icon,
    required this.title,
    this.subtitle,
    this.trailing,
    this.titleColor,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: titleColor ?? AppColors.primary),
      title: Text(
        title,
        style: TextStyle(color: titleColor),
      ),
      subtitle: subtitle != null ? Text(subtitle!) : null,
      trailing: trailing ?? const Icon(Icons.chevron_left),
      onTap: onTap,
    );
  }
}

/// شيت إدارة الفئات
class CategoriesManagementSheet extends ConsumerStatefulWidget {
  const CategoriesManagementSheet({super.key});

  @override
  ConsumerState<CategoriesManagementSheet> createState() =>
      _CategoriesManagementSheetState();
}

class _CategoriesManagementSheetState
    extends ConsumerState<CategoriesManagementSheet> {
  @override
  Widget build(BuildContext context) {
    // استخدام StreamProvider للتحديث التلقائي
    final categoriesAsync = ref.watch(categoriesStreamProvider);

    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) {
        return Column(
          children: [
            Container(
              padding: const EdgeInsets.all(AppSizes.md),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'إدارة الفئات',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  IconButton(
                    icon: const Icon(Icons.add),
                    onPressed: () => _showAddCategoryDialog(context),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: categoriesAsync.when(
                data: (categories) {
                  if (categories.isEmpty) {
                    return const Center(
                      child: Text('لا توجد فئات'),
                    );
                  }
                  return ReorderableListView.builder(
                    scrollController: scrollController,
                    itemCount: categories.length,
                    onReorder: (oldIndex, newIndex) {
                      // إعادة ترتيب الفئات
                    },
                    itemBuilder: (context, index) {
                      final category = categories[index];
                      return ListTile(
                        key: ValueKey(category.id),
                        leading: const Icon(Icons.drag_handle),
                        title: Text(category.name),
                        subtitle: category.description != null
                            ? Text(category.description!)
                            : null,
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit),
                              onPressed: () =>
                                  _showEditCategoryDialog(context, category),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete,
                                  color: AppColors.error),
                              onPressed: () =>
                                  _showDeleteCategoryDialog(context, category),
                            ),
                          ],
                        ),
                      );
                    },
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, _) => Center(child: Text('خطأ: $e')),
              ),
            ),
          ],
        );
      },
    );
  }

  void _showAddCategoryDialog(BuildContext context) {
    final nameController = TextEditingController();
    final descriptionController = TextEditingController();
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('إضافة فئة'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: 'اسم الفئة',
              ),
              autofocus: true,
            ),
            const SizedBox(height: AppSizes.md),
            TextField(
              controller: descriptionController,
              decoration: const InputDecoration(
                labelText: 'الوصف (اختياري)',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text(AppStrings.cancel),
          ),
          ElevatedButton(
            onPressed: () async {
              final name = nameController.text.trim();
              if (name.isEmpty) {
                scaffoldMessenger.showSnackBar(
                  const SnackBar(content: Text('الرجاء إدخال اسم الفئة')),
                );
                return;
              }

              final category = CategoryEntity(
                id: '', // سيتم إنشاؤه في الـ repository
                name: name,
                description: descriptionController.text.trim().isEmpty
                    ? null
                    : descriptionController.text.trim(),
                createdAt: DateTime.now(),
              );

              Navigator.pop(dialogContext);

              final success = await ref
                  .read(categoryActionsProvider.notifier)
                  .addCategory(category);

              if (success) {
                scaffoldMessenger.showSnackBar(
                  const SnackBar(content: Text('تمت إضافة الفئة بنجاح')),
                );
              }
            },
            child: const Text('إضافة'),
          ),
        ],
      ),
    );
  }

  void _showEditCategoryDialog(BuildContext context, CategoryEntity category) {
    final nameController = TextEditingController(text: category.name);
    final descriptionController =
        TextEditingController(text: category.description ?? '');
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('تعديل الفئة'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: 'اسم الفئة',
              ),
              autofocus: true,
            ),
            const SizedBox(height: AppSizes.md),
            TextField(
              controller: descriptionController,
              decoration: const InputDecoration(
                labelText: 'الوصف (اختياري)',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text(AppStrings.cancel),
          ),
          ElevatedButton(
            onPressed: () async {
              final name = nameController.text.trim();
              if (name.isEmpty) {
                scaffoldMessenger.showSnackBar(
                  const SnackBar(content: Text('الرجاء إدخال اسم الفئة')),
                );
                return;
              }

              final updatedCategory = category.copyWith(
                name: name,
                description: descriptionController.text.trim().isEmpty
                    ? null
                    : descriptionController.text.trim(),
              );

              Navigator.pop(dialogContext);

              final success = await ref
                  .read(categoryActionsProvider.notifier)
                  .updateCategory(updatedCategory);

              if (success) {
                scaffoldMessenger.showSnackBar(
                  const SnackBar(content: Text('تم تعديل الفئة بنجاح')),
                );
              }
            },
            child: const Text('حفظ'),
          ),
        ],
      ),
    );
  }

  void _showDeleteCategoryDialog(
      BuildContext context, CategoryEntity category) {
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('حذف الفئة'),
        content: Text('هل أنت متأكد من حذف فئة "${category.name}"؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text(AppStrings.cancel),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
            ),
            onPressed: () async {
              Navigator.pop(dialogContext);

              final success = await ref
                  .read(categoryActionsProvider.notifier)
                  .deleteCategory(category.id);

              if (success) {
                scaffoldMessenger.showSnackBar(
                  const SnackBar(content: Text('تم حذف الفئة بنجاح')),
                );
              }
            },
            child: const Text('حذف'),
          ),
        ],
      ),
    );
  }
}
