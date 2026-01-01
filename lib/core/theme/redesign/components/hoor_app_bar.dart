import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../design_tokens.dart';
import '../typography.dart';

/// ═══════════════════════════════════════════════════════════════════════════
/// HoorAppBar - Professional App Bar Components
/// Modern, clean app bars with various configurations
/// ═══════════════════════════════════════════════════════════════════════════

class HoorAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String? title;
  final Widget? titleWidget;
  final List<Widget>? actions;
  final Widget? leading;
  final bool centerTitle;
  final bool showBackButton;
  final VoidCallback? onBackPressed;
  final PreferredSizeWidget? bottom;
  final Color? backgroundColor;
  final bool transparent;
  final double elevation;
  final SystemUiOverlayStyle? systemOverlayStyle;

  const HoorAppBar({
    super.key,
    this.title,
    this.titleWidget,
    this.actions,
    this.leading,
    this.centerTitle = false,
    this.showBackButton = true,
    this.onBackPressed,
    this.bottom,
    this.backgroundColor,
    this.transparent = false,
    this.elevation = 0,
    this.systemOverlayStyle,
  });

  @override
  Widget build(BuildContext context) {
    final canPop = Navigator.of(context).canPop();

    return AppBar(
      title: titleWidget ??
          (title != null
              ? Text(
                  title!,
                  style: HoorTypography.titleLarge.copyWith(
                    color: transparent ? Colors.white : HoorColors.textPrimary,
                  ),
                )
              : null),
      centerTitle: centerTitle,
      leading: _buildLeading(context, canPop),
      actions: actions,
      backgroundColor: transparent
          ? Colors.transparent
          : (backgroundColor ?? HoorColors.surface),
      elevation: elevation,
      scrolledUnderElevation: transparent ? 0 : 0.5,
      surfaceTintColor: Colors.transparent,
      systemOverlayStyle: systemOverlayStyle ??
          (transparent
              ? SystemUiOverlayStyle.light
              : SystemUiOverlayStyle.dark),
      bottom: bottom,
      automaticallyImplyLeading: false,
    );
  }

  Widget? _buildLeading(BuildContext context, bool canPop) {
    if (leading != null) return leading;

    if (showBackButton && canPop) {
      return IconButton(
        icon: Icon(
          Icons.arrow_back_ios_new_rounded,
          color: transparent ? Colors.white : HoorColors.textPrimary,
          size: HoorIconSize.md,
        ),
        onPressed: onBackPressed ?? () => Navigator.of(context).pop(),
      );
    }

    return null;
  }

  @override
  Size get preferredSize => Size.fromHeight(
        kToolbarHeight.h + (bottom?.preferredSize.height ?? 0),
      );
}

/// ═══════════════════════════════════════════════════════════════════════════
/// Large Title App Bar (iOS style)
/// ═══════════════════════════════════════════════════════════════════════════

class HoorLargeTitleAppBar extends StatelessWidget {
  final String title;
  final String? subtitle;
  final List<Widget>? actions;
  final Widget? leading;
  final bool showBackButton;
  final VoidCallback? onBackPressed;
  final Widget? flexibleContent;
  final double expandedHeight;

  const HoorLargeTitleAppBar({
    super.key,
    required this.title,
    this.subtitle,
    this.actions,
    this.leading,
    this.showBackButton = true,
    this.onBackPressed,
    this.flexibleContent,
    this.expandedHeight = 120,
  });

  @override
  Widget build(BuildContext context) {
    final canPop = Navigator.of(context).canPop();

    return SliverAppBar(
      expandedHeight: expandedHeight.h,
      floating: false,
      pinned: true,
      backgroundColor: HoorColors.surface,
      surfaceTintColor: Colors.transparent,
      leading: _buildLeading(context, canPop),
      actions: actions,
      flexibleSpace: FlexibleSpaceBar(
        titlePadding: EdgeInsets.only(
          right: HoorSpacing.md.w,
          bottom: HoorSpacing.md.h,
          left: HoorSpacing.md.w,
        ),
        title: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: HoorTypography.headlineSmall.copyWith(
                color: HoorColors.textPrimary,
              ),
            ),
            if (subtitle != null)
              Text(
                subtitle!,
                style: HoorTypography.bodySmall.copyWith(
                  color: HoorColors.textSecondary,
                ),
              ),
          ],
        ),
        background: flexibleContent,
      ),
    );
  }

  Widget? _buildLeading(BuildContext context, bool canPop) {
    if (leading != null) return leading;

    if (showBackButton && canPop) {
      return IconButton(
        icon: const Icon(
          Icons.arrow_back_ios_new_rounded,
          color: HoorColors.textPrimary,
          size: HoorIconSize.md,
        ),
        onPressed: onBackPressed ?? () => Navigator.of(context).pop(),
      );
    }

    return null;
  }
}

/// ═══════════════════════════════════════════════════════════════════════════
/// Search App Bar
/// ═══════════════════════════════════════════════════════════════════════════

class HoorSearchAppBar extends StatefulWidget implements PreferredSizeWidget {
  final String? title;
  final String hintText;
  final ValueChanged<String>? onSearch;
  final VoidCallback? onClear;
  final List<Widget>? actions;
  final bool autoFocus;
  final TextEditingController? controller;

  const HoorSearchAppBar({
    super.key,
    this.title,
    this.hintText = 'بحث...',
    this.onSearch,
    this.onClear,
    this.actions,
    this.autoFocus = false,
    this.controller,
  });

  @override
  State<HoorSearchAppBar> createState() => _HoorSearchAppBarState();

  @override
  Size get preferredSize => Size.fromHeight(kToolbarHeight.h);
}

class _HoorSearchAppBarState extends State<HoorSearchAppBar> {
  late TextEditingController _controller;
  bool _isSearching = false;
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

  void _startSearch() {
    setState(() => _isSearching = true);
  }

  void _stopSearch() {
    _controller.clear();
    widget.onClear?.call();
    setState(() => _isSearching = false);
  }

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: HoorColors.surface,
      surfaceTintColor: Colors.transparent,
      title: _isSearching ? _buildSearchField() : _buildTitle(),
      leading: _isSearching
          ? IconButton(
              icon: const Icon(
                Icons.arrow_back_rounded,
                color: HoorColors.textPrimary,
              ),
              onPressed: _stopSearch,
            )
          : null,
      actions: _isSearching ? _buildSearchActions() : _buildNormalActions(),
    );
  }

  Widget _buildTitle() {
    if (widget.title != null) {
      return Text(
        widget.title!,
        style: HoorTypography.titleLarge.copyWith(
          color: HoorColors.textPrimary,
        ),
      );
    }
    return const SizedBox();
  }

  Widget _buildSearchField() {
    return TextField(
      controller: _controller,
      autofocus: widget.autoFocus,
      style: HoorTypography.bodyMedium,
      decoration: InputDecoration(
        hintText: widget.hintText,
        hintStyle: HoorTypography.bodyMedium.copyWith(
          color: HoorColors.textTertiary,
        ),
        border: InputBorder.none,
        enabledBorder: InputBorder.none,
        focusedBorder: InputBorder.none,
      ),
      onChanged: widget.onSearch,
    );
  }

  List<Widget> _buildNormalActions() {
    return [
      IconButton(
        icon: const Icon(
          Icons.search_rounded,
          color: HoorColors.textSecondary,
        ),
        onPressed: _startSearch,
      ),
      ...?widget.actions,
    ];
  }

  List<Widget> _buildSearchActions() {
    return [
      if (_hasText)
        IconButton(
          icon: const Icon(
            Icons.close_rounded,
            color: HoorColors.textSecondary,
          ),
          onPressed: () {
            _controller.clear();
            widget.onClear?.call();
            widget.onSearch?.call('');
          },
        ),
    ];
  }
}
