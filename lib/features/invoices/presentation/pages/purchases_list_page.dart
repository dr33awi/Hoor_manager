import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../app/theme/app_theme.dart';
import '../../../../app/routes/app_router.dart';
import '../../../../app/providers/database_providers.dart';
import '../../../../data/database.dart';

/// صفحة استعراض المشتريات
class PurchasesListPage extends ConsumerStatefulWidget {
  final bool isReturns;

  const PurchasesListPage({super.key, this.isReturns = false});

  @override
  ConsumerState<PurchasesListPage> createState() => _PurchasesListPageState();
}

class _PurchasesListPageState extends ConsumerState<PurchasesListPage> {
  final _dateFormat = DateFormat('yyyy/MM/dd', 'ar');
  final _currencyFormat = NumberFormat.currency(locale: 'ar_SA', symbol: 'ر.س');

  @override
  Widget build(BuildContext context) {
    final invoicesAsync = widget.isReturns
        ? ref.watch(purchaseReturnsProvider)
        : ref.watch(purchaseInvoicesProvider);

    return Scaffold(
      appBar: AppBar(
        title:
            Text(widget.isReturns ? 'مرتجعات المشتريات' : 'استعراض المشتريات'),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: () {},
          ),
        ],
      ),
      body: invoicesAsync.when(
        data: (invoices) {
          if (invoices.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    widget.isReturns ? Icons.redo : Icons.shopping_cart,
                    size: 64,
                    color: Colors.grey,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    widget.isReturns
                        ? 'لا توجد مرتجعات'
                        : 'لا توجد فواتير مشتريات',
                    style: const TextStyle(color: Colors.grey, fontSize: 16),
                  ),
                  const SizedBox(height: 24),
                  if (!widget.isReturns)
                    ElevatedButton.icon(
                      onPressed: () => Navigator.pushNamed(
                          context, AppRoutes.purchaseInvoice),
                      icon: const Icon(Icons.add),
                      label: const Text('إنشاء فاتورة جديدة'),
                    ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () async {
              if (widget.isReturns) {
                ref.invalidate(purchaseReturnsProvider);
              } else {
                ref.invalidate(purchaseInvoicesProvider);
              }
            },
            child: ListView.builder(
              padding: const EdgeInsets.all(AppSizes.paddingSM),
              itemCount: invoices.length,
              itemBuilder: (context, index) {
                final invoice = invoices[index];
                final isPaid = invoice.dueAmount <= 0;

                return Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: widget.isReturns
                          ? AppColors.info.withOpacity(0.1)
                          : AppColors.warning.withOpacity(0.1),
                      child: Icon(
                        widget.isReturns ? Icons.redo : Icons.shopping_cart,
                        color: widget.isReturns
                            ? AppColors.info
                            : AppColors.warning,
                      ),
                    ),
                    title: Text('فاتورة #${invoice.number}'),
                    subtitle: Text(_dateFormat.format(invoice.invoiceDate)),
                    trailing: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          _currencyFormat.format(invoice.total),
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: isPaid
                                ? AppColors.success.withOpacity(0.1)
                                : AppColors.warning.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            isPaid ? 'مدفوعة' : 'آجل',
                            style: TextStyle(
                              fontSize: 11,
                              color: isPaid
                                  ? AppColors.success
                                  : AppColors.warning,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                    onTap: () {
                      // عرض تفاصيل الفاتورة
                    },
                  ),
                );
              },
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 64, color: AppColors.error),
              const SizedBox(height: 16),
              Text('خطأ في تحميل الفواتير',
                  style: TextStyle(color: AppColors.error)),
              ElevatedButton(
                onPressed: () {
                  if (widget.isReturns) {
                    ref.invalidate(purchaseReturnsProvider);
                  } else {
                    ref.invalidate(purchaseInvoicesProvider);
                  }
                },
                child: const Text('إعادة المحاولة'),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: widget.isReturns
          ? null
          : FloatingActionButton.extended(
              onPressed: () async {
                final result = await Navigator.pushNamed(
                    context, AppRoutes.purchaseInvoice);
                if (result == true) {
                  ref.invalidate(purchaseInvoicesProvider);
                }
              },
              icon: const Icon(Icons.add),
              label: const Text('فاتورة جديدة'),
            ),
    );
  }
}
