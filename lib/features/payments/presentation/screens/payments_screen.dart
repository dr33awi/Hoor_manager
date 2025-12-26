import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../domain/entities/entities.dart';
import '../providers/payment_providers.dart';
import '../widgets/payment_card.dart';
import '../widgets/payment_stats_card.dart';

/// شاشة السندات المالية
class PaymentsScreen extends ConsumerStatefulWidget {
  const PaymentsScreen({super.key});

  @override
  ConsumerState<PaymentsScreen> createState() => _PaymentsScreenState();
}

class _PaymentsScreenState extends ConsumerState<PaymentsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _searchController = TextEditingController();
  PaymentVoucherType? _selectedType;
  PaymentVoucherStatus? _selectedStatus;
  DateTimeRange? _dateRange;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('السندات المالية'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'الكل', icon: Icon(Icons.receipt_long)),
            Tab(text: 'القبض', icon: Icon(Icons.arrow_downward)),
            Tab(text: 'الصرف', icon: Icon(Icons.arrow_upward)),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: _showFilterSheet,
          ),
        ],
      ),
      body: Column(
        children: [
          // الإحصائيات
          const PaymentStatsCard(),

          // البحث
          Padding(
            padding: EdgeInsets.all(16.w),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'بحث في السندات...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          setState(() {});
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12.r),
                ),
              ),
              onChanged: (_) => setState(() {}),
            ),
          ),

          // قائمة السندات
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildPaymentsList(ref.watch(paymentsProvider)),
                _buildPaymentsList(ref.watch(receiptsProvider)),
                _buildPaymentsList(ref.watch(paymentVouchersProvider)),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddPaymentSheet,
        icon: const Icon(Icons.add),
        label: const Text('سند جديد'),
      ),
    );
  }

  Widget _buildPaymentsList(
      AsyncValue<List<PaymentVoucherEntity>> paymentsAsync) {
    return paymentsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64.sp, color: Colors.red),
            SizedBox(height: 16.h),
            Text('حدث خطأ: $error'),
            SizedBox(height: 16.h),
            ElevatedButton(
              onPressed: () => ref.invalidate(paymentsProvider),
              child: const Text('إعادة المحاولة'),
            ),
          ],
        ),
      ),
      data: (payments) {
        // تطبيق الفلاتر
        var filtered = _applyFilters(payments);

        // تطبيق البحث
        final query = _searchController.text.toLowerCase();
        if (query.isNotEmpty) {
          filtered = filtered.where((p) {
            return p.voucherNumber.toLowerCase().contains(query) ||
                (p.description?.toLowerCase().contains(query) ?? false) ||
                (p.partyName?.toLowerCase().contains(query) ?? false);
          }).toList();
        }

        if (filtered.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.receipt_long, size: 64.sp, color: Colors.grey),
                SizedBox(height: 16.h),
                Text(
                  'لا توجد سندات',
                  style: TextStyle(fontSize: 18.sp, color: Colors.grey),
                ),
              ],
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: () async => ref.invalidate(paymentsProvider),
          child: ListView.builder(
            padding: EdgeInsets.all(16.w),
            itemCount: filtered.length,
            itemBuilder: (context, index) {
              final payment = filtered[index];
              return PaymentCard(
                payment: payment,
                onTap: () => _showPaymentDetails(payment),
                onEdit: () => _showEditPaymentSheet(payment),
                onDelete: () => _confirmDelete(payment),
                onStatusChange: () => _showStatusChangeDialog(payment),
              );
            },
          ),
        );
      },
    );
  }

  List<PaymentVoucherEntity> _applyFilters(
      List<PaymentVoucherEntity> payments) {
    var filtered = payments;

    if (_selectedType != null) {
      filtered = filtered.where((p) => p.type == _selectedType).toList();
    }

    if (_selectedStatus != null) {
      filtered = filtered.where((p) => p.status == _selectedStatus).toList();
    }

    if (_dateRange != null) {
      filtered = filtered.where((p) {
        return p.voucherDate.isAfter(_dateRange!.start) &&
            p.voucherDate
                .isBefore(_dateRange!.end.add(const Duration(days: 1)));
      }).toList();
    }

    return filtered;
  }

  void _showFilterSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => StatefulBuilder(
        builder: (context, setSheetState) => DraggableScrollableSheet(
          initialChildSize: 0.6,
          minChildSize: 0.3,
          maxChildSize: 0.9,
          expand: false,
          builder: (context, scrollController) => SingleChildScrollView(
            controller: scrollController,
            padding: EdgeInsets.all(16.w),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40.w,
                    height: 4.h,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(2.r),
                    ),
                  ),
                ),
                SizedBox(height: 16.h),
                Text(
                  'تصفية السندات',
                  style: TextStyle(
                    fontSize: 20.sp,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 24.h),

                // نوع السند
                Text('نوع السند',
                    style: TextStyle(fontWeight: FontWeight.bold)),
                SizedBox(height: 8.h),
                Wrap(
                  spacing: 8.w,
                  children: [
                    FilterChip(
                      label: const Text('الكل'),
                      selected: _selectedType == null,
                      onSelected: (_) {
                        setSheetState(() => _selectedType = null);
                      },
                    ),
                    ...PaymentVoucherType.values.map((type) => FilterChip(
                          label: Text(type.arabicName),
                          selected: _selectedType == type,
                          onSelected: (_) {
                            setSheetState(() => _selectedType = type);
                          },
                        )),
                  ],
                ),
                SizedBox(height: 16.h),

                // الحالة
                Text('الحالة', style: TextStyle(fontWeight: FontWeight.bold)),
                SizedBox(height: 8.h),
                Wrap(
                  spacing: 8.w,
                  children: [
                    FilterChip(
                      label: const Text('الكل'),
                      selected: _selectedStatus == null,
                      onSelected: (_) {
                        setSheetState(() => _selectedStatus = null);
                      },
                    ),
                    ...PaymentVoucherStatus.values.map((status) => FilterChip(
                          label: Text(status.arabicName),
                          selected: _selectedStatus == status,
                          onSelected: (_) {
                            setSheetState(() => _selectedStatus = status);
                          },
                        )),
                  ],
                ),
                SizedBox(height: 16.h),

                // الفترة الزمنية
                Text('الفترة الزمنية',
                    style: TextStyle(fontWeight: FontWeight.bold)),
                SizedBox(height: 8.h),
                OutlinedButton.icon(
                  onPressed: () async {
                    final range = await showDateRangePicker(
                      context: context,
                      firstDate: DateTime(2020),
                      lastDate: DateTime.now(),
                      initialDateRange: _dateRange,
                    );
                    if (range != null) {
                      setSheetState(() => _dateRange = range);
                    }
                  },
                  icon: const Icon(Icons.date_range),
                  label: Text(_dateRange != null
                      ? '${_dateRange!.start.toString().split(' ')[0]} - ${_dateRange!.end.toString().split(' ')[0]}'
                      : 'اختر الفترة'),
                ),
                SizedBox(height: 24.h),

                // أزرار التحكم
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () {
                          setSheetState(() {
                            _selectedType = null;
                            _selectedStatus = null;
                            _dateRange = null;
                          });
                        },
                        child: const Text('مسح الفلاتر'),
                      ),
                    ),
                    SizedBox(width: 16.w),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          setState(() {});
                          Navigator.pop(context);
                        },
                        child: const Text('تطبيق'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showAddPaymentSheet() {
    _showPaymentFormSheet(null);
  }

  void _showEditPaymentSheet(PaymentVoucherEntity payment) {
    _showPaymentFormSheet(payment);
  }

  void _showPaymentFormSheet(PaymentVoucherEntity? payment) {
    final isEdit = payment != null;
    final formKey = GlobalKey<FormState>();
    var type = payment?.type ?? PaymentVoucherType.receipt;
    var method = payment?.method ?? PaymentMethod.cash;
    final amountController =
        TextEditingController(text: payment?.amount.toString() ?? '');
    final descriptionController =
        TextEditingController(text: payment?.description ?? '');
    final referenceController =
        TextEditingController(text: payment?.referenceNumber ?? '');

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => StatefulBuilder(
        builder: (context, setSheetState) => DraggableScrollableSheet(
          initialChildSize: 0.9,
          minChildSize: 0.5,
          maxChildSize: 0.95,
          expand: false,
          builder: (context, scrollController) => SingleChildScrollView(
            controller: scrollController,
            padding: EdgeInsets.all(16.w),
            child: Form(
              key: formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40.w,
                      height: 4.h,
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(2.r),
                      ),
                    ),
                  ),
                  SizedBox(height: 16.h),
                  Text(
                    isEdit ? 'تعديل السند' : 'سند جديد',
                    style: TextStyle(
                      fontSize: 20.sp,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 24.h),

                  // نوع السند
                  Text('نوع السند *',
                      style: TextStyle(fontWeight: FontWeight.bold)),
                  SizedBox(height: 8.h),
                  SegmentedButton<PaymentVoucherType>(
                    segments: PaymentVoucherType.values
                        .map((t) => ButtonSegment(
                              value: t,
                              label: Text(t.arabicName),
                            ))
                        .toList(),
                    selected: {type},
                    onSelectionChanged: (selected) {
                      setSheetState(() => type = selected.first);
                    },
                  ),
                  SizedBox(height: 16.h),

                  // طريقة الدفع
                  Text('طريقة الدفع *',
                      style: TextStyle(fontWeight: FontWeight.bold)),
                  SizedBox(height: 8.h),
                  DropdownButtonFormField<PaymentMethod>(
                    value: method,
                    decoration: InputDecoration(
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12.r),
                      ),
                    ),
                    items: PaymentMethod.values
                        .map((m) => DropdownMenuItem(
                              value: m,
                              child: Text(m.arabicName),
                            ))
                        .toList(),
                    onChanged: (value) {
                      if (value != null) {
                        setSheetState(() => method = value);
                      }
                    },
                  ),
                  SizedBox(height: 16.h),

                  // المبلغ
                  TextFormField(
                    controller: amountController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: 'المبلغ *',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12.r),
                      ),
                      suffixText: 'ر.س',
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'المبلغ مطلوب';
                      }
                      if (double.tryParse(value) == null) {
                        return 'أدخل مبلغ صحيح';
                      }
                      return null;
                    },
                  ),
                  SizedBox(height: 16.h),

                  // الوصف
                  TextFormField(
                    controller: descriptionController,
                    maxLines: 3,
                    decoration: InputDecoration(
                      labelText: 'الوصف',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12.r),
                      ),
                    ),
                  ),
                  SizedBox(height: 16.h),

                  // رقم المرجع
                  TextFormField(
                    controller: referenceController,
                    decoration: InputDecoration(
                      labelText: 'رقم المرجع',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12.r),
                      ),
                    ),
                  ),
                  SizedBox(height: 24.h),

                  // أزرار الحفظ
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () async {
                        if (formKey.currentState!.validate()) {
                          final notifier =
                              ref.read(paymentNotifierProvider.notifier);

                          if (isEdit) {
                            final updated = payment.copyWith(
                              type: type,
                              paymentMethod: method,
                              amount: double.parse(amountController.text),
                              description: descriptionController.text.isEmpty
                                  ? null
                                  : descriptionController.text,
                              transferReference:
                                  referenceController.text.isEmpty
                                      ? null
                                      : referenceController.text,
                            );
                            await notifier.updatePayment(updated);
                          } else {
                            final voucherNumber =
                                await notifier.generateVoucherNumber(type);
                            final newPayment = PaymentVoucherEntity(
                              id: '',
                              voucherNumber: voucherNumber,
                              type: type,
                              paymentMethod: method,
                              amount: double.parse(amountController.text),
                              description: descriptionController.text.isEmpty
                                  ? null
                                  : descriptionController.text,
                              transferReference:
                                  referenceController.text.isEmpty
                                      ? null
                                      : referenceController.text,
                              date: DateTime.now(),
                              status: PaymentVoucherStatus.draft,
                              createdBy:
                                  'current_user', // TODO: Get current user
                              createdAt: DateTime.now(),
                              updatedAt: DateTime.now(),
                            );
                            await notifier.createPayment(newPayment);
                          }

                          if (mounted) {
                            Navigator.pop(context);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(isEdit
                                    ? 'تم تحديث السند بنجاح'
                                    : 'تم إنشاء السند بنجاح'),
                              ),
                            );
                          }
                        }
                      },
                      child: Padding(
                        padding: EdgeInsets.symmetric(vertical: 16.h),
                        child: Text(isEdit ? 'تحديث' : 'إنشاء'),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _showPaymentDetails(PaymentVoucherEntity payment) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.3,
        maxChildSize: 0.9,
        expand: false,
        builder: (context, scrollController) => SingleChildScrollView(
          controller: scrollController,
          padding: EdgeInsets.all(16.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40.w,
                  height: 4.h,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2.r),
                  ),
                ),
              ),
              SizedBox(height: 16.h),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'تفاصيل السند',
                      style: TextStyle(
                        fontSize: 20.sp,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Container(
                    padding:
                        EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
                    decoration: BoxDecoration(
                      color: payment.status.color.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(20.r),
                    ),
                    child: Text(
                      payment.status.arabicName,
                      style: TextStyle(
                        color: payment.status.color,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 24.h),
              _buildDetailRow('رقم السند', payment.voucherNumber),
              _buildDetailRow('النوع', payment.type.arabicName),
              _buildDetailRow('طريقة الدفع', payment.method.arabicName),
              _buildDetailRow(
                  'المبلغ', '${payment.amount.toStringAsFixed(2)} ر.س'),
              _buildDetailRow(
                  'التاريخ', payment.voucherDate.toString().split(' ')[0]),
              if (payment.partyName != null)
                _buildDetailRow('الطرف', payment.partyName!),
              if (payment.description != null)
                _buildDetailRow('الوصف', payment.description!),
              if (payment.referenceNumber != null)
                _buildDetailRow('رقم المرجع', payment.referenceNumber!),
              _buildDetailRow('أنشئ بواسطة', payment.createdBy ?? 'غير معروف'),
              _buildDetailRow(
                  'تاريخ الإنشاء', payment.createdAt.toString().split(' ')[0]),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8.h),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120.w,
            child: Text(
              label,
              style: TextStyle(
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  void _confirmDelete(PaymentVoucherEntity payment) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('حذف السند'),
        content: Text('هل أنت متأكد من حذف السند ${payment.voucherNumber}؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إلغاء'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              final notifier = ref.read(paymentNotifierProvider.notifier);
              final success = await notifier.deletePayment(payment.id);
              if (success && mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('تم حذف السند بنجاح')),
                );
              }
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('حذف'),
          ),
        ],
      ),
    );
  }

  void _showStatusChangeDialog(PaymentVoucherEntity payment) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('تغيير الحالة'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: PaymentVoucherStatus.values
              .where((s) => s != payment.status)
              .map((status) => ListTile(
                    title: Text(status.arabicName),
                    leading: Icon(Icons.circle, color: status.color),
                    onTap: () async {
                      Navigator.pop(context);
                      final notifier =
                          ref.read(paymentNotifierProvider.notifier);
                      await notifier.updateStatus(
                        id: payment.id,
                        status: status,
                      );
                    },
                  ))
              .toList(),
        ),
      ),
    );
  }
}
