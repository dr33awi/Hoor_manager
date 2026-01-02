// ═══════════════════════════════════════════════════════════════════════════
// Pro Dialog - Unified Dialog Widget
// Consistent dialogs across all screens
// ═══════════════════════════════════════════════════════════════════════════

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../theme/design_tokens.dart';
import 'pro_button.dart';
import 'pro_icon_box.dart';

/// عرض حوار موحد
Future<T?> showProDialog<T>({
  required BuildContext context,
  required Widget child,
  String? title,
  IconData? icon,
  Color? iconColor,
  bool barrierDismissible = true,
}) {
  return showDialog<T>(
    context: context,
    barrierDismissible: barrierDismissible,
    builder: (context) => ProDialogContainer(
      title: title,
      icon: icon,
      iconColor: iconColor,
      child: child,
    ),
  );
}

/// حاوية الحوار الموحدة
class ProDialogContainer extends StatelessWidget {
  final Widget child;
  final String? title;
  final IconData? icon;
  final Color? iconColor;

  const ProDialogContainer({
    super.key,
    required this.child,
    this.title,
    this.icon,
    this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.xl),
      ),
      backgroundColor: AppColors.surface,
      child: Padding(
        padding: EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              ProIconBox.large(
                icon: icon!,
                color: iconColor ?? AppColors.primary,
              ),
              SizedBox(height: AppSpacing.md),
            ],
            if (title != null) ...[
              Text(
                title!,
                style: AppTypography.titleLarge,
                textAlign: TextAlign.center,
              ),
              SizedBox(height: AppSpacing.md),
            ],
            child,
          ],
        ),
      ),
    );
  }
}

/// حوار التأكيد
Future<bool?> showProConfirmDialog({
  required BuildContext context,
  required String title,
  String? message,
  IconData? icon,
  Color? iconColor,
  String confirmText = 'تأكيد',
  String cancelText = 'إلغاء',
  Color? confirmColor,
  bool isDanger = false,
  bool barrierDismissible = true,
}) {
  final effectiveConfirmColor =
      confirmColor ?? (isDanger ? AppColors.error : AppColors.primary);
  final effectiveIconColor = iconColor ?? effectiveConfirmColor;

  return showProDialog<bool>(
    context: context,
    barrierDismissible: barrierDismissible,
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (icon != null) ...[
          ProIconBox.large(icon: icon, color: effectiveIconColor),
          SizedBox(height: AppSpacing.md),
        ],
        Text(
          title,
          style: AppTypography.titleLarge,
          textAlign: TextAlign.center,
        ),
        if (message != null) ...[
          SizedBox(height: AppSpacing.sm),
          Text(
            message,
            style: AppTypography.bodyMedium.copyWith(
              color: AppColors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
        ],
        SizedBox(height: AppSpacing.xl),
        Row(
          children: [
            Expanded(
              child: ProButton.outline(
                label: cancelText,
                color: AppColors.textSecondary,
                onPressed: () => Navigator.pop(context, false),
              ),
            ),
            SizedBox(width: AppSpacing.md),
            Expanded(
              child: ProButton(
                label: confirmText,
                color: effectiveConfirmColor,
                onPressed: () => Navigator.pop(context, true),
              ),
            ),
          ],
        ),
      ],
    ),
  );
}

/// حوار الحذف
Future<bool?> showProDeleteDialog({
  required BuildContext context,
  required String itemName,
  String? message,
}) {
  return showProConfirmDialog(
    context: context,
    title: 'حذف $itemName',
    message: message ?? 'هل أنت متأكد من حذف $itemName؟ لا يمكن التراجع عن هذا الإجراء.',
    icon: Icons.delete_outline_rounded,
    isDanger: true,
    confirmText: 'حذف',
  );
}

/// حوار النجاح
Future<void> showProSuccessDialog({
  required BuildContext context,
  required String title,
  String? message,
  String buttonText = 'حسناً',
  VoidCallback? onPressed,
}) {
  return showProDialog(
    context: context,
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        ProIconBox.large(icon: Icons.check_circle_rounded, color: AppColors.success),
        SizedBox(height: AppSpacing.md),
        Text(
          title,
          style: AppTypography.titleLarge,
          textAlign: TextAlign.center,
        ),
        if (message != null) ...[
          SizedBox(height: AppSpacing.sm),
          Text(
            message,
            style: AppTypography.bodyMedium.copyWith(
              color: AppColors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
        ],
        SizedBox(height: AppSpacing.xl),
        ProButton.success(
          label: buttonText,
          fullWidth: true,
          onPressed: () {
            Navigator.pop(context);
            onPressed?.call();
          },
        ),
      ],
    ),
  );
}

/// حوار الخطأ
Future<void> showProErrorDialog({
  required BuildContext context,
  required String title,
  String? message,
  String buttonText = 'حسناً',
  VoidCallback? onRetry,
}) {
  return showProDialog(
    context: context,
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        ProIconBox.large(icon: Icons.error_outline_rounded, color: AppColors.error),
        SizedBox(height: AppSpacing.md),
        Text(
          title,
          style: AppTypography.titleLarge,
          textAlign: TextAlign.center,
        ),
        if (message != null) ...[
          SizedBox(height: AppSpacing.sm),
          Text(
            message,
            style: AppTypography.bodyMedium.copyWith(
              color: AppColors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
        ],
        SizedBox(height: AppSpacing.xl),
        if (onRetry != null) ...[
          Row(
            children: [
              Expanded(
                child: ProButton.outline(
                  label: 'إلغاء',
                  color: AppColors.textSecondary,
                  onPressed: () => Navigator.pop(context),
                ),
              ),
              SizedBox(width: AppSpacing.md),
              Expanded(
                child: ProButton.danger(
                  label: 'إعادة المحاولة',
                  onPressed: () {
                    Navigator.pop(context);
                    onRetry();
                  },
                ),
              ),
            ],
          ),
        ] else
          ProButton.outline(
            label: buttonText,
            color: AppColors.textSecondary,
            fullWidth: true,
            onPressed: () => Navigator.pop(context),
          ),
      ],
    ),
  );
}

/// حوار التحميل
Future<void> showProLoadingDialog({
  required BuildContext context,
  String? message,
}) {
  return showDialog(
    context: context,
    barrierDismissible: false,
    builder: (context) => PopScope(
      canPop: false,
      child: Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.xl),
        ),
        backgroundColor: AppColors.surface,
        child: Padding(
          padding: EdgeInsets.all(AppSpacing.xl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: 48.w,
                height: 48.w,
                child: CircularProgressIndicator(
                  strokeWidth: 3,
                  valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                ),
              ),
              if (message != null) ...[
                SizedBox(height: AppSpacing.lg),
                Text(
                  message,
                  style: AppTypography.bodyMedium.copyWith(
                    color: AppColors.textSecondary,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ],
          ),
        ),
      ),
    ),
  );
}

/// إغلاق حوار التحميل
void hideProLoadingDialog(BuildContext context) {
  Navigator.of(context, rootNavigator: true).pop();
}

/// حوار الإدخال
Future<String?> showProInputDialog({
  required BuildContext context,
  required String title,
  String? initialValue,
  String? hintText,
  String? labelText,
  String confirmText = 'حفظ',
  String cancelText = 'إلغاء',
  IconData? icon,
  TextInputType keyboardType = TextInputType.text,
  int maxLines = 1,
  String? Function(String?)? validator,
}) {
  final controller = TextEditingController(text: initialValue);
  final formKey = GlobalKey<FormState>();

  return showProDialog<String>(
    context: context,
    child: Form(
      key: formKey,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (icon != null) ...[
            Center(
              child: ProIconBox(icon: icon, color: AppColors.primary),
            ),
            SizedBox(height: AppSpacing.md),
          ],
          Center(
            child: Text(
              title,
              style: AppTypography.titleLarge,
            ),
          ),
          SizedBox(height: AppSpacing.lg),
          TextFormField(
            controller: controller,
            keyboardType: keyboardType,
            maxLines: maxLines,
            autofocus: true,
            validator: validator,
            decoration: InputDecoration(
              hintText: hintText,
              labelText: labelText,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppRadius.md),
              ),
            ),
          ),
          SizedBox(height: AppSpacing.lg),
          Row(
            children: [
              Expanded(
                child: ProButton.outline(
                  label: cancelText,
                  color: AppColors.textSecondary,
                  onPressed: () => Navigator.pop(context),
                ),
              ),
              SizedBox(width: AppSpacing.md),
              Expanded(
                child: ProButton.primary(
                  label: confirmText,
                  onPressed: () {
                    if (formKey.currentState?.validate() ?? true) {
                      Navigator.pop(context, controller.text);
                    }
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    ),
  );
}
