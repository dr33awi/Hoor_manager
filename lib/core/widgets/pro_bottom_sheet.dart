// ═══════════════════════════════════════════════════════════════════════════
// Pro Bottom Sheet - Unified Bottom Sheet Widget
// Consistent bottom sheets across all screens
// ═══════════════════════════════════════════════════════════════════════════

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../theme/design_tokens.dart';
import 'pro_button.dart';

/// عرض bottom sheet موحد
Future<T?> showProBottomSheet<T>({
  required BuildContext context,
  required Widget child,
  String? title,
  IconData? titleIcon,
  Color? titleIconColor,
  bool showHandle = true,
  bool showCloseButton = false,
  bool isScrollControlled = true,
  bool isDismissible = true,
  bool enableDrag = true,
  double? maxHeight,
}) {
  return showModalBottomSheet<T>(
    context: context,
    isScrollControlled: isScrollControlled,
    isDismissible: isDismissible,
    enableDrag: enableDrag,
    backgroundColor: Colors.transparent,
    builder: (context) => ProBottomSheetContainer(
      title: title,
      titleIcon: titleIcon,
      titleIconColor: titleIconColor,
      showHandle: showHandle,
      showCloseButton: showCloseButton,
      maxHeight: maxHeight,
      child: child,
    ),
  );
}

/// حاوية bottom sheet موحدة
class ProBottomSheetContainer extends StatelessWidget {
  final Widget child;
  final String? title;
  final IconData? titleIcon;
  final Color? titleIconColor;
  final bool showHandle;
  final bool showCloseButton;
  final double? maxHeight;

  const ProBottomSheetContainer({
    super.key,
    required this.child,
    this.title,
    this.titleIcon,
    this.titleIconColor,
    this.showHandle = true,
    this.showCloseButton = false,
    this.maxHeight,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: maxHeight != null
          ? BoxConstraints(maxHeight: maxHeight!)
          : null,
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadius.sheet,
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (showHandle) _buildHandle(),
            if (title != null || showCloseButton) _buildHeader(context),
            child,
          ],
        ),
      ),
    );
  }

  Widget _buildHandle() {
    return Container(
      margin: EdgeInsets.only(top: AppSpacing.md),
      width: 40.w,
      height: 4.h,
      decoration: BoxDecoration(
        color: AppColors.border,
        borderRadius: BorderRadius.circular(AppRadius.full),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.lg,
        showCloseButton ? AppSpacing.sm : AppSpacing.lg,
        AppSpacing.md,
      ),
      child: Row(
        children: [
          if (titleIcon != null) ...[
            Container(
              padding: EdgeInsets.all(AppSpacing.sm),
              decoration: BoxDecoration(
                color: (titleIconColor ?? AppColors.primary)
                    .withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(AppRadius.md),
              ),
              child: Icon(
                titleIcon,
                color: titleIconColor ?? AppColors.primary,
                size: 20.sp,
              ),
            ),
            SizedBox(width: AppSpacing.md),
          ],
          Expanded(
            child: Text(
              title ?? '',
              style: AppTypography.titleLarge,
            ),
          ),
          if (showCloseButton)
            ProIconButton.close(
              onPressed: () => Navigator.pop(context),
            ),
        ],
      ),
    );
  }
}

/// bottom sheet تأكيدي (confirmation)
Future<bool?> showProConfirmationSheet({
  required BuildContext context,
  required String title,
  String? message,
  IconData? icon,
  Color? iconColor,
  String confirmText = 'تأكيد',
  String cancelText = 'إلغاء',
  Color? confirmColor,
  bool isDanger = false,
}) {
  final effectiveConfirmColor =
      confirmColor ?? (isDanger ? AppColors.error : AppColors.primary);

  return showProBottomSheet<bool>(
    context: context,
    title: title,
    titleIcon: icon,
    titleIconColor: iconColor ?? effectiveConfirmColor,
    showCloseButton: true,
    child: Padding(
      padding: EdgeInsets.all(AppSpacing.lg),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (message != null) ...[
            Text(
              message,
              style: AppTypography.bodyMedium.copyWith(
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: AppSpacing.xl),
          ],
          Row(
            children: [
              Expanded(
                child: ProButton.cancel(
                  onPressed: () => Navigator.pop(context, false),
                  label: cancelText,
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
    ),
  );
}

/// bottom sheet خيارات (actions)
Future<T?> showProActionsSheet<T>({
  required BuildContext context,
  required List<ProSheetAction<T>> actions,
  String? title,
}) {
  return showProBottomSheet<T>(
    context: context,
    title: title,
    child: Padding(
      padding: EdgeInsets.fromLTRB(
        AppSpacing.md,
        title != null ? 0 : AppSpacing.md,
        AppSpacing.md,
        AppSpacing.lg,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: actions
            .map((action) => _ActionTile<T>(action: action))
            .toList(),
      ),
    ),
  );
}

/// عنصر خيار في bottom sheet
class ProSheetAction<T> {
  final IconData icon;
  final String label;
  final T? value;
  final VoidCallback? onTap;
  final Color? color;
  final bool isDanger;

  const ProSheetAction({
    required this.icon,
    required this.label,
    this.value,
    this.onTap,
    this.color,
    this.isDanger = false,
  });
}

class _ActionTile<T> extends StatelessWidget {
  final ProSheetAction<T> action;

  const _ActionTile({required this.action});

  @override
  Widget build(BuildContext context) {
    final color = action.color ??
        (action.isDanger ? AppColors.error : AppColors.textPrimary);

    return ListTile(
      onTap: () {
        if (action.onTap != null) {
          action.onTap!();
        } else if (action.value != null) {
          Navigator.pop(context, action.value);
        }
      },
      leading: Container(
        padding: EdgeInsets.all(AppSpacing.sm),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
        child: Icon(action.icon, color: color, size: 20.sp),
      ),
      title: Text(
        action.label,
        style: AppTypography.titleSmall.copyWith(color: color),
      ),
      trailing: Icon(
        Icons.chevron_left_rounded,
        color: AppColors.textTertiary,
      ),
      contentPadding: EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.xs,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
    );
  }
}

/// bottom sheet إدخال (input form)
Future<String?> showProInputSheet({
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

  return showProBottomSheet<String>(
    context: context,
    title: title,
    titleIcon: icon,
    showCloseButton: true,
    child: Padding(
      padding: EdgeInsets.all(AppSpacing.lg),
      child: Form(
        key: formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
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
                  child: ProButton.cancel(
                    onPressed: () => Navigator.pop(context),
                    label: cancelText,
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
    ),
  );
}
