// lib/features/sales/screens/sales_screen.dart
// شاشة قائمة الفواتير

import 'package:hoor_manager/features/sales/providers/sale_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_theme.dart';
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
        // شريط البحث والفلاتر
        _buildSearchAndFilters(),

        // قائمة الفواتير
        Expanded(
          child: Consumer<SaleProvider>(
            builder: (context, provider, _) {
              if (provider.isLoading) {
                return const Center(child: CircularProgressIndicator());
              }

              final sales = provider.sales;

              if (sales.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.receipt_long_outlined,
                        size: 64,
                        color: AppTheme.grey400,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        provider.searchQuery.isNotEmpty
                            ? 'لا توجد نتائج'
                            : 'لا توجد فواتير',
                        style: TextStyle(color: AppTheme.grey600),
                      ),
                    ],
                  ),
                );
              }

              return RefreshIndicator(
                onRefresh: () => provider.loadSales(),
                child: ListView.builder(
                  padding: const EdgeInsets.all(8),
                  itemCount: sales.length,
                  itemBuilder: (context, index) {
                    return _SaleCard(
                      sale: sales[index],
                      onTap: () => _navigateToDetails(sales[index]),
                    );
                  },
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildSearchAndFilters() {
    return Consumer<SaleProvider>(
      builder: (context, provider, _) {
        return Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppTheme.surfaceColor,
            boxShadow: [
              BoxShadow(
                color: AppTheme.grey400.withOpacity(0.2),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            children: [
              // شريط البحث
              TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'بحث برقم الفاتورة أو اسم المشتري...',
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () {
                            _searchController.clear();
                            provider.setSearchQuery('');
                          },
                        )
                      : null,
                  contentPadding: const EdgeInsets.symmetric(vertical: 0),
                ),
                onChanged: (value) => provider.setSearchQuery(value),
              ),
              const SizedBox(height: 8),

              // فلتر الحالة
              SizedBox(
                height: 40,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: [
                    _FilterChip(
                      label: 'الكل',
                      isSelected:
                          provider.searchQuery.isEmpty &&
                          provider.sales == provider.allSales,
                      onTap: () {
                        provider.setFilterStatus(null);
                        provider.setSearchQuery('');
                        _searchController.clear();
                      },
                    ),
                    _FilterChip(
                      label: 'مكتمل',
                      isSelected: false,
                      onTap: () => provider.setFilterStatus(
                        AppConstants.saleStatusCompleted,
                      ),
                      color: AppTheme.successColor,
                    ),
                    _FilterChip(
                      label: 'معلق',
                      isSelected: false,
                      onTap: () => provider.setFilterStatus(
                        AppConstants.saleStatusPending,
                      ),
                      color: AppTheme.warningColor,
                    ),
                    _FilterChip(
                      label: 'ملغي',
                      isSelected: false,
                      onTap: () => provider.setFilterStatus(
                        AppConstants.saleStatusCancelled,
                      ),
                      color: AppTheme.errorColor,
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

  void _navigateToDetails(SaleModel sale) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => SaleDetailsScreen(sale: sale)),
    );
  }
}

/// بطاقة الفاتورة
class _SaleCard extends StatelessWidget {
  final SaleModel sale;
  final VoidCallback onTap;

  const _SaleCard({required this.sale, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final formatter = NumberFormat('#,##0.00', 'ar');
    final dateFormatter = DateFormat('dd/MM/yyyy - hh:mm a', 'ar');

    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // الصف الأول: رقم الفاتورة والحالة
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(Icons.receipt, color: _getStatusColor(), size: 20),
                      const SizedBox(width: 8),
                      Text(
                        sale.invoiceNumber,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: _getStatusColor().withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      sale.status,
                      style: TextStyle(
                        color: _getStatusColor(),
                        fontWeight: FontWeight.w500,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
              const Divider(height: 24),

              // معلومات الفاتورة
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (sale.buyerName != null) ...[
                          Row(
                            children: [
                              Icon(
                                Icons.person_outline,
                                size: 16,
                                color: AppTheme.grey600,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                sale.buyerName!,
                                style: TextStyle(color: AppTheme.grey600),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                        ],
                        Row(
                          children: [
                            Icon(
                              Icons.access_time,
                              size: 16,
                              color: AppTheme.grey600,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              dateFormatter.format(sale.saleDate),
                              style: TextStyle(
                                color: AppTheme.grey600,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(
                              _getPaymentIcon(),
                              size: 16,
                              color: AppTheme.grey600,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              sale.paymentMethod,
                              style: TextStyle(
                                color: AppTheme.grey600,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // الإجمالي
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '${formatter.format(sale.total)} ر.س',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.primaryColor,
                        ),
                      ),
                      Text(
                        '${sale.itemsCount} عنصر',
                        style: TextStyle(color: AppTheme.grey600, fontSize: 12),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getStatusColor() {
    switch (sale.status) {
      case 'مكتمل':
        return AppTheme.successColor;
      case 'ملغي':
        return AppTheme.errorColor;
      case 'معلق':
        return AppTheme.warningColor;
      default:
        return AppTheme.grey600;
    }
  }

  IconData _getPaymentIcon() {
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

/// رقاقة الفلتر
class _FilterChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  final Color? color;

  const _FilterChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 8),
      child: FilterChip(
        label: Text(label),
        selected: isSelected,
        onSelected: (_) => onTap(),
        selectedColor: (color ?? AppTheme.primaryColor).withOpacity(0.2),
        checkmarkColor: color ?? AppTheme.primaryColor,
      ),
    );
  }
}
