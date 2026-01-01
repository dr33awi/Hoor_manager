// ═══════════════════════════════════════════════════════════════════════════
// Recent Transactions List Component
// Displays the most recent financial transactions
// ═══════════════════════════════════════════════════════════════════════════

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/pro/design_tokens.dart';

/// Transaction types for visual differentiation
enum TransactionType {
  sale,
  purchase,
  receiptVoucher,
  paymentVoucher,
  expense,
  refund,
}

/// Transaction status
enum TransactionStatus {
  completed,
  pending,
  overdue,
  cancelled,
}

/// Transaction data model
class Transaction {
  const Transaction({
    required this.id,
    required this.type,
    required this.title,
    required this.subtitle,
    required this.amount,
    required this.dateTime,
    required this.status,
    this.customerName,
  });

  final String id;
  final TransactionType type;
  final String title;
  final String subtitle;
  final double amount;
  final DateTime dateTime;
  final TransactionStatus status;
  final String? customerName;
}

class RecentTransactionsList extends StatelessWidget {
  const RecentTransactionsList({
    super.key,
    this.transactions,
    this.onTransactionTap,
    this.maxItems = 5,
  });

  final List<Transaction>? transactions;
  final void Function(Transaction)? onTransactionTap;
  final int maxItems;

  @override
  Widget build(BuildContext context) {
    // Sample data - replace with actual data
    final items = transactions ?? _sampleTransactions;

    if (items.isEmpty) {
      return _buildEmptyState();
    }

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.border),
        boxShadow: AppShadows.card,
      ),
      child: Column(
        children: [
          for (int i = 0; i < items.take(maxItems).length; i++) ...[
            _TransactionRow(
              transaction: items[i],
              onTap: () {
                HapticFeedback.lightImpact();
                onTransactionTap?.call(items[i]);
              },
            ),
            if (i < items.take(maxItems).length - 1)
              Divider(
                height: 1,
                color: AppColors.divider,
                indent: AppSpacing.md.w + AppIconSize.xl.w + AppSpacing.md.w,
              ),
          ],
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      padding: EdgeInsets.all(AppSpacing.xxl.w),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          Icon(
            Icons.receipt_long_outlined,
            color: AppColors.textTertiary,
            size: AppIconSize.huge,
          ),
          SizedBox(height: AppSpacing.md.h),
          Text(
            'لا توجد معاملات حديثة',
            style: AppTypography.titleMedium.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          SizedBox(height: AppSpacing.xs.h),
          Text(
            'ستظهر هنا آخر المعاملات المالية',
            style: AppTypography.bodySmall.copyWith(
              color: AppColors.textTertiary,
            ),
          ),
        ],
      ),
    );
  }

  static final _sampleTransactions = [
    Transaction(
      id: 'INV-1234',
      type: TransactionType.sale,
      title: 'فاتورة بيع #1234',
      subtitle: '3 منتجات',
      amount: 1500.00,
      dateTime: DateTime.now().subtract(const Duration(hours: 1)),
      status: TransactionStatus.completed,
      customerName: 'أحمد محمد',
    ),
    Transaction(
      id: 'PUR-567',
      type: TransactionType.purchase,
      title: 'فاتورة شراء #567',
      subtitle: 'مورد الأمانة',
      amount: -3200.00,
      dateTime: DateTime.now().subtract(const Duration(hours: 3)),
      status: TransactionStatus.pending,
    ),
    Transaction(
      id: 'RV-89',
      type: TransactionType.receiptVoucher,
      title: 'سند قبض #89',
      subtitle: 'تحصيل مستحقات',
      amount: 500.00,
      dateTime: DateTime.now().subtract(const Duration(hours: 5)),
      status: TransactionStatus.completed,
      customerName: 'خالد علي',
    ),
    Transaction(
      id: 'INV-1233',
      type: TransactionType.sale,
      title: 'فاتورة بيع #1233',
      subtitle: '1 منتج',
      amount: 750.00,
      dateTime: DateTime.now().subtract(const Duration(days: 1)),
      status: TransactionStatus.completed,
      customerName: 'سارة أحمد',
    ),
    Transaction(
      id: 'PV-45',
      type: TransactionType.paymentVoucher,
      title: 'سند صرف #45',
      subtitle: 'دفعة للمورد',
      amount: -1200.00,
      dateTime: DateTime.now().subtract(const Duration(days: 1, hours: 2)),
      status: TransactionStatus.completed,
    ),
  ];
}

class _TransactionRow extends StatelessWidget {
  const _TransactionRow({
    required this.transaction,
    this.onTap,
  });

  final Transaction transaction;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final isIncome = transaction.amount > 0;
    final typeInfo = _getTypeInfo(transaction.type);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: EdgeInsets.all(AppSpacing.md.w),
          child: Row(
            children: [
              // Type Icon
              Container(
                padding: EdgeInsets.all(AppSpacing.sm.w),
                decoration: BoxDecoration(
                  color: typeInfo.color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
                child: Icon(
                  typeInfo.icon,
                  color: typeInfo.color,
                  size: AppIconSize.md,
                ),
              ),
              SizedBox(width: AppSpacing.md.w),

              // Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            transaction.title,
                            style: AppTypography.titleSmall.copyWith(
                              color: AppColors.textPrimary,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        _buildStatusBadge(transaction.status),
                      ],
                    ),
                    SizedBox(height: AppSpacing.xxxs.h),
                    Row(
                      children: [
                        if (transaction.customerName != null) ...[
                          Icon(
                            Icons.person_outline_rounded,
                            color: AppColors.textTertiary,
                            size: AppIconSize.xs,
                          ),
                          SizedBox(width: AppSpacing.xxxs.w),
                          Text(
                            transaction.customerName!,
                            style: AppTypography.bodySmall.copyWith(
                              color: AppColors.textSecondary,
                            ),
                          ),
                          SizedBox(width: AppSpacing.sm.w),
                        ],
                        Text(
                          transaction.subtitle,
                          style: AppTypography.bodySmall.copyWith(
                            color: AppColors.textTertiary,
                          ),
                        ),
                        const Spacer(),
                        Text(
                          _formatTime(transaction.dateTime),
                          style: AppTypography.caption.copyWith(
                            color: AppColors.textTertiary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              SizedBox(width: AppSpacing.md.w),

              // Amount
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '${isIncome ? '+' : ''}${_formatAmount(transaction.amount)}',
                    style: AppTypography.moneySmall.copyWith(
                      color: isIncome ? AppColors.income : AppColors.expense,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    'ر.س',
                    style: AppTypography.caption.copyWith(
                      color: AppColors.textTertiary,
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

  Widget _buildStatusBadge(TransactionStatus status) {
    final statusInfo = _getStatusInfo(status);

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: AppSpacing.xs.w,
        vertical: AppSpacing.xxxs.h,
      ),
      decoration: BoxDecoration(
        color: statusInfo.color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppRadius.full),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6.w,
            height: 6.w,
            decoration: BoxDecoration(
              color: statusInfo.color,
              shape: BoxShape.circle,
            ),
          ),
          SizedBox(width: AppSpacing.xxs.w),
          Text(
            statusInfo.label,
            style: AppTypography.caption.copyWith(
              color: statusInfo.color,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  ({IconData icon, Color color}) _getTypeInfo(TransactionType type) {
    return switch (type) {
      TransactionType.sale => (
          icon: Icons.receipt_long_outlined,
          color: AppColors.sales
        ),
      TransactionType.purchase => (
          icon: Icons.shopping_cart_outlined,
          color: AppColors.purchases
        ),
      TransactionType.receiptVoucher => (
          icon: Icons.payments_outlined,
          color: AppColors.income
        ),
      TransactionType.paymentVoucher => (
          icon: Icons.money_off_outlined,
          color: AppColors.expense
        ),
      TransactionType.expense => (
          icon: Icons.account_balance_wallet_outlined,
          color: AppColors.expense
        ),
      TransactionType.refund => (
          icon: Icons.replay_outlined,
          color: AppColors.warning
        ),
    };
  }

  ({String label, Color color}) _getStatusInfo(TransactionStatus status) {
    return switch (status) {
      TransactionStatus.completed => (label: 'مكتمل', color: AppColors.income),
      TransactionStatus.pending => (label: 'معلق', color: AppColors.warning),
      TransactionStatus.overdue => (label: 'متأخر', color: AppColors.expense),
      TransactionStatus.cancelled => (
          label: 'ملغي',
          color: AppColors.textTertiary
        ),
    };
  }

  String _formatAmount(double amount) {
    final formatter = NumberFormat('#,##0.00', 'ar');
    return formatter.format(amount.abs());
  }

  String _formatTime(DateTime dateTime) {
    final now = DateTime.now();
    final diff = now.difference(dateTime);

    if (diff.inMinutes < 60) {
      return 'منذ ${diff.inMinutes} دقيقة';
    } else if (diff.inHours < 24) {
      return 'منذ ${diff.inHours} ساعة';
    } else if (diff.inDays == 1) {
      return 'أمس';
    } else if (diff.inDays < 7) {
      return 'منذ ${diff.inDays} أيام';
    } else {
      return DateFormat('d/M').format(dateTime);
    }
  }
}
