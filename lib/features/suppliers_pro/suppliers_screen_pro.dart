// ═══════════════════════════════════════════════════════════════════════════
// Suppliers Screen Pro - Professional Design System
// Supplier Management Interface with Real Data
// ═══════════════════════════════════════════════════════════════════════════

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/pro/design_tokens.dart';
import '../../core/providers/app_providers.dart';
import '../../data/database/app_database.dart';

class SuppliersScreenPro extends ConsumerStatefulWidget {
  const SuppliersScreenPro({super.key});

  @override
  ConsumerState<SuppliersScreenPro> createState() => _SuppliersScreenProState();
}

class _SuppliersScreenProState extends ConsumerState<SuppliersScreenPro>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _searchController = TextEditingController();
  String _sortBy = 'name';

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

  List<Supplier> _filterSuppliers(List<Supplier> suppliers) {
    var filtered = suppliers.where((supplier) {
      final matchesSearch = _searchController.text.isEmpty ||
          supplier.name
              .toLowerCase()
              .contains(_searchController.text.toLowerCase()) ||
          (supplier.phone?.contains(_searchController.text) ?? false);
      return matchesSearch;
    }).toList();

    switch (_sortBy) {
      case 'name':
        filtered.sort((a, b) => a.name.compareTo(b.name));
        break;
      case 'balance':
        filtered.sort((a, b) => b.balance.compareTo(a.balance));
        break;
      case 'recent':
        filtered.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
        break;
    }

    return filtered;
  }

  double _totalPayables(List<Supplier> suppliers) => suppliers
      .where((s) => s.balance > 0)
      .fold(0.0, (sum, s) => sum + s.balance);

  double _totalReceivables(List<Supplier> suppliers) => suppliers
      .where((s) => s.balance < 0)
      .fold(0.0, (sum, s) => sum + s.balance.abs());

  @override
  Widget build(BuildContext context) {
    final suppliersAsync = ref.watch(suppliersStreamProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: suppliersAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, stack) => Center(
            child: Text('خطأ: $error', style: AppTypography.bodyMedium),
          ),
          data: (suppliers) {
            final filtered = _filterSuppliers(suppliers);
            return Column(
              children: [
                _buildHeader(suppliers.length),
                _buildStatsSummary(suppliers),
                _buildSearchBar(),
                _buildTabs(suppliers),
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      _buildSupplierList(filtered),
                      _buildSupplierList(
                          filtered.where((s) => s.balance > 0).toList()),
                      _buildSupplierList(
                          filtered.where((s) => s.balance < 0).toList()),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/suppliers/add'),
        backgroundColor: AppColors.secondary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.person_add_rounded),
        label: Text(
          'مورد جديد',
          style: AppTypography.labelLarge.copyWith(color: Colors.white),
        ),
      ),
    );
  }

  Widget _buildHeader(int totalSuppliers) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border(bottom: BorderSide(color: AppColors.border)),
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: () => context.go('/'),
            icon: Icon(
              Icons.arrow_back_ios_rounded,
              size: AppIconSize.sm,
              color: AppColors.textSecondary,
            ),
          ),
          SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'الموردين',
                  style: AppTypography.headlineSmall.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  '$totalSuppliers مورد',
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.textTertiary,
                  ),
                ),
              ],
            ),
          ),
          PopupMenuButton<String>(
            icon: Icon(Icons.sort_rounded, color: AppColors.textSecondary),
            onSelected: (value) => setState(() => _sortBy = value),
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'name',
                child: _buildSortOption('الاسم', _sortBy == 'name'),
              ),
              PopupMenuItem(
                value: 'balance',
                child: _buildSortOption('الرصيد', _sortBy == 'balance'),
              ),
              PopupMenuItem(
                value: 'recent',
                child: _buildSortOption('آخر تعامل', _sortBy == 'recent'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSortOption(String label, bool isSelected) {
    return Row(
      children: [
        if (isSelected)
          Icon(Icons.check_rounded,
              size: AppIconSize.sm, color: AppColors.secondary),
        if (!isSelected) SizedBox(width: AppIconSize.sm),
        SizedBox(width: AppSpacing.sm),
        Text(label),
      ],
    );
  }

  Widget _buildStatsSummary(List<Supplier> suppliers) {
    return Container(
      margin: EdgeInsets.all(AppSpacing.md),
      child: Row(
        children: [
          Expanded(
            child: _StatCard(
              label: 'مستحقات لهم',
              amount: _totalPayables(suppliers),
              icon: Icons.arrow_upward_rounded,
              color: AppColors.error,
            ),
          ),
          SizedBox(width: AppSpacing.sm),
          Expanded(
            child: _StatCard(
              label: 'مستحقات لنا',
              amount: _totalReceivables(suppliers),
              icon: Icons.arrow_downward_rounded,
              color: AppColors.success,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: AppSpacing.md),
      child: Container(
        height: 48.h,
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(color: AppColors.border),
        ),
        child: TextField(
          controller: _searchController,
          onChanged: (value) => setState(() {}),
          decoration: InputDecoration(
            hintText: 'ابحث بالاسم أو رقم الجوال...',
            hintStyle: AppTypography.bodyMedium.copyWith(
              color: AppColors.textTertiary,
            ),
            prefixIcon:
                Icon(Icons.search_rounded, color: AppColors.textTertiary),
            border: InputBorder.none,
            contentPadding: EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.sm,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTabs(List<Supplier> suppliers) {
    return Container(
      margin: EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppColors.border),
      ),
      child: TabBar(
        controller: _tabController,
        labelColor: AppColors.primary,
        unselectedLabelColor: AppColors.textSecondary,
        indicatorSize: TabBarIndicatorSize.tab,
        indicator: BoxDecoration(
          color: AppColors.primary.withOpacity(0.1),
          borderRadius: BorderRadius.circular(AppRadius.md - 1),
        ),
        dividerColor: Colors.transparent,
        tabs: [
          _buildTab('الكل', suppliers.length),
          _buildTab('دائنين', suppliers.where((s) => s.balance > 0).length),
          _buildTab('مدينين', suppliers.where((s) => s.balance < 0).length),
        ],
      ),
    );
  }

  Widget _buildTab(String label, int count) {
    return Tab(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(label),
          SizedBox(width: AppSpacing.xs),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
            decoration: BoxDecoration(
              color: AppColors.textTertiary.withOpacity(0.2),
              borderRadius: BorderRadius.circular(AppRadius.full),
            ),
            child: Text(
              '$count',
              style: AppTypography.labelSmall.copyWith(
                fontFamily: 'JetBrains Mono',
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSupplierList(List<Supplier> suppliers) {
    if (suppliers.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.local_shipping_outlined,
              size: 80.sp,
              color: AppColors.textTertiary,
            ),
            SizedBox(height: AppSpacing.lg),
            Text(
              'لا يوجد موردين',
              style: AppTypography.headlineMedium.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: EdgeInsets.symmetric(horizontal: AppSpacing.md),
      itemCount: suppliers.length,
      itemBuilder: (context, index) {
        final supplier = suppliers[index];
        return _SupplierCard(
          supplier: supplier,
          onTap: () {
            // Navigate to supplier details
          },
        );
      },
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final double amount;
  final IconData icon;
  final Color color;

  const _StatCard({
    required this.label,
    required this.amount,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(AppSpacing.sm),
            decoration: BoxDecoration(
              color: color.withOpacity(0.2),
              borderRadius: BorderRadius.circular(AppRadius.sm),
            ),
            child: Icon(icon, color: color, size: AppIconSize.md),
          ),
          SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: AppTypography.labelMedium.copyWith(
                    color: color,
                  ),
                ),
                Text(
                  '${amount.toStringAsFixed(0)} ر.س',
                  style: AppTypography.titleMedium.copyWith(
                    color: color,
                    fontWeight: FontWeight.w700,
                    fontFamily: 'JetBrains Mono',
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SupplierCard extends StatelessWidget {
  final Supplier supplier;
  final VoidCallback onTap;

  const _SupplierCard({
    required this.supplier,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final balance = supplier.balance;
    final isCreditor = balance > 0;
    final balanceColor = balance == 0
        ? AppColors.textTertiary
        : (balance > 0 ? AppColors.error : AppColors.success);

    return Card(
      margin: EdgeInsets.only(bottom: AppSpacing.sm),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.lg),
        side: BorderSide(color: AppColors.border),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        child: Padding(
          padding: EdgeInsets.all(AppSpacing.md),
          child: Row(
            children: [
              CircleAvatar(
                radius: 28.r,
                backgroundColor: AppColors.secondary.withOpacity(0.1),
                child: Icon(
                  Icons.local_shipping_rounded,
                  color: AppColors.secondary,
                  size: AppIconSize.md,
                ),
              ),
              SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            supplier.name,
                            style: AppTypography.titleSmall.copyWith(
                              color: AppColors.textPrimary,
                              fontWeight: FontWeight.w600,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (!supplier.isActive)
                          Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: AppSpacing.xs + 2,
                              vertical: 2.h,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.textTertiary.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(AppRadius.sm),
                            ),
                            child: Text(
                              'غير نشط',
                              style: AppTypography.labelSmall.copyWith(
                                color: AppColors.textTertiary,
                              ),
                            ),
                          ),
                      ],
                    ),
                    SizedBox(height: 4.h),
                    Row(
                      children: [
                        if (supplier.phone != null) ...[
                          Icon(
                            Icons.phone_outlined,
                            size: AppIconSize.xs,
                            color: AppColors.textTertiary,
                          ),
                          SizedBox(width: AppSpacing.xs),
                          Text(
                            supplier.phone!,
                            style: AppTypography.bodySmall.copyWith(
                              color: AppColors.textSecondary,
                              fontFamily: 'JetBrains Mono',
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    balance == 0
                        ? 'لا يوجد رصيد'
                        : '${balance.abs().toStringAsFixed(0)} ر.س',
                    style: AppTypography.titleSmall.copyWith(
                      color: balanceColor,
                      fontWeight: FontWeight.w700,
                      fontFamily: 'JetBrains Mono',
                    ),
                  ),
                  if (balance != 0)
                    Text(
                      isCreditor ? 'مستحق له' : 'مستحق لنا',
                      style: AppTypography.labelSmall.copyWith(
                        color: balanceColor,
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
