// ═══════════════════════════════════════════════════════════════════════════
// Pro Search Field Component
// Advanced Search with Filters & Suggestions
// ═══════════════════════════════════════════════════════════════════════════

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../theme/design_tokens.dart';

class ProSearchField extends StatefulWidget {
  final String? hintText;
  final TextEditingController? controller;
  final ValueChanged<String>? onChanged;
  final VoidCallback? onFilterTap;
  final bool showFilterButton;
  final bool hasActiveFilters;
  final FocusNode? focusNode;
  final bool autofocus;
  final List<String>? suggestions;
  final ValueChanged<String>? onSuggestionSelected;

  const ProSearchField({
    super.key,
    this.hintText,
    this.controller,
    this.onChanged,
    this.onFilterTap,
    this.showFilterButton = true,
    this.hasActiveFilters = false,
    this.focusNode,
    this.autofocus = false,
    this.suggestions,
    this.onSuggestionSelected,
  });

  @override
  State<ProSearchField> createState() => _ProSearchFieldState();
}

class _ProSearchFieldState extends State<ProSearchField> {
  late TextEditingController _controller;
  late FocusNode _focusNode;
  bool _showClear = false;
  // ignore: unused_field
  bool _showSuggestions = false;
  OverlayEntry? _overlayEntry;
  final LayerLink _layerLink = LayerLink();

  @override
  void initState() {
    super.initState();
    _controller = widget.controller ?? TextEditingController();
    _focusNode = widget.focusNode ?? FocusNode();
    _controller.addListener(_onTextChanged);
    _focusNode.addListener(_onFocusChanged);
  }

  @override
  void dispose() {
    if (widget.controller == null) _controller.dispose();
    if (widget.focusNode == null) _focusNode.dispose();
    _removeOverlay();
    super.dispose();
  }

  void _onTextChanged() {
    setState(() {
      _showClear = _controller.text.isNotEmpty;
    });
    widget.onChanged?.call(_controller.text);
    _updateSuggestions();
  }

  void _onFocusChanged() {
    if (_focusNode.hasFocus && widget.suggestions != null) {
      _showSuggestionsOverlay();
    } else {
      _removeOverlay();
    }
  }

  void _updateSuggestions() {
    if (_focusNode.hasFocus && widget.suggestions != null) {
      _showSuggestionsOverlay();
    }
  }

  void _showSuggestionsOverlay() {
    _removeOverlay();
    if (widget.suggestions == null || widget.suggestions!.isEmpty) return;

    final filteredSuggestions = widget.suggestions!
        .where((s) => s.contains(_controller.text.toLowerCase()))
        .take(5)
        .toList();

    if (filteredSuggestions.isEmpty) return;

    _overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        width: MediaQuery.of(context).size.width - (AppSpacing.md * 2),
        child: CompositedTransformFollower(
          link: _layerLink,
          showWhenUnlinked: false,
          offset: Offset(0, 56.h),
          child: Material(
            elevation: 8,
            borderRadius: BorderRadius.circular(AppRadius.md),
            child: Container(
              constraints: BoxConstraints(maxHeight: 200.h),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(AppRadius.md),
                border: Border.all(color: AppColors.border),
              ),
              child: ListView.builder(
                shrinkWrap: true,
                padding: EdgeInsets.zero,
                itemCount: filteredSuggestions.length,
                itemBuilder: (context, index) {
                  final suggestion = filteredSuggestions[index];
                  return ListTile(
                    dense: true,
                    title: Text(
                      suggestion,
                      style: AppTypography.bodyMedium,
                    ),
                    onTap: () {
                      _controller.text = suggestion;
                      widget.onSuggestionSelected?.call(suggestion);
                      _removeOverlay();
                    },
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );

    Overlay.of(context).insert(_overlayEntry!);
    _showSuggestions = true;
  }

  void _removeOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
    _showSuggestions = false;
  }

  void _clearSearch() {
    _controller.clear();
    widget.onChanged?.call('');
  }

  @override
  Widget build(BuildContext context) {
    return CompositedTransformTarget(
      link: _layerLink,
      child: Container(
        height: 52.h,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          border: Border.all(color: AppColors.border),
          boxShadow: AppShadows.sm,
        ),
        child: Row(
          children: [
            SizedBox(width: AppSpacing.md),
            Icon(
              Icons.search,
              color: AppColors.textTertiary,
              size: AppIconSize.md,
            ),
            SizedBox(width: AppSpacing.sm),
            Expanded(
              child: TextField(
                controller: _controller,
                focusNode: _focusNode,
                autofocus: widget.autofocus,
                style: AppTypography.bodyMedium,
                decoration: InputDecoration(
                  hintText: widget.hintText ?? 'بحث...',
                  hintStyle: AppTypography.bodyMedium.copyWith(
                    color: AppColors.textTertiary,
                  ),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.zero,
                  isDense: true,
                ),
              ),
            ),
            if (_showClear) ...[
              IconButton(
                onPressed: _clearSearch,
                icon: Icon(
                  Icons.close,
                  color: AppColors.textTertiary,
                  size: AppIconSize.sm,
                ),
                splashRadius: 20.r,
              ),
            ],
            if (widget.showFilterButton) ...[
              Container(
                width: 1,
                height: 24.h,
                color: AppColors.border,
              ),
              Stack(
                clipBehavior: Clip.none,
                children: [
                  IconButton(
                    onPressed: widget.onFilterTap,
                    icon: Icon(
                      Icons.tune,
                      color: widget.hasActiveFilters
                          ? AppColors.primary
                          : AppColors.textSecondary,
                      size: AppIconSize.md,
                    ),
                    splashRadius: 20.r,
                  ),
                  if (widget.hasActiveFilters)
                    Positioned(
                      top: 8,
                      right: 8,
                      child: Container(
                        width: 8.w,
                        height: 8.h,
                        decoration: const BoxDecoration(
                          color: AppColors.error,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                ],
              ),
            ],
            SizedBox(width: AppSpacing.xs),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// Filter Chip Pro
// ═══════════════════════════════════════════════════════════════════════════

class ProFilterChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  final IconData? icon;
  final Color? selectedColor;

  const ProFilterChip({
    super.key,
    required this.label,
    required this.isSelected,
    required this.onTap,
    this.icon,
    this.selectedColor,
  });

  @override
  Widget build(BuildContext context) {
    final color = selectedColor ?? AppColors.primary;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        decoration: BoxDecoration(
          color: isSelected ? color.withValues(alpha: 0.1) : Colors.white,
          borderRadius: BorderRadius.circular(AppRadius.full),
          border: Border.all(
            color: isSelected ? color : AppColors.border,
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(
                icon,
                size: 16.sp,
                color: isSelected ? color : AppColors.textSecondary,
              ),
              SizedBox(width: AppSpacing.xs),
            ],
            Text(
              label,
              style: AppTypography.labelMedium.copyWith(
                color: isSelected ? color : AppColors.textSecondary,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
            if (isSelected) ...[
              SizedBox(width: AppSpacing.xs),
              Icon(
                Icons.check,
                size: 14.sp,
                color: color,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// Filter Sheet
// ═══════════════════════════════════════════════════════════════════════════

class ProFilterSheet extends StatelessWidget {
  final String title;
  final List<Widget> children;
  final VoidCallback? onApply;
  final VoidCallback? onReset;

  const ProFilterSheet({
    super.key,
    required this.title,
    required this.children,
    this.onApply,
    this.onReset,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppRadius.xl),
        ),
      ),
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

          // Header
          Padding(
            padding: EdgeInsets.all(AppSpacing.lg),
            child: Row(
              children: [
                Text(
                  title,
                  style: AppTypography.titleLarge,
                ),
                const Spacer(),
                if (onReset != null)
                  TextButton(
                    onPressed: onReset,
                    child: Text(
                      'إعادة تعيين',
                      style: AppTypography.labelMedium.copyWith(
                        color: AppColors.error,
                      ),
                    ),
                  ),
              ],
            ),
          ),

          Divider(height: 1, color: AppColors.border),

          // Content
          Flexible(
            child: SingleChildScrollView(
              padding: EdgeInsets.all(AppSpacing.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: children,
              ),
            ),
          ),

          // Actions
          Padding(
            padding: EdgeInsets.all(AppSpacing.lg),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      padding: EdgeInsets.symmetric(vertical: AppSpacing.md),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppRadius.md),
                      ),
                    ),
                    child: Text('إلغاء'),
                  ),
                ),
                SizedBox(width: AppSpacing.md),
                Expanded(
                  flex: 2,
                  child: ElevatedButton(
                    onPressed: () {
                      onApply?.call();
                      Navigator.pop(context);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      padding: EdgeInsets.symmetric(vertical: AppSpacing.md),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppRadius.md),
                      ),
                    ),
                    child: Text('تطبيق الفلاتر'),
                  ),
                ),
              ],
            ),
          ),

          SizedBox(height: MediaQuery.of(context).padding.bottom),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// Date Range Picker Button
// ═══════════════════════════════════════════════════════════════════════════

class DateRangeButton extends StatelessWidget {
  final DateTimeRange? dateRange;
  final VoidCallback onTap;
  final String? label;

  const DateRangeButton({
    super.key,
    this.dateRange,
    required this.onTap,
    this.label,
  });

  String get _displayText {
    if (dateRange == null) return label ?? 'اختر الفترة';

    final start = dateRange!.start;
    final end = dateRange!.end;

    return '${start.day}/${start.month}/${start.year} - ${end.day}/${end.month}/${end.year}';
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        decoration: BoxDecoration(
          color: dateRange != null
              ? AppColors.primary.withValues(alpha: 0.1)
              : Colors.white,
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(
            color: dateRange != null ? AppColors.primary : AppColors.border,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.calendar_today_outlined,
              size: 18.sp,
              color: dateRange != null
                  ? AppColors.primary
                  : AppColors.textSecondary,
            ),
            SizedBox(width: AppSpacing.sm),
            Text(
              _displayText,
              style: AppTypography.bodyMedium.copyWith(
                color: dateRange != null
                    ? AppColors.primary
                    : AppColors.textSecondary,
              ),
            ),
            if (dateRange != null) ...[
              SizedBox(width: AppSpacing.sm),
              Icon(
                Icons.close,
                size: 16.sp,
                color: AppColors.primary,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
