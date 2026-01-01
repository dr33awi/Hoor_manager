import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../design_tokens.dart';
import '../typography.dart';

/// ═══════════════════════════════════════════════════════════════════════════
/// HoorDataTable - Professional Data Table
/// Clean, responsive tables for financial data
/// ═══════════════════════════════════════════════════════════════════════════

class HoorDataTable<T> extends StatelessWidget {
  final List<HoorDataColumn> columns;
  final List<T> data;
  final Widget Function(T item, int columnIndex) cellBuilder;
  final void Function(T item)? onRowTap;
  final bool showHeader;
  final bool showBorder;
  final bool isLoading;
  final String? emptyMessage;
  final EdgeInsetsGeometry? padding;
  final double? rowHeight;

  const HoorDataTable({
    super.key,
    required this.columns,
    required this.data,
    required this.cellBuilder,
    this.onRowTap,
    this.showHeader = true,
    this.showBorder = true,
    this.isLoading = false,
    this.emptyMessage,
    this.padding,
    this.rowHeight,
  });

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return _buildLoading();
    }

    if (data.isEmpty) {
      return _buildEmpty();
    }

    return Container(
      decoration: showBorder
          ? BoxDecoration(
              border: Border.all(color: HoorColors.border),
              borderRadius: HoorRadius.cardRadius,
            )
          : null,
      child: ClipRRect(
        borderRadius: showBorder ? HoorRadius.cardRadius : BorderRadius.zero,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (showHeader) _buildHeader(),
            ...List.generate(data.length, (index) {
              return _buildRow(data[index], index);
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      color: HoorColors.surfaceMuted,
      padding: padding ??
          EdgeInsets.symmetric(
            horizontal: HoorSpacing.md,
            vertical: HoorSpacing.sm,
          ),
      child: Row(
        children: columns.asMap().entries.map((entry) {
          final column = entry.value;
          return Expanded(
            flex: column.flex,
            child: Text(
              column.title,
              style: HoorTypography.labelMedium.copyWith(
                color: HoorColors.textSecondary,
              ),
              textAlign: column.alignment == HoorColumnAlignment.end
                  ? TextAlign.end
                  : column.alignment == HoorColumnAlignment.center
                      ? TextAlign.center
                      : TextAlign.start,
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildRow(T item, int index) {
    final isLast = index == data.length - 1;

    return Material(
      color: index.isEven ? HoorColors.surface : HoorColors.surfaceHover,
      child: InkWell(
        onTap: onRowTap != null ? () => onRowTap!(item) : null,
        child: Container(
          height: rowHeight?.h,
          padding: padding ??
              EdgeInsets.symmetric(
                horizontal: HoorSpacing.md,
                vertical: HoorSpacing.sm,
              ),
          decoration: !isLast
              ? const BoxDecoration(
                  border: Border(
                    bottom: BorderSide(color: HoorColors.border),
                  ),
                )
              : null,
          child: Row(
            children: columns.asMap().entries.map((entry) {
              final columnIndex = entry.key;
              final column = entry.value;
              return Expanded(
                flex: column.flex,
                child: Align(
                  alignment: column.alignment == HoorColumnAlignment.end
                      ? Alignment.centerLeft
                      : column.alignment == HoorColumnAlignment.center
                          ? Alignment.center
                          : Alignment.centerRight,
                  child: cellBuilder(item, columnIndex),
                ),
              );
            }).toList(),
          ),
        ),
      ),
    );
  }

  Widget _buildLoading() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (index) {
        return Container(
          height: 56.h,
          padding: EdgeInsets.symmetric(
            horizontal: HoorSpacing.md,
            vertical: HoorSpacing.sm,
          ),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: HoorColors.border,
                width: index == 4 ? 0 : 1,
              ),
            ),
          ),
          child: Row(
            children: [
              Expanded(
                flex: 2,
                child: Container(
                  height: 16.h,
                  decoration: BoxDecoration(
                    color: HoorColors.surfaceMuted,
                    borderRadius: BorderRadius.circular(HoorRadius.xs),
                  ),
                ),
              ),
              SizedBox(width: HoorSpacing.md),
              Expanded(
                child: Container(
                  height: 16.h,
                  decoration: BoxDecoration(
                    color: HoorColors.surfaceMuted,
                    borderRadius: BorderRadius.circular(HoorRadius.xs),
                  ),
                ),
              ),
              SizedBox(width: HoorSpacing.md),
              Expanded(
                child: Container(
                  height: 16.h,
                  decoration: BoxDecoration(
                    color: HoorColors.surfaceMuted,
                    borderRadius: BorderRadius.circular(HoorRadius.xs),
                  ),
                ),
              ),
            ],
          ),
        );
      }),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(HoorSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.inbox_outlined,
              color: HoorColors.textTertiary,
              size: 48.sp,
            ),
            SizedBox(height: HoorSpacing.md),
            Text(
              emptyMessage ?? 'لا توجد بيانات',
              style: HoorTypography.bodyMedium.copyWith(
                color: HoorColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class HoorDataColumn {
  final String title;
  final int flex;
  final HoorColumnAlignment alignment;

  const HoorDataColumn({
    required this.title,
    this.flex = 1,
    this.alignment = HoorColumnAlignment.start,
  });
}

enum HoorColumnAlignment {
  start,
  center,
  end,
}

/// ═══════════════════════════════════════════════════════════════════════════
/// Simple Key-Value Table
/// ═══════════════════════════════════════════════════════════════════════════

class HoorKeyValueTable extends StatelessWidget {
  final List<HoorKeyValuePair> items;
  final bool showDividers;
  final EdgeInsetsGeometry? padding;

  const HoorKeyValueTable({
    super.key,
    required this.items,
    this.showDividers = true,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: items.asMap().entries.map((entry) {
        final index = entry.key;
        final item = entry.value;
        final isLast = index == items.length - 1;

        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: padding ??
                  EdgeInsets.symmetric(
                    horizontal: HoorSpacing.md,
                    vertical: HoorSpacing.sm,
                  ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 2,
                    child: Text(
                      item.key,
                      style: HoorTypography.bodyMedium.copyWith(
                        color: HoorColors.textSecondary,
                      ),
                    ),
                  ),
                  SizedBox(width: HoorSpacing.md),
                  Expanded(
                    flex: 3,
                    child: item.valueWidget ??
                        Text(
                          item.value ?? '-',
                          style: HoorTypography.bodyMedium.copyWith(
                            color: HoorColors.textPrimary,
                            fontWeight:
                                item.isBold ? FontWeight.w600 : FontWeight.w400,
                          ),
                          textAlign: TextAlign.start,
                        ),
                  ),
                ],
              ),
            ),
            if (showDividers && !isLast) const Divider(height: 1),
          ],
        );
      }).toList(),
    );
  }
}

class HoorKeyValuePair {
  final String key;
  final String? value;
  final Widget? valueWidget;
  final bool isBold;

  const HoorKeyValuePair({
    required this.key,
    this.value,
    this.valueWidget,
    this.isBold = false,
  });
}

/// ═══════════════════════════════════════════════════════════════════════════
/// Financial Summary Table
/// ═══════════════════════════════════════════════════════════════════════════

class HoorFinancialSummary extends StatelessWidget {
  final List<HoorFinancialRow> rows;
  final String? totalLabel;
  final String? totalValue;
  final Color? totalColor;
  final EdgeInsetsGeometry? padding;

  const HoorFinancialSummary({
    super.key,
    required this.rows,
    this.totalLabel,
    this.totalValue,
    this.totalColor,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        ...rows.map((row) => _buildRow(row)),
        if (totalLabel != null && totalValue != null) ...[
          const Divider(height: 1),
          SizedBox(height: HoorSpacing.xs),
          _buildTotalRow(),
        ],
      ],
    );
  }

  Widget _buildRow(HoorFinancialRow row) {
    return Padding(
      padding: padding ??
          EdgeInsets.symmetric(
            horizontal: HoorSpacing.md,
            vertical: HoorSpacing.xs,
          ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              if (row.icon != null) ...[
                Icon(
                  row.icon,
                  size: HoorIconSize.sm,
                  color: row.color ?? HoorColors.textSecondary,
                ),
                SizedBox(width: HoorSpacing.xs),
              ],
              Text(
                row.label,
                style: HoorTypography.bodyMedium.copyWith(
                  color: HoorColors.textSecondary,
                ),
              ),
            ],
          ),
          Text(
            row.value,
            style: HoorTypography.numericTable.copyWith(
              color: row.color ?? HoorColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTotalRow() {
    return Padding(
      padding: padding ??
          EdgeInsets.symmetric(
            horizontal: HoorSpacing.md,
            vertical: HoorSpacing.sm,
          ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            totalLabel!,
            style: HoorTypography.titleMedium.copyWith(
              color: HoorColors.textPrimary,
            ),
          ),
          Text(
            totalValue!,
            style: HoorTypography.numericMedium.copyWith(
              color: totalColor ?? HoorColors.primary,
            ),
          ),
        ],
      ),
    );
  }
}

class HoorFinancialRow {
  final String label;
  final String value;
  final IconData? icon;
  final Color? color;

  const HoorFinancialRow({
    required this.label,
    required this.value,
    this.icon,
    this.color,
  });
}
