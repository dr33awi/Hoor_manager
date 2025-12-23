// lib/features/sales/screens/sale_details_screen.dart
// شاشة تفاصيل الفاتورة

import 'package:hoor_manager/features/sales/providers/sale_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_theme.dart';
import '../models/sale_model.dart';

class SaleDetailsScreen extends StatelessWidget {
  final SaleModel sale;

  const SaleDetailsScreen({super.key, required this.sale});

  @override
  Widget build(BuildContext context) {
    final formatter = NumberFormat('#,##0.00', 'ar');
    final dateFormatter = DateFormat('dd MMMM yyyy - hh:mm a', 'ar');

    return Scaffold(
      appBar: AppBar(
        title: Text(sale.invoiceNumber),
        actions: [
          if (!sale.isCancelled)
            PopupMenuButton<String>(
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'print',
                  child: Row(
                    children: [
                      Icon(Icons.print),
                      SizedBox(width: 12),
                      Text('طباعة'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'share',
                  child: Row(
                    children: [
                      Icon(Icons.share),
                      SizedBox(width: 12),
                      Text('مشاركة'),
                    ],
                  ),
                ),
                if (sale.isCompleted)
                  const PopupMenuItem(
                    value: 'cancel',
                    child: Row(
                      children: [
                        Icon(Icons.cancel, color: AppTheme.errorColor),
                        SizedBox(width: 12),
                        Text(
                          'إلغاء الفاتورة',
                          style: TextStyle(color: AppTheme.errorColor),
                        ),
                      ],
                    ),
                  ),
              ],
              onSelected: (value) {
                switch (value) {
                  case 'print':
                    // TODO: طباعة
                    break;
                  case 'share':
                    // TODO: مشاركة
                    break;
                  case 'cancel':
                    _showCancelConfirmation(context);
                    break;
                }
              },
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // الحالة
            Center(
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: _getStatusColor().withOpacity(0.1),
                  borderRadius: BorderRadius.circular(30),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(_getStatusIcon(), color: _getStatusColor()),
                    const SizedBox(width: 8),
                    Text(
                      sale.status,
                      style: TextStyle(
                        color: _getStatusColor(),
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // معلومات الفاتورة
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildInfoRow(
                      'رقم الفاتورة',
                      sale.invoiceNumber,
                      Icons.receipt,
                    ),
                    const Divider(),
                    _buildInfoRow(
                      'التاريخ',
                      dateFormatter.format(sale.saleDate),
                      Icons.calendar_today,
                    ),
                    const Divider(),
                    _buildInfoRow(
                      'طريقة الدفع',
                      sale.paymentMethod,
                      _getPaymentIcon(),
                    ),
                    const Divider(),
                    _buildInfoRow('البائع', sale.userName, Icons.person),
                    if (sale.buyerName != null) ...[
                      const Divider(),
                      _buildInfoRow(
                        'المشتري',
                        sale.buyerName!,
                        Icons.person_outline,
                      ),
                    ],
                    if (sale.buyerPhone != null) ...[
                      const Divider(),
                      _buildInfoRow(
                        'هاتف المشتري',
                        sale.buyerPhone!,
                        Icons.phone,
                      ),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // المنتجات
            Text(
              'المنتجات',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Card(
              child: ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: sale.items.length,
                separatorBuilder: (_, __) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final item = sale.items[index];
                  return ListTile(
                    title: Text(item.productName),
                    subtitle: Text(
                      '${item.color} - مقاس ${item.size}',
                      style: TextStyle(color: AppTheme.grey600),
                    ),
                    trailing: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          '${formatter.format(item.totalPrice)} ر.س',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        Text(
                          '${item.quantity} × ${formatter.format(item.unitPrice)}',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppTheme.grey600,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 16),

            // الإجماليات
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    _buildSummaryRow(
                      'المجموع الفرعي',
                      '${formatter.format(sale.subtotal)} ر.س',
                    ),
                    if (sale.discount > 0) ...[
                      const SizedBox(height: 8),
                      _buildSummaryRow(
                        'الخصم${sale.discountPercent > 0 ? ' (${sale.discountPercent}%)' : ''}',
                        '- ${formatter.format(sale.discount)} ر.س',
                        color: AppTheme.errorColor,
                      ),
                    ],
                    if (sale.tax > 0) ...[
                      const SizedBox(height: 8),
                      _buildSummaryRow(
                        'الضريبة (${(AppConstants.defaultTaxRate * 100).toInt()}%)',
                        '${formatter.format(sale.tax)} ر.س',
                      ),
                    ],
                    const Divider(height: 24),
                    _buildSummaryRow(
                      'الإجمالي',
                      '${formatter.format(sale.total)} ر.س',
                      isBold: true,
                      fontSize: 18,
                      color: AppTheme.primaryColor,
                    ),
                  ],
                ),
              ),
            ),

            // الملاحظات
            if (sale.notes != null && sale.notes!.isNotEmpty) ...[
              const SizedBox(height: 16),
              Text(
                'ملاحظات',
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Icon(Icons.note, color: AppTheme.grey600),
                      const SizedBox(width: 12),
                      Expanded(child: Text(sale.notes!)),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, size: 20, color: AppTheme.grey600),
          const SizedBox(width: 12),
          Text(label, style: TextStyle(color: AppTheme.grey600)),
          const Spacer(),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(
    String label,
    String value, {
    bool isBold = false,
    double fontSize = 14,
    Color? color,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontWeight: isBold ? FontWeight.bold : null,
            fontSize: fontSize,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontWeight: isBold ? FontWeight.bold : null,
            fontSize: fontSize,
            color: color,
          ),
        ),
      ],
    );
  }

  Color _getStatusColor() {
    switch (sale.status) {
      case 'مكتمل':
        return AppTheme.successColor;
      case 'ملغي':
        return AppTheme.errorColor;
      case 'معلق':
        return AppTheme.warningColor;
      default:
        return AppTheme.grey600;
    }
  }

  IconData _getStatusIcon() {
    switch (sale.status) {
      case 'مكتمل':
        return Icons.check_circle;
      case 'ملغي':
        return Icons.cancel;
      case 'معلق':
        return Icons.access_time;
      default:
        return Icons.help;
    }
  }

  IconData _getPaymentIcon() {
    switch (sale.paymentMethod) {
      case 'نقدي':
        return Icons.payments;
      case 'بطاقة':
        return Icons.credit_card;
      case 'آجل':
        return Icons.schedule;
      default:
        return Icons.payment;
    }
  }

  void _showCancelConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('إلغاء الفاتورة'),
        content: const Text(
          'هل أنت متأكد من إلغاء هذه الفاتورة؟\nسيتم إرجاع المنتجات للمخزون.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('لا'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              final provider = context.read<SaleProvider>();
              final success = await provider.cancelSale(sale.id);
              if (success) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('تم إلغاء الفاتورة'),
                    backgroundColor: AppTheme.successColor,
                  ),
                );
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(provider.error ?? 'حدث خطأ'),
                    backgroundColor: AppTheme.errorColor,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.errorColor,
            ),
            child: const Text('نعم، إلغاء'),
          ),
        ],
      ),
    );
  }
}
