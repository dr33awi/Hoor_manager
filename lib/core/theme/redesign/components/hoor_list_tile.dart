import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../design_tokens.dart';
import '../typography.dart';

/// ═══════════════════════════════════════════════════════════════════════════
/// HoorListTile - Professional List Item Components
/// Modern, customizable list tiles for various use cases
/// ═══════════════════════════════════════════════════════════════════════════

class HoorListTile extends StatelessWidget {
  final String title;
  final String? subtitle;
  final String? caption;
  final Widget? leading;
  final Widget? trailing;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final bool isSelected;
  final bool showDivider;
  final bool dense;
  final EdgeInsetsGeometry? padding;

  const HoorListTile({
    super.key,
    required this.title,
    this.subtitle,
    this.caption,
    this.leading,
    this.trailing,
    this.onTap,
    this.onLongPress,
    this.isSelected = false,
    this.showDivider = false,
    this.dense = false,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Material(
          color: isSelected ? HoorColors.primarySoft : Colors.transparent,
          child: InkWell(
            onTap: onTap,
            onLongPress: onLongPress,
            child: Padding(
              padding: padding ??
                  EdgeInsets.symmetric(
                    horizontal: HoorSpacing.md,
                    vertical: dense ? HoorSpacing.sm : HoorSpacing.md,
                  ),
              child: Row(
                children: [
                  if (leading != null) ...[
                    leading!,
                    SizedBox(width: dense ? HoorSpacing.sm : HoorSpacing.md),
                  ],
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: (dense
                                  ? HoorTypography.bodySmall
                                  : HoorTypography.bodyMedium)
                              .copyWith(
                            color: HoorColors.textPrimary,
                            fontWeight:
                                isSelected ? FontWeight.w600 : FontWeight.w400,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (subtitle != null) ...[
                          SizedBox(height: 2.h),
                          Text(
                            subtitle!,
                            style: HoorTypography.bodySmall.copyWith(
                              color: HoorColors.textSecondary,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                        if (caption != null) ...[
                          SizedBox(height: 2.h),
                          Text(
                            caption!,
                            style: HoorTypography.caption.copyWith(
                              color: HoorColors.textTertiary,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ],
                    ),
                  ),
                  if (trailing != null) ...[
                    SizedBox(width: dense ? HoorSpacing.sm : HoorSpacing.md),
                    trailing!,
                  ],
                ],
              ),
            ),
          ),
        ),
        if (showDivider)
          Divider(height: 1, indent: HoorSpacing.md, endIndent: HoorSpacing.md),
      ],
    );
  }
}

/// ═══════════════════════════════════════════════════════════════════════════
/// Invoice/Transaction List Item
/// ═══════════════════════════════════════════════════════════════════════════

class HoorTransactionTile extends StatelessWidget {
  final String title;
  final String subtitle;
  final String amount;
  final String? date;
  final IconData icon;
  final Color? color;
  final bool isIncome;
  final String? status;
  final Color? statusColor;
  final VoidCallback? onTap;

  const HoorTransactionTile({
    super.key,
    required this.title,
    required this.subtitle,
    required this.amount,
    this.date,
    required this.icon,
    this.color,
    this.isIncome = true,
    this.status,
    this.statusColor,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveColor =
        color ?? (isIncome ? HoorColors.income : HoorColors.expense);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: HoorSpacing.md,
            vertical: HoorSpacing.sm,
          ),
          child: Row(
            children: [
              Container(
                padding: EdgeInsets.all(HoorSpacing.sm),
                decoration: BoxDecoration(
                  color: effectiveColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(HoorRadius.md),
                ),
                child: Icon(
                  icon,
                  color: effectiveColor,
                  size: HoorIconSize.md,
                ),
              ),
              SizedBox(width: HoorSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            title,
                            style: HoorTypography.bodyMedium.copyWith(
                              color: HoorColors.textPrimary,
                              fontWeight: FontWeight.w500,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (status != null) _buildStatusBadge(),
                      ],
                    ),
                    SizedBox(height: 2.h),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            subtitle,
                            style: HoorTypography.bodySmall.copyWith(
                              color: HoorColors.textSecondary,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (date != null)
                          Text(
                            date!,
                            style: HoorTypography.caption,
                          ),
                      ],
                    ),
                  ],
                ),
              ),
              SizedBox(width: HoorSpacing.md),
              Text(
                '${isIncome ? '+' : '-'} $amount',
                style: HoorTypography.titleSmall.copyWith(
                  color: isIncome ? HoorColors.income : HoorColors.expense,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusBadge() {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: HoorSpacing.xs,
        vertical: 2.h,
      ),
      decoration: BoxDecoration(
        color: (statusColor ?? HoorColors.info).withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(HoorRadius.full),
      ),
      child: Text(
        status!,
        style: HoorTypography.labelSmall.copyWith(
          color: statusColor ?? HoorColors.info,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

/// ═══════════════════════════════════════════════════════════════════════════
/// Product/Inventory List Item
/// ═══════════════════════════════════════════════════════════════════════════

class HoorProductTile extends StatelessWidget {
  final String name;
  final String? code;
  final String price;
  final String? stock;
  final String? imageUrl;
  final bool isLowStock;
  final VoidCallback? onTap;
  final VoidCallback? onAddTap;

  const HoorProductTile({
    super.key,
    required this.name,
    this.code,
    required this.price,
    this.stock,
    this.imageUrl,
    this.isLowStock = false,
    this.onTap,
    this.onAddTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: HoorSpacing.md,
            vertical: HoorSpacing.sm,
          ),
          child: Row(
            children: [
              _buildImage(),
              SizedBox(width: HoorSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: HoorTypography.bodyMedium.copyWith(
                        color: HoorColors.textPrimary,
                        fontWeight: FontWeight.w500,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: 2.h),
                    Row(
                      children: [
                        if (code != null) ...[
                          Text(
                            code!,
                            style: HoorTypography.caption,
                          ),
                          SizedBox(width: HoorSpacing.sm),
                        ],
                        if (stock != null)
                          Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: HoorSpacing.xs,
                              vertical: 2.h,
                            ),
                            decoration: BoxDecoration(
                              color: isLowStock
                                  ? HoorColors.warningLight
                                  : HoorColors.successLight,
                              borderRadius:
                                  BorderRadius.circular(HoorRadius.full),
                            ),
                            child: Text(
                              'الكمية: $stock',
                              style: HoorTypography.labelSmall.copyWith(
                                color: isLowStock
                                    ? HoorColors.warning
                                    : HoorColors.success,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
              SizedBox(width: HoorSpacing.sm),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    price,
                    style: HoorTypography.titleSmall.copyWith(
                      color: HoorColors.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (onAddTap != null)
                    IconButton(
                      icon: Container(
                        padding: EdgeInsets.all(HoorSpacing.xxs),
                        decoration: BoxDecoration(
                          color: HoorColors.primary,
                          borderRadius: BorderRadius.circular(HoorRadius.sm),
                        ),
                        child: Icon(
                          Icons.add_rounded,
                          color: Colors.white,
                          size: HoorIconSize.sm,
                        ),
                      ),
                      onPressed: onAddTap,
                      padding: EdgeInsets.zero,
                      constraints: BoxConstraints(
                        minWidth: 32.w,
                        minHeight: 32.w,
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildImage() {
    return Container(
      width: 56.w,
      height: 56.w,
      decoration: BoxDecoration(
        color: HoorColors.surfaceMuted,
        borderRadius: BorderRadius.circular(HoorRadius.md),
        border: Border.all(color: HoorColors.border),
      ),
      child: imageUrl != null
          ? ClipRRect(
              borderRadius: BorderRadius.circular(HoorRadius.md),
              child: Image.network(
                imageUrl!,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => _buildPlaceholder(),
              ),
            )
          : _buildPlaceholder(),
    );
  }

  Widget _buildPlaceholder() {
    return Center(
      child: Icon(
        Icons.inventory_2_outlined,
        color: HoorColors.textTertiary,
        size: HoorIconSize.lg,
      ),
    );
  }
}

/// ═══════════════════════════════════════════════════════════════════════════
/// Contact/Customer List Item
/// ═══════════════════════════════════════════════════════════════════════════

class HoorContactTile extends StatelessWidget {
  final String name;
  final String? subtitle;
  final String? phone;
  final String? avatarUrl;
  final String? balance;
  final bool isPositiveBalance;
  final VoidCallback? onTap;
  final VoidCallback? onCallTap;

  const HoorContactTile({
    super.key,
    required this.name,
    this.subtitle,
    this.phone,
    this.avatarUrl,
    this.balance,
    this.isPositiveBalance = true,
    this.onTap,
    this.onCallTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: HoorSpacing.md,
            vertical: HoorSpacing.sm,
          ),
          child: Row(
            children: [
              _buildAvatar(),
              SizedBox(width: HoorSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: HoorTypography.bodyMedium.copyWith(
                        color: HoorColors.textPrimary,
                        fontWeight: FontWeight.w500,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (subtitle != null || phone != null) ...[
                      SizedBox(height: 2.h),
                      Text(
                        subtitle ?? phone!,
                        style: HoorTypography.bodySmall.copyWith(
                          color: HoorColors.textSecondary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),
              if (balance != null) ...[
                SizedBox(width: HoorSpacing.sm),
                Text(
                  balance!,
                  style: HoorTypography.titleSmall.copyWith(
                    color: isPositiveBalance
                        ? HoorColors.income
                        : HoorColors.expense,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
              if (onCallTap != null && phone != null) ...[
                SizedBox(width: HoorSpacing.sm),
                IconButton(
                  icon: Icon(
                    Icons.phone_rounded,
                    color: HoorColors.success,
                    size: HoorIconSize.md,
                  ),
                  onPressed: onCallTap,
                  padding: EdgeInsets.all(HoorSpacing.xs),
                  constraints: BoxConstraints(
                    minWidth: 36.w,
                    minHeight: 36.w,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAvatar() {
    return Container(
      width: 48.w,
      height: 48.w,
      decoration: BoxDecoration(
        color: HoorColors.primarySoft,
        shape: BoxShape.circle,
        border: Border.all(color: HoorColors.border),
      ),
      child: avatarUrl != null
          ? ClipOval(
              child: Image.network(
                avatarUrl!,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => _buildInitials(),
              ),
            )
          : _buildInitials(),
    );
  }

  Widget _buildInitials() {
    final initials = name.isNotEmpty
        ? name.split(' ').map((e) => e.isNotEmpty ? e[0] : '').take(2).join()
        : '?';

    return Center(
      child: Text(
        initials.toUpperCase(),
        style: HoorTypography.titleMedium.copyWith(
          color: HoorColors.primary,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
