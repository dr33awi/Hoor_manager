import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../design_tokens.dart';
import '../typography.dart';

/// ═══════════════════════════════════════════════════════════════════════════
/// HoorBottomSheet - Premium Animated Bottom Sheet Components
/// ═══════════════════════════════════════════════════════════════════════════

class HoorBottomSheet extends StatelessWidget {
  final String? title;
  final Widget child;
  final List<Widget>? actions;
  final bool showHandle;
  final bool showCloseButton;
  final double? maxHeight;
  final bool enableGlassmorphism;

  const HoorBottomSheet({
    super.key,
    this.title,
    required this.child,
    this.actions,
    this.showHandle = true,
    this.showCloseButton = false,
    this.maxHeight,
    this.enableGlassmorphism = false,
  });

  static Future<T?> show<T>(
    BuildContext context, {
    required Widget child,
    String? title,
    List<Widget>? actions,
    bool showHandle = true,
    bool showCloseButton = false,
    double? maxHeight,
    bool isDismissible = true,
    bool enableDrag = true,
    bool isScrollControlled = true,
    bool enableGlassmorphism = false,
  }) {
    return showModalBottomSheet<T>(
      context: context,
      isDismissible: isDismissible,
      enableDrag: enableDrag,
      isScrollControlled: isScrollControlled,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.5),
      transitionAnimationController: AnimationController(
        vsync: Navigator.of(context),
        duration: HoorDurations.normal,
      ),
      builder: (context) => HoorBottomSheet(
        title: title,
        actions: actions,
        showHandle: showHandle,
        showCloseButton: showCloseButton,
        maxHeight: maxHeight,
        enableGlassmorphism: enableGlassmorphism,
        child: child,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final effectiveMaxHeight =
        maxHeight ?? MediaQuery.of(context).size.height * 0.85;

    return Container(
      constraints: BoxConstraints(maxHeight: effectiveMaxHeight),
      decoration: BoxDecoration(
        color: enableGlassmorphism
            ? HoorColors.glassBackground
            : HoorColors.surface,
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(HoorRadius.xxl),
        ),
        border: enableGlassmorphism
            ? Border.all(color: HoorColors.glassBorder)
            : null,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 20,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle
          if (showHandle)
            Container(
              margin: EdgeInsets.only(top: HoorSpacing.md.h),
              width: 48.w,
              height: 5.h,
              decoration: BoxDecoration(
                color: HoorColors.textTertiary.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(HoorRadius.full),
              ),
            ),

          // Header
          if (title != null || showCloseButton)
            Padding(
              padding: EdgeInsets.fromLTRB(
                HoorSpacing.xl.w,
                HoorSpacing.lg.h,
                HoorSpacing.lg.w,
                HoorSpacing.sm.h,
              ),
              child: Row(
                children: [
                  if (title != null)
                    Expanded(
                      child: Text(
                        title!,
                        style: HoorTypography.headlineSmall.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  if (showCloseButton)
                    Container(
                      decoration: BoxDecoration(
                        color: HoorColors.surfaceMuted,
                        shape: BoxShape.circle,
                      ),
                      child: IconButton(
                        onPressed: () => Navigator.of(context).pop(),
                        icon: const Icon(Icons.close_rounded),
                        iconSize: HoorIconSize.md,
                        color: HoorColors.textSecondary,
                      ),
                    ),
                ],
              ),
            ),

          // Content
          Flexible(child: child),

          // Actions
          if (actions != null && actions!.isNotEmpty)
            SafeArea(
              child: Container(
                padding: EdgeInsets.all(HoorSpacing.lg.w),
                decoration: BoxDecoration(
                  color: enableGlassmorphism
                      ? Colors.transparent
                      : HoorColors.surface,
                  border: Border(
                    top: BorderSide(
                      color: HoorColors.border.withValues(alpha: 0.5),
                    ),
                  ),
                ),
                child: Row(
                  children: actions!.map((action) {
                    final index = actions!.indexOf(action);
                    return Expanded(
                      child: Padding(
                        padding: EdgeInsets.only(
                          right: index < actions!.length - 1
                              ? HoorSpacing.md.w
                              : 0,
                        ),
                        child: action,
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// ═══════════════════════════════════════════════════════════════════════════
/// HoorActionSheet - iOS-style action sheet
/// ═══════════════════════════════════════════════════════════════════════════

class HoorActionSheet extends StatelessWidget {
  final String? title;
  final String? message;
  final List<HoorActionSheetItem> actions;
  final String cancelLabel;

  const HoorActionSheet({
    super.key,
    this.title,
    this.message,
    required this.actions,
    this.cancelLabel = 'إلغاء',
  });

  static Future<T?> show<T>(
    BuildContext context, {
    String? title,
    String? message,
    required List<HoorActionSheetItem> actions,
    String cancelLabel = 'إلغاء',
  }) {
    return showModalBottomSheet<T>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => HoorActionSheet(
        title: title,
        message: message,
        actions: actions,
        cancelLabel: cancelLabel,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.all(HoorSpacing.md.w),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Actions Card
            Container(
              decoration: BoxDecoration(
                color: HoorColors.surface,
                borderRadius: BorderRadius.circular(HoorRadius.lg),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Header
                  if (title != null || message != null)
                    Padding(
                      padding: EdgeInsets.all(HoorSpacing.md.w),
                      child: Column(
                        children: [
                          if (title != null)
                            Text(
                              title!,
                              style: HoorTypography.titleMedium,
                              textAlign: TextAlign.center,
                            ),
                          if (message != null) ...[
                            SizedBox(height: HoorSpacing.xs.h),
                            Text(
                              message!,
                              style: HoorTypography.bodySmall.copyWith(
                                color: HoorColors.textSecondary,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ],
                      ),
                    ),

                  if (title != null || message != null)
                    Divider(height: 1.h, color: HoorColors.border),

                  // Actions
                  ...actions.map((action) {
                    final index = actions.indexOf(action);
                    return Column(
                      children: [
                        _ActionItem(action: action),
                        if (index < actions.length - 1)
                          Divider(height: 1.h, color: HoorColors.border),
                      ],
                    );
                  }),
                ],
              ),
            ),

            SizedBox(height: HoorSpacing.sm.h),

            // Cancel Button
            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: HoorColors.surface,
                borderRadius: BorderRadius.circular(HoorRadius.lg),
              ),
              child: TextButton(
                onPressed: () => Navigator.of(context).pop(),
                style: TextButton.styleFrom(
                  padding: EdgeInsets.all(HoorSpacing.md.w),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(HoorRadius.lg),
                  ),
                ),
                child: Text(
                  cancelLabel,
                  style: HoorTypography.titleMedium.copyWith(
                    color: HoorColors.primary,
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

class _ActionItem extends StatefulWidget {
  final HoorActionSheetItem action;

  const _ActionItem({required this.action});

  @override
  State<_ActionItem> createState() => _ActionItemState();
}

class _ActionItemState extends State<_ActionItem> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final color = widget.action.isDestructive
        ? HoorColors.error
        : widget.action.color ?? HoorColors.textPrimary;

    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) => setState(() => _isPressed = false),
      onTapCancel: () => setState(() => _isPressed = false),
      onTap: () {
        Navigator.of(context).pop(widget.action.value);
        widget.action.onTap?.call();
      },
      child: AnimatedContainer(
        duration: HoorDurations.fast,
        color: _isPressed ? HoorColors.surfaceMuted : Colors.transparent,
        padding: EdgeInsets.all(HoorSpacing.lg.w),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (widget.action.icon != null) ...[
              Icon(widget.action.icon, color: color, size: HoorIconSize.md),
              SizedBox(width: HoorSpacing.sm.w),
            ],
            Text(
              widget.action.label,
              style: HoorTypography.titleMedium.copyWith(
                color: color,
                fontWeight: widget.action.isDestructive
                    ? FontWeight.w600
                    : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class HoorActionSheetItem {
  final String label;
  final IconData? icon;
  final VoidCallback? onTap;
  final Color? color;
  final bool isDestructive;
  final dynamic value;

  const HoorActionSheetItem({
    required this.label,
    this.icon,
    this.onTap,
    this.color,
    this.isDestructive = false,
    this.value,
  });
}

/// ═══════════════════════════════════════════════════════════════════════════
/// HoorSelectSheet - Selection bottom sheet
/// ═══════════════════════════════════════════════════════════════════════════

class HoorSelectSheet<T> extends StatelessWidget {
  final String title;
  final List<HoorSelectOption<T>> options;
  final T? selectedValue;
  final bool showSearch;

  const HoorSelectSheet({
    super.key,
    required this.title,
    required this.options,
    this.selectedValue,
    this.showSearch = false,
  });

  static Future<T?> show<T>(
    BuildContext context, {
    required String title,
    required List<HoorSelectOption<T>> options,
    T? selectedValue,
    bool showSearch = false,
  }) {
    return showModalBottomSheet<T>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => HoorSelectSheet<T>(
        title: title,
        options: options,
        selectedValue: selectedValue,
        showSearch: showSearch,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return HoorBottomSheet(
      title: title,
      showCloseButton: true,
      maxHeight: MediaQuery.of(context).size.height * 0.6,
      child: ListView.builder(
        shrinkWrap: true,
        padding: EdgeInsets.symmetric(vertical: HoorSpacing.sm.h),
        itemCount: options.length,
        itemBuilder: (context, index) {
          final option = options[index];
          final isSelected = option.value == selectedValue;

          return Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () => Navigator.of(context).pop(option.value),
              child: Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: HoorSpacing.lg.w,
                  vertical: HoorSpacing.md.h,
                ),
                child: Row(
                  children: [
                    if (option.icon != null) ...[
                      Icon(
                        option.icon,
                        size: HoorIconSize.md,
                        color: isSelected
                            ? HoorColors.primary
                            : HoorColors.textSecondary,
                      ),
                      SizedBox(width: HoorSpacing.md.w),
                    ],
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            option.label,
                            style: HoorTypography.bodyLarge.copyWith(
                              color: isSelected
                                  ? HoorColors.primary
                                  : HoorColors.textPrimary,
                              fontWeight: isSelected
                                  ? FontWeight.w600
                                  : FontWeight.normal,
                            ),
                          ),
                          if (option.subtitle != null) ...[
                            SizedBox(height: 2.h),
                            Text(
                              option.subtitle!,
                              style: HoorTypography.bodySmall.copyWith(
                                color: HoorColors.textSecondary,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    if (isSelected)
                      Icon(
                        Icons.check,
                        color: HoorColors.primary,
                        size: HoorIconSize.md,
                      ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class HoorSelectOption<T> {
  final T value;
  final String label;
  final String? subtitle;
  final IconData? icon;

  const HoorSelectOption({
    required this.value,
    required this.label,
    this.subtitle,
    this.icon,
  });
}
