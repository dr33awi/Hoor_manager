// ═══════════════════════════════════════════════════════════════════════════
// Recent Transactions List Component
// Displays the most recent financial transactions FROM REAL DATABASE
// ═══════════════════════════════════════════════════════════════════════════

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/design_tokens.dart';
import '../../../core/providers/app_providers.dart';
import '../../../data/database/app_database.dart';

/// Transaction types for visual differentiation
enum TransactionType {
  sale,
  purchase,
  saleReturn,
  purchaseReturn,
  receiptVoucher,
  paymentVoucher,
  expense,
}

/// Transaction status
enum TransactionStatus {
  completed,
  pending,
  overdue,
  cancelled,
}

/// Transaction data model (mapped from real data)
class TransactionItem {
  const TransactionItem({
    required this.id,
    required this.type,
    required this.title,
    required this.subtitle,
    required this.amount,
    required this.dateTime,
    required this.status,
    this.customerName,
    this.supplierName,
  });

  final String id;
  final TransactionType type;
  final String title;
  final String subtitle;
  final double amount;
  final DateTime dateTime;
  final TransactionStatus status;
  final String? customerName;
  final String? supplierName;

  /// Create from Invoice
  factory TransactionItem.fromInvoice(Invoice invoice,
      {String? customerName, String? supplierName}) {
    final type = switch (invoice.type) {
      'sale' => TransactionType.sale,
      'purchase' => TransactionType.purchase,
      'sale_return' => TransactionType.saleReturn,
      'purchase_return' => TransactionType.purchaseReturn,
      _ => TransactionType.sale,
    };

    final typeLabel = switch (invoice.type) {
      'sale' => 'فاتورة بيع',
      'purchase' => 'فاتورة شراء',
      'sale_return' => 'مرتجع مبيعات',
      'purchase_return' => 'مرتجع مشتريات',
      _ => 'فاتورة',
    };

    final isIncome =
        invoice.type == 'sale' || invoice.type == 'purchase_return';

    return TransactionItem(
      id: invoice.id,
      type: type,
      title: '$typeLabel #${invoice.invoiceNumber.split('-').last}',
      subtitle: invoice.paymentMethod == 'cash' ? 'نقداً' : 'آجل',
      amount: isIncome ? invoice.total : -invoice.total,
      dateTime: invoice.invoiceDate,
      status: _mapStatus(invoice.status),
      customerName: customerName,
      supplierName: supplierName,
    );
  }

  /// Create from Voucher
  factory TransactionItem.fromVoucher(Voucher voucher,
      {String? customerName, String? supplierName}) {
    final type = switch (voucher.type) {
      'receipt' => TransactionType.receiptVoucher,
      'payment' => TransactionType.paymentVoucher,
      'expense' => TransactionType.expense,
      _ => TransactionType.expense,
    };

    final typeLabel = switch (voucher.type) {
      'receipt' => 'سند قبض',
      'payment' => 'سند دفع',
      'expense' => 'سند مصاريف',
      _ => 'سند',
    };

    final isIncome = voucher.type == 'receipt';

    return TransactionItem(
      id: voucher.id,
      type: type,
      title: '$typeLabel #${voucher.voucherNumber.split('-').last}',
      subtitle: voucher.description ?? '',
      amount: isIncome ? voucher.amount : -voucher.amount,
      dateTime: voucher.voucherDate,
      status: TransactionStatus.completed,
      customerName: customerName,
      supplierName: supplierName,
    );
  }

  static TransactionStatus _mapStatus(String status) {
    return switch (status) {
      'completed' => TransactionStatus.completed,
      'pending' => TransactionStatus.pending,
      'overdue' => TransactionStatus.overdue,
      'cancelled' => TransactionStatus.cancelled,
      _ => TransactionStatus.completed,
    };
  }
}

/// Provider for recent transactions (combines invoices and vouchers)
final recentTransactionsProvider =
    FutureProvider<List<TransactionItem>>((ref) async {
  final db = ref.watch(databaseProvider);

  // Get recent transactions from the last 7 days
  final now = DateTime.now();
  final sevenDaysAgo = now.subtract(const Duration(days: 7));

  // Fetch invoices
  final invoices = await db.getInvoicesByDateRange(sevenDaysAgo, now);

  // Fetch vouchers
  final vouchers = await db.getVouchersByDateRange(sevenDaysAgo, now);

  // Fetch customers and suppliers for names
  final customers = await db.getAllCustomers();
  final suppliers = await db.getAllSuppliers();

  final customerMap = {for (var c in customers) c.id: c.name};
  final supplierMap = {for (var s in suppliers) s.id: s.name};

  // Convert to TransactionItems
  final List<TransactionItem> transactions = [];

  for (final invoice in invoices) {
    transactions.add(TransactionItem.fromInvoice(
      invoice,
      customerName:
          invoice.customerId != null ? customerMap[invoice.customerId] : null,
      supplierName:
          invoice.supplierId != null ? supplierMap[invoice.supplierId] : null,
    ));
  }

  for (final voucher in vouchers) {
    transactions.add(TransactionItem.fromVoucher(
      voucher,
      customerName:
          voucher.customerId != null ? customerMap[voucher.customerId] : null,
      supplierName:
          voucher.supplierId != null ? supplierMap[voucher.supplierId] : null,
    ));
  }

  // Sort by date descending
  transactions.sort((a, b) => b.dateTime.compareTo(a.dateTime));

  return transactions;
});

class RecentTransactionsList extends ConsumerWidget {
  const RecentTransactionsList({
    super.key,
    this.maxItems = 5,
  });

  final int maxItems;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final transactionsAsync = ref.watch(recentTransactionsProvider);

    return transactionsAsync.when(
      loading: () => _buildLoadingState(),
      error: (error, _) => _buildErrorState(error.toString()),
      data: (transactions) {
        if (transactions.isEmpty) {
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
              for (int i = 0; i < transactions.take(maxItems).length; i++) ...[
                _TransactionRow(
                  transaction: transactions[i],
                  onTap: () {
                    HapticFeedback.lightImpact();
                    _navigateToTransaction(context, transactions[i]);
                  },
                ),
                if (i < transactions.take(maxItems).length - 1)
                  Divider(
                    height: 1,
                    color: AppColors.divider,
                    indent:
                        AppSpacing.md.w + AppIconSize.xl.w + AppSpacing.md.w,
                  ),
              ],
            ],
          ),
        );
      },
    );
  }

  void _navigateToTransaction(
      BuildContext context, TransactionItem transaction) {
    switch (transaction.type) {
      case TransactionType.sale:
      case TransactionType.purchase:
      case TransactionType.saleReturn:
      case TransactionType.purchaseReturn:
        context.push('/invoices/${transaction.id}');
        break;
      case TransactionType.receiptVoucher:
      case TransactionType.paymentVoucher:
      case TransactionType.expense:
        context.push('/vouchers');
        break;
    }
  }

  Widget _buildLoadingState() {
    return Container(
      padding: EdgeInsets.all(AppSpacing.xxl.w),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.border),
      ),
      child: const Center(
        child: CircularProgressIndicator(),
      ),
    );
  }

  Widget _buildErrorState(String error) {
    return Container(
      padding: EdgeInsets.all(AppSpacing.xxl.w),
      decoration: BoxDecoration(
        color: AppColors.expenseSurface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.expense.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Icon(
            Icons.error_outline_rounded,
            color: AppColors.expense,
            size: AppIconSize.huge,
          ),
          SizedBox(height: AppSpacing.md.h),
          Text(
            'حدث خطأ في تحميل المعاملات',
            style: AppTypography.titleMedium.copyWith(
              color: AppColors.expense,
            ),
          ),
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
}

class _TransactionRow extends StatelessWidget {
  const _TransactionRow({
    required this.transaction,
    this.onTap,
  });

  final TransactionItem transaction;
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
                          Flexible(
                            child: Text(
                              transaction.customerName!,
                              style: AppTypography.bodySmall.copyWith(
                                color: AppColors.textSecondary,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          SizedBox(width: AppSpacing.sm.w),
                        ] else if (transaction.supplierName != null) ...[
                          Icon(
                            Icons.business_outlined,
                            color: AppColors.textTertiary,
                            size: AppIconSize.xs,
                          ),
                          SizedBox(width: AppSpacing.xxxs.w),
                          Flexible(
                            child: Text(
                              transaction.supplierName!,
                              style: AppTypography.bodySmall.copyWith(
                                color: AppColors.textSecondary,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          SizedBox(width: AppSpacing.sm.w),
                        ],
                        if (transaction.subtitle.isNotEmpty)
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
      TransactionType.saleReturn => (
          icon: Icons.replay_outlined,
          color: AppColors.warning
        ),
      TransactionType.purchaseReturn => (
          icon: Icons.replay_outlined,
          color: AppColors.info
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

    if (diff.inMinutes < 1) {
      return 'الآن';
    } else if (diff.inMinutes < 60) {
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
