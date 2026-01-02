// ═══════════════════════════════════════════════════════════════════════════
// Invoice Details Screen Pro
// View detailed invoice information with Print Support
// ═══════════════════════════════════════════════════════════════════════════

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../core/theme/design_tokens.dart';
import '../../core/providers/app_providers.dart';
import '../../core/widgets/widgets.dart';
import '../../core/services/printing/printing_services.dart';
import '../../core/di/injection.dart';
import '../../core/services/printing/print_settings_service.dart';
import '../../data/database/app_database.dart';

class InvoiceDetailsScreenPro extends ConsumerStatefulWidget {
  final String invoiceId;

  const InvoiceDetailsScreenPro({
    super.key,
    required this.invoiceId,
  });

  @override
  ConsumerState<InvoiceDetailsScreenPro> createState() =>
      _InvoiceDetailsScreenProState();
}

class _InvoiceDetailsScreenProState
    extends ConsumerState<InvoiceDetailsScreenPro> {
  Invoice? _invoice;
  List<InvoiceItem> _invoiceItems = [];
  Customer? _customer;
  Supplier? _supplier;
  bool _isLoading = true;
  bool _isPrinting = false;

  @override
  void initState() {
    super.initState();
    _loadInvoiceData();
  }

  Future<void> _loadInvoiceData() async {
    try {
      final invoiceRepo = ref.read(invoiceRepositoryProvider);
      final customerRepo = ref.read(customerRepositoryProvider);
      final supplierRepo = ref.read(supplierRepositoryProvider);

      final invoice = await invoiceRepo.getInvoiceById(widget.invoiceId);
      if (invoice != null) {
        final items = await invoiceRepo.getInvoiceItems(widget.invoiceId);

        Customer? customer;
        Supplier? supplier;

        if (invoice.customerId != null) {
          customer = await customerRepo.getCustomerById(invoice.customerId!);
        }
        if (invoice.supplierId != null) {
          supplier = await supplierRepo.getSupplierById(invoice.supplierId!);
        }

        if (mounted) {
          setState(() {
            _invoice = invoice;
            _invoiceItems = items;
            _customer = customer;
            _supplier = supplier;
            _isLoading = false;
          });
        }
      } else {
        if (mounted) setState(() => _isLoading = false);
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  bool get isSales => _invoice?.type == 'sale';
  double get remaining => (_invoice?.total ?? 0) - (_invoice?.paidAmount ?? 0);
  double get paidPercentage => _invoice != null && _invoice!.total > 0
      ? _invoice!.paidAmount / _invoice!.total
      : 0;
  String get customerName => _customer?.name ?? _supplier?.name ?? 'غير محدد';
  String get customerPhone => _customer?.phone ?? _supplier?.phone ?? '';

  // ═══════════════════════════════════════════════════════════════════════════
  // Print Functions
  // ═══════════════════════════════════════════════════════════════════════════

  Future<void> _handlePrint(PrintType type) async {
    if (_invoice == null || _isPrinting) return;

    setState(() => _isPrinting = true);

    try {
      final printSettingsService = getIt<PrintSettingsService>();
      final printOptions = await printSettingsService.getPrintOptions();

      switch (type) {
        case PrintType.print:
          await InvoicePdfGenerator.printInvoiceDirectly(
            invoice: _invoice!,
            items: _invoiceItems,
            customer: _customer,
            supplier: _supplier,
            options: printOptions,
          );
          if (mounted) {
            ProSnackbar.info(context, 'جاري الطباعة...');
          }
          break;

        case PrintType.share:
          await InvoicePdfGenerator.shareInvoiceAsPdf(
            invoice: _invoice!,
            items: _invoiceItems,
            customer: _customer,
            supplier: _supplier,
            options: printOptions,
          );
          break;

        case PrintType.save:
          await InvoicePdfGenerator.saveInvoiceAsPdf(
            invoice: _invoice!,
            items: _invoiceItems,
            customer: _customer,
            supplier: _supplier,
            options: printOptions,
          );
          if (mounted) {
            ProSnackbar.success(context, 'تم حفظ الفاتورة');
          }
          break;

        case PrintType.preview:
          // معاينة PDF
          final pdfBytes = await InvoicePdfGenerator.generateInvoicePdfBytes(
            invoice: _invoice!,
            items: _invoiceItems,
            customer: _customer,
            supplier: _supplier,
            options: printOptions,
          );
          if (mounted) {
            _showPdfPreview(pdfBytes);
          }
          break;
      }
    } catch (e) {
      if (mounted) {
        ProSnackbar.showError(context, e);
      }
    } finally {
      if (mounted) setState(() => _isPrinting = false);
    }
  }

  void _showPdfPreview(dynamic pdfBytes) async {
    final shouldPrint = await showProConfirmDialog(
      context: context,
      title: 'معاينة الفاتورة',
      message: 'تم إنشاء PDF بنجاح. اختر طباعة أو مشاركة.',
      icon: Icons.picture_as_pdf_rounded,
      iconColor: AppColors.success,
      confirmText: 'طباعة',
      cancelText: 'إغلاق',
    );
    if (shouldPrint == true) {
      _handlePrint(PrintType.print);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          backgroundColor: AppColors.surface,
          leading: IconButton(
            onPressed: () => context.pop(),
            icon: Icon(Icons.arrow_back_ios_rounded,
                color: AppColors.textSecondary),
          ),
        ),
        body: ProLoadingState.card(),
      );
    }

    if (_invoice == null) {
      return Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          backgroundColor: AppColors.surface,
          leading: IconButton(
            onPressed: () => context.pop(),
            icon: Icon(Icons.arrow_back_ios_rounded,
                color: AppColors.textSecondary),
          ),
        ),
        body: Center(child: Text('الفاتورة غير موجودة')),
      );
    }

    final dateFormat = DateFormat('dd MMMM yyyy', 'ar');

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        leading: IconButton(
          onPressed: () => context.pop(),
          icon: Icon(Icons.arrow_back_ios_rounded,
              color: AppColors.textSecondary),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _invoice!.invoiceNumber,
              style: AppTypography.titleMedium
                  .copyWith(
                    color: AppColors.textPrimary,
                  )
                  .mono,
            ),
            Text(
              isSales ? 'فاتورة بيع' : 'فاتورة شراء',
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.textTertiary,
              ),
            ),
          ],
        ),
        actions: [
          // ═══════════════════════════════════════════════════════════════
          // زر الطباعة الموحد
          // ═══════════════════════════════════════════════════════════════
          PrintMenuButton(
            onPrint: _handlePrint,
            isLoading: _isPrinting,
            enabledOptions: const {
              PrintType.print,
              PrintType.share,
              PrintType.save,
              PrintType.preview,
            },
            tooltip: 'طباعة الفاتورة',
            color: AppColors.secondary,
          ),
          PopupMenuButton<String>(
            icon: Icon(Icons.more_vert_rounded, color: AppColors.textSecondary),
            onSelected: (value) => _handleMenuAction(value),
            itemBuilder: (context) => [
              const PopupMenuItem(value: 'duplicate', child: Text('نسخ')),
              const PopupMenuItem(value: 'return', child: Text('مرتجع')),
              const PopupMenuDivider(),
              PopupMenuItem(
                value: 'delete',
                child: Text('حذف', style: TextStyle(color: AppColors.error)),
              ),
            ],
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Status Card
            _buildStatusCard(dateFormat),
            SizedBox(height: AppSpacing.lg),

            // Customer Info
            _buildCustomerCard(),
            SizedBox(height: AppSpacing.lg),

            // Items
            _buildItemsCard(),
            SizedBox(height: AppSpacing.lg),

            // Totals
            _buildTotalsCard(),
            SizedBox(height: AppSpacing.lg),

            // Notes
            if (_invoice!.notes != null && _invoice!.notes!.isNotEmpty) ...[
              _buildNotesCard(),
              SizedBox(height: AppSpacing.lg),
            ],

            // ═══════════════════════════════════════════════════════════════
            // Quick Print Actions
            // ═══════════════════════════════════════════════════════════════
            _buildQuickPrintActions(),

            SizedBox(height: AppSpacing.xl),
          ],
        ),
      ),
      bottomNavigationBar: remaining > 0 ? _buildBottomBar(context) : null,
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // Quick Print Actions Widget
  // ═══════════════════════════════════════════════════════════════════════════
  Widget _buildQuickPrintActions() {
    return Container(
      padding: EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.print_outlined,
                size: AppIconSize.sm,
                color: AppColors.textTertiary,
              ),
              SizedBox(width: AppSpacing.sm),
              Text(
                'إجراءات سريعة',
                style: AppTypography.titleSmall.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          SizedBox(height: AppSpacing.md),
          Row(
            children: [
              Expanded(
                child: _buildQuickActionButton(
                  icon: Icons.print_rounded,
                  label: 'طباعة',
                  color: AppColors.secondary,
                  onTap: () => _handlePrint(PrintType.print),
                ),
              ),
              SizedBox(width: AppSpacing.sm),
              Expanded(
                child: _buildQuickActionButton(
                  icon: Icons.share_rounded,
                  label: 'مشاركة',
                  color: AppColors.success,
                  onTap: () => _handlePrint(PrintType.share),
                ),
              ),
              SizedBox(width: AppSpacing.sm),
              Expanded(
                child: _buildQuickActionButton(
                  icon: Icons.save_alt_rounded,
                  label: 'حفظ',
                  color: AppColors.warning,
                  onTap: () => _handlePrint(PrintType.save),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: _isPrinting ? null : onTap,
        borderRadius: BorderRadius.circular(AppRadius.md),
        child: Container(
          padding: EdgeInsets.symmetric(
            vertical: AppSpacing.md,
            horizontal: AppSpacing.sm,
          ),
          decoration: BoxDecoration(
            color: color.soft,
            borderRadius: BorderRadius.circular(AppRadius.md),
            border: Border.all(color: color.border),
          ),
          child: Column(
            children: [
              _isPrinting
                  ? SizedBox(
                      width: 20.w,
                      height: 20.w,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation(color),
                      ),
                    )
                  : Icon(icon, color: color, size: AppIconSize.md),
              SizedBox(height: AppSpacing.xs),
              Text(
                label,
                style: AppTypography.labelSmall.copyWith(
                  color: color,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _handleMenuAction(String action) async {
    switch (action) {
      case 'delete':
        final confirm = await showProDeleteDialog(
          context: context,
          itemName: 'الفاتورة',
        );
        if (confirm == true && mounted) {
          try {
            final invoiceRepo = ref.read(invoiceRepositoryProvider);
            await invoiceRepo.deleteInvoiceWithReverse(widget.invoiceId);
            if (mounted) {
              ProSnackbar.deleted(context);
              context.pop();
            }
          } catch (e) {
            if (mounted) {
              ProSnackbar.showError(context, e);
            }
          }
        }
        break;
    }
  }

  Widget _buildStatusCard(DateFormat dateFormat) {
    final isPaid = _invoice!.paidAmount >= _invoice!.total;
    Color statusColor;
    String statusText;
    IconData statusIcon;

    if (isPaid) {
      statusColor = AppColors.success;
      statusText = 'مدفوعة بالكامل';
      statusIcon = Icons.check_circle_outline_rounded;
    } else if (_invoice!.paidAmount > 0) {
      statusColor = AppColors.warning;
      statusText = 'مدفوعة جزئياً';
      statusIcon = Icons.timelapse_rounded;
    } else {
      statusColor = AppColors.textSecondary;
      statusText = 'معلقة';
      statusIcon = Icons.schedule_rounded;
    }

    return Container(
      padding: EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            statusColor.soft,
            statusColor.subtle,
          ],
        ),
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: statusColor.border),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(AppSpacing.sm),
                decoration: BoxDecoration(
                  color: statusColor.light,
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
                child:
                    Icon(statusIcon, color: statusColor, size: AppIconSize.lg),
              ),
              SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      statusText,
                      style: AppTypography.titleMedium.copyWith(
                        color: statusColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      dateFormat.format(_invoice!.invoiceDate),
                      style: AppTypography.bodySmall.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '${_invoice!.total.toStringAsFixed(2)} ر.س',
                    style: AppTypography.headlineSmall
                        .copyWith(
                          color:
                              isSales ? AppColors.success : AppColors.secondary,
                        )
                        .monoBold,
                  ),
                  if (!isPaid)
                    Text(
                      'متبقي: ${remaining.toStringAsFixed(0)} ر.س',
                      style: AppTypography.bodySmall
                          .copyWith(
                            color: AppColors.error,
                          )
                          .mono,
                    ),
                ],
              ),
            ],
          ),
          if (_invoice!.paidAmount > 0 && !isPaid) ...[
            SizedBox(height: AppSpacing.md),
            ClipRRect(
              borderRadius: BorderRadius.circular(AppRadius.full),
              child: LinearProgressIndicator(
                value: paidPercentage,
                backgroundColor: AppColors.border,
                valueColor: AlwaysStoppedAnimation(AppColors.success),
                minHeight: 8.h,
              ),
            ),
            SizedBox(height: AppSpacing.xs),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'تم دفع ${(paidPercentage * 100).toInt()}%',
                  style: AppTypography.labelSmall.copyWith(
                    color: AppColors.success,
                  ),
                ),
                Text(
                  '${_invoice!.paidAmount.toStringAsFixed(0)} من ${_invoice!.total.toStringAsFixed(0)} ر.س',
                  style: AppTypography.labelSmall
                      .copyWith(
                        color: AppColors.textSecondary,
                      )
                      .mono,
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildCustomerCard() {
    return _buildCard(
      title: isSales ? 'العميل' : 'المورد',
      icon: Icons.person_outline_rounded,
      child: Row(
        children: [
          CircleAvatar(
            radius: 24.r,
            backgroundColor: AppColors.secondary.soft,
            child: Text(
              customerName.isNotEmpty ? customerName[0] : '?',
              style: AppTypography.titleLarge.copyWith(
                color: AppColors.secondary,
              ),
            ),
          ),
          SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  customerName,
                  style: AppTypography.titleSmall.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (customerPhone.isNotEmpty)
                  Text(
                    customerPhone,
                    style: AppTypography.bodySmall
                        .copyWith(
                          color: AppColors.textSecondary,
                        )
                        .mono,
                  ),
              ],
            ),
          ),
          if (customerPhone.isNotEmpty)
            Row(
              children: [
                IconButton(
                  onPressed: () {},
                  icon: Icon(Icons.phone_outlined, color: AppColors.secondary),
                ),
                IconButton(
                  onPressed: () {},
                  icon:
                      Icon(Icons.message_outlined, color: AppColors.secondary),
                ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildItemsCard() {
    return _buildCard(
      title: 'الأصناف',
      icon: Icons.inventory_2_outlined,
      trailing: Text(
        '${_invoiceItems.length} صنف',
        style: AppTypography.labelMedium.copyWith(
          color: AppColors.textTertiary,
        ),
      ),
      child: Column(
        children: [
          ..._invoiceItems.asMap().entries.map((entry) {
            final index = entry.key;
            final item = entry.value;
            return Column(
              children: [
                if (index > 0)
                  Divider(height: AppSpacing.lg, color: AppColors.border),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 40.w,
                      height: 40.w,
                      decoration: BoxDecoration(
                        color: AppColors.background,
                        borderRadius: BorderRadius.circular(AppRadius.sm),
                      ),
                      child: Center(
                        child: Text(
                          '${item.quantity}x',
                          style: AppTypography.labelMedium
                              .copyWith(
                                color: AppColors.secondary,
                              )
                              .mono,
                        ),
                      ),
                    ),
                    SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.productName,
                            style: AppTypography.titleSmall.copyWith(
                              color: AppColors.textPrimary,
                            ),
                          ),
                          Text(
                            '${item.unitPrice.toStringAsFixed(0)} ر.س للوحدة',
                            style: AppTypography.bodySmall
                                .copyWith(
                                  color: AppColors.textTertiary,
                                )
                                .mono,
                          ),
                        ],
                      ),
                    ),
                    Text(
                      '${item.total.toStringAsFixed(0)} ر.س',
                      style: AppTypography.titleSmall
                          .copyWith(
                            color: AppColors.textPrimary,
                          )
                          .monoSemibold,
                    ),
                  ],
                ),
              ],
            );
          }),
        ],
      ),
    );
  }

  Widget _buildTotalsCard() {
    return _buildCard(
      title: 'ملخص الفاتورة',
      icon: Icons.receipt_outlined,
      child: Column(
        children: [
          _buildTotalRow('المجموع الفرعي', _invoice!.subtotal),
          SizedBox(height: AppSpacing.sm),
          _buildTotalRow('الخصم', -_invoice!.discountAmount, isNegative: true),
          SizedBox(height: AppSpacing.sm),
          _buildTotalRow('الضريبة', _invoice!.taxAmount),
          Divider(height: AppSpacing.lg, color: AppColors.border),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'الإجمالي',
                style: AppTypography.titleMedium.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w700,
                ),
              ),
              Text(
                '${_invoice!.total.toStringAsFixed(2)} ر.س',
                style: AppTypography.titleLarge
                    .copyWith(
                      color: isSales ? AppColors.success : AppColors.secondary,
                    )
                    .monoBold,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildNotesCard() {
    return _buildCard(
      title: 'ملاحظات',
      icon: Icons.notes_outlined,
      child: Text(
        _invoice!.notes ?? '',
        style: AppTypography.bodyMedium.copyWith(
          color: AppColors.textSecondary,
        ),
      ),
    );
  }

  Widget _buildCard({
    required String title,
    required IconData icon,
    Widget? trailing,
    required Widget child,
  }) {
    return Container(
      padding: EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: AppIconSize.sm, color: AppColors.textTertiary),
              SizedBox(width: AppSpacing.sm),
              Text(
                title,
                style: AppTypography.titleSmall.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              if (trailing != null) trailing,
            ],
          ),
          SizedBox(height: AppSpacing.md),
          child,
        ],
      ),
    );
  }

  Widget _buildTotalRow(String label, double amount,
      {bool isNegative = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: AppTypography.bodyMedium.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
        Text(
          '${isNegative ? "-" : ""}${amount.abs().toStringAsFixed(2)} ر.س',
          style: AppTypography.bodyMedium
              .copyWith(
                color: isNegative ? AppColors.error : AppColors.textPrimary,
              )
              .mono,
        ),
      ],
    );
  }

  Widget _buildBottomBar(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border(top: BorderSide(color: AppColors.border)),
      ),
      child: SafeArea(
        child: FilledButton.icon(
          onPressed: () {
            // TODO: Show payment dialog
          },
          icon: const Icon(Icons.payments_outlined),
          label: Text(
            'تسجيل دفعة (${remaining.toStringAsFixed(0)} ر.س)',
            style: AppTypography.labelLarge.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w600,
            ),
          ),
          style: FilledButton.styleFrom(
            backgroundColor: AppColors.success,
            padding: EdgeInsets.symmetric(vertical: AppSpacing.md),
            minimumSize: Size(double.infinity, 50.h),
          ),
        ),
      ),
    );
  }
}
