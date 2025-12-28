import 'package:flutter/material.dart';

import '../../../../core/constants/constants.dart';
import '../../../../core/extensions/extensions.dart';
import '../../domain/entities/entities.dart';

/// بطاقة عرض الفاتورة
class InvoiceCard extends StatelessWidget {
  final InvoiceEntity invoice;
  final VoidCallback? onTap;

  const InvoiceCard({
    super.key,
    required this.invoice,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(
        horizontal: AppSizes.md,
        vertical: AppSizes.xs,
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppSizes.radiusMd),
        child: Padding(
          padding: const EdgeInsets.all(AppSizes.md),
          child: Column(
            children: [
              // الصف الأول: رقم الفاتورة والحالة
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '#${invoice.invoiceNumber}',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  _buildStatusChip(context),
                ],
              ),
              const SizedBox(height: AppSizes.sm),

              // الصف الثاني: التاريخ وعدد المنتجات
              Row(
                children: [
                  Icon(
                    Icons.access_time,
                    size: 16,
                    color: AppColors.textSecondary,
                  ),
                  const SizedBox(width: AppSizes.xs),
                  Text(
                    invoice.saleDate.toRelativeDate(),
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                  ),
                  const Spacer(),
                  Icon(
                    Icons.shopping_bag_outlined,
                    size: 16,
                    color: AppColors.textSecondary,
                  ),
                  const SizedBox(width: AppSizes.xs),
                  Text(
                    '${invoice.itemCount} منتج',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                  ),
                ],
              ),

              const Divider(height: AppSizes.lg),

              // الصف الثالث: الإجمالي والربح
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'الإجمالي',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppColors.textSecondary,
                            ),
                      ),
                      Text(
                        invoice.total.toCurrency(),
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              color: AppColors.primary,
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                    ],
                  ),
                  if (invoice.isCompleted)
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          'الربح',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: AppColors.textSecondary,
                              ),
                        ),
                        Text(
                          invoice.profit.toCurrency(),
                          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                color: AppColors.success,
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                      ],
                    ),
                ],
              ),

              // الخصم إن وجد
              if (invoice.hasDiscount) ...[
                const SizedBox(height: AppSizes.sm),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSizes.sm,
                    vertical: AppSizes.xs,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.error.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(AppSizes.radiusSm),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.local_offer,
                        size: 14,
                        color: AppColors.error,
                      ),
                      const SizedBox(width: AppSizes.xs),
                      Text(
                        'خصم ${invoice.discount.description}',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppColors.error,
                            ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusChip(BuildContext context) {
    Color bgColor;
    Color textColor;
    String text;

    if (invoice.isCompleted) {
      bgColor = AppColors.success.withOpacity(0.1);
      textColor = AppColors.success;
      text = 'مكتملة';
    } else {
      bgColor = AppColors.error.withOpacity(0.1);
      textColor = AppColors.error;
      text = 'ملغاة';
    }

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSizes.sm,
        vertical: AppSizes.xs,
      ),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(AppSizes.radiusSm),
      ),
      child: Text(
        text,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: textColor,
              fontWeight: FontWeight.bold,
            ),
      ),
    );
  }
}
