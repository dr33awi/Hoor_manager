// ═══════════════════════════════════════════════════════════════════════════
// Warehouses Screen Pro - Professional Design System
// Modern Warehouse Management Interface
// ═══════════════════════════════════════════════════════════════════════════

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/design_tokens.dart';
import '../../core/providers/app_providers.dart';
import '../../data/database/app_database.dart';

class WarehousesScreenPro extends ConsumerStatefulWidget {
  const WarehousesScreenPro({super.key});

  @override
  ConsumerState<WarehousesScreenPro> createState() =>
      _WarehousesScreenProState();
}

class _WarehousesScreenProState extends ConsumerState<WarehousesScreenPro> {
  final _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final warehousesAsync = ref.watch(warehousesStreamProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            _buildSearchBar(),
            Expanded(
              child: warehousesAsync.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (error, _) => _buildErrorState(error.toString()),
                data: (warehouses) {
                  final filtered = _filterWarehouses(warehouses);
                  if (filtered.isEmpty) {
                    return _buildEmptyState();
                  }
                  return _buildWarehousesList(filtered);
                },
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showWarehouseDialog(),
        backgroundColor: AppColors.secondary,
        icon: const Icon(Icons.add, color: Colors.white),
        label: Text(
          'مستودع جديد',
          style: AppTypography.labelLarge.copyWith(color: Colors.white),
        ),
      ),
    );
  }

  List<Warehouse> _filterWarehouses(List<Warehouse> warehouses) {
    if (_searchQuery.isEmpty) return warehouses;
    return warehouses.where((w) {
      return w.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          (w.code?.toLowerCase().contains(_searchQuery.toLowerCase()) ?? false);
    }).toList();
  }

  Widget _buildHeader() {
    return Container(
      padding: EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border(bottom: BorderSide(color: AppColors.border)),
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: () => context.pop(),
            icon: Icon(
              Icons.arrow_back_ios_rounded,
              color: AppColors.textSecondary,
            ),
          ),
          SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'المستودعات',
                  style: AppTypography.headlineSmall.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  'إدارة مواقع التخزين',
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.textTertiary,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () => context.push('/inventory/transfer'),
            icon: Icon(Icons.swap_horiz_rounded, color: AppColors.secondary),
            tooltip: 'نقل المخزون',
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: EdgeInsets.all(AppSpacing.md),
      child: Container(
        height: 48.h,
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(color: AppColors.border),
        ),
        child: TextField(
          controller: _searchController,
          onChanged: (value) => setState(() => _searchQuery = value),
          decoration: InputDecoration(
            hintText: 'البحث عن مستودع...',
            hintStyle: AppTypography.bodyMedium.copyWith(
              color: AppColors.textTertiary,
            ),
            prefixIcon:
                Icon(Icons.search_rounded, color: AppColors.textTertiary),
            border: InputBorder.none,
            contentPadding: EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.sm,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: EdgeInsets.all(AppSpacing.xl),
              decoration: BoxDecoration(
                color: AppColors.secondary.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.warehouse_outlined,
                size: 64.sp,
                color: AppColors.secondary,
              ),
            ),
            SizedBox(height: AppSpacing.lg),
            Text(
              'لا توجد مستودعات',
              style: AppTypography.titleLarge.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(height: AppSpacing.sm),
            Text(
              'أضف مستودعاً جديداً لبدء إدارة المخزون',
              style: AppTypography.bodyMedium.copyWith(
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: AppSpacing.xl),
            ElevatedButton.icon(
              onPressed: () => _showWarehouseDialog(),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.secondary,
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(
                  horizontal: AppSpacing.xl,
                  vertical: AppSpacing.md,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
              ),
              icon: const Icon(Icons.add_rounded),
              label: Text(
                'إضافة مستودع',
                style: AppTypography.labelLarge.copyWith(color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState(String error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 64.sp, color: AppColors.error),
          SizedBox(height: AppSpacing.md),
          Text(
            'حدث خطأ',
            style: AppTypography.titleMedium.copyWith(color: AppColors.error),
          ),
          SizedBox(height: AppSpacing.sm),
          Text(error, style: AppTypography.bodySmall),
        ],
      ),
    );
  }

  Widget _buildWarehousesList(List<Warehouse> warehouses) {
    return ListView.builder(
      padding: EdgeInsets.symmetric(horizontal: AppSpacing.md),
      itemCount: warehouses.length,
      itemBuilder: (context, index) {
        final warehouse = warehouses[index];
        return _WarehouseCard(
          warehouse: warehouse,
          onTap: () => _showWarehouseDialog(warehouse: warehouse),
          onDelete: () => _deleteWarehouse(warehouse),
          onSetDefault: () => _setAsDefault(warehouse),
        );
      },
    );
  }

  void _showWarehouseDialog({Warehouse? warehouse}) {
    final isEditing = warehouse != null;
    final nameController = TextEditingController(text: warehouse?.name ?? '');
    final codeController = TextEditingController(text: warehouse?.code ?? '');
    final addressController =
        TextEditingController(text: warehouse?.address ?? '');
    final phoneController = TextEditingController(text: warehouse?.phone ?? '');
    final notesController = TextEditingController(text: warehouse?.notes ?? '');
    bool isDefault = warehouse?.isDefault ?? false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setSheetState) => Container(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.vertical(
              top: Radius.circular(AppRadius.xl),
            ),
          ),
          child: SingleChildScrollView(
            padding: EdgeInsets.all(AppSpacing.lg),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Handle
                Center(
                  child: Container(
                    width: 40.w,
                    height: 4.h,
                    decoration: BoxDecoration(
                      color: AppColors.border,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                SizedBox(height: AppSpacing.lg),

                // Title
                Row(
                  children: [
                    Container(
                      padding: EdgeInsets.all(AppSpacing.sm),
                      decoration: BoxDecoration(
                        color: AppColors.secondary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(AppRadius.md),
                      ),
                      child: Icon(Icons.warehouse_rounded,
                          color: AppColors.secondary),
                    ),
                    SizedBox(width: AppSpacing.md),
                    Text(
                      isEditing ? 'تعديل المستودع' : 'مستودع جديد',
                      style: AppTypography.titleLarge
                          .copyWith(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                SizedBox(height: AppSpacing.lg),

                // Form Fields
                _buildTextField(
                  controller: nameController,
                  label: 'اسم المستودع *',
                  icon: Icons.warehouse_outlined,
                ),
                SizedBox(height: AppSpacing.md),

                _buildTextField(
                  controller: codeController,
                  label: 'رمز المستودع',
                  icon: Icons.qr_code_rounded,
                ),
                SizedBox(height: AppSpacing.md),

                _buildTextField(
                  controller: addressController,
                  label: 'العنوان',
                  icon: Icons.location_on_outlined,
                ),
                SizedBox(height: AppSpacing.md),

                _buildTextField(
                  controller: phoneController,
                  label: 'رقم الهاتف',
                  icon: Icons.phone_outlined,
                  keyboardType: TextInputType.phone,
                ),
                SizedBox(height: AppSpacing.md),

                _buildTextField(
                  controller: notesController,
                  label: 'ملاحظات',
                  icon: Icons.notes_rounded,
                  maxLines: 2,
                ),
                SizedBox(height: AppSpacing.md),

                // Default Switch
                Container(
                  padding: EdgeInsets.all(AppSpacing.sm),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceMuted,
                    borderRadius: BorderRadius.circular(AppRadius.md),
                  ),
                  child: SwitchListTile(
                    title: Text('المستودع الافتراضي',
                        style: AppTypography.titleSmall),
                    subtitle: Text(
                      'سيتم اختياره تلقائياً في العمليات',
                      style: AppTypography.bodySmall.copyWith(
                        color: AppColors.textTertiary,
                      ),
                    ),
                    value: isDefault,
                    activeThumbColor: AppColors.secondary,
                    onChanged: (value) =>
                        setSheetState(() => isDefault = value),
                  ),
                ),
                SizedBox(height: AppSpacing.xl),

                // Buttons
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(context),
                        style: OutlinedButton.styleFrom(
                          padding: EdgeInsets.all(AppSpacing.md),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(AppRadius.md),
                          ),
                        ),
                        child: Text('إلغاء', style: AppTypography.labelLarge),
                      ),
                    ),
                    SizedBox(width: AppSpacing.md),
                    Expanded(
                      flex: 2,
                      child: ElevatedButton(
                        onPressed: () => _saveWarehouse(
                          isEditing: isEditing,
                          warehouse: warehouse,
                          name: nameController.text,
                          code: codeController.text,
                          address: addressController.text,
                          phone: phoneController.text,
                          notes: notesController.text,
                          isDefault: isDefault,
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.secondary,
                          foregroundColor: Colors.white,
                          padding: EdgeInsets.all(AppSpacing.md),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(AppRadius.md),
                          ),
                        ),
                        child: Text(
                          isEditing ? 'تحديث' : 'إضافة',
                          style: AppTypography.labelLarge
                              .copyWith(color: Colors.white),
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: AppSpacing.md),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    int maxLines = 1,
    TextInputType? keyboardType,
  }) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: AppColors.textTertiary),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: BorderSide(color: AppColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: BorderSide(color: AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: BorderSide(color: AppColors.secondary, width: 2),
        ),
        filled: true,
        fillColor: AppColors.surfaceMuted,
      ),
    );
  }

  Future<void> _saveWarehouse({
    required bool isEditing,
    Warehouse? warehouse,
    required String name,
    required String code,
    required String address,
    required String phone,
    required String notes,
    required bool isDefault,
  }) async {
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('أدخل اسم المستودع'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    try {
      final warehouseRepo = ref.read(warehouseRepositoryProvider);

      if (isEditing && warehouse != null) {
        await warehouseRepo.updateWarehouse(
          id: warehouse.id,
          name: name,
          code: code.isEmpty ? null : code,
          address: address.isEmpty ? null : address,
          phone: phone.isEmpty ? null : phone,
          notes: notes.isEmpty ? null : notes,
          isDefault: isDefault,
        );
      } else {
        await warehouseRepo.createWarehouse(
          name: name,
          code: code.isEmpty ? null : code,
          address: address.isEmpty ? null : address,
          phone: phone.isEmpty ? null : phone,
          notes: notes.isEmpty ? null : notes,
          isDefault: isDefault,
        );
      }

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content:
                Text(isEditing ? 'تم تحديث المستودع' : 'تم إضافة المستودع'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('خطأ: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  Future<void> _deleteWarehouse(Warehouse warehouse) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('تأكيد الحذف'),
        content: Text('هل تريد حذف المستودع "${warehouse.name}"؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('حذف', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      final warehouseRepo = ref.read(warehouseRepositoryProvider);
      await warehouseRepo.deleteWarehouse(warehouse.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('تم حذف المستودع'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('خطأ في الحذف: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  Future<void> _setAsDefault(Warehouse warehouse) async {
    try {
      final warehouseRepo = ref.read(warehouseRepositoryProvider);
      await warehouseRepo.updateWarehouse(
        id: warehouse.id,
        name: warehouse.name,
        isDefault: true,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('تم تعيين "${warehouse.name}" كافتراضي'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('خطأ: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// Warehouse Card Widget
// ═══════════════════════════════════════════════════════════════════════════

class _WarehouseCard extends StatelessWidget {
  final Warehouse warehouse;
  final VoidCallback onTap;
  final VoidCallback onDelete;
  final VoidCallback onSetDefault;

  const _WarehouseCard({
    required this.warehouse,
    required this.onTap,
    required this.onDelete,
    required this.onSetDefault,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(bottom: AppSpacing.md.h),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(
          color: warehouse.isDefault
              ? AppColors.secondary.withOpacity(0.5)
              : AppColors.border,
          width: warehouse.isDefault ? 2 : 1,
        ),
        boxShadow: AppShadows.sm,
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        child: Padding(
          padding: EdgeInsets.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  // Icon
                  Container(
                    padding: EdgeInsets.all(AppSpacing.sm),
                    decoration: BoxDecoration(
                      color: AppColors.secondary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(AppRadius.md),
                    ),
                    child: Icon(
                      Icons.warehouse_rounded,
                      color: AppColors.secondary,
                      size: 24.sp,
                    ),
                  ),
                  SizedBox(width: AppSpacing.md),

                  // Name & Code
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                warehouse.name,
                                style: AppTypography.titleMedium.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            if (warehouse.isDefault)
                              Container(
                                padding: EdgeInsets.symmetric(
                                  horizontal: AppSpacing.sm,
                                  vertical: 2.h,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.secondary.withOpacity(0.1),
                                  borderRadius:
                                      BorderRadius.circular(AppRadius.full),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.star_rounded,
                                      size: 12.sp,
                                      color: AppColors.secondary,
                                    ),
                                    SizedBox(width: 2.w),
                                    Text(
                                      'افتراضي',
                                      style: AppTypography.labelSmall.copyWith(
                                        color: AppColors.secondary,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                          ],
                        ),
                        if (warehouse.code != null)
                          Text(
                            warehouse.code!,
                            style: AppTypography.bodySmall.copyWith(
                              color: AppColors.textTertiary,
                              fontFamily: 'JetBrains Mono',
                            ),
                          ),
                      ],
                    ),
                  ),

                  // Menu
                  PopupMenuButton<String>(
                    icon: Icon(Icons.more_vert_rounded,
                        color: AppColors.textTertiary),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppRadius.md),
                    ),
                    onSelected: (value) {
                      if (value == 'edit') {
                        onTap();
                      } else if (value == 'delete') {
                        onDelete();
                      } else if (value == 'default') {
                        onSetDefault();
                      }
                    },
                    itemBuilder: (context) => [
                      PopupMenuItem(
                        value: 'edit',
                        child: Row(
                          children: [
                            Icon(Icons.edit_rounded,
                                color: AppColors.secondary, size: 20),
                            SizedBox(width: AppSpacing.sm),
                            const Text('تعديل'),
                          ],
                        ),
                      ),
                      if (!warehouse.isDefault)
                        PopupMenuItem(
                          value: 'default',
                          child: Row(
                            children: [
                              Icon(Icons.star_rounded,
                                  color: AppColors.warning, size: 20),
                              SizedBox(width: AppSpacing.sm),
                              const Text('تعيين كافتراضي'),
                            ],
                          ),
                        ),
                      PopupMenuItem(
                        value: 'delete',
                        child: Row(
                          children: [
                            Icon(Icons.delete_rounded,
                                color: AppColors.error, size: 20),
                            SizedBox(width: AppSpacing.sm),
                            Text('حذف',
                                style: TextStyle(color: AppColors.error)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),

              // Additional Info
              if (warehouse.address != null || warehouse.phone != null) ...[
                SizedBox(height: AppSpacing.sm),
                Divider(color: AppColors.border, height: 1),
                SizedBox(height: AppSpacing.sm),
                Wrap(
                  spacing: AppSpacing.md,
                  runSpacing: AppSpacing.xs,
                  children: [
                    if (warehouse.address != null)
                      _buildInfoChip(
                        Icons.location_on_outlined,
                        warehouse.address!,
                      ),
                    if (warehouse.phone != null)
                      _buildInfoChip(
                        Icons.phone_outlined,
                        warehouse.phone!,
                      ),
                  ],
                ),
              ],

              // Notes
              if (warehouse.notes != null && warehouse.notes!.isNotEmpty) ...[
                SizedBox(height: AppSpacing.xs),
                Text(
                  warehouse.notes!,
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.textTertiary,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoChip(IconData icon, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14.sp, color: AppColors.textTertiary),
        SizedBox(width: 4.w),
        Text(
          text,
          style: AppTypography.bodySmall.copyWith(
            color: AppColors.textTertiary,
          ),
        ),
      ],
    );
  }
}
