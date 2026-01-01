import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:pdf/pdf.dart';
import 'package:printing/printing.dart';

import '../../../../core/theme/redesign/design_system.dart';
import '../../../../core/di/injection.dart';
import '../../../../core/services/export/export_services.dart';
import '../../../../data/database/app_database.dart';
import '../../../../data/repositories/invoice_repository.dart';

/// ═══════════════════════════════════════════════════════════════════════════
/// Invoices Screen - Modern Redesign
/// Professional Invoice Management Interface
/// ═══════════════════════════════════════════════════════════════════════════

class InvoicesScreenRedesign extends ConsumerStatefulWidget {
  final String? type;

  const InvoicesScreenRedesign({super.key, this.type});

  @override
  ConsumerState<InvoicesScreenRedesign> createState() =>
      _InvoicesScreenRedesignState();
}

class _InvoicesScreenRedesignState extends ConsumerState<InvoicesScreenRedesign>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _invoiceRepo = getIt<InvoiceRepository>();
  final _searchController = TextEditingController();
  String _searchQuery = '';

  final _tabs = [
    _TabItem(type: null, label: 'الكل', icon: Icons.list_alt_rounded),
    _TabItem(
        type: 'sale', label: 'المبيعات', icon: Icons.point_of_sale_rounded),
    _TabItem(
        type: 'purchase',
        label: 'المشتريات',
        icon: Icons.shopping_cart_rounded),
    _TabItem(
        type: 'sale_return',
        label: 'مرتجع مبيعات',
        icon: Icons.assignment_return_rounded),
    _TabItem(
        type: 'purchase_return',
        label: 'مرتجع مشتريات',
        icon: Icons.keyboard_return_rounded),
  ];

  @override
  void initState() {
    super.initState();
    int initialIndex = 0;
    if (widget.type != null) {
      initialIndex = _tabs.indexWhere((t) => t.type == widget.type);
      if (initialIndex < 0) initialIndex = 0;
    }
    _tabController = TabController(
      length: _tabs.length,
      vsync: this,
      initialIndex: initialIndex,
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: HoorColors.background,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            _buildHeader(context),

            // Search & Filter Bar
            _buildSearchBar(),

            // Tab Bar
            _buildTabBar(),

            // Content
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: _tabs
                    .map((tab) => _InvoicesList(
                          type: tab.type,
                          searchQuery: _searchQuery,
                        ))
                    .toList(),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: _buildFAB(context),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(HoorSpacing.lg.w),
      child: Row(
        children: [
          // Back Button
          _IconButton(
            icon: Icons.arrow_forward_ios_rounded,
            onTap: () => context.pop(),
          ),
          SizedBox(width: HoorSpacing.md.w),

          // Title
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'الفواتير',
                  style: HoorTypography.headlineSmall.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 2.h),
                StreamBuilder<List<Invoice>>(
                  stream: _invoiceRepo.watchAllInvoices(),
                  builder: (context, snapshot) {
                    final count = snapshot.data?.length ?? 0;
                    return Text(
                      '$count فاتورة',
                      style: HoorTypography.bodySmall.copyWith(
                        color: HoorColors.textSecondary,
                      ),
                    );
                  },
                ),
              ],
            ),
          ),

          // Export Button
          _IconButton(
            icon: Icons.file_download_outlined,
            onTap: () => _showExportOptions(context),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: HoorSpacing.lg.w),
      child: HoorSearchBar(
        controller: _searchController,
        hint: 'بحث عن فاتورة...',
        onChanged: (value) {
          setState(() => _searchQuery = value);
        },
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      height: 52.h,
      margin: EdgeInsets.symmetric(
        horizontal: HoorSpacing.lg.w,
        vertical: HoorSpacing.md.h,
      ),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: _tabs.length,
        itemBuilder: (context, index) {
          return AnimatedBuilder(
            animation: _tabController,
            builder: (context, child) {
              final isSelected = _tabController.index == index;
              final tab = _tabs[index];
              return GestureDetector(
                onTap: () => _tabController.animateTo(index),
                child: Container(
                  margin: EdgeInsets.only(left: HoorSpacing.sm.w),
                  padding: EdgeInsets.symmetric(horizontal: HoorSpacing.lg.w),
                  decoration: BoxDecoration(
                    color: isSelected ? HoorColors.primary : HoorColors.surface,
                    borderRadius: BorderRadius.circular(HoorRadius.full),
                    border: isSelected
                        ? null
                        : Border.all(color: HoorColors.border),
                    boxShadow: isSelected
                        ? [
                            BoxShadow(
                              color: HoorColors.primary.withValues(alpha: 0.2),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ]
                        : null,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        tab.icon,
                        size: HoorIconSize.sm,
                        color: isSelected
                            ? Colors.white
                            : HoorColors.textSecondary,
                      ),
                      SizedBox(width: HoorSpacing.xs.w),
                      Text(
                        tab.label,
                        style: HoorTypography.labelMedium.copyWith(
                          color: isSelected
                              ? Colors.white
                              : HoorColors.textSecondary,
                          fontWeight:
                              isSelected ? FontWeight.w600 : FontWeight.normal,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildFAB(BuildContext context) {
    return FloatingActionButton.extended(
      onPressed: () => _showNewInvoiceOptions(context),
      backgroundColor: HoorColors.primary,
      foregroundColor: Colors.white,
      elevation: 4,
      icon: const Icon(Icons.add_rounded),
      label: Text(
        'فاتورة جديدة',
        style: HoorTypography.labelLarge.copyWith(
          color: Colors.white,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  void _showNewInvoiceOptions(BuildContext context) {
    HoorActionSheet.show(
      context,
      title: 'إنشاء فاتورة جديدة',
      message: 'اختر نوع الفاتورة التي تريد إنشاءها',
      actions: [
        HoorActionSheetItem(
          label: 'فاتورة مبيعات',
          icon: Icons.point_of_sale_rounded,
          value: 'sale',
          onTap: () => context.push('/invoices/new/sale'),
        ),
        HoorActionSheetItem(
          label: 'فاتورة مشتريات',
          icon: Icons.shopping_cart_rounded,
          value: 'purchase',
          onTap: () => context.push('/invoices/new/purchase'),
        ),
        HoorActionSheetItem(
          label: 'مرتجع مبيعات',
          icon: Icons.assignment_return_rounded,
          value: 'sale_return',
          onTap: () => context.push('/invoices/new/sale_return'),
        ),
        HoorActionSheetItem(
          label: 'مرتجع مشتريات',
          icon: Icons.keyboard_return_rounded,
          value: 'purchase_return',
          onTap: () => context.push('/invoices/new/purchase_return'),
        ),
      ],
    );
  }

  void _showExportOptions(BuildContext context) {
    HoorActionSheet.show(
      context,
      title: 'تصدير الفواتير',
      message: 'اختر صيغة التصدير',
      actions: [
        HoorActionSheetItem(
          label: 'تصدير كملف Excel',
          icon: Icons.table_chart_rounded,
          onTap: () => _handleExport(ExportType.excel),
        ),
        HoorActionSheetItem(
          label: 'تصدير كملف PDF',
          icon: Icons.picture_as_pdf_rounded,
          onTap: () => _handleExport(ExportType.pdf),
        ),
        HoorActionSheetItem(
          label: 'مشاركة Excel',
          icon: Icons.share_rounded,
          onTap: () => _handleExport(ExportType.shareExcel),
        ),
        HoorActionSheetItem(
          label: 'مشاركة PDF',
          icon: Icons.ios_share_rounded,
          onTap: () => _handleExport(ExportType.sharePdf),
        ),
      ],
    );
  }

  Future<void> _handleExport(ExportType exportType) async {
    final currentTabIndex = _tabController.index;
    final currentType = _tabs[currentTabIndex].type;

    var invoices = await _invoiceRepo.getAllInvoices();
    if (currentType != null) {
      invoices = invoices.where((i) => i.type == currentType).toList();
    }

    if (invoices.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('لا توجد فواتير للتصدير'),
            backgroundColor: HoorColors.warning,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(HoorRadius.md),
            ),
          ),
        );
      }
      return;
    }

    try {
      switch (exportType) {
        case ExportType.excel:
          final filePath = await ExcelExportService.exportInvoices(
            invoices: invoices,
            type: currentType,
          );
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: const Text('تم تصدير الفواتير بنجاح'),
                backgroundColor: HoorColors.success,
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(HoorRadius.md),
                ),
                action: SnackBarAction(
                  label: 'مشاركة',
                  textColor: Colors.white,
                  onPressed: () => ExcelExportService.shareFile(filePath),
                ),
              ),
            );
          }
          break;

        case ExportType.pdf:
          final pdfBytes = await PdfExportService.generateInvoicesList(
            invoices: invoices,
            type: currentType,
          );
          await Printing.layoutPdf(
            onLayout: (PdfPageFormat format) async => pdfBytes,
            name: 'invoices_list.pdf',
          );
          break;

        case ExportType.sharePdf:
          final pdfBytes = await PdfExportService.generateInvoicesList(
            invoices: invoices,
            type: currentType,
          );
          await Printing.sharePdf(
            bytes: pdfBytes,
            filename: 'invoices_list.pdf',
          );
          break;

        case ExportType.shareExcel:
          final filePath = await ExcelExportService.exportInvoices(
            invoices: invoices,
            type: currentType,
          );
          await ExcelExportService.shareFile(filePath);
          break;
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('خطأ في التصدير: $e'),
            backgroundColor: HoorColors.error,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(HoorRadius.md),
            ),
          ),
        );
      }
    }
  }
}

/// ═══════════════════════════════════════════════════════════════════════════
/// Tab Item Data Class
/// ═══════════════════════════════════════════════════════════════════════════

class _TabItem {
  final String? type;
  final String label;
  final IconData icon;

  const _TabItem({
    this.type,
    required this.label,
    required this.icon,
  });
}

/// ═══════════════════════════════════════════════════════════════════════════
/// Icon Button Component
/// ═══════════════════════════════════════════════════════════════════════════

class _IconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _IconButton({
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: HoorColors.surface,
      borderRadius: BorderRadius.circular(HoorRadius.md),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(HoorRadius.md),
        child: Container(
          padding: EdgeInsets.all(HoorSpacing.sm.w),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(HoorRadius.md),
            border: Border.all(color: HoorColors.border),
          ),
          child: Icon(
            icon,
            size: HoorIconSize.md,
            color: HoorColors.textSecondary,
          ),
        ),
      ),
    );
  }
}

/// ═══════════════════════════════════════════════════════════════════════════
/// Invoices List with Search
/// ═══════════════════════════════════════════════════════════════════════════

class _InvoicesList extends StatelessWidget {
  final String? type;
  final String searchQuery;
  final _invoiceRepo = getIt<InvoiceRepository>();

  _InvoicesList({
    required this.type,
    required this.searchQuery,
  });

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<Invoice>>(
      stream: _invoiceRepo.watchAllInvoices(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: HoorLoading(
              size: HoorLoadingSize.large,
              message: 'جاري تحميل الفواتير...',
            ),
          );
        }

        var invoices = snapshot.data ?? [];

        // Filter by type
        if (type != null) {
          invoices = invoices.where((i) => i.type == type).toList();
        }

        // Filter by search query
        if (searchQuery.isNotEmpty) {
          invoices = invoices.where((i) {
            final query = searchQuery.toLowerCase();
            return i.id.toString().contains(query) ||
                i.invoiceNumber.toLowerCase().contains(query) ||
                i.total.toString().contains(query);
          }).toList();
        }

        if (invoices.isEmpty) {
          return HoorEmptyState(
            icon: Icons.receipt_long_outlined,
            title: 'لا توجد فواتير',
            message: searchQuery.isNotEmpty
                ? 'لم يتم العثور على فواتير تطابق بحثك'
                : 'ابدأ بإنشاء فاتورة جديدة',
            actionLabel: searchQuery.isEmpty ? 'إنشاء فاتورة' : null,
            onAction: searchQuery.isEmpty
                ? () {
                    if (type == null || type == 'sale') {
                      context.push('/invoices/new/sale');
                    } else {
                      context.push('/invoices/new/$type');
                    }
                  }
                : null,
          );
        }

        return ListView.separated(
          padding: EdgeInsets.all(HoorSpacing.lg.w),
          itemCount: invoices.length,
          separatorBuilder: (context, index) =>
              SizedBox(height: HoorSpacing.sm.h),
          itemBuilder: (context, index) {
            final invoice = invoices[index];
            return _InvoiceCard(
              invoice: invoice,
              onTap: () => context.push('/invoices/details/${invoice.id}'),
            );
          },
        );
      },
    );
  }
}

/// ═══════════════════════════════════════════════════════════════════════════
/// Invoice Card - Redesigned
/// ═══════════════════════════════════════════════════════════════════════════

class _InvoiceCard extends StatelessWidget {
  final Invoice invoice;
  final VoidCallback onTap;

  const _InvoiceCard({
    required this.invoice,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final typeInfo = _getTypeInfo(invoice.type);
    final formattedDate = _formatDate(invoice.invoiceDate);

    return Material(
      color: HoorColors.surface,
      borderRadius: BorderRadius.circular(HoorRadius.lg),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(HoorRadius.lg),
        child: Container(
          padding: EdgeInsets.all(HoorSpacing.md.w),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(HoorRadius.lg),
            border: Border.all(color: HoorColors.border.withValues(alpha: 0.5)),
          ),
          child: Row(
            children: [
              // Type Icon
              Container(
                padding: EdgeInsets.all(HoorSpacing.md.w),
                decoration: BoxDecoration(
                  color: typeInfo.color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(HoorRadius.md),
                ),
                child: Icon(
                  typeInfo.icon,
                  color: typeInfo.color,
                  size: HoorIconSize.lg,
                ),
              ),
              SizedBox(width: HoorSpacing.md.w),

              // Invoice Details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Invoice Number & Type
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            '#${invoice.id}',
                            style: HoorTypography.titleMedium.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        SizedBox(width: HoorSpacing.xs.w),
                        HoorBadge(
                          label: typeInfo.label,
                          color: typeInfo.color,
                          size: HoorBadgeSize.small,
                        ),
                      ],
                    ),
                    SizedBox(height: HoorSpacing.xs.h),

                    // Customer/Supplier Name
                    Text(
                      _getContactName(invoice),
                      style: HoorTypography.bodyMedium.copyWith(
                        color: HoorColors.textSecondary,
                      ),
                    ),
                    SizedBox(height: HoorSpacing.xs.h),

                    // Date
                    Row(
                      children: [
                        Icon(
                          Icons.schedule_rounded,
                          size: HoorIconSize.xs,
                          color: HoorColors.textTertiary,
                        ),
                        SizedBox(width: HoorSpacing.xxs.w),
                        Text(
                          formattedDate,
                          style: HoorTypography.labelSmall.copyWith(
                            color: HoorColors.textTertiary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Total & Status
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    invoice.total.toStringAsFixed(2),
                    style: HoorTypography.titleMedium.copyWith(
                      fontWeight: FontWeight.bold,
                      color: typeInfo.color,
                      fontFamily: 'IBM Plex Sans Arabic',
                    ),
                  ),
                  Text(
                    'ر.س',
                    style: HoorTypography.labelSmall.copyWith(
                      color: HoorColors.textSecondary,
                    ),
                  ),
                ],
              ),
              SizedBox(width: HoorSpacing.xs.w),

              // Arrow
              Icon(
                Icons.chevron_left_rounded,
                color: HoorColors.textTertiary,
                size: HoorIconSize.md,
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _getContactName(Invoice invoice) {
    if (invoice.type == 'sale' || invoice.type == 'sale_return') {
      return invoice.customerId != null ? 'عميل' : 'عميل نقدي';
    } else {
      return invoice.supplierId != null ? 'مورد' : 'مورد غير محدد';
    }
  }

  _TypeInfo _getTypeInfo(String type) {
    switch (type) {
      case 'sale':
        return _TypeInfo(
          label: 'مبيعات',
          icon: Icons.point_of_sale_rounded,
          color: HoorColors.sales,
        );
      case 'purchase':
        return _TypeInfo(
          label: 'مشتريات',
          icon: Icons.shopping_cart_rounded,
          color: HoorColors.purchases,
        );
      case 'sale_return':
        return _TypeInfo(
          label: 'مرتجع',
          icon: Icons.assignment_return_rounded,
          color: HoorColors.returns,
        );
      case 'purchase_return':
        return _TypeInfo(
          label: 'مرتجع مشتريات',
          icon: Icons.keyboard_return_rounded,
          color: HoorColors.warning,
        );
      default:
        return _TypeInfo(
          label: 'فاتورة',
          icon: Icons.receipt_rounded,
          color: HoorColors.textSecondary,
        );
    }
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      return 'اليوم ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
    } else if (difference.inDays == 1) {
      return 'أمس';
    } else if (difference.inDays < 7) {
      return 'منذ ${difference.inDays} أيام';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }
}

class _TypeInfo {
  final String label;
  final IconData icon;
  final Color color;

  const _TypeInfo({
    required this.label,
    required this.icon,
    required this.color,
  });
}
