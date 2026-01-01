import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/redesign/design_system.dart';
import '../../../../core/di/injection.dart';
import '../../../../data/database/app_database.dart';
import '../../../../data/repositories/category_repository.dart';

/// ═══════════════════════════════════════════════════════════════════════════
/// Categories Screen - Modern Redesign
/// Professional Category Management Interface
/// ═══════════════════════════════════════════════════════════════════════════

class CategoriesScreenRedesign extends ConsumerStatefulWidget {
  const CategoriesScreenRedesign({super.key});

  @override
  ConsumerState<CategoriesScreenRedesign> createState() =>
      _CategoriesScreenRedesignState();
}

class _CategoriesScreenRedesignState
    extends ConsumerState<CategoriesScreenRedesign> {
  final _categoryRepo = getIt<CategoryRepository>();
  final _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: HoorColors.background,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(context),
            _buildSearchBar(),
            _buildStats(),
            Expanded(child: _buildCategoriesList()),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddCategorySheet,
        backgroundColor: HoorColors.primary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_rounded),
        label: const Text('فئة جديدة'),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(HoorSpacing.lg.w),
      child: Row(
        children: [
          _IconButton(
            icon: Icons.arrow_forward_ios_rounded,
            onTap: () => context.pop(),
          ),
          SizedBox(width: HoorSpacing.md.w),
          Expanded(
            child: Text(
              'الفئات',
              style: HoorTypography.headlineSmall.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: HoorSpacing.lg.w),
      child: HoorSearchBar(
        controller: _searchController,
        hint: 'بحث في الفئات...',
        onChanged: (value) => setState(() => _searchQuery = value),
      ),
    );
  }

  Widget _buildStats() {
    return StreamBuilder<List<Category>>(
      stream: _categoryRepo.watchAllCategories(),
      builder: (context, snapshot) {
        final categories = snapshot.data ?? [];

        return Container(
          margin: EdgeInsets.all(HoorSpacing.lg.w),
          padding: EdgeInsets.all(HoorSpacing.lg.w),
          decoration: BoxDecoration(
            color: HoorColors.surface,
            borderRadius: BorderRadius.circular(HoorRadius.lg),
            border: Border.all(color: HoorColors.border.withValues(alpha: 0.5)),
          ),
          child: Row(
            children: [
              Container(
                padding: EdgeInsets.all(HoorSpacing.md.w),
                decoration: BoxDecoration(
                  color: HoorColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(HoorRadius.md),
                ),
                child: Icon(
                  Icons.category_rounded,
                  color: HoorColors.primary,
                  size: HoorIconSize.lg,
                ),
              ),
              SizedBox(width: HoorSpacing.md.w),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'إجمالي الفئات',
                    style: HoorTypography.labelMedium.copyWith(
                      color: HoorColors.textSecondary,
                    ),
                  ),
                  Text(
                    '${categories.length}',
                    style: HoorTypography.headlineSmall.copyWith(
                      fontWeight: FontWeight.bold,
                      color: HoorColors.primary,
                    ),
                  ),
                ],
              ),
              const Spacer(),
              TextButton.icon(
                onPressed: _showAddCategorySheet,
                icon: Icon(Icons.add_rounded, size: HoorIconSize.sm),
                label: const Text('إضافة'),
                style: TextButton.styleFrom(
                  foregroundColor: HoorColors.primary,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildCategoriesList() {
    return StreamBuilder<List<Category>>(
      stream: _categoryRepo.watchAllCategories(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: HoorLoading());
        }

        var categories = snapshot.data ?? [];

        // Apply search filter
        if (_searchQuery.isNotEmpty) {
          categories = categories
              .where((c) =>
                  c.name.toLowerCase().contains(_searchQuery.toLowerCase()))
              .toList();
        }

        if (categories.isEmpty) {
          if (_searchQuery.isNotEmpty) {
            return HoorEmptyState(
              icon: Icons.search_off_rounded,
              title: 'لا توجد نتائج',
              message: 'جرب البحث بكلمات أخرى',
            );
          }
          return HoorEmptyState(
            icon: Icons.category_outlined,
            title: 'لا توجد فئات',
            message: 'أضف فئة جديدة لتنظيم منتجاتك',
          );
        }

        return ListView.separated(
          padding: EdgeInsets.symmetric(horizontal: HoorSpacing.lg.w),
          itemCount: categories.length,
          separatorBuilder: (_, __) => SizedBox(height: HoorSpacing.sm.h),
          itemBuilder: (context, index) {
            final category = categories[index];
            return _CategoryCard(
              category: category,
              index: index,
              onEdit: () => _showEditCategorySheet(category),
              onDelete: () => _confirmDeleteCategory(category),
            );
          },
        );
      },
    );
  }

  void _showAddCategorySheet() {
    final nameController = TextEditingController();

    HoorBottomSheet.show(
      context,
      title: 'فئة جديدة',
      showCloseButton: true,
      child: Padding(
        padding: EdgeInsets.all(HoorSpacing.lg.w),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: EdgeInsets.all(HoorSpacing.lg.w),
              decoration: BoxDecoration(
                color: HoorColors.primary.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.category_rounded,
                color: HoorColors.primary,
                size: HoorIconSize.xxl,
              ),
            ),
            SizedBox(height: HoorSpacing.lg.h),
            HoorTextField(
              controller: nameController,
              label: 'اسم الفئة',
              hint: 'أدخل اسم الفئة',
              prefixIcon: Icons.label_rounded,
              autofocus: true,
            ),
            SizedBox(height: HoorSpacing.xl.h),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => _saveCategory(nameController.text),
                style: ElevatedButton.styleFrom(
                  backgroundColor: HoorColors.primary,
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.all(HoorSpacing.md.w),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(HoorRadius.md),
                  ),
                ),
                child: const Text('حفظ الفئة'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _saveCategory(String name) async {
    if (name.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('يرجى إدخال اسم الفئة'),
          backgroundColor: HoorColors.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    try {
      await _categoryRepo.createCategory(name: name.trim());
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('تم إضافة الفئة بنجاح'),
            backgroundColor: HoorColors.success,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(HoorRadius.md),
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('خطأ: $e'),
            backgroundColor: HoorColors.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  void _showEditCategorySheet(Category category) {
    final nameController = TextEditingController(text: category.name);

    HoorBottomSheet.show(
      context,
      title: 'تعديل الفئة',
      showCloseButton: true,
      child: Padding(
        padding: EdgeInsets.all(HoorSpacing.lg.w),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: EdgeInsets.all(HoorSpacing.lg.w),
              decoration: BoxDecoration(
                color: HoorColors.info.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.edit_rounded,
                color: HoorColors.info,
                size: HoorIconSize.xxl,
              ),
            ),
            SizedBox(height: HoorSpacing.lg.h),
            HoorTextField(
              controller: nameController,
              label: 'اسم الفئة',
              hint: 'أدخل اسم الفئة',
              prefixIcon: Icons.label_rounded,
              autofocus: true,
            ),
            SizedBox(height: HoorSpacing.xl.h),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () =>
                    _updateCategory(category.id, nameController.text),
                style: ElevatedButton.styleFrom(
                  backgroundColor: HoorColors.primary,
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.all(HoorSpacing.md.w),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(HoorRadius.md),
                  ),
                ),
                child: const Text('حفظ التغييرات'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _updateCategory(String id, String name) async {
    if (name.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('يرجى إدخال اسم الفئة'),
          backgroundColor: HoorColors.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    try {
      await _categoryRepo.updateCategory(id: id, name: name.trim());
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('تم تحديث الفئة بنجاح'),
            backgroundColor: HoorColors.success,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(HoorRadius.md),
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('خطأ: $e'),
            backgroundColor: HoorColors.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  void _confirmDeleteCategory(Category category) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(HoorRadius.lg),
        ),
        title: Row(
          children: [
            Container(
              padding: EdgeInsets.all(HoorSpacing.sm.w),
              decoration: BoxDecoration(
                color: HoorColors.error.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(HoorRadius.md),
              ),
              child: Icon(
                Icons.warning_rounded,
                color: HoorColors.error,
                size: HoorIconSize.lg,
              ),
            ),
            SizedBox(width: HoorSpacing.md.w),
            const Text('حذف الفئة'),
          ],
        ),
        content: Text(
          'هل أنت متأكد من حذف فئة "${category.name}"؟',
          style: HoorTypography.bodyMedium,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _deleteCategory(category);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: HoorColors.error,
              foregroundColor: Colors.white,
            ),
            child: const Text('حذف'),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteCategory(Category category) async {
    try {
      await _categoryRepo.deleteCategory(category.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('تم حذف الفئة'),
            backgroundColor: HoorColors.success,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(HoorRadius.md),
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('خطأ: $e'),
            backgroundColor: HoorColors.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }
}

/// ═══════════════════════════════════════════════════════════════════════════
/// Supporting Widgets
/// ═══════════════════════════════════════════════════════════════════════════

class _IconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _IconButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: HoorColors.surface,
      borderRadius: BorderRadius.circular(HoorRadius.md),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(HoorRadius.md),
        child: Container(
          padding: EdgeInsets.all(HoorSpacing.sm.w),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(HoorRadius.md),
            border: Border.all(color: HoorColors.border),
          ),
          child: Icon(icon,
              size: HoorIconSize.md, color: HoorColors.textSecondary),
        ),
      ),
    );
  }
}

class _CategoryCard extends StatelessWidget {
  final Category category;
  final int index;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _CategoryCard({
    required this.category,
    required this.index,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    // Generate different colors for categories
    final colors = [
      HoorColors.primary,
      HoorColors.info,
      HoorColors.income,
      HoorColors.warning,
      HoorColors.expense,
      const Color(0xFF9C27B0),
      const Color(0xFF00BCD4),
      const Color(0xFF795548),
    ];
    final color = colors[index % colors.length];

    return Material(
      color: HoorColors.surface,
      borderRadius: BorderRadius.circular(HoorRadius.lg),
      child: InkWell(
        onTap: onEdit,
        borderRadius: BorderRadius.circular(HoorRadius.lg),
        child: Container(
          padding: EdgeInsets.all(HoorSpacing.md.w),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(HoorRadius.lg),
            border: Border.all(color: HoorColors.border.withValues(alpha: 0.5)),
          ),
          child: Row(
            children: [
              Container(
                width: 48.w,
                height: 48.w,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(HoorRadius.md),
                ),
                child: Center(
                  child: Text(
                    category.name.isNotEmpty
                        ? category.name.substring(0, 1).toUpperCase()
                        : '?',
                    style: HoorTypography.titleLarge.copyWith(
                      color: color,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              SizedBox(width: HoorSpacing.md.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      category.name,
                      style: HoorTypography.titleMedium.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    SizedBox(height: HoorSpacing.xxs.h),
                    Row(
                      children: [
                        Icon(
                          Icons.tag_rounded,
                          size: HoorIconSize.xs,
                          color: HoorColors.textTertiary,
                        ),
                        SizedBox(width: HoorSpacing.xxs.w),
                        Text(
                          'ID: ${category.id}',
                          style: HoorTypography.labelSmall.copyWith(
                            color: HoorColors.textTertiary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: onEdit,
                icon: Icon(
                  Icons.edit_rounded,
                  color: HoorColors.info,
                  size: HoorIconSize.md,
                ),
              ),
              IconButton(
                onPressed: onDelete,
                icon: Icon(
                  Icons.delete_rounded,
                  color: HoorColors.error,
                  size: HoorIconSize.md,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
