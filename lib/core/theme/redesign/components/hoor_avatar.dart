import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../design_tokens.dart';

/// ═══════════════════════════════════════════════════════════════════════════
/// HoorAvatar - Avatar Components
/// User, company, and product image displays
/// ═══════════════════════════════════════════════════════════════════════════

enum HoorAvatarSize {
  xs,
  sm,
  md,
  lg,
  xl,
  xxl,
}

class HoorAvatar extends StatelessWidget {
  final String? imageUrl;
  final String? name;
  final IconData? icon;
  final HoorAvatarSize size;
  final Color? backgroundColor;
  final Color? foregroundColor;
  final bool showBorder;
  final bool isOnline;
  final VoidCallback? onTap;

  const HoorAvatar({
    super.key,
    this.imageUrl,
    this.name,
    this.icon,
    this.size = HoorAvatarSize.md,
    this.backgroundColor,
    this.foregroundColor,
    this.showBorder = false,
    this.isOnline = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final dimension = _getDimension();
    final bgColor = backgroundColor ?? HoorColors.primarySoft;
    final fgColor = foregroundColor ?? HoorColors.primary;

    Widget avatar = Container(
      width: dimension,
      height: dimension,
      decoration: BoxDecoration(
        color: bgColor,
        shape: BoxShape.circle,
        border: showBorder
            ? Border.all(color: HoorColors.border, width: 2.w)
            : null,
      ),
      child: _buildContent(bgColor, fgColor, dimension),
    );

    if (isOnline) {
      avatar = Stack(
        children: [
          avatar,
          Positioned(
            bottom: 0,
            left: 0,
            child: Container(
              width: dimension * 0.3,
              height: dimension * 0.3,
              decoration: BoxDecoration(
                color: HoorColors.success,
                shape: BoxShape.circle,
                border: Border.all(
                  color: HoorColors.surface,
                  width: 2.w,
                ),
              ),
            ),
          ),
        ],
      );
    }

    if (onTap != null) {
      avatar = GestureDetector(
        onTap: onTap,
        child: avatar,
      );
    }

    return avatar;
  }

  Widget _buildContent(Color bgColor, Color fgColor, double dimension) {
    if (imageUrl != null) {
      return ClipOval(
        child: Image.network(
          imageUrl!,
          width: dimension,
          height: dimension,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => _buildFallback(fgColor, dimension),
        ),
      );
    }

    return _buildFallback(fgColor, dimension);
  }

  Widget _buildFallback(Color color, double dimension) {
    if (name != null && name!.isNotEmpty) {
      return _buildInitials(color);
    }

    return Center(
      child: Icon(
        icon ?? Icons.person_outline_rounded,
        color: color,
        size: dimension * 0.5,
      ),
    );
  }

  Widget _buildInitials(Color color) {
    final initials = name!
        .split(' ')
        .map((e) => e.isNotEmpty ? e[0] : '')
        .take(2)
        .join()
        .toUpperCase();

    return Center(
      child: Text(
        initials,
        style: _getInitialsStyle(color),
      ),
    );
  }

  double _getDimension() {
    switch (size) {
      case HoorAvatarSize.xs:
        return 24.w;
      case HoorAvatarSize.sm:
        return 32.w;
      case HoorAvatarSize.md:
        return 40.w;
      case HoorAvatarSize.lg:
        return 56.w;
      case HoorAvatarSize.xl:
        return 72.w;
      case HoorAvatarSize.xxl:
        return 96.w;
    }
  }

  TextStyle _getInitialsStyle(Color color) {
    final fontSize = switch (size) {
      HoorAvatarSize.xs => 10.sp,
      HoorAvatarSize.sm => 12.sp,
      HoorAvatarSize.md => 14.sp,
      HoorAvatarSize.lg => 18.sp,
      HoorAvatarSize.xl => 24.sp,
      HoorAvatarSize.xxl => 32.sp,
    };

    return TextStyle(
      color: color,
      fontSize: fontSize,
      fontWeight: FontWeight.w600,
    );
  }
}

/// ═══════════════════════════════════════════════════════════════════════════
/// Avatar Group - Stacked avatars
/// ═══════════════════════════════════════════════════════════════════════════

class HoorAvatarGroup extends StatelessWidget {
  final List<HoorAvatarData> avatars;
  final int maxDisplay;
  final HoorAvatarSize size;
  final double overlap;
  final VoidCallback? onMoreTap;

  const HoorAvatarGroup({
    super.key,
    required this.avatars,
    this.maxDisplay = 4,
    this.size = HoorAvatarSize.sm,
    this.overlap = 0.3,
    this.onMoreTap,
  });

  @override
  Widget build(BuildContext context) {
    final displayAvatars = avatars.take(maxDisplay).toList();
    final remaining = avatars.length - maxDisplay;
    final dimension = _getDimension();
    final overlapAmount = dimension * overlap;

    return SizedBox(
      height: dimension,
      child: Stack(
        children: [
          ...List.generate(displayAvatars.length, (index) {
            final avatar = displayAvatars[index];
            return Positioned(
              right: index * (dimension - overlapAmount),
              child: HoorAvatar(
                imageUrl: avatar.imageUrl,
                name: avatar.name,
                size: size,
                showBorder: true,
              ),
            );
          }),
          if (remaining > 0)
            Positioned(
              right: displayAvatars.length * (dimension - overlapAmount),
              child: GestureDetector(
                onTap: onMoreTap,
                child: Container(
                  width: dimension,
                  height: dimension,
                  decoration: BoxDecoration(
                    color: HoorColors.surfaceMuted,
                    shape: BoxShape.circle,
                    border: Border.all(color: HoorColors.surface, width: 2.w),
                  ),
                  child: Center(
                    child: Text(
                      '+$remaining',
                      style: TextStyle(
                        color: HoorColors.textSecondary,
                        fontSize: dimension * 0.35,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  double _getDimension() {
    switch (size) {
      case HoorAvatarSize.xs:
        return 24.w;
      case HoorAvatarSize.sm:
        return 32.w;
      case HoorAvatarSize.md:
        return 40.w;
      case HoorAvatarSize.lg:
        return 56.w;
      case HoorAvatarSize.xl:
        return 72.w;
      case HoorAvatarSize.xxl:
        return 96.w;
    }
  }
}

class HoorAvatarData {
  final String? imageUrl;
  final String? name;

  const HoorAvatarData({
    this.imageUrl,
    this.name,
  });
}

/// ═══════════════════════════════════════════════════════════════════════════
/// Company/Brand Avatar
/// ═══════════════════════════════════════════════════════════════════════════

class HoorCompanyAvatar extends StatelessWidget {
  final String? logoUrl;
  final String name;
  final HoorAvatarSize size;
  final Color? backgroundColor;
  final bool showBorder;

  const HoorCompanyAvatar({
    super.key,
    this.logoUrl,
    required this.name,
    this.size = HoorAvatarSize.md,
    this.backgroundColor,
    this.showBorder = false,
  });

  @override
  Widget build(BuildContext context) {
    final dimension = _getDimension();

    return Container(
      width: dimension,
      height: dimension,
      decoration: BoxDecoration(
        color: backgroundColor ?? HoorColors.surface,
        borderRadius: BorderRadius.circular(dimension * 0.2),
        border: showBorder ? Border.all(color: HoorColors.border) : null,
      ),
      child: logoUrl != null
          ? ClipRRect(
              borderRadius: BorderRadius.circular(dimension * 0.2),
              child: Image.network(
                logoUrl!,
                fit: BoxFit.contain,
                errorBuilder: (_, __, ___) => _buildInitials(dimension),
              ),
            )
          : _buildInitials(dimension),
    );
  }

  Widget _buildInitials(double dimension) {
    final initial = name.isNotEmpty ? name[0].toUpperCase() : '?';

    return Center(
      child: Text(
        initial,
        style: TextStyle(
          color: HoorColors.primary,
          fontSize: dimension * 0.5,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  double _getDimension() {
    switch (size) {
      case HoorAvatarSize.xs:
        return 24.w;
      case HoorAvatarSize.sm:
        return 32.w;
      case HoorAvatarSize.md:
        return 40.w;
      case HoorAvatarSize.lg:
        return 56.w;
      case HoorAvatarSize.xl:
        return 72.w;
      case HoorAvatarSize.xxl:
        return 96.w;
    }
  }
}
