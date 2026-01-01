// ═══════════════════════════════════════════════════════════════════════════
// Search Field Component
// Optimized search input for filtering lists and finding records
// ═══════════════════════════════════════════════════════════════════════════

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../theme/pro/design_tokens.dart';

class SearchField extends StatefulWidget {
  const SearchField({
    super.key,
    this.controller,
    this.hintText = 'ابحث...',
    this.onChanged,
    this.onSubmitted,
    this.onClear,
    this.autofocus = false,
    this.showFilterButton = false,
    this.onFilterTap,
    this.filterActive = false,
    this.prefixIcon,
    this.enabled = true,
  });

  final TextEditingController? controller;
  final String hintText;
  final void Function(String)? onChanged;
  final void Function(String)? onSubmitted;
  final VoidCallback? onClear;
  final bool autofocus;
  final bool showFilterButton;
  final VoidCallback? onFilterTap;
  final bool filterActive;
  final IconData? prefixIcon;
  final bool enabled;

  @override
  State<SearchField> createState() => _SearchFieldState();
}

class _SearchFieldState extends State<SearchField> {
  late TextEditingController _controller;
  late FocusNode _focusNode;
  bool _hasText = false;

  @override
  void initState() {
    super.initState();
    _controller = widget.controller ?? TextEditingController();
    _focusNode = FocusNode();
    _hasText = _controller.text.isNotEmpty;

    _controller.addListener(_onTextChanged);
  }

  @override
  void dispose() {
    _controller.removeListener(_onTextChanged);
    if (widget.controller == null) {
      _controller.dispose();
    }
    _focusNode.dispose();
    super.dispose();
  }

  void _onTextChanged() {
    final hasText = _controller.text.isNotEmpty;
    if (hasText != _hasText) {
      setState(() => _hasText = hasText);
    }
    widget.onChanged?.call(_controller.text);
  }

  void _handleClear() {
    HapticFeedback.lightImpact();
    _controller.clear();
    widget.onClear?.call();
    _focusNode.requestFocus();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceMuted,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          // Search Icon
          Padding(
            padding: EdgeInsets.only(left: AppSpacing.md.w),
            child: Icon(
              widget.prefixIcon ?? Icons.search_rounded,
              color: AppColors.textTertiary,
              size: AppIconSize.md,
            ),
          ),

          // Text Field
          Expanded(
            child: TextField(
              controller: _controller,
              focusNode: _focusNode,
              autofocus: widget.autofocus,
              enabled: widget.enabled,
              textInputAction: TextInputAction.search,
              style: AppTypography.bodyMedium.copyWith(
                color: AppColors.textPrimary,
              ),
              decoration: InputDecoration(
                hintText: widget.hintText,
                hintStyle: AppTypography.bodyMedium.copyWith(
                  color: AppColors.textTertiary,
                ),
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(
                  horizontal: AppSpacing.sm.w,
                  vertical: AppSpacing.md.h,
                ),
              ),
              onSubmitted: widget.onSubmitted,
            ),
          ),

          // Clear Button
          if (_hasText)
            _buildIconButton(
              icon: Icons.close_rounded,
              onTap: _handleClear,
            ),

          // Filter Button
          if (widget.showFilterButton)
            _buildIconButton(
              icon: Icons.tune_rounded,
              onTap: widget.onFilterTap,
              isActive: widget.filterActive,
            ),
        ],
      ),
    );
  }

  Widget _buildIconButton({
    required IconData icon,
    VoidCallback? onTap,
    bool isActive = false,
  }) {
    return Material(
      color: isActive
          ? AppColors.secondary.withValues(alpha: 0.1)
          : Colors.transparent,
      borderRadius: BorderRadius.circular(AppRadius.md),
      child: InkWell(
        onTap: () {
          HapticFeedback.lightImpact();
          onTap?.call();
        },
        borderRadius: BorderRadius.circular(AppRadius.md),
        child: Padding(
          padding: EdgeInsets.all(AppSpacing.sm.w),
          child: Icon(
            icon,
            color: isActive ? AppColors.secondary : AppColors.textTertiary,
            size: AppIconSize.md,
          ),
        ),
      ),
    );
  }
}

/// Compact search button that expands into a search field
class SearchButton extends StatefulWidget {
  const SearchButton({
    super.key,
    required this.onSearch,
    this.hintText = 'ابحث...',
  });

  final void Function(String) onSearch;
  final String hintText;

  @override
  State<SearchButton> createState() => _SearchButtonState();
}

class _SearchButtonState extends State<SearchButton>
    with SingleTickerProviderStateMixin {
  bool _isExpanded = false;
  late AnimationController _controller;
  late Animation<double> _widthAnimation;
  final _textController = TextEditingController();
  final _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: AppDurations.normal,
      vsync: this,
    );
    _widthAnimation = CurvedAnimation(
      parent: _controller,
      curve: AppCurves.enter,
    );

    _focusNode.addListener(() {
      if (!_focusNode.hasFocus && _textController.text.isEmpty) {
        _collapse();
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _textController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _expand() {
    setState(() => _isExpanded = true);
    _controller.forward();
    _focusNode.requestFocus();
  }

  void _collapse() {
    _focusNode.unfocus();
    _controller.reverse().then((_) {
      setState(() => _isExpanded = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _widthAnimation,
      builder: (context, child) {
        return Container(
          width: _isExpanded ? 200.w * _widthAnimation.value + 44.w : 44.w,
          height: 44.h,
          decoration: BoxDecoration(
            color: AppColors.surfaceMuted,
            borderRadius: BorderRadius.circular(AppRadius.lg),
            border: Border.all(color: AppColors.border),
          ),
          child: _isExpanded
              ? Row(
                  children: [
                    Padding(
                      padding: EdgeInsets.only(left: AppSpacing.sm.w),
                      child: Icon(
                        Icons.search_rounded,
                        color: AppColors.textTertiary,
                        size: AppIconSize.md,
                      ),
                    ),
                    Expanded(
                      child: TextField(
                        controller: _textController,
                        focusNode: _focusNode,
                        style: AppTypography.bodyMedium,
                        decoration: InputDecoration(
                          hintText: widget.hintText,
                          hintStyle: AppTypography.bodyMedium.copyWith(
                            color: AppColors.textTertiary,
                          ),
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: AppSpacing.xs.w,
                            vertical: AppSpacing.sm.h,
                          ),
                        ),
                        onChanged: widget.onSearch,
                        onSubmitted: widget.onSearch,
                      ),
                    ),
                    IconButton(
                      icon: Icon(
                        Icons.close_rounded,
                        size: AppIconSize.sm,
                        color: AppColors.textTertiary,
                      ),
                      onPressed: () {
                        _textController.clear();
                        widget.onSearch('');
                        _collapse();
                      },
                    ),
                  ],
                )
              : IconButton(
                  icon: Icon(
                    Icons.search_rounded,
                    color: AppColors.textSecondary,
                    size: AppIconSize.md,
                  ),
                  onPressed: _expand,
                ),
        );
      },
    );
  }
}
