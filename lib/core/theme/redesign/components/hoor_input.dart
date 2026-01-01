import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../design_tokens.dart';
import '../typography.dart';

/// ═══════════════════════════════════════════════════════════════════════════
/// HoorInput - Professional Input Components
/// Clean, accessible form inputs with validation support
/// ═══════════════════════════════════════════════════════════════════════════

class HoorTextField extends StatelessWidget {
  final String? label;
  final String? hint;
  final String? helperText;
  final String? errorText;
  final TextEditingController? controller;
  final FocusNode? focusNode;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final bool obscureText;
  final bool readOnly;
  final bool enabled;
  final bool autofocus;
  final int? maxLines;
  final int? minLines;
  final int? maxLength;
  final IconData? prefixIcon;
  final Widget? prefix;
  final Widget? suffix;
  final IconData? suffixIcon;
  final VoidCallback? onSuffixTap;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final VoidCallback? onTap;
  final FormFieldValidator<String>? validator;
  final List<TextInputFormatter>? inputFormatters;
  final AutovalidateMode? autovalidateMode;
  final TextAlign textAlign;
  final TextDirection? textDirection;

  const HoorTextField({
    super.key,
    this.label,
    this.hint,
    this.helperText,
    this.errorText,
    this.controller,
    this.focusNode,
    this.keyboardType,
    this.textInputAction,
    this.obscureText = false,
    this.readOnly = false,
    this.enabled = true,
    this.autofocus = false,
    this.maxLines = 1,
    this.minLines,
    this.maxLength,
    this.prefixIcon,
    this.prefix,
    this.suffix,
    this.suffixIcon,
    this.onSuffixTap,
    this.onChanged,
    this.onSubmitted,
    this.onTap,
    this.validator,
    this.inputFormatters,
    this.autovalidateMode,
    this.textAlign = TextAlign.start,
    this.textDirection,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (label != null) ...[
          Text(
            label!,
            style: HoorTypography.labelMedium.copyWith(
              color: HoorColors.textPrimary,
            ),
          ),
          SizedBox(height: HoorSpacing.xs),
        ],
        TextFormField(
          controller: controller,
          focusNode: focusNode,
          keyboardType: keyboardType,
          textInputAction: textInputAction,
          obscureText: obscureText,
          readOnly: readOnly,
          enabled: enabled,
          autofocus: autofocus,
          maxLines: maxLines,
          minLines: minLines,
          maxLength: maxLength,
          onChanged: onChanged,
          onFieldSubmitted: onSubmitted,
          onTap: onTap,
          validator: validator,
          inputFormatters: inputFormatters,
          autovalidateMode: autovalidateMode,
          textAlign: textAlign,
          textDirection: textDirection,
          style: HoorTypography.bodyMedium,
          decoration: InputDecoration(
            hintText: hint,
            helperText: helperText,
            errorText: errorText,
            prefixIcon: prefixIcon != null
                ? Icon(prefixIcon, size: HoorIconSize.md)
                : prefix,
            suffixIcon: _buildSuffix(),
            counterText: '',
          ),
        ),
      ],
    );
  }

  Widget? _buildSuffix() {
    if (suffix != null) return suffix;
    if (suffixIcon == null) return null;

    return IconButton(
      icon: Icon(suffixIcon, size: HoorIconSize.md),
      onPressed: onSuffixTap,
      padding: EdgeInsets.zero,
      constraints: BoxConstraints(
        minWidth: 40.w,
        minHeight: 40.w,
      ),
    );
  }
}

/// ═══════════════════════════════════════════════════════════════════════════
/// Numeric Input for Financial Data
/// ═══════════════════════════════════════════════════════════════════════════

class HoorNumericInput extends StatelessWidget {
  final String? label;
  final String? hint;
  final String? suffix;
  final TextEditingController? controller;
  final bool allowDecimal;
  final bool allowNegative;
  final double? min;
  final double? max;
  final ValueChanged<double?>? onChanged;
  final bool enabled;
  final String? errorText;
  final bool showCurrency;
  final String currencySymbol;

  const HoorNumericInput({
    super.key,
    this.label,
    this.hint,
    this.suffix,
    this.controller,
    this.allowDecimal = true,
    this.allowNegative = false,
    this.min,
    this.max,
    this.onChanged,
    this.enabled = true,
    this.errorText,
    this.showCurrency = false,
    this.currencySymbol = 'ر.س',
  });

  @override
  Widget build(BuildContext context) {
    return HoorTextField(
      label: label,
      hint: hint ?? '0.00',
      controller: controller,
      keyboardType: TextInputType.numberWithOptions(
        decimal: allowDecimal,
        signed: allowNegative,
      ),
      textAlign: TextAlign.start,
      textDirection: TextDirection.ltr,
      enabled: enabled,
      errorText: errorText,
      suffix: suffix != null || showCurrency
          ? Padding(
              padding: EdgeInsets.only(left: HoorSpacing.sm),
              child: Text(
                suffix ?? currencySymbol,
                style: HoorTypography.bodyMedium.copyWith(
                  color: HoorColors.textSecondary,
                ),
              ),
            )
          : null,
      inputFormatters: [
        FilteringTextInputFormatter.allow(
          RegExp(allowDecimal
              ? (allowNegative ? r'^-?\d*\.?\d*' : r'^\d*\.?\d*')
              : (allowNegative ? r'^-?\d*' : r'^\d*')),
        ),
      ],
      onChanged: (value) {
        if (onChanged != null) {
          final parsed = double.tryParse(value);
          onChanged!(parsed);
        }
      },
    );
  }
}

/// ═══════════════════════════════════════════════════════════════════════════
/// Search Input
/// ═══════════════════════════════════════════════════════════════════════════

class HoorSearchInput extends StatefulWidget {
  final String? hint;
  final TextEditingController? controller;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final VoidCallback? onClear;
  final bool autofocus;
  final bool showFilterButton;
  final VoidCallback? onFilterTap;

  const HoorSearchInput({
    super.key,
    this.hint,
    this.controller,
    this.onChanged,
    this.onSubmitted,
    this.onClear,
    this.autofocus = false,
    this.showFilterButton = false,
    this.onFilterTap,
  });

  @override
  State<HoorSearchInput> createState() => _HoorSearchInputState();
}

class _HoorSearchInputState extends State<HoorSearchInput> {
  late TextEditingController _controller;
  bool _hasText = false;

  @override
  void initState() {
    super.initState();
    _controller = widget.controller ?? TextEditingController();
    _hasText = _controller.text.isNotEmpty;
    _controller.addListener(_onTextChanged);
  }

  @override
  void dispose() {
    if (widget.controller == null) {
      _controller.dispose();
    }
    super.dispose();
  }

  void _onTextChanged() {
    final hasText = _controller.text.isNotEmpty;
    if (hasText != _hasText) {
      setState(() => _hasText = hasText);
    }
  }

  void _clearText() {
    _controller.clear();
    widget.onClear?.call();
    widget.onChanged?.call('');
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: HoorColors.surfaceMuted,
        borderRadius: BorderRadius.circular(HoorRadius.lg),
      ),
      child: Row(
        children: [
          Padding(
            padding:
                EdgeInsets.only(right: HoorSpacing.sm, left: HoorSpacing.md),
            child: Icon(
              Icons.search_rounded,
              color: HoorColors.textTertiary,
              size: HoorIconSize.md,
            ),
          ),
          Expanded(
            child: TextField(
              controller: _controller,
              autofocus: widget.autofocus,
              style: HoorTypography.bodyMedium,
              decoration: InputDecoration(
                hintText: widget.hint ?? 'بحث...',
                hintStyle: HoorTypography.bodyMedium.copyWith(
                  color: HoorColors.textTertiary,
                ),
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(
                  vertical: HoorSpacing.sm,
                ),
              ),
              onChanged: widget.onChanged,
              onSubmitted: widget.onSubmitted,
            ),
          ),
          if (_hasText)
            IconButton(
              icon: Icon(
                Icons.close_rounded,
                color: HoorColors.textTertiary,
                size: HoorIconSize.sm,
              ),
              onPressed: _clearText,
              padding: EdgeInsets.all(HoorSpacing.xs),
              constraints: BoxConstraints(minWidth: 36.w, minHeight: 36.w),
            ),
          if (widget.showFilterButton) ...[
            Container(
              width: 1.w,
              height: 24.h,
              color: HoorColors.border,
              margin: EdgeInsets.symmetric(horizontal: HoorSpacing.xs),
            ),
            IconButton(
              icon: Icon(
                Icons.tune_rounded,
                color: HoorColors.textSecondary,
                size: HoorIconSize.md,
              ),
              onPressed: widget.onFilterTap,
              padding: EdgeInsets.all(HoorSpacing.xs),
              constraints: BoxConstraints(minWidth: 40.w, minHeight: 40.w),
            ),
          ],
        ],
      ),
    );
  }
}

/// ═══════════════════════════════════════════════════════════════════════════
/// Dropdown Select
/// ═══════════════════════════════════════════════════════════════════════════

class HoorDropdown<T> extends StatelessWidget {
  final String? label;
  final String? hint;
  final T? value;
  final List<DropdownMenuItem<T>> items;
  final ValueChanged<T?>? onChanged;
  final bool enabled;
  final String? errorText;
  final Widget? prefix;

  const HoorDropdown({
    super.key,
    this.label,
    this.hint,
    this.value,
    required this.items,
    this.onChanged,
    this.enabled = true,
    this.errorText,
    this.prefix,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (label != null) ...[
          Text(
            label!,
            style: HoorTypography.labelMedium.copyWith(
              color: HoorColors.textPrimary,
            ),
          ),
          SizedBox(height: HoorSpacing.xs),
        ],
        DropdownButtonFormField<T>(
          initialValue: value,
          items: items,
          onChanged: enabled ? onChanged : null,
          hint: hint != null
              ? Text(
                  hint!,
                  style: HoorTypography.bodyMedium.copyWith(
                    color: HoorColors.textTertiary,
                  ),
                )
              : null,
          style: HoorTypography.bodyMedium,
          icon: Icon(
            Icons.keyboard_arrow_down_rounded,
            color: HoorColors.textSecondary,
          ),
          decoration: InputDecoration(
            errorText: errorText,
            prefixIcon: prefix,
            contentPadding: EdgeInsets.symmetric(
              horizontal: HoorSpacing.md,
              vertical: HoorSpacing.sm,
            ),
          ),
          borderRadius: HoorRadius.buttonRadius,
          dropdownColor: HoorColors.surface,
          elevation: 4,
        ),
      ],
    );
  }
}
