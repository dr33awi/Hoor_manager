// ═══════════════════════════════════════════════════════════════════════════
// Invoice Card Pro Widget
// Modern invoice list card with status and payment info
// ═══════════════════════════════════════════════════════════════════════════

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../core/theme/design_tokens.dart';

class InvoiceCardPro extends StatelessWidget {
  final Map<String, dynamic> invoice;
  final bool isSales;
  final VoidCallback onTap;

  const InvoiceCardPro({
    super.key,
    required this.invoice,
    required this.isSales,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final status = invoice['status'] as String;
    final total = invoice['total'] as double;
    final paid = invoice['paid'] as double;
    final remaining = total - paid;
    final paymentProgress = paid / total;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        child: Container(
          padding: EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(AppRadius.lg),
            border: Border.all(
              color: status == 'overdue'
                  ? AppColors.error.border
                  : AppColors.border,
            ),
            boxShadow: AppShadows.xs,
          ),
          child: Column(
            children: [
              // ═══════════════════════════════════════════════════════════════
              // Header Row
              // ═══════════════════════════════════════════════════════════════
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Invoice Icon
                  Container(
                    padding: EdgeInsets.all(AppSpacing.sm),
                    decoration: BoxDecoration(
                      color: _getStatusColor(status).soft,
                      borderRadius: BorderRadius.circular(AppRadius.md),
                    ),
                    child: Icon(
                      isSales
                          ? Icons.arrow_upward_rounded
                          : Icons.arrow_downward_rounded,
                      color: _getStatusColor(status),
                      size: AppIconSize.md,
                    ),
                  ),
                  SizedBox(width: AppSpacing.md),

                  // Invoice Info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                invoice['customer'],
                                style: AppTypography.titleSmall.copyWith(
                                  color: AppColors.textPrimary,
                                  fontWeight: FontWeight.w600,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            _buildStatusBadge(status),
                          ],
                        ),
                        SizedBox(height: 4.h),
                        Row(
                          children: [
                            Text(
                              invoice['id'],
                              style: AppTypography.bodySmall.copyWith(
                                color: AppColors.secondary,
                                fontFamily: 'JetBrains Mono',
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            SizedBox(width: AppSpacing.sm),
                            Text(
                              '•',
                              style: TextStyle(color: AppColors.textTertiary),
                            ),
                            SizedBox(width: AppSpacing.sm),
                            Text(
                              invoice['date'],
                              style: AppTypography.bodySmall.copyWith(
                                color: AppColors.textTertiary,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              SizedBox(height: AppSpacing.md),

              // ═══════════════════════════════════════════════════════════════
              // Payment Progress (for partial payments)
              // ═══════════════════════════════════════════════════════════════
              if (status == 'partial') ...[
                Column(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(AppRadius.full),
                      child: LinearProgressIndicator(
                        value: paymentProgress,
                        backgroundColor: AppColors.border,
                        valueColor: AlwaysStoppedAnimation(AppColors.success),
                        minHeight: 6.h,
                      ),
                    ),
                    SizedBox(height: AppSpacing.xs),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'تم دفع ${(paymentProgress * 100).toInt()}%',
                          style: AppTypography.labelSmall.copyWith(
                            color: AppColors.success,
                          ),
                        ),
                        Text(
                          'متبقي: ${remaining.toStringAsFixed(0)} ر.س',
                          style: AppTypography.labelSmall.copyWith(
                            color: AppColors.warning,
                            fontFamily: 'JetBrains Mono',
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                SizedBox(height: AppSpacing.sm),
              ],

              // ═══════════════════════════════════════════════════════════════
              // Footer Row
              // ═══════════════════════════════════════════════════════════════
              Container(
                padding: EdgeInsets.all(AppSpacing.sm),
                decoration: BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Items Count
                    Row(
                      children: [
                        Icon(
                          Icons.inventory_2_outlined,
                          size: AppIconSize.xs,
                          color: AppColors.textTertiary,
                        ),
                        SizedBox(width: AppSpacing.xs),
                        Text(
                          '${invoice['items']} صنف',
                          style: AppTypography.bodySmall.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),

                    // Due Date (if pending)
                    if (invoice['dueDate'] != null && status != 'paid')
                      Row(
                        children: [
                          Icon(
                            status == 'overdue'
                                ? Icons.warning_amber_rounded
                                : Icons.event_outlined,
                            size: AppIconSize.xs,
                            color: status == 'overdue'
                                ? AppColors.error
                                : AppColors.textTertiary,
                          ),
                          SizedBox(width: AppSpacing.xs),
                          Text(
                            'استحقاق: ${invoice['dueDate']}',
                            style: AppTypography.bodySmall.copyWith(
                              color: status == 'overdue'
                                  ? AppColors.error
                                  : AppColors.textTertiary,
                            ),
                          ),
                        ],
                      ),

                    // Total Amount
                    Text(
                      '${total.toStringAsFixed(0)} ر.س',
                      style: AppTypography.titleMedium.copyWith(
                        color:
                            isSales ? AppColors.success : AppColors.secondary,
                        fontWeight: FontWeight.w700,
                        fontFamily: 'JetBrains Mono',
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    String label;
    Color color;

    switch (status) {
      case 'paid':
        label = 'مدفوعة';
        color = AppColors.success;
        break;
      case 'partial':
        label = 'جزئية';
        color = AppColors.warning;
        break;
      case 'overdue':
        label = 'متأخرة';
        color = AppColors.error;
        break;
      default:
        label = 'معلقة';
        color = AppColors.textTertiary;
    }

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: color.soft,
        borderRadius: BorderRadius.circular(AppRadius.full),
      ),
      child: Text(
        label,
        style: AppTypography.labelSmall.copyWith(
          color: color,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'paid':
        return AppColors.success;
      case 'partial':
        return AppColors.warning;
      case 'overdue':
        return AppColors.error;
      default:
        return AppColors.textSecondary;
    }
  }
}
