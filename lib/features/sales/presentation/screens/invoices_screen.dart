import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/constants.dart';
import '../../../../core/extensions/extensions.dart';
import '../../domain/entities/entities.dart';
import '../providers/sales_providers.dart';
import '../widgets/widgets.dart';

/// فلتر حالة الفاتورة
final invoiceStatusFilterProvider =
    StateProvider<InvoiceStatus?>((ref) => null);

/// فلتر تاريخ البداية
final invoiceStartDateProvider = StateProvider<DateTime?>((ref) => null);

/// فلتر تاريخ النهاية
final invoiceEndDateProvider = StateProvider<DateTime?>((ref) => null);

/// نص البحث
final invoiceSearchQueryProvider = StateProvider<String>((ref) => '');

/// مزود الفواتير المفلترة
final filteredInvoicesProvider = StreamProvider<List<InvoiceEntity>>((ref) {
  final repository = ref.watch(salesRepositoryProvider);
  return repository.watchInvoices();
});

/// مزود الفواتير المعروضة (بعد تطبيق الفلاتر)
final displayedInvoicesProvider =
    Provider<AsyncValue<List<InvoiceEntity>>>((ref) {
  final invoicesAsync = ref.watch(filteredInvoicesProvider);
  final statusFilter = ref.watch(invoiceStatusFilterProvider);
  final startDate = ref.watch(invoiceStartDateProvider);
  final endDate = ref.watch(invoiceEndDateProvider);
  final searchQuery = ref.watch(invoiceSearchQueryProvider).toLowerCase();

  return invoicesAsync.when(
    data: (invoices) {
      var filtered = invoices;

      // فلترة حسب الحالة
      if (statusFilter != null) {
        filtered = filtered.where((inv) => inv.status == statusFilter).toList();
      }

      // فلترة حسب التاريخ
      if (startDate != null) {
        filtered = filtered
            .where((inv) =>
                inv.saleDate.isAfter(startDate) ||
                inv.saleDate.isAtSameMomentAs(startDate))
            .toList();
      }
      if (endDate != null) {
        final endOfDay =
            DateTime(endDate.year, endDate.month, endDate.day, 23, 59, 59);
        filtered = filtered
            .where((inv) =>
                inv.saleDate.isBefore(endOfDay) ||
                inv.saleDate.isAtSameMomentAs(endOfDay))
            .toList();
      }

      // البحث
      if (searchQuery.isNotEmpty) {
        filtered = filtered.where((inv) {
          return inv.invoiceNumber.toLowerCase().contains(searchQuery) ||
              inv.items.any((item) =>
                  item.productName.toLowerCase().contains(searchQuery));
        }).toList();
      }

      // ترتيب: حسب الحالة أولاً ثم التاريخ
      filtered.sort((a, b) {
        final statusOrder = {
          InvoiceStatus.completed: 0,
          InvoiceStatus.cancelled: 1,
          InvoiceStatus.refunded: 2,
        };
        final statusCompare =
            statusOrder[a.status]!.compareTo(statusOrder[b.status]!);
        if (statusCompare != 0) return statusCompare;
        return b.saleDate.compareTo(a.saleDate);
      });

      return AsyncValue.data(filtered);
    },
    loading: () => const AsyncValue.loading(),
    error: (e, st) => AsyncValue.error(e, st),
  );
});

/// شاشة الفواتير
class InvoicesScreen extends ConsumerStatefulWidget {
  const InvoicesScreen({super.key});

  @override
  ConsumerState<InvoicesScreen> createState() => _InvoicesScreenState();
}

class _InvoicesScreenState extends ConsumerState<InvoicesScreen> {
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final invoicesAsync = ref.watch(displayedInvoicesProvider);
    final statusFilter = ref.watch(invoiceStatusFilterProvider);
    final startDate = ref.watch(invoiceStartDateProvider);
    final endDate = ref.watch(invoiceEndDateProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('الفواتير'),
        actions: [
          // زر الفلاتر
          IconButton(
            icon: Badge(
              isLabelVisible:
                  statusFilter != null || startDate != null || endDate != null,
              child: const Icon(Icons.filter_list),
            ),
            onPressed: () => _showFilterSheet(context),
            tooltip: 'الفلاتر',
          ),
        ],
      ),
      body: Column(
        children: [
          // شريط البحث
          Padding(
            padding: const EdgeInsets.all(AppSizes.md),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'بحث برقم الفاتورة أو المنتج...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          ref.read(invoiceSearchQueryProvider.notifier).state =
                              '';
                        },
                      )
                    : null,
              ),
              onChanged: (value) {
                ref.read(invoiceSearchQueryProvider.notifier).state = value;
              },
            ),
          ),

          // شريط الفلاتر السريعة (حسب الحالة)
          _buildStatusFilterChips(),

          // الفلاتر النشطة
          if (startDate != null || endDate != null) _buildActiveDateFilters(),

          // قائمة الفواتير
          Expanded(
            child: RefreshIndicator(
              onRefresh: () async {
                ref.invalidate(filteredInvoicesProvider);
              },
              child: invoicesAsync.when(
                data: (invoices) {
                  if (invoices.isEmpty) {
                    return _buildEmptyState();
                  }
                  return _buildInvoicesList(invoices);
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, _) => Center(child: Text('خطأ: $e')),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusFilterChips() {
    final statusFilter = ref.watch(invoiceStatusFilterProvider);

    return SizedBox(
      height: 50,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: AppSizes.sm),
        children: [
          Padding(
            padding: const EdgeInsets.only(left: AppSizes.xs),
            child: ChoiceChip(
              label: const Text('الكل'),
              selected: statusFilter == null,
              onSelected: (_) {
                ref.read(invoiceStatusFilterProvider.notifier).state = null;
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(left: AppSizes.xs),
            child: ChoiceChip(
              label: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: AppColors.success,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 4),
                  const Text('مكتملة'),
                ],
              ),
              selected: statusFilter == InvoiceStatus.completed,
              onSelected: (_) {
                ref.read(invoiceStatusFilterProvider.notifier).state =
                    statusFilter == InvoiceStatus.completed
                        ? null
                        : InvoiceStatus.completed;
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(left: AppSizes.xs),
            child: ChoiceChip(
              label: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: AppColors.error,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 4),
                  const Text('ملغاة'),
                ],
              ),
              selected: statusFilter == InvoiceStatus.cancelled,
              onSelected: (_) {
                ref.read(invoiceStatusFilterProvider.notifier).state =
                    statusFilter == InvoiceStatus.cancelled
                        ? null
                        : InvoiceStatus.cancelled;
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(left: AppSizes.xs),
            child: ChoiceChip(
              label: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: AppColors.warning,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 4),
                  const Text('مسترجعة'),
                ],
              ),
              selected: statusFilter == InvoiceStatus.refunded,
              onSelected: (_) {
                ref.read(invoiceStatusFilterProvider.notifier).state =
                    statusFilter == InvoiceStatus.refunded
                        ? null
                        : InvoiceStatus.refunded;
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActiveDateFilters() {
    final startDate = ref.watch(invoiceStartDateProvider);
    final endDate = ref.watch(invoiceEndDateProvider);

    return Container(
      padding: const EdgeInsets.symmetric(
          horizontal: AppSizes.md, vertical: AppSizes.xs),
      child: Row(
        children: [
          const Icon(Icons.date_range,
              size: 16, color: AppColors.textSecondary),
          const SizedBox(width: AppSizes.xs),
          if (startDate != null)
            Chip(
              label: Text('من: ${startDate.toShortDate}'),
              onDeleted: () {
                ref.read(invoiceStartDateProvider.notifier).state = null;
              },
              deleteIconColor: AppColors.textSecondary,
              visualDensity: VisualDensity.compact,
            ),
          if (startDate != null && endDate != null)
            const SizedBox(width: AppSizes.xs),
          if (endDate != null)
            Chip(
              label: Text('إلى: ${endDate.toShortDate}'),
              onDeleted: () {
                ref.read(invoiceEndDateProvider.notifier).state = null;
              },
              deleteIconColor: AppColors.textSecondary,
              visualDensity: VisualDensity.compact,
            ),
        ],
      ),
    );
  }

  Widget _buildInvoicesList(List<InvoiceEntity> invoices) {
    // تجميع الفواتير حسب التاريخ
    final groupedInvoices = <String, List<InvoiceEntity>>{};
    for (final invoice in invoices) {
      final dateKey = invoice.saleDate.toShortDate;
      groupedInvoices.putIfAbsent(dateKey, () => []).add(invoice);
    }

    return ListView.builder(
      padding: const EdgeInsets.only(bottom: AppSizes.xl),
      itemCount: groupedInvoices.length,
      itemBuilder: (context, index) {
        final dateKey = groupedInvoices.keys.elementAt(index);
        final dateInvoices = groupedInvoices[dateKey]!;

        // حساب إجمالي اليوم
        final dayTotal = dateInvoices
            .where((inv) => inv.status == InvoiceStatus.completed)
            .fold(0.0, (sum, inv) => sum + inv.total);

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // عنوان اليوم مع الإجمالي
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSizes.md,
                vertical: AppSizes.sm,
              ),
              color: Theme.of(context).scaffoldBackgroundColor,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    dateKey,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          color: AppColors.textSecondary,
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  Text(
                    '${dateInvoices.length} فاتورة • ${dayTotal.toCurrency()}',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                  ),
                ],
              ),
            ),
            // فواتير اليوم
            ...dateInvoices.map((invoice) => InvoiceCard(
                  invoice: invoice,
                  onTap: () => context.push('/sales/${invoice.id}'),
                )),
          ],
        );
      },
    );
  }

  Widget _buildEmptyState() {
    final hasFilters = ref.read(invoiceStatusFilterProvider) != null ||
        ref.read(invoiceStartDateProvider) != null ||
        ref.read(invoiceEndDateProvider) != null ||
        ref.read(invoiceSearchQueryProvider).isNotEmpty;

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            hasFilters ? Icons.filter_alt_off : Icons.receipt_long_outlined,
            size: 80,
            color: AppColors.textHint,
          ),
          const SizedBox(height: AppSizes.md),
          Text(
            hasFilters ? 'لا توجد فواتير مطابقة للفلاتر' : 'لا توجد فواتير',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: AppColors.textSecondary,
                ),
          ),
          if (hasFilters) ...[
            const SizedBox(height: AppSizes.sm),
            TextButton.icon(
              onPressed: _clearAllFilters,
              icon: const Icon(Icons.clear_all),
              label: const Text('مسح الفلاتر'),
            ),
          ],
        ],
      ),
    );
  }

  void _clearAllFilters() {
    ref.read(invoiceStatusFilterProvider.notifier).state = null;
    ref.read(invoiceStartDateProvider.notifier).state = null;
    ref.read(invoiceEndDateProvider.notifier).state = null;
    ref.read(invoiceSearchQueryProvider.notifier).state = '';
    _searchController.clear();
  }

  void _showFilterSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius:
            BorderRadius.vertical(top: Radius.circular(AppSizes.radiusLg)),
      ),
      builder: (context) => const _FilterBottomSheet(),
    );
  }
}

/// شاشة الفلاتر
class _FilterBottomSheet extends ConsumerWidget {
  const _FilterBottomSheet();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final startDate = ref.watch(invoiceStartDateProvider);
    final endDate = ref.watch(invoiceEndDateProvider);

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        padding: const EdgeInsets.all(AppSizes.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // العنوان
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'الفلاتر',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                TextButton(
                  onPressed: () {
                    ref.read(invoiceStatusFilterProvider.notifier).state = null;
                    ref.read(invoiceStartDateProvider.notifier).state = null;
                    ref.read(invoiceEndDateProvider.notifier).state = null;
                    Navigator.pop(context);
                  },
                  child: const Text('مسح الكل'),
                ),
              ],
            ),
            const Divider(),
            const SizedBox(height: AppSizes.md),

            // فلتر التاريخ
            Text(
              'نطاق التاريخ',
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: AppSizes.sm),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _selectDate(context, ref, isStart: true),
                    icon: const Icon(Icons.calendar_today, size: 18),
                    label: Text(startDate?.toShortDate ?? 'من'),
                  ),
                ),
                const SizedBox(width: AppSizes.sm),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _selectDate(context, ref, isStart: false),
                    icon: const Icon(Icons.calendar_today, size: 18),
                    label: Text(endDate?.toShortDate ?? 'إلى'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSizes.md),

            // اختصارات التواريخ
            Wrap(
              spacing: AppSizes.xs,
              children: [
                ActionChip(
                  label: const Text('اليوم'),
                  onPressed: () {
                    final now = DateTime.now();
                    final today = DateTime(now.year, now.month, now.day);
                    ref.read(invoiceStartDateProvider.notifier).state = today;
                    ref.read(invoiceEndDateProvider.notifier).state = today;
                  },
                ),
                ActionChip(
                  label: const Text('أمس'),
                  onPressed: () {
                    final now = DateTime.now();
                    final yesterday =
                        DateTime(now.year, now.month, now.day - 1);
                    ref.read(invoiceStartDateProvider.notifier).state =
                        yesterday;
                    ref.read(invoiceEndDateProvider.notifier).state = yesterday;
                  },
                ),
                ActionChip(
                  label: const Text('هذا الأسبوع'),
                  onPressed: () {
                    final now = DateTime.now();
                    final startOfWeek =
                        now.subtract(Duration(days: now.weekday - 1));
                    ref.read(invoiceStartDateProvider.notifier).state =
                        DateTime(startOfWeek.year, startOfWeek.month,
                            startOfWeek.day);
                    ref.read(invoiceEndDateProvider.notifier).state = now;
                  },
                ),
                ActionChip(
                  label: const Text('هذا الشهر'),
                  onPressed: () {
                    final now = DateTime.now();
                    ref.read(invoiceStartDateProvider.notifier).state =
                        DateTime(now.year, now.month, 1);
                    ref.read(invoiceEndDateProvider.notifier).state = now;
                  },
                ),
                ActionChip(
                  label: const Text('الشهر الماضي'),
                  onPressed: () {
                    final now = DateTime.now();
                    final lastMonth = DateTime(now.year, now.month - 1, 1);
                    final lastDayOfLastMonth = DateTime(now.year, now.month, 0);
                    ref.read(invoiceStartDateProvider.notifier).state =
                        lastMonth;
                    ref.read(invoiceEndDateProvider.notifier).state =
                        lastDayOfLastMonth;
                  },
                ),
              ],
            ),

            const SizedBox(height: AppSizes.lg),

            // زر تطبيق
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('تطبيق'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _selectDate(BuildContext context, WidgetRef ref,
      {required bool isStart}) async {
    final initialDate = isStart
        ? ref.read(invoiceStartDateProvider) ?? DateTime.now()
        : ref.read(invoiceEndDateProvider) ?? DateTime.now();

    final picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      locale: const Locale('ar'),
    );

    if (picked != null) {
      if (isStart) {
        ref.read(invoiceStartDateProvider.notifier).state = picked;
      } else {
        ref.read(invoiceEndDateProvider.notifier).state = picked;
      }
    }
  }
}
