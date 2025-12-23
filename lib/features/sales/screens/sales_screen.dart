// lib/features/sales/screens/sales_screen.dart
// شاشة قائمة الفواتير - تصميم حديث

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/app_constants.dart';
import '../providers/sale_provider.dart';
import '../models/sale_model.dart';
import 'sale_details_screen.dart';

class SalesScreen extends StatefulWidget {
  const SalesScreen({super.key});

  @override
  State<SalesScreen> createState() => _SalesScreenState();
}

class _SalesScreenState extends State<SalesScreen> {
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildFilters(),
        Expanded(
          child: Consumer<SaleProvider>(
            builder: (context, provider, _) {
              if (provider.isLoading) {
                return const Center(
                  child: CircularProgressIndicator(color: Color(0xFF1A1A2E)),
                );
              }

              final sales = provider.sales;
              if (sales.isEmpty) {
                return _buildEmpty(provider.searchQuery.isNotEmpty);
              }

              return RefreshIndicator(
                onRefresh: () => provider.loadSales(),
                color: const Color(0xFF1A1A2E),
                child: ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: sales.length,
                  itemBuilder: (_, i) => _SaleCard(
                    sale: sales[i],
                    onTap: () => _goToDetails(sales[i]),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildFilters() {
    return Consumer<SaleProvider>(
      builder: (context, provider, _) {
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border(bottom: BorderSide(color: Colors.grey.shade100)),
          ),
          child: Column(
            children: [
              Container(
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'بحث برقم الفاتورة...',
                    hintStyle: TextStyle(
                      color: Colors.grey.shade400,
                      fontSize: 14,
                    ),
                    prefixIcon: Icon(Icons.search, color: Colors.grey.shade400),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: Icon(
                              Icons.close,
                              color: Colors.grey.shade400,
                              size: 20,
                            ),
                            onPressed: () {
                              _searchController.clear();
                              provider.setSearchQuery('');
                            },
                          )
                        : null,
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
                  ),
                  onChanged: (v) => provider.setSearchQuery(v),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                height: 36,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: [
                    _FilterChip(
                      label: 'الكل',
                      isSelected: true,
                      onTap: () => provider.setFilterStatus(null),
                    ),
                    _FilterChip(
                      label: 'مكتمل',
                      color: const Color(0xFF10B981),
                      onTap: () => provider.setFilterStatus(
                        AppConstants.saleStatusCompleted,
                      ),
                    ),
                    _FilterChip(
                      label: 'معلق',
                      color: const Color(0xFFD97706),
                      onTap: () => provider.setFilterStatus(
                        AppConstants.saleStatusPending,
                      ),
                    ),
                    _FilterChip(
                      label: 'ملغي',
                      color: const Color(0xFFEF4444),
                      onTap: () => provider.setFilterStatus(
                        AppConstants.saleStatusCancelled,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildEmpty(bool hasSearch) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Icon(
              Icons.receipt_long_outlined,
              size: 36,
              color: Colors.grey.shade400,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            hasSearch ? 'لا توجد نتائج' : 'لا توجد فواتير',
            style: TextStyle(
              color: Colors.grey.shade600,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  void _goToDetails(SaleModel sale) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => SaleDetailsScreen(sale: sale)),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final Color? color;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    this.isSelected = false,
    this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 8),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFF1A1A2E) : Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isSelected
                  ? const Color(0xFF1A1A2E)
                  : Colors.grey.shade200,
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: isSelected
                  ? Colors.white
                  : (color ?? Colors.grey.shade600),
            ),
          ),
        ),
      ),
    );
  }
}

class _SaleCard extends StatelessWidget {
  final SaleModel sale;
  final VoidCallback onTap;

  const _SaleCard({required this.sale, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final formatter = NumberFormat('#,##0.00', 'ar');
    final dateFormatter = DateFormat('dd/MM/yyyy - hh:mm a', 'ar');

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.grey.shade100),
        ),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: _statusColor().withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.receipt_outlined,
                    color: _statusColor(),
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        sale.invoiceNumber,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 15,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        dateFormatter.format(sale.saleDate),
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade500,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: _statusColor().withOpacity(0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    sale.status,
                    style: TextStyle(
                      color: _statusColor(),
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            Divider(height: 24, color: Colors.grey.shade100),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (sale.buyerName != null)
                      Text(
                        sale.buyerName!,
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    Row(
                      children: [
                        Icon(
                          _paymentIcon(),
                          size: 14,
                          color: Colors.grey.shade400,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          sale.paymentMethod,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade500,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '${formatter.format(sale.total)} ر.س',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF1A1A2E),
                      ),
                    ),
                    Text(
                      '${sale.itemsCount} عنصر',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey.shade500,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Color _statusColor() {
    switch (sale.status) {
      case 'مكتمل':
        return const Color(0xFF10B981);
      case 'ملغي':
        return const Color(0xFFEF4444);
      case 'معلق':
        return const Color(0xFFD97706);
      default:
        return Colors.grey;
    }
  }

  IconData _paymentIcon() {
    switch (sale.paymentMethod) {
      case 'نقدي':
        return Icons.payments_outlined;
      case 'بطاقة':
        return Icons.credit_card;
      case 'آجل':
        return Icons.schedule;
      default:
        return Icons.payment;
    }
  }
}
