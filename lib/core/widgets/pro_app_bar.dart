// ═══════════════════════════════════════════════════════════════════════════
// Pro App Bar - Unified AppBar Widget
// Consistent app bars across all screens
// ═══════════════════════════════════════════════════════════════════════════

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

import '../theme/design_tokens.dart';

/// AppBar موحد لجميع الشاشات
class ProAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final String? subtitle;
  final VoidCallback? onBack;
  final bool showBackButton;
  final List<Widget>? actions;
  final Widget? leading;
  final Color? backgroundColor;
  final bool centerTitle;
  final double? elevation;
  final bool implyLeading;
  final Widget? bottom;

  const ProAppBar({
    super.key,
    required this.title,
    this.subtitle,
    this.onBack,
    this.showBackButton = true,
    this.actions,
    this.leading,
    this.backgroundColor,
    this.centerTitle = false,
    this.elevation = 0,
    this.implyLeading = true,
    this.bottom,
  });

  @override
  Size get preferredSize => Size.fromHeight(
        kToolbarHeight + (bottom != null ? kTextTabBarHeight : 0),
      );

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: backgroundColor ?? AppColors.surface,
      elevation: elevation,
      scrolledUnderElevation: 1,
      surfaceTintColor: Colors.transparent,
      centerTitle: centerTitle,
      automaticallyImplyLeading: implyLeading,
      leading: leading ??
          (showBackButton
              ? IconButton(
                  onPressed: onBack ?? () => context.pop(),
                  icon: Icon(
                    Icons.arrow_back_ios_rounded,
                    color: AppColors.textSecondary,
                    size: 20.sp,
                  ),
                )
              : null),
      title: subtitle == null
          ? Text(
              title,
              style: AppTypography.titleLarge.copyWith(
                color: AppColors.textPrimary,
              ),
            )
          : Column(
              crossAxisAlignment: centerTitle
                  ? CrossAxisAlignment.center
                  : CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  style: AppTypography.titleLarge.copyWith(
                    color: AppColors.textPrimary,
                  ),
                ),
                Text(
                  subtitle!,
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.textTertiary,
                  ),
                ),
              ],
            ),
      actions: actions,
      bottom: bottom != null
          ? PreferredSize(
              preferredSize: const Size.fromHeight(kTextTabBarHeight),
              child: bottom!,
            )
          : null,
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // Factory Constructors
  // ═══════════════════════════════════════════════════════════════════════════

  /// AppBar بسيط
  factory ProAppBar.simple({
    required String title,
    VoidCallback? onBack,
    List<Widget>? actions,
  }) {
    return ProAppBar(
      title: title,
      onBack: onBack,
      actions: actions,
    );
  }

  /// AppBar مع عنوان فرعي
  factory ProAppBar.withSubtitle({
    required String title,
    required String subtitle,
    VoidCallback? onBack,
    List<Widget>? actions,
  }) {
    return ProAppBar(
      title: title,
      subtitle: subtitle,
      onBack: onBack,
      actions: actions,
    );
  }

  /// AppBar بدون زر الرجوع
  factory ProAppBar.noBack({
    required String title,
    List<Widget>? actions,
  }) {
    return ProAppBar(
      title: title,
      showBackButton: false,
      implyLeading: false,
      actions: actions,
    );
  }

  /// AppBar مع زر إغلاق
  factory ProAppBar.close({
    required String title,
    VoidCallback? onClose,
    List<Widget>? actions,
  }) {
    return ProAppBar(
      title: title,
      showBackButton: false,
      leading: Builder(
        builder: (context) => IconButton(
          onPressed: onClose ?? () => context.pop(),
          icon: Icon(
            Icons.close_rounded,
            color: AppColors.textSecondary,
            size: 24.sp,
          ),
        ),
      ),
      actions: actions,
    );
  }

  /// AppBar شفاف
  factory ProAppBar.transparent({
    required String title,
    VoidCallback? onBack,
    List<Widget>? actions,
  }) {
    return ProAppBar(
      title: title,
      onBack: onBack,
      actions: actions,
      backgroundColor: Colors.transparent,
      elevation: 0,
    );
  }

  /// AppBar مع tabs
  factory ProAppBar.withTabs({
    required String title,
    required TabBar tabBar,
    VoidCallback? onBack,
    List<Widget>? actions,
  }) {
    return ProAppBar(
      title: title,
      onBack: onBack,
      actions: actions,
      bottom: tabBar,
    );
  }
}

/// زر في AppBar
class ProAppBarAction extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onPressed;
  final String? tooltip;
  final Color? color;
  final int? badge;

  const ProAppBarAction({
    super.key,
    required this.icon,
    this.onPressed,
    this.tooltip,
    this.color,
    this.badge,
  });

  @override
  Widget build(BuildContext context) {
    Widget iconWidget = Icon(
      icon,
      color: color ?? AppColors.textSecondary,
      size: 24.sp,
    );

    if (badge != null && badge! > 0) {
      iconWidget = Badge(
        label: Text(badge.toString()),
        child: iconWidget,
      );
    }

    Widget button = IconButton(
      onPressed: onPressed,
      icon: iconWidget,
    );

    if (tooltip != null) {
      return Tooltip(message: tooltip!, child: button);
    }

    return button;
  }

  /// زر الإعدادات
  factory ProAppBarAction.settings({VoidCallback? onPressed}) {
    return ProAppBarAction(
      icon: Icons.settings_outlined,
      tooltip: 'الإعدادات',
      onPressed: onPressed,
    );
  }

  /// زر البحث
  factory ProAppBarAction.search({VoidCallback? onPressed}) {
    return ProAppBarAction(
      icon: Icons.search_rounded,
      tooltip: 'بحث',
      onPressed: onPressed,
    );
  }

  /// زر الإشعارات
  factory ProAppBarAction.notifications({VoidCallback? onPressed, int? badge}) {
    return ProAppBarAction(
      icon: Icons.notifications_outlined,
      tooltip: 'الإشعارات',
      onPressed: onPressed,
      badge: badge,
    );
  }

  /// زر المزيد
  factory ProAppBarAction.more({VoidCallback? onPressed}) {
    return ProAppBarAction(
      icon: Icons.more_vert_rounded,
      tooltip: 'المزيد',
      onPressed: onPressed,
    );
  }

  /// زر المشاركة
  factory ProAppBarAction.share({VoidCallback? onPressed}) {
    return ProAppBarAction(
      icon: Icons.share_outlined,
      tooltip: 'مشاركة',
      onPressed: onPressed,
    );
  }

  /// زر الحذف
  factory ProAppBarAction.delete({VoidCallback? onPressed}) {
    return ProAppBarAction(
      icon: Icons.delete_outline_rounded,
      tooltip: 'حذف',
      color: AppColors.error,
      onPressed: onPressed,
    );
  }

  /// زر التعديل
  factory ProAppBarAction.edit({VoidCallback? onPressed}) {
    return ProAppBarAction(
      icon: Icons.edit_outlined,
      tooltip: 'تعديل',
      onPressed: onPressed,
    );
  }

  /// زر التصفية
  factory ProAppBarAction.filter(
      {VoidCallback? onPressed, bool isActive = false}) {
    return ProAppBarAction(
      icon: Icons.filter_list_rounded,
      tooltip: 'تصفية',
      color: isActive ? AppColors.primary : null,
      onPressed: onPressed,
    );
  }

  /// زر الطباعة
  factory ProAppBarAction.print({VoidCallback? onPressed}) {
    return ProAppBarAction(
      icon: Icons.print_outlined,
      tooltip: 'طباعة',
      onPressed: onPressed,
    );
  }
}
