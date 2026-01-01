import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../core/theme/redesign/design_system.dart';
import 'menu_item_card.dart';

/// ═══════════════════════════════════════════════════════════════════════════
/// Menu Group - A section of menu items with a header
/// ═══════════════════════════════════════════════════════════════════════════

class MenuGroup extends StatelessWidget {
  final String title;
  final IconData icon;
  final List<MenuItemCard> items;

  const MenuGroup({
    super.key,
    required this.title,
    required this.icon,
    required this.items,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Group Header
        HoorDecoratedHeader(
          title: title,
          icon: icon,
        ),
        SizedBox(height: HoorSpacing.md.h),

        // Grid of Items
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            mainAxisSpacing: HoorSpacing.sm.h,
            crossAxisSpacing: HoorSpacing.sm.w,
            childAspectRatio: 1.6,
          ),
          itemCount: items.length,
          itemBuilder: (context, index) => items[index],
        ),
      ],
    );
  }
}
