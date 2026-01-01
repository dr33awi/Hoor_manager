/// ═══════════════════════════════════════════════════════════════════════════
/// Warehouses Screen - Redesigned
/// Modern Warehouse Management Interface
/// ═══════════════════════════════════════════════════════════════════════════
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/di/injection.dart';
import '../../../../data/database/app_database.dart';
import '../../../../data/repositories/warehouse_repository.dart';

class WarehousesScreenRedesign extends ConsumerStatefulWidget {
  const WarehousesScreenRedesign({super.key});

  @override
  ConsumerState<WarehousesScreenRedesign> createState() =>
      _WarehousesScreenRedesignState();
}

class _WarehousesScreenRedesignState
    extends ConsumerState<WarehousesScreenRedesign> {
  final _warehouseRepo = getIt<WarehouseRepository>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: HoorColors.background,
      appBar: AppBar(
        backgroundColor: HoorColors.surface,
        title: Text('المستودعات', style: HoorTypography.headlineSmall),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.pop(),
        ),
        actions: [
          IconButton(
            icon: Container(
              padding: EdgeInsets.all(HoorSpacing.xs.w),
              decoration: BoxDecoration(
                color: HoorColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(HoorRadius.sm),
              ),
              child: Icon(Icons.add_rounded, color: HoorColors.primary),
            ),
            onPressed: () => _showWarehouseDialog(),
          ),
        ],
      ),
      body: StreamBuilder<List<Warehouse>>(
        stream: _warehouseRepo.watchAllWarehouses(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: HoorColors.primary),
            );
          }

          final warehouses = snapshot.data ?? [];

          if (warehouses.isEmpty) {
            return _buildEmptyState();
          }

          return ListView.builder(
            padding: EdgeInsets.all(HoorSpacing.md.w),
            itemCount: warehouses.length,
            itemBuilder: (context, index) {
              final warehouse = warehouses[index];
              return _buildWarehouseCard(warehouse);
            },
          );
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: EdgeInsets.all(HoorSpacing.lg.w),
            decoration: BoxDecoration(
              color: HoorColors.primary.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.warehouse_outlined,
                size: 64, color: HoorColors.primary),
          ),
          SizedBox(height: HoorSpacing.lg.h),
          Text(
            'لا توجد مستودعات',
            style: HoorTypography.titleLarge.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: HoorSpacing.xs.h),
          Text(
            'أضف مستودع لبدء إدارة المخزون',
            style: HoorTypography.bodyMedium.copyWith(
              color: HoorColors.textSecondary,
            ),
          ),
          SizedBox(height: HoorSpacing.lg.h),
          ElevatedButton.icon(
            onPressed: () => _showWarehouseDialog(),
            icon: const Icon(Icons.add_rounded, color: Colors.white),
            label: Text('إضافة مستودع',
                style: HoorTypography.labelLarge.copyWith(color: Colors.white)),
            style: ElevatedButton.styleFrom(
              backgroundColor: HoorColors.primary,
              padding: EdgeInsets.symmetric(
                horizontal: HoorSpacing.lg.w,
                vertical: HoorSpacing.sm.h,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(HoorRadius.md),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWarehouseCard(Warehouse warehouse) {
    return Container(
      margin: EdgeInsets.only(bottom: HoorSpacing.sm.h),
      decoration: BoxDecoration(
        color: HoorColors.surface,
        borderRadius: BorderRadius.circular(HoorRadius.lg),
        border: Border.all(
          color: warehouse.isDefault
              ? HoorColors.primary.withValues(alpha: 0.3)
              : HoorColors.border,
        ),
      ),
      child: InkWell(
        onTap: () => _showWarehouseDialog(warehouse: warehouse),
        borderRadius: BorderRadius.circular(HoorRadius.lg),
        child: Padding(
          padding: EdgeInsets.all(HoorSpacing.md.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(HoorSpacing.sm.w),
                    decoration: BoxDecoration(
                      color: HoorColors.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(HoorRadius.md),
                    ),
                    child: Icon(Icons.warehouse_rounded,
                        color: HoorColors.primary, size: 24),
                  ),
                  SizedBox(width: HoorSpacing.sm.w),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                warehouse.name,
                                style: HoorTypography.titleMedium.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            if (warehouse.isDefault)
                              Container(
                                padding: EdgeInsets.symmetric(
                                  horizontal: HoorSpacing.xs.w,
                                  vertical: HoorSpacing.xxs.h,
                                ),
                                decoration: BoxDecoration(
                                  color:
                                      HoorColors.primary.withValues(alpha: 0.1),
                                  borderRadius:
                                      BorderRadius.circular(HoorRadius.sm),
                                ),
                                child: Text(
                                  'افتراضي',
                                  style: HoorTypography.labelSmall.copyWith(
                                    color: HoorColors.primary,
                                  ),
                                ),
                              ),
                          ],
                        ),
                        if (warehouse.code != null)
                          Text(
                            warehouse.code!,
                            style: HoorTypography.labelSmall.copyWith(
                              color: HoorColors.textSecondary,
                            ),
                          ),
                      ],
                    ),
                  ),
                  PopupMenuButton<String>(
                    icon: Icon(Icons.more_vert_rounded,
                        color: HoorColors.textSecondary),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(HoorRadius.md),
                    ),
                    onSelected: (value) {
                      if (value == 'edit') {
                        _showWarehouseDialog(warehouse: warehouse);
                      } else if (value == 'delete') {
                        _deleteWarehouse(warehouse);
                      } else if (value == 'default') {
                        _setAsDefault(warehouse);
                      }
                    },
                    itemBuilder: (context) => [
                      PopupMenuItem(
                        value: 'edit',
                        child: Row(
                          children: [
                            Icon(Icons.edit_rounded,
                                color: HoorColors.primary, size: 20),
                            SizedBox(width: HoorSpacing.sm.w),
                            Text('تعديل', style: HoorTypography.bodyMedium),
                          ],
                        ),
                      ),
                      if (!warehouse.isDefault)
                        PopupMenuItem(
                          value: 'default',
                          child: Row(
                            children: [
                              Icon(Icons.star_rounded,
                                  color: HoorColors.warning, size: 20),
                              SizedBox(width: HoorSpacing.sm.w),
                              Text('تعيين كافتراضي',
                                  style: HoorTypography.bodyMedium),
                            ],
                          ),
                        ),
                      PopupMenuItem(
                        value: 'delete',
                        child: Row(
                          children: [
                            Icon(Icons.delete_rounded,
                                color: HoorColors.error, size: 20),
                            SizedBox(width: HoorSpacing.sm.w),
                            Text('حذف',
                                style: HoorTypography.bodyMedium.copyWith(
                                  color: HoorColors.error,
                                )),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              if (warehouse.address != null || warehouse.phone != null) ...[
                SizedBox(height: HoorSpacing.sm.h),
                Divider(color: HoorColors.border, height: 1),
                SizedBox(height: HoorSpacing.sm.h),
                Wrap(
                  spacing: HoorSpacing.md.w,
                  runSpacing: HoorSpacing.xs.h,
                  children: [
                    if (warehouse.address != null)
                      _buildInfoChip(
                        icon: Icons.location_on_outlined,
                        text: warehouse.address!,
                      ),
                    if (warehouse.phone != null)
                      _buildInfoChip(
                        icon: Icons.phone_outlined,
                        text: warehouse.phone!,
                      ),
                  ],
                ),
              ],
              if (warehouse.notes != null && warehouse.notes!.isNotEmpty) ...[
                SizedBox(height: HoorSpacing.xs.h),
                Text(
                  warehouse.notes!,
                  style: HoorTypography.bodySmall.copyWith(
                    color: HoorColors.textSecondary,
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

  Widget _buildInfoChip({required IconData icon, required String text}) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: HoorColors.textSecondary),
        SizedBox(width: HoorSpacing.xxs.w),
        Text(
          text,
          style: HoorTypography.labelSmall.copyWith(
            color: HoorColors.textSecondary,
          ),
        ),
      ],
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

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: HoorColors.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(HoorRadius.lg),
          ),
          title: Row(
            children: [
              Icon(Icons.warehouse_rounded, color: HoorColors.primary),
              SizedBox(width: HoorSpacing.sm.w),
              Text(
                isEditing ? 'تعديل مستودع' : 'إضافة مستودع',
                style: HoorTypography.titleLarge,
              ),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildDialogTextField(
                  controller: nameController,
                  label: 'اسم المستودع *',
                  icon: Icons.warehouse_outlined,
                ),
                SizedBox(height: HoorSpacing.sm.h),
                _buildDialogTextField(
                  controller: codeController,
                  label: 'رمز المستودع',
                  icon: Icons.qr_code_rounded,
                ),
                SizedBox(height: HoorSpacing.sm.h),
                _buildDialogTextField(
                  controller: addressController,
                  label: 'العنوان',
                  icon: Icons.location_on_outlined,
                  maxLines: 2,
                ),
                SizedBox(height: HoorSpacing.sm.h),
                _buildDialogTextField(
                  controller: phoneController,
                  label: 'رقم الهاتف',
                  icon: Icons.phone_outlined,
                  keyboardType: TextInputType.phone,
                ),
                SizedBox(height: HoorSpacing.sm.h),
                _buildDialogTextField(
                  controller: notesController,
                  label: 'ملاحظات',
                  icon: Icons.notes_rounded,
                  maxLines: 2,
                ),
                SizedBox(height: HoorSpacing.sm.h),
                Container(
                  decoration: BoxDecoration(
                    color: HoorColors.background,
                    borderRadius: BorderRadius.circular(HoorRadius.md),
                  ),
                  child: SwitchListTile(
                    title: Text('المستودع الافتراضي',
                        style: HoorTypography.bodyMedium),
                    subtitle: Text(
                      'سيتم اختياره تلقائياً في العمليات',
                      style: HoorTypography.labelSmall.copyWith(
                        color: HoorColors.textSecondary,
                      ),
                    ),
                    value: isDefault,
                    activeTrackColor: HoorColors.primary,
                    onChanged: (value) =>
                        setDialogState(() => isDefault = value),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('إلغاء', style: HoorTypography.labelLarge),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: HoorColors.primary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(HoorRadius.sm),
                ),
              ),
              onPressed: () async {
                if (nameController.text.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('أدخل اسم المستودع'),
                      backgroundColor: HoorColors.error,
                    ),
                  );
                  return;
                }

                try {
                  if (isEditing) {
                    await _warehouseRepo.updateWarehouse(
                      id: warehouse.id,
                      name: nameController.text,
                      code: codeController.text.isEmpty
                          ? null
                          : codeController.text,
                      address: addressController.text.isEmpty
                          ? null
                          : addressController.text,
                      phone: phoneController.text.isEmpty
                          ? null
                          : phoneController.text,
                      notes: notesController.text.isEmpty
                          ? null
                          : notesController.text,
                      isDefault: isDefault,
                    );
                  } else {
                    await _warehouseRepo.createWarehouse(
                      name: nameController.text,
                      code: codeController.text.isEmpty
                          ? null
                          : codeController.text,
                      address: addressController.text.isEmpty
                          ? null
                          : addressController.text,
                      phone: phoneController.text.isEmpty
                          ? null
                          : phoneController.text,
                      notes: notesController.text.isEmpty
                          ? null
                          : notesController.text,
                      isDefault: isDefault,
                    );
                  }
                  if (mounted) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(isEditing
                            ? 'تم تحديث المستودع'
                            : 'تم إضافة المستودع'),
                        backgroundColor: HoorColors.success,
                      ),
                    );
                  }
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('خطأ: $e'),
                        backgroundColor: HoorColors.error,
                      ),
                    );
                  }
                }
              },
              child: Text(
                isEditing ? 'تحديث' : 'إضافة',
                style: HoorTypography.labelLarge.copyWith(color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDialogTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    int maxLines = 1,
    TextInputType? keyboardType,
  }) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      keyboardType: keyboardType,
      style: HoorTypography.bodyMedium,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: HoorTypography.bodySmall.copyWith(
          color: HoorColors.textSecondary,
        ),
        prefixIcon: Icon(icon, color: HoorColors.textSecondary, size: 20),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(HoorRadius.md),
          borderSide: BorderSide(color: HoorColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(HoorRadius.md),
          borderSide: BorderSide(color: HoorColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(HoorRadius.md),
          borderSide: BorderSide(color: HoorColors.primary),
        ),
        filled: true,
        fillColor: HoorColors.background,
      ),
    );
  }

  Future<void> _deleteWarehouse(Warehouse warehouse) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: HoorColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(HoorRadius.lg),
        ),
        title: Text('تأكيد الحذف', style: HoorTypography.titleLarge),
        content: Text(
          'هل تريد حذف المستودع "${warehouse.name}"؟',
          style: HoorTypography.bodyMedium,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('إلغاء', style: HoorTypography.labelLarge),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: HoorColors.error,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(HoorRadius.sm),
              ),
            ),
            onPressed: () => Navigator.pop(context, true),
            child: Text('حذف',
                style: HoorTypography.labelLarge.copyWith(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      await _warehouseRepo.deleteWarehouse(warehouse.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('تم حذف المستودع'),
            backgroundColor: HoorColors.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('خطأ في الحذف: $e'),
            backgroundColor: HoorColors.error,
          ),
        );
      }
    }
  }

  Future<void> _setAsDefault(Warehouse warehouse) async {
    try {
      await _warehouseRepo.updateWarehouse(
        id: warehouse.id,
        name: warehouse.name,
        isDefault: true,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('تم تعيين "${warehouse.name}" كافتراضي'),
            backgroundColor: HoorColors.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('خطأ: $e'),
            backgroundColor: HoorColors.error,
          ),
        );
      }
    }
  }
}
