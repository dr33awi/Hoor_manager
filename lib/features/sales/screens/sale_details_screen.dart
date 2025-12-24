// lib/features/sales/screens/sale_details_screen.dart
// شاشة تفاصيل الفاتورة - تصميم حديث

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_theme.dart';
import '../providers/sale_provider.dart';
import '../models/sale_model.dart';

class SaleDetailsScreen extends StatelessWidget {
  final SaleModel sale;

  const SaleDetailsScreen({super.key, required this.sale});

  @override
  Widget build(BuildContext context) {
    final formatter = NumberFormat('#,##0.00', 'ar');
    final dateFormatter = DateFormat('dd MMMM yyyy - hh:mm a', 'ar');

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back_ios_rounded, size: 18, color: AppColors.primary),
        ),
        title: Text(
          sale.invoiceNumber,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.primary),
        ),
        centerTitle: true,
        actions: [
          if (!sale.isCancelled)
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert, color: AppColors.primary),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              itemBuilder: (_) => [
                const PopupMenuItem(
                  value: 'print',
                  child: Row(
                    children: [
                      Icon(Icons.print_outlined, size: 20),
                      SizedBox(width: 12),
                      Text('طباعة'),
                    ],
                  ),
                ),
                if (sale.isCompleted)
                  const PopupMenuItem(
                    value: 'cancel',
                    child: Row(
                      children: [
                        Icon(Icons.cancel_outlined, size: 20, color: AppColors.error),
                        SizedBox(width: 12),
                        Text('إلغاء', style: TextStyle(color: AppColors.error)),
                      ],
                    ),
                  ),
              ],
              onSelected: (v) {
                if (v == 'cancel') _showCancelDialog(context);
              },
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              decoration: BoxDecoration(
                color: _statusColor().withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(_statusIcon(), color: _statusColor(), size: 20),
                  const SizedBox(width: 8),
                  Text(
                    sale.status,
                    style: TextStyle(color: _statusColor(), fontWeight: FontWeight.w600, fontSize: 15),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.grey.shade100),
              ),
              child: Column(
                children: [
                  _infoRow(Icons.receipt_outlined, 'رقم الفاتورة', sale.invoiceNumber),
                  Divider(height: 20, color: Colors.grey.shade100),
                  _infoRow(Icons.calendar_today_outlined, 'التاريخ', dateFormatter.format(sale.saleDate)),
                  Divider(height: 20, color: Colors.grey.shade100),
                  _infoRow(Icons.payments_outlined, 'طريقة الدفع', 'نقدي'),
                  Divider(height: 20, color: Colors.grey.shade100),
                  _infoRow(Icons.person_outline, 'البائع', sale.userName),
                ],
              ),
            ),
            const SizedBox(height: 20),

            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.grey.shade100),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Padding(
                    padding: EdgeInsets.all(16),
                    child: Text('المنتجات', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
                  ),
                  Divider(height: 1, color: Colors.grey.shade100),
                  ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: sale.items.length,
                    separatorBuilder: (_, __) => Divider(height: 1, color: Colors.grey.shade100),
                    itemBuilder: (_, i) {
                      final item = sale.items[i];
                      return Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(item.productName, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                                  Text('${item.color} - مقاس ${item.size}', style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
                                ],
                              ),
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text('${formatter.format(item.totalPrice)} ر.س', style: const TextStyle(fontWeight: FontWeight.w600)),
                                Text('${item.quantity} × ${formatter.format(item.unitPrice)}', style: TextStyle(fontSize: 11, color: Colors.grey.shade500)),
                              ],
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.grey.shade100),
              ),
              child: Column(
                children: [
                  _summaryRow('المجموع الفرعي', '${formatter.format(sale.subtotal)} ر.س'),
                  if (sale.discount > 0) ...[
                    const SizedBox(height: 8),
                    _summaryRow(
                      'الخصم${sale.discountPercent > 0 ? ' (${sale.discountPercent}%)' : ''}',
                      '- ${formatter.format(sale.discount)} ر.س',
                      color: AppColors.error,
                    ),
                  ],
                  Divider(height: 24, color: AppColors.border),
                  _summaryRow('الإجمالي', '${formatter.format(sale.total)} ر.س', isBold: true, color: AppColors.primary),
                ],
              ),
            ),

            if (sale.notes?.isNotEmpty == true) ...[
              const SizedBox(height: 20),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: Colors.grey.shade100),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('ملاحظات', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                    const SizedBox(height: 8),
                    Text(sale.notes!, style: TextStyle(color: Colors.grey.shade600)),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _infoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 18, color: Colors.grey.shade500),
        const SizedBox(width: 12),
        Expanded(child: Text(label, style: TextStyle(color: Colors.grey.shade500, fontSize: 13))),
        Text(value, style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13)),
      ],
    );
  }

  Widget _summaryRow(String label, String value, {bool isBold = false, Color? color}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(fontWeight: isBold ? FontWeight.w600 : null, fontSize: isBold ? 16 : 14)),
        Text(value, style: TextStyle(fontWeight: isBold ? FontWeight.w700 : FontWeight.w500, fontSize: isBold ? 18 : 14, color: color)),
      ],
    );
  }

  Color _statusColor() {
    switch (sale.status) {
      case 'مكتمل': return AppColors.success;
      case 'ملغي': return AppColors.error;
      case 'معلق': return AppColors.warning;
      default: return Colors.grey;
    }
  }

  IconData _statusIcon() {
    switch (sale.status) {
      case 'مكتمل': return Icons.check_circle;
      case 'ملغي': return Icons.cancel;
      case 'معلق': return Icons.access_time;
      default: return Icons.help;
    }
  }

  void _showCancelDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(color: AppColors.errorLight, borderRadius: BorderRadius.circular(16)),
                child: const Icon(Icons.cancel_outlined, color: AppColors.error, size: 28),
              ),
              const SizedBox(height: 20),
              const Text('إلغاء الفاتورة', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
              const SizedBox(height: 8),
              Text('سيتم إرجاع المنتجات للمخزون', style: TextStyle(color: Colors.grey.shade600), textAlign: TextAlign.center),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(ctx),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        side: BorderSide(color: Colors.grey.shade200),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: Text('لا', style: TextStyle(color: Colors.grey.shade600)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () async {
                        Navigator.pop(ctx);
                        final provider = context.read<SaleProvider>();
                        final success = await provider.cancelSale(sale.id);
                        if (success && context.mounted) {
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: const Text('تم إلغاء الفاتورة'),
                              backgroundColor: AppColors.success,
                              behavior: SnackBarBehavior.floating,
                              margin: const EdgeInsets.all(20),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                          );
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.error,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text('نعم، إلغاء'),
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
}
