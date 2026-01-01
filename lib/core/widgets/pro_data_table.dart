// ═══════════════════════════════════════════════════════════════════════════
// Pro Data Table Component
// Modern, Animated Data Table for Financial Data
// ═══════════════════════════════════════════════════════════════════════════

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../theme/design_tokens.dart';
import '../animations/pro_animations.dart';

// ═══════════════════════════════════════════════════════════════════════════
// Data Table Column Definition
// ═══════════════════════════════════════════════════════════════════════════

class ProTableColumn<T> {
  final String title;
  final String Function(T item) getValue;
  final int flex;
  final TextAlign alignment;
  final bool isNumeric;
  final Widget Function(T item)? customBuilder;
  final bool sortable;

  const ProTableColumn({
    required this.title,
    required this.getValue,
    this.flex = 1,
    this.alignment = TextAlign.start,
    this.isNumeric = false,
    this.customBuilder,
    this.sortable = false,
  });
}

// ═══════════════════════════════════════════════════════════════════════════
// Pro Data Table
// ═══════════════════════════════════════════════════════════════════════════

class ProDataTable<T> extends StatefulWidget {
  final List<ProTableColumn<T>> columns;
  final List<T> data;
  final void Function(T item)? onRowTap;
  final bool showHeader;
  final bool isLoading;
  final bool animateRows;
  final bool alternatingRowColors;
  final Widget? emptyWidget;
  final bool showBorder;
  final ScrollController? scrollController;

  const ProDataTable({
    super.key,
    required this.columns,
    required this.data,
    this.onRowTap,
    this.showHeader = true,
    this.isLoading = false,
    this.animateRows = true,
    this.alternatingRowColors = true,
    this.emptyWidget,
    this.showBorder = true,
    this.scrollController,
  });

  @override
  State<ProDataTable<T>> createState() => _ProDataTableState<T>();
}

class _ProDataTableState<T> extends State<ProDataTable<T>> {
  int? _hoveredIndex;

  @override
  Widget build(BuildContext context) {
    if (widget.data.isEmpty && !widget.isLoading) {
      return widget.emptyWidget ?? _buildEmptyState();
    }

    return Container(
      decoration: widget.showBorder
          ? BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(AppRadius.lg),
              border: Border.all(color: AppColors.border),
              boxShadow: AppShadows.sm,
            )
          : null,
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          if (widget.showHeader) _buildHeader(),
          Expanded(
            child: ListView.builder(
              controller: widget.scrollController,
              itemCount: widget.data.length,
              itemBuilder: (context, index) {
                final item = widget.data[index];
                return widget.animateRows
                    ? StaggeredListAnimation(
                        index: index,
                        staggerDuration: const Duration(milliseconds: 30),
                        child: _buildRow(item, index),
                      )
                    : _buildRow(item, index);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.md,
      ),
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant,
        border: Border(
          bottom: BorderSide(color: AppColors.border),
        ),
      ),
      child: Row(
        children: widget.columns.map((column) {
          return Expanded(
            flex: column.flex,
            child: Text(
              column.title,
              textAlign: column.alignment,
              style: AppTypography.labelMedium.copyWith(
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w600,
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildRow(T item, int index) {
    final isHovered = _hoveredIndex == index;
    final isAlternate = widget.alternatingRowColors && index.isOdd;

    return MouseRegion(
      onEnter: (_) => setState(() => _hoveredIndex = index),
      onExit: (_) => setState(() => _hoveredIndex = null),
      child: GestureDetector(
        onTap: widget.onRowTap != null ? () => widget.onRowTap!(item) : null,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.md,
          ),
          decoration: BoxDecoration(
            color: isHovered
                ? AppColors.primary.withValues(alpha: 0.05)
                : isAlternate
                    ? AppColors.surfaceVariant.withValues(alpha: 0.5)
                    : Colors.white,
            border: Border(
              bottom: BorderSide(
                color: AppColors.border.withValues(alpha: 0.5),
              ),
            ),
          ),
          child: Row(
            children: widget.columns.map((column) {
              return Expanded(
                flex: column.flex,
                child: column.customBuilder != null
                    ? column.customBuilder!(item)
                    : Text(
                        column.getValue(item),
                        textAlign: column.alignment,
                        style: AppTypography.bodyMedium.copyWith(
                          color: AppColors.textPrimary,
                          fontFamily:
                              column.isNumeric ? 'JetBrains Mono' : 'Cairo',
                        ),
                      ),
              );
            }).toList(),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.inbox_outlined,
            size: 64.sp,
            color: AppColors.textTertiary,
          ),
          SizedBox(height: AppSpacing.md),
          Text(
            'لا توجد بيانات',
            style: AppTypography.titleMedium.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// Compact Table Row
// ═══════════════════════════════════════════════════════════════════════════

class CompactTableRow extends StatelessWidget {
  final List<String> cells;
  final List<int>? flexValues;
  final bool isHeader;
  final VoidCallback? onTap;
  final bool isAlternate;

  const CompactTableRow({
    super.key,
    required this.cells,
    this.flexValues,
    this.isHeader = false,
    this.onTap,
    this.isAlternate = false,
  });

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
          color: isHeader
              ? AppColors.surfaceVariant
              : isAlternate
                  ? AppColors.surfaceVariant.withValues(alpha: 0.3)
                  : Colors.white,
          border: Border(
            bottom: BorderSide(
              color: AppColors.border.withValues(alpha: 0.5),
            ),
          ),
        ),
        child: Row(
          children: List.generate(cells.length, (index) {
            return Expanded(
              flex: flexValues != null && index < flexValues!.length
                  ? flexValues![index]
                  : 1,
              child: Text(
                cells[index],
                style: isHeader
                    ? AppTypography.labelMedium.copyWith(
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w600,
                      )
                    : AppTypography.bodySmall.copyWith(
                        color: AppColors.textPrimary,
                      ),
              ),
            );
          }),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// Status Badge for Table
// ═══════════════════════════════════════════════════════════════════════════

class TableStatusBadge extends StatelessWidget {
  final String text;
  final Color color;
  final IconData? icon;

  const TableStatusBadge({
    super.key,
    required this.text,
    required this.color,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppRadius.full),
        border: Border.all(
          color: color.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 12.sp, color: color),
            SizedBox(width: 4.w),
          ],
          Text(
            text,
            style: AppTypography.labelSmall.copyWith(
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// Action Cell for Table
// ═══════════════════════════════════════════════════════════════════════════

class TableActionCell extends StatelessWidget {
  final List<TableAction> actions;

  const TableActionCell({
    super.key,
    required this.actions,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: actions.map((action) {
        return Padding(
          padding: EdgeInsets.only(left: AppSpacing.xs),
          child: IconButton(
            onPressed: action.onPressed,
            icon: Icon(
              action.icon,
              size: 18.sp,
              color: action.color ?? AppColors.textSecondary,
            ),
            tooltip: action.tooltip,
            splashRadius: 18.r,
            constraints: BoxConstraints(
              minWidth: 32.w,
              minHeight: 32.h,
            ),
            padding: EdgeInsets.zero,
          ),
        );
      }).toList(),
    );
  }
}

class TableAction {
  final IconData icon;
  final VoidCallback onPressed;
  final String? tooltip;
  final Color? color;

  const TableAction({
    required this.icon,
    required this.onPressed,
    this.tooltip,
    this.color,
  });
}
