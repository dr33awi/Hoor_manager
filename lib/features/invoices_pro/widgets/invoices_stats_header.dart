// ═══════════════════════════════════════════════════════════════════════════
// Invoices Stats Header Widget
// Summary cards showing invoice statistics
// ═══════════════════════════════════════════════════════════════════════════

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../core/theme/pro/design_tokens.dart';

class InvoicesStatsHeader extends StatelessWidget {
  final bool isSales;
  final double totalAmount;
  final double paidAmount;
  final double pendingAmount;
  final double overdueAmount;

  const InvoicesStatsHeader({
    super.key,
    required this.isSales,
    required this.totalAmount,
    required this.paidAmount,
    required this.pendingAmount,
    required this.overdueAmount,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 100.h,
      margin: EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      child: Row(
        children: [
          Expanded(
            child: _StatCard(
              label: 'الإجمالي',
              amount: totalAmount,
              icon: Icons.receipt_long_rounded,
              color: isSales ? AppColors.success : AppColors.secondary,
            ),
          ),
          SizedBox(width: AppSpacing.sm),
          Expanded(
            child: _StatCard(
              label: 'المحصل',
              amount: paidAmount,
              icon: Icons.check_circle_outline_rounded,
              color: AppColors.success,
            ),
          ),
          SizedBox(width: AppSpacing.sm),
          Expanded(
            child: _StatCard(
              label: 'معلق',
              amount: pendingAmount,
              icon: Icons.schedule_rounded,
              color: AppColors.warning,
            ),
          ),
          if (overdueAmount > 0) ...[
            SizedBox(width: AppSpacing.sm),
            Expanded(
              child: _StatCard(
                label: 'متأخر',
                amount: overdueAmount,
                icon: Icons.warning_amber_rounded,
                color: AppColors.error,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final double amount;
  final IconData icon;
  final Color color;

  const _StatCard({
    required this.label,
    required this.amount,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: AppIconSize.sm, color: color),
          SizedBox(height: AppSpacing.xs),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              _formatAmount(amount),
              style: AppTypography.titleMedium.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w700,
                fontFamily: 'JetBrains Mono',
              ),
            ),
          ),
          Text(
            label,
            style: AppTypography.labelSmall.copyWith(
              color: AppColors.textTertiary,
            ),
          ),
        ],
      ),
    );
  }

  String _formatAmount(double amount) {
    if (amount >= 1000000) {
      return '${(amount / 1000000).toStringAsFixed(1)}M';
    } else if (amount >= 1000) {
      return '${(amount / 1000).toStringAsFixed(1)}K';
    }
    return amount.toStringAsFixed(0);
  }
}
