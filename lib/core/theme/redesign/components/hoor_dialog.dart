import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../design_tokens.dart';
import '../typography.dart';

/// ═══════════════════════════════════════════════════════════════════════════
/// HoorDialog - Premium Animated Dialog Components
/// ═══════════════════════════════════════════════════════════════════════════

class HoorDialog extends StatefulWidget {
  final String? title;
  final String? message;
  final Widget? content;
  final List<HoorDialogAction>? actions;
  final IconData? icon;
  final Color? iconColor;
  final bool showCloseButton;
  final bool enableGlassmorphism;

  const HoorDialog({
    super.key,
    this.title,
    this.message,
    this.content,
    this.actions,
    this.icon,
    this.iconColor,
    this.showCloseButton = false,
    this.enableGlassmorphism = false,
  });

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
      barrierColor: Colors.black.withValues(alpha: 0.5),
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

  @override
  State<HoorDialog> createState() => _HoorDialogState();
}

class _HoorDialogState extends State<HoorDialog>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: HoorDurations.normal,
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 0.85, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutBack),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Opacity(
          opacity: _fadeAnimation.value,
          child: Transform.scale(
            scale: _scaleAnimation.value,
            child: Dialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(HoorRadius.xxl),
              ),
              backgroundColor: widget.enableGlassmorphism
                  ? HoorColors.glassBackground
                  : HoorColors.surface,
              elevation: 0,
              child: Container(
                constraints: BoxConstraints(maxWidth: 340.w),
                padding: EdgeInsets.all(HoorSpacing.xl),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(HoorRadius.xxl),
                  border: widget.enableGlassmorphism
                      ? Border.all(color: HoorColors.glassBorder)
                      : null,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.15),
                      blurRadius: 30,
                      spreadRadius: 5,
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Header with close button
                    if (widget.showCloseButton)
                      Align(
                        alignment: Alignment.topLeft,
                        child: Container(
                          decoration: BoxDecoration(
                            color: HoorColors.surfaceMuted,
                            shape: BoxShape.circle,
                          ),
                          child: IconButton(
                            icon: const Icon(Icons.close_rounded),
                            onPressed: () => Navigator.of(context).pop(),
                            iconSize: HoorIconSize.sm,
                            color: HoorColors.textSecondary,
                          ),
                        ),
                      ),

                    // Icon with animated container
                    if (widget.icon != null) ...[
                      TweenAnimationBuilder<double>(
                        tween: Tween(begin: 0.0, end: 1.0),
                        duration: const Duration(milliseconds: 400),
                        curve: Curves.elasticOut,
                        builder: (context, value, child) {
                          return Transform.scale(
                            scale: value,
                            child: Container(
                              padding: EdgeInsets.all(HoorSpacing.lg),
                              decoration: BoxDecoration(
                                gradient: RadialGradient(
                                  colors: [
                                    (widget.iconColor ?? HoorColors.primary)
                                        .withValues(alpha: 0.15),
                                    (widget.iconColor ?? HoorColors.primary)
                                        .withValues(alpha: 0.05),
                                  ],
                                ),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                widget.icon,
                                size: HoorIconSize.xxl,
                                color: widget.iconColor ?? HoorColors.primary,
                              ),
                            ),
                          );
                        },
                      ),
                      SizedBox(height: HoorSpacing.xl),
                    ],

                    // Title
                    if (widget.title != null) ...[
                      Text(
                        widget.title!,
                        style: HoorTypography.headlineSmall.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      SizedBox(height: HoorSpacing.sm),
                    ],

                    // Message
                    if (widget.message != null) ...[
                      Text(
                        widget.message!,
                        style: HoorTypography.bodyMedium.copyWith(
                          color: HoorColors.textSecondary,
                          height: 1.5,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      SizedBox(height: HoorSpacing.lg),
                    ],

                    // Custom content
                    if (widget.content != null) ...[
                      widget.content!,
                      SizedBox(height: HoorSpacing.lg),
                    ],

                    // Actions
                    if (widget.actions != null &&
                        widget.actions!.isNotEmpty) ...[
                      SizedBox(height: HoorSpacing.md),
                      Row(
                        children: widget.actions!.map((action) {
                          return Expanded(
                            child: Padding(
                              padding: EdgeInsets.only(
                                right: action != widget.actions!.last
                                    ? HoorSpacing.sm
                                    : 0,
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
            ),
          ),
        );
      },
    );
  }

  Widget _buildActionButton(BuildContext context, HoorDialogAction action) {
    switch (action.type) {
      case HoorDialogActionType.primary:
        return _AnimatedDialogButton(
          label: action.label,
          onPressed: () {
            action.onPressed?.call();
            if (action.dismissOnTap) Navigator.of(context).pop(action.value);
          },
          backgroundColor: action.color ?? HoorColors.primary,
          foregroundColor: HoorColors.textOnPrimary,
        );
      case HoorDialogActionType.secondary:
        return _AnimatedDialogButton(
          label: action.label,
          onPressed: () {
            action.onPressed?.call();
            if (action.dismissOnTap) Navigator.of(context).pop(action.value);
          },
          backgroundColor: Colors.transparent,
          foregroundColor: action.color ?? HoorColors.primary,
          borderColor: action.color ?? HoorColors.primary,
        );
      case HoorDialogActionType.destructive:
        return _AnimatedDialogButton(
          label: action.label,
          onPressed: () {
            action.onPressed?.call();
            if (action.dismissOnTap) Navigator.of(context).pop(action.value);
          },
          backgroundColor: HoorColors.error,
          foregroundColor: Colors.white,
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

/// ═══════════════════════════════════════════════════════════════════════════
/// Animated Dialog Button
/// ═══════════════════════════════════════════════════════════════════════════

class _AnimatedDialogButton extends StatefulWidget {
  final String label;
  final VoidCallback onPressed;
  final Color backgroundColor;
  final Color foregroundColor;
  final Color? borderColor;

  const _AnimatedDialogButton({
    required this.label,
    required this.onPressed,
    required this.backgroundColor,
    required this.foregroundColor,
    this.borderColor,
  });

  @override
  State<_AnimatedDialogButton> createState() => _AnimatedDialogButtonState();
}

class _AnimatedDialogButtonState extends State<_AnimatedDialogButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  bool _isPressed = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 100),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onTapDown(TapDownDetails details) {
    setState(() => _isPressed = true);
    _controller.forward();
  }

  void _onTapUp(TapUpDetails details) {
    setState(() => _isPressed = false);
    _controller.reverse();
    widget.onPressed();
  }

  void _onTapCancel() {
    setState(() => _isPressed = false);
    _controller.reverse();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: _onTapDown,
      onTapUp: _onTapUp,
      onTapCancel: _onTapCancel,
      child: AnimatedBuilder(
        animation: _scaleAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: AnimatedContainer(
              duration: HoorDurations.fast,
              height: 52.h,
              decoration: BoxDecoration(
                color: _isPressed
                    ? widget.backgroundColor.withValues(alpha: 0.85)
                    : widget.backgroundColor,
                borderRadius: BorderRadius.circular(HoorRadius.lg),
                border: widget.borderColor != null
                    ? Border.all(color: widget.borderColor!)
                    : null,
                boxShadow: widget.backgroundColor != Colors.transparent
                    ? [
                        BoxShadow(
                          color: widget.backgroundColor
                              .withValues(alpha: _isPressed ? 0.2 : 0.3),
                          blurRadius: _isPressed ? 4 : 8,
                          offset: Offset(0, _isPressed ? 2 : 4),
                        ),
                      ]
                    : null,
              ),
              child: Center(
                child: Text(
                  widget.label,
                  style: HoorTypography.titleSmall.copyWith(
                    color: widget.foregroundColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
