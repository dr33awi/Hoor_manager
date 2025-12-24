import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/constants.dart';
import '../../../../core/extensions/extensions.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../data/services/invoice_pdf_service.dart';
import '../../domain/entities/entities.dart';
import '../providers/sales_providers.dart';

/// شاشة تفاصيل الفاتورة
class InvoiceDetailsScreen extends ConsumerWidget {
  final String invoiceId;

  const InvoiceDetailsScreen({super.key, required this.invoiceId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final invoiceAsync = ref.watch(invoiceProvider(invoiceId));

    return invoiceAsync.when(
      data: (invoice) {
        if (invoice == null) {
          return Scaffold(
            appBar: AppBar(),
            body: const Center(child: Text('الفاتورة غير موجودة')),
          );
        }
        return _buildContent(context, ref, invoice);
      },
      loading: () => Scaffold(
        appBar: AppBar(),
        body: const Center(child: CircularProgressIndicator()),
      ),
      error: (e, _) => Scaffold(
        appBar: AppBar(),
        body: Center(child: Text('خطأ: $e')),
      ),
    );
  }

  Widget _buildContent(BuildContext context, WidgetRef ref, InvoiceEntity invoice) {
    return Scaffold(
      appBar: AppBar(
        title: Text('#${invoice.invoiceNumber}'),
        actions: [
          IconButton(
            icon: const Icon(Icons.print),
            onPressed: () => _printInvoice(context, invoice),
            tooltip: 'طباعة',
          ),
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: () => _shareInvoice(context, invoice),
            tooltip: 'مشاركة',
          ),
          if (invoice.isCompleted)
            PopupMenuButton<String>(
              onSelected: (value) {
                if (value == 'cancel') {
                  _confirmCancel(context, ref, invoice);
                }
              },
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'cancel',
                  child: Row(
                    children: [
                      Icon(Icons.cancel_outlined, color: AppColors.error),
                      SizedBox(width: AppSizes.sm),
                      Text('إلغاء الفاتورة', style: TextStyle(color: AppColors.error)),
                    ],
                  ),
                ),
              ],
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSizes.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // حالة الفاتورة
            _buildStatusBanner(context, invoice),
            const SizedBox(height: AppSizes.md),

            // معلومات الفاتورة
            _buildInfoCard(context, invoice),
            const SizedBox(height: AppSizes.md),

            // قائمة المنتجات
            _buildItemsCard(context, invoice),
            const SizedBox(height: AppSizes.md),

            // الإجماليات
            _buildTotalsCard(context, invoice),

            // سبب الإلغاء
            if (invoice.isCancelled && invoice.cancellationReason != null) ...[
              const SizedBox(height: AppSizes.md),
              _buildCancellationCard(context, invoice),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStatusBanner(BuildContext context, InvoiceEntity invoice) {
    Color bgColor;
    Color textColor;
    IconData icon;
    String text;

    if (invoice.isCompleted) {
      bgColor = AppColors.success.withOpacity(0.1);
      textColor = AppColors.success;
      icon = Icons.check_circle;
      text = 'فاتورة مكتملة';
    } else {
      bgColor = AppColors.error.withOpacity(0.1);
      textColor = AppColors.error;
      icon = Icons.cancel;
      text = 'فاتورة ملغاة';
    }

    return Container(
      padding: const EdgeInsets.all(AppSizes.md),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(AppSizes.radiusMd),
      ),
      child: Row(
        children: [
          Icon(icon, color: textColor),
          const SizedBox(width: AppSizes.sm),
          Text(
            text,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: textColor,
                  fontWeight: FontWeight.bold,
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard(BuildContext context, InvoiceEntity invoice) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSizes.md),
        child: Column(
          children: [
            _buildInfoRow(context, 'التاريخ', invoice.saleDate.toArabicDateTime()),
            const Divider(),
            _buildInfoRow(context, 'البائع', invoice.soldByName ?? '-'),
            const Divider(),
            _buildInfoRow(context, 'طريقة الدفع', invoice.paymentMethod.arabicName),
            if (invoice.customerName != null) ...[
              const Divider(),
              _buildInfoRow(context, 'العميل', invoice.customerName!),
            ],
            if (invoice.customerPhone != null) ...[
              const Divider(),
              _buildInfoRow(context, 'الهاتف', invoice.customerPhone!),
            ],
            if (invoice.notes != null) ...[
              const Divider(),
              _buildInfoRow(context, 'ملاحظات', invoice.notes!),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(BuildContext context, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSizes.xs),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.textSecondary,
                ),
          ),
          Text(
            value,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w500,
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildItemsCard(BuildContext context, InvoiceEntity invoice) {
    return Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(AppSizes.md),
            child: Text(
              'المنتجات (${invoice.itemCount})',
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ),
          const Divider(height: 1),
          ...invoice.items.map((item) => _buildItemRow(context, item)),
        ],
      ),
    );
  }

  Widget _buildItemRow(BuildContext context, CartItem item) {
    return Container(
      padding: const EdgeInsets.all(AppSizes.md),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.border, width: 0.5)),
      ),
      child: Row(
        children: [
          // صورة المنتج
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: AppColors.secondaryLight,
              borderRadius: BorderRadius.circular(AppSizes.radiusSm),
            ),
            child: item.productImage != null
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(AppSizes.radiusSm),
                    child: Image.network(item.productImage!, fit: BoxFit.cover),
                  )
                : const Icon(Icons.image, color: AppColors.textHint),
          ),
          const SizedBox(width: AppSizes.md),
          // تفاصيل المنتج
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.productName,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                ),
                Text(
                  '${item.color} - ${item.size}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                ),
              ],
            ),
          ),
          // الكمية والسعر
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                item.totalPrice.toCurrency(),
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              Text(
                '${item.quantity} × ${item.unitPrice.toCurrency()}',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.textSecondary,
                    ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTotalsCard(BuildContext context, InvoiceEntity invoice) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSizes.md),
        child: Column(
          children: [
            _buildTotalRow(context, 'المجموع الفرعي', invoice.subtotal.toCurrency()),
            if (invoice.hasDiscount) ...[
              const SizedBox(height: AppSizes.sm),
              _buildTotalRow(
                context,
                'الخصم (${invoice.discount.description})',
                '- ${invoice.discountAmount.toCurrency()}',
                valueColor: AppColors.error,
              ),
            ],
            const Divider(),
            _buildTotalRow(
              context,
              'الإجمالي',
              invoice.total.toCurrency(),
              isLarge: true,
            ),
            const Divider(),
            _buildTotalRow(context, 'المبلغ المدفوع', invoice.amountPaid.toCurrency()),
            if (invoice.change > 0)
              _buildTotalRow(context, 'الباقي', invoice.change.toCurrency()),
            const Divider(),
            _buildTotalRow(
              context,
              'الربح',
              invoice.profit.toCurrency(),
              valueColor: AppColors.success,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTotalRow(
    BuildContext context,
    String label,
    String value, {
    Color? valueColor,
    bool isLarge = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSizes.xs),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: isLarge
                ? Theme.of(context).textTheme.titleMedium
                : Theme.of(context).textTheme.bodyMedium,
          ),
          Text(
            value,
            style: (isLarge
                    ? Theme.of(context).textTheme.titleLarge
                    : Theme.of(context).textTheme.bodyMedium)
                ?.copyWith(
              fontWeight: FontWeight.bold,
              color: valueColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCancellationCard(BuildContext context, InvoiceEntity invoice) {
    return Card(
      color: AppColors.error.withOpacity(0.1),
      child: Padding(
        padding: const EdgeInsets.all(AppSizes.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.info_outline, color: AppColors.error),
                const SizedBox(width: AppSizes.sm),
                Text(
                  'سبب الإلغاء',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        color: AppColors.error,
                      ),
                ),
              ],
            ),
            const SizedBox(height: AppSizes.sm),
            Text(invoice.cancellationReason!),
            if (invoice.cancelledAt != null) ...[
              const SizedBox(height: AppSizes.sm),
              Text(
                'تاريخ الإلغاء: ${invoice.cancelledAt!.toArabicDateTime()}',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _printInvoice(BuildContext context, InvoiceEntity invoice) async {
    try {
      await InvoicePdfService.printInvoice(invoice);
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('فشل الطباعة: $e')),
        );
      }
    }
  }

  Future<void> _shareInvoice(BuildContext context, InvoiceEntity invoice) async {
    try {
      await InvoicePdfService.shareInvoice(invoice);
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('فشل المشاركة: $e')),
        );
      }
    }
  }

  Future<void> _confirmCancel(
    BuildContext context,
    WidgetRef ref,
    InvoiceEntity invoice,
  ) async {
    final reasonController = TextEditingController();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('إلغاء الفاتورة'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('هل أنت متأكد من إلغاء هذه الفاتورة؟'),
            const Text(
              'سيتم استرجاع المخزون تلقائياً',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
            ),
            const SizedBox(height: AppSizes.md),
            TextField(
              controller: reasonController,
              decoration: const InputDecoration(
                labelText: 'سبب الإلغاء (اختياري)',
                border: OutlineInputBorder(),
              ),
              maxLines: 2,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text(AppStrings.cancel),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('إلغاء الفاتورة'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final user = ref.read(currentUserProvider);
      final success = await ref.read(salesActionsProvider.notifier).cancelInvoice(
            invoiceId: invoice.id,
            cancelledBy: user?.id ?? '',
            reason: reasonController.text.trim().isEmpty ? null : reasonController.text.trim(),
          );

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(success ? 'تم إلغاء الفاتورة' : 'فشل إلغاء الفاتورة'),
            backgroundColor: success ? AppColors.success : AppColors.error,
          ),
        );
      }
    }
  }
}
