import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../design_tokens.dart';
import '../typography.dart';
import 'hoor_input.dart';

/// ═══════════════════════════════════════════════════════════════════════════
/// HoorSearchBar - Premium Animated Search Components
/// Modern search bars with smooth animations and filters
/// ═══════════════════════════════════════════════════════════════════════════

class HoorSearchBar extends StatefulWidget {
  final String? hint;
  final TextEditingController? controller;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final VoidCallback? onClear;
  final VoidCallback? onFilterTap;
  final bool autofocus;
  final bool showFilterButton;
  final int? filterCount;
  final bool enableGlassmorphism;

  const HoorSearchBar({
    super.key,
    this.hint,
    this.controller,
    this.onChanged,
    this.onSubmitted,
    this.onClear,
    this.onFilterTap,
    this.autofocus = false,
    this.showFilterButton = false,
    this.filterCount,
    this.enableGlassmorphism = false,
  });

  @override
  State<HoorSearchBar> createState() => _HoorSearchBarState();
}

class _HoorSearchBarState extends State<HoorSearchBar>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  bool _isFocused = false;
  final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: HoorDurations.fast,
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.02).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
    );
    _focusNode.addListener(_onFocusChange);
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _onFocusChange() {
    setState(() => _isFocused = _focusNode.hasFocus);
    if (_focusNode.hasFocus) {
      _controller.forward();
    } else {
      _controller.reverse();
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _scaleAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: AnimatedContainer(
            duration: HoorDurations.fast,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(HoorRadius.xl),
              boxShadow: _isFocused
                  ? [
                      BoxShadow(
                        color: HoorColors.primary.withValues(alpha: 0.15),
                        blurRadius: 20,
                        offset: const Offset(0, 4),
                      ),
                    ]
                  : [],
            ),
            child: Row(
              children: [
                Expanded(
                  child: HoorSearchInput(
                    hint: widget.hint ?? 'بحث...',
                    controller: widget.controller,
                    onChanged: widget.onChanged,
                    onSubmitted: widget.onSubmitted,
                    onClear: widget.onClear,
                    autofocus: widget.autofocus,
                    showFilterButton: widget.showFilterButton,
                    onFilterTap: widget.onFilterTap,
                    focusNode: _focusNode,
                  ),
                ),
                if (widget.showFilterButton &&
                    widget.filterCount != null &&
                    widget.filterCount! > 0) ...[
                  SizedBox(width: HoorSpacing.sm),
                  _AnimatedFilterButton(
                    count: widget.filterCount!,
                    onTap: widget.onFilterTap,
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}

/// Animated Filter Button
class _AnimatedFilterButton extends StatefulWidget {
  final int count;
  final VoidCallback? onTap;

  const _AnimatedFilterButton({
    required this.count,
    this.onTap,
  });

  @override
  State<_AnimatedFilterButton> createState() => _AnimatedFilterButtonState();
}

class _AnimatedFilterButtonState extends State<_AnimatedFilterButton>
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
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.9).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) {
        setState(() => _isPressed = true);
        _controller.forward();
      },
      onTapUp: (_) {
        setState(() => _isPressed = false);
        _controller.reverse();
        widget.onTap?.call();
      },
      onTapCancel: () {
        setState(() => _isPressed = false);
        _controller.reverse();
      },
      child: AnimatedBuilder(
        animation: _scaleAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: AnimatedContainer(
              duration: HoorDurations.fast,
              padding: EdgeInsets.all(HoorSpacing.sm),
              decoration: BoxDecoration(
                gradient: HoorColors.premiumGradient,
                borderRadius: BorderRadius.circular(HoorRadius.md),
                boxShadow: _isPressed
                    ? []
                    : HoorShadows.colored(HoorColors.primary, opacity: 0.3),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.filter_list_rounded,
                    color: Colors.white,
                    size: HoorIconSize.sm,
                  ),
                  SizedBox(width: 4.w),
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: HoorSpacing.xs,
                      vertical: 2.h,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.25),
                      borderRadius: BorderRadius.circular(HoorRadius.full),
                    ),
                    child: Text(
                      widget.count.toString(),
                      style: HoorTypography.labelSmall.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

/// ═══════════════════════════════════════════════════════════════════════════
/// Search with suggestions
/// ═══════════════════════════════════════════════════════════════════════════

class HoorSearchWithSuggestions<T> extends StatefulWidget {
  final String? hint;
  final TextEditingController? controller;
  final ValueChanged<String>? onChanged;
  final ValueChanged<T>? onSuggestionSelected;
  final Future<List<T>> Function(String query)? suggestionsCallback;
  final Widget Function(BuildContext context, T suggestion) suggestionBuilder;
  final bool autofocus;
  final int minCharsForSuggestions;

  const HoorSearchWithSuggestions({
    super.key,
    this.hint,
    this.controller,
    this.onChanged,
    this.onSuggestionSelected,
    this.suggestionsCallback,
    required this.suggestionBuilder,
    this.autofocus = false,
    this.minCharsForSuggestions = 2,
  });

  @override
  State<HoorSearchWithSuggestions<T>> createState() =>
      _HoorSearchWithSuggestionsState<T>();
}

class _HoorSearchWithSuggestionsState<T>
    extends State<HoorSearchWithSuggestions<T>> {
  late TextEditingController _controller;
  final LayerLink _layerLink = LayerLink();
  OverlayEntry? _overlayEntry;
  List<T> _suggestions = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _controller = widget.controller ?? TextEditingController();
    _controller.addListener(_onTextChanged);
  }

  @override
  void dispose() {
    _removeOverlay();
    if (widget.controller == null) {
      _controller.dispose();
    }
    super.dispose();
  }

  void _onTextChanged() async {
    widget.onChanged?.call(_controller.text);

    if (_controller.text.length < widget.minCharsForSuggestions) {
      _removeOverlay();
      return;
    }

    if (widget.suggestionsCallback != null) {
      setState(() => _isLoading = true);

      try {
        final suggestions = await widget.suggestionsCallback!(_controller.text);
        setState(() {
          _suggestions = suggestions;
          _isLoading = false;
        });

        if (_suggestions.isNotEmpty) {
          _showOverlay();
        } else {
          _removeOverlay();
        }
      } catch (e) {
        setState(() => _isLoading = false);
        _removeOverlay();
      }
    }
  }

  void _showOverlay() {
    _removeOverlay();

    _overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        width: context.size?.width ?? 300.w,
        child: CompositedTransformFollower(
          link: _layerLink,
          showWhenUnlinked: false,
          offset: Offset(0, 52.h),
          child: Material(
            elevation: 8,
            borderRadius: HoorRadius.cardRadius,
            color: HoorColors.surface,
            child: ConstrainedBox(
              constraints: BoxConstraints(maxHeight: 300.h),
              child: _isLoading
                  ? Center(
                      child: Padding(
                        padding: EdgeInsets.all(HoorSpacing.md),
                        child: CircularProgressIndicator(),
                      ),
                    )
                  : ListView.builder(
                      shrinkWrap: true,
                      padding: EdgeInsets.symmetric(vertical: HoorSpacing.xs),
                      itemCount: _suggestions.length,
                      itemBuilder: (context, index) {
                        return InkWell(
                          onTap: () {
                            widget.onSuggestionSelected
                                ?.call(_suggestions[index]);
                            _removeOverlay();
                          },
                          child: widget.suggestionBuilder(
                              context, _suggestions[index]),
                        );
                      },
                    ),
            ),
          ),
        ),
      ),
    );

    Overlay.of(context).insert(_overlayEntry!);
  }

  void _removeOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  @override
  Widget build(BuildContext context) {
    return CompositedTransformTarget(
      link: _layerLink,
      child: HoorSearchBar(
        hint: widget.hint,
        controller: _controller,
        autofocus: widget.autofocus,
        onClear: () {
          _controller.clear();
          _removeOverlay();
        },
      ),
    );
  }
}

/// ═══════════════════════════════════════════════════════════════════════════
/// Filter Chips Row
/// ═══════════════════════════════════════════════════════════════════════════

class HoorFilterChips<T> extends StatelessWidget {
  final List<HoorFilterChipItem<T>> items;
  final T? selectedValue;
  final ValueChanged<T?>? onSelected;
  final bool allowDeselect;
  final EdgeInsetsGeometry? padding;

  const HoorFilterChips({
    super.key,
    required this.items,
    this.selectedValue,
    this.onSelected,
    this.allowDeselect = true,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: padding ?? EdgeInsets.symmetric(horizontal: HoorSpacing.md),
      child: Row(
        children: items.map((item) {
          final isSelected = item.value == selectedValue;

          return Padding(
            padding: EdgeInsets.only(left: HoorSpacing.xs),
            child: FilterChip(
              label: Text(item.label),
              selected: isSelected,
              onSelected: (selected) {
                if (selected) {
                  onSelected?.call(item.value);
                } else if (allowDeselect) {
                  onSelected?.call(null);
                }
              },
              avatar: item.icon != null
                  ? Icon(
                      item.icon,
                      size: HoorIconSize.sm,
                      color: isSelected
                          ? HoorColors.primary
                          : HoorColors.textSecondary,
                    )
                  : null,
              labelStyle: HoorTypography.labelMedium.copyWith(
                color:
                    isSelected ? HoorColors.primary : HoorColors.textSecondary,
              ),
              backgroundColor: HoorColors.surfaceMuted,
              selectedColor: HoorColors.primarySoft,
              checkmarkColor: HoorColors.primary,
              side: BorderSide.none,
              shape: RoundedRectangleBorder(
                borderRadius: HoorRadius.chipRadius,
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class HoorFilterChipItem<T> {
  final String label;
  final T value;
  final IconData? icon;

  const HoorFilterChipItem({
    required this.label,
    required this.value,
    this.icon,
  });
}

/// ═══════════════════════════════════════════════════════════════════════════
/// Date Range Picker
/// ═══════════════════════════════════════════════════════════════════════════

class HoorDateRangeFilter extends StatelessWidget {
  final DateTimeRange? selectedRange;
  final ValueChanged<DateTimeRange?>? onRangeSelected;
  final VoidCallback? onClear;
  final String? label;

  const HoorDateRangeFilter({
    super.key,
    this.selectedRange,
    this.onRangeSelected,
    this.onClear,
    this.label,
  });

  String get _rangeText {
    if (selectedRange == null) return label ?? 'اختر الفترة';

    final start = selectedRange!.start;
    final end = selectedRange!.end;

    return '${start.day}/${start.month}/${start.year} - ${end.day}/${end.month}/${end.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _showDatePicker(context),
        borderRadius: BorderRadius.circular(HoorRadius.md),
        child: Container(
          padding: EdgeInsets.symmetric(
            horizontal: HoorSpacing.md,
            vertical: HoorSpacing.sm,
          ),
          decoration: BoxDecoration(
            color: selectedRange != null
                ? HoorColors.primarySoft
                : HoorColors.surfaceMuted,
            borderRadius: BorderRadius.circular(HoorRadius.md),
            border: selectedRange != null
                ? Border.all(color: HoorColors.primary.withValues(alpha: 0.3))
                : null,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.date_range_rounded,
                size: HoorIconSize.sm,
                color: selectedRange != null
                    ? HoorColors.primary
                    : HoorColors.textSecondary,
              ),
              SizedBox(width: HoorSpacing.xs),
              Text(
                _rangeText,
                style: HoorTypography.labelMedium.copyWith(
                  color: selectedRange != null
                      ? HoorColors.primary
                      : HoorColors.textSecondary,
                ),
              ),
              if (selectedRange != null) ...[
                SizedBox(width: HoorSpacing.xs),
                GestureDetector(
                  onTap: onClear,
                  child: Icon(
                    Icons.close_rounded,
                    size: HoorIconSize.xs,
                    color: HoorColors.primary,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _showDatePicker(BuildContext context) async {
    final range = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      initialDateRange: selectedRange,
      locale: const Locale('ar'),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: HoorColors.primary,
              onPrimary: Colors.white,
              surface: HoorColors.surface,
            ),
          ),
          child: child!,
        );
      },
    );

    if (range != null) {
      onRangeSelected?.call(range);
    }
  }
}
