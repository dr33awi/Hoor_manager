import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/redesign/design_system.dart';
import '../../../../core/di/injection.dart';
import '../../../../core/services/currency_service.dart';
import '../../../../data/database/app_database.dart';
import '../../../../data/repositories/customer_repository.dart';

/// ═══════════════════════════════════════════════════════════════════════════
/// Customers Screen - Modern Redesign
/// Professional Customer Management Interface
/// ═══════════════════════════════════════════════════════════════════════════

class CustomersScreenRedesign extends ConsumerStatefulWidget {
  const CustomersScreenRedesign({super.key});

  @override
  ConsumerState<CustomersScreenRedesign> createState() =>
      _CustomersScreenRedesignState();
}

class _CustomersScreenRedesignState
    extends ConsumerState<CustomersScreenRedesign> {
  final _customerRepo = getIt<CustomerRepository>();
  final _currencyService = getIt<CurrencyService>();
  final _searchController = TextEditingController();

  String _searchQuery = '';
  _SortOption _sortBy = _SortOption.name;
  bool _sortDescending = false;
  bool _showOnlyWithBalance = false;

  @override
  void dispose() {
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

            // Stats Section
            _buildStats(),

            // Search & Filter Bar
            _buildSearchAndFilters(),

            // Customers List
            Expanded(child: _buildCustomersList()),
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
                  'العملاء',
                  style: HoorTypography.headlineSmall.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 2.h),
                StreamBuilder<List<Customer>>(
                  stream: _customerRepo.watchAllCustomers(),
                  builder: (context, snapshot) {
                    final count = snapshot.data?.length ?? 0;
                    return Text(
                      '$count عميل',
                      style: HoorTypography.bodySmall.copyWith(
                        color: HoorColors.textSecondary,
                      ),
                    );
                  },
                ),
              ],
            ),
          ),

          // Balance Filter
          _FilterButton(
            icon: Icons.account_balance_wallet_rounded,
            isActive: _showOnlyWithBalance,
            activeColor: HoorColors.warning,
            tooltip: 'إظهار من عليهم رصيد',
            onTap: () =>
                setState(() => _showOnlyWithBalance = !_showOnlyWithBalance),
          ),
          SizedBox(width: HoorSpacing.xs.w),

          // Sort Menu
          _SortButton(
            sortBy: _sortBy,
            sortDescending: _sortDescending,
            onSortChanged: (option, descending) {
              setState(() {
                _sortBy = option;
                _sortDescending = descending;
              });
            },
          ),
        ],
      ),
    );
  }

  Widget _buildStats() {
    return StreamBuilder<List<Customer>>(
      stream: _customerRepo.watchAllCustomers(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return SizedBox(
            height: 100.h,
            child:
                const Center(child: HoorLoading(size: HoorLoadingSize.small)),
          );
        }

        final customers = snapshot.data!;
        final totalCustomers = customers.length;
        final customersWithBalance =
            customers.where((c) => c.balance > 0).length;
        final totalBalance = customers.fold<double>(
          0,
          (sum, c) => sum + c.balance,
        );

        return Container(
          margin: EdgeInsets.symmetric(horizontal: HoorSpacing.lg.w),
          child: Row(
            children: [
              Expanded(
                child: _MiniStatCard(
                  icon: Icons.people_rounded,
                  label: 'إجمالي العملاء',
                  value: totalCustomers.toString(),
                  color: HoorColors.primary,
                ),
              ),
              SizedBox(width: HoorSpacing.sm.w),
              Expanded(
                child: _MiniStatCard(
                  icon: Icons.account_balance_wallet_rounded,
                  label: 'عليهم رصيد',
                  value: customersWithBalance.toString(),
                  color: customersWithBalance > 0
                      ? HoorColors.warning
                      : HoorColors.success,
                ),
              ),
              SizedBox(width: HoorSpacing.sm.w),
              Expanded(
                child: _MiniStatCard(
                  icon: Icons.payments_rounded,
                  label: 'إجمالي الرصيد',
                  value: _formatCurrency(totalBalance),
                  color: HoorColors.expense,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSearchAndFilters() {
    return Padding(
      padding: EdgeInsets.all(HoorSpacing.lg.w),
      child: HoorSearchBar(
        controller: _searchController,
        hint: 'بحث عن عميل بالاسم أو الهاتف...',
        onChanged: (value) => setState(() => _searchQuery = value),
        onClear: _searchQuery.isNotEmpty
            ? () {
                _searchController.clear();
                setState(() => _searchQuery = '');
              }
            : null,
      ),
    );
  }

  Widget _buildCustomersList() {
    return StreamBuilder<List<Customer>>(
      stream: _customerRepo.watchAllCustomers(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: HoorLoading(
              size: HoorLoadingSize.large,
              message: 'جاري تحميل العملاء...',
            ),
          );
        }

        var customers = snapshot.data ?? [];

        // Apply filters
        if (_searchQuery.isNotEmpty) {
          customers = customers
              .where((c) =>
                  c.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
                  (c.phone?.contains(_searchQuery) ?? false) ||
                  (c.email
                          ?.toLowerCase()
                          .contains(_searchQuery.toLowerCase()) ??
                      false))
              .toList();
        }

        if (_showOnlyWithBalance) {
          customers = customers.where((c) => c.balance > 0).toList();
        }

        // Apply sorting
        customers.sort((a, b) {
          int comparison;
          switch (_sortBy) {
            case _SortOption.name:
              comparison = a.name.compareTo(b.name);
              break;
            case _SortOption.balance:
              comparison = a.balance.compareTo(b.balance);
              break;
          }
          return _sortDescending ? -comparison : comparison;
        });

        if (customers.isEmpty) {
          return HoorEmptyState(
            icon: Icons.people_outline_rounded,
            title: 'لا يوجد عملاء',
            message: _searchQuery.isNotEmpty || _showOnlyWithBalance
                ? 'لم يتم العثور على عملاء تطابق معايير البحث'
                : 'ابدأ بإضافة عملائك',
            actionLabel: _searchQuery.isEmpty ? 'إضافة عميل' : null,
            onAction: _searchQuery.isEmpty
                ? () => _showAddCustomerSheet(context)
                : null,
          );
        }

        return ListView.separated(
          padding: EdgeInsets.all(HoorSpacing.lg.w),
          itemCount: customers.length,
          separatorBuilder: (context, index) =>
              SizedBox(height: HoorSpacing.sm.h),
          itemBuilder: (context, index) {
            final customer = customers[index];
            return _CustomerCard(
              customer: customer,
              currencyService: _currencyService,
              onTap: () => _showCustomerDetails(context, customer),
            );
          },
        );
      },
    );
  }

  Widget _buildFAB(BuildContext context) {
    return FloatingActionButton.extended(
      onPressed: () => _showAddCustomerSheet(context),
      backgroundColor: HoorColors.primary,
      foregroundColor: Colors.white,
      elevation: 4,
      icon: const Icon(Icons.person_add_rounded),
      label: Text(
        'عميل جديد',
        style: HoorTypography.labelLarge.copyWith(
          color: Colors.white,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  void _showAddCustomerSheet(BuildContext context) {
    HoorBottomSheet.show(
      context,
      title: 'إضافة عميل جديد',
      showCloseButton: true,
      child: Padding(
        padding: EdgeInsets.all(HoorSpacing.lg.w),
        child: _AddCustomerForm(
          onSave: (name, phone, email, address) async {
            await _customerRepo.createCustomer(
              name: name,
              phone: phone,
              email: email,
              address: address,
            );
            if (mounted) Navigator.pop(context);
          },
        ),
      ),
    );
  }

  void _showCustomerDetails(BuildContext context, Customer customer) {
    HoorBottomSheet.show(
      context,
      title: customer.name,
      showCloseButton: true,
      child: _CustomerDetailsSheet(
        customer: customer,
        currencyService: _currencyService,
        customerRepo: _customerRepo,
      ),
    );
  }

  String _formatCurrency(double value) {
    if (value >= 1000000) {
      return '${(value / 1000000).toStringAsFixed(1)}M';
    } else if (value >= 1000) {
      return '${(value / 1000).toStringAsFixed(1)}K';
    }
    return value.toStringAsFixed(0);
  }
}

/// ═══════════════════════════════════════════════════════════════════════════
/// Supporting Widgets
/// ═══════════════════════════════════════════════════════════════════════════

enum _SortOption { name, balance }

class _IconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _IconButton({required this.icon, required this.onTap});

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
          child: Icon(icon,
              size: HoorIconSize.md, color: HoorColors.textSecondary),
        ),
      ),
    );
  }
}

class _FilterButton extends StatelessWidget {
  final IconData icon;
  final bool isActive;
  final Color? activeColor;
  final String tooltip;
  final VoidCallback onTap;

  const _FilterButton({
    required this.icon,
    required this.isActive,
    this.activeColor,
    required this.tooltip,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = isActive
        ? (activeColor ?? HoorColors.primary)
        : HoorColors.textSecondary;

    return Tooltip(
      message: tooltip,
      child: Material(
        color: isActive ? color.withValues(alpha: 0.1) : HoorColors.surface,
        borderRadius: BorderRadius.circular(HoorRadius.md),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(HoorRadius.md),
          child: Container(
            padding: EdgeInsets.all(HoorSpacing.sm.w),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(HoorRadius.md),
              border: Border.all(
                color: isActive ? color : HoorColors.border,
              ),
            ),
            child: Icon(icon, size: HoorIconSize.md, color: color),
          ),
        ),
      ),
    );
  }
}

class _SortButton extends StatelessWidget {
  final _SortOption sortBy;
  final bool sortDescending;
  final void Function(_SortOption, bool) onSortChanged;

  const _SortButton({
    required this.sortBy,
    required this.sortDescending,
    required this.onSortChanged,
  });

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<_SortOption>(
      child: Material(
        color: HoorColors.surface,
        borderRadius: BorderRadius.circular(HoorRadius.md),
        child: Container(
          padding: EdgeInsets.all(HoorSpacing.sm.w),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(HoorRadius.md),
            border: Border.all(color: HoorColors.border),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.sort_rounded,
                size: HoorIconSize.md,
                color: HoorColors.textSecondary,
              ),
              SizedBox(width: HoorSpacing.xxs.w),
              Icon(
                sortDescending
                    ? Icons.arrow_downward_rounded
                    : Icons.arrow_upward_rounded,
                size: HoorIconSize.xs,
                color: HoorColors.textSecondary,
              ),
            ],
          ),
        ),
      ),
      onSelected: (option) {
        if (sortBy == option) {
          onSortChanged(option, !sortDescending);
        } else {
          onSortChanged(option, option == _SortOption.balance);
        }
      },
      itemBuilder: (context) => [
        PopupMenuItem(
          value: _SortOption.name,
          child: Row(
            children: [
              Icon(
                sortBy == _SortOption.name
                    ? (sortDescending
                        ? Icons.arrow_downward_rounded
                        : Icons.arrow_upward_rounded)
                    : Icons.sort_by_alpha_rounded,
                size: HoorIconSize.sm,
                color: sortBy == _SortOption.name
                    ? HoorColors.primary
                    : HoorColors.textSecondary,
              ),
              SizedBox(width: HoorSpacing.sm.w),
              Text(
                'الاسم',
                style: HoorTypography.bodyMedium.copyWith(
                  color: sortBy == _SortOption.name
                      ? HoorColors.primary
                      : HoorColors.textPrimary,
                  fontWeight: sortBy == _SortOption.name
                      ? FontWeight.w600
                      : FontWeight.normal,
                ),
              ),
            ],
          ),
        ),
        PopupMenuItem(
          value: _SortOption.balance,
          child: Row(
            children: [
              Icon(
                sortBy == _SortOption.balance
                    ? (sortDescending
                        ? Icons.arrow_downward_rounded
                        : Icons.arrow_upward_rounded)
                    : Icons.account_balance_wallet_outlined,
                size: HoorIconSize.sm,
                color: sortBy == _SortOption.balance
                    ? HoorColors.primary
                    : HoorColors.textSecondary,
              ),
              SizedBox(width: HoorSpacing.sm.w),
              Text(
                'الرصيد',
                style: HoorTypography.bodyMedium.copyWith(
                  color: sortBy == _SortOption.balance
                      ? HoorColors.primary
                      : HoorColors.textPrimary,
                  fontWeight: sortBy == _SortOption.balance
                      ? FontWeight.w600
                      : FontWeight.normal,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _MiniStatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _MiniStatCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(HoorSpacing.md.w),
      decoration: BoxDecoration(
        color: HoorColors.surface,
        borderRadius: BorderRadius.circular(HoorRadius.lg),
        border: Border.all(color: HoorColors.border.withValues(alpha: 0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: HoorIconSize.sm, color: color),
          SizedBox(height: HoorSpacing.xs.h),
          Text(
            value,
            style: HoorTypography.titleMedium.copyWith(
              fontWeight: FontWeight.bold,
              fontFamily: 'IBM Plex Sans Arabic',
            ),
          ),
          Text(
            label,
            style: HoorTypography.labelSmall.copyWith(
              color: HoorColors.textSecondary,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

class _CustomerCard extends StatelessWidget {
  final Customer customer;
  final CurrencyService currencyService;
  final VoidCallback onTap;

  const _CustomerCard({
    required this.customer,
    required this.currencyService,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final hasBalance = customer.balance > 0;

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
            border: Border.all(
              color: hasBalance
                  ? HoorColors.warning.withValues(alpha: 0.5)
                  : HoorColors.border.withValues(alpha: 0.5),
            ),
          ),
          child: Row(
            children: [
              // Avatar
              HoorAvatar(
                name: customer.name,
                size: HoorAvatarSize.lg,
                backgroundColor: HoorColors.primarySoft,
                foregroundColor: HoorColors.primary,
              ),
              SizedBox(width: HoorSpacing.md.w),

              // Customer Details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      customer.name,
                      style: HoorTypography.titleSmall.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: HoorSpacing.xxs.h),
                    if (customer.phone != null && customer.phone!.isNotEmpty)
                      Row(
                        children: [
                          Icon(
                            Icons.phone_outlined,
                            size: HoorIconSize.xs,
                            color: HoorColors.textTertiary,
                          ),
                          SizedBox(width: HoorSpacing.xxs.w),
                          Text(
                            customer.phone!,
                            style: HoorTypography.labelSmall.copyWith(
                              color: HoorColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
              ),

              // Balance
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  if (hasBalance) ...[
                    Text(
                      customer.balance.toStringAsFixed(2),
                      style: HoorTypography.titleMedium.copyWith(
                        fontWeight: FontWeight.bold,
                        color: HoorColors.warning,
                        fontFamily: 'IBM Plex Sans Arabic',
                      ),
                    ),
                    Text(
                      'رصيد متبقي',
                      style: HoorTypography.labelSmall.copyWith(
                        color: HoorColors.warning,
                      ),
                    ),
                  ] else ...[
                    HoorBadge(
                      label: 'مسدد',
                      color: HoorColors.success,
                      size: HoorBadgeSize.small,
                    ),
                  ],
                ],
              ),
              SizedBox(width: HoorSpacing.xs.w),

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
}

/// ═══════════════════════════════════════════════════════════════════════════
/// Add Customer Form
/// ═══════════════════════════════════════════════════════════════════════════

class _AddCustomerForm extends StatefulWidget {
  final Future<void> Function(
      String name, String? phone, String? email, String? address) onSave;

  const _AddCustomerForm({required this.onSave});

  @override
  State<_AddCustomerForm> createState() => _AddCustomerFormState();
}

class _AddCustomerFormState extends State<_AddCustomerForm> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _addressController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Name Field
          HoorTextField(
            controller: _nameController,
            label: 'اسم العميل',
            hint: 'أدخل اسم العميل',
            prefixIcon: Icons.person_outline_rounded,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'يرجى إدخال اسم العميل';
              }
              return null;
            },
          ),
          SizedBox(height: HoorSpacing.md.h),

          // Phone Field
          HoorTextField(
            controller: _phoneController,
            label: 'رقم الهاتف',
            hint: 'أدخل رقم الهاتف',
            prefixIcon: Icons.phone_outlined,
            keyboardType: TextInputType.phone,
          ),
          SizedBox(height: HoorSpacing.md.h),

          // Email Field
          HoorTextField(
            controller: _emailController,
            label: 'البريد الإلكتروني',
            hint: 'أدخل البريد الإلكتروني',
            prefixIcon: Icons.email_outlined,
            keyboardType: TextInputType.emailAddress,
          ),
          SizedBox(height: HoorSpacing.md.h),

          // Address Field
          HoorTextField(
            controller: _addressController,
            label: 'العنوان',
            hint: 'أدخل العنوان',
            prefixIcon: Icons.location_on_outlined,
            maxLines: 2,
          ),
          SizedBox(height: HoorSpacing.xl.h),

          // Save Button
          HoorLoadingButton(
            label: 'حفظ العميل',
            isLoading: _isLoading,
            isFullWidth: true,
            icon: Icons.save_rounded,
            onPressed: _handleSave,
          ),
        ],
      ),
    );
  }

  Future<void> _handleSave() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      await widget.onSave(
        _nameController.text.trim(),
        _phoneController.text.trim().isEmpty
            ? null
            : _phoneController.text.trim(),
        _emailController.text.trim().isEmpty
            ? null
            : _emailController.text.trim(),
        _addressController.text.trim().isEmpty
            ? null
            : _addressController.text.trim(),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }
}

/// ═══════════════════════════════════════════════════════════════════════════
/// Customer Details Sheet
/// ═══════════════════════════════════════════════════════════════════════════

class _CustomerDetailsSheet extends StatelessWidget {
  final Customer customer;
  final CurrencyService currencyService;
  final CustomerRepository customerRepo;

  const _CustomerDetailsSheet({
    required this.customer,
    required this.currencyService,
    required this.customerRepo,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(HoorSpacing.lg.w),
      child: Column(
        children: [
          // Customer Info Card
          Container(
            padding: EdgeInsets.all(HoorSpacing.lg.w),
            decoration: BoxDecoration(
              color: HoorColors.primarySoft,
              borderRadius: BorderRadius.circular(HoorRadius.lg),
            ),
            child: Column(
              children: [
                HoorAvatar(
                  name: customer.name,
                  size: HoorAvatarSize.xl,
                  backgroundColor: HoorColors.primary,
                  foregroundColor: Colors.white,
                ),
                SizedBox(height: HoorSpacing.md.h),
                Text(
                  customer.name,
                  style: HoorTypography.titleLarge.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                if (customer.balance > 0) ...[
                  SizedBox(height: HoorSpacing.sm.h),
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: HoorSpacing.md.w,
                      vertical: HoorSpacing.xs.h,
                    ),
                    decoration: BoxDecoration(
                      color: HoorColors.warning.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(HoorRadius.full),
                    ),
                    child: Text(
                      'رصيد: ${customer.balance.toStringAsFixed(2)} ر.س',
                      style: HoorTypography.labelMedium.copyWith(
                        color: HoorColors.warning,
                        fontWeight: FontWeight.w600,
                        fontFamily: 'IBM Plex Sans Arabic',
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
          SizedBox(height: HoorSpacing.lg.h),

          // Contact Info
          if (customer.phone != null && customer.phone!.isNotEmpty)
            _DetailItem(
              icon: Icons.phone_outlined,
              label: 'رقم الهاتف',
              value: customer.phone!,
            ),
          if (customer.email != null && customer.email!.isNotEmpty)
            _DetailItem(
              icon: Icons.email_outlined,
              label: 'البريد الإلكتروني',
              value: customer.email!,
            ),
          if (customer.address != null && customer.address!.isNotEmpty)
            _DetailItem(
              icon: Icons.location_on_outlined,
              label: 'العنوان',
              value: customer.address!,
            ),

          SizedBox(height: HoorSpacing.xl.h),

          // Action Buttons
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {
                    // Navigate to customer invoices
                    Navigator.pop(context);
                    context.push('/invoices?customer=${customer.id}');
                  },
                  icon: const Icon(Icons.receipt_long_rounded),
                  label: const Text('الفواتير'),
                  style: OutlinedButton.styleFrom(
                    padding: EdgeInsets.all(HoorSpacing.md.w),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(HoorRadius.md),
                    ),
                  ),
                ),
              ),
              SizedBox(width: HoorSpacing.sm.w),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pop(context);
                    context.push('/invoices/new/sale?customer=${customer.id}');
                  },
                  icon: const Icon(Icons.add_rounded),
                  label: const Text('فاتورة جديدة'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: HoorColors.primary,
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.all(HoorSpacing.md.w),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(HoorRadius.md),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _DetailItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _DetailItem({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: HoorSpacing.md.h),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(HoorSpacing.sm.w),
            decoration: BoxDecoration(
              color: HoorColors.primarySoft,
              borderRadius: BorderRadius.circular(HoorRadius.md),
            ),
            child: Icon(
              icon,
              size: HoorIconSize.md,
              color: HoorColors.primary,
            ),
          ),
          SizedBox(width: HoorSpacing.md.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: HoorTypography.labelSmall.copyWith(
                    color: HoorColors.textSecondary,
                  ),
                ),
                Text(
                  value,
                  style: HoorTypography.bodyMedium,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
