// lib/features/sales/screens/sales_screen.dart
// شاشة قائمة الفواتير - تصميم محسّن

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/widgets.dart';
import '../providers/sale_provider.dart';
import '../models/sale_model.dart';
import 'sale_details_screen.dart';

class SalesScreen extends StatefulWidget {
  const SalesScreen({super.key});

  @override
  State<SalesScreen> createState() => _SalesScreenState();
}

class _SalesScreenState extends State<SalesScreen> with SingleTickerProviderStateMixin {
  final _searchController = TextEditingController();
  late TabController _tabController;
  String? _selectedStatus;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _tabController.addListener(_onTabChanged);
  }

  void _onTabChanged() {
    if (_tabController.indexIsChanging) return;

    setState(() {
      switch (_tabController.index) {
        case 0: _selectedStatus = null; break;
        case 1: _selectedStatus = AppConstants.saleStatusCompleted; break;
        case 2: _selectedStatus = AppConstants.saleStatusPending; break;
        case 3: _selectedStatus = AppConstants.saleStatusCancelled; break;
      }
    });
    context.read<SaleProvider>().setFilterStatus(_selectedStatus);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildHeader(),
        Expanded(
          child: Consumer<SaleProvider>(
            builder: (context, provider, _) {
              if (provider.isLoading) {
                return _buildShimmerList();
              }

              final sales = provider.sales;
              if (sales.isEmpty) {
                return _buildEmpty(provider.searchQuery.isNotEmpty);
              }

              return RefreshIndicator(
                onRefresh: () => provider.loadSales(),
                color: AppColors.primary,
                backgroundColor: Colors.white,
                child: ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: sales.length,
                  itemBuilder: (_, index) => _SaleCard(
                    sale: sales[index],
                    onTap: () => _goToDetails(sales[index]),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildHeader() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 10, offset: const Offset(0, 2)),
        ],
      ),
      child: Column(
        children: [
          Padding(padding: const EdgeInsets.all(16), child: _buildSearchBar()),
          _buildTabs(),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Consumer<SaleProvider>(
      builder: (context, provider, _) {
        return Container(
          decoration: BoxDecoration(
            color: Colors.grey.shade50,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'بحث برقم الفاتورة...',
              hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
              prefixIcon: Icon(Icons.search_rounded, color: Colors.grey.shade400),
              suffixIcon: _searchController.text.isNotEmpty
                  ? IconButton(
                      icon: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(color: Colors.grey.shade200, shape: BoxShape.circle),
                        child: Icon(Icons.close, color: Colors.grey.shade600, size: 14),
                      ),
                      onPressed: () {
                        _searchController.clear();
                        provider.setSearchQuery('');
                        setState(() {});
                      },
                    )
                  : null,
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            ),
            onChanged: (v) {
              provider.setSearchQuery(v);
              setState(() {});
            },
          ),
        );
      },
    );
  }

  Widget _buildTabs() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: TabBar(
        controller: _tabController,
        labelColor: AppColors.primary,
        unselectedLabelColor: Colors.grey.shade500,
        indicatorColor: AppColors.primary,
        indicatorWeight: 3,
        indicatorSize: TabBarIndicatorSize.label,
        labelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
        unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w500),
        tabs: [
          _buildTab('الكل', null),
          _buildTab('مكتمل', AppColors.success),
          _buildTab('معلق', AppColors.warning),
          _buildTab('ملغي', AppColors.error),
        ],
      ),
    );
  }

  Widget _buildTab(String label, Color? dotColor) {
    return Tab(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (dotColor != null) ...[
            Container(width: 8, height: 8, decoration: BoxDecoration(color: dotColor, shape: BoxShape.circle)),
            const SizedBox(width: 6),
          ],
          Text(label),
        ],
      ),
    );
  }

  Widget _buildShimmerList() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: 5,
      itemBuilder: (_, __) => Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: ShimmerLoading.listTile(),
      ),
    );
  }

  Widget _buildEmpty(bool hasSearch) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Colors.grey.shade100, Colors.grey.shade50],
              ),
              borderRadius: BorderRadius.circular(24),
            ),
            child: Icon(
              hasSearch ? Icons.search_off_rounded : Icons.receipt_long_outlined,
              size: 48,
              color: Colors.grey.shade400,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            hasSearch ? 'لا توجد نتائج' : 'لا توجد فواتير',
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: AppColors.primary),
          ),
          const SizedBox(height: 8),
          Text(
            hasSearch ? 'جرب البحث برقم فاتورة مختلف' : 'ستظهر الفواتير هنا بعد إنشائها',
            style: TextStyle(fontSize: 14, color: Colors.grey.shade500),
          ),
          if (hasSearch) ...[
            const SizedBox(height: 20),
            OutlinedButton.icon(
              onPressed: () {
                _searchController.clear();
                context.read<SaleProvider>().setSearchQuery('');
                setState(() {});
              },
              icon: const Icon(Icons.clear_all),
              label: const Text('مسح البحث'),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ],
      ),
    );
  }

  void _goToDetails(SaleModel sale) {
    Navigator.push(context, MaterialPageRoute(builder: (_) => SaleDetailsScreen(sale: sale)));
  }
}

class _SaleCard extends StatelessWidget {
  final SaleModel sale;
  final VoidCallback onTap;

  const _SaleCard({required this.sale, required this.onTap});

  Color get _statusColor {
    switch (sale.status) {
      case 'مكتمل': return AppColors.success;
      case 'ملغي': return AppColors.error;
      case 'معلق': return AppColors.warning;
      default: return Colors.grey;
    }
  }

  IconData get _statusIcon {
    switch (sale.status) {
      case 'مكتمل': return Icons.check_circle_outline;
      case 'ملغي': return Icons.cancel_outlined;
      case 'معلق': return Icons.schedule;
      default: return Icons.receipt_outlined;
    }
  }

  @override
  Widget build(BuildContext context) {
    final formatter = NumberFormat('#,##0.00', 'ar');
    final dateFormatter = DateFormat('dd/MM/yyyy - hh:mm a', 'ar');

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 10, offset: const Offset(0, 2)),
          ],
        ),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [_statusColor.withValues(alpha: 0.15), _statusColor.withValues(alpha: 0.05)],
                      ),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(_statusIcon, color: _statusColor, size: 24),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(sale.invoiceNumber, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                            const Spacer(),
                            _StatusBadge(status: sale.status, color: _statusColor),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(Icons.access_time, size: 14, color: Colors.grey.shade400),
                            const SizedBox(width: 4),
                            Text(dateFormatter.format(sale.saleDate), style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Container(height: 1, margin: const EdgeInsets.symmetric(horizontal: 16), color: Colors.grey.shade100),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(Icons.person_outline, size: 18, color: AppColors.primary),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('البائع', style: TextStyle(fontSize: 10, color: Colors.grey.shade500)),
                              Text(sale.userName, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600), maxLines: 1, overflow: TextOverflow.ellipsis),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text('${formatter.format(sale.total)} ر.س', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.primary)),
                      Row(
                        children: [
                          Icon(Icons.shopping_cart_outlined, size: 12, color: Colors.grey.shade400),
                          const SizedBox(width: 4),
                          Text('${sale.itemsCount} عنصر', style: TextStyle(fontSize: 11, color: Colors.grey.shade500)),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final String status;
  final Color color;

  const _StatusBadge({required this.status, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [color.withValues(alpha: 0.15), color.withValues(alpha: 0.05)]),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(status, style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w600)),
    );
  }
}
