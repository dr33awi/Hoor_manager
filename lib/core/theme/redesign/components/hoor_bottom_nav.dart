import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../design_tokens.dart';
import '../typography.dart';

/// ═══════════════════════════════════════════════════════════════════════════
/// HoorBottomNav - Professional Bottom Navigation
/// Modern, accessible navigation with badges and animations
/// ═══════════════════════════════════════════════════════════════════════════

class HoorBottomNav extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;
  final List<HoorBottomNavItem> items;
  final Color? backgroundColor;
  final Color? selectedColor;
  final Color? unselectedColor;
  final bool showLabels;
  final double elevation;

  const HoorBottomNav({
    super.key,
    required this.currentIndex,
    required this.onTap,
    required this.items,
    this.backgroundColor,
    this.selectedColor,
    this.unselectedColor,
    this.showLabels = true,
    this.elevation = 0,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: backgroundColor ?? HoorColors.surface,
        border: Border(
          top: BorderSide(
            color: HoorColors.border,
            width: 1,
          ),
        ),
        boxShadow: elevation > 0 ? HoorShadows.md : null,
      ),
      child: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: HoorSpacing.sm.w,
            vertical: HoorSpacing.xs.h,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: List.generate(items.length, (index) {
              final item = items[index];
              final isSelected = index == currentIndex;

              return _HoorNavItem(
                item: item,
                isSelected: isSelected,
                selectedColor: selectedColor ?? HoorColors.primary,
                unselectedColor: unselectedColor ?? HoorColors.textTertiary,
                showLabel: showLabels,
                onTap: () => onTap(index),
              );
            }),
          ),
        ),
      ),
    );
  }
}

class HoorBottomNavItem {
  final IconData icon;
  final IconData? activeIcon;
  final String label;
  final int? badgeCount;
  final bool showBadge;

  const HoorBottomNavItem({
    required this.icon,
    this.activeIcon,
    required this.label,
    this.badgeCount,
    this.showBadge = false,
  });
}

class _HoorNavItem extends StatelessWidget {
  final HoorBottomNavItem item;
  final bool isSelected;
  final Color selectedColor;
  final Color unselectedColor;
  final bool showLabel;
  final VoidCallback onTap;

  const _HoorNavItem({
    required this.item,
    required this.isSelected,
    required this.selectedColor,
    required this.unselectedColor,
    required this.showLabel,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(HoorRadius.md),
          child: AnimatedContainer(
            duration: HoorDurations.fast,
            padding: const EdgeInsets.symmetric(
              vertical: HoorSpacing.xs,
              horizontal: HoorSpacing.xs,
            ),
            decoration: isSelected
                ? BoxDecoration(
                    color: selectedColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(HoorRadius.md),
                  )
                : null,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildIcon(),
                if (showLabel) ...[
                  const SizedBox(height: 4),
                  AnimatedDefaultTextStyle(
                    duration: HoorDurations.fast,
                    style: HoorTypography.labelSmall.copyWith(
                      color: isSelected ? selectedColor : unselectedColor,
                      fontWeight:
                          isSelected ? FontWeight.w600 : FontWeight.w400,
                    ),
                    child: Text(item.label),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildIcon() {
    final icon = isSelected ? (item.activeIcon ?? item.icon) : item.icon;
    final color = isSelected ? selectedColor : unselectedColor;

    return Stack(
      clipBehavior: Clip.none,
      children: [
        AnimatedContainer(
          duration: HoorDurations.fast,
          child: Icon(
            icon,
            color: color,
            size: HoorIconSize.md,
          ),
        ),
        if (item.showBadge || (item.badgeCount != null && item.badgeCount! > 0))
          Positioned(
            top: -4,
            left: -8,
            child: _buildBadge(),
          ),
      ],
    );
  }

  Widget _buildBadge() {
    if (item.badgeCount != null && item.badgeCount! > 0) {
      return Container(
        padding: const EdgeInsets.symmetric(
          horizontal: 5,
          vertical: 1,
        ),
        constraints: const BoxConstraints(minWidth: 16),
        decoration: BoxDecoration(
          color: HoorColors.error,
          borderRadius: BorderRadius.circular(HoorRadius.full),
        ),
        child: Text(
          item.badgeCount! > 99 ? '99+' : item.badgeCount.toString(),
          style: HoorTypography.labelSmall.copyWith(
            color: Colors.white,
            fontSize: 10,
            fontWeight: FontWeight.w600,
          ),
          textAlign: TextAlign.center,
        ),
      );
    }

    return Container(
      width: 8,
      height: 8,
      decoration: const BoxDecoration(
        color: HoorColors.error,
        shape: BoxShape.circle,
      ),
    );
  }
}

/// ═══════════════════════════════════════════════════════════════════════════
/// Navigation Rail (for tablets and larger screens)
/// ═══════════════════════════════════════════════════════════════════════════

class HoorNavigationRail extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;
  final List<HoorBottomNavItem> items;
  final Widget? header;
  final Widget? footer;
  final bool extended;
  final double? minWidth;
  final double? minExtendedWidth;

  const HoorNavigationRail({
    super.key,
    required this.currentIndex,
    required this.onTap,
    required this.items,
    this.header,
    this.footer,
    this.extended = false,
    this.minWidth,
    this.minExtendedWidth,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: extended ? (minExtendedWidth ?? 200) : (minWidth ?? 72),
      decoration: BoxDecoration(
        color: HoorColors.surface,
        border: Border(
          left: BorderSide(
            color: HoorColors.border,
            width: 1,
          ),
        ),
      ),
      child: SafeArea(
        child: Column(
          children: [
            if (header != null) ...[
              header!,
              const SizedBox(height: HoorSpacing.md),
            ],
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(
                  horizontal: HoorSpacing.sm,
                  vertical: HoorSpacing.sm,
                ),
                itemCount: items.length,
                itemBuilder: (context, index) {
                  final item = items[index];
                  final isSelected = index == currentIndex;

                  return Padding(
                    padding: const EdgeInsets.only(bottom: HoorSpacing.xs),
                    child: _HoorRailItem(
                      item: item,
                      isSelected: isSelected,
                      extended: extended,
                      onTap: () => onTap(index),
                    ),
                  );
                },
              ),
            ),
            if (footer != null) ...[
              const SizedBox(height: HoorSpacing.md),
              footer!,
            ],
          ],
        ),
      ),
    );
  }
}

class _HoorRailItem extends StatelessWidget {
  final HoorBottomNavItem item;
  final bool isSelected;
  final bool extended;
  final VoidCallback onTap;

  const _HoorRailItem({
    required this.item,
    required this.isSelected,
    required this.extended,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final selectedColor = HoorColors.primary;
    final unselectedColor = HoorColors.textTertiary;
    final icon = isSelected ? (item.activeIcon ?? item.icon) : item.icon;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(HoorRadius.md),
        child: AnimatedContainer(
          duration: HoorDurations.fast,
          padding: EdgeInsets.symmetric(
            vertical: HoorSpacing.sm,
            horizontal: extended ? HoorSpacing.md : HoorSpacing.sm,
          ),
          decoration: BoxDecoration(
            color: isSelected
                ? selectedColor.withValues(alpha: 0.1)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(HoorRadius.md),
          ),
          child: Row(
            mainAxisAlignment:
                extended ? MainAxisAlignment.start : MainAxisAlignment.center,
            children: [
              Stack(
                clipBehavior: Clip.none,
                children: [
                  Icon(
                    icon,
                    color: isSelected ? selectedColor : unselectedColor,
                    size: HoorIconSize.md,
                  ),
                  if (item.showBadge ||
                      (item.badgeCount != null && item.badgeCount! > 0))
                    Positioned(
                      top: -4,
                      left: -8,
                      child: Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          color: HoorColors.error,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                ],
              ),
              if (extended) ...[
                const SizedBox(width: HoorSpacing.md),
                Expanded(
                  child: Text(
                    item.label,
                    style: HoorTypography.bodyMedium.copyWith(
                      color: isSelected ? selectedColor : unselectedColor,
                      fontWeight:
                          isSelected ? FontWeight.w600 : FontWeight.w400,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
