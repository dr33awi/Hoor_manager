import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../app/theme/app_theme.dart';
import '../../../../app/routes/app_router.dart';
import '../../../../app/providers/database_providers.dart';
import '../../../../data/database.dart';
import '../../../../shared/services/print_service.dart';

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
                    onTap: () => _showInvoiceDetails(invoice),
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

  void _showInvoiceDetails(Invoice invoice) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (context, scrollController) => _PurchaseInvoiceDetailsSheet(
          invoice: invoice,
          scrollController: scrollController,
          dateFormat: _dateFormat,
          currencyFormat: _currencyFormat,
        ),
      ),
    );
  }
}

class _PurchaseInvoiceDetailsSheet extends ConsumerWidget {
  final Invoice invoice;
  final ScrollController scrollController;
  final DateFormat dateFormat;
  final NumberFormat currencyFormat;

  const _PurchaseInvoiceDetailsSheet({
    required this.invoice,
    required this.scrollController,
    required this.dateFormat,
    required this.currencyFormat,
  });

  Future<void> _printInvoice(BuildContext context, WidgetRef ref) async {
    final items = await ref.read(invoiceItemsProvider(invoice.id).future);
    final products = await Future.wait(
      items.map((item) => ref.read(productByIdProvider(item.productId).future)),
    );

    final printableItems = items.asMap().entries.map((entry) {
      final item = entry.value;
      final product = products[entry.key];
      return PrintableInvoiceItem(
        name: product?.name ?? 'منتج غير معروف',
        quantity: item.qty,
        unitPrice: item.unitPrice,
        lineTotal: item.lineTotal,
      );
    }).toList();

    if (context.mounted) {
      await PrintService.previewInvoice(
        context: context,
        invoiceNumber: invoice.number,
        invoiceType: invoice.type,
        date: invoice.invoiceDate,
        items: printableItems,
        subtotal: invoice.subtotal,
        discountAmount: invoice.discountAmount,
        taxAmount: invoice.taxAmount,
        total: invoice.total,
        paidAmount: invoice.paidAmount,
        paymentMethod: invoice.paymentMethod,
      );
    }
  }

  Future<void> _shareInvoice(WidgetRef ref) async {
    final items = await ref.read(invoiceItemsProvider(invoice.id).future);
    final products = await Future.wait(
      items.map((item) => ref.read(productByIdProvider(item.productId).future)),
    );

    final printableItems = items.asMap().entries.map((entry) {
      final item = entry.value;
      final product = products[entry.key];
      return PrintableInvoiceItem(
        name: product?.name ?? 'منتج غير معروف',
        quantity: item.qty,
        unitPrice: item.unitPrice,
        lineTotal: item.lineTotal,
      );
    }).toList();

    await PrintService.shareInvoice(
      invoiceNumber: invoice.number,
      invoiceType: invoice.type,
      date: invoice.invoiceDate,
      items: printableItems,
      subtotal: invoice.subtotal,
      discountAmount: invoice.discountAmount,
      taxAmount: invoice.taxAmount,
      total: invoice.total,
      paidAmount: invoice.paidAmount,
      paymentMethod: invoice.paymentMethod,
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final itemsAsync = ref.watch(invoiceItemsProvider(invoice.id));

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: Column(
        children: [
          Container(
            margin: const EdgeInsets.only(top: 8),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(AppSizes.paddingMD),
            child: Row(
              children: [
                const Icon(Icons.shopping_cart, color: AppColors.warning),
                const SizedBox(width: 8),
                Text(
                  'فاتورة #${invoice.number}',
                  style: const TextStyle(
                      fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.print),
                  onPressed: () => _printInvoice(context, ref),
                ),
                IconButton(
                  icon: const Icon(Icons.share),
                  onPressed: () => _shareInvoice(ref),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: ListView(
              controller: scrollController,
              padding: const EdgeInsets.all(AppSizes.paddingMD),
              children: [
                _DetailRow(
                    label: 'التاريخ',
                    value: dateFormat.format(invoice.invoiceDate)),
                _DetailRow(label: 'الحالة', value: invoice.status),
                _DetailRow(label: 'طريقة الدفع', value: invoice.paymentMethod),
                const Divider(height: 24),
                const Text('البنود',
                    style:
                        TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                itemsAsync.when(
                  data: (items) => Column(
                    children: items
                        .map((item) => _ItemRow(
                            item: item, currencyFormat: currencyFormat))
                        .toList(),
                  ),
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                  error: (e, s) => Text('خطأ: $e'),
                ),
                const Divider(height: 24),
                _DetailRow(
                    label: 'المجموع الفرعي',
                    value: currencyFormat.format(invoice.subtotal)),
                if (invoice.discountAmount > 0)
                  _DetailRow(
                      label: 'الخصم',
                      value:
                          '- ${currencyFormat.format(invoice.discountAmount)}',
                      valueColor: AppColors.error),
                if (invoice.taxAmount > 0)
                  _DetailRow(
                      label: 'الضريبة',
                      value: currencyFormat.format(invoice.taxAmount)),
                _DetailRow(
                    label: 'الإجمالي',
                    value: currencyFormat.format(invoice.total),
                    isTotal: true),
                const SizedBox(height: 8),
                _DetailRow(
                    label: 'المدفوع',
                    value: currencyFormat.format(invoice.paidAmount),
                    valueColor: AppColors.success),
                _DetailRow(
                    label: 'المتبقي',
                    value: currencyFormat.format(invoice.dueAmount),
                    valueColor: invoice.dueAmount > 0
                        ? AppColors.warning
                        : AppColors.success),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;
  final bool isTotal;

  const _DetailRow(
      {required this.label,
      required this.value,
      this.valueColor,
      this.isTotal = false});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: TextStyle(
                  fontSize: isTotal ? 16 : 14,
                  fontWeight: isTotal ? FontWeight.bold : FontWeight.normal)),
          Text(value,
              style: TextStyle(
                  fontSize: isTotal ? 18 : 14,
                  fontWeight: isTotal ? FontWeight.bold : FontWeight.w500,
                  color: valueColor ?? (isTotal ? AppColors.primary : null))),
        ],
      ),
    );
  }
}

class _ItemRow extends ConsumerWidget {
  final InvoiceItem item;
  final NumberFormat currencyFormat;

  const _ItemRow({required this.item, required this.currencyFormat});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final productAsync = ref.watch(productByIdProvider(item.productId));

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
          border: Border(bottom: BorderSide(color: Colors.grey[200]!))),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                productAsync.when(
                  data: (product) => Text(product?.name ?? 'منتج غير معروف',
                      style: const TextStyle(fontWeight: FontWeight.w500)),
                  loading: () => const Text('جاري التحميل...'),
                  error: (e, s) => const Text('خطأ'),
                ),
                Text('${item.qty} × ${currencyFormat.format(item.unitPrice)}',
                    style: TextStyle(color: Colors.grey[600], fontSize: 12)),
              ],
            ),
          ),
          Text(currencyFormat.format(item.lineTotal),
              style: const TextStyle(fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}
