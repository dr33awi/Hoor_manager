// ═══════════════════════════════════════════════════════════════════════════
// Pro Dialogs & Bottom Sheets
// Beautiful, Animated Dialogs and Sheets
// ═══════════════════════════════════════════════════════════════════════════

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../theme/design_tokens.dart';

// ═══════════════════════════════════════════════════════════════════════════
// Confirm Dialog
// ═══════════════════════════════════════════════════════════════════════════

class ProConfirmDialog extends StatelessWidget {
  final String title;
  final String message;
  final String? confirmLabel;
  final String? cancelLabel;
  final Color? confirmColor;
  final IconData? icon;
  final bool isDanger;

  const ProConfirmDialog({
    super.key,
    required this.title,
    required this.message,
    this.confirmLabel,
    this.cancelLabel,
    this.confirmColor,
    this.icon,
    this.isDanger = false,
  });

  static Future<bool?> show(
    BuildContext context, {
    required String title,
    required String message,
    String? confirmLabel,
    String? cancelLabel,
    Color? confirmColor,
    IconData? icon,
    bool isDanger = false,
  }) {
    return showDialog<bool>(
      context: context,
      builder: (context) => ProConfirmDialog(
        title: title,
        message: message,
        confirmLabel: confirmLabel,
        cancelLabel: cancelLabel,
        confirmColor: confirmColor,
        icon: icon,
        isDanger: isDanger,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final color =
        isDanger ? AppColors.error : (confirmColor ?? AppColors.primary);

    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.xl),
      ),
      child: Padding(
        padding: EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Container(
                width: 64.w,
                height: 64.h,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  icon,
                  size: 32.sp,
                  color: color,
                ),
              ),
              SizedBox(height: AppSpacing.lg),
            ],
            Text(
              title,
              style: AppTypography.titleLarge.copyWith(
                color: AppColors.textPrimary,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: AppSpacing.md),
            Text(
              message,
              style: AppTypography.bodyMedium.copyWith(
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: AppSpacing.xl),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context, false),
                    style: OutlinedButton.styleFrom(
                      padding: EdgeInsets.symmetric(vertical: AppSpacing.md),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppRadius.md),
                      ),
                      side: BorderSide(color: AppColors.border),
                    ),
                    child: Text(
                      cancelLabel ?? 'إلغاء',
                      style: AppTypography.labelLarge.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                ),
                SizedBox(width: AppSpacing.md),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context, true),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: color,
                      padding: EdgeInsets.symmetric(vertical: AppSpacing.md),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppRadius.md),
                      ),
                    ),
                    child: Text(
                      confirmLabel ?? 'تأكيد',
                      style: AppTypography.labelLarge.copyWith(
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// Delete Confirm Dialog
// ═══════════════════════════════════════════════════════════════════════════

class ProDeleteDialog extends StatelessWidget {
  final String itemName;
  final String? itemType;

  const ProDeleteDialog({
    super.key,
    required this.itemName,
    this.itemType,
  });

  static Future<bool?> show(
    BuildContext context, {
    required String itemName,
    String? itemType,
  }) {
    return ProConfirmDialog.show(
      context,
      title: 'حذف ${itemType ?? 'العنصر'}؟',
      message:
          'هل أنت متأكد من حذف "$itemName"؟\nلا يمكن التراجع عن هذا الإجراء.',
      confirmLabel: 'حذف',
      cancelLabel: 'إلغاء',
      icon: Icons.delete_outline,
      isDanger: true,
    );
  }

  @override
  Widget build(BuildContext context) {
    return ProConfirmDialog(
      title: 'حذف ${itemType ?? 'العنصر'}؟',
      message:
          'هل أنت متأكد من حذف "$itemName"؟\nلا يمكن التراجع عن هذا الإجراء.',
      confirmLabel: 'حذف',
      cancelLabel: 'إلغاء',
      icon: Icons.delete_outline,
      isDanger: true,
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// Success Dialog
// ═══════════════════════════════════════════════════════════════════════════

class ProSuccessDialog extends StatelessWidget {
  final String title;
  final String? message;
  final String? buttonLabel;

  const ProSuccessDialog({
    super.key,
    required this.title,
    this.message,
    this.buttonLabel,
  });

  static Future<void> show(
    BuildContext context, {
    required String title,
    String? message,
    String? buttonLabel,
  }) {
    return showDialog(
      context: context,
      builder: (context) => ProSuccessDialog(
        title: title,
        message: message,
        buttonLabel: buttonLabel,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.xl),
      ),
      child: Padding(
        padding: EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80.w,
              height: 80.h,
              decoration: BoxDecoration(
                color: AppColors.success.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.check_circle_outline,
                size: 48.sp,
                color: AppColors.success,
              ),
            ),
            SizedBox(height: AppSpacing.lg),
            Text(
              title,
              style: AppTypography.titleLarge.copyWith(
                color: AppColors.textPrimary,
              ),
              textAlign: TextAlign.center,
            ),
            if (message != null) ...[
              SizedBox(height: AppSpacing.sm),
              Text(
                message!,
                style: AppTypography.bodyMedium.copyWith(
                  color: AppColors.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
            ],
            SizedBox(height: AppSpacing.xl),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.success,
                  padding: EdgeInsets.symmetric(vertical: AppSpacing.md),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppRadius.md),
                  ),
                ),
                child: Text(
                  buttonLabel ?? 'حسناً',
                  style: AppTypography.labelLarge.copyWith(
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// Action Bottom Sheet
// ═══════════════════════════════════════════════════════════════════════════

class ProActionSheet extends StatelessWidget {
  final String? title;
  final List<ProActionSheetItem> items;

  const ProActionSheet({
    super.key,
    this.title,
    required this.items,
  });

  static Future<T?> show<T>(
    BuildContext context, {
    String? title,
    required List<ProActionSheetItem> items,
  }) {
    return showModalBottomSheet<T>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => ProActionSheet(
        title: title,
        items: items,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppRadius.xl),
        ),
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle
            Container(
              margin: EdgeInsets.only(top: AppSpacing.md),
              width: 40.w,
              height: 4.h,
              decoration: BoxDecoration(
                color: AppColors.border,
                borderRadius: BorderRadius.circular(AppRadius.full),
              ),
            ),

            // Title
            if (title != null) ...[
              Padding(
                padding: EdgeInsets.all(AppSpacing.lg),
                child: Text(
                  title!,
                  style: AppTypography.titleMedium,
                ),
              ),
              Divider(height: 1, color: AppColors.border),
            ],

            // Items
            ...items.map((item) => _ActionItem(item: item)),

            SizedBox(height: AppSpacing.md),

            // Cancel Button
            Padding(
              padding: EdgeInsets.symmetric(horizontal: AppSpacing.lg),
              child: SizedBox(
                width: double.infinity,
                child: TextButton(
                  onPressed: () => Navigator.pop(context),
                  style: TextButton.styleFrom(
                    padding: EdgeInsets.symmetric(vertical: AppSpacing.md),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppRadius.md),
                    ),
                  ),
                  child: Text(
                    'إلغاء',
                    style: AppTypography.labelLarge.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
              ),
            ),

            SizedBox(height: AppSpacing.md),
          ],
        ),
      ),
    );
  }
}

class _ActionItem extends StatelessWidget {
  final ProActionSheetItem item;

  const _ActionItem({required this.item});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(
        item.icon,
        color: item.isDanger ? AppColors.error : item.iconColor,
      ),
      title: Text(
        item.label,
        style: AppTypography.bodyLarge.copyWith(
          color: item.isDanger ? AppColors.error : AppColors.textPrimary,
        ),
      ),
      subtitle: item.subtitle != null
          ? Text(
              item.subtitle!,
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.textSecondary,
              ),
            )
          : null,
      onTap: () {
        Navigator.pop(context, item.value);
        item.onTap?.call();
      },
    );
  }
}

class ProActionSheetItem<T> {
  final String label;
  final IconData icon;
  final String? subtitle;
  final Color? iconColor;
  final bool isDanger;
  final VoidCallback? onTap;
  final T? value;

  const ProActionSheetItem({
    required this.label,
    required this.icon,
    this.subtitle,
    this.iconColor,
    this.isDanger = false,
    this.onTap,
    this.value,
  });
}

// ═══════════════════════════════════════════════════════════════════════════
// Input Dialog
// ═══════════════════════════════════════════════════════════════════════════

class ProInputDialog extends StatefulWidget {
  final String title;
  final String? initialValue;
  final String? hintText;
  final String? confirmLabel;
  final TextInputType? keyboardType;
  final int? maxLines;
  final String? Function(String?)? validator;

  const ProInputDialog({
    super.key,
    required this.title,
    this.initialValue,
    this.hintText,
    this.confirmLabel,
    this.keyboardType,
    this.maxLines = 1,
    this.validator,
  });

  static Future<String?> show(
    BuildContext context, {
    required String title,
    String? initialValue,
    String? hintText,
    String? confirmLabel,
    TextInputType? keyboardType,
    int? maxLines,
    String? Function(String?)? validator,
  }) {
    return showDialog<String>(
      context: context,
      builder: (context) => ProInputDialog(
        title: title,
        initialValue: initialValue,
        hintText: hintText,
        confirmLabel: confirmLabel,
        keyboardType: keyboardType,
        maxLines: maxLines,
        validator: validator,
      ),
    );
  }

  @override
  State<ProInputDialog> createState() => _ProInputDialogState();
}

class _ProInputDialogState extends State<ProInputDialog> {
  late TextEditingController _controller;
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialValue);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.xl),
      ),
      child: Padding(
        padding: EdgeInsets.all(AppSpacing.lg),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.title,
                style: AppTypography.titleLarge,
              ),
              SizedBox(height: AppSpacing.lg),
              TextFormField(
                controller: _controller,
                keyboardType: widget.keyboardType,
                maxLines: widget.maxLines,
                validator: widget.validator,
                decoration: InputDecoration(
                  hintText: widget.hintText,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppRadius.md),
                  ),
                ),
              ),
              SizedBox(height: AppSpacing.lg),
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text('إلغاء'),
                    ),
                  ),
                  SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        if (_formKey.currentState?.validate() ?? true) {
                          Navigator.pop(context, _controller.text);
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                      ),
                      child: Text(
                        widget.confirmLabel ?? 'حفظ',
                        style: const TextStyle(color: Colors.white),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// Toast / Snackbar Helper
// ═══════════════════════════════════════════════════════════════════════════

class ProToast {
  static void show(
    BuildContext context, {
    required String message,
    ToastType type = ToastType.info,
    Duration duration = const Duration(seconds: 3),
    VoidCallback? onAction,
    String? actionLabel,
  }) {
    final color = _getColor(type);
    final icon = _getIcon(type);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(icon, color: Colors.white, size: 20.sp),
            SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Text(
                message,
                style: AppTypography.bodyMedium.copyWith(color: Colors.white),
              ),
            ),
          ],
        ),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
        margin: EdgeInsets.all(AppSpacing.md),
        duration: duration,
        action: onAction != null && actionLabel != null
            ? SnackBarAction(
                label: actionLabel,
                textColor: Colors.white,
                onPressed: onAction,
              )
            : null,
      ),
    );
  }

  static void success(BuildContext context, String message) {
    show(context, message: message, type: ToastType.success);
  }

  static void error(BuildContext context, String message) {
    show(context, message: message, type: ToastType.error);
  }

  static void warning(BuildContext context, String message) {
    show(context, message: message, type: ToastType.warning);
  }

  static void info(BuildContext context, String message) {
    show(context, message: message, type: ToastType.info);
  }

  static Color _getColor(ToastType type) {
    switch (type) {
      case ToastType.success:
        return AppColors.success;
      case ToastType.error:
        return AppColors.error;
      case ToastType.warning:
        return AppColors.warning;
      case ToastType.info:
        return AppColors.info;
    }
  }

  static IconData _getIcon(ToastType type) {
    switch (type) {
      case ToastType.success:
        return Icons.check_circle;
      case ToastType.error:
        return Icons.error;
      case ToastType.warning:
        return Icons.warning;
      case ToastType.info:
        return Icons.info;
    }
  }
}

enum ToastType { success, error, warning, info }
