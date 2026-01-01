import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../design_tokens.dart';
import '../typography.dart';

/// ═══════════════════════════════════════════════════════════════════════════
/// HoorDialog - Professional Dialog Components
/// ═══════════════════════════════════════════════════════════════════════════

class HoorDialog extends StatelessWidget {
  final String? title;
  final String? message;
  final Widget? content;
  final List<HoorDialogAction>? actions;
  final IconData? icon;
  final Color? iconColor;
  final bool showCloseButton;

  const HoorDialog({
    super.key,
    this.title,
    this.message,
    this.content,
    this.actions,
    this.icon,
    this.iconColor,
    this.showCloseButton = false,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(HoorRadius.xl),
      ),
      backgroundColor: HoorColors.surface,
      elevation: 0,
      child: Padding(
        padding: EdgeInsets.all(HoorSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header with close button
            if (showCloseButton)
              Align(
                alignment: Alignment.topLeft,
                child: IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.of(context).pop(),
                  iconSize: HoorIconSize.md,
                  color: HoorColors.textSecondary,
                ),
              ),

            // Icon
            if (icon != null) ...[
              Container(
                padding: EdgeInsets.all(HoorSpacing.md),
                decoration: BoxDecoration(
                  color:
                      (iconColor ?? HoorColors.primary).withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  icon,
                  size: HoorIconSize.xxl,
                  color: iconColor ?? HoorColors.primary,
                ),
              ),
              SizedBox(height: HoorSpacing.lg),
            ],

            // Title
            if (title != null) ...[
              Text(
                title!,
                style: HoorTypography.titleLarge,
                textAlign: TextAlign.center,
              ),
              SizedBox(height: HoorSpacing.sm),
            ],

            // Message
            if (message != null) ...[
              Text(
                message!,
                style: HoorTypography.bodyMedium.copyWith(
                  color: HoorColors.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: HoorSpacing.lg),
            ],

            // Custom content
            if (content != null) ...[
              content!,
              SizedBox(height: HoorSpacing.lg),
            ],

            // Actions
            if (actions != null && actions!.isNotEmpty) ...[
              SizedBox(height: HoorSpacing.md),
              Row(
                children: actions!.map((action) {
                  return Expanded(
                    child: Padding(
                      padding: EdgeInsets.only(
                        right: action != actions!.last ? HoorSpacing.sm : 0,
                      ),
                      child: _buildActionButton(context, action),
                    ),
                  );
                }).toList(),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton(BuildContext context, HoorDialogAction action) {
    switch (action.type) {
      case HoorDialogActionType.primary:
        return ElevatedButton(
          onPressed: () {
            action.onPressed?.call();
            if (action.dismissOnTap) Navigator.of(context).pop(action.value);
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: action.color ?? HoorColors.primary,
            foregroundColor: HoorColors.textOnPrimary,
            minimumSize: Size(0, 48.h),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(HoorRadius.md),
            ),
          ),
          child: Text(action.label),
        );
      case HoorDialogActionType.secondary:
        return OutlinedButton(
          onPressed: () {
            action.onPressed?.call();
            if (action.dismissOnTap) Navigator.of(context).pop(action.value);
          },
          style: OutlinedButton.styleFrom(
            foregroundColor: action.color ?? HoorColors.primary,
            minimumSize: Size(0, 48.h),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(HoorRadius.md),
            ),
            side: BorderSide(color: action.color ?? HoorColors.primary),
          ),
          child: Text(action.label),
        );
      case HoorDialogActionType.destructive:
        return ElevatedButton(
          onPressed: () {
            action.onPressed?.call();
            if (action.dismissOnTap) Navigator.of(context).pop(action.value);
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: HoorColors.error,
            foregroundColor: Colors.white,
            minimumSize: Size(0, 48.h),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(HoorRadius.md),
            ),
          ),
          child: Text(action.label),
        );
      case HoorDialogActionType.text:
        return TextButton(
          onPressed: () {
            action.onPressed?.call();
            if (action.dismissOnTap) Navigator.of(context).pop(action.value);
          },
          style: TextButton.styleFrom(
            foregroundColor: action.color ?? HoorColors.textSecondary,
            minimumSize: Size(0, 48.h),
          ),
          child: Text(action.label),
        );
    }
  }

  /// Show a confirmation dialog
  static Future<bool?> showConfirm(
    BuildContext context, {
    required String title,
    required String message,
    String confirmLabel = 'تأكيد',
    String cancelLabel = 'إلغاء',
    bool isDestructive = false,
  }) {
    return showDialog<bool>(
      context: context,
      builder: (context) => HoorDialog(
        icon: isDestructive ? Icons.warning_amber_rounded : Icons.help_outline,
        iconColor: isDestructive ? HoorColors.error : HoorColors.warning,
        title: title,
        message: message,
        actions: [
          HoorDialogAction(
            label: cancelLabel,
            type: HoorDialogActionType.secondary,
            value: false,
          ),
          HoorDialogAction(
            label: confirmLabel,
            type: isDestructive
                ? HoorDialogActionType.destructive
                : HoorDialogActionType.primary,
            value: true,
          ),
        ],
      ),
    );
  }

  /// Show an alert dialog
  static Future<void> showAlert(
    BuildContext context, {
    required String title,
    required String message,
    String buttonLabel = 'حسناً',
    IconData? icon,
    Color? iconColor,
  }) {
    return showDialog<void>(
      context: context,
      builder: (context) => HoorDialog(
        icon: icon ?? Icons.info_outline,
        iconColor: iconColor ?? HoorColors.info,
        title: title,
        message: message,
        actions: [
          HoorDialogAction(
            label: buttonLabel,
            type: HoorDialogActionType.primary,
          ),
        ],
      ),
    );
  }

  /// Show a success dialog
  static Future<void> showSuccess(
    BuildContext context, {
    required String title,
    String? message,
  }) {
    return showDialog<void>(
      context: context,
      builder: (context) => HoorDialog(
        icon: Icons.check_circle_outline,
        iconColor: HoorColors.success,
        title: title,
        message: message,
        actions: [
          HoorDialogAction(
            label: 'حسناً',
            type: HoorDialogActionType.primary,
          ),
        ],
      ),
    );
  }

  /// Show an error dialog
  static Future<void> showError(
    BuildContext context, {
    required String title,
    String? message,
  }) {
    return showDialog<void>(
      context: context,
      builder: (context) => HoorDialog(
        icon: Icons.error_outline,
        iconColor: HoorColors.error,
        title: title,
        message: message,
        actions: [
          HoorDialogAction(
            label: 'حسناً',
            type: HoorDialogActionType.primary,
          ),
        ],
      ),
    );
  }
}

class HoorDialogAction {
  final String label;
  final HoorDialogActionType type;
  final VoidCallback? onPressed;
  final Color? color;
  final dynamic value;
  final bool dismissOnTap;

  const HoorDialogAction({
    required this.label,
    this.type = HoorDialogActionType.primary,
    this.onPressed,
    this.color,
    this.value,
    this.dismissOnTap = true,
  });
}

enum HoorDialogActionType {
  primary,
  secondary,
  destructive,
  text,
}

/// ═══════════════════════════════════════════════════════════════════════════
/// HoorInputDialog - Dialog with text input
/// ═══════════════════════════════════════════════════════════════════════════

class HoorInputDialog extends StatefulWidget {
  final String title;
  final String? message;
  final String? initialValue;
  final String? hintText;
  final String confirmLabel;
  final String cancelLabel;
  final TextInputType keyboardType;
  final int? maxLines;
  final String? Function(String?)? validator;

  const HoorInputDialog({
    super.key,
    required this.title,
    this.message,
    this.initialValue,
    this.hintText,
    this.confirmLabel = 'تأكيد',
    this.cancelLabel = 'إلغاء',
    this.keyboardType = TextInputType.text,
    this.maxLines = 1,
    this.validator,
  });

  static Future<String?> show(
    BuildContext context, {
    required String title,
    String? message,
    String? initialValue,
    String? hintText,
    String confirmLabel = 'تأكيد',
    String cancelLabel = 'إلغاء',
    TextInputType keyboardType = TextInputType.text,
    int? maxLines = 1,
    String? Function(String?)? validator,
  }) {
    return showDialog<String>(
      context: context,
      builder: (context) => HoorInputDialog(
        title: title,
        message: message,
        initialValue: initialValue,
        hintText: hintText,
        confirmLabel: confirmLabel,
        cancelLabel: cancelLabel,
        keyboardType: keyboardType,
        maxLines: maxLines,
        validator: validator,
      ),
    );
  }

  @override
  State<HoorInputDialog> createState() => _HoorInputDialogState();
}

class _HoorInputDialogState extends State<HoorInputDialog> {
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
        borderRadius: BorderRadius.circular(HoorRadius.xl),
      ),
      backgroundColor: HoorColors.surface,
      child: Padding(
        padding: EdgeInsets.all(HoorSpacing.lg),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                widget.title,
                style: HoorTypography.titleLarge,
              ),
              if (widget.message != null) ...[
                SizedBox(height: HoorSpacing.xs),
                Text(
                  widget.message!,
                  style: HoorTypography.bodyMedium.copyWith(
                    color: HoorColors.textSecondary,
                  ),
                ),
              ],
              SizedBox(height: HoorSpacing.lg),
              TextFormField(
                controller: _controller,
                keyboardType: widget.keyboardType,
                maxLines: widget.maxLines,
                validator: widget.validator,
                decoration: InputDecoration(
                  hintText: widget.hintText,
                  filled: true,
                  fillColor: HoorColors.background,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(HoorRadius.md),
                    borderSide: BorderSide.none,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(HoorRadius.md),
                    borderSide: BorderSide(
                      color: HoorColors.border,
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(HoorRadius.md),
                    borderSide: BorderSide(
                      color: HoorColors.primary,
                      width: 2.w,
                    ),
                  ),
                ),
              ),
              SizedBox(height: HoorSpacing.lg),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      style: OutlinedButton.styleFrom(
                        minimumSize: Size(0, 48.h),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(HoorRadius.md),
                        ),
                      ),
                      child: Text(widget.cancelLabel),
                    ),
                  ),
                  SizedBox(width: HoorSpacing.sm),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        if (_formKey.currentState?.validate() ?? false) {
                          Navigator.of(context).pop(_controller.text);
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        minimumSize: Size(0, 48.h),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(HoorRadius.md),
                        ),
                      ),
                      child: Text(widget.confirmLabel),
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
