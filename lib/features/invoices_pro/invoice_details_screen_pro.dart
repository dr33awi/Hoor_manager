// ═══════════════════════════════════════════════════════════════════════════
// Invoice Details Screen Pro
// View detailed invoice information
// ═══════════════════════════════════════════════════════════════════════════

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/pro/design_tokens.dart';

class InvoiceDetailsScreenPro extends StatelessWidget {
  final String invoiceId;

  const InvoiceDetailsScreenPro({
    super.key,
    required this.invoiceId,
  });

  // Sample data
  Map<String, dynamic> get _invoice => {
        'id': invoiceId,
        'customer': 'شركة النور للتجارة',
        'customerPhone': '0551234567',
        'date': '20 يونيو 2024',
        'dueDate': '20 يوليو 2024',
        'status': 'partial',
        'subtotal': 5375.00,
        'discount': 200.00,
        'tax': 776.25,
        'total': 5951.25,
        'paid': 3000.00,
        'type': 'sale',
        'paymentMethod': 'آجل',
        'notes': 'تسليم خلال 3 أيام عمل',
        'items': [
          {
            'name': 'لابتوب HP ProBook',
            'sku': 'LAP-001',
            'quantity': 2,
            'price': 2500.00,
            'discount': 0,
            'total': 5000.00,
          },
          {
            'name': 'ماوس لاسلكي',
            'sku': 'MOU-002',
            'quantity': 5,
            'price': 75.00,
            'discount': 0,
            'total': 375.00,
          },
        ],
        'payments': [
          {'date': '20 يونيو 2024', 'amount': 2000.00, 'method': 'تحويل بنكي'},
          {'date': '22 يونيو 2024', 'amount': 1000.00, 'method': 'نقدي'},
        ],
      };

  bool get isSales => _invoice['type'] == 'sale';
  double get remaining => _invoice['total'] - _invoice['paid'];
  double get paidPercentage => _invoice['paid'] / _invoice['total'];

  @override
  Widget build(BuildContext context) {
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
              _invoice['id'],
              style: AppTypography.titleMedium.copyWith(
                color: AppColors.textPrimary,
                fontFamily: 'JetBrains Mono',
              ),
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
          IconButton(
            onPressed: () {
              // TODO: Print invoice
            },
            icon: Icon(Icons.print_outlined, color: AppColors.textSecondary),
          ),
          IconButton(
            onPressed: () {
              // TODO: Share invoice
            },
            icon: Icon(Icons.share_outlined, color: AppColors.textSecondary),
          ),
          PopupMenuButton<String>(
            icon: Icon(Icons.more_vert_rounded, color: AppColors.textSecondary),
            itemBuilder: (context) => [
              const PopupMenuItem(value: 'edit', child: Text('تعديل')),
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
            _buildStatusCard(),
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

            // Payments
            if (_invoice['status'] != 'paid') ...[
              _buildPaymentsCard(),
              SizedBox(height: AppSpacing.lg),
            ],

            // Notes
            if (_invoice['notes'] != null) ...[
              _buildNotesCard(),
              SizedBox(height: AppSpacing.lg),
            ],

            SizedBox(height: AppSpacing.xl),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomBar(context),
    );
  }

  Widget _buildStatusCard() {
    final status = _invoice['status'];
    Color statusColor;
    String statusText;
    IconData statusIcon;

    switch (status) {
      case 'paid':
        statusColor = AppColors.success;
        statusText = 'مدفوعة بالكامل';
        statusIcon = Icons.check_circle_outline_rounded;
        break;
      case 'partial':
        statusColor = AppColors.warning;
        statusText = 'مدفوعة جزئياً';
        statusIcon = Icons.timelapse_rounded;
        break;
      case 'overdue':
        statusColor = AppColors.error;
        statusText = 'متأخرة';
        statusIcon = Icons.warning_amber_rounded;
        break;
      default:
        statusColor = AppColors.textSecondary;
        statusText = 'معلقة';
        statusIcon = Icons.schedule_rounded;
    }

    return Container(
      padding: EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            statusColor.withOpacity(0.1),
            statusColor.withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: statusColor.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(AppSpacing.sm),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.2),
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
                      _invoice['date'],
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
                    '${_invoice['total'].toStringAsFixed(2)} ر.س',
                    style: AppTypography.headlineSmall.copyWith(
                      color: isSales ? AppColors.success : AppColors.secondary,
                      fontWeight: FontWeight.w700,
                      fontFamily: 'JetBrains Mono',
                    ),
                  ),
                  if (status != 'paid')
                    Text(
                      'متبقي: ${remaining.toStringAsFixed(0)} ر.س',
                      style: AppTypography.bodySmall.copyWith(
                        color: AppColors.error,
                        fontFamily: 'JetBrains Mono',
                      ),
                    ),
                ],
              ),
            ],
          ),
          if (status == 'partial') ...[
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
                  '${_invoice['paid'].toStringAsFixed(0)} من ${_invoice['total'].toStringAsFixed(0)} ر.س',
                  style: AppTypography.labelSmall.copyWith(
                    color: AppColors.textSecondary,
                    fontFamily: 'JetBrains Mono',
                  ),
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
            backgroundColor: AppColors.secondary.withOpacity(0.1),
            child: Text(
              _invoice['customer'][0],
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
                  _invoice['customer'],
                  style: AppTypography.titleSmall.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  _invoice['customerPhone'],
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.textSecondary,
                    fontFamily: 'JetBrains Mono',
                  ),
                ),
              ],
            ),
          ),
          Row(
            children: [
              IconButton(
                onPressed: () {},
                icon: Icon(Icons.phone_outlined, color: AppColors.secondary),
              ),
              IconButton(
                onPressed: () {},
                icon: Icon(Icons.message_outlined, color: AppColors.secondary),
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
        '${_invoice['items'].length} صنف',
        style: AppTypography.labelMedium.copyWith(
          color: AppColors.textTertiary,
        ),
      ),
      child: Column(
        children: [
          ...(_invoice['items'] as List).asMap().entries.map((entry) {
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
                          '${item['quantity']}x',
                          style: AppTypography.labelMedium.copyWith(
                            color: AppColors.secondary,
                            fontFamily: 'JetBrains Mono',
                          ),
                        ),
                      ),
                    ),
                    SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item['name'],
                            style: AppTypography.titleSmall.copyWith(
                              color: AppColors.textPrimary,
                            ),
                          ),
                          Text(
                            '${item['price'].toStringAsFixed(0)} ر.س للوحدة',
                            style: AppTypography.bodySmall.copyWith(
                              color: AppColors.textTertiary,
                              fontFamily: 'JetBrains Mono',
                            ),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      '${item['total'].toStringAsFixed(0)} ر.س',
                      style: AppTypography.titleSmall.copyWith(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w600,
                        fontFamily: 'JetBrains Mono',
                      ),
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
          _buildTotalRow('المجموع الفرعي', _invoice['subtotal']),
          SizedBox(height: AppSpacing.sm),
          _buildTotalRow('الخصم', -_invoice['discount'], isNegative: true),
          SizedBox(height: AppSpacing.sm),
          _buildTotalRow('الضريبة (15%)', _invoice['tax']),
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
                '${_invoice['total'].toStringAsFixed(2)} ر.س',
                style: AppTypography.titleLarge.copyWith(
                  color: isSales ? AppColors.success : AppColors.secondary,
                  fontWeight: FontWeight.w700,
                  fontFamily: 'JetBrains Mono',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentsCard() {
    return _buildCard(
      title: 'الدفعات',
      icon: Icons.payments_outlined,
      trailing: TextButton(
        onPressed: () {},
        child: Text(
          'إضافة دفعة',
          style: AppTypography.labelMedium.copyWith(
            color: AppColors.secondary,
          ),
        ),
      ),
      child: Column(
        children: [
          ...(_invoice['payments'] as List).asMap().entries.map((entry) {
            final index = entry.key;
            final payment = entry.value;
            return Column(
              children: [
                if (index > 0)
                  Divider(height: AppSpacing.lg, color: AppColors.border),
                Row(
                  children: [
                    Container(
                      padding: EdgeInsets.all(AppSpacing.sm),
                      decoration: BoxDecoration(
                        color: AppColors.success.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(AppRadius.sm),
                      ),
                      child: Icon(
                        Icons.check_rounded,
                        color: AppColors.success,
                        size: AppIconSize.sm,
                      ),
                    ),
                    SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            payment['method'],
                            style: AppTypography.titleSmall.copyWith(
                              color: AppColors.textPrimary,
                            ),
                          ),
                          Text(
                            payment['date'],
                            style: AppTypography.bodySmall.copyWith(
                              color: AppColors.textTertiary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      '${payment['amount'].toStringAsFixed(0)} ر.س',
                      style: AppTypography.titleSmall.copyWith(
                        color: AppColors.success,
                        fontWeight: FontWeight.w600,
                        fontFamily: 'JetBrains Mono',
                      ),
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

  Widget _buildNotesCard() {
    return _buildCard(
      title: 'ملاحظات',
      icon: Icons.notes_outlined,
      child: Text(
        _invoice['notes'],
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
          style: AppTypography.bodyMedium.copyWith(
            color: isNegative ? AppColors.error : AppColors.textPrimary,
            fontFamily: 'JetBrains Mono',
          ),
        ),
      ],
    );
  }

  Widget _buildBottomBar(BuildContext context) {
    final status = _invoice['status'];
    if (status == 'paid') return const SizedBox.shrink();

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
